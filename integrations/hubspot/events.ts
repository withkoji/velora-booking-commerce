import { DomainEvent } from "../../api/core/types";

export interface EventSink { send(event: DomainEvent): Promise<void>; }

export function createHubSpotForwarder(webhookUrl: string): EventSink {
  if (!webhookUrl) throw new Error("HUBSPOT_AUTOMATION_WEBHOOK_URL is required");
  return {
    async send(event) {
      const response = await fetch(webhookUrl, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(event)
      });
      if (!response.ok) throw new Error(`HubSpot webhook failed: ${response.status}`);
    }
  };
}
