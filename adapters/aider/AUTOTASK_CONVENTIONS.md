# Autotask PSA API Conventions

Use this reference when writing or modifying any code that interacts with the
Autotask REST API.

---

## 1. Authentication

Every API request requires these four headers:

| Header              | Description                                      |
|---------------------|--------------------------------------------------|
| `ApiIntegrationcode`| Your integration code from the Autotask admin UI |
| `UserName`          | The API user's email address                     |
| `Secret`            | The API user's secret key                        |
| `Content-Type`      | Always `application/json`                        |

Credentials are created in Autotask UI under **Admin -> Extensions & Integrations -> API User**.
Each API user is bound to a specific zone -- credentials are not portable across zones.

---

## 2. Zone Discovery

Autotask is a multi-zone system. You must discover the correct zone URL before
making any API calls.

```
GET https://webservices.autotask.net/atservicesrest/v1.0/zoneInformation?user={email}
```

Response:

```json
{ "url": "https://webservices15.autotask.net/atservicesrest" }
```

Use the returned `url` as the base for all subsequent requests.
Zone 5 is the **sandbox** environment for development and testing.

---

## 3. Base URL Pattern

```
{zone-url}/v1.0/{entity}
```

Examples:
- `https://webservices15.autotask.net/atservicesrest/v1.0/Tickets`
- `https://webservices15.autotask.net/atservicesrest/v1.0/Companies`

---

## 4. Query Syntax

Queries use a POST request to `/{entity}/query` with a JSON search body.

### Request Body

```json
{
  "filter": [
    { "field": "Status", "op": "eq", "value": "1" },
    { "field": "CreateDate", "op": "gte", "value": "2025-01-01" }
  ],
  "maxRecords": 100,
  "includeFields": ["id", "title", "status"]
}
```

### Filter Operators

| Operator        | Description                          |
|-----------------|--------------------------------------|
| `eq`            | Equals                               |
| `noteq`         | Not equals                           |
| `gt`            | Greater than                         |
| `gte`           | Greater than or equal                |
| `lt`            | Less than                            |
| `lte`           | Less than or equal                   |
| `beginsWith`    | String starts with                   |
| `endsWith`      | String ends with                     |
| `contains`      | String contains                      |
| `notContains`   | String does not contain              |
| `in`            | Value in comma-separated list        |
| `isNull`        | Field is null (no value needed)      |
| `isNotNull`     | Field is not null (no value needed)  |
| `today`         | Date is today                        |
| `yesterday`     | Date is yesterday                    |
| `thisWeek`      | Date is in current week              |
| `lastWeek`      | Date is in last week                 |
| `thisMonth`     | Date is in current month             |
| `lastMonth`     | Date is in last month                |
| `thisQuarter`   | Date is in current quarter           |
| `lastQuarter`   | Date is in last quarter              |
| `thisYear`      | Date is in current year              |
| `lastYear`      | Date is in last year                 |

### Pagination

- `maxRecords` -- max results per page (default 500, max 5000).
- If there are more results, the response includes `nextPageUrl`.
- `totalCount` reports the total number of matching records.

### Logic Groups

```json
{
  "filter": [
    { "or": [
      { "field": "Status", "op": "eq", "value": "1" },
      { "field": "Status", "op": "eq", "value": "2" }
    ]}
  ]
}
```

---

## 5. Key Entities

### 5.1 Tickets

**Endpoint:** `/v1.0/Tickets`

Key fields: `id`, `ticketNumber`, `title`, `description`, `status`, `priority`,
`queueID`, `assignedResourceID`, `accountID`, `createDateTime`, `lastActivityDate`

**Status values:**

| Value | Label              |
|-------|--------------------|
| 1     | New                |
| 2     | In Progress        |
| 3     | Waiting Customer   |
| 4     | Waiting Vendor     |
| 5     | Escalated          |
| 6     | Complete           |
| 8     | Waiting Engineer   |

**Priority values:** 1=Low, 2=Medium, 3=High, 4=Critical

### 5.2 Companies (Accounts)

**Endpoint:** `/v1.0/Companies`

Key fields: `id`, `companyName`, `companyType`, `phone`, `address1`, `city`,
`state`, `postalCode`, `country`, `ownerResourceID`

**CompanyType values:**

| Value | Label        |
|-------|--------------|
| 1     | Customer     |
| 2     | Lead         |
| 3     | Prospect     |
| 4     | Dead         |
| 5     | Cancelation  |
| 6     | Vendor       |
| 7     | Partner      |

### 5.3 Contacts

**Endpoint:** `/v1.0/Contacts`

Key fields: `id`, `firstName`, `lastName`, `emailAddress`, `phone`,
`accountID`, `isActive`, `title`

### 5.4 Resources

**Endpoint:** `/v1.0/Resources`

Key fields: `id`, `firstName`, `lastName`, `email`, `resourceType`

**ResourceType values:** 1=Employee, 2=Contractor, 3=Partner

### 5.5 Contracts

**Endpoint:** `/v1.0/Contracts`

Key fields: `id`, `contractName`, `contractType`, `accountID`, `startDate`,
`endDate`, `status`, `billingRule`

**ContractType values:**

| Value | Label              |
|-------|--------------------|
| 1     | Per Ticket         |
| 2     | Per Incident       |
| 3     | Fixed Price        |
| 4     | Billing Overages   |
| 5     | Block Hours        |
| 6     | Retainer           |
| 7     | Time & Materials   |

**ContractStatus values:** 0=Inactive, 1=Active, 2=Cancelled

### 5.6 Configuration Items (CIs)

**Endpoint:** `/v1.0/ConfigurationItems`

Key fields: `id`, `configurationItemName`, `serialNumber`, `accountID`,
`productID`, `installedProductID`, `isActive`, `auditArchitecture`

### 5.7 Projects

**Endpoint:** `/v1.0/Projects`

Key fields: `id`, `projectName`, `accountID`, `status`, `startDateTime`,
`endDateTime`, `projectLeadResourceID`, `type`

**ProjectStatus values:** 1=New, 2=In Progress, 3=On Hold, 4=Complete, 5=Cancelled

### 5.8 Time Entries

**Endpoint:** `/v1.0/TimeEntries`

Key fields: `id`, `resourceID`, `ticketID`, `projectID`, `dateWorked`,
`startDateTime`, `endDateTime`, `hoursWorked`, `summaryNotes`, `billingCodeID`

### 5.9 Opportunities

**Endpoint:** `/v1.0/Opportunities`

Key fields: `id`, `title`, `accountID`, `stage`, `amount`, `closeDate`,
`ownerResourceID`, `probability`

### 5.10 Tasks

**Endpoint:** `/v1.0/Tasks`

Key fields: `id`, `projectID`, `title`, `status`, `assignedResourceID`,
`startDateTime`, `endDateTime`, `estimatedHours`

### 5.11 Notes

**Endpoint:** `/v1.0/TicketNotes` or `/v1.0/TaskNotes`

Key fields: `id`, `ticketID`/`taskID`, `title`, `description`, `noteType`,
`createDateTime`, `creatorResourceID`

**NoteType values:** 1=Activity, 2=Detail

---

## 6. Batch Operations

```
POST /{entity}/batch
```

Body:

```json
{
  "items": [
    { "status": "6", "id": 12345 },
    { "status": "6", "id": 12346 }
  ]
}
```

- Max 20 items per batch.
- Supports create (POST), update (PATCH), and delete (DELETE).

---

## 7. User-Defined Fields (UDFs)

- UDFs are accessed via the `userDefinedFields` array on any entity.
- To filter on a UDF, use the field name format: `UDF{FieldName}` with no spaces.
- Example filter: `{ "field": "UDFMyCustomField", "op": "eq", "value": "abc" }`

---

## 8. Webhooks

Configure in Autotask under **Admin -> Extensions & Integrations -> Webhooks**.

- Supported events: Create, Update, Delete on any enabled entity.
- Payloads include the full entity JSON.
- Webhook URLs must be publicly accessible HTTPS endpoints.
- Use a signing secret to verify webhook authenticity.

---

## 9. KPI and Reporting Patterns

When building KPI queries:

- Use date operators (`thisMonth`, `lastWeek`, etc.) for time-based metrics.
- Filter on `status` to count open vs. closed tickets.
- Join entities by querying related IDs (e.g., `accountID` on tickets to group
  by company).
- For average resolution time, query tickets with `createDateTime` and
  `completedDate` and compute durations client-side.
- Use `includeFields` to minimize payload when building dashboards.

---

## 10. Error Handling

| Code | Meaning                 | Action                            |
|------|-------------------------|-----------------------------------|
| 200  | Success                 | Process response                  |
| 201  | Created                 | Check response for new entity ID  |
| 400  | Bad Request             | Check field names and body format |
| 401  | Unauthorized            | Verify credentials and headers    |
| 403  | Forbidden               | Check API user permissions        |
| 404  | Not Found               | Verify zone URL and entity path   |
| 429  | Rate Limited            | Retry after Retry-After seconds   |
| 500  | Internal Server Error   | Retry with exponential backoff    |

---

## 11. Best Practices

1. **Always discover the zone first.** Cache the zone URL for the session.
2. **Use `includeFields`** to request only the columns you need.
3. **Always filter large tables.** Avoid unfiltered queries on Tickets,
   TimeEntries, or AuditLogs.
4. **Paginate properly.** Use `maxRecords` and follow `nextPageUrl`.
5. **Respect rate limits.** Approximately 100 requests/minute per API user.
   Implement exponential backoff on HTTP 429.
6. **Use the sandbox (zone 5)** for development and testing.
7. **Batch bulk operations.** Use `/{entity}/batch` instead of looping single
   creates or updates.
8. **Secure credentials.** Store API keys in environment variables or a secrets
   manager. Never commit them to source control.
9. **Server-side calls only.** Do not embed API credentials in client-side
   browser code.
10. **Handle pagination completely.** Always check for and follow `nextPageUrl`
    when building complete datasets.
