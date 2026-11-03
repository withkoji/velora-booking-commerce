# Stripe sandbox release sequence

This change prepares a sandbox candidate. No live release or fulfillment is authorized by these checks.

1. Coordinate #35 now; finish ownership/source links (#30/#40) with OpenAPI PR #1. Generated specifications stay upstream-managed.
2. Complete #31/#41 compatibility review against a pinned schema AND the runtime SDK API version. Resolve exceptions explicitly before promotion.
3. Align profile, runtime, guards and tests (#32). Automatic tax is disabled in the canonical sandbox profile; no Tax API access is needed in that mode. Enabling tax must restore the registration requirement. This is not production tax approval.
4. Require passing Ruby tests and pinned profile comparison (#33/#37). Review changes to the pinned profile revision deliberately. The comparison catches configured-field drift; it does not prove Stripe API acceptance or generated-spec integrity.
5. Perform #38 prerequisites before #34: identify the actual host, configure sandbox credentials, approved terms in Stripe Dashboard, the $25/month Price, account-owned branding file, working redirects, signing secret and persistent receipt storage. Do not provision a second payment path.
6. Complete #34/#42 against the exact deployed candidate: hosted presentation/terms, success and cancellation redirects, signed checkout.session.completed, duplicate delivery including restart, unpaid/failed events with no fulfillment, live-key and live-event rejection. Capture redacted Session/event IDs and run links. An assigned failure remains a release blocker.
7. Merge the matching reference/runtime changes in documented order; deploy only the tested revision, repeat acceptance if the deployed revision/configuration changes, finish #38 handoff, and record #39 monitoring/rollback results in #20. Revert the runtime/profile pair if compatibility, redirects, signature checks, deduplication or sandbox restrictions regress.

#36 label hygiene is independent. #43 should establish this order before further parallel implementation. #29 closes only after children are completed or explicitly deferred; acceptance/security failures cannot be deferred into a release claim.

## Compatibility evidence and remaining exception

Inspected `withkoji/openapi-stripe` revision `0fcde96d7bde2b5d82f32016cb410a4c5402a603`, GA public spec `2026-10-28.endive`. Its Session-create schema includes the profile's configured fields, including submit_type=book in subscription mode, branding, name collection, promotion consent and saved-payment settings. Schema presence does not prove account access, branding-file existence or successful execution.

The GA spec's ui_mode enum uses hosted_page, not hosted. Stripe Ruby v19.6.3 (revision `9b2314f9a21d6bbaa27c27123e3b799f93b5dc45`) defaults to API `2026-08-26.dahlia`. Keep the existing hosted intent pending version-specific validation; do not mechanically replace it using a newer GA enum. #31/#41 remain open until this exception and actual sandbox request acceptance are evidenced.

## Scope boundaries

This is a recurring membership sandbox flow. Shopify/Apntly remain the designated appointment deposit route. Receipt recording does not activate membership or confirm appointments. Authorization, subscription lifecycle, fulfillment, reconciliation, rate limits and production operations remain live-release blockers under #20/#12.

## Evidence still needed

- Passing candidate CI link (including pinned profile comparison).
- Version-specific API compatibility evidence.
- Actual deployment host/revision and configured-resource verification.
- All #34 sandbox evidence; final #42 boundary review.
