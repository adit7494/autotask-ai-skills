---
name: autotask-data-warehouse
description: Use when connecting to Autotask Report Data Warehouse for complex SQL-based reporting, BI tool integration, historical analysis, or when REST API queries are too limited for aggregations and joins
---

# Autotask Report Data Warehouse

## Overview

The Report Data Warehouse is a read-only SQL Server database for complex reporting. Unlike the REST API (no joins, 500-record limits), the Data Warehouse supports full SQL queries with joins, aggregations, and window functions.

**Key difference:** REST API for real-time CRUD operations. Data Warehouse for analytical reporting.

## Connection

| Parameter | Value |
|-----------|-------|
| Protocol | Microsoft SQL Server |
| Port | 1433 |
| Authentication | Separate username/password (not API credentials) |
| IP Allowlist | Up to 3 static IPs |
| URL | Zone-specific (provided by Client Services) |

**Important:** Data Warehouse credentials are NOT the same as API or Autotask UI credentials.

## Data Freshness

| Region | Refresh Time | Duration |
|--------|--------------|----------|
| North America | 4:00 AM ET | ~10 minutes |
| Global | 4:00 PM ET | ~10 minutes |

Check last refresh:
```sql
SELECT * FROM warehouse_last_load
```

Returns:
- `Last_Load` — Refresh completion time
- `Backup_Taken` — Data accuracy timestamp

**Note:** During refresh, active queries are aborted and users disconnected.

## Schema Design

The Data Warehouse uses **views** (not base tables). Views abstract underlying table structures and auto-update when schema changes.

Key characteristics:
- Views map to one or more base tables
- Focus on "most commonly used data for reporting"
- Not all Autotask data is available
- Column names may differ from REST API field names
- A schema spreadsheet (Excel) is available listing view names, column names, and data types

## Common Views

| View | Description |
|------|-------------|
| v_ticket | Ticket data with all fields |
| v_ticket_note | Ticket notes |
| v_time_entry | Time entries |
| v_resource | Resource data |
| v_account | Company/account data |
| v_contact | Contact data |
| v_project | Project data |
| v_task | Task data |
| v_contract | Contract data |
| v_contract_service | Contract services |
| v_contract_block | Block hour data |
| v_billing_item | Billing items |
| v_invoice | Invoice data |
| v_opportunity | Opportunity data |
| v_quote | Quote data |
| v_product | Product data |
| v_inventory_item | Inventory items |
| v_purchase_order | Purchase orders |
| v_expense_item | Expense items |
| v_expense_report | Expense reports |
| v_sla_result | SLA compliance data |
| v_survey_result | Survey results |
| v_knowledgebase_article | KB articles |
| v_document | Documents |
| v_configuration_item | Assets/configuration items |
| v_service_call | Service calls |
| v_subscription | Subscriptions |

## Terminology Mapping

| UI Term | Warehouse Term | Notes |
|---------|----------------|-------|
| Company | Account | Business entities |
| Charge | Cost | Billing items |
| Multiplier | Factor | Block hour factor |
| Quote | eQuote | One usage of "quote" |
| Client Portal | client_access | Portal access |
| End Date | through_date | Date range end |

## Common Query Patterns

### Data Freshness Check
```sql
-- Always check before running reports
SELECT Last_Load, Backup_Taken FROM warehouse_last_load
```

### Ticket Metrics
```sql
-- Open tickets by priority and status
SELECT 
    priority_name,
    status_name,
    COUNT(*) as ticket_count,
    AVG(DATEDIFF(hour, create_date, GETDATE())) as avg_age_hours
FROM v_ticket
WHERE status_name NOT IN ('Complete', 'Cancelled')
GROUP BY priority_name, status_name
ORDER BY priority_name, ticket_count DESC
```

### Resource Utilization
```sql
-- Monthly utilization by resource
SELECT 
    resource_name,
    SUM(hours_worked) as total_hours,
    SUM(CASE WHEN is_billable = 1 THEN hours_worked ELSE 0 END) as billable_hours,
    SUM(hours_worked) / NULLIF(SUM(available_hours), 0) * 100 as utilization_pct
FROM v_time_entry te
JOIN v_resource_daily_availability rda ON te.resource_id = rda.resource_id
WHERE te.worked_date BETWEEN '2024-01-01' AND '2024-01-31'
GROUP BY resource_name
ORDER BY utilization_pct DESC
```

### SLA Compliance
```sql
-- SLA compliance rate by priority
SELECT 
    priority_name,
    COUNT(*) as total_tickets,
    SUM(CASE WHEN first_response_met = 1 THEN 1 ELSE 0 END) as met_first_response,
    SUM(CASE WHEN resolution_met = 1 THEN 1 ELSE 0 END) as met_resolution,
    CAST(SUM(CASE WHEN first_response_met = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 as first_response_pct,
    CAST(SUM(CASE WHEN resolution_met = 1 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 as resolution_pct
FROM v_sla_result
WHERE create_date >= DATEADD(month, -1, GETDATE())
GROUP BY priority_name
```

### Revenue Analysis
```sql
-- Monthly revenue by contract type
SELECT 
    contract_type_name,
    DATEPART(year, posted_date) as year,
    DATEPART(month, posted_date) as month,
    SUM(extended_price) as revenue,
    SUM(cost_amount) as cost,
    SUM(extended_price) - SUM(cost_amount) as margin
FROM v_billing_item
WHERE status_name = 'Posted'
GROUP BY contract_type_name, DATEPART(year, posted_date), DATEPART(month, posted_date)
ORDER BY year, month, contract_type_name
```

### Block Hour Utilization
```sql
-- Block hour consumption by contract
SELECT 
    c.contract_name,
    cb.start_date,
    cb.end_date,
    cb.hours_purchased,
    cb.hours_used,
    cb.hours_remaining,
    (cb.hours_used / NULLIF(cb.hours_purchased, 0)) * 100 as utilization_pct
FROM v_contract_block cb
JOIN v_contract c ON cb.contract_id = c.contract_id
WHERE cb.end_date >= GETDATE()
ORDER BY utilization_pct DESC
```

### Project Budget Tracking
```sql
-- Project budget vs actual
SELECT 
    project_name,
    estimated_hours,
    actual_hours,
    budget_amount,
    actual_cost,
    (actual_hours - estimated_hours) as hours_variance,
    (actual_cost - budget_amount) as cost_variance,
    CASE 
        WHEN estimated_hours > 0 THEN (actual_hours / estimated_hours) * 100 
        ELSE NULL 
    END as hours_pct
FROM v_project
WHERE status_name = 'In Progress'
ORDER BY cost_variance DESC
```

### Client Satisfaction
```sql
-- Survey scores by company and month
SELECT 
    account_name,
    DATEPART(year, survey_date) as year,
    DATEPART(month, survey_date) as month,
    AVG(score) as avg_score,
    COUNT(*) as response_count
FROM v_survey_result sr
JOIN v_account a ON sr.account_id = a.account_id
GROUP BY account_name, DATEPART(year, survey_date), DATEPART(month, survey_date)
ORDER BY account_name, year, month
```

## BI Tool Integration

Compatible tools:
- Microsoft Power BI
- Tableau
- Crystal Reports
- SSRS (SQL Server Reporting Services)
- Any ODBC/JDBC tool

Connection string example:
```
Server=your-zone-url.autotask.net,1433;Database=AutotaskDW;User Id=your-user;Password=your-pass;Encrypt=true;
```

## Views vs REST API

| Aspect | Data Warehouse | REST API |
|--------|----------------|----------|
| Joins | Full SQL joins | Not supported |
| Aggregations | SUM, AVG, COUNT, etc. | Client-side only |
| Record limit | Unlimited | 500 per page |
| Real-time | Daily refresh | Live data |
| Write access | Read-only | Full CRUD |
| Complexity | High | Low-Medium |

## Best Practices

1. **Check freshness first** — Always query `warehouse_last_load` before reports
2. **Use views, not tables** — Views auto-update; tables may change
3. **Filter early** — Add WHERE clauses to reduce data volume
4. **Index awareness** — Views inherit index structure; filter on indexed columns
5. **Schedule around refresh** — Don't run reports during 4 AM ET / 4 PM ET
6. **Cache results** — For dashboards, cache query results rather than querying live
7. **Use parameterized queries** — Prevent SQL injection in BI tools

## Limitations

1. **No real-time data** — Daily refresh only
2. **Read-only** — Cannot write back to Autotask
3. **Not all data available** — Some entities/fields missing
4. **Separate credentials** — Different from API and UI login
5. **IP restricted** — Max 3 static IPs allowlisted
6. **Refresh disruption** — Active queries aborted during refresh

## When to Use Each

| Use Case | Best Tool |
|----------|-----------|
| Create/update tickets | REST API |
| Real-time notifications | Webhooks |
| Complex aggregations | Data Warehouse |
| Historical trends | Data Warehouse |
| Cross-entity joins | Data Warehouse |
| BI dashboards | Data Warehouse |
| Simple lookups | REST API |
| Bulk operations | REST API (paginated) |

## Reference

- API Skill: `autotask-psa-api`
- KPI Skill: `autotask-kpi-reporting`
- Full Documentation: https://www.autotask.net/help/developerhelp/Content/DataWarehouse/DataWarehouseMain.htm
