ENV["RACK_ENV"] = "test"
require "minitest/autorun"
require "minitest/mock"
require "rack/test"
require "tmpdir"
require "openssl"
require_relative "../app"

class WebhookTest < Minitest::Test
  include Rack::Test::Methods
  SECRET = "whsec_fixture_only_not_a_real_secret"

  def app = Velora::App

  def setup
    @dir = Dir.mktmpdir
    @path = File.join(@dir, "events.sqlite3")
    app.set :host_authorization, { permitted_hosts: ["example.org"] }
    app.set :signing_secret, SECRET
    app.set :allowed_accounts, []
    app.set :event_store, Velora::EventStore.new(@path)
  end

  def teardown = FileUtils.remove_entry(@dir)

  def event(type = "payment_intent.succeeded")
    checkout = type.start_with?("checkout.")
    { "id" => "evt_fixture1", "object" => "event", "type" => type, "livemode" => false,
      "data" => { "object" => { "id" => checkout ? "cs_test_fixture" : "pi_fixture",
        "object" => checkout ? "checkout.session" : "payment_intent", "livemode" => false,
        "status" => "succeeded", "payment_status" => "paid", "amount_received" => 6000,
        "amount_total" => 6000, "currency" => "usd" } } }
  end

  def deliver(data, timestamp: Time.now.to_i, key: SECRET)
    body = data.is_a?(String) ? data : JSON.generate(data)
    digest = OpenSSL::HMAC.hexdigest("SHA256", key, "#{timestamp}.#{body}")
    post "/api/webhook", body, { "CONTENT_TYPE" => "application/json", "HTTP_STRIPE_SIGNATURE" => "t=#{timestamp},v1=#{digest}" }
  end

  def response = JSON.parse(last_response.body)

  def receipts
    db = SQLite3::Database.new(@path)
    db.execute("SELECT * FROM stripe_event_receipts")
  ensure
    db&.close
  end

  def test_signed_test_event_is_recorded_without_booking_update
    deliver(event)
    assert_equal 200, last_response.status
    assert_equal "recorded_for_review", response["result"]
    assert_equal false, response["booking_updated"]
    assert_equal 1, receipts.length
  end

  def test_duplicate_survives_store_restart
    deliver(event)
    app.set :event_store, Velora::EventStore.new(@path)
    deliver(event)
    assert_equal "duplicate", response["result"]
    assert_equal 1, receipts.length
  end

  def test_concurrent_duplicates_are_recorded_once
    store = app.settings.event_store
    inserted = 8.times.map { Thread.new { store.record(event, "payment_success_observed") } }.map(&:value)
    assert_equal 1, inserted.count(true)
    assert_equal 1, receipts.length
  end

  def test_unsigned_event_rejected
    post "/api/webhook", JSON.generate(event), { "CONTENT_TYPE" => "application/json" }
    assert_equal 400, last_response.status
    assert_empty receipts
  end

  def test_wrong_signature_rejected
    deliver(event, key: "wrong-secret")
    assert_equal 400, last_response.status
    assert_empty receipts
  end

  def test_stale_signature_rejected
    deliver(event, timestamp: Time.now.to_i - 1000)
    assert_equal 400, last_response.status
    assert_empty receipts
  end

  def test_signed_malformed_json_rejected
    deliver("{invalid")
    assert_equal 400, last_response.status
  end

  def test_signed_non_object_payload_rejected
    deliver("[]")
    assert_equal 400, last_response.status
  end

  def test_invalid_data_shape_rejected
    deliver(event.merge("data" => "invalid"))
    assert_equal 400, last_response.status
  end

  def test_missing_secret_fails_closed
    app.set :signing_secret, nil
    deliver(event)
    assert_equal 503, last_response.status
    assert_empty receipts
  end

  def test_live_event_rejected
    value = event.merge("livemode" => true)
    deliver(value)
    assert_equal 400, last_response.status
    assert_empty receipts
  end

  def test_live_object_rejected
    value = event
    value["data"]["object"]["livemode"] = true
    deliver(value)
    assert_equal 400, last_response.status
    assert_empty receipts
  end

  def test_unapproved_connected_account_rejected
    deliver(event.merge("account" => "acct_fixture"))
    assert_equal 403, last_response.status
    assert_empty receipts
  end

  def test_approved_connected_account_receipt
    app.set :allowed_accounts, ["acct_fixture"]
    deliver(event.merge("account" => "acct_fixture"))
    assert_equal 200, last_response.status
    assert_equal "acct_fixture", receipts.first[1]
  end

  def test_unpaid_checkout_never_becomes_success
    value = event("checkout.session.completed")
    value["data"]["object"]["payment_status"] = "unpaid"
    deliver(value)
    assert_equal 200, last_response.status
    assert_equal "checkout_completed_unpaid", receipts.first[4]
    assert_equal false, response["booking_updated"]
  end

  def test_delayed_payment_success_is_supported
    deliver(event("checkout.session.async_payment_succeeded"))
    assert_equal 200, last_response.status
    assert_equal "payment_success_observed", receipts.first[4]
  end

  def test_delayed_payment_failure_is_supported
    deliver(event("checkout.session.async_payment_failed"))
    assert_equal 200, last_response.status
    assert_equal "async_payment_failed", receipts.first[4]
  end

  def test_other_event_type_is_ignored_without_writes
    deliver(event("customer.created"))
    assert_equal 200, last_response.status
    assert_equal "ignored_event_type", response["result"]
    assert_empty receipts
  end

  def test_wrong_object_type_rejected
    value = event
    value["data"]["object"]["object"] = "customer"
    deliver(value)
    assert_equal 400, last_response.status
    assert_empty receipts
  end

  def test_database_failure_is_retryable
    broken = Object.new
    def broken.record(*) = raise(SQLite3::BusyException, "busy")
    app.set :event_store, broken
    deliver(event)
    assert_equal 503, last_response.status
  end

  def test_request_size_limit
    post "/api/webhook", "x" * (Velora::App::MAX_BODY_BYTES + 1), { "CONTENT_TYPE" => "application/json" }
    assert_equal 413, last_response.status
  end

  def test_public_management_routes_are_not_exposed
    %w[/api/create-product /api/create-connect-account /api/create-account-link].each do |path|
      post path, "{}", { "CONTENT_TYPE" => "application/json" }
      assert_equal 404, last_response.status
    end
    get "/api/account-status/acct_fixture"
    assert_equal 404, last_response.status
  end

  def with_checkout_environment(key: nil, mode: "sandbox")
    names = %w[STRIPE_SECRET_KEY STRIPE_MODE STRIPE_MEMBERSHIP_PRICE_ID STRIPE_SUCCESS_URL STRIPE_CANCEL_URL STRIPE_TERMS_URL CONFIGURATION_MONITOR_TOKEN]
    previous = names.to_h { |name| [name, ENV[name]] }
    key ? ENV["STRIPE_SECRET_KEY"] = key : ENV.delete("STRIPE_SECRET_KEY")
    ENV["STRIPE_MODE"] = mode
    ENV["STRIPE_MEMBERSHIP_PRICE_ID"] = "price_fixture"
    ENV["STRIPE_SUCCESS_URL"] = "https://checkout.velora.test/receipt?checkout_session={CHECKOUT_SESSION_ID}"
    ENV["STRIPE_CANCEL_URL"] = "https://checkout.velora.test"
    ENV["STRIPE_TERMS_URL"] = "https://checkout.velora.test/terms"
    ENV["CONFIGURATION_MONITOR_TOKEN"] = "monitor-fixture-token-for-tests-only-123456"
    header "Idempotency-Key", "fixture-checkout-12345678"
    yield
  ensure
    previous.each { |name, value| value ? ENV[name] = value : ENV.delete(name) }
    header "Idempotency-Key", nil
    header "Authorization", nil
  end

  def checkout_client(sessions, registrations: [Object.new])
    recurring = Struct.new(:interval, :interval_count).new("month", 1)
    price = Struct.new(:active, :livemode, :currency, :unit_amount, :recurring).new(true, false, "usd", 2500, recurring)
    prices = Object.new
    prices.define_singleton_method(:retrieve) { |*| price }
    registration_service = Object.new
    registration_service.define_singleton_method(:list) { |*| Struct.new(:data).new(registrations) }
    v1 = Struct.new(:checkout, :prices, :tax).new(Struct.new(:sessions).new(sessions), prices,
      Struct.new(:registrations).new(registration_service))
    Struct.new(:v1).new(v1)
  end

  def test_checkout_fails_closed_without_test_key
    [nil, "sk_live_fixture", "rk_live_fixture"].each do |key|
      with_checkout_environment(key: key) do
        Stripe::StripeClient.stub(:new, ->(*) { flunk "Must not call Stripe" }) do
          post "/api/create-checkout-session"
          assert_equal 503, last_response.status
        end
      end
    end
    with_checkout_environment(key: "sk_test_fixture", mode: "live") do
      post "/api/create-checkout-session"
      assert_equal 503, last_response.status
    end
  end

  def test_checkout_creates_server_owned_subscription_and_redirects
    captured = nil
    captured_options = nil
    sessions = Object.new
    sessions.define_singleton_method(:create) do |params, options|
      captured = params
      captured_options = options
      Struct.new(:url).new("https://checkout.stripe.com/c/pay/cs_test_fixture")
    end
    client = checkout_client(sessions)
    with_checkout_environment(key: "sk_test_fixture") do
      Stripe::StripeClient.stub(:new, ->(key) { assert_equal "sk_test_fixture", key; client }) do
        post "/api/create-checkout-session", { price: "price_attacker", success_url: "https://attacker.invalid" }
        assert_equal 303, last_response.status
        assert_equal "https://checkout.stripe.com/c/pay/cs_test_fixture", last_response.headers["location"]
      end
    end
    assert_equal "subscription", captured[:mode]
    assert_equal "hosted", captured[:ui_mode]
    assert_equal "always", captured[:payment_method_collection]
    assert_equal [{ price: "price_fixture", quantity: 1 }], captured[:line_items]
    assert_equal "https://checkout.velora.test/receipt?checkout_session={CHECKOUT_SESSION_ID}", captured[:success_url]
    assert_equal "https://checkout.velora.test", captured[:cancel_url]
    assert_equal "velora-membership-fixture-checkout-12345678", captured_options[:idempotency_key]
    refute captured.key?(:custom_text)
    refute captured[:branding_settings].key?(:icon)
    assert_equal true, captured.dig(:automatic_tax, :enabled)
    assert_equal "if_supported", captured.dig(:tax_id_collection, :required)
    assert_equal "hosted_mobile_app_0002", captured[:integration_identifier]
    assert_equal "mobile_app", captured[:origin_context]
    assert_equal false, captured[:allow_promotion_codes]
  end

  def test_checkout_api_errors_do_not_expose_details
    sessions = Object.new
    def sessions.create(*) = raise(Stripe::StripeError, "sensitive provider detail")
    client = checkout_client(sessions)
    with_checkout_environment(key: "rk_test_fixture") do
      Stripe::StripeClient.stub(:new, client) do
        post "/api/create-checkout-session"
        assert_equal 502, last_response.status
        refute_includes last_response.body, "sensitive provider detail"
      end
    end
  end

  def test_missing_configuration_never_calls_stripe
    with_checkout_environment(key: "sk_test_fixture") do
      ENV["STRIPE_MEMBERSHIP_PRICE_ID"] = "price_..."
      Stripe::StripeClient.stub(:new, ->(*) { flunk "Must not call Stripe" }) do
        post "/api/create-checkout-session"
        assert_equal 503, last_response.status
        assert_includes response["issues"], "membership_price_required"
      end
    end
  end

  def test_missing_idempotency_key_never_calls_stripe
    with_checkout_environment(key: "sk_test_fixture") do
      header "Idempotency-Key", nil
      Stripe::StripeClient.stub(:new, ->(*) { flunk "Must not call Stripe" }) do
        post "/api/create-checkout-session"
        assert_equal 400, last_response.status
      end
    end
  end

  def test_missing_tax_registration_blocks_session_creation
    sessions = Object.new
    def sessions.create(*) = raise("Must not create a Session")
    with_checkout_environment(key: "sk_test_fixture") do
      Stripe::StripeClient.stub(:new, checkout_client(sessions, registrations: [])) do
        post "/api/create-checkout-session"
        assert_equal 503, last_response.status
        assert_includes response["issues"], "active_tax_registration_required"
      end
    end
  end

  def test_monitor_requires_bearer_token_and_redacts_secrets
    with_checkout_environment(key: "sk_test_fixture") do
      Stripe::StripeClient.stub(:new, ->(*) { flunk "Unauthorized monitoring must not call Stripe" }) do
        get "/api/configuration-status"
        assert_equal 401, last_response.status
        header "Authorization", ENV["CONFIGURATION_MONITOR_TOKEN"]
        get "/api/configuration-status"
        assert_equal 401, last_response.status
      end
      header "Authorization", "Bearer #{ENV.fetch('CONFIGURATION_MONITOR_TOKEN')}"
      Stripe::StripeClient.stub(:new, checkout_client(Object.new, registrations: [])) do
        get "/api/configuration-status"
        assert_equal 503, last_response.status
        assert_equal false, response["live_ready"]
        refute_includes last_response.body, ENV["STRIPE_SECRET_KEY"]
        refute_includes last_response.body, ENV["CONFIGURATION_MONITOR_TOKEN"]
      end
    end
  end

  def test_thin_destination_cannot_silently_accept_unprocessed_events
    post "/api/thin-webhook", "{}", { "CONTENT_TYPE" => "application/json" }
    assert_equal 501, last_response.status
  end

  def test_no_full_customer_payload_is_stored
    value = event
    value["data"]["object"]["customer_email"] = "fixture@example.invalid"
    deliver(value)
    refute_includes receipts.inspect, "fixture@example.invalid"
  end
end
