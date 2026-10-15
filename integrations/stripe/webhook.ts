import { createHmac, timingSafeEqual } from "node:crypto";

export function verifyWebhookSignature(payload: string, signature: string, secret: string, toleranceSeconds = 300): boolean {
  if (!payload || !signature || !secret) return false;
  const parts = Object.fromEntries(signature.split(",").map(p => p.split("=", 2) as [string,string]));
  const timestamp = Number(parts.t);
  const v1 = parts.v1;
  if (!Number.isFinite(timestamp) || !v1 || Math.abs(Date.now() / 1000 - timestamp) > toleranceSeconds) return false;
  const expected = createHmac("sha256", secret).update(`${timestamp}.${payload}`).digest("hex");
  const a = Buffer.from(expected, "utf8"), b = Buffer.from(v1, "utf8");
  return a.length === b.length && timingSafeEqual(a, b);
}
