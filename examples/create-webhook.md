# Example: Set Up Autotask Webhooks

This example shows how to use the `autotask-webhooks` skill to create real-time event-driven integrations.

## Prerequisites

1. **API-only user** with `Can create WebHooks` permission on their security level
2. **Public HTTPS endpoint** on port 443 with TLS 1.2+
3. **API credentials** (Username, Secret, APIIntegrationcode)

## Step 1: Create Security Level (if needed)

In Autotask UI:
1. Admin → Resources → Security Levels
2. Copy the "API User (API-only)" security level
3. Enable `Can create WebHooks` permission

## Step 2: Create API-Only Resource

```json
POST /Resources
{
  "id": 0,
  "firstName": "Webhook",
  "lastName": "API",
  "email": "webhook-api@yourcompany.com",
  "userName": "webhook-api",
  "isActive": true,
  "resourceType": "Employee",
  "securityLevel": <your-webhook-security-level-id>
}
```

## Step 3: Create a Ticket Webhook

**POST** `/TicketsWebhooks`

```json
{
  "id": 0,
  "name": "New Ticket Notification",
  "description": "Fires when a new ticket is created",
  "isActive": true,
  "url": "https://your-endpoint.com/autotask/webhooks",
  "events": [
    {
      "eventType": "Create"
    }
  ],
  "secret": "your-webhook-secret-for-signature-verification"
}
```

### Supported Events
| Event | Description |
|-------|-------------|
| `Create` | Record created |
| `Update` | At least one field changed |
| `Delete` | Record deleted |

## Step 4: Configure Which Fields to Send

**POST** `/TicketWebhookFields`

```json
{
  "id": 0,
  "webhookId": <webhook-id-from-step-3>,
  "includeFields": [
    "id",
    "ticketNumber",
    "title",
    "status",
    "priority",
    "companyID",
    "assignedResourceID",
    "createDate"
  ]
}
```

## Step 5: Exclude Specific Resources (Optional)

Prevent webhook from firing for changes made by specific resources:

**POST** `/TicketWebhookExcludedResources`

```json
{
  "id": 0,
  "webhookId": <webhook-id>,
  "resourceId": <resource-id-to-exclude>
}
```

## Step 6: Include UDFs (Optional)

**POST** `/TicketWebhookUdfFields`

```json
{
  "id": 0,
  "webhookId": <webhook-id>,
  "udfFieldId": <udf-definition-id>
}
```

## Webhook Payload Example

When a ticket is created, Autotask sends:

```json
{
  "entityId": 12345,
  "entityType": "Ticket",
  "eventType": "Create",
  "timestamp": "2026-06-15T14:30:00.000Z",
  "fields": {
    "id": 12345,
    "ticketNumber": "T20260615.0001",
    "title": "Server is down",
    "status": 1,
    "priority": 1,
    "companyID": 67890,
    "assignedResourceID": 111,
    "createDate": "2026-06-15T14:30:00.000Z"
  },
  "userDefinedFields": [
    {
      "name": "CustomerPriority",
      "value": "Critical"
    }
  ]
}
```

## Webhook Management Entities

| Entity | Purpose |
|--------|---------|
| `TicketsWebhooks` | Ticket webhook definitions |
| `TicketWebhookFields` | Fields included in payload |
| `TicketWebhookExcludedResources` | Resources excluded from triggering |
| `TicketWebhookUdfFields` | UDFs included in payload |
| `CompaniesWebhooks` | Company webhook definitions |
| `ContactsWebhooks` | Contact webhook definitions |
| `ConfigurationItemsWebhooks` | Asset webhook definitions |
| `TicketNotesWebhooks` | Ticket note webhook definitions |
| `WebhookEventErrorLogs` | Error log (30-day retention) |

## Error Handling

- Webhooks auto-deactivate after repeated failures
- Check `WebhookEventErrorLogs` for issues
- Webhooks may occasionally miss events — implement polling as backup
- Each payload should be idempotent (handle duplicates)

## What to Ask Your AI

```
"Set up a webhook for new ticket creation in Autotask"

"Create a webhook that notifies me when high-priority tickets are updated"

"Show me webhook error logs from the last 24 hours"

"Add a UDF field to my existing ticket webhook"
```
