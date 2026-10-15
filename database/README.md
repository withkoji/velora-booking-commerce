# VIVIA Rentals — Repository Database Documentation

**Secure • Simple • Connected**  
Status: Repository design baseline (revised) • Last reviewed: 2026-10-04

## 1. Purpose

The VIVIA Rentals database is the operational source of truth for rental listings, applicants, properties, owners/landlords, leasing activity, subscriptions, payments, verification, documents, communications, and syndication status. It defines boundaries between public content, internal operations, and external integrations.

## 2. Data ownership model

- **Property** — physical asset/unit.
- **Listing** — public marketing representation of a property.
- **Applicant/renter** — people applying for or occupying a property.
- **Application** — application process and fee.
- **Verification** — identity verification state.
- **Lease** — lease lifecycle and document references.
- **Payment** — application fee, deposit, rent, subscription, other.
- **Subscription** — landlord property management plan.
- **Owner/landlord** — ownership or management relationship.
- **Operations** — tours, tasks, approvals, exceptions.
- **Integration** — external IDs and sync state (HubSpot, Stripe, Fillout, Zite, Square, syndication, email, Slack).

Internal VIVIA identifiers stay stable; external systems are mapped to them.

## 3. Universal tracking ID

Format: `VIVIA-YYYYMMDD-XXXX` (example: `VIVIA-20261002-0001`).  
Application ID format: `APP-YYYYMMDD-NNNN` (example: `APP-20261002-0001`).

`tracking_id` is required on: Applicants, Applications, Verifications, Payments, Leases, Tours, Documents, Communications, Events, and Subscriptions (where applicable). The same value is written to the website, HubSpot, Stripe customer/subscription/invoice/payment metadata, Gmail, Slack, and automation workflows.

## 4. Core entities

### Properties

| Field | Type | Purpose |
|---|---|---|
| property_id | ID | Stable internal identifier |
| property_title | Text | Public title |
| property_status | Enum | Draft, Active, Pending, Leased, Unavailable, Archived |
| property_type | Enum | Single-family, apartment, townhouse, condo, etc. |
| street_address, city, state, zip | Text | Address |
| bedrooms, bathrooms, square_feet | Number | Specs |
| base_rent | Currency | Advertised monthly rent |
| security_deposit | Currency | Per-property |
| availability_date | Date | First available |
| owner_id | Relation | Responsible owner/landlord |
| pets_allowed | Boolean | Pet policy |
| description | Long text | Public description |
| created_at, updated_at | Timestamp | Audit |

### Listings

| Field | Type | Purpose |
|---|---|---|
| listing_id | ID | Listing identifier |
| property_id | Relation | Linked property |
| public_listing_url | URL | Public listing |
| listing_status | Enum | Draft, Published, Paused, Closed |
| listing_source | Text | Origin/channel |
| syndication_status | Enum | Distribution state |
| application_url, tour_url | URL | Public CTAs |
| public_description, amenities, appliances, neighborhood_info | Text | Marketing content |
| media_refs | References | Photos/media |
| external_listing_ids | Map | Channel IDs |
| created_at, updated_at | Timestamp | Audit |

### Owners / Landlords

| Field | Type | Purpose |
|---|---|---|
| owner_id / landlord_id | ID | Stable identifier |
| display_name, organization | Text | Name |
| email, phone, mailing_address | Text | Private contact |
| relationship_type | Enum | Owner, partner, manager |
| property_ids | Relations | Associated properties |
| account_status, verification_status | Enum | State |
| stripe_customer_id | Text | Stripe customer |
| hubspot_id | Text | CRM ID |
| tracking_id | Text | Universal ID |
| created_at, updated_at | Timestamp | Audit |

### Subscriptions

| Field | Type | Purpose |
|---|---|---|
| subscription_id | ID | Internal identifier |
| owner_id / landlord_id | Relation | Subscriber |
| property_id | Relation | Property covered |
| stripe_subscription_id | Text | Stripe subscription |
| stripe_customer_id | Text | Stripe customer |
| plan_lookup_key | Text | `VIVIA-PROPERTY-MANAGEMENT-MONTHLY-25` |
| amount, currency, billing_interval | Value | $25.00 USD monthly; tax behavior auto |
| subscriber_type | Enum | landlord |
| subscriber_status | Enum | active, past_due, canceled |
| service_type | Text | property_management |
| workflow_status | Enum | active, etc. |
| tracking_id | Text | Universal ID |
| environment | Enum | test / live |
| created_at, updated_at | Timestamp | Audit |

### Applicants / Renters

| Field | Type | Purpose |
|---|---|---|
| applicant_id | ID | Stable identifier |
| first_name, last_name, email, phone | Text | Contact |
| customer_type | Enum | renter |
| customer_status | Enum | active, etc. |
| property_id, listing_id | Relation | Property/listing |
| lead_source | Text | Default VIVIA Website |
| workflow_status | Enum | Lifecycle |
| payment_status | Enum | pending, paid, failed, refunded |
| application_fee_status | Enum | pending, paid, failed, refunded |
| deposit_status | Enum | pending, paid, refunded |
| lease_status | Enum | none, sent, signed |
| stripe_payment_status | Text | Last confirmed Stripe status |
| verification_status | Enum | pending, in_progress, verified, failed |
| next_action | Text | Next required step |
| assigned_team | Text | Default VIVIA Leasing |
| automation_source | Text | e.g. stripe |
| last_event | Text | Most recent event type |
| stripe_customer_id | Text | Stripe customer |
| hubspot_id, fillout_submission_id | Text | External IDs |
| tracking_id, application_id | Text | Universal IDs |
| primary_applicant | Boolean | Role |
| created_at, updated_at | Timestamp | Audit |

### Applications

| Field | Type | Purpose |
|---|---|---|
| application_id | ID | APP-YYYYMMDD-NNNN |
| property_id, primary_applicant_id | Relation | Links |
| application_status | Enum | Lifecycle |
| payment_status, application_fee_status | Enum | Fee state |
| application_fee_amount | Currency | $75 per adult |
| adult_applicant_count | Number | Adults screened |
| submitted_at, reviewed_at | Timestamp | Timing |
| decision, decision_reason | Enum/Text | Outcome |
| external_form_id | Text | Fillout |
| stripe_payment_intent_id / invoice_id | Text | Payment references |
| tracking_id | Text | Universal ID |
| created_at, updated_at | Timestamp | Audit |

### Verifications

| Field | Type | Purpose |
|---|---|---|
| verification_id | ID | Identifier |
| applicant_id, application_id | Relation | Links |
| flow_name | Text | VIVIA Rentals — Renter Identity Verification |
| stripe_verification_session_id | Text | Stripe Identity session |
| verification_status | Enum | pending, in_progress, verified, failed |
| checks | Text | Document, ID number, live capture, email, phone |
| verified_at | Timestamp | Completion |
| failure_reason | Text | Internal detail |
| tracking_id | Text | Universal ID |

Raw ID images and document numbers are not stored in the VIVIA database.

### Leases

| Field | Type | Purpose |
|---|---|---|
| lease_id | ID | Identifier |
| property_id, applicant_id | Relation | Links |
| lease_status | Enum | Draft, sent, signed, active, ended |
| start_date, end_date | Date | Term |
| monthly_rent, security_deposit | Currency | Contract amounts |
| signed_at | Timestamp | Signature time |
| document_ref | Secure reference | Metadata only |
| renewal_status, move_in_status | Enum | State |
| tracking_id | Text | Universal ID |
| created_at, updated_at | Timestamp | Audit |

### Payments

| Field | Type | Purpose |
|---|---|---|
| payment_id | ID | Identifier |
| property_id, applicant_id, application_id, lease_id, subscription_id | Relation | Links |
| payment_type | Enum | application_fee, deposit, rent, subscription, holding_fee, other |
| amount, currency | Value | Amount |
| status | Enum | pending, paid, failed, refunded |
| provider | Enum | stripe, square |
| external_payment_id, external_customer_id, invoice_id | Text | Provider references |
| stripe_event_id | Text | Confirming event/idempotency |
| environment | Enum | test / live |
| paid_at | Timestamp | Confirmed provider event only |
| refunded_at, refund_amount | Value | Refunds |
| failure_reason | Text | Failure detail |
| tracking_id | Text | Universal ID |
| created_at, updated_at | Timestamp | Audit |

## 5. Operational entities

- **Tours / Self-Tour Access:** tour_id, property_id, applicant_id, tour_type, scheduled_start/end, access_status, access_credential_reference, check_in/out, cancellation_reason, tracking_id.
- **Communications:** communication_id, applicant_id, property_id, channel, message_type, recipient, subject, template_id, delivery_status, external_message_id, sent_at, failure_reason, tracking_id.
- **Documents:** document_id, document_type, related_entity_type/id, storage_reference, version, status, uploaded_at, expires_at, access_classification, tracking_id.
- **Syndication:** syndication_id, property_id, channel, external_listing_id, status, published_url, last_submitted_at, last_verified_at, last_error, sync_version.

## 6. Status model

### Renter lifecycle

```
lead → application_started → application_submitted → payment_pending
→ payment_successful → screening → qualified → deposit_pending
→ deposit_paid → lease_sent → lease_signed → active_renter
```

`payment_successful` and `deposit_paid` are set only after Stripe confirms payment.

### Property

`Draft → Active → Pending → Leased`; `Unavailable` and `Archived` from any state.

### HubSpot mapping

| VIVIA workflow_status | HubSpot stage |
|---|---|
| lead / application_started | Lead |
| application_submitted / payment_pending | Application Submitted |
| payment_successful / screening | Processing |
| qualified | Qualified Lead |
| lease_sent | Opportunity |
| deposit_paid + lease_signed | Closed Won |

HubSpot advances only after the underlying event is confirmed. The database preserves the entity state even if the HubSpot stage changes.

## 7. Relationships

```
Owner/Landlord ─┬─< Subscriptions
                └─< Properties ─┬─< Listings
                                ├─< Applications ─┬─< Applicants
                                │                 └─< Verifications
                                ├─< Tours
                                ├─< Leases ─< Payments
                                ├─< Payments
                                ├─< Documents
                                └─< Syndication
```

## 8. Payment rules

- Application fee: **$75 per adult**.
- Application fee stays `pending` until Stripe confirms successful payment.
- Invoice creation alone never marks a payment successful.
- A $0 or trial invoice never counts as paying the application fee.
- Security deposits and rent are tracked separately from application fees.
- Holding fee and security deposit amounts are per-property; no global default is assumed.
- If a holding fee is credited toward the deposit, record an explicit credit rather than altering the original payment.
- Every customer-facing payment has an invoice or appropriate Stripe payment record.
- Credit grants apply only to eligible usage-based/billing-meter prices; do not assume they offset standard subscriptions or one-time fees.

Stripe subscription price: $25.00 USD/month, tax not included, tax behavior auto, lookup key `VIVIA-PROPERTY-MANAGEMENT-MONTHLY-25`.

## 9. Integration mapping

| System | Purpose | Stored |
|---|---|---|
| HubSpot | CRM and workflows | Contact/Company/Deal IDs, sync status |
| Fillout | Applications/forms | Form/submission IDs |
| Stripe | Subscriptions, payments, invoices, Identity | Customer, subscription, invoice, payment, verification IDs; environment |
| Square | Alternate payments where enabled | Customer/payment/order IDs |
| Zite | Operational app layer | Record/table IDs |
| Listing channels | Syndication | External listing IDs/URLs |
| Gmail / Slack | Communications / ops | Message/channel references |

Secrets, API keys, and webhook URLs live in secret management, never in records or the repository. Test/sandbox and live environments are kept separate.

## 10. Event architecture

Events:

`property.created`, `property.updated`, `listing.published`, `listing.updated`, `application.started`, `application.submitted`, `payment.initiated`, `payment.succeeded`, `payment.failed`, `invoice.created`, `invoice.paid`, `subscription.created`, `subscription.updated`, `subscription.canceled`, `verification.started`, `verification.verified`, `verification.failed`, `screening.approved`, `screening.declined`, `deposit.paid`, `lease.sent`, `lease.signed`, `move_in.completed`, `tour.scheduled`, `tour.cancelled`, `syndication.published`, `syndication.failed`.

Each event includes: event_id, event_type, entity_type, entity_id, tracking_id, timestamp, source_system, idempotency_key, version, sanitized payload. Never include secrets or unnecessary sensitive applicant data.

## 11. Public vs. private data

**Public:** title, beds/baths/sq ft, rent, availability, amenities, appliances, neighborhood context, photos, public tour/application CTAs.

**Private:** screening and verification details, owner information, payment provider IDs, CRM IDs, application/lease documents, access credentials, webhook URLs, keys, internal notes, security logs.

## 12. Audit and data integrity

- Mutable records carry created_at, updated_at, created_by/updated_by where applicable, status history for key workflows, last_event, and sync status.
- Financial and compliance records are append-oriented; corrections are auditable adjustments.
- Use idempotent writes for webhooks.
- Match existing Stripe customers/subscriptions before creating new ones to avoid duplicates.

## 13. Security requirements

Least-privilege access; encrypt in transit and at rest; no secrets in Git; server-side authorization; verify webhook signatures; log security events without passwords, tokens, payment secrets, or sensitive form data; short-lived revocable self-tour credentials; rate limiting and bot protection on public endpoints; retain only needed data.

## 14. Source-of-truth rules

1. VIVIA internal IDs stay stable even if external IDs change.
2. Stripe is authoritative for payment-processing status; VIVIA records the resulting business event.
3. HubSpot is authoritative for CRM workflow stage only.
4. Listing channels are distribution endpoints, not the master property record.
5. Fillout supplies submissions; VIVIA retains the lifecycle and external reference.
6. Lease documents stay in controlled storage; the database holds metadata and secure references.
7. Integration failures must be retryable and observable.

## 15. Repository structure

```
vivia/
├── database/
│   ├── README.md
│   ├── schema.md
│   ├── entities.md
│   ├── events.md
│   ├── integrations.md
│   └── security.md
├── listings/
├── applications/
├── leases/
└── payments/
```

## 16. Implementation checklist

- [ ] Stable internal IDs and universal tracking_id on all core entities
- [ ] Property/listing and applicant/application separation
- [ ] Subscriptions and Verifications entities
- [ ] Renter metadata fields
- [ ] Lease/payment relationships and external ID mapping
- [ ] Status, audit, and environment fields
- [ ] Webhook idempotency using Stripe event IDs
- [ ] Payment reconciliation (paid only on confirmed Stripe status)
- [ ] Syndication status tracking and secure document references
- [ ] Role-based access controls and event logging
- [ ] Public/private boundary validation and schema validation
- [ ] Integration tests: HubSpot, Stripe, Fillout, syndication

## 17. Phase alignment

VIVIA Rentals is Phase 2 of the VIVIA/VELORA roadmap; VELORA By SJ remains Phase 1. VIVIA is implemented as a separate business domain reusing shared conventions for authentication, events, integrations, security, validation, and deployment.
