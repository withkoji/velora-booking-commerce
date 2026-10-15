import { Booking, BookingStatus, Money, Service } from "./types";

export function calculateEnd(startAt: string, durationMinutes: number): string {
  const start = new Date(startAt);
  if (Number.isNaN(start.getTime())) throw new Error("Invalid booking start time");
  return new Date(start.getTime() + durationMinutes * 60_000).toISOString();
}

export function calculateDeposit(total: Money, percentage = 0.5): Money {
  if (percentage <= 0 || percentage > 1) throw new Error("Deposit percentage must be > 0 and <= 1");
  return { currency: total.currency, amountCents: Math.round(total.amountCents * percentage) };
}

export function createBooking(input: {
  id: string; guestId: string; providerId: string; service: Service;
  state: string; city: string; startAt: string;
}): Booking {
  if (!input.service.active) throw new Error("Service is inactive");
  if (!input.guestId || !input.providerId) throw new Error("Guest and provider are required");
  const total = input.service.price;
  return {
    id: input.id, guestId: input.guestId, providerId: input.providerId,
    serviceId: input.service.id, state: input.state, city: input.city,
    startAt: input.startAt, endAt: calculateEnd(input.startAt, input.service.durationMinutes),
    status: "pending_payment", total, deposit: calculateDeposit(total)
  };
}

const transitions: Record<BookingStatus, BookingStatus[]> = {
  draft: ["pending_payment", "cancelled"],
  pending_payment: ["confirmed", "cancelled"],
  confirmed: ["completed", "cancelled"],
  completed: ["refunded"],
  cancelled: [],
  refunded: []
};

export function transitionBooking(booking: Booking, next: BookingStatus): Booking {
  if (!transitions[booking.status].includes(next)) throw new Error(`Invalid booking transition: ${booking.status} -> ${next}`);
  return { ...booking, status: next };
}
