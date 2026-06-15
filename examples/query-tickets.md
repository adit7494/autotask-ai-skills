# Example: Query Autotask Tickets

This example shows how to use the `autotask-psa-api` skill to query tickets from Autotask PSA.

## Step 1: Discover Your Zone

First, determine which Autotask zone your account is on:

```
GET https://webservices[n].autotask.net/atservicesrest/v1.0/ZoneInformation?user=your-api-email@company.com
```

Response tells you your base URL (e.g., `https://webservices3.autotask.net/atservicesrest/v1.0/`).

## Step 2: Authentication Headers

Every request needs these 4 headers:

| Header | Value |
|--------|-------|
| `Username` | Your API user email |
| `Secret` | Your API user password |
| `APIIntegrationcode` | Your integration tracking code |
| `Content-Type` | `application/json` |

## Step 3: Query Open High-Priority Tickets

**POST** `/Tickets/query`

```json
{
  "IncludeFields": [
    "id",
    "ticketNumber",
    "title",
    "status",
    "priority",
    "companyID",
    "assignedResourceID",
    "createDate",
    "dueDateTime"
  ],
  "filter": [
    {"op": "noteq", "field": "status", "value": 5},
    {"op": "noteq", "field": "status", "value": 6},
    {"op": "eq", "field": "priority", "value": 1}
  ]
}
```

### Status Values Reference
- `1` = New
- `2` = In Progress
- `3` = Waiting Customer
- `4` = Waiting Vendor
- `5` = Complete
- `6` = Cancelled
- `7` = Resolved

## Step 4: Paginate Through Results

If you have more than 500 tickets, paginate:

```json
{
  "MaxRecords": 500,
  "filter": [
    {"op": "noteq", "field": "status", "value": 5}
  ]
}
```

The response includes `pageDetails.nextPageUrl` — follow it until null.

## Step 5: Add Date Range Filter

Query tickets created in the last 7 days:

```json
{
  "filter": [
    {"op": "gte", "field": "createDate", "value": "2026-06-08T00:00:00.000"},
    {"op": "noteq", "field": "status", "value": 5}
  ]
}
```

## Step 6: Query with UDF Filter

Filter by a user-defined field:

```json
{
  "filter": [
    {"op": "eq", "field": "CustomerPriority", "udf": true, "value": "Critical"}
  ]
}
```

## Full cURL Example

```bash
# Step 1: Discover zone
curl -s "https://webservices3.autotask.net/atservicesrest/v1.0/ZoneInformation?user=api@company.com"

# Step 2: Query tickets
curl -X POST "https://webservices3.autotask.net/atservicesrest/v1.0/Tickets/query" \
  -H "Username: api@company.com" \
  -H "Secret: your-password" \
  -H "APIIntegrationcode: your-integration-code" \
  -H "Content-Type: application/json" \
  -d '{
    "IncludeFields": ["id", "ticketNumber", "title", "status", "priority"],
    "filter": [
      {"op": "noteq", "field": "status", "value": 5},
      {"op": "eq", "field": "priority", "value": 1}
    ]
  }'
```

## What to Ask Your AI

```
"Query all open high-priority tickets from Autotask and summarize them by queue"

"Show me tickets created this week that are waiting on the customer"

"Find all tickets assigned to John Smith that are past their due date"

"List tickets with the UDF 'CustomerPriority' set to 'Critical'"
```
