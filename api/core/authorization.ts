import { Role } from "./types";

const permissions: Record<Role, string[]> = {
  guest: ["booking:create", "booking:read:self", "payment:read:self", "profile:write:self"],
  provider: ["booking:read:provider", "booking:update:provider", "service:write:self", "availability:write:self", "payout:read:self", "profile:write:self"],
  admin: ["*"]
};

export function can(role: Role, permission: string): boolean {
  return permissions[role].includes("*") || permissions[role].includes(permission);
}

export function assertCan(role: Role, permission: string): void {
  if (!can(role, permission)) throw new Error("Forbidden");
}
