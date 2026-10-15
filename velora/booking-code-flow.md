# VELORA Booking Code & Session Ticket Flow

## Guest experience
After a verified booking deposit:
1. Booking becomes confirmed.
2. The booking code remains hidden.
3. The confirmation screen shows a prominent request box: "Request your booking code now".
4. The guest submits the request.
5. Management receives an awaiting-approval request.
6. Until approval, the guest receives no booking code.
7. After management releases the code, the session ticket becomes active.
8. The guest can use the released booking code for the session.

## Management
Management can approve or reject a requested booking code. After approval, management releases the code. The plaintext code should only exist in the controlled release response and should not be stored in source code, logs, URLs, or public booking data.

## Provider validation
Provider-side validation accepts the booking code through an authenticated provider action and verifies that the ticket is active, unexpired, unused, and matches the stored hash. Successful validation can mark the ticket used.

## UI state contract
- not_requested -> show "Request your booking code now"
- requested -> show "Booking code request sent to management"
- approved -> show "Your request was approved and is being activated"
- rejected -> show the management rejection state
- released -> show the controlled booking-code reveal/session-ticket state

Never place the private booking code in public booking JSON, page source, analytics events, client logs, or URLs.
