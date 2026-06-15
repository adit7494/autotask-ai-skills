---
name: autotask-webhooks
description: Use when setting up real-time event-driven integrations with Autotask PSA using webhooks for companies, contacts, tickets, assets, and ticket notes
---

# Autotask Webhooks Integration

## Overview

Webhooks provide push-based notifications when entities change in Autotask. Instead of polling, Autotask sends HTTP POST to your endpoint in near real-time.

**Required:** Use `autotask-psa-api` skill for authentication and API reference.

## Supported Entities

| Entity | Events |
|--------|--------|
| Companies (Accounts) | Create, Update, Delete |
| Contacts | Create, Update, Delete |
| ConfigurationItems (Assets) | Create, Update, Delete |
| Tickets | Create, Update, Delete |
| Ticket Notes | Create, Update, Delete |

## Triggering Events

| Event | Description |
|-------|-------------|
| **Create** | Any record creation |
| **Update** | At least one callout field or UDF changed |
| **Delete** | Record deletion |
| **Deactivate** | Webhook deactivated after repeated failures |

## Prerequisites

1. **API-only user** with security level that includes `Can create WebHooks` permission
2. **Separate resource per integration** - Best practice for security isolation
3. **Public endpoint** - Your server must accept HTTPS POST on port 443
4. **TLS 1.2+** required for all connections

## Setup Steps

### Step 1: Configure Security Level

1. Navigate: Admin > Company Settings & Users > Resources/Users (HR) > Security > Security Levels
2. Copy the **API User (system) (API-only)** security level
3. Under **Other** section, check **Can create WebHooks**
4. Set maximum webhook count for this security level

### Step 2: Create API-Only Resource

1. Create dedicated resource for this integration
2. Assign the configured security level
3. Set `APIIntegrationcode` (vendor or custom)
4. Configure ImpersonationResourceId if needed

### Step 3: Create Webhook via API

```json
POST /v1.0/TicketWebhooks

{
  "name": "My Integration - Tickets",
  "description": "Notifications for ticket changes",
  "url": "https://your-server.com/webhook/autotask",
  "isActive": true,
  "events": {
    "onCreate": true,
    "onUpdate": true,
    "onDelete": false
  },
  "fields": [
    "id",
    "ticketNumber",
    "title",
    "status",
    "priority",
    "assignedResourceID",
    "companyID"
  ]
}
```

### Step 4: Configure Webhook Fields

Define which fields trigger notifications and which are included in payload:

```json
POST /v1.0/TicketWebhookFields

{
  "webhookID": 12345,
  "fieldName": "status",
  "onUpdate": true
}
```

## Payload Structure

Webhook payloads are JSON POST requests:

```json
{
  "entityId": 12345,
  "entityType": "Ticket",
  "eventType": "Update",
  "timestamp": "2024-01-15T10:30:00Z",
  "fields": {
    "id": 12345,
    "ticketNumber": "T20240115.0001",
    "title": "Server Down",
    "status": 2,
    "priority": 1,
    "assignedResourceID": 67890,
    "companyID": 11111,
    "lastModifiedDate": "2024-01-15T10:30:00Z"
  },
  "userDefinedFields": [
    {"name": "CustomField1", "value": "Some Value"}
  ]
}
```

## Webhook Management Entities

| Entity | Purpose |
|--------|---------|
| `TicketWebhooks` | CRUD for ticket webhooks |
| `TicketWebhookFields` | Fields that trigger/include in payload |
| `TicketWebhookExcludedResources` | Resources whose changes don't trigger |
| `TicketWebhookUdfFields` | UDF fields for ticket webhooks |
| `CompanyWebhooks` | CRUD for company webhooks |
| `CompanyWebhookFields` | Fields for company webhooks |
| `CompanyWebhookExcludedResources` | Excluded resources |
| `CompanyWebhookUdfFields` | UDF fields |
| `ContactWebhook` | CRUD for contact webhooks |
| `ContactWebhookField` | Fields for contact webhooks |
| `ContactWebhookExcludedResource` | Excluded resources |
| `ContactWebhookUdfField` | UDF fields |
| `ConfigurationItemWebhooks` | CRUD for asset webhooks |
| `ConfigurationItemWebhookFields` | Fields for asset webhooks |
| `ConfigurationItemWebhookExcludedResources` | Excluded resources |
| `ConfigurationItemWebhookUdfFields` | UDF fields |
| `TicketNoteWebhooks` | CRUD for ticket note webhooks |
| `TicketNoteWebhookFields` | Fields for ticket note webhooks |
| `TicketNoteWebhookExcludedResources` | Excluded resources |
| `WebhookEventErrorLogs` | Error logs (30-day retention) |

### TicketWebhooks Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| name | string | ✓ | |
| description | string | — | |
| url | string | ✓ | HTTPS endpoint |
| isActive | boolean | — | |
| events.onCreate | boolean | — | |
| events.onUpdate | boolean | — | |
| events.onDelete | boolean | — | |
| fields | array | — | Fields to include in payload |
| udfFields | array | — | UDF fields to include |

### TicketWebhookFields Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| webhookID | integer | ✓ | References TicketWebhooks |
| fieldName | string | ✓ | Must be valid field name |
| onUpdate | boolean | — | Whether this field triggers update notification |

### TicketWebhookExcludedResources Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| webhookID | integer | ✓ | References TicketWebhooks |
| resourceID | integer | ✓ | Resource to exclude |

### TicketWebhookUdfFields Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| webhookID | integer | ✓ | References TicketWebhooks |
| udfName | string | ✓ | Must be valid UDF name |
| onUpdate | boolean | — | Whether this UDF triggers update notification |

## Excluding Resources

Prevent specific resources from triggering webhooks:

```json
POST /v1.0/TicketWebhookExcludedResources

{
  "webhookID": 12345,
  "resourceID": 67890
}
```

Use case: Exclude monitoring/system accounts from triggering notifications.

## Security Considerations

1. **Owner permissions** - Webhooks only fire if owner has entity permissions
2. **Protected data** - Owner must have Protected Data Permissions
3. **Line of business** - Owner must have appropriate LOB access
4. **Dedicated resources** - Create separate API users per integration
5. **Webhook validation** - Verify payload source in your endpoint

## Error Handling

### Deactivation

Webhooks auto-deactivate after repeated delivery failures. Monitor with:

```json
GET /v1.0/WebhookEventErrorLogs/query

{
  "filter": [
    {"op": "gte", "field": "createDate", "value": "2024-01-01"}
  ]
}
```

### Retry Logic

Autotask may retry failed deliveries. Your endpoint should:
- Return 200 OK promptly
- Process asynchronously if needed
- Be idempotent (handle duplicate deliveries)

## Best Practices

1. **Verify ownership** - Check webhook owner has required permissions
2. **Minimal fields** - Only include fields you need (reduces payload size)
3. **Exclude resources** - Filter out system/monitoring accounts
4. **Log everything** - Track deliveries for debugging
5. **Handle failures gracefully** - Don't lose data on endpoint downtime
6. **Use HTTPS** - Always use TLS for webhook endpoints
7. **Validate payloads** - Verify entity IDs exist before processing
8. **Process async** - Return 200 quickly, process in background

## Webhooks vs Polling

| Aspect | Webhooks | Polling |
|--------|----------|---------|
| Latency | Near real-time | Delayed (poll interval) |
| API usage | Minimal | High (constant queries) |
| Complexity | Endpoint required | Cache + comparison logic |
| Reliability | May miss events | Always catches changes |
| Rate limits | Low impact | High impact |

**Recommendation:** Use webhooks for real-time needs. Poll only as fallback or for entities without webhook support.

## Monitoring

```json
// Check recent webhook errors
GET /v1.0/WebhookEventErrorLogs/query

{
  "IncludeFields": ["webhookID", "entityID", "errorMessage", "createDate"],
  "filter": [
    {"op": "gte", "field": "createDate", "value": "2024-01-15T00:00:00"}
  ],
  "MaxRecords": 50
}
```

## Reference

- API Skill: `autotask-psa-api`
- KPI Skill: `autotask-kpi-reporting`
- Full Documentation: https://www.autotask.net/help/developerhelp/Content/APIs/Webhooks/WEBHOOKS.htm
