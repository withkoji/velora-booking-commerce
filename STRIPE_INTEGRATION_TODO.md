# Stripe Integration TODO

This is the single source of truth for remaining Checkout setup.

## Status

October 17 configuration alignment: existing Checkout Session parameters now match the attached Checkout Studio Field Intents, including branding. Only Session parameters and this setup checklist were changed. Ruby is unavailable in the editing environment, so syntax and regression tests were not run; run the test command below and verify a real sandbox Session before release.

Scenario B: a scan of the repository found no Checkout Session creation call. A minimal `POST /api/create-checkout-session` endpoint now uses the existing Ruby/Sinatra server and StripeClient. No new framework, middleware, webhook handler, or datastore was added.

The endpoint creates a subscription Session for the customer Wellness Membership and redirects to hosted Checkout with HTTP 303. It is sandbox-only: missing keys and live keys are rejected before any API call. This is a test integration, not a production booking or membership fulfillment system. Existing Shopify/Apntly bookings retain their designated payment route.

## Values to Replace

The following values are placeholders and must be updated before going live.

**Files containing placeholders:**
- [integrations/stripe-server/app.rb](integrations/stripe-server/app.rb)
- [integrations/stripe-server/.env.example](integrations/stripe-server/.env.example)

| Field | Current Value | What to Set |
|-------|---------------|-------------|
| mode | `subscription` | Chosen for the recurring Wellness Membership. Use `payment` only for a separate one-time product; the conditional excludes payment_method_collection in payment mode. |
| success_url | `#{domain}/success?session_id={CHECKOUT_SESSION_ID}` | Your real success page via server-side DOMAIN. Keep the `{CHECKOUT_SESSION_ID}` template. No success page is implemented here. |
| cancel_url | `domain` | Your real return page via server-side DOMAIN. |
| line_items[].price | `price_...` | Your sandbox recurring Stripe Price ID from https://dashboard.stripe.com/prices; confirm USD 25/month for this membership. |
| DOMAIN | `http://localhost:3000` | Local frontend origin for testing; use the actual HTTPS frontend origin for deployment. |

There are no real Price IDs or approved frontend URLs embedded in this change. The placeholder Price ID must be replaced before a real sandbox checkout can succeed.

## Configured Parameters

These are the exact Checkout Studio settings, with the requested SDK-specific ui_mode adjustment.

**File containing these parameters:**
- [integrations/stripe-server/app.rb](integrations/stripe-server/app.rb)

| Parameter | Value |
|-----------|-------|
| ui_mode | `hosted` — Gemfile constrains Stripe Ruby to `~> 19.6`, below 21.0.0 |
| billing_address_collection | `required` |
| phone_number_collection.enabled | `true` |
| automatic_tax.enabled | `true` |
| allow_promotion_codes | `false` |
| payment_method_collection | `always`, included only when mode is subscription |
| submit_type | `auto` |
| tax_id_collection.enabled | `true` |
| tax_id_collection.required | `if_supported` |
| consent_collection.terms_of_service | `required` |
| custom_text.terms_of_service_acceptance.message | `t` |
| name_collection.individual.enabled | `true` |
| locale | `en` |
| branding_settings.background_color | `#0C0702` |
| branding_settings.button_color | `#5B4D31` |
| branding_settings.font_family | `default` |
| branding_settings.border_style | `rounded` |
| branding_settings.icon | file `file_1URKb8HHtpUU8BercuOZWrYp` |
| integration_identifier | `hosted_mobile_app_0002` |
| origin_context | `mobile_app` |

The text `t` is preserved exactly as supplied, not substituted with an invented policy. Review it in Checkout Studio before public use. The supplied branding settings are included exactly; the unrequested saved-payment-method option is removed. Confirm the icon file exists in the same sandbox account used by the endpoint. The Stripe API version is not explicitly set. There is no Gemfile.lock in the repository; dependency resolution and actual API acceptance must be verified in the sandbox. If upgrading to SDK 21+, change ui_mode to hosted_page according to the requested versioning rule.

## Setup and Next Steps

1. Use Ruby 3.3+ and Bundler. In `integrations/stripe-server`, run `bundle install`. The existing Gemfile already declares Stripe, Sinatra, Puma, dotenv, SQLite and test dependencies.
2. Copy `.env.example` to a local `.env` in that directory, which the existing dotenv loader reads. Set STRIPE_SECRET_KEY to a restricted sandbox API key with the required Checkout/subscription permissions (or a sandbox secret key). The code and example use the same variable names. Never commit credentials. No browser or Vite variables are needed.
3. Keep STRIPE_MODE=sandbox. Retain existing STRIPE_WEBHOOK_SECRET and absolute EVENT_DATABASE_PATH configuration; the existing server startup still requires them. No new hosting resources or webhook registrations are created.
4. Replace the placeholder recurring Price ID and DOMAIN. Enable the required payment methods and configure the business Terms of Service URL in the sandbox Dashboard.
5. Verify Stripe Tax configuration, applicable product tax code/tax behavior, and active registrations in jurisdictions where collection is required. automatic_tax.enabled alone does not establish registration or guarantee tax collection. Production registrations were not verified by this code change.
6. Run `bundle exec ruby -Itest test/app_test.rb`. Checkout tests mock Stripe; they do not make purchases. The PR workflow also runs this test file.
7. From an allowed host, POST to `/api/create-checkout-session`; the server creates a Session and responds with a 303 redirect to Stripe. Client-submitted prices, URLs and mode are ignored. Use a browser form or navigate to the returned Location. No frontend files are introduced.
8. In the sandbox use `4242 4242 4242 4242`, any future expiry and any three-digit CVC. Test decline with `4000 0000 0000 0002`, and authentication with `4000 0025 0000 3155`. Never use real card data in testing. Confirm all requested fields are accepted by the resolved SDK/API and shown as expected.
9. The 30-day trial is NOT activated by this endpoint: trial parameters were absent from the supplied Field Intents. Configure an approved trial separately before advertising a trial through this endpoint. Customer membership benefits also remain to be defined.
10. Existing webhooks verify signatures and persist sandbox receipts only. Before granting membership access, implement verified customer/subscription association, invoice-paid/failed and subscription lifecycle handling, durable fulfillment/retries and reconciliation. Do not grant access from a redirect or assume receipt means fulfillment. This datastore has no existing customer/subscription persistence pattern, so none was invented.
11. Public rollout remains pending application authorization/rate limits, retry/idempotency design for Session creation, approved policy text, verified billing/tax settings, complete fulfillment tests and explicit release approval. The endpoint intentionally rejects live keys. Keep it separate from existing Shopify/Apntly booking payments.

## Project Structure

No new server files or infrastructure were added. Modified files:
- [integrations/stripe-server/app.rb](integrations/stripe-server/app.rb): one Checkout endpoint; existing receipt handlers unchanged.
- [integrations/stripe-server/.env.example](integrations/stripe-server/.env.example): adds server-only STRIPE_SECRET_KEY and DOMAIN.
- [integrations/stripe-server/test/app_test.rb](integrations/stripe-server/test/app_test.rb): sandbox-key guard, server-owned parameters/redirect and sanitized API error tests; existing webhook regression tests retained.
- [docs/stripe-deployment-setup.md](docs/stripe-deployment-setup.md): points Checkout setup here.
- This TODO replaces the stale statement that no server framework exists.

## Flow Overview

Browser POST → Sinatra → sandbox StripeClient → subscription Checkout Session → HTTP 303 to hosted Checkout → existing signed webhook receipt. Business fulfillment and order/membership tracking remain unimplemented; the receipt ledger stores only event/object references, not customer/subscription models.

## Resources

- https://support.stripe.com
- https://docs.stripe.com/mcp
- https://docs.stripe.com/checkout/quickstart
- https://docs.stripe.com/billing/subscriptions/trials
- https://docs.stripe.com/testing
- https://docs.stripe.com/tax/registering
