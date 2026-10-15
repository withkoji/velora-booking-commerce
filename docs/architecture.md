# VELORA Platform Logic

## Request flow
Guest/provider/admin request -> authorization -> domain validation -> Zite persistence -> payment provider -> domain event -> HubSpot event sink -> notifications.

## Booking lifecycle
draft -> pending_payment -> confirmed -> completed
draft/pending_payment/confirmed -> cancelled
completed -> refunded

A booking is created only for an active service. End time is derived from service duration. The default booking deposit is 50% of the booking total.

## Payment lifecycle
pending -> paid
pending -> failed
paid -> partially_refunded -> refunded
paid -> refunded

Payment state changes must be driven by verified provider events rather than client-side success screens.

## Authorization
Guest, provider, and admin roles use explicit permissions. Admin has full permission; self-service permissions are scoped to the authenticated actor.

## Event flow
Domain events use a unique event ID, event type, aggregate ID, timestamp, and event payload. Major booking/payment/provider/guest events can be forwarded to the configured HubSpot automation webhook.

## Webhook security
Stripe webhook signatures are checked with HMAC-SHA256, constant-time comparison, and a five-minute replay tolerance. The signing secret must come from deployment secret storage.

## Secrets
Never commit API keys, OAuth credentials, Stripe secrets, HubSpot tokens, or webhook signing secrets. `api/env.example` contains names only.


## Private booking code and session ticket
After a verified deposit payment confirms a booking, the booking code stays hidden. The guest sees a request action: "Request your booking code now". Management must approve the request before the code can be released. Booking codes are generated with cryptographic randomness and persisted as SHA-256 hashes rather than plaintext.

Release activates the session ticket. Provider validation requires an authenticated provider action and checks that the ticket is active, unexpired, unused, and that the submitted code matches the stored hash. The code must never appear in public booking payloads, URLs, client logs, analytics, or source code.
