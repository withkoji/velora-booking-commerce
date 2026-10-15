export type Role = "guest" | "provider" | "admin";
export type BookingStatus = "draft" | "pending_payment" | "confirmed" | "completed" | "cancelled" | "refunded";
export type PaymentStatus = "pending" | "paid" | "failed" | "refunded" | "partially_refunded";
export type BookingCodeRequestStatus = "not_requested" | "requested" | "approved" | "rejected" | "released";
export type SessionTicketStatus = "inactive" | "active" | "used" | "expired" | "cancelled";
export type EventType = "booking.created" | "booking.confirmed" | "booking.cancelled" | "payment.initiated" | "payment.succeeded" | "payment.failed" | "booking_code.requested" | "booking_code.approved" | "booking_code.rejected" | "booking_code.released" | "session_ticket.activated" | "session_ticket.used" | "provider.updated" | "guest.updated";

export interface Money { currency: "USD"; amountCents: number; }
export interface Guest { id: string; email: string; name: string; phone?: string; }
export interface Provider { id: string; name: string; active: boolean; state: string; city: string; }
export interface Service { id: string; providerId: string; name: string; durationMinutes: number; price: Money; active: boolean; }
export interface Booking { id: string; guestId: string; providerId: string; serviceId: string; state: string; city: string; startAt: string; endAt: string; status: BookingStatus; total: Money; deposit: Money; }
export interface Payment { id: string; bookingId: string; providerId?: string; status: PaymentStatus; amount: Money; externalId?: string; }
export interface BookingCodeRequest { id: string; bookingId: string; guestId: string; status: BookingCodeRequestStatus; requestedAt?: string; approvedAt?: string; approvedBy?: string; rejectedAt?: string; rejectedBy?: string; rejectionReason?: string; releasedAt?: string; codeHash?: string; }
export interface SessionTicket { id: string; bookingId: string; guestId: string; status: SessionTicketStatus; codeHash: string; activatedAt?: string; expiresAt: string; usedAt?: string; }
export interface DomainEvent { id: string; type: EventType; occurredAt: string; aggregateId: string; data: Record<string, unknown>; }