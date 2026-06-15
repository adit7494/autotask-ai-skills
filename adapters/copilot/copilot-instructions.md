# Autotask PSA API Reference for GitHub Copilot

You are an Autotask PSA API expert. Follow this reference when writing any code
that interacts with the Autotask REST API.

---

## Authentication

Every API request requires four headers:

| Header              | Description                                      |
|---------------------|--------------------------------------------------|
| `ApiIntegrationcode`| Integration code from the Autotask admin UI      |
| `UserName`          | API user's email address                         |
| `Secret`            | API user's secret key                            |
| `Content-Type`      | Always `application/json`                        |

Credentials are created in **Admin -> Extensions & Integrations -> API User**.
Each API user is bound to a specific zone.

---

## Zone Discovery

Autotask is multi-zone. Discover the zone URL before making any API call:

```
GET https://webservices.autotask.net/atservicesrest/v1.0/zoneInformation?user={email}
```

Response: `{ "url": "https://webservices15.autotask.net/atservicesrest" }`

Use the returned URL as the base for all subsequent requests.
Zone 5 is the sandbox environment for testing.

---

## Base URL Pattern

```
{zone-url}/v1.0/{entity}
```

---

## HTTP Methods

| Method | Purpose          | Example                    |
|--------|------------------|----------------------------|
| GET    | Read one entity  | `GET /Tickets/{id}`        |
| POST   | Query or create  | `POST /Tickets/query`      |
| PATCH  | Partial update   | `PATCH /Tickets/{id}`      |
| PUT    | Full replace     | `PUT /Tickets/{id}`        |
| DELETE | Delete entity    | `DELETE /Tickets/{id}`     |

---

## Query Syntax

Queries use POST to `/{entity}/query` with a JSON body:

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
| `isNull`        | Field is null                        |
| `isNotNull`     | Field is not null                    |
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

- `maxRecords`: max results per page (default 500, max 5000).
- Follow `nextPageUrl` in the response for subsequent pages.
- `totalCount` reports total matching records.

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

Field names are PascalCase and case-sensitive. Multiple filters default to AND.

---

## Entity Reference

### Tickets (`/v1.0/Tickets`)

| Field                 | Type     | Description              |
|-----------------------|----------|--------------------------|
| id                    | Long     | Primary key              |
| ticketNumber          | String   | Display number           |
| title                 | String   | Ticket title             |
| description           | String   | Detailed description     |
| status                | Int      | See status table below   |
| priority              | Int      | 1-4                      |
| queueID               | Long     | Assigned queue            |
| assignedResourceID    | Long     | Assigned resource         |
| accountID             | Long     | Parent company            |
| createDateTime        | DateTime | Creation timestamp        |
| lastActivityDate      | DateTime | Last activity timestamp   |
| completedDate         | DateTime | Completion timestamp      |
| ticketType            | Int      | 1=Service Request, 2=Incident, 3=Problem, 4=Change Request |

**Ticket Status:**

| Value | Label              |
|-------|--------------------|
| 1     | New                |
| 2     | In Progress        |
| 3     | Waiting Customer   |
| 4     | Waiting Vendor     |
| 5     | Escalated          |
| 6     | Complete           |
| 8     | Waiting Engineer   |

**Priority:** 1=Low, 2=Medium, 3=High, 4=Critical

### Companies (`/v1.0/Companies`)

| Field           | Type   | Description          |
|-----------------|--------|----------------------|
| id              | Long   | Primary key          |
| companyName     | String | Company name         |
| companyType     | Int    | See type table below |
| phone           | String | Phone number         |
| address1        | String | Street address       |
| city            | String | City                 |
| state           | String | State/Province       |
| postalCode      | String | ZIP/Postal code      |
| country         | String | Country              |
| ownerResourceID | Long   | Account owner        |
| isActive        | Bool   | Active flag          |

**CompanyType:**

| Value | Label        |
|-------|--------------|
| 1     | Customer     |
| 2     | Lead         |
| 3     | Prospect     |
| 4     | Dead         |
| 5     | Cancelation  |
| 6     | Vendor       |
| 7     | Partner      |

### Contacts (`/v1.0/Contacts`)

Key fields: `id`, `firstName`, `lastName`, `emailAddress`, `phone`, `accountID`,
`isActive`, `title`, `middleInitial`

### Resources (`/v1.0/Resources`)

Key fields: `id`, `firstName`, `lastName`, `email`, `resourceType`

**ResourceType:** 1=Employee, 2=Contractor, 3=Partner

### Contracts (`/v1.0/Contracts`)

Key fields: `id`, `contractName`, `contractType`, `accountID`, `startDate`,
`endDate`, `status`, `billingRule`, `serviceLevelAgreementID`

**ContractType:**

| Value | Label              |
|-------|--------------------|
| 1     | Per Ticket         |
| 2     | Per Incident       |
| 3     | Fixed Price        |
| 4     | Billing Overages   |
| 5     | Block Hours        |
| 6     | Retainer           |
| 7     | Time & Materials   |

**ContractStatus:** 0=Inactive, 1=Active, 2=Cancelled

### Configuration Items (`/v1.0/ConfigurationItems`)

Key fields: `id`, `configurationItemName`, `serialNumber`, `accountID`,
`productID`, `installedProductID`, `isActive`, `auditArchitecture`,
`operatingSystem`

### Projects (`/v1.0/Projects`)

Key fields: `id`, `projectName`, `accountID`, `status`, `startDateTime`,
`endDateTime`, `projectLeadResourceID`, `type`

**ProjectStatus:** 1=New, 2=In Progress, 3=On Hold, 4=Complete, 5=Cancelled

### Time Entries (`/v1.0/TimeEntries`)

Key fields: `id`, `resourceID`, `ticketID`, `projectID`, `dateWorked`,
`startDateTime`, `endDateTime`, `hoursWorked`, `summaryNotes`, `billingCodeID`

### Opportunities (`/v1.0/Opportunities`)

Key fields: `id`, `title`, `accountID`, `stage`, `amount`, `closeDate`,
`ownerResourceID`, `probability`, `status`

**OpportunityStage:** 1=Qualification, 2=Needs Analysis, 3=Proposal,
4=Negotiation, 5=Closed Won, 6=Closed Lost

### Tasks (`/v1.0/Tasks`)

Key fields: `id`, `projectID`, `title`, `status`, `assignedResourceID`,
`startDateTime`, `endDateTime`, `estimatedHours`, `departmentID`

### Ticket Notes (`/v1.0/TicketNotes`)

Key fields: `id`, `ticketID`, `title`, `description`, `noteType`,
`createDateTime`, `creatorResourceID`

**NoteType:** 1=Activity, 2=Detail

### Task Notes (`/v1.0/TaskNotes`)

Same structure as Ticket Notes with `taskID` instead of `ticketID`.

### Roles (`/v1.0/Roles`)

Key fields: `id`, `name`, `description`, `active`

### Queues (`/v1.0/Queues`)

Key fields: `id`, `name`, `description`, `isActive`

### Products (`/v1.0/Products`)

Key fields: `id`, `productName`, `description`, `manufacturerID`, `isActive`

### Inventory Items (`/v1.0/InventoryItems`)

Key fields: `id`, `productID`, `serialNumber`, `warehouseID`, `status`

---

## Batch Operations

```
POST /{entity}/batch
```

```json
{
  "items": [
    { "status": "6", "id": 12345 },
    { "status": "6", "id": 12346 }
  ]
}
```

Max 20 items per batch. Supports create, update, and delete.

---

## User-Defined Fields (UDFs)

UDFs are returned in the `userDefinedFields` array on entity responses.
To filter on a UDF: `{ "field": "UDF{FieldNameNoSpaces}", "op": "eq", "value": "x" }`

Example: a UDF named "My Custom Field" becomes `UDFMyCustomField` in filters.

---

## Webhooks

Configure in **Admin -> Extensions & Integrations -> Webhooks**.

- Events: Create, Update, Delete on any enabled entity.
- Payloads include full entity JSON.
- Must use HTTPS endpoints.
- Verify authenticity with the configured signing secret.

---

## Data Warehouse / Reporting

For reporting and analytics, Autotask provides a data warehouse with a star
schema. Common fact tables:

- `v_fact_ticket` -- ticket metrics and dimensions
- `v_fact_time_entry` -- time tracking data
- `v_fact_invoice` -- billing and invoice data
- `v_fact_opportunity` -- sales pipeline data

Dimension tables include `v_dim_company`, `v_dim_resource`, `v_dim_date`,
`v_dim_product`, and `v_dim_contract`.

Use the data warehouse for historical reporting and KPI calculations instead
of querying the live API for aggregates.

---

## KPI Patterns

**Open Tickets by Company:**
```
POST /Tickets/query
filter: accountID = {id}, status in (1,2,3,4,5,8)
```

**Tickets Closed This Month:**
```
POST /Tickets/query
filter: status = 6, completedDate = thisMonth
```

**Average Resolution Time:**
Query completed tickets with `createDateTime` and `completedDate`, compute
durations client-side.

**Billable Hours This Week:**
```
POST /TimeEntries/query
filter: dateWorked = thisWeek
Sum: hoursWorked
```

**SLA Compliance:**
Query tickets with `serviceLevelAgreementID`, compare `completedDate` against
SLA target times.

---

## Inventory Management

- Track hardware and software CIs via `/v1.0/ConfigurationItems`.
- Inventory items at `/v1.0/InventoryItems` track stock by warehouse.
- Use `serialNumber` and `productID` for asset tracking.
- CIs link to companies via `accountID` and to products via `productID`.

---

## Error Handling

| Code | Meaning               | Action                           |
|------|-----------------------|----------------------------------|
| 200  | Success               | Process response                 |
| 201  | Created               | Check for new entity ID          |
| 400  | Bad Request           | Validate field names and body    |
| 401  | Unauthorized          | Check credentials and headers    |
| 403  | Forbidden             | Check API user permissions       |
| 404  | Not Found             | Verify zone URL and entity       |
| 405  | Method Not Allowed    | Check HTTP method for endpoint   |
| 429  | Rate Limited          | Retry after Retry-After header   |
| 500  | Internal Server Error | Retry with exponential backoff   |

Error body: `{ "errors": [{ "message": "...", "details": "..." }] }`

---

## Best Practices

1. **Always discover the zone first** and cache the URL for the session.
2. **Use `includeFields`** to request only needed columns.
3. **Always filter large tables.** Never query Tickets or TimeEntries without
   date or status filters.
4. **Paginate properly.** Use `maxRecords` and follow `nextPageUrl`.
5. **Respect rate limits.** ~100 requests/minute per API user. Implement
   exponential backoff on HTTP 429.
6. **Use the sandbox (zone 5)** for development and testing.
7. **Use batch endpoints** for bulk operations instead of looping single calls.
8. **Secure credentials.** Store in environment variables or a secrets manager.
   Never commit to source control.
9. **Server-side only.** Do not embed API credentials in client-side code.
10. **Handle pagination completely.** Always follow `nextPageUrl` for full
    datasets.
11. **Use the data warehouse** for aggregate reporting instead of live API
    queries.
12. **Prefer UDFs** for custom fields over modifying core entity schemas.
