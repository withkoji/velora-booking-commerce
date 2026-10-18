# VELORA Stripe sandbox receiver

The supplied Sinatra sample has been adapted into a sandbox-only, durable webhook receipt service at `integrations/stripe-server`. A sandbox-only Checkout endpoint has since been added; see [STRIPE_INTEGRATION_TODO.md](../STRIPE_INTEGRATION_TODO.md) for all remaining Checkout setup. Booking and membership fulfillment are not implemented. A sandbox-only test membership product and recurring Price now exist; no customer payment or verified live deployment was created.

## Repository and deployment
- Repository: `withkoji/velora-booking-commerce`
- Branch: `integration/stripe-deployment`
- Runtime: Ruby 3.3 / Sinatra / Puma
- Render Blueprint: `integrations/stripe-server/render.yaml`
- Health route: `GET /health`
- Snapshot webhook route: `POST /api/webhook`
- Sandbox Checkout route: `POST /api/create-checkout-session` (setup in the TODO linked above)

The Stripe SDK repository and its private-preview branch are libraries, not the VELORA application. This implementation uses the stable Ruby gem.

## Configure Render
Create a Blueprint from the application repository and integration branch, selecting the Blueprint path above. Review the Starter web-service and 1 GB disk charges before provisioning. Nothing here subscribes to a paid plan automatically.

The Blueprint supplies sandbox mode, the persistent disk path and the start command. Set `STRIPE_WEBHOOK_SECRET` in Render's secret environment settings to the signing secret for this exact sandbox destination. The service refuses to start without it. `RENDER_EXTERNAL_HOSTNAME` supplies host authorization automatically; add `PUBLIC_HOSTNAME` only if using a custom domain. Set `STRIPE_ALLOWED_ACCOUNTS` to an approved comma-separated account allowlist only if receiving connected-account events; the default accepts platform events only.

Webhook receipt handling does not need a Stripe API key. The optional Checkout route requires the explicit server-side Checkout variables as documented in the TODO. Do not add live keys. It rejects every event with `livemode: true` and cannot be enabled for live fulfillment by an environment switch.

After deployment, the endpoint URL is the host's actual HTTPS URL followed by `/api/webhook`. Do not point a destination to this URL before the server is running. Do not replace a working production destination with this sandbox-only receiver.

## Event subscriptions
Use a sandbox snapshot destination with:
- `payment_intent.succeeded`
- `checkout.session.completed`
- `checkout.session.async_payment_succeeded`
- `checkout.session.async_payment_failed`

Snapshot format matches the supplied payment event sample and CLI trigger. The `/api/thin-webhook` route returns 501; it does not process account notifications. Accounts v2 onboarding, requirements and capability synchronization need a separately implemented handler and destination secret.

The handler verifies the raw body and signing timestamp, rejects unsigned or oversized requests, enforces sandbox and account scope, and stores minimal event references. Receipt insertion is atomic and deduplicated across restarts using `(event_id, account_scope)`. Storage failures return 503 for Stripe to retry. Events are acknowledged after receipts are committed.

Recorded payment observations are not verified VELORA deposits: no trusted booking correlation, expected amount check, Zite payment update, provider payout or Apntly confirmation is implemented. Unpaid Checkout completion and delayed-payment outcomes are distinguished. A generic CLI fixture never changes a guest booking. Receipts contain no raw payload, customer contact data, or credentials. No receipt review UI is exposed.

## Local sandbox test
With Ruby 3.3 and Bundler installed, change to `integrations/stripe-server`, run `bundle install`, then `bundle exec ruby -Itest test/app_test.rb`. Tests sign synthetic local payloads and make no Stripe API requests.

For CLI testing, run `stripe listen --forward-to localhost:4242/api/webhook`. Use that listener's signing secret (different from the Dashboard destination secret) and an absolute local database path in environment variables. Then run `bundle exec puma -b tcp://127.0.0.1:4242 config.ru`. In another authenticated terminal, run `stripe trigger payment_intent.succeeded`. A 2xx means the receipt was recorded, not that a booking was confirmed.

## Changes from the supplied sample
- Removed unsigned webhook fallback and empty signing secrets.
- Disabled live events and public account/product management routes. Checkout remains sandbox-only and configuration-gated.
- Removed global `Stripe.api_key` and sample image/redirect URLs.
- No company identity, Dashboard, fee ownership or loss liability choices are made for providers.
- Removed the inference that missing requirements mean account details are submitted.
- Added durable receipts, duplicate protection, body limits and fixed JSON errors without secret or payload logging.
- Removed browser sessions and static asset exposure.

## Before real payments or Zite synchronization
Implement authenticated provider/admin identity with server-side account ownership. Confirm the Connect charge pattern, Dashboard access, fee ownership, loss liability and commission rules before adding account creation or onboarding. Add server-owned price and booking selection, expected amount/currency verification, durable processing/retry state, API reconciliation and authorized Zite updates. Payment success alone must never confirm an appointment. Existing Shopify/Apntly bookings must stay on their designated payment route.

Use a shared database/queue before scaling beyond this single-instance disk-backed receiver. Define retention, backup and replay procedures before production. No live deployment is enabled here.

## References
- https://docs.stripe.com/webhooks
- https://docs.stripe.com/events/manage-webhook-endpoints
- https://docs.stripe.com/testing-use-cases
- https://render.com/docs/blueprint-spec
