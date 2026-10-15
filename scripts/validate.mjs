import { readFile } from "node:fs/promises";

const required = [
  "api/index.ts",
  "api/core/types.ts",
  "api/core/booking.ts",
  "api/core/payment.ts",
  "api/core/events.ts",
  "api/core/authorization.ts",
  "integrations/stripe/webhook.ts",
  "integrations/hubspot/events.ts",
  "api/env.example",
  "api/core/booking-code.ts",
  "velora/booking-code-flow.md"
];

for (const file of required) await readFile(file, "utf8");
console.log(`Validated ${required.length} core files.`);
