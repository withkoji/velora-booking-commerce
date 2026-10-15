# VIVIA Rentals — Repository Database Documentation

## 1. Purpose

The VIVIA Rentals database is the operational source of truth for residential rental listings, applicants, properties, owners/partners, leasing activity, payments, documents, communications, and syndication status.

The repository documentation defines the canonical data model and the boundaries between public rental content, internal operations, and external integrations.

**Brand:** VIVIA Rentals  
**Operating model:** Residential rental/property management and leasing operations  
**Primary promise:** Secure • Simple • Connected

## 2. Data ownership model

The database should distinguish between:

- **Property data** — physical asset and unit information.
- **Listing data** — public marketing representation of a property.
- **Applicant/renter data** — people applying for or occupying a property.
- **Lease data** — lease lifecycle and signed-document references.
- **Payment data** — application, holding, deposit, rent, and other payment events.
- **Owner/partner data** — property ownership or management relationship.
- **Operations data** — tours, self-tour access, follow-ups, tasks, approvals, and exceptions.
- **Integration data** — external IDs and synchronization state for HubSpot, Stripe, Fillout, Zite, syndication providers, email, and other connected systems.

External systems may process or display data, but the VIVIA database should maintain stable internal identifiers and integration mappings.

## 3. Core entities

### Properties

Represents the physical rental property or unit.

Recommended fields:

| Field | Type | Purpose |
|---|---|---|
| Property ID | UUID/string | Stable internal identifier |
| Property Title | Text | Public title, e.g. `4 Beds | 2 Baths | 1,331 Sq Ft` |
| Property Status | Enum | Draft, Active, Pending, Leased, Unavailable, Archived |
| Property Type | Enum/text | Single-family, apartment, townhouse, condo, etc. |
| Street Address | Text | Street/unit address |
| City | Text | City |
| State | Text | State |
| ZIP | Text | Postal code |
| Bedrooms | Number | Bedroom count |
| Bathrooms | Decimal | Bathroom count |
| Square Feet | Number | Living area |
| Base Rent | Currency | Advertised monthly rent |
| Security Deposit | Currency | Required security deposit |
| Availability Date | Date | First available date |
| Owner/Partner ID | Relation | Responsible owner/partner |
| Pets Allowed | Boolean | Pet policy flag |
| Description | Long text | Public listing description |
| Created At | Timestamp | Record creation |
| Updated At | Timestamp | Last modification |

### Listings

Represents a marketing/listing instance for a property.

Recommended fields:

- Listing ID
- Property ID
- Public Listing URL
- Listing Status
- Listing Source
- Syndication Status
- Syndication Last Updated
- Application URL
- Tour URL
- Featured/Published flag
- Public Description
- Amenities
- Appliances
- Neighborhood Information
- Photos/Media references
- External Listing IDs
- Created At
- Updated At

A property can have more than one listing channel.

### Owners / Partners

Represents the owner, property partner, or account responsible for a property.

Recommended fields:

- Owner/Partner ID
- Legal/Display Name
- Organization
- Email
- Phone
- Mailing Address
- Relationship Type
- Property IDs
- Account Status
- Verification Status
- Created At
- Updated At

Do not publish private owner information on public listing pages.

### Applicants

Represents a person applying for a rental.

Recommended fields:

- Applicant ID
- First Name
- Last Name
- Email
- Phone
- Property ID
- Application Status
- Application Submitted At
- Screening Status
- Screening Decision
- Screening Completed At
- Primary/Co-Applicant flag
- External Application ID
- Created At
- Updated At

Sensitive application information should remain access-controlled and should not be duplicated into public listing data.

### Applications

Represents an application transaction/process rather than the person.

Recommended fields:

- Application ID
- Property ID
- Primary Applicant ID
- Application Status
- Payment Status
- Application Fee Amount
- Adult Applicant Count
- Submitted At
- Reviewed At
- Decision
- Decision Reason
- External Form ID
- External Payment ID
- Created At
- Updated At

Current application fee default: **$75 per adult**.

### Leases

Represents the lease lifecycle for an approved renter.

Recommended fields:

- Lease ID
- Property ID
- Applicant/Renter ID
- Lease Status
- Start Date
- End Date
- Monthly Rent
- Security Deposit
- Signed At
- Lease Document Reference
- Renewal Status
- Move-In Status
- Created At
- Updated At

Lease documents should be referenced securely; do not store public document links when access is restricted.

### Payments

Represents each financial event.

Recommended fields:

- Payment ID
- Property ID
- Applicant/Renter ID
- Application ID
- Lease ID
- Payment Type
- Amount
- Currency
- Status
- Provider
- External Payment ID
- External Customer ID
- Invoice ID
- Paid At
- Refunded At
- Refund Amount
- Failure Reason
- Created At
- Updated At

Payment types may include:

- Application Fee
- Holding Fee
- Security Deposit
- Rent
- Move-In Balance
- Other Approved Charge

Payments should be stored as individual events. Do not overwrite historical payment records to represent a new transaction.

### Tours / Self-Tour Access

Represents property-tour scheduling and access.

Recommended fields:

- Tour ID
- Property ID
- Applicant ID
- Tour Type
- Scheduled Start
- Scheduled End
- Access Status
- Access Credential Reference
- Check-In At
- Check-Out At
- Cancellation Reason
- Created At
- Updated At

Credentials should be short-lived, revocable, and stored as references or hashes where possible.

### Communications

Represents operational messages.

Recommended fields:

- Communication ID
- Applicant/Renter ID
- Property ID
- Channel
- Message Type
- Recipient
- Subject
- Template ID
- Delivery Status
- External Message ID
- Sent At
- Failed At
- Failure Reason

Channels may include email, SMS, and internal notifications.

### Documents

Represents secure document metadata.

Recommended fields:

- Document ID
- Document Type
- Related Entity Type
- Related Entity ID
- Storage Reference
- Version
- Status
- Uploaded At
- Expires At
- Access Classification

Do not store credentials, payment secrets, webhook secrets, or API keys in document metadata.

### Syndication

Tracks publishing to rental marketplaces.

Recommended fields:

- Syndication ID
- Property ID
- Channel
- External Listing ID
- Status
- Published URL
- Last Submitted At
- Last Verified At
- Last Error
- Sync Version

A failed syndication must not automatically mark the underlying property as unavailable.

## 4. Recommended relationships

Core relationship map:

```
Owner/Partner
    │
    └──< Properties
             │
             ├──< Listings
             ├──< Applications
             │       └──< Applicants
             ├──< Tours
             ├──< Leases
             │       └──< Payments
             ├──< Payments
             ├──< Documents
             └──< Syndication
```

Applicants may have multiple applications over time. A property may have multiple listings and syndication records.

## 5. Status model

### Property

```
Draft → Active → Pending → Leased
                 ↘
                  Unavailable
Draft/Active/Pending/Leased → Archived
```

### Application

```
Started
  ↓
Payment Initiated
  ↓
Submitted
  ↓
Processing
  ↓
Approved / Declined
```

### HubSpot lifecycle mapping

VIVIA's operational HubSpot pipeline uses:

| Event | HubSpot stage |
|---|---|
| Checkout Started | Lead |
| Payment Initiated | Application Submitted |
| Payment Successful | Processing |
| Screening Approved | Qualified Lead |
| Lease Sent | Opportunity |
| Payment Verified + Lease Signed | Closed Won |

The database should preserve the underlying event and entity state even when HubSpot stage changes.

## 6. Payment rules

Current default rental amounts:

- Application fee: **$75 per adult**
- Holding fee: **$500**
- Security deposit: **$1,000**

Property-specific amounts override defaults when explicitly configured.

Move-in charges should remain separately identifiable. For example:

```
Rent
+ Security Deposit
+ Holding Fee / Remaining Balance
= Total Move-In Amount
```

If a holding fee is credited toward the deposit, record the credit explicitly rather than changing the original payment amount.

Every successful payment should have a corresponding payment record and invoice/receipt reference when supported by the payment provider.

## 7. Integration mapping

The database should maintain external identifiers rather than replacing internal IDs.

| System | Purpose | Store |
|---|---|---|
| HubSpot | CRM and workflow automation | Contact/Company/Deal IDs, sync status |
| Fillout | Applications/forms | Form/submission IDs |
| Stripe | Payments/invoices | Customer/payment/invoice IDs |
| Square | Alternate payment processing where enabled | Customer/payment/order IDs |
| Zite | Operational database/app layer | Record/table IDs |
| Listing channels | Rental syndication | External listing IDs/URLs |
| Gmail/Email | Communications | Message/thread references where applicable |
| Slack | Internal operations | Channel/event references where applicable |

Secrets, API keys, webhook URLs, and authentication credentials belong in environment/secret management, not database records or repository source.

## 8. Event architecture

Major events should be emitted as structured events so integrations can react without duplicating business logic.

Recommended event names:

- `property.created`
- `property.updated`
- `listing.published`
- `listing.updated`
- `application.started`
- `application.submitted`
- `payment.initiated`
- `payment.succeeded`
- `payment.failed`
- `screening.approved`
- `screening.declined`
- `lease.sent`
- `lease.signed`
- `payment.verified`
- `move_in.completed`
- `tour.scheduled`
- `tour.cancelled`
- `syndication.published`
- `syndication.failed`

Events should include:

- Event ID
- Event type
- Entity type
- Entity ID
- Timestamp
- Source system
- Idempotency key
- Version
- Sanitized payload

Never include secrets or unnecessary sensitive applicant data in event payloads.

## 9. Public vs. private data

### Public

Allowed on rental listing pages:

- Property Title
- Beds/Baths/Square Feet
- Rent
- Availability
- Amenities
- Appliances
- Neighborhood context
- Photos
- Public tour/application CTA

### Private/internal

Keep restricted:

- Applicant screening details
- Private owner information
- Payment provider IDs
- Internal CRM IDs
- Application documents
- Lease documents
- Access credentials
- Webhook URLs
- API keys/secrets
- Internal notes
- Security/access logs

## 10. Audit and data integrity

Every mutable operational record should support:

- Created At
- Updated At
- Created By where applicable
- Updated By where applicable
- Status history for important workflows
- External synchronization status where applicable

Financial and compliance-sensitive records should be append-oriented. Corrections should create an auditable adjustment rather than silently rewriting historical facts.

Use idempotency keys for webhook-driven writes to prevent duplicate payments, applications, or lifecycle events.

## 11. Security requirements

- Use least-privilege access.
- Encrypt sensitive data in transit and at rest where supported.
- Keep credentials in secret/environment storage.
- Never commit secrets to Git.
- Do not expose internal IDs on public pages unless required.
- Validate authorization server-side for applicant, renter, owner, and staff actions.
- Log security-relevant events without logging passwords, tokens, payment secrets, or sensitive form responses.
- Use short-lived/revocable access credentials for self-tour workflows.
- Verify webhook signatures before processing trusted external events.
- Apply rate limiting and bot protection to public application, account, and booking-style endpoints.
- Retain only the data needed for the business and legal/operational requirements.

## 12. Source-of-truth rules

1. Internal VIVIA identifiers remain stable even if an external platform changes its ID.
2. Payment providers are authoritative for payment-processing status; VIVIA records the resulting business event.
3. HubSpot is authoritative for CRM workflow stage, not for the complete property or payment ledger.
4. Public listing channels are distribution endpoints, not the master property database.
5. Application systems provide application submissions; VIVIA retains the application lifecycle and external submission reference.
6. Lease documents remain in controlled document storage; the database stores metadata and secure references.
7. Integration failures must be retryable and observable.

## 13. Recommended repository structure

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

This document is the high-level database contract. Implementation-specific schemas should live beneath `vivia/database/` and remain consistent with this model.

## 14. Implementation checklist

- [ ] Create stable internal IDs for all core entities.
- [ ] Define property/listing separation.
- [ ] Define applicant/application separation.
- [ ] Define lease/payment relationships.
- [ ] Add external ID mapping fields.
- [ ] Add status and audit fields.
- [ ] Add webhook idempotency handling.
- [ ] Add payment reconciliation.
- [ ] Add syndication status tracking.
- [ ] Add secure document references.
- [ ] Add role-based access controls.
- [ ] Add event logging.
- [ ] Validate public/private field boundaries.
- [ ] Add automated schema validation.
- [ ] Add integration tests for HubSpot, payment, application, and syndication events.

## 15. Phase alignment

VIVIA Rentals is **Phase 2** of the VIVIA/VELORA platform roadmap. VELORA By SJ / massage and wellness marketplace remains Phase 1.

The VIVIA database should therefore be implemented as a separate business domain while reusing shared platform conventions for authentication, events, integrations, security, validation, and deployment.

**Document status:** Repository design baseline  
**Last reviewed:** 2026-10-04
