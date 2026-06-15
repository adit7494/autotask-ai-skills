# Example: Build a KPI Dashboard

This example shows how to use the `autotask-kpi-reporting` skill to build MSP KPI dashboards.

## Ticket KPIs

### Open Ticket Volume by Priority

```json
POST /Tickets/query
{
  "IncludeFields": ["id", "priority", "status", "queueID"],
  "filter": [
    {"op": "noteq", "field": "status", "value": 5},
    {"op": "noteq", "field": "status", "value": 6}
  ]
}
```

Group results by `priority` (1=Critical, 2=High, 3=Medium, 4=Low).

### Average Resolution Time

Query completed tickets and calculate:

```json
POST /Tickets/query
{
  "IncludeFields": ["id", "createDate", "completedDate", "priority"],
  "filter": [
    {"op": "eq", "field": "status", "value": 5},
    {"op": "gte", "field": "completedDate", "value": "2026-06-01T00:00:00.000"}
  ]
}
```

For each ticket: `resolutionTime = completedDate - createDate`

### SLA Compliance

```json
POST /ServiceLevelAgreementResults/query
{
  "IncludeFields": [
    "ticketID",
    "serviceLevelAgreementID",
    "firstResponseMet",
    "resolutionMet",
    "firstResponseDueDateTime",
    "resolutionDueDateTime"
  ],
  "filter": [
    {"op": "gte", "field": "createDate", "value": "2026-06-01T00:00:00.000"}
  ]
}
```

Calculate: `compliance% = (met / total) * 100`

### Ticket Aging Buckets

```json
POST /Tickets/query
{
  "IncludeFields": ["id", "createDate", "status", "priority"],
  "filter": [
    {"op": "noteq", "field": "status", "value": 5},
    {"op": "noteq", "field": "status", "value": 6}
  ]
}
```

Bucket by age:
- 0-24 hours
- 1-3 days
- 3-7 days
- 7-14 days
- 14+ days

## Resource Utilization KPIs

### Hours Logged This Week

```json
POST /TimeEntries/query
{
  "IncludeFields": ["resourceID", "hoursWorked", "dateWorked", "isNonBillable"],
  "filter": [
    {"op": "gte", "field": "dateWorked", "value": "2026-06-08T00:00:00.000"}
  ]
}
```

Group by `resourceID`, sum `hoursWorked`, split by `isNonBillable`.

### Resource Availability

```json
POST /ResourceDailyAvailabilities/query
{
  "IncludeFields": ["resourceID", "date", "availableHours"],
  "filter": [
    {"op": "gte", "field": "date", "value": "2026-06-01"},
    {"op": "lte", "field": "date", "value": "2026-06-30"}
  ]
}
```

### Time Off Balances

```json
POST /ResourceTimeOffBalances/query
{
  "IncludeFields": [
    "resourceID",
    "timeOffTypeID",
    "annualAllocation",
    "balance",
    "used",
    "planned",
    "waitingApproval"
  ]
}
```

## Financial KPIs

### Revenue by Contract

```json
POST /BillingItems/query
{
  "IncludeFields": ["contractID", "extendedPrice", "billingItemType", "postedDate"],
  "filter": [
    {"op": "gte", "field": "postedDate", "value": "2026-06-01T00:00:00.000"}
  ]
}
```

billingItemType: 1=Labor, 2=ProjectCost, 3=Cost, 4=Expense, 5=Subscription, 6=RecurringService, 7=RecurringServices, 8=Milestone

### Monthly Recurring Revenue (MRR)

```json
POST /ContractServices/query
{
  "IncludeFields": ["contractID", "serviceID", "unitPrice", "quantity"],
  "filter": [
    {"op": "eq", "field": "contract.contractType", "value": 7}
  ]
}
```

MRR = sum of (unitPrice * quantity) for all active recurring services.

### Block Hour Utilization

```json
POST /ContractBlocks/query
{
  "IncludeFields": ["contractID", "hours", "hoursApproved", "startDate", "endDate"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": <your-contract-id>}
  ]
}
```

Utilization% = (hoursApproved / hours) * 100

## Sales KPIs

### Pipeline Value (Weighted)

```json
POST /Opportunities/query
{
  "IncludeFields": ["id", "title", "amount", "probability", "status", "projectedCloseDate"],
  "filter": [
    {"op": "noteq", "field": "status", "value": <lost-status-id>},
    {"op": "noteq", "field": "status", "value": <won-status-id>}
  ]
}
```

Weighted value = amount * (probability / 100)

### Win Rate

```json
POST /Opportunities/query
{
  "IncludeFields": ["id", "status", "closedDate"],
  "filter": [
    {"op": "exist", "field": "closedDate"}
  ]
}
```

Win rate = (won / total closed) * 100

## Client Satisfaction

```json
POST /SurveyResults/query
{
  "IncludeFields": [
    "surveyID",
    "companyID",
    "companyRating",
    "contactRating",
    "resourceRating",
    "surveyRating"
  ],
  "filter": [
    {"op": "gte", "field": "createDate", "value": "2026-01-01T00:00:00.000"}
  ]
}
```

## What to Ask Your AI

```
"Build a ticket SLA compliance dashboard for this month"

"Show me resource utilization - billable vs non-billable hours per engineer"

"Calculate our monthly recurring revenue from active recurring service contracts"

"What's our sales pipeline weighted value by close date?"

"Which resources have the most time off planned this quarter?"

"Show me ticket aging - how long have open tickets been sitting?"
```

## Data Warehouse Alternative

For complex queries requiring joins, use the Data Warehouse (SQL Server):

```sql
-- Ticket SLA compliance by client
SELECT 
    a.AccountName,
    COUNT(*) AS TotalTickets,
    SUM(CASE WHEN sla.FirstResponseMet = 1 THEN 1 ELSE 0 END) AS FirstResponseMet,
    SUM(CASE WHEN sla.ResolutionMet = 1 THEN 1 ELSE 0 END) AS ResolutionMet
FROM v_ticket t
JOIN v_account a ON t.AccountID = a.AccountID
LEFT JOIN v_sla_result sla ON t.TicketID = sla.TicketID
WHERE t.CreateDate >= '2026-06-01'
GROUP BY a.AccountName
ORDER BY TotalTickets DESC
```
