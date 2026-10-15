# VIVIA | VELORA Platform Wiki Context

## 1. Overview

This repository contains the shared foundation and application context for two related business platforms:

- **VIVIA Rentals** — residential rental, leasing, property management, applications, screening, tours, payments, leases, and listing operations.
- **VELORA By SJ** — a massage and wellness marketplace connecting guests with wellness providers, services, locations, scheduling, payments, and provider operations.

The implementation is designed around a shared platform foundation while keeping the VIVIA Rentals and VELORA By SJ product domains separated.

## 2. Product Strategy

### Phase 1 — VELORA By SJ

VELORA is the first production-focused product.

Primary flow:

1. Guest selects state.
2. Guest selects city/location.
3. Guest selects provider.
4. Guest selects service.
5. Guest selects optional add-ons.
6. Guest selects date and time.
7. Guest enters guest/contact details.
8. Guest pays the required booking deposit.
9. Payment is matched to the booking.
10. Payment confirmation triggers booking confirmation.
11. Management receives the required operational event.
12. Guest receives confirmation and secure session instructions.
13. Provider can validate the authorized session before service.

### Phase 2 — VIVIA Rentals

VIVIA Rentals follows after the VELORA launch foundation is complete.

Core rental lifecycle:

Listing → inquiry → application → screening → qualification → lease → move-in payments → active tenancy → property management.

## 3. Architecture

The platform is organized into these major areas:

| Area | Purpose |
| --- | --- |
| `velora/` | VELORA product documentation and domain context |
| `vivia/` | VIVIA Rentals product context |
| `api/` | Shared API/domain logic |
| `integrations/` | External service integrations |
| `repository/` | Repository landing/redirect foundation |
| `docs/` | Architecture, routes, release, and operational documentation |
| `.github/workflows/` | CI and package automation |

### Domain separation

VELORA and VIVIA share infrastructure patterns but should not share sensitive business records unless an explicit integration requires it.

Each product should maintain clear ownership of:

- users
- customers/guests
- providers/owners
- bookings/applications
- payments
- notifications
- operational records

## 4. VELORA By SJ

### Guest marketplace

VELORA's public marketplace is designed around:

- State discovery
- City/location discovery
- Provider discovery
- Provider profiles
- Service selection
- Add-ons
- Date/time selection
- Guest details
- Deposit checkout
- Booking confirmation

### Provider operations

Provider functionality includes:

- Provider authentication
- Dashboard
- Profile
- Services
- Availability
- Bookings
- Payouts
- Session validation

### Management operations

Management functionality includes:

- Provider management
- Booking management
- Payment monitoring
- Booking-code requests
- Session-ticket management
- Notifications
- Operational controls

## 5. Secure Booking-Code Flow

A confirmed and paid booking can enter the private booking-code workflow.

### Guest

The guest requests access to the private booking/session code after payment is confirmed.

The public guest application must not expose the plaintext code before authorized release.

### Management

Management reviews the request:

`Requested → Approved → Released`

or:

`Requested → Rejected`

When released:

1. A secure random code is generated.
2. Only a hash of the code is stored.
3. A session ticket is created.
4. The ticket receives an expiration time.
5. The plaintext code is delivered through the approved notification channel.
6. The management interface may display the generated code only as part of the release operation.

### Session ticket

Session tickets support controlled provider/session access.

Expected lifecycle:

`Inactive → Active → Used`

Additional terminal states:

- Expired
- Cancelled

## 6. VIVIA Rentals

VIVIA Rentals is the rental/property-operations domain.

Primary capabilities:

- Rental listing creation
- Listing syndication
- Property information management
- Rental applications
- Applicant screening
- Qualification workflow
- Tour scheduling
- Lease management
- Move-in payments
- Security deposits
- Holding fees where applicable
- Customer communications
- Property management follow-up

### Rental listing structure

A standard listing record should support:

- Property Title
- Address
- City
- State
- ZIP Code
- Monthly Rent
- Security Deposit
- Bedrooms
- Bathrooms
- Square Footage
- Property Type
- Status
- Pets Allowed
- Amenities
- Property Images
- Listing URL
- Applications
- Customers
- Leases
- Listing Syndication
- Follow-Up Tasks
- External listing identifiers
- HubSpot Deal ID

Public listing descriptions should focus on the property, amenities, appliances, neighborhood, and availability. Sensitive operational/payment information should remain in internal systems.

## 7. Routes

### Public routes

- `/`
- `/login`
- `/signup`
- `/states`
- `/states/:state`
- `/cities/:state/:city`
- `/providers`
- `/providers/:providerId`
- `/services`
- `/services/:serviceId`
- `/booking`
- `/booking/service`
- `/booking/add-ons`
- `/booking/date-time`
- `/booking/guest`
- `/booking/checkout`
- `/booking/confirmation`

### Account routes

- `/account`
- `/account/profile`
- `/account/bookings`
- `/account/payments`

### Provider routes

- `/provider`
- `/provider/login`
- `/provider/dashboard`
- `/provider/profile`
- `/provider/services`
- `/provider/availability`
- `/provider/bookings`
- `/provider/payouts`

### Admin routes

- `/admin`
- `/admin/login`
- `/admin/dashboard`
- `/admin/providers`
- `/admin/bookings`
- `/admin/payments`
- `/admin/settings`

### API route families

- `/api/auth/*`
- `/api/booking/*`
- `/api/payments/*`
- `/api/stripe/*`
- `/api/hubspot/*`
- `/api/webhooks/*`

The maintained route map is also documented in `docs/routes.md`.

## 8. Integrations

### HubSpot

HubSpot is the central CRM/event automation layer for major VELORA and VIVIA events.

Important events may include:

- Lead/customer creation
- Booking creation
- Payment initiation
- Payment success
- Booking confirmation
- Screening events
- Lease events
- Operational notifications

The central HubSpot automation webhook must be configured through an environment variable. Never hardcode the webhook URL in source code.

### Stripe

Stripe is treated as a payment integration layer where enabled.

Required controls include:

- Webhook signature verification
- Payment-to-booking matching
- Payment state validation
- Idempotent event handling
- Secure secret storage
- Deposit/payment reconciliation

Stripe secrets must never be committed to Git.

### Zite

Zite provides application/data infrastructure used by the VELORA product and operations workflows.

Current VELORA data concepts include:

- Bookings
- Booking Code Requests
- Notifications
- Providers
- Services
- Customers
- Locations
- Payments
- Reviews

The application should validate data at the API boundary and avoid exposing sensitive internal records to public clients.

### Fillout / Airtable / other systems

External form and data systems may feed customer, booking, listing, or operational workflows.

All integrations should have:

- Explicit field mapping
- Authentication
- Validation
- Error handling
- Idempotency where appropriate
- Auditability

## 9. Security

Security is a platform requirement, not a later enhancement.

### Secrets

Never commit:

- API keys
- OAuth secrets
- Stripe secret keys
- webhook secrets
- private tokens
- passwords
- payment credentials

Use environment variables or the appropriate platform secret store.

### Webhooks

Webhook handlers should:

1. Validate the signature.
2. Validate timestamp/tolerance where supported.
3. Parse and validate the event.
4. Prevent replay/duplicate processing.
5. Match the event to the correct business record.
6. Persist the state transition.
7. Emit the required downstream event.

### Authorization

Roles currently include:

- Guest
- Provider
- Admin

Authorization must be checked server-side. UI visibility alone is not authorization.

### Booking/session security

Booking access should be tied to the correct booking and authenticated/verified identity.

Private booking codes should never be returned by a public status endpoint.

Plaintext codes should not be persisted when a secure hash is sufficient.

Session tickets should have expiration and controlled use.

## 10. Payment Lifecycle

VELORA payment states include:

- Pending
- Paid
- Failed
- Refunded
- Partially refunded

Booking states include:

- Draft
- Pending Payment
- Confirmed
- Completed
- Cancelled
- Refunded

The system should not mark a booking as confirmed solely because a checkout page was opened. Confirmation must follow verified payment state.

## 11. Event Architecture

The platform uses domain events to separate core business logic from external integrations.

Typical event categories:

- Booking created
- Booking confirmed
- Payment initiated
- Payment succeeded
- Payment failed
- Booking-code requested
- Booking-code approved
- Booking-code rejected
- Booking-code released
- Session ticket activated
- Session ticket used

External integrations consume validated events rather than directly modifying unrelated domain state.

## 12. Deployment

### Repository foundation

The repository default branch is currently `main`.

The active foundation work has been developed on:

`setup/vivia-velora-foundation`

The foundation includes repository structure, documentation, package configuration, validation, and integration scaffolding.

### Repository landing page

`repository/index.html` provides the repository landing/redirect foundation for the VELORA application.

The current redirect target is the configured VELORA application destination.

A repository file existing does not by itself prove that the destination is deployed or live.

### Package publishing

The project includes an npm package configuration for:

`@vivia-velora/platform`

The configured registry is GitHub Packages.

Publishing is automated through:

`.github/workflows/publish-package.yml`

The workflow supports manual workflow execution and version tags beginning with `v`.

Publishing requires GitHub Actions package permissions and must be verified in the GitHub Actions/Packages interface.

## 13. CI and Dependency Management

Validation workflow:

`.github/workflows/validate.yml`

Package publishing workflow:

`.github/workflows/publish-package.yml`

Dependabot configuration:

`.github/dependabot.yml`

Dependabot is configured for weekly:

- npm dependency updates
- GitHub Actions updates

## 14. Development Workflow

### Branching

Use focused feature branches.

Examples:

- `feat/velora-core-logic`
- `setup/vivia-velora-foundation`

Avoid making unrelated changes in the same branch.

### Pull requests

Production changes should move through:

1. Issue
2. Feature branch
3. Implementation
4. Validation
5. Pull request
6. Review
7. Merge
8. Deployment verification

### Issue organization

The VELORA platform build is organized around the main platform epic and child workstreams:

- Authentication
- Guest booking
- Provider portal
- Payments
- Stripe webhooks
- HubSpot events
- Zite data/API
- Notifications
- Security
- Testing and launch

## 15. Testing and Launch

Before production launch, verify:

### Authentication

- Guest authentication
- Provider authentication
- Admin authentication
- Authorization boundaries
- Session expiration

### Booking

- Service selection
- Add-ons
- Availability
- Guest information
- Booking creation
- Confirmation

### Payments

- Checkout
- Successful payment
- Failed payment
- Duplicate webhook
- Refund
- Payment-to-booking matching

### Booking-code/session flow

- Request
- Approval
- Rejection
- Release
- Expiration
- Provider validation
- Ticket use

### Integrations

- Zite data persistence
- Stripe webhook validation
- HubSpot event delivery
- Notifications
- Error/retry handling

### Security

- Secrets are absent from source
- Authorization is enforced server-side
- Webhooks are verified
- Sensitive data is not exposed publicly
- Logs do not contain secrets or plaintext credentials

## 16. Operational Principles

1. **Verify before trusting external events.**
2. **Keep payment state authoritative and reconciled.**
3. **Never expose secrets or private booking codes unnecessarily.**
4. **Keep VELORA and VIVIA business domains separated.**
5. **Use environment variables for deployment-specific configuration.**
6. **Prefer explicit state transitions over implicit status changes.**
7. **Make external integrations idempotent.**
8. **Document production behavior before launch.**
9. **Do not call an application live until deployment has been verified.**
10. **Use pull requests for material production changes.**

## 17. Current Build Priority

The VELORA By SJ platform is Phase 1.

Recommended completion order:

1. Provider session-ticket validation
2. Payment-to-booking matching
3. HubSpot event flow
4. Guest/provider notifications
5. Security hardening
6. End-to-end testing
7. Production launch verification
8. VIVIA Rentals Phase 2

## 18. Source of Truth

Repository documentation should be treated as implementation context, not as proof that an external service is currently live.

For production verification, check the actual:

- GitHub Actions run
- GitHub Packages publication
- Zite build/publish status
- Payment provider status
- HubSpot event delivery
- Application deployment
- Domain/redirect behavior

Update this wiki context whenever architecture, routes, integrations, security requirements, or deployment procedures materially change.
