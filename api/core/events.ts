import { DomainEvent, EventType } from "./types";

export function event(type: EventType, aggregateId: string, data: Record<string, unknown>, id = crypto.randomUUID()): DomainEvent {
  return { id, type, aggregateId, data, occurredAt: new Date().toISOString() };
}

export function isMajorEvent(type: EventType): boolean {
  return type.startsWith("booking.") || type.startsWith("payment.") || type === "provider.updated" || type === "guest.updated";
}
