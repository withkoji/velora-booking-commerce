# VELORA Stripe deployment setup

Status: branch prepared; application deployment and Stripe connection are not configured.

## Repository and branch
- Application repository: https://github.com/withkoji/velora-booking-commerce
- Integration branch: `integration/stripe-deployment`
- Base branch: `main`

The supplied stripe/stripe-ruby compare URL is an upstream Ruby SDK preview comparison. It is not a VELORA application or deployment endpoint. The withkoji/stripe-ruby fork is likewise a library fork. Do not deploy either as the booking application.

## Current integration boundary
Existing massage and spa bookings use Shopify/Apntly. Stripe is for separately designated flows only. Never charge the same booking through both systems. Payment success alone must not confirm an appointment.

## Required implementation
1. Identify the deployment host, runtime and project. Inspect the existing application and workflows before adding a server.
2. Use the stable official Stripe SDK appropriate to the application runtime. Do not depend on the private-preview branch without a specific required preview feature.
3. Configure a dedicated Stripe sandbox and an isolated backend environment.
4. Store credentials only in host-managed server secrets. Suggested variable names are STRIPE_API_KEY, STRIPE_WEBHOOK_SECRET, and ZITE_API_KEY. No secret values belong in this repository. Prefer a restricted Stripe key with only required permissions.
5. Deploy a signature-verifying HTTPS webhook handler. The endpoint path must be determined by the implemented route, not guessed from the storefront domain.
6. Use the exact raw request body for verification. Fail closed on missing or invalid signing configuration. Keep a durable event ledger and process events idempotently.
7. Resolve booking and payment references from trusted server records; verify payment route, environment, amount, currency and customer/account context. Uncorrelated CLI fixture events must not update a real guest booking.
8. Persist authorized payment changes into Zite; appointment confirmation additionally requires authoritative scheduling verification.
9. Verify sandbox delivery, duplicate-event handling, failed-event retries, wrong amounts, invalid signatures and isolation from live bookings before production configuration.

## Still required before deployment
- Hosting provider/project and runtime selection.
- Implemented application entrypoint and persistent event processing.
- Verified existing webhook destination and its environment.
- Server-side credentials and authorized Zite mapping.
- End-to-end sandbox test.

Creating this branch or connecting GitHub alone does not connect a Stripe account, register a webhook or deploy a working payment service.

## References
- https://docs.stripe.com/webhooks/quickstart
- https://docs.stripe.com/keys-best-practices
- https://docs.stripe.com/testing-use-cases
