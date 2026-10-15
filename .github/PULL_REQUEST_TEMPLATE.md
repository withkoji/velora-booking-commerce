## Summary

Describe the change and the VELORA flow it affects.

## Related work

Closes/Refs #

## Flow impact

- [ ] Customer booking UX
- [ ] Shopify commerce/payment
- [ ] Apntly appointment/availability
- [ ] Zite public/operations
- [ ] Provider marketplace/mobile
- [ ] Membership/commission/payout
- [ ] HubSpot CRM
- [ ] Security/CI/operations only

## Validation

- [ ] Tests pass or new tests were added where required
- [ ] No production credentials or customer payment data are committed
- [ ] Cart creation does not confirm an appointment
- [ ] `Deposit Paid` requires authoritative payment verification
- [ ] `Appointment Confirmed` requires authoritative appointment verification
- [ ] Webhook/event handling remains idempotent
- [ ] A booking uses only one authoritative payment source
- [ ] Provider/admin data access remains authorized

## Rollback

Describe how this change can be safely reverted if it affects production integrations.
