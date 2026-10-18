require "uri"

module Velora
  # Deterministic configuration checks. Never sends secrets or customer data to a model.
  class CheckoutConfiguration
    def initialize(env = ENV)
      @env = env
    end

    def problems
      issues = []
      issues << "sandbox_required" unless @env.fetch("STRIPE_MODE", "sandbox") == "sandbox"
      issues << "sandbox_key_required" unless @env["STRIPE_SECRET_KEY"].to_s.match?(/\A(?:sk|rk)_test_[a-zA-Z0-9]+\z/)
      issues << "membership_price_required" unless price_id.match?(/\Aprice_[a-zA-Z0-9]+\z/)
      issues << "success_url_invalid" unless valid_url?(success_url) && success_url.include?("{CHECKOUT_SESSION_ID}")
      issues << "cancel_url_invalid" unless valid_url?(cancel_url)
      issues << "terms_url_required" unless valid_url?(@env["STRIPE_TERMS_URL"].to_s)
      issues
    end

    def price_id = @env["STRIPE_MEMBERSHIP_PRICE_ID"].to_s
    def success_url = @env["STRIPE_SUCCESS_URL"].to_s
    def cancel_url = @env["STRIPE_CANCEL_URL"].to_s

    def remote_problems(client)
      issues = []
      price = client.v1.prices.retrieve(price_id)
      recurring = price.recurring
      unless price.active && price.livemode == false && price.currency == "usd" && price.unit_amount == 2500 &&
             recurring && recurring.interval == "month" && recurring.interval_count == 1
        issues << "membership_price_mismatch"
      end
      # A configured automatic_tax flag is not evidence of tax registration.
      registrations = client.v1.tax.registrations.list({ status: "active", limit: 1 })
      issues << "active_tax_registration_required" if registrations.data.empty?
      issues
    end

    private

    def valid_url?(value)
      uri = URI.parse(value.gsub("{CHECKOUT_SESSION_ID}", "checkout_session"))
      return false if uri.userinfo || uri.fragment || uri.host.to_s.empty?
      return false if uri.host == "example.com" || uri.host.end_with?(".invalid")
      uri.scheme == "https" || (uri.scheme == "http" && %w[localhost 127.0.0.1].include?(uri.host))
    rescue URI::InvalidURIError
      false
    end
  end
end
