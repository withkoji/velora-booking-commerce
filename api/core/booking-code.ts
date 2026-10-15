import { createHash, randomBytes, timingSafeEqual } from "node:crypto";
import { Booking, Payment, BookingCodeRequest, SessionTicket } from "./types";

export function generateBookingCode(): { code: string; hash: string } {
  const code = randomBytes(6).toString("hex").toUpperCase();
  return { code, hash: hashBookingCode(code) };
}

export function hashBookingCode(code: string): string {
  return createHash("sha256").update(code.trim().toUpperCase()).digest("hex");
}

export function verifyBookingCode(code: string, expectedHash: string): boolean {
  const actual = Buffer.from(hashBookingCode(code), "hex");
  const expected = Buffer.from(expectedHash, "hex");
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}

export function createBookingCodeRequest(booking: Booking, payment: Payment, requestId: string): BookingCodeRequest {
  if (payment.bookingId !== booking.id) throw new Error("Payment does not belong to booking");
  if (payment.status !== "paid") throw new Error("Booking deposit must be paid");
  if (booking.status !== "confirmed") throw new Error("Booking must be confirmed");
  return { id: requestId, bookingId: booking.id, guestId: booking.guestId, status: "requested", requestedAt: new Date().toISOString() };
}

export function approveBookingCodeRequest(request: BookingCodeRequest, managementId: string): BookingCodeRequest {
  if (request.status !== "requested") throw new Error("Booking code request is not awaiting approval");
  return { ...request, status: "approved", approvedAt: new Date().toISOString(), approvedBy: managementId };
}

export function rejectBookingCodeRequest(request: BookingCodeRequest, managementId: string, reason?: string): BookingCodeRequest {
  if (request.status !== "requested") throw new Error("Booking code request is not awaiting review");
  return { ...request, status: "rejected", rejectedAt: new Date().toISOString(), rejectedBy: managementId, rejectionReason: reason };
}

export function releaseBookingCode(request: BookingCodeRequest, codeHash: string): BookingCodeRequest {
  if (request.status !== "approved") throw new Error("Management approval is required before release");
  return { ...request, status: "released", releasedAt: new Date().toISOString(), codeHash };
}

export function activateSessionTicket(request: BookingCodeRequest, ticketId: string, expiresAt: string): SessionTicket {
  if (request.status !== "released" || !request.codeHash) throw new Error("Booking code must be released before ticket activation");
  if (new Date(expiresAt).getTime() <= Date.now()) throw new Error("Ticket expiration must be in the future");
  return { id: ticketId, bookingId: request.bookingId, guestId: request.guestId, status: "active", codeHash: request.codeHash, activatedAt: new Date().toISOString(), expiresAt };
}

export function validateSessionTicket(ticket: SessionTicket, bookingCode: string): SessionTicket {
  if (ticket.status !== "active") throw new Error("Session ticket is not active");
  if (new Date(ticket.expiresAt).getTime() <= Date.now()) throw new Error("Session ticket is expired");
  if (!verifyBookingCode(bookingCode, ticket.codeHash)) throw new Error("Invalid booking code");
  return ticket;
}

export function useSessionTicket(ticket: SessionTicket): SessionTicket {
  if (ticket.status !== "active") throw new Error("Session ticket is not active");
  return { ...ticket, status: "used", usedAt: new Date().toISOString() };
}