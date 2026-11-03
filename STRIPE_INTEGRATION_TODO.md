# Stripe Integration TODO

Single source of truth for the remaining VELORA Stripe Checkout setup after applying the current Checkout Studio field intents.

## Current status

The repository is **Scenario A**: an existing Ruby/Sinatra Checkout Session endpoint is present at [`integrations/stripe-server/app.rb`](integrations/stripe-server/app.rb). The Checkout Session parameters were updated in place only; no new route, infrastructure, authentication flow, webhook handler, or datastore was added.

The project pins Stripe Ruby to `~> 19.6`, so the Checkout `ui_mode` remains `hosted` under the supplied SDK-version rule. The existing recurring membership `mode`, server-owned success/cancel URLs, and server-owned Price ID were preserved.

## Values to Replace

There are **no literal `sample_only` placeholder values in the Checkout Session call**. The existing `mode`, `success_url`, `cancel_url`, and `line_items` are backed by the application's existing configuration and were preserved.

The following runtime values still must be configured correctly before Checkout can work in a deployed environment:

**Files using these values:**
- [`integrations/stripe-server/app.rb`](integrations/stripe-server/app.rb)
- [`integrations/stripe-server/checkout_configuration.rb`](integrations/stripe-server/checkout_configuration.rb)
- [`integrations/stripe-server/.env.example`](integrations/stripe-server/.env.example)

| Field / variable | Current source | What to set |
| --- | --- | --- |
| `STRIPE_SECRET_KEY` | Environment | Valid sandbox server-side Stripe secret/restricted key for the intended account. Never commit it. |
| `STRIPE_MEMBERSHIP_PRICE_ID` | Environment | Actual recurring Stripe Price ID for the VELORA Wellness Membership. |
| `STRIPE_SUCCESS_URL` | Environment | Real HTTPS success URL containing `{CHECKOUT_SESSION_ID}`. |
| `STRIPE_CANCEL_URL` | Environment | Real HTTPS cancel/return URL. |
| `STRIPE_TERMS_URL` | Environment | Business-approved public Terms of Service URL required by the existing configuration guard. |
| `STRIPE_WEBHOOK_SECRET` | Environment | Signing secret for the deployed webhook destination. |
| `EVENT_DATABASE_PATH` | Environment | Absolute persistent path for the existing SQLite event store. |
| `CONFIGURATION_MONITOR_TOKEN` | Environment | Server-side token of at least 32 characters for the private configuration-status endpoint. |
| `PUBLIC_HOSTNAME` | Environment | Deployed service hostname if needed; hostname only. |
| `STRIPE_ALLOWED_ACCOUNTS` | Environment | Approved connected-account IDs when Connect events are expected. |

## Configured Parameters

These parameters were configured in Checkout Studio and are now placed in the existing Checkout Session creation path.

**File containing these parameters:**
- [`integrations/stripe-server/app.rb`](integrations/stripe-server/app.rb)

| Parameter | Value |
| --- | --- |
| `ui_mode` | `hosted` because Stripe Ruby is `~> 19.6` (< 21.0.0) |
| `mode` | `subscription` (existing real value preserved) |
| `billing_address_collection` | `auto` |
| `phone_number_collection.enabled` | `false` |
| `automatic_tax.enabled` | `false` |
| `allow_promotion_codes` | `false` |
| `payment_method_collection` | `always` (included only because mode is `subscription`) |
| `submit_type` | `book` |
| `consent_collection.terms_of_service` | `required` |
| `consent_collection.promotions` | `auto` |
| `name_collection.individual.enabled` | `true` |
| `locale` | `en` |
| `saved_payment_method_options.payment_method_save` | `enabled` |
| `integration_identifier` | `hosted_mobile_app_0001` |
| `origin_context` | `mobile_app` |
| `branding_settings.background_color` | `#0c0702` |
| `branding_settings.button_color` | `#5b4d31` |
| `branding_settings.font_family` | `default` |
| `branding_settings.border_style` | `rounded` |
| `branding_settings.icon.type` | `file` |
| `branding_settings.icon.file` | `file_1UWqQv2f2UX4QyfJFw9yJG4N` |
| `success_url` | Existing `config.success_url` preserved |
| `cancel_url` | Existing `config.cancel_url` preserved |
| `line_items[].price` | Existing `config.price_id` preserved |

The previously present `tax_id_collection` parameter was removed because it is absent from the current Field Intents.

## Setup and Next Steps

1. Configure the environment variables above in the actual deployed server secret store. Keep all Stripe secret material server-side.
2. Confirm the Stripe account contains the configured branding file `file_1UWqQv2f2UX4QyfJFw9yJG4N` and that the account's public business details include the Terms of Service URL required by Checkout consent collection.
3. Verify the recurring Price referenced by `STRIPE_MEMBERSHIP_PRICE_ID` is active and represents the intended membership product.
4. The automatic-tax guard now follows the disabled automatic-tax profile; it does not query Tax registrations in this mode. This sandbox setting does not establish production tax readiness. Any future tax-enabled profile must retain active-registration validation.
5. Run the Ruby test suite from `integrations/stripe-server`:
   `bundle install`
   `bundle exec ruby -Itest -e 'Dir.glob("test/**/*_test.rb").sort.each { |file| require File.expand_path(file) }'`
6. Test `/api/create-checkout-session` in Stripe sandbox mode with the endpoint's required `Idempotency-Key` header. Confirm the hosted Checkout page displays the configured name collection, consent, saved-payment-method option, `Book` submit label, branding, and redirects.
7. Use Stripe test payment methods only. For a standard successful card test, use `4242 4242 4242 4242`, a future expiry, and any valid three-digit CVC.
8. Verify signed webhook delivery to `/api/webhook`, duplicate-event behavior, and persistence. The existing webhook receiver records events but does not implement live membership fulfillment or booking confirmation.
9. Before live rollout, add/verify customer authorization, customer/subscription association, fulfillment, reconciliation, lifecycle handling, rate limiting, and production-specific operational controls.

## Project Structure

No new application files or routes were created for this change.

Updated files:
- [`integrations/stripe-server/app.rb`](integrations/stripe-server/app.rb) — Checkout Session parameters only.
- [`STRIPE_INTEGRATION_TODO.md`](STRIPE_INTEGRATION_TODO.md) — remaining setup and validation steps.

## Flow Overview

1. The client calls the existing `/api/create-checkout-session` endpoint with a valid idempotency key.
2. The server validates its existing configuration and Stripe Price.
3. The server creates a Stripe-hosted Checkout Session using the Studio-configured parameters plus the existing membership mode, URLs, and Price.
4. Stripe redirects the customer to the configured success or cancel destination.
5. Signed Stripe webhook events are received by the existing `/api/webhook` route and recorded for review.

## Resources

- https://docs.stripe.com/checkout
- https://docs.stripe.com/testing
- https://docs.stripe.com/webhooks
- https://support.stripe.com
- https://docs.stripe.com/mcp

## Release gates (2026-11-03)

See [Stripe release sequence](docs/stripe-release-sequence.md). Passing unit tests or configuration diagnostics is not sandbox acceptance or live readiness. Do not close #34 merely because a failed check has an owner.
