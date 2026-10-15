# Stripe Integration TODO

## Status

Scenario B was detected: no existing Stripe Checkout Session API call is present in the repository.

The repository does not contain an application server framework, package manifest, or existing server entrypoint. Its `api/` directory currently contains only `.gitkeep`. Adding a server endpoint would therefore require choosing and introducing a deployment/server framework that is not verifiably part of the project. Per the integration task, no such framework is being invented.

## Values to Replace

No Checkout Session endpoint was added, so there are currently no code placeholders to replace.

When a supported server endpoint is added, these sample-only values must be configured with real project values:

| Field | Current Value | What to Set |
|-------|---------------|-------------|
| mode | payment/subscription | Use `payment` for one-time wellness purchases or `subscription` for recurring VELORA memberships. |
| success_url | placeholder | Actual VELORA post-payment success URL, retaining the `{CHECKOUT_SESSION_ID}` template. |
| cancel_url | placeholder | Actual VELORA cancel/return URL. |
| line_items[].price | `price_...` | Actual Stripe Price ID for the selected VELORA product. |

## Configured Parameters

No Checkout Session creation call exists in the repository yet, so no Checkout Studio parameters could be placed without introducing an unsupported server framework.

The required Checkout Studio parameters for the eventual endpoint are:

| Parameter | Value |
|-----------|-------|
| ui_mode | hosted_page (or hosted for Stripe SDKs below 21.0.0) |
| billing_address_collection | required |
| phone_number_collection.enabled | true |
| automatic_tax.enabled | true |
| allow_promotion_codes | false |
| payment_method_collection | always (subscription mode only) |
| submit_type | auto |
| tax_id_collection.enabled | true |
| tax_id_collection.required | if_supported |
| consent_collection.terms_of_service | required |
| name_collection.individual.enabled | true |
| integration_identifier | hosted_mobile_app_0002 |
| origin_context | mobile_app |
| branding_settings.background_color | #FEE403 |
| branding_settings.button_color | #17132B |
| branding_settings.font_family | default |
| branding_settings.border_style | rounded |
| branding_settings.logo.type | file |
| branding_settings.logo.file | file_1UMmiGGxsADilKuOzfFVswWD |
| custom_text.terms_of_service_acceptance.message | By booking with VELORA HAND & STONE BODYWORK SPA, you agree to these Policies & Terms. VELORA HAND & STONE BODYWORK SPA may cancel or reschedule a confirmed appointment if needed and will notify you as soon as reasonably possible. Please arrive on time; arriving late may shorten your service or require rescheduling. If you need to cancel or reschedule, please do so as early as possible; late cancellations and no-shows may incur a fee. |

## Setup and Next Steps

1. Add or expose the server-side runtime used by the deployed VELORA application. Do not add a new framework solely for this integration unless that runtime is confirmed.
2. Install/use the Stripe server SDK already supported by that runtime. Do not commit API keys.
3. Store the Stripe secret key in server-side secret storage. If the project uses Vite, browser-accessible variables must use the `VITE_` prefix; the Stripe secret key must remain server-only and must not use that prefix.
4. Leave the Stripe API version unspecified when initializing the SDK.
5. Add the Checkout Session creation call using the configured parameters above.
6. Use `payment` for one-time wellness products and `subscription` for recurring VELORA memberships. Only include `payment_method_collection: always` for subscriptions.
7. Use real VELORA success/cancel URLs and real Stripe Price IDs.
8. Configure Stripe webhook handling in the application's existing server/runtime if it already exists; do not add duplicate webhook infrastructure.
9. Verify automatic tax eligibility/registrations and applicable state/local tax treatment before production use.

## Project Structure

Current repository structure relevant to Stripe:

- `api/.gitkeep` — empty API directory; no server endpoint exists.
- `integrations/.gitkeep` — empty integrations directory.
- `velora/.gitkeep` — empty VELORA directory.
- `README.md` — identifies this repository as a central repository for VIVIA/VELORA integrations.

No new application server files were created because no existing server framework could be verified.

## How the Integration Will Work

VELORA will create a server-side Stripe Checkout Session from the existing application runtime. The session will use Hosted Checkout, collect the configured customer/billing information, and route the customer to the VELORA success or cancel page. Stripe will process the payment or recurring subscription. The application's existing fulfillment/webhook flow should then update the booking or membership state.

## Testing

Use Stripe test mode and Stripe's documented test payment methods for development. Never place test or live secret keys in source control.

Before production:
- verify the real Price IDs;
- verify success and cancel URLs;
- test successful one-time checkout;
- test successful subscription checkout;
- test declined/failed payments;
- verify webhook fulfillment and idempotency;
- verify automatic-tax behavior.

## Resources

- https://support.stripe.com
- https://docs.stripe.com/mcp
