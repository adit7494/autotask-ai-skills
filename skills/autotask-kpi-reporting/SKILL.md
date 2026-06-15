---
name: autotask-kpi-reporting
description: Use when building KPI dashboards, reports, or analytics from Autotask PSA data including ticket metrics, resource utilization, SLA compliance, financial summaries, and operational performance
---

# Autotask KPI & Reporting Patterns

## Overview

Common MSP KPIs derived from Autotask REST API data. Each section shows the entity, key fields, and query patterns for building dashboards and reports.

**Required:** Use `autotask-psa-api` skill for API authentication, query syntax, and entity reference.

## Ticket KPIs

### Open Ticket Volume

```json
// GET /Tickets/query
{
  "IncludeFields": ["id", "ticketNumber", "status", "priority", "queueID", "assignedResourceID", "createDate"],
  "filter": [
    {"op": "noteq", "field": "status", "value": 5}
  ]
}
```

Status values: 1=New, 2=In Progress, 3=Waiting Customer, 4=Waiting Vendor, 5=Complete, 6=Cancelled, 7=Resolved

### Tickets by Priority

```json
{
  "filter": [
    {"op": "noteq", "field": "Status", "value": 5},
    {"op": "eq", "field": "Priority", "value": 1}
  ]
}
```

Priority values: 1=Critical, 2=High, 3=Medium, 4=Low (verify via entityInformation/fields)

### Average Resolution Time

Query completed tickets with createDate and completedDate:

```json
{
  "IncludeFields": ["id", "createDate", "completedDate", "priority"],
  "filter": [
    {"op": "eq", "field": "Status", "value": 5},
    {"op": "gte", "field": "completedDate", "value": "2024-01-01T00:00:00"}
  ]
}
```

Calculate: `AVG(completedDate - createDate)` grouped by priority.

### SLA Compliance

```json
// GET /ServiceLevelAgreementResults/query
{
  "IncludeFields": ["ticketID", "serviceLevelAgreementName", "isFirstResponseMet", "isResolutionMet", "isResolutionPlanMet", "firstResponseElapsedHours", "resolutionElapsedHours"],
  "filter": [
    {"op": "exist", "field": "ticketID"}
  ]
}
```

Note: ServiceLevelAgreementResults is query-only. All fields are read-only.

KPIs: % first response met, % resolution met, SLA breaches by priority.

### Ticket Aging

```json
{
  "IncludeFields": ["id", "createDate", "status", "priority"],
  "filter": [
    {"op": "noteq", "field": "Status", "value": 5},
    {"op": "lte", "field": "createDate", "value": "2024-01-01T00:00:00"}
  ]
}
```

Group by age buckets: 0-24h, 24-48h, 3-7 days, 7-14 days, 14+ days.

### First Response Time

Query ticket notes (first note after creation):

```json
// GET /TicketNotes/query
{
  "IncludeFields": ["ticketID", "createDateTime", "noteType", "creatorResourceID"],
  "filter": [
    {"op": "eq", "field": "noteType", "value": 1},
    {"op": "gte", "field": "createDateTime", "value": "2024-01-01T00:00:00"}
  ]
}
```

Calculate: `MIN(note.createDateTime) - ticket.createDate` per ticket.

## Resource Utilization KPIs

### Hours Logged by Resource

```json
// GET /TimeEntries/query
{
  "IncludeFields": ["resourceID", "dateWorked", "hoursWorked", "billingCodeID", "type"],
  "filter": [
    {"op": "gte", "field": "dateWorked", "value": "2024-01-01"},
    {"op": "lte", "field": "dateWorked", "value": "2024-01-31"}
  ]
}
```

Group by `resourceID`, sum `hoursWorked`.

### Billable vs Non-Billable Hours

```json
{
  "IncludeFields": ["resourceID", "hoursWorked", "billingCodeID", "nonBillable"],
  "filter": [
    {"op": "gte", "field": "dateWorked", "value": "2024-01-01"},
    {"op": "lte", "field": "dateWorked", "value": "2024-01-31"}
  ]
}
```

KPI: `billableHours / totalHours * 100` = Utilization %

### Resource Availability

```json
// GET /ResourceDailyAvailabilities/query
{
  "filter": [
    {"op": "gte", "field": "date", "value": "2024-01-01"},
    {"op": "lte", "field": "date", "value": "2024-01-31"}
  ]
}
```

Note: ResourceDailyAvailabilities is a newer entity. Use entityInformation/fields to discover available fields.

### Time Off Tracking

```json
// GET /ResourceTimeOffBalances/query
{
  "filter": [
    {"op": "exist", "field": "resourceID"}
  ]
}
```

Returns fields per time-off type (vacation, sick, personal, floating holiday):
- `{type}AnnualAllowance` - Yearly allotment
- `{type}Balance` - Remaining hours
- `{type}Used` - Hours consumed
- `{type}Planned` - Hours scheduled
- `{type}WaitingApproval` - Hours pending approval

Note: All fields are read-only. Query via `Resource/{resourceId}/TimeOffBalances` or `Resource/{resourceId}/TimeOffBalances/{year}`.

## Financial KPIs

### Revenue by Contract

```json
// GET /BillingItems/query
{
  "IncludeFields": ["contractID", "billingCodeID", "quantity", "rate", "extendedPrice", "postedDate", "billingItemType"],
  "filter": [
    {"op": "gte", "field": "postedDate", "value": "2024-01-01"}
  ]
}
```

BillingItemType: 1=Labor, 2=ProjectCost, 3=Cost, 4=Expense, 5=Subscription, 6=RecurringService, 7=RecurringServices, 8=Milestone

Note: BillingItems is mostly read-only. Only `webServiceDate` can be updated. Cost fields require permissions.

### Block Hour Utilization

```json
// GET /ContractBlocks/query
{
  "IncludeFields": ["contractID", "startDate", "endDate", "hours", "hoursApproved", "hourlyRate", "isPaid"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

Note: `hoursApproved` is not queryable (returns error). Track usage via TimeEntries with contractID.

KPI: Block utilization requires tracking time entries against the contract, not direct hoursUsed field.

### Outstanding Invoices

```json
// GET /Invoices/query
{
  "IncludeFields": ["id", "companyID", "invoiceDateTime", "invoiceTotal", "paidDate", "isVoided"],
  "filter": [
    {"op": "exist", "field": "paidDate", "notExist": true}
  ]
}
```

Note: `dueDate` is not queryable. `paidDate` stores date only (no time). `invoiceTotal` is read-only.

KPI: `invoiceTotal` for invoices where `paidDate` is null = Outstanding balance

### Monthly Recurring Revenue (MRR)

```json
// GET /ContractServices/query
{
  "IncludeFields": ["contractID", "serviceID", "unitPrice", "quantity", "billingStartDate", "billingEndDate"],
  "filter": [
    {"op": "eq", "field": "status", "value": 1}
  ]
}
```

KPI: `SUM(unitPrice * quantity)` for active recurring services.

## Project KPIs

### Project Status Summary

```json
// GET /Projects/query
{
  "IncludeFields": ["id", "projectName", "status", "startDateTime", "endDateTime", "actualHours", "estimatedHours", "laborEstimatedRevenue", "laborEstimatedCosts", "laborEstimatedMarginPercentage", "completedPercentage"],
  "filter": [
    {"op": "exist", "field": "status"}
  ]
}
```

Note: Use `entityInformation/fields` to get picklist values for status. Date fields are `startDateTime`/`endDateTime` (not startDate/endDate).

### Project Budget Variance

```json
{
  "IncludeFields": ["id", "projectName", "budget", "actualHours", "estimatedHours"],
  "filter": [
    {"op": "eq", "field": "status", "value": 2}
  ]
}
```

KPI: `(actualHours * hourlyRate - budget) / budget * 100` = Budget variance %

### Task Completion Rate

```json
// GET /Tasks/query
{
  "IncludeFields": ["id", "projectID", "status", "estimatedHours", "actualHours"],
  "filter": [
    {"op": "eq", "field": "projectID", "value": 12345}
  ]
}
```

KPI: `completedTasks / totalTasks * 100` = Completion rate

## Sales KPIs

### Pipeline Value

```json
// GET /Opportunities/query
{
  "IncludeFields": ["id", "title", "status", "amount", "probability", "projectedCloseDate", "stage", "companyID", "ownerResourceID"],
  "filter": [
    {"op": "noteq", "field": "status", "value": 3}
  ]
}
```

Note: Field is `title` (not `name`), `projectedCloseDate` (not `closeDate`). `stage` is read-only. Use `entityInformation/fields` for status picklist values.

KPI: `SUM(amount * probability / 100)` = Weighted pipeline

### Win Rate

```json
{
  "IncludeFields": ["id", "status", "closeDate"],
  "filter": [
    {"op": "gte", "field": "closeDate", "value": "2024-01-01"},
    {"op": "lte", "field": "closeDate", "value": "2024-12-31"}
  ]
}
```

KPI: `wonOpportunities / totalClosedOpportunities * 100`

### Quote-to-Close Ratio

Query quotes and link to opportunities:

```json
// GET /Quotes/query
{
  "IncludeFields": ["id", "opportunityID", "status", "totalAmount"],
  "filter": [
    {"op": "gte", "field": "createDate", "value": "2024-01-01"}
  ]
}
```

## Client Satisfaction KPIs

### Survey Results

```json
// GET /SurveyResults/query
{
  "IncludeFields": ["surveyID", "ticketID", "companyID", "contactID", "companyRating", "contactRating", "resourceRating", "surveyRating", "sendDate", "completeDate"],
  "filter": [
    {"op": "exist", "field": "surveyID"}
  ]
}
```

Note: SurveyResults is query-only. Rating fields are: `companyRating`, `contactRating`, `resourceRating`, `surveyRating` (all decimal, read-only).

KPI: `AVG(surveyRating)` by company, resource, or ticket category.

## Contract KPIs

### Contract Expiration Alert

```json
// GET /Contracts/query
{
  "IncludeFields": ["id", "contractName", "contractType", "companyID", "startDate", "endDate", "status"],
  "filter": [
    {"op": "eq", "field": "status", "value": 1},
    {"op": "lte", "field": "endDate", "value": "2024-02-01"},
    {"op": "gte", "field": "endDate", "value": "2024-01-01"}
  ]
}
```

ContractType: 1=Time&Materials, 2=FixedPrice, 3=BlockHours, 4=Retainer, 5=Incident, 7=RecurringService

### Service Delivery Margin

```json
// GET /ContractServices/query
{
  "IncludeFields": ["contractID", "serviceID", "unitPrice", "unitCost", "adjustedPrice"],
  "filter": [
    {"op": "exist", "field": "contractID"}
  ]
}
```

KPI: `(unitPrice - unitCost) / unitPrice * 100` = Margin %

Note: `unitCost` requires cost data permissions. `adjustedPrice` allows negative values for discounts.

### Block Hour Depletion Forecast

```json
// GET /TimeEntries/query
{
  "IncludeFields": ["contractID", "hoursWorked", "dateWorked"],
  "filter": [
    {"op": "exist", "field": "contractID"},
    {"op": "gte", "field": "dateWorked", "value": "2024-01-01"}
  ]
}
```

Aggregate by contractID to calculate burn rate, then forecast depletion based on remaining block hours.

## Inventory KPIs

### Stock Levels

```json
// GET /InventoryStockedItems/query
{
  "IncludeFields": ["inventoryProductID", "onHandUnits", "availableUnits", "reservedUnits", "pickedUnits"],
  "filter": [
    {"op": "exist", "field": "inventoryProductID"}
  ]
}
```

Note: All fields are read-only. `quantityOnHand` is calculated (not directly queryable on InventoryStockedItems).

### Reorder Alerts

```json
// GET /InventoryProducts/query
{
  "IncludeFields": ["productID", "inventoryLocationID", "quantityMinimum", "quantityMaximum", "onHandUnits", "unitsOnOrder"],
  "filter": [
    {"op": "exist", "field": "productID"}
  ]
}
```

KPI: Items where `onHandUnits <= quantityMinimum` need reorder.

### Inventory Value

```json
// GET /InventoryStockedItems/query
{
  "IncludeFields": ["inventoryProductID", "onHandUnits", "unitCost"],
  "filter": [
    {"op": "exist", "field": "inventoryProductID"}
  ]
}
```

KPI: `SUM(onHandUnits * unitCost)` = Total inventory value

Note: `unitCost` requires cost data permissions.

## Expense KPIs

### Expense by Category

```json
// GET /ExpenseItems/query
{
  "IncludeFields": ["expenseCategory", "expenseDate", "internalCurrencyExpenseAmount", "isBillableToCompany"],
  "filter": [
    {"op": "gte", "field": "expenseDate", "value": "2024-01-01"},
    {"op": "lte", "field": "expenseDate", "value": "2024-12-31"}
  ]
}
```

KPI: `SUM(internalCurrencyExpenseAmount)` grouped by expenseCategory.

### Billable Expense Recovery

```json
{
  "filter": [
    {"op": "eq", "field": "isBillableToCompany", "value": true},
    {"op": "gte", "field": "expenseDate", "value": "2024-01-01"}
  ]
}
```

KPI: `SUM(billable expenses) / SUM(total expenses) * 100` = Recovery rate %

## Data Aggregation Patterns

### Grouped Counts

Since the API returns flat records, aggregate in your application:

```javascript
// Pseudo-code for counting tickets by priority
const tickets = await query('Tickets', { filter: [...] });
const grouped = tickets.reduce((acc, t) => {
  acc[t.priority] = (acc[t.priority] || 0) + 1;
  return acc;
}, {});
```

### Time-Series Data

Group by date field (createDate, dateWorked, etc.):

```javascript
// Pseudo-code for daily ticket creation
const tickets = await query('Tickets', { filter: [...] });
const byDate = tickets.reduce((acc, t) => {
  const date = t.createDate.split('T')[0];
  acc[date] = (acc[date] || 0) + 1;
  return acc;
}, {});
```

### Cross-Entity Joins

The API doesn't support SQL-style joins. Pattern:

1. Query parent entity (e.g., Tickets)
2. Extract IDs from results
3. Query child entity with `in` filter on parent IDs

```javascript
const tickets = await query('Tickets', { filter: [...] });
const ticketIds = tickets.map(t => t.id);
const notes = await query('TicketNotes', {
  filter: [{ op: 'in', field: 'ticketID', value: ticketIds }]
});
```

## Performance Tips for Reporting

1. **Use IncludeFields** - Only fetch fields you need
2. **Filter by date ranges** - Don't fetch all historical data
3. **Use /query/count** - Get counts without fetching records
4. **Batch date ranges** - Query month-by-month for large datasets
5. **Cache entity metadata** - Fetch field definitions once, reuse
6. **Use LastModifiedDate** - Incremental updates only
7. **Consider Data Warehouse** - For complex reporting, use the SQL-based Report Data Warehouse (port 1433)

## Report Data Warehouse

For complex reporting needs, Autotask offers a read-only SQL Server Data Warehouse:
- Connection: Port 1433 (Microsoft SQL Server)
- Access: Separate credentials from API
- Refresh: Daily at 4 AM ET (North America)
- Query: `SELECT * FROM warehouse_last_load` to check data freshness
- Schema: Views map to underlying tables, auto-updated

Best for: Complex joins, aggregations, historical analysis, BI tool integration.

## Common Pitfalls

1. **Timezone handling** - All API times in UTC; convert for display
2. **Date-only fields** - Time forced to midnight; avoid timezone shifts
3. **500 record limit** - Paginate or use id > max_id loops
4. **Rate limits** - 10,000 requests/hour; monitor with ThresholdInformation
5. **Picklist values** - May differ by account; verify via entityInformation/fields
6. **Multi-currency** - Affects billing/financial entities; handle currency codes
7. **Boolean fields** - Must be true/false, not null

## Reference

- API Skill: `autotask-psa-api`
- Full Documentation: https://www.autotask.net/help/developerhelp/Content/0_HOME/HOME.htm
- Swagger UI: `[platform URL]/swagger/ui/index`
