---
name: autotask-contract-management
description: Use when managing Autotask contracts including recurring services, block hours, retainers, fixed price, per-ticket billing, contract services, milestones, and billing rules
---

# Autotask Contract Management

## Overview

Contracts define billing arrangements with companies. Autotask supports multiple contract types with complex sub-entities for services, blocks, milestones, and billing rules.

**Required:** Use `autotask-psa-api` skill for authentication and query syntax.

## Contract Types

| Type | Billing Model | Key Entity |
|------|---------------|------------|
| **Recurring Service** | Fixed monthly fee for services | ContractServices, ContractServiceBundles |
| **Block Hour** | Pre-purchased hour blocks | ContractBlocks |
| **Retainer** | Pre-paid retainer amount | ContractRetainers |
| **Fixed Price** | Milestone-based billing | ContractMilestones |
| **Per Ticket** | Bill per ticket/issue | ContractTicketPurchases |
| **Time & Materials** | Bill actual hours/rates | Standard billing |

## Contract Entity Relationships

```
Contracts
├── ContractServices (recurring services)
├── ContractServiceBundles (service bundles)
├── ContractBlocks (block hours)
├── ContractRetainers (retainer payments)
├── ContractMilestones (fixed price milestones)
├── ContractTicketPurchases (per-ticket prepayments)
├── ContractBillingRules (auto-charge rules)
├── ContractRates (role rate overrides)
├── ContractRoleCosts (internal cost rates)
├── ContractExclusionBillingCodes (excluded work types)
├── ContractExclusionRoles (excluded roles)
├── ContractExclusionSets (reusable exclusion sets)
├── ContractServiceAdjustments (service quantity changes)
├── ContractServiceBundleAdjustments (bundle quantity changes)
├── ContractServiceUnits (service units by date)
├── ContractServiceBundleUnits (bundle units by date)
├── ContractCharges (contract-level charges)
└── ContractNotes (contract notes)
```

## Key Queries

### List Active Contracts

```json
GET /Contracts/query

{
  "IncludeFields": ["id", "contractName", "contractType", "companyID", "startDate", "endDate", "status"],
  "filter": [
    {"op": "eq", "field": "status", "value": 1},
    {"op": "gte", "field": "endDate", "value": "2024-01-01"}
  ]
}
```

Status: 1=Active, 2=Inactive, 3=Expired (verify via entityInformation/fields)

### Contract with Services

```json
GET /ContractServices/query

{
  "IncludeFields": ["contractID", "serviceID", "unitPrice", "quantity", "billingStartDate", "billingEndDate"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

### Contract with Service Bundles

```json
GET /ContractServiceBundles/query

{
  "IncludeFields": ["contractID", "serviceBundleID", "unitPrice", "quantity", "billingStartDate"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

## Block Hour Contracts

### Block Balance

```json
GET /ContractBlocks/query

{
  "IncludeFields": ["contractID", "startDate", "endDate", "hours", "hoursApproved", "hourlyRate", "isPaid", "datePurchased"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

**Key Fields:**
- `hours` - Total purchased hours (must be >= hoursApproved when updating)
- `hoursApproved` - Read-only, not queryable (returns error)
- `hourlyRate` - Cannot change when billed
- `isPaid` - Read-only, defaults to 0 on create
- `startDate`/`endDate` - Must be within contract dates, date-only values

**Tracking Usage:** Since `hoursApproved` is not queryable, track block usage via TimeEntries:
```json
GET /TimeEntries/query
{
  "IncludeFields": ["contractID", "hoursWorked", "dateWorked"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

KPI: `SUM(timeEntries.hoursWorked)` = Hours used from block

### Block Hour Factors

Multipliers for different roles on block contracts:

```json
GET /ContractBlockHourFactors/query

{
  "IncludeFields": ["contractID", "roleID", "blockHourMultiplier", "contractHourlyRate"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

**Key Fields:**
- `blockHourMultiplier` - The multiplier (e.g., 2.0 = 2 block hours per 1 hour worked)
- `contractHourlyRate` - Rate in customer currency (multi-currency)
- `contractID` - Must reference Block Hour type contract
- `roleID` - Must be active role

**Uniqueness:** Each roleID/contractID combination can have only one ContractBlockHourFactor.

Example: $60 contract rate with $120 Engineer rate = 2.0 multiplier (debits 2 block hours per hour worked)

## Retainer Contracts

### Retainer Balance

```json
GET /ContractRetainers/query

{
  "IncludeFields": ["contractID", "startDate", "endDate", "amount", "amountApproved", "isPaid", "datePurchased"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

**Key Fields:**
- `amount` - Total retainer amount (must be >= amountApproved when updating)
- `amountApproved` - Not queryable (returns error)
- `isPaid` - Read-only, defaults to 0 on create
- `startDate`/`endDate` - Must be within contract dates, date-only values

**Multi-currency:** `amount` returns customer currency; `internalCurrencyAmount` returns internal currency.

## Fixed Price Contracts

### Milestones

```json
GET /ContractMilestones/query

{
  "IncludeFields": ["contractID", "title", "amount", "dateDue", "status", "isInitialPayment", "billingCodeID"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

**Key Fields:**
- `title` - Milestone name (required)
- `amount` - Milestone amount (required)
- `dateDue` - Due date (required)
- `status` - Picklist (required)
- `isInitialPayment` - Required
- `billingCodeID` - Must reference Milestone type allocation code
- `contractID` - Must reference Fixed Price type contract

**Status Rules:**
- If `isInitialPayment = False`, status cannot be "isBilled"
- If `isInitialPayment = True`, allows one "Billed" and one "Ready to Bill" milestone
- Status cannot update once set to "isBilled"

**Multi-currency:** `amount` returns customer currency; `internalCurrencyAmount` returns internal currency.

## Contract Billing Rules

Automated charge generation rules:

```json
GET /ContractBillingRules/query

{
  "IncludeFields": ["contractID", "productID", "determineUnits", "invoiceDescription", "isActive", "startDate", "endDate", "createChargesAsBillable", "minimumUnits", "maximumUnits"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

**Key Fields:**
- `productID` - Required on create, read-only on update (must be active, non-Standard billing)
- `determineUnits` - Picklist (required)
- `isActive` - Required
- `startDate` - Required on create
- `createChargesAsBillable` - Required
- `invoiceDescription` - Max 500 characters

## Role Rate Overrides

Custom rates per contract (override standard role rates):

```json
GET /ContractRates/query

{
  "IncludeFields": ["contractID", "roleID", "contractHourlyRate"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

**Key Fields:**
- `contractHourlyRate` - Required, returns customer currency in multi-currency
- `contractID` - Cannot reference Recurring Service or Block Hour contracts
- `roleID` - Required

**Uniqueness:** Each roleID/contractID combination can have only one ContractRate.

## Internal Cost Tracking

Cost rates for margin calculations:

```json
GET /ContractRoleCosts/query

{
  "IncludeFields": ["contractID", "resourceID", "roleID", "rate"],
  "filter": [
    {"op": "eq", "field": "contractID", "value": 12345}
  ]
}
```

**Key Fields:**
- `rate` - Cost per hour (required, only writable field)
- `contractID` - Required, read-only
- `resourceID` - Required, read-only
- `roleID` - Required, read-only

**Constraints:**
- `roleID` must reference a Role associated with the Resource via Department or Queue
- Only applies to time entries with create date within contract start/end dates

## Exclusion Sets

Reusable sets of excluded roles/work types:

```json
GET /ContractExclusionSets/query

{
  "IncludeFields": ["id", "name", "description", "isActive"]
}

GET /ContractExclusionSetExcludedRoles/query
{
  "IncludeFields": ["contractExclusionSetID", "excludedRoleID"],
  "filter": [{"op": "eq", "field": "contractExclusionSetID", "value": 123}]
}

GET /ContractExclusionSetExcludedWorkTypes/query
{
  "IncludeFields": ["contractExclusionSetID", "excludedWorkTypeID"],
  "filter": [{"op": "eq", "field": "contractExclusionSetID", "value": 123}]
}
```

**Key Constraints:**
- `name` must be unique
- Max 500 roles per exclusion set
- Max 500 work types per exclusion set
- `excludedRoleID` must be active role
- `excludedWorkTypeID` must be active BillingCode with useType=1 (work type)

## Service Quantity Adjustments

Track changes to service quantities over time (create only, cannot query):

```json
POST /ContractServiceAdjustments

{
  "contractServiceID": 456,
  "effectiveDate": "2024-01-01",
  "unitChange": 5,
  "adjustedUnitPrice": 100.00
}
```

**Key Fields:**
- `contractServiceID` - Either this OR contractID+serviceID required
- `contractID` - Required if no contractServiceID
- `serviceID` - Required if no contractServiceID (picklist)
- `effectiveDate` - Required
- `unitChange` - Required (quantity change)
- `adjustedUnitPrice` - Allows negative values for discounts
- `allowRepeatService` - Must be True to create duplicate service on contract

**Note:** If ContractService doesn't exist, API creates it automatically.
  ]
}
```

## Common KPI Patterns

### Contract Revenue Forecast

```javascript
// For recurring services: SUM(unitPrice * quantity) per month
// For block hours: block price when purchased
// For retainers: retainer amount
// For fixed price: milestone amounts by due date
```

### Contract Expiration Alert

```json
{
  "filter": [
    {"op": "eq", "field": "status", "value": 1},
    {"op": "lte", "field": "endDate", "value": "2024-02-01"},
    {"op": "gte", "field": "endDate", "value": "2024-01-01"}
  ]
}
```

### Block Utilization Trend

Query ContractBlocks monthly, calculate:
- `hoursUsed / hours` per block period
- Trend over time to predict exhaustion

### Service Delivery Margin

```javascript
// Revenue: ContractServices.unitPrice * quantity
// Cost: ContractRoleCosts.cost * hours logged
// Margin: (Revenue - Cost) / Revenue * 100
```

## Best Practices

1. **Verify contract type** — Different types have different sub-entities
2. **Check date ranges** — Filter by startDate/endDate for active contracts
3. **Use exclusion sets** — Reusable across contracts, easier to maintain
4. **Track adjustments** — Service quantity changes affect forecasting
5. **Monitor block depletion** — Alert when blocks nearing exhaustion
6. **Calculate true margin** — Include role costs, not just billing rates
7. **Handle multi-currency** — Contract amounts may be in different currencies

## Reference

- API Skill: `autotask-psa-api`
- KPI Skill: `autotask-kpi-reporting`
- Full Documentation: https://www.autotask.net/help/developerhelp/Content/APIs/REST/Entities/ContractsEntity.htm
