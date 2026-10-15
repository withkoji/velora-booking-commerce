VELORA Booking Commerce

Public integration architecture for the VELORA By SJ wellness marketplace.

VELORA provides a unified customer journey for discovering wellness services, finding providers, selecting studio or mobile appointments, booking services, paying required deposits, and managing appointments.

System Architecture

VELORA uses several specialized platforms rather than duplicating commerce, booking, and CRM responsibilities.

Platform	Primary Responsibility
VELORA By SJ / Zite	Customer marketplace, provider discovery, customer experience
VELORA Operations / Zite	Provider and administrative operations
Shopify	Products, customers, checkout, payments, orders, and gift cards
Apntly	Appointment scheduling, availability, deposit configuration, and booking references
Fillout / Zite Workflow	Secure synchronization of approved commerce events
HubSpot	CRM and lifecycle automation
Stripe Connect	Designated marketplace/provider payment and payout workflows

Customer Booking Flow

VELORA By SJ
      ↓
Find Service
      ↓
Find Provider
      ↓
Studio / Mobile / In-Home
      ↓
Select Date & Time
      ↓
Guest Details
      ↓
Review Service Price
      ↓
Review 50% Deposit
      ↓
Shopify / Apntly Checkout
      ↓
Payment Verification
      ↓
Appointment Verification
      ↓
Booking Confirmation
      ↓
Booking Code
      ↓
Appointment
      ↓
Remaining Balance
      ↓
Completed

Creating a cart does not constitute a confirmed appointment.

Payment and appointment confirmation must be verified through the appropriate authoritative systems before a booking is marked confirmed.

Services

VELORA supports wellness services including:

* Swedish Massage
* Deep Tissue Massage
* Hot Stone Massage
* Prenatal Massage
* Therapeutic Bodywork
* Relaxation & Stress Relief
* Mobile / In-Home Massage
* Couples Massage
* Multi-session Wellness Packages
* Gift Cards

Appointment services can use a 50% booking deposit, with the remaining balance tracked separately.

Gift-card purchases are excluded from appointment-deposit calculations.

Booking Lifecycle

The application supports a controlled booking lifecycle:

Draft
→ Cart Created
→ Checkout Started
→ Deposit Pending
→ Deposit Paid
→ Booking Pending
→ Appointment Confirmed
→ Booking Code Issued
→ Checked In
→ Balance Due
→ Paid in Full
→ Completed

Additional lifecycle states include:

Rescheduled
Cancelled
Refunded

Important state rules:

* Cart Created does not equal Appointment Confirmed.
* Deposit Pending does not equal Deposit Paid.
* Payment success must be independently verified.
* Appointment confirmation must be independently verified.
* Webhook processing should be idempotent.

Shopify Integration

Shopify serves as the commerce system of record for:

* Products
* Service products
* Customers
* Cart
* Checkout
* Payments
* Orders
* Gift cards
* Order status

VELORA stores only the external Shopify identifiers and operational information required to associate marketplace activity with authoritative Shopify records.

VELORA must not create duplicate Shopify orders.

Apntly Integration

Apntly manages supported appointment functionality, including:

* Service booking
* Provider availability
* Appointment dates
* Appointment times
* Deposit configuration
* Booking confirmation
* Booking references/codes

External booking identifiers can be associated with the corresponding VELORA booking record.

Payment Model

For eligible appointment services:

Deposit = Service Price × 50%
Remaining Balance = Service Price − Verified Deposit

Payment records distinguish between:

* Expected deposit
* Verified deposit payment
* Remaining balance
* Verified balance payment
* Refunds
* Payment status

Financial state changes must originate from verified payment events rather than browser activity or cart creation.

Payment Routing

A booking uses one designated payment path.

Shopify / Apntly

or, for specifically configured marketplace workflows:

Stripe Connect

A single booking must never be processed simultaneously through both payment paths.

Provider Marketplace

Customers can discover providers using criteria such as:

* State
* City
* County
* Service
* Studio availability
* Mobile availability
* In-home availability
* Available today
* Same-day availability

Provider profiles may contain approved public information such as professional title, biography, service area, appointment options, and next availability.

VELORA does not invent or infer provider licenses, certifications, or professional credentials.

Mobile Appointments

Mobile and in-home appointments may require an authorized service location and access instructions.

Service-location information is appointment data and must be handled accordingly.

It should not automatically be treated as a physical-product shipping address.

Provider Membership

The provider onboarding lifecycle supports:

Apply
→ Administrative Review
→ Approved
→ Free Trial
→ Active Membership

Operational membership states can include:

Pending Approval
Approved
Trial
Active
Past Due
Suspended
Cancelled

Marketplace Commission

Eligible marketplace transactions may support platform commission accounting.

Commission and provider earnings must be calculated from verified transactions, never from cart creation or an unverified checkout.

The operations layer can track:

* Gross eligible service amount
* Commission rate
* Platform commission
* Provider earnings
* Refund adjustments
* Payout status

VELORA Operations

The internal operations application manages authorized operational records including:

* Providers
* Provider applications
* Customers
* Services
* Availability
* Appointments
* Bookings
* Deposits
* Outstanding balances
* Shopify order references
* Apntly booking references
* Booking codes
* Provider memberships
* Commissions
* Provider earnings
* Payout statuses
* Webhook events
* Integration failures
* CRM events

Internal operational data is not exposed through the public marketplace.

CRM Integration

Approved lifecycle events can be routed to HubSpot, including:

New Guest
New Provider Application
Provider Approved
Booking Started
Deposit Paid
Appointment Confirmed
Appointment Completed
Provider Trial Started
Provider Membership Activated
Follow-Up Required

Only information necessary for the CRM workflow should be transmitted.

Security

Security boundaries are mandatory throughout this project.

Never commit or expose:

Shopify Admin API access tokens
Client secrets
Webhook signing secrets
Stripe secret keys
Apntly private credentials
Zite credentials
HubSpot private access tokens
CI/CD credentials
Environment secrets

Secrets belong in approved server-side secret-management or environment-variable systems.

Never place secrets in:

* Git repositories
* Public frontend JavaScript
* HTML
* Query-string URLs
* Browser storage
* Customer-readable database fields
* Documentation examples

Previously exposed credentials should be revoked and replaced rather than reused.

Use .env.example files containing variable names only, never real values.

Webhook Principles

Integration endpoints should:

1. Authenticate or verify incoming events.
2. Reject invalid requests.
3. Validate required data.
4. identify the external event or transaction.
5. Prevent duplicate processing.
6. Match the appropriate booking.
7. Update only permitted fields.
8. Preserve authoritative external identifiers.
9. Record processing status.
10. Surface failures for administrative review.

All payment-related webhook processing should be idempotent.

Customer Experience

The public experience is organized around:

Home
Book a Service
Available Today
Find a Provider
Studio & Mobile
Packages
Gift Cards
Wellness
My Appointments
Contact

The goal is a continuous VELORA experience even though commerce, appointment scheduling, marketplace operations, and CRM automation are handled by separate systems.

Core Integration Principle

One customer journey. One booking. One authoritative payment path.

VELORA should prevent:

* Duplicate bookings
* Duplicate orders
* Duplicate payments
* Premature appointment confirmation
* Unauthorized provider data access
* Exposure of administrative credentials

Repository Structure

Recommended structure:

velora-booking-commerce/
├── README.md
├── .gitignore
├── .env.example
├── .github/
│   └── workflows/
├── integrations/
│   ├── shopify/
│   ├── apntly/
│   ├── zite/
│   ├── hubspot/
│   └── stripe-connect/
├── config/
├── docs/
└── tests/

Development Status

VELORA By SJ and VELORA Operations are existing applications.

Current integration work focuses on establishing reliable synchronization among the marketplace, Shopify commerce, appointment scheduling, CRM, and authorized provider operations.

Direct Zite build-tool availability is environment/account dependent and is not required for the deployed applications themselves to continue operating.

Contributing

Before submitting changes:

* Never include production credentials.
* Keep commerce and booking responsibilities separated.
* Preserve idempotency for webhook handlers.
* Add tests for payment and booking-state transitions.
* Do not treat cart creation as payment confirmation.
* Do not treat payment initiation as payment success.
* Validate authorization before returning provider or customer records.
* Document new environment variables without supplying their values.

License

Copyright © VELORA By SJ. All rights reserved.

This repository is publicly visible for development and integration documentation. Public visibility does not grant permission to use VELORA branding, customer information, provider information, or proprietary business assets.
