# VELORA Booking Commerce

Public architecture and integration documentation for **VELORA By SJ**, a wellness-service marketplace connecting customer discovery, provider availability, appointment booking, commerce, payments, and CRM lifecycle automation.

> **Core rule:** One customer journey. One booking. One authoritative payment path.

## Overview

VELORA Booking Commerce coordinates multiple systems while keeping each platform responsible for its own authoritative records.

| System | Responsibility |
| --- | --- |
| **VELORA By SJ / Zite** | Public marketplace, service discovery, provider profiles, guest experience |
| **VELORA Operations / Zite** | Internal provider, booking, membership, commission, payout, and integration operations |
| **Shopify** | Products, customers, cart, checkout, payments, orders, gift cards, order status |
| **Apntly** | Appointment scheduling, provider availability, deposit configuration, booking confirmation, booking reference/code |
| **Fillout / Zite Workflow** | Secure synchronization of approved Shopify events into VELORA operations |
| **HubSpot** | CRM and customer/provider lifecycle automation |
| **Stripe Connect** | Designated marketplace/provider payment and payout workflows only |

VELORA does **not** duplicate Shopify orders or treat a cart event as proof of payment or appointment confirmation.

## Customer Booking Journey

```text
Home
  → Find Service
  → Find Provider
  → Choose Studio / Mobile / In-Home
  → Select Date & Time
  → Enter Guest Details
  → Review Full Service Price
  → Review 50% Deposit
  → Review Remaining Balance
  → Continue to Shopify / Apntly Checkout
  → Deposit Payment
  → Shopify Order Verification
  → Apntly Booking Verification
  → Booking Confirmation
  → Booking Code
  → Appointment
  → Staff/Provider Verifies Booking Code
  → Remaining Balance Confirmed
  → Appointment Completed
```

**Cart creation alone never confirms an appointment.** A booking becomes confirmed only after the required payment state and appointment record have been verified through their authoritative systems.

## Services

| Service | Duration | Full Price | 50% Deposit | Remaining Balance |
| --- | ---: | ---: | ---: | ---: |
| Swedish Massage | 60 min | $120 | $60 | $60 |
| Deep Tissue Massage | 60 min | $140 | $70 | $70 |
| Hot Stone Massage | 75 min | $160 | $80 | $80 |
| Prenatal Massage | 60 min | $130 | $65 | $65 |
| Therapeutic Bodywork Session | 60 min | $150 | $75 | $75 |
| Relaxation & Stress Relief | 60 min | $120 | $60 | $60 |
| Mobile Massage — In-Home | 60 min | $175 | $87.50 | $87.50 |
| Couples Massage | 60 min / 2 guests | $240 | $120 | $120 |
| Wellness Package — 3 Sessions | Package | $330 | $165 | $165 |
| Gift Cards | — | Starting at $50 | Not applicable | Not applicable |

Gift-card purchases are excluded from appointment-deposit calculations.

## Booking State Machine

Supported booking states:

```text
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
```

Additional terminal or exception states:

- Rescheduled
- Cancelled
- Refunded

### State invariants

- `Cart Created` ≠ `Appointment Confirmed`
- `Deposit Pending` ≠ `Deposit Paid`
- Payment success must be verified from an authoritative payment/order event.
- Appointment confirmation must be verified against the appointment system.
- Payment and booking webhooks must be idempotent.
- Duplicate events must not create duplicate bookings, orders, payments, commissions, or payouts.

## Shopify — Commerce System of Record

Shopify owns:

- Products and service products
- Customers
- Cart and checkout
- Payment processing
- Orders and order status
- Gift cards

VELORA may retain Shopify identifiers required for synchronization, including:

```text
shopify_customer_id
shopify_product_id
shopify_variant_id
shopify_cart_id
shopify_checkout_reference
shopify_order_id
shopify_order_number
shopify_payment_status
```

These references associate VELORA operational records with Shopify. They do not replace Shopify's authoritative commerce records.

## Apntly — Appointment System

Apntly manages supported appointment functions:

- Service booking
- Provider availability
- Appointment date and time
- 50% deposit configuration
- Booking confirmation
- Booking reference/code

VELORA can associate external appointment identifiers with operational booking records:

```text
apntly_booking_id
apntly_service_id
apntly_provider_id
apntly_booking_status
booking_code
```

## Shopify Webhook Processing

The existing synchronization path begins with Shopify commerce activity and feeds approved booking data into the VELORA operations layer.

For a cart-creation event, the integration should:

1. Verify the webhook signature.
2. Reject invalid requests.
3. Extract the Shopify cart identifier.
4. Check whether the event/cart has already been processed.
5. Create or update the pending booking/cart record.
6. Match the service/product.
7. Match the provider when available.
8. Store the full service price.
9. Store the expected 50% deposit.
10. Store the remaining balance.
11. Set the booking to `Cart Created` or `Deposit Pending`.
12. **Do not** mark the payment successful.
13. **Do not** confirm the appointment.

An authoritative successful Shopify order/payment event should then locate the pending booking, verify the expected amount, record the verified deposit, transition the booking to `Deposit Paid`, verify the corresponding Apntly appointment, and only then transition it to `Appointment Confirmed` and store the booking reference/code.

## Payment Model

For eligible appointment services:

```text
deposit_percentage = 50
deposit_amount = service_price × 0.50
remaining_balance = service_price − verified_deposit
```

Operational payment records may track:

```text
service_price
deposit_percentage
deposit_amount
deposit_paid
deposit_paid_at
remaining_balance
remaining_balance_paid
payment_source
payment_status
shopify_order_id
stripe_payment_id
refund_amount
```

Gift cards do not use the appointment-deposit calculation.

### Payment routing

Every booking has exactly one designated payment source:

- `shopify_apntly` — existing VELORA booking flow
- `stripe_connect` — specifically configured marketplace/provider payment flows

The same booking must never be processed through both payment systems.

## Provider Marketplace

Guests can discover providers by supported marketplace criteria such as:

- State
- City
- County
- Service
- Studio availability
- Mobile availability
- In-home availability
- Available today
- Same-day availability

Approved provider profiles may expose fields such as:

```text
provider_name
professional_title
profile_photo
bio
city
county
state
service_area
studio_available
mobile_available
home_service_available
available_today
same_day_booking
next_available
membership_status
```

VELORA must not invent, infer, or display unverified licenses, certifications, or professional credentials.

## Mobile / In-Home Bookings

Mobile appointments can collect the information required to perform the appointment, including guest contact information, service, provider, appointment date/time, authorized service address, and access instructions.

A mobile-service address is **appointment information**. It must not automatically be reused as a physical-product shipping address.

## Provider Membership

Provider onboarding follows:

```text
Apply
→ Admin Review
→ Approved
→ 30-Day Free Trial
→ $25/Month Subscription
→ Active Provider
```

Supported membership states:

```text
Pending Approval
Approved
Trial
Active
Past Due
Suspended
Cancelled
```

## Marketplace Commission

Eligible marketplace bookings use a **25% platform commission**.

Operational accounting may track:

```text
gross_service_amount
platform_commission_rate = 25%
platform_commission_amount
provider_earnings
refund_adjustments
payout_status
```

Final commission and provider earnings must be calculated from a **verified payment transaction**, never from cart creation or an unverified checkout.

## VELORA Operations

The internal operations application is responsible for authorized management of:

- Providers and provider applications
- Customers
- Services and availability
- Appointments and bookings
- Deposits and remaining balances
- Shopify order references
- Apntly booking references and booking codes
- Provider memberships
- Platform commissions
- Provider earnings and payout status
- Webhook events
- Failed integrations
- CRM events

Suggested operational dashboard metrics include:

- Bookings Today
- Upcoming Bookings
- Deposits Paid
- Deposits Pending
- Balances Due
- Active Providers
- Providers on Trial
- Past-Due Memberships
- Marketplace Revenue
- Provider Earnings
- Failed Webhook Events

## Provider Dashboard & Authorization

Providers should receive access only to records they are authorized to view. A provider dashboard may include today's appointments, upcoming appointments, requested service, studio/mobile status, authorized mobile appointment address, guest name, booking code, deposit status, balance due, appointment status, and provider earnings.

Provider-facing clients must never receive Shopify administrative credentials or other server-side secrets.

## HubSpot CRM Events

Permitted lifecycle events may include:

```text
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
```

Only data required for the CRM workflow should be transmitted. API secrets, full payment credentials, and unnecessary sensitive information must not be sent to HubSpot.

## Customer Experience

Primary public navigation:

```text
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
```

Recommended homepage sequence:

1. Hero
2. Find a Service
3. Available Today
4. Featured Services
5. Provider Directory
6. Studio or Mobile
7. Wellness Package
8. Gift Cards
9. How Booking Works
10. Wellness Content
11. About VELORA
12. Contact
13. Book Now CTA

## Security Requirements

This is a **public repository**. Secrets and private credentials must never be committed.

Never expose:

- Shopify Admin API access tokens
- Client secrets
- Webhook signing secrets
- Stripe secret keys
- Apntly private credentials
- Zite credentials
- HubSpot private access tokens
- CI/CD tokens
- Production environment secrets

Secrets must remain server-side in approved secret-management or environment-variable systems. Never place them in public frontend code, HTML, URLs, browser storage, customer-readable fields, documentation examples, commits, issues, or pull requests.

If a credential has previously been exposed, revoke/rotate it rather than reusing it.

An `.env.example` file may document required environment-variable **names only** and must never contain production values.

## Integration Design Principles

All integrations should follow these rules:

1. Verify authenticity before processing external events.
2. Validate required fields and reject malformed input.
3. Use stable external identifiers for reconciliation.
4. Make webhook handlers idempotent.
5. Separate pending, verified, and completed states.
6. Never infer payment success from frontend activity.
7. Never infer appointment confirmation from cart creation.
8. Enforce record-level authorization for guests and providers.
9. Log integration failures without logging secrets.
10. Route failed or incomplete events for administrative review.

## Repository Structure

As implementation files are added, the repository can follow this structure:

```text
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
```

## Development Status

The public repository currently documents the intended VELORA booking-commerce architecture. The existing **VELORA By SJ** application serves the guest/customer marketplace, while **VELORA Operations** serves internal provider and administrative workflows.

Direct Zite build-tool availability is separate from deployed app availability. Integration changes should be applied through authorized development tooling or the Zite editor without exposing private credentials in this repository.

## Contributing

Before submitting a change:

- Never commit production credentials or customer secrets.
- Preserve the system-of-record boundaries described above.
- Preserve webhook idempotency.
- Add tests for payment and booking-state transitions when implementation code is introduced.
- Do not treat cart creation as payment confirmation.
- Do not treat payment initiation as payment success.
- Validate authorization before returning guest/provider records.
- Document environment-variable names without documenting their secret values.

## License & Brand Notice

Copyright © VELORA By SJ. All rights reserved.

This repository is publicly visible for architecture and integration development. Public visibility does not grant permission to use VELORA branding, customer information, provider information, proprietary business assets, or private operational data.
