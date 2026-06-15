---
name: autotask-udf
description: Use when working with Autotask User-Defined Fields to extend entities with custom data, query UDF values, manage UDF definitions, or integrate custom fields into reports and workflows
---

# Autotask User-Defined Fields (UDFs)

## Overview

UDFs are custom fields that Autotask customers add to extend entity data. They're critical for integrations that need to store custom data without modifying standard fields.

**Required:** Use `autotask-psa-api` skill for authentication and query syntax.

## UDF-Supported Entities

| Entity | Max UDFs | Notes |
|--------|----------|-------|
| Companies | 200 | |
| Contacts | 100 | |
| Contracts | 50 | |
| ConfigurationItems (Assets) | 500 | |
| Opportunities | 200 | |
| Products | 100 | |
| Projects | 200 | |
| SalesOrders | 100 | |
| Services | 100 | |
| ServiceBundles | 100 | |
| Subscriptions | 100 | |
| Tasks | 100 | |
| Tickets | 300 | |
| CompanySiteConfigurations | 500 | Protected Data Permissions apply |

## UDF Data Types

| Type | Description | Query Support |
|------|-------------|---------------|
| String | Text values | eq, noteq, beginsWith, endsWith, contains |
| Number | Numeric values | eq, noteq, gt, gte, lt, lte |
| Date | Date values | eq, noteq, gt, gte, lt, lte |
| List | Dropdown selections | eq, noteq, in, notIn |
| Boolean | True/false | eq |

## Querying UDFs

### Basic UDF Query

Add `"udf": true` to filter:

```json
GET /Companies/query

{
  "filter": [
    {
      "op": "eq",
      "field": "CustomerRanking",
      "udf": true,
      "value": "Golden"
    }
  ]
}
```

### Multiple UDF Conditions

**VB entities:** 1 UDF per query
**C# entities:** Up to 5 unique UDFs (same UDF can appear multiple times with different conditions)

```json
{
  "filter": [
    {
      "op": "eq",
      "field": "CustomerRanking",
      "udf": true,
      "value": "Golden"
    },
    {
      "op": "eq",
      "field": "Region",
      "udf": true,
      "value": "West"
    }
  ]
}
```

### UDF with IncludeFields

```json
{
  "IncludeFields": ["id", "companyName", "CustomerRanking"],
  "filter": [
    {
      "op": "exist",
      "field": "CustomerRanking",
      "udf": true
    }
  ]
}
```

### List UDF with IN Operator

```json
{
  "filter": [
    {
      "op": "in",
      "field": "ServiceTier",
      "udf": true,
      "value": ["Gold", "Platinum"]
    }
  ]
}
```

## Managing UDF Definitions

### Get All UDF Definitions for Entity

```json
GET /UserDefinedFieldDefinitions/query

{
  "filter": [
    {"op": "eq", "field": "parentObjectName", "value": "Ticket"}
  ]
}
```

### UDF Definition Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| name | string(45) | ✓ | Must be unique |
| udfType | integer | ✓ | Picklist, cannot change after creation |
| dataType | integer | ✓ | Picklist, cannot change after creation |
| description | string(128) | — | |
| defaultValue | string(1024) | — | Must match dataType |
| isActive | boolean | — | |
| isRequired | boolean | — | Cannot set True for Ticket/Task UDFs |
| isProtected | boolean | — | Default: false |
| isEncrypted | boolean | — | Default: false, cannot query encrypted data |
| isPrivate | boolean | — | Only for protected Asset UDFs of String type |
| isVisibleToClientPortal | boolean | — | Only for Asset/Ticket UDFs |
| displayFormat | integer | — | Picklist, only for String dataType |
| sortOrder | integer | — | Must be > 0, defaults to 1 |
| numberOfDecimalPlaces | integer | — | 1-4, defaults to 2 |
| mergeVariableName | string(100) | — | Must start with "var", must be unique |
| isFieldMapping | boolean | — | Read-only, restricts updates |
| createDate | datetime | — | Read-only |
| crmToProjectUdfId | long | — | Link to Opportunity UDF |

**Key Constraints:**
- Max active UDFs per entity type varies (50-500)
- Cannot delete UDFs via API
- Cannot query multi-select or reference UDFs
- Only 1 UDF per query (VB entities) or 5 unique UDFs (C# entities)
- `isEncrypted` cannot be True if `isProtected` is False
- `isRequired` cannot be True for Ticket/Task UDFs

### Get List UDF Values

```json
GET /UserDefinedFieldListItems/query

{
  "IncludeFields": ["id", "udfFieldId", "valueForDisplay", "valueForExport", "isActive"],
  "filter": [
    {"op": "eq", "field": "udfFieldId", "value": 123}
  ]
}
```

**List Item Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| udfFieldId | long | ✓ | References UserDefinedFieldDefinitions |
| valueForDisplay | string(128) | ✓ | Must be unique within UDF |
| valueForExport | string(128) | ✓ | Must be unique within UDF |
| isActive | boolean | — | Defaults to true on create |
| createDate | datetime | — | Read-only |

**Key Constraints:**
- Cannot change default display value
- Cannot delete via API (use parent entity)
- Both valueForDisplay and valueForExport must be unique per UDF

## UDF Response Format

UDF values appear in `userDefinedFields` array:

```json
{
  "items": [
    {
      "id": 12345,
      "companyName": "ACME Corp",
      "userDefinedFields": [
        {"name": "CustomerRanking", "value": "Golden"},
        {"name": "AccountManager", "value": "John Smith"},
        {"name": "ContractRenewalDate", "value": "2024-06-01"},
        {"name": "CustomCheckbox", "value": "true"}
      ]
    }
  ]
}
```

## Writing UDF Values

### Update via PUT/PATCH

```json
PATCH /Companies

{
  "id": 12345,
  "userDefinedFields": [
    {"name": "CustomerRanking", "value": "Platinum"},
    {"name": "Notes", "value": "Updated via API"}
  ]
}
```

### Create with UDFs

```json
POST /Tickets

{
  "companyID": 11111,
  "title": "New Ticket",
  "userDefinedFields": [
    {"name": "Source", "value": "Integration"},
    {"name": "Priority", "value": "High"}
  ]
}
```

## Protected UDFs

Protected UDFs require special permissions:
- Querying protected UDFs is case-sensitive
- API user must have Protected Data Permissions
- Values may be masked in responses

```json
{
  "filter": [
    {
      "op": "eq",
      "field": "SSN",
      "udf": true,
      "value": "123-45-6789"
    }
  ]
}
```

## UDF Patterns for Integrations

### Store External System IDs

```json
{
  "userDefinedFields": [
    {"name": "SalesforceID", "value": "001xx000003DGP0"},
    {"name": "JiraProjectKey", "value": "PROJ-123"},
    {"name": "ExternalSyncStatus", "value": "Synced"}
  ]
}
```

### Track Integration Metadata

```json
{
  "userDefinedFields": [
    {"name": "LastSyncDate", "value": "2024-01-15T10:30:00"},
    {"name": "SyncSource", "value": "Salesforce"},
    {"name": "ImportBatchID", "value": "BATCH-2024-01-15-001"}
  ]
}
```

### Custom Workflow Flags

```json
{
  "userDefinedFields": [
    {"name": "RequiresApproval", "value": "true"},
    {"name": "ApprovalStatus", "value": "Pending"},
    {"name": "ApprovedBy", "value": null}
  ]
}
```

## Best Practices

1. **Use UDFs for integration data** — Don't populate External fields
2. **Create dedicated UDFs** — One per integration purpose
3. **Use List types** — Enforce data consistency with dropdowns
4. **Document UDF names** — Keep a mapping of UDF names to purposes
5. **Handle null values** — UDFs may not exist on all records
6. **Check data type** — Query operators depend on UDF data type
7. **Limit UDF queries** — Max 5 unique UDFs per query (C# entities)
8. **Case sensitivity** — Protected UDF queries are case-sensitive

## Common Pitfalls

1. **Missing UDFs** — Not all entities support UDFs
2. **Wrong operators** — String UDFs can't use gt/lt
3. **Too many UDFs** — Max 5 per query can be limiting
4. **Protected data** — Requires special permissions
5. **Null handling** — `exist`/`notExist` for checking nulls
6. **List values** — Must match exact dropdown values
7. **Date format** — Use yyyy-mm-ddThh:mm:ss format

## Reference

- API Skill: `autotask-psa-api`
- Full Documentation: https://www.autotask.net/help/developerhelp/Content/APIs/REST/Entities/UserDefinedFieldDefinitionsEntity.htm
