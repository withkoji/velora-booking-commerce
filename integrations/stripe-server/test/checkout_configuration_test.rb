require "minitest/autorun"
require_relative "../checkout_configuration"

class CheckoutConfigurationTest < Minitest::Test
  def valid_environment
    { "STRIPE_MODE" => "sandbox", "STRIPE_SECRET_KEY" => "rk_test_fixture",
      "STRIPE_MEMBERSHIP_PRICE_ID" => "price_fixture",
      "STRIPE_SUCCESS_URL" => "https://billing.velora.test/receipt?checkout_session={CHECKOUT_SESSION_ID}",
      "STRIPE_CANCEL_URL" => "https://book.velora.test", "STRIPE_TERMS_URL" => "https://book.velora.test/terms" }
  end

  def test_valid_sandbox_configuration
    assert_empty Velora::CheckoutConfiguration.new(valid_environment).problems
  end

  def test_missing_values_and_live_keys_are_blocked
    problems = Velora::CheckoutConfiguration.new({ "STRIPE_SECRET_KEY" => "sk_live_private" }).problems
    assert_includes problems, "sandbox_key_required"
    assert_includes problems, "membership_price_required"
    assert_includes problems, "success_url_invalid"
    assert_includes problems, "terms_url_required"
    refute_includes problems.inspect, "sk_live_private"
  end

  def test_redirects_reject_credentials_http_and_missing_session_template
    ["http://billing.velora.test/receipt?checkout_session={CHECKOUT_SESSION_ID}",
     "https://user:password@billing.velora.test/receipt?checkout_session={CHECKOUT_SESSION_ID}",
     "https://billing.velora.test/receipt", "not a url"].each do |url|
      env = valid_environment.merge("STRIPE_SUCCESS_URL" => url)
      assert_includes Velora::CheckoutConfiguration.new(env).problems, "success_url_invalid"
    end
  end

  def test_local_http_is_allowed_for_development
    env = valid_environment.merge("STRIPE_CANCEL_URL" => "http://localhost:3000")
    assert_empty Velora::CheckoutConfiguration.new(env).problems
  end
end
