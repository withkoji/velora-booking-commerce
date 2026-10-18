require "dotenv/load"
require "sinatra/base"
require "stripe"
require "json"
require_relative "event_store"
require_relative "checkout_configuration"

module Velora
  class App < Sinatra::Base
    MAX_BODY_BYTES = 1_048_576
    SUPPORTED_EVENTS = %w[payment_intent.succeeded checkout.session.completed checkout.session.async_payment_succeeded checkout.session.async_payment_failed].freeze

    set :show_exceptions, false
    set :dump_errors, false
    set :logging, false
    set :sessions, false
    set :static, false
    set :event_store, nil
    set :signing_secret, nil
    set :allowed_accounts, []
    set :host_authorization, { permitted_hosts: ["localhost", "127.0.0.1"] }

    def self.configure_from_environment!
      # Intentionally sandbox-only: this service does not implement live fulfillment.
      raise "This service only supports Stripe sandbox events" unless ENV.fetch("STRIPE_MODE", "sandbox") == "sandbox"
      secret = ENV.fetch("STRIPE_WEBHOOK_SECRET")
      raise "A webhook signing secret is required" unless secret.start_with?("whsec_") && secret.length > 12
      path = ENV.fetch("EVENT_DATABASE_PATH")
      raise "EVENT_DATABASE_PATH must be absolute" unless path.start_with?("/")
      accounts = ENV.fetch("STRIPE_ALLOWED_ACCOUNTS", "").split(",").map(&:strip).reject(&:empty?)
      raise "Invalid connected-account allowlist" unless accounts.all? { |a| a.match?(/\Aacct_[a-zA-Z0-9]+\z/) }
      hosts = ["localhost", "127.0.0.1", ENV["RENDER_EXTERNAL_HOSTNAME"]].compact
      extra_host = ENV["PUBLIC_HOSTNAME"]
      hosts << extra_host if extra_host && !extra_host.empty?
      raise "Hostnames must not contain URLs or paths" unless hosts.all? { |h| h.match?(/\A[a-zA-Z0-9.-]+\z/) }
      set :host_authorization, { permitted_hosts: hosts.uniq }
      set :signing_secret, secret
      set :allowed_accounts, accounts
      set :event_store, EventStore.new(path)
    end

    before do
      content_type :json
      headers "Cache-Control" => "no-store", "X-Content-Type-Options" => "nosniff"
    end

    get "/health" do
      halt 503, JSON.generate(error: "Service not configured") unless settings.event_store && settings.signing_secret
      JSON.generate(status: "ok", mode: "sandbox", booking_sync: "not_implemented")
    end

    # Private, read-only interface for an internal monitoring/assistant service.
    # The bearer token belongs only in that service's server-side secret store.
    get "/api/configuration-status" do
      token = ENV["CONFIGURATION_MONITOR_TOKEN"].to_s
      supplied = request.env["HTTP_AUTHORIZATION"].to_s.delete_prefix("Bearer ")
      halt 503, JSON.generate(error: "Monitor not configured") if token.length < 32
      halt 401, JSON.generate(error: "Unauthorized") unless request.env["HTTP_AUTHORIZATION"].to_s.start_with?("Bearer ") &&
        Rack::Utils.secure_compare(supplied, token)
      config = CheckoutConfiguration.new
      issues = config.problems
      issues += config.remote_problems(Stripe::StripeClient.new(ENV.fetch("STRIPE_SECRET_KEY"))) if issues.empty?
      status issues.empty? ? 200 : 503
      JSON.generate(mode: "sandbox", configuration_valid: issues.empty?, issues: issues,
                    checkout_status: "requires_end_to_end_verification",
                    live_ready: false, fulfillment: "not_implemented", ai_engine_connected: false)
    rescue Stripe::StripeError
      halt 503, JSON.generate(configuration_valid: false, issues: ["stripe_configuration_check_failed"], live_ready: false)
    end

    post "/api/create-checkout-session" do
      # This receiver has no customer authorization/fulfillment layer yet.
      # Keep Checkout sandbox-only; prices and redirects are server-owned.
      config = CheckoutConfiguration.new
      issues = config.problems
      halt 503, JSON.generate(error: "Checkout configuration incomplete", issues: issues) unless issues.empty?
      idempotency_key = request.env["HTTP_IDEMPOTENCY_KEY"].to_s
      halt 400, JSON.generate(error: "A stable Idempotency-Key header (16–128 letters, digits or hyphens) is required") unless
        idempotency_key.match?(/\A[a-zA-Z0-9-]{16,128}\z/)
      client = Stripe::StripeClient.new(ENV.fetch("STRIPE_SECRET_KEY"))
      issues = config.remote_problems(client)
      halt 503, JSON.generate(error: "Checkout configuration incomplete", issues: issues) unless issues.empty?
      mode = "subscription" # Recurring VELORA Wellness Membership.
      session_params = {
        ui_mode: "hosted", # Gemfile pins stripe ~> 19.6 (< 21.0.0).
        mode: mode,
        billing_address_collection: "required",
        phone_number_collection: { enabled: true },
        automatic_tax: { enabled: true },
        allow_promotion_codes: false,
        submit_type: "auto",
        tax_id_collection: { enabled: true, required: "if_supported" },
        consent_collection: { terms_of_service: "required" },
        name_collection: { individual: { enabled: true } },
        locale: "en",
        branding_settings: {
          background_color: "#0C0702",
          button_color: "#5B4D31",
          font_family: "default",
          border_style: "rounded"
        },
        integration_identifier: "hosted_mobile_app_0002",
        origin_context: "mobile_app",
        success_url: config.success_url,
        cancel_url: config.cancel_url,
        line_items: [{ price: config.price_id, quantity: 1 }]
      }
      session_params[:payment_method_collection] = "always" if mode == "subscription"
      session = client.v1.checkout.sessions.create(session_params, { idempotency_key: "velora-membership-#{idempotency_key}" })
      redirect session.url, 303
    rescue Stripe::StripeError
      halt 502, JSON.generate(error: "Checkout unavailable; review server configuration")
    end

    post "/api/webhook" do
      secret = settings.signing_secret
      halt 503, JSON.generate(error: "Webhook not configured") unless secret && !secret.empty? && settings.event_store
      halt 415, JSON.generate(error: "JSON required") unless request.media_type == "application/json"
      payload = request.body.read(MAX_BODY_BYTES + 1)
      halt 413, JSON.generate(error: "Payload too large") if payload.bytesize > MAX_BODY_BYTES
      signature = request.env["HTTP_STRIPE_SIGNATURE"]
      halt 400, JSON.generate(error: "Invalid webhook signature") if signature.to_s.empty?

      begin
        Stripe::Webhook.construct_event(payload, signature, secret)
        # Parse only after signature verification; use string keys consistently.
        event = JSON.parse(payload)
      rescue Stripe::SignatureVerificationError, JSON::ParserError, ArgumentError, TypeError, NoMethodError
        halt 400, JSON.generate(error: "Invalid webhook signature or payload")
      end

      halt 400, JSON.generate(error: "Invalid event") unless event.is_a?(Hash) && event["object"] == "event" && event["id"].is_a?(String) && event["id"].match?(/\Aevt_[a-zA-Z0-9]+\z/) && event["type"].is_a?(String)
      halt 400, JSON.generate(error: "Sandbox events only") unless event["livemode"] == false
      account = event["account"]
      halt 403, JSON.generate(error: "Account not permitted") if account && !settings.allowed_accounts.include?(account)
      halt 200, JSON.generate(received: true, result: "ignored_event_type") unless SUPPORTED_EVENTS.include?(event["type"])

      halt 400, JSON.generate(error: "Invalid event data") unless event["data"].is_a?(Hash)
      object = event.dig("data", "object")
      halt 400, JSON.generate(error: "Invalid event object") unless object.is_a?(Hash) && object["id"].is_a?(String)
      halt 400, JSON.generate(error: "Inconsistent event environment") if object["livemode"] == true
      expected_object = event["type"].start_with?("checkout.session.") ? "checkout.session" : "payment_intent"
      halt 400, JSON.generate(error: "Unexpected object type") unless object["object"] == expected_object
      observation = case event["type"]
                    when "payment_intent.succeeded"
                      object["status"] == "succeeded" ? "payment_success_observed" : "inconsistent_payment_state"
                    when "checkout.session.async_payment_succeeded"
                      object["payment_status"] == "paid" ? "payment_success_observed" : "inconsistent_payment_state"
                    when "checkout.session.completed"
                      object["payment_status"] == "paid" ? "payment_success_observed" : "checkout_completed_unpaid"
                    else "async_payment_failed"
                    end
      begin
        inserted = settings.event_store.record(event, observation)
      rescue SQLite3::Exception, IOError, SystemCallError
        halt 503, JSON.generate(error: "Event storage unavailable; retry delivery")
      end
      JSON.generate(received: true, result: inserted ? "recorded_for_review" : "duplicate", booking_updated: false)
    end

    # Thin events need their own verified destination, secret, and authorized API fetch.
    # Do not acknowledge them as processed until that handler is implemented.
    post "/api/thin-webhook" do
      halt 501, JSON.generate(error: "Thin-event handler not implemented; use the snapshot destination")
    end

    not_found { JSON.generate(error: "Not found") }
    error { status 500; JSON.generate(error: "Internal error") }
  end
end
