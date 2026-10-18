# Stripe Integration TODO

Single source of truth for remaining VELORA Checkout setup. Updated October 17, 2026 (America/Indianapolis).

## Current status

The Ruby/Sinatra sandbox Checkout endpoint already existed. It now validates its configuration and the selected Stripe Price before creating a Session, requires a stable Idempotency-Key, and checks for an active Stripe Tax registration. Live keys and live webhook events remain blocked. This service records webhook receipts only: booking confirmation, membership activation and credits are not implemented.

### Verified account findings

- Connected account: **VELORA BY SJ sandbox**, `acct_1URDvdHiYWtYXjrY` (test mode).
- Created one sandbox-only test product: `velora_wellness_membership_sandbox`.
- Its real recurring Price is **`price_1URhWEHiYWtYXjrYcfiJ4bBE`**, USD 25/month, exclusive tax. This is not a live Price.
- No active tax registrations were returned. No registration was invented or created.
- Stripe rejected the supplied branding file `file_1URKb8HHtpUU8BercuOZWrYp` as nonexistent in this account. The broken icon reference was removed; the supplied colors, font and rounded border remain.
- A second sandbox API validation request was rejected because the account has no Terms of Service URL configured in its Dashboard. No Checkout Session or payment was successfully created by these checks.
- The meaningless custom terms message `t` was removed. Stripe's standard required-consent wording is used.
- The receipt URL returned HTTP 403 to the verification client; its functionality is unverified. The storefront policy route returned HTML, but its policy content still needs business review.
- The owner identified the deployed service as using another hosting service, not the connected Render workspace. Its actual hosting/application link has not been supplied.

## Values to configure

**Files:** [app.rb](integrations/stripe-server/app.rb), [checkout_configuration.rb](integrations/stripe-server/checkout_configuration.rb), [.env.example](integrations/stripe-server/.env.example).

All sensitive values belong in the hosting platform's server-side secret store. Do not paste keys into chat or commit them.

| Variable | Required value / action |
| --- | --- |
| STRIPE_MODE | `sandbox` only |
| STRIPE_SECRET_KEY | Restricted sandbox key with Checkout write, Prices read and Tax registration read access; use a key for the verified sandbox account above |
| STRIPE_MEMBERSHIP_PRICE_ID | `price_1URhWEHiYWtYXjrYcfiJ4bBE` for this sandbox; the code no longer contains `price_...` |
| STRIPE_SUCCESS_URL | An implemented and tested receipt/success URL containing `{CHECKOUT_SESSION_ID}`; proposed owner URL: `https://billing.viviarental.online/receipt?checkout_session={CHECKOUT_SESSION_ID}` (unverified) |
| STRIPE_CANCEL_URL | An implemented and tested return page; proposed storefront: `https://book.viviarental.online` |
| STRIPE_TERMS_URL | Business-approved public terms URL; also set the same URL in Stripe Dashboard public business details. This variable does not configure Stripe's Dashboard. |
| STRIPE_WEBHOOK_SECRET | Signing secret for this exact deployed sandbox webhook destination |
| EVENT_DATABASE_PATH | Absolute persistent SQLite path for existing webhook receipts |
| CONFIGURATION_MONITOR_TOKEN | Random server-side bearer secret, at least 32 characters, for the internal diagnostic reader |
| PUBLIC_HOSTNAME | Actual service hostname if it is not localhost or the automatically supplied Render hostname; hostname only, no scheme/path |
| STRIPE_ALLOWED_ACCOUNTS | Approved connected-account IDs only when needed; empty accepts platform events only |

`DOMAIN` is no longer used: redirects have explicit required variables to avoid accidentally redirecting deployed users to localhost. The service rejects non-local HTTP URLs, embedded credentials, fragments, invalid URLs and success URLs missing the session template.

## Configured Checkout parameters

**File:** [app.rb](integrations/stripe-server/app.rb).

| Parameter | Value |
| --- | --- |
| ui_mode | `hosted`, following the supplied versioning rule for Ruby gem `~> 19.6`; verify acceptance against the resolved SDK/API before release |
| mode | `subscription` |
| billing_address_collection | `required` |
| phone_number_collection.enabled | `true` |
| automatic_tax.enabled | `true`; Session creation is blocked while no active registration is returned |
| allow_promotion_codes | `false` |
| payment_method_collection | `always`, subscription mode only |
| submit_type | `auto` |
| tax_id_collection | enabled, required `if_supported` |
| consent_collection.terms_of_service | `required` |
| name_collection.individual.enabled | `true` |
| locale | `en` |
| branding_settings | background `#0C0702`, button `#5B4D31`, font `default`, border `rounded` |
| integration_identifier | `hosted_mobile_app_0002` |
| origin_context | `mobile_app` |
| success_url / cancel_url / line_items[].price | Required server-owned environment values above |

No payment method allowlist, unrequested saved-payment-method option, broken branding file, or custom message `t` is sent. The Stripe client API version is not overridden.

## Required setup and tests

1. Identify the actual deployed hosting service/application. Deploy the tested `main` source there and configure the variables above. The existing Render Blueprint is a separate deployment option, not evidence of a deployed service; do not provision it as a second payment path by accident.
2. Publish and review the real terms policy and set its URL under Stripe Dashboard public business details. Keep required consent enabled.
3. Resolve the tax setup with the business's actual registration information. A Stripe registration records an existing registration; it does not register the business with a government. The runtime checks for at least one active registration, which does not prove coverage of every customer jurisdiction or product classification. Do not switch off tax as a workaround or invent a registration.
4. Run the complete Ruby suite in `integrations/stripe-server`: `bundle install`, then `bundle exec ruby -Itest -e 'Dir.glob("test/**/*_test.rb").sort.each { |file| require File.expand_path(file) }'`. GitHub Actions now runs this on main pushes and pull requests. The CI workflow also supports manual dispatch.
5. POST `/api/create-checkout-session` from the approved application with an `Idempotency-Key` header containing 16–128 letters, digits or hyphens. Keep it stable for retries of one checkout attempt; use a new unpredictable key for each distinct attempt. The key is sent to Stripe with a VELORA prefix. Client-supplied prices and redirect URLs are ignored.
6. Configuration issues return 503 with safe issue codes before Session creation. Missing/invalid idempotency headers return 400. Stripe errors return a sanitized 502. Do not interpret these statuses as payment success.
7. After setup, complete a real sandbox checkout using `4242 4242 4242 4242`, a future expiry and a three-digit CVC. Test declines, authentication and duplicate requests. No real card data. Confirm price, consent, branding, required fields and the return page against the actual SDK/API.
8. Test signed webhook delivery to the deployed `/api/webhook`, duplicate delivery and persistence after restart. Receipt logging must continue to leave `booking_updated: false`. Payments must never confirm an appointment without authoritative booking verification.
9. Before public or live rollout, implement customer authorization, rate limits, customer/subscription association, verified invoice/subscription lifecycle handling, fulfillment retries, membership entitlements and business reconciliation. The prior 30-day trial is not implemented by this endpoint. Keep Shopify/Apntly bookings on their designated payment route.

## Internal configuration monitor / AI connection

The built-in rule checks run on every Checkout request. `GET /api/configuration-status` is a private, read-only diagnostic interface protected by `Authorization: Bearer <CONFIGURATION_MONITOR_TOKEN>`. It returns issue codes, never API keys, bearer tokens or customer payloads. It checks local configuration and, when local checks pass, the remote Price and active tax registrations. Its `live_ready` is always false because live fulfillment is absent.

This is a deterministic guard, **not a connected AI model**. No internal engine URL, credentials or verified running engine were found in the repository. An internal assistant can consume this endpoint from its server once its application and authentication method are identified. Do not expose the bearer token in the browser, give a model payment-write privileges, or treat generated advice as permission to change financial records. No autonomous repair service, model subscription, scheduled poller or alerts have been deployed.

## Files changed for hardening

- [app.rb](integrations/stripe-server/app.rb): guards, private diagnostics and Stripe idempotency; existing webhook verification and receipt semantics preserved.
- [checkout_configuration.rb](integrations/stripe-server/checkout_configuration.rb): local and remote configuration rules.
- [.env.example](integrations/stripe-server/.env.example): required variable names without secret values.
- [app_test.rb](integrations/stripe-server/test/app_test.rb) and [checkout_configuration_test.rb](integrations/stripe-server/test/checkout_configuration_test.rb): failed configuration, authorization, secret redaction, idempotency and existing webhook regression coverage.
- [stripe-sandbox.yml](.github/workflows/stripe-sandbox.yml): all Ruby tests on main/PR/manual runs.
- [policy-validator-cfn.yml](.github/workflows/policy-validator-cfn.yml): restrict the unused AWS sample to CloudFormation changes. Its example AWS credentials/template fields still require real setup if CloudFormation is introduced; it is not a Stripe deployment check.

## Resources

- https://dashboard.stripe.com/settings/business-details?edit=public
- https://dashboard.stripe.com/settings/tax
- https://docs.stripe.com/checkout/quickstart
- https://docs.stripe.com/testing
- https://docs.stripe.com/webhooks
- https://support.stripe.com
- https://docs.stripe.com/mcp
