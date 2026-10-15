# VELORA Shopify service catalog → Zite

Status: implementation prepared; live Shopify authentication and GitHub secrets are not configured or verified. No live sync has been run.

Destination: Guest Booking → Services in the VELORA H&S BODYWORK SPA account.
Database `14f87f80d78b0a99`, table `teDwGUqase8`.

## Behavior

Trigger: manual GitHub Actions run, or hourly after explicit activation.
Data received: selected Shopify products, variants, descriptions, types, status and prices.
Record created/updated: one Zite service per Shopify variant, matched by Service ID `shopify:<canonical-shop-domain>:<variant-GID>`.
Action: update Service Name, Description, Category and Price. Create new services inactive. Deactivate matched draft/archived products. Existing active services remain active for active products; previously inactive services are never automatically reactivated.
Notification: GitHub Actions reports success/failure and aggregate create/update/unchanged counts. Repository notification preferences control delivery; no client messages are sent.
Next step: operations staff set duration, provider, availability, booking policies and activation inside Zite.
Errors: missing credentials, wrong shop, non-USD currency, duplicate IDs, title collisions, invalid prices, API failures and truncated variant lists stop the run. API response bodies and credentials are never logged.

Provider links, duration, deposit percentage, advance notice, buffers, bookings, payments and policies are not overwritten. The four existing services remain untouched unless their Service IDs are explicitly mapped to verified Shopify variants. Existing titles are never used for automatic matching. Match IDs only after checking title, variant and business meaning; review any near-duplicate catalog entries before importing.

Deleted or unselected Shopify products are not deleted or deactivated in Zite. Review removals manually. Keep inactive products inside the selected query if their status should propagate. At most 100 variants per product are supported; larger products stop the run. The sync reads the complete selected catalog before any writes, but API writes are not transactional: reconcile partial failures and rerun. Never retry a timed-out create blindly. Stable IDs make successful writes safe on subsequent serialized reruns. All writers to this table must use the same identity convention; GitHub concurrency prevents overlap within this repository, not other systems.

## Activation

1. Authenticate Shopify and verify the canonical `*.myshopify.com` store and selected service products. Use an Admin API token with `read_products`. Connected ChatGPT sessions do not populate GitHub secrets.
2. Add repository secrets `SHOPIFY_ADMIN_ACCESS_TOKEN` and `ZITE_API_KEY` using each platform's secure settings. Do not send tokens through chat or commit them. Scope the Zite key to the intended database if supported.
3. Add repository variables `SHOPIFY_SHOP_DOMAIN` (verified canonical domain) and `SHOPIFY_SERVICE_QUERY` (an explicit service-only selection, for example `tag:velora-service` after applying that tag in Shopify). Exclude retail, gift cards, memberships and add-ons unless separately modeled as services. The query must not filter to only active products if draft/archive changes should be reconciled.
4. Merge the reviewed code. Run the workflow with **apply unchecked**. Confirm selected product scope and expected counts; manually inspect the source catalog and resolve collisions. No scheduling occurs while `VELORA_SYNC_ENABLED` is unset.
5. Run once with **apply checked**, inspect Services in Zite, and configure booking readiness. Only then set repository variable `VELORA_SYNC_ENABLED=true` for hourly catalog sync. Remove it to pause. A manual run can still apply changes while scheduling is paused.

GitHub hosts the code and runs the job; this does not deploy an HTTP endpoint or register Shopify webhooks. Checkout uses a pinned commit; the script needs Node 22+ with built-in fetch and no external packages. The Ubuntu runner's supplied Node version must meet that requirement.

The Zite MCP build-tool trial was expired during discovery. This integration uses the separate database REST API; its credentials and live access must still be tested. No plan upgrade is assumed or purchased.

## Validation

Run `node --test integrations/velora-shopify-zite/sync.test.mjs`.
Tests cover inactive creation, preserved booking configuration, rerun behavior, price updates, archived products, duplicate identity/title collisions, invalid variants/prices, and mocked dry-run/apply HTTP calls. Live end-to-end validation remains pending authentication and secrets.

## API references

- https://shopify.dev/docs/api/admin-graphql/2026-07/queries/products
- https://developers.zite.com/api/overview
- https://developers.zite.com/api/records/list-records
- https://developers.zite.com/api/records/create-record
- https://developers.zite.com/api/records/update-record
