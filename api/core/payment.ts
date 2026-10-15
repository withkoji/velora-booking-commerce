import { Booking, Payment, PaymentStatus } from "./types";

export function createPayment(booking: Booking, id: string): Payment {
  return { id, bookingId: booking.id, providerId: booking.providerId, status: "pending", amount: booking.deposit };
}

const transitions: Record<PaymentStatus, PaymentStatus[]> = {
  pending: ["paid", "failed"],
  paid: ["partially_refunded", "refunded"],
  failed: ["pending"],
  partially_refunded: ["refunded"],
  refunded: []
};

export function transitionPayment(payment: Payment, next: PaymentStatus, externalId?: string): Payment {
  if (!transitions[payment.status].includes(next)) throw new Error(`Invalid payment transition: ${payment.status} -> ${next}`);
  return { ...payment, status: next, externalId: externalId ?? payment.externalId };
}
