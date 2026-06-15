---
name: autotask-psa-api
description: Use when integrating with Autotask PSA REST API to query, create, update, or delete PSA data including tickets, companies, contacts, projects, contracts, resources, time entries, and other entities
---

# Autotask PSA REST API Reference

## Overview

Autotask PSA exposes a REST API at `/atservicesrest/v1.0/` with ~226 entity types covering tickets, accounts, contacts, projects, contracts, billing, inventory, and more. All responses are JSON. Authentication uses API-only user credentials with a tracking integration code.

## Authentication

Four required headers:

| Header | Description |
|--------|-------------|
| `Username` | API user email |
| `Secret` | API user password |
| `APIIntegrationcode` | Vendor or custom integration tracking ID |
| `Content-Type` | `application/json` |

Optional: `ImpersonationResourceId` header to act as another resource.

**Key rules:**
- Only **API User (API-only)** security level can access REST API
- No per-seat charge; unlimited API-only users
- TLS 1.2 required
- SSO not supported for API
- Never expire API-only user passwords (they can't log into UI to change it)

## Zone Discovery

Autotask operates multiple geographic zones. First call `ZoneInformation` (unauthenticated) to get the correct base URL:

```
GET https://webservices[n].autotask.net/atservicesrest/v1.0/ZoneInformation?user={email}
```

Common zones:
- America East: `webservices3.autotask.net`
- America West: `webservices8.autotask.net`
- UK: `webservices4.autotask.net`
- EU1: `webservices5.autotask.net`
- Australia/NZ: `webservices6.autotask.net`

## Base URL Pattern

```
https://webservices[n].autotask.net/atservicesrest/v1.0/{EntityName}
```

## Entity Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/{EntityName}/{id}` | Get single record |
| GET | `/{EntityName}/query` | Query with filters |
| GET | `/{EntityName}/query/count` | Count matching records |
| POST | `/{EntityName}/query` | Complex query (body) |
| POST | `/{EntityName}` | Create record |
| PUT | `/{EntityName}` | Update record |
| PATCH | `/{EntityName}` | Partial update |
| DELETE | `/{EntityName}/{id}` | Delete record |

## Metadata Endpoints

| Endpoint | Returns |
|----------|---------|
| `/{EntityName}/entityInformation` | Entity capabilities (CRUD permissions) |
| `/{EntityName}/entityInformation/fields` | Field definitions and picklist values |
| `/{EntityName}/entityInformation/userDefinedFields` | UDF definitions |

## Query Syntax

### Basic Filter (GET)

```
?search={"filter":[{"op":"eq","field":"CompanyName","value":"ACME Corp"}]}
```

### Filter Operators

| Operator | Description |
|----------|-------------|
| `eq` | Equals |
| `noteq` | Not equals |
| `gt` / `gte` | Greater than (or equal) |
| `lt` / `lte` | Less than (or equal) |
| `beginsWith` | Starts with |
| `endsWith` | Ends with |
| `contains` | Contains string |
| `exist` | Field is not null |
| `notExist` | Field is null |
| `in` | Value in list |
| `notIn` | Value not in list |

### AND/OR Grouping

```json
{
  "filter": [
    {"op": "eq", "field": "IsActive", "value": true},
    {
      "op": "or",
      "items": [
        {"op": "eq", "field": "Status", "value": 1},
        {"op": "eq", "field": "Status", "value": 2}
      ]
    }
  ]
}
```

Max 500 OR conditions per call.

### UDF Queries

Add `"udf": true` to filter on user-defined fields:

```json
{"op": "eq", "field": "CustomerRanking", "udf": true, "value": "Golden"}
```

### Field Selection

```json
{
  "IncludeFields": ["Id", "companyName", "phone"],
  "filter": [...]
}
```

### MaxRecords

```json
{"MaxRecords": 100, "filter": [...]}
```

Range: 1-500 per page.

## Pagination

Response includes `pageDetails`:

```json
{
  "items": [...],
  "pageDetails": {
    "count": 500,
    "requestCount": 500,
    "prevPageUrl": null,
    "nextPageUrl": "https://.../query/next?paging=..."
  }
}
```

- Max 500 records per page
- Follow `nextPageUrl` until null
- API retains 50 most recent pages
- Alternative: loop with `id > max_id_previous`

## Rate Limits

| Usage | Added Latency |
|-------|---------------|
| 0-49.99% of 10,000/hr | 0 sec |
| 50-74.99% | 0.5 sec |
| 75%+ | 1 sec |

Monitor via: `GET /v1.0/ThresholdInformation`

## Key Entities for Common Operations

### Tickets
- `Tickets` - Service requests
- `TicketNotes` - Notes on tickets
- `TicketCharges` - Costs on tickets
- `TicketHistory` - Field change tracking
- `TicketSecondaryResources` - Additional resources (max 50 per ticket)
- `TicketCategories` - Ticket type definitions
- `ServiceLevelAgreementResults` - SLA data
- `TicketChecklistItems` - Checklist items (max 40 per ticket)
- `TicketAdditionalContacts` - Additional contacts (max 30 per ticket)
- `TicketAdditionalConfigurationItems` - Additional assets (max 100 per ticket)
- `TicketTagAssociations` - Tags (max 30 per ticket)

**Tickets Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| ticketNumber | string(50) | — | Custom prefix allowed TYYYYMMDD |
| title | string(255) | ✓ | |
| status | integer | ✓ | 1=New, 2=In Progress, 3=Waiting Customer, 4=Waiting Vendor, 5=Complete, 6=Cancelled, 7=Resolved |
| priority | integer | ✓ | Must be active on create |
| companyID | integer | ✓ | Cannot change if ticket has posted time/charges |
| contactID | integer | — | Must match ticket company or parent |
| assignedResourceID | integer | — | Primary resource |
| assignedResourceroleID | integer | — | Role for primary resource |
| queueID | integer | — | Required based on category setting |
| issueType | integer | — | Never required in API |
| subIssueType | integer | — | Depends on issueType |
| ticketType | integer | — | Default: Service Request |
| source | integer | — | Default: "Other" in API |
| billingCodeID | integer | — | Work Type allocation code |
| contractID | integer | — | Active contract for account |
| configurationItemID | integer | — | Must belong to ticket company |
| projectID | integer | — | Link to project |
| dueDateTime | datetime | ✓ | Based on category settings |
| estimatedHours | decimal | — | |
| description | string(8000) | — | Rich Text lost via API |
| resolution | string(32000) | — | |
| createDate | datetime | — | Read-only |
| completedDate | datetime | — | Read-only |
| lastActivityDate | datetime | — | Read-only |
| firstResponseDateTime | datetime | — | Read-only |
| firstResponseDueDateTime | datetime | — | Read-only |
| resolvedDateTime | datetime | — | Read-only |
| resolvedDueDateTime | datetime | — | Read-only |
| serviceLevelAgreementID | integer | — | Auto-determined via fallback |

### Companies & Contacts
- `Companies` - Accounts/organizations (max 200 UDFs, cannot delete)
- `Contacts` - Individuals at companies (max 100 UDFs)
- `CompanyNotes` - Account notes
- `CompanyLocations` - Business locations (max 5,000 per company)
- `CompanyAlerts` - Alert messages
- `CompanyTeams` - Account team resources
- `CompanyCategories` - Category definitions
- `ContactGroups` - Contact groupings
- `ContactGroupContacts` - Contact-group associations
- `ClientPortalUsers` - Portal access

**Companies Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| companyName | string(100) | ✓ | |
| companyType | short | ✓ | 1=Customer, 2=Lead, 3=Prospect, 4=Dead, 5=Cancelation, 6=Vendor, 7=Partner |
| companyCategoryID | integer | — | Default category if omitted |
| ownerResourceID | integer | ✓ | Account Manager, must be active CRM user |
| phone | string(25) | ✓ | |
| address1 | string(150) | — | |
| address2 | string(128) | — | |
| city | string(30) | — | |
| state | string(40) | — | |
| postalCode | string(30) | ✓ | |
| countryID | integer | — | |
| isActive | boolean | — | Default: true |
| parentCompanyID | integer | — | Parent organization |
| webAddress | string(255) | — | |
| marketSegmentID | integer | — | |
| territoryID | integer | — | |
| classification | integer | — | |
| createDate | datetime | — | Read-only |
| lastActivityDate | datetime | — | Read-only |
| lastTrackedModifiedDateTime | datetime | — | Read-only |
| currencyID | integer | — | Read-only after creation |

**Contacts Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| firstName | string(20) | ✓ | |
| lastName | string(20) | ✓ | |
| companyID | integer | ✓ | Read-only after creation |
| emailAddress | string(50) | — | Max 254 chars enforced |
| phone | string(25) | — | |
| isActive | integer | ✓ | |
| primaryContact | boolean | — | Only one per company |
| title | string(50) | — | |
| createDate | datetime | — | Read-only |
| lastModifiedDate | datetime | — | Read-only |

### Projects & Tasks
- `Projects` - Project definitions (max 200 UDFs)
- `Tasks` - Work items within projects (max 100 UDFs)
- `Phases` - Project sub-groups
- `TaskPredecessors` - Dependencies
- `TaskSecondaryResources` - Additional resources (max 50 per task)
- `ProjectCharges` - Project costs
- `ProjectNotes` - Project notes

**Projects Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| projectName | string(100) | ✓ | |
| companyID | integer | ✓ | Read-only after creation |
| projectType | integer | ✓ | Read-only, Baseline projects are read-only via API |
| status | integer | — | Picklist |
| startDateTime | datetime | ✓ | Cannot update if tasks exist |
| endDateTime | datetime | ✓ | Must be >= latest task/phase end |
| estimatedHours | decimal | — | Read-only |
| actualHours | decimal | — | Read-only |
| estimatedSalesCost | decimal | — | |
| laborEstimatedCosts | decimal | — | |
| laborEstimatedRevenue | decimal | — | |
| laborEstimatedMarginPercentage | decimal | — | Read-only |
| projectLeadResourceID | integer | — | |
| contractID | integer | — | |
| description | string(2000) | — | |
| completedPercentage | integer | — | Read-only |

**Tasks Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| title | string(255) | ✓ | |
| projectID | integer | ✓ | Cannot change on update |
| status | integer | ✓ | Picklist, 5=Complete zeros remainingHours |
| taskType | integer | ✓ | Picklist |
| startDateTime | datetime | — | |
| endDateTime | datetime | — | Time component ignored |
| estimatedHours | decimal | — | |
| assignedResourceID | integer | — | |
| assignedResourceroleID | integer | — | |
| billingCodeID | integer | — | Work Type, required if resource assigned |
| phaseID | integer | — | |
| priorityLabel | integer | — | Picklist |
| description | string(8000) | — | Rich Text lost via API |
| completedDateTime | datetime | — | Read-only |
| remainingHours | decimal | — | Not queryable, set to 0 when complete |

### Contracts & Billing
- `Contracts` - Billing arrangements (max 50 UDFs, cannot delete)
- `ContractServices` - Services on recurring contracts
- `ContractServiceBundles` - Service bundles on contracts
- `ContractBlocks` - Block hour purchases
- `ContractRetainers` - Retainer payments
- `ContractMilestones` - Fixed price milestones
- `ContractTicketPurchases` - Per-ticket prepayments
- `ContractBillingRules` - Automated charge rules
- `ContractRates` - Role rate overrides
- `ContractRoleCosts` - Internal cost rates
- `ContractExclusionSets` - Reusable exclusion sets
- `ContractExclusionRoles` - Excluded roles
- `ContractExclusionBillingCodes` - Excluded work types
- `ContractServiceAdjustments` - Service quantity changes (create only)
- `ContractServiceBundleAdjustments` - Bundle quantity changes (create only)
- `ContractServiceUnits` - Service units by period (query only)
- `ContractServiceBundleUnits` - Bundle units by period (query only)
- `ContractBlockHourFactors` - Block hour multipliers
- `ContractNotes` - Contract notes
- `ContractCharges` - Contract-level costs
- `BillingItems` - Approved/posted billable items (query/update only)
- `BillingCodes` - Allocation codes (query only)
- `BillingItemApprovalLevels` - Multi-level approvals
- `Invoices` - Invoiced billing items (mostly read-only)
- `InvoiceTemplates` - Template definitions (query only)

**Contracts Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| contractName | string(100) | ✓ | |
| contractType | integer | ✓ | Read-only, 1=Time&Materails, 2=FixedPrice, 3=BlockHours, 4=Retainer, 5=Incident, 7=RecurringService |
| companyID | integer | ✓ | Read-only after create |
| status | integer | ✓ | Picklist |
| startDate | datetime | ✓ | Must be < endDate |
| endDate | datetime | ✓ | |
| billingPreference | integer | ✓ | Default: 2 (Reconcile Billing) |
| contactID | integer | — | |
| serviceLevelAgreementID | integer | — | Picklist |
| description | string(2000) | — | |
| estimatedHours | decimal | — | Not for RecurringService |
| estimatedCost | decimal | — | Not for RecurringService |
| estimatedRevenue | decimal | — | Not for RecurringService |
| exclusionContractID | long | — | Read-only |
| isDefaultContract | boolean | — | |
| isCompliant | boolean | — | Can set False only for RecurringService |

**ContractBlocks Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| contractID | integer | ✓ | Must be BlockHour type |
| hours | decimal | ✓ | Must be >= hoursApproved when updating |
| hourlyRate | decimal | ✓ | Cannot change when billed |
| startDate | datetime | ✓ | Must be within contract dates |
| endDate | datetime | ✓ | Must be within contract dates |
| datePurchased | datetime | ✓ | |
| hoursApproved | decimal | — | Read-only, not queryable |
| isPaid | boolean | — | Read-only |

**BillingItems Key Fields (mostly read-only):**
| Field | Type | Notes |
|-------|------|-------|
| id | long | Read-only |
| companyID | integer | Read-only |
| contractID | integer | Read-only |
| ticketID | integer | Read-only |
| taskID | integer | Read-only |
| timeEntryID | integer | Read-only |
| billingCodeID | integer | Read-only |
| roleID | integer | Read-only |
| quantity | decimal | Read-only |
| rate | decimal | Read-only |
| extendedPrice | decimal | Read-only |
| ourCost | decimal | Read-only, requires cost permissions |
| postedDate | datetime | Read-only |
| itemDate | datetime | Read-only |
| webServiceDate | datetime | Only writable field |
| billingItemType | integer | 1=Labor, 2=ProjectCost, 3=Cost, 4=Expense, 5=Subscription, 6=RecurringService, 7=RecurringServices, 8=Milestone |

### Resources & Time
- `Resources` - Employees/contractors (cannot delete)
- `TimeEntries` - Time logged against tickets/tasks (no UDFs)
- `ResourceRoles` - Resource-role relationships (query only)
- `ResourceRoleDepartments` - Resource-role-department links
- `ResourceRoleQueues` - Resource-role-queue links
- `ResourceServiceDeskRoles` - Service desk role assignments
- `ResourceSkills` - Resource skills for matching
- `ResourceDailyAvailabilities` - Daily availability/hours
- `ResourceTimeOffBalances` - Time off balances (query only)
- `ResourceTimeOffAdditional` - Additional time off granted
- `ResourceTimeOffApprovers` - Timesheet approvers (query only)
- `TimeOffRequests` - Time off requests
- `TimeOffRequestsApprove` - Approval actions (create only)
- `TimeOffRequestsReject` - Rejection actions (create only)
- `Departments` - Organizational departments
- `Roles` - Billing roles with rates
- `Appointments` - Calendar appointments
- `CompanyToDos` - CRM to-dos

**Resources Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| firstName | string(50) | ✓ | |
| lastName | string(50) | ✓ | |
| email | string(254) | ✓ | |
| userName | string(32) | ✓ | Must be unique |
| isActive | boolean | ✓ | |
| resourceType | string(15) | ✓ | Picklist |
| licenseType | integer | ✓ | Read-only |
| locationID | integer | ✓ | Read-only |
| userType | integer | ✓ | Security level, read-only |
| hireDate | datetime | ✓ | Read-only |
| dateFormat | string(20) | — | Read-only |
| timeFormat | string(20) | — | Read-only |
| numberFormat | string(20) | ✓ | Picklist |
| title | string(50) | — | Job title |
| payrollIdentifier | string(32) | — | |
| internalCost | decimal | — | Read-only, returns 0 without permissions |
| surveyResourceRating | decimal | — | Read-only |

**TimeEntries Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| resourceID | integer | ✓ | |
| roleID | integer | ✓ | Must be valid for resource |
| dateWorked | datetime | — | Required if no startDateTime, set to midnight |
| startDateTime | datetime | — | |
| endDateTime | datetime | — | |
| hoursWorked | decimal | — | Calculated if empty, must be 0-24 |
| hoursToBill | decimal | — | Read-only |
| billingCodeID | integer | — | Active Work Type |
| contractID | integer | — | Active contract for account |
| ticketID | integer | — | For ticket time |
| taskID | integer | — | For task time |
| timeEntryType | integer | — | 2=Ticket, 6=Task |
| isNonBillable | boolean | — | Default from ticket/task |
| summaryNotes | string(32000) | — | Required for tickets |
| internalNotes | string(32000) | — | |
| showOnInvoice | boolean | — | Requires ticket/taskID |
| createDateTime | datetime | — | Read-only |
| lastModifiedDateTime | datetime | — | Read-only |
| billingApprovalLevelMostRecent | integer | — | Read-only |
| billingApprovalDateTime | datetime | — | |
| billingApprovalResourceID | integer | — | |

### Products & Inventory
- `Products` - Hardware/software/materials (max 100 UDFs, cannot delete)
- `ProductTiers` - Pricing tiers
- `ProductVendors` - Vendor associations
- `ProductNotes` - Product notes
- `InventoryItems` - Products in inventory (query/create)
- `InventoryLocations` - Storage locations
- `InventoryProducts` - Product-location associations
- `InventoryStockedItems` - On-hand quantities (query/update only)
- `InventoryStockedItemsAdd` - Increase stock (create only)
- `InventoryStockedItemsRemove` - Decrease stock (create only)
- `InventoryStockedItemsTransfer` - Transfer stock (create only)
- `InventoryTransfers` - Transfer history
- `InventoryItemSerialNumbers` - Serial number tracking
- `PurchaseOrders` - Procurement orders
- `PurchaseOrderItems` - PO line items
- `PurchaseOrderItemReceiving` - Receiving transactions
- `PurchaseApprovals` - Purchase approvals

**Products Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| name | string(1000) | — | Picklist |
| isActive | boolean | ✓ | |
| isSerialized | boolean | ✓ | Must be false for non-Standard billing |
| productCategory | integer | — | Picklist |
| productBillingCodeID | integer | ✓ | Deprecated, use chargeBillingCodeID |
| chargeBillingCodeID | integer | ✓ | |
| unitCost | decimal | — | Requires cost permissions |
| unitPrice | decimal | — | |
| mSRP | decimal | — | |
| billingType | integer | — | Default: Standard |
| periodType | integer | — | Must be Monthly for non-Standard billing |
| priceCostMethod | integer | — | Default: Standard |
| description | string(8000) | — | |
| manufacturerName | string(100) | — | |
| sKU | string(50) | — | |
| externalProductID | string(50) | — | |
| createdByResourceID | integer | — | Read-only |
| createdTime | datetime | — | Read-only |

**InventoryLocations Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| locationName | string(50) | ✓ | Must be unique |
| isActive | boolean | ✓ | |
| isDefault | boolean | — | Read-only, cannot inactivate default |
| resourceID | integer | — | Read-only |

**PurchaseOrders Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| vendorID | integer | ✓ | Must be Vendor type company |
| status | integer | ✓ | 1=New, 2=Submitted, 3=Partial, 4=Received, 5=Cancelled |
| shipToName | string(100) | ✓ | |
| shipToAddress1 | string(128) | ✓ | |
| purchaseOrderNumber | string(50) | — | Read-only |
| createDateTime | datetime | — | Read-only |
| vendorInvoiceNumber | string(50) | — | Read-only after receipt |

### Quotes & Opportunities
- `Quotes` - Sales quotes (cannot delete)
- `QuoteItems` - Line items on quotes
- `QuoteTemplates` - Template definitions (query only)
- `Opportunities` - Forecasted business (max 200 UDFs, cannot delete)
- `OpportunityCategories` - Category definitions
- `OpportunityAttachments` - Attachments
- `SalesOrders` - Quote cost tracking (auto-created, max 100 UDFs)
- `SalesOrderAttachments` - Attachments

**Opportunities Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| title | string(128) | ✓ | |
| companyID | integer | ✓ | |
| ownerResourceID | integer | ✓ | Must be active CRM resource |
| status | integer | ✓ | Picklist |
| amount | decimal | ✓ | |
| probability | integer | ✓ | 0-100 |
| projectedCloseDate | datetime | ✓ | Must be >= startDate |
| startDate | datetime | ✓ | Read-only, creation date |
| stage | integer | — | Read-only, picklist |
| closedDate | datetime | — | |
| lostDate | datetime | — | Auto-set when status=Lost |
| cost | decimal | ✓ | |
| description | string(8000) | — | |
| lossReason | integer | — | Picklist |
| winReason | integer | — | Picklist |
| leadSource | integer | — | Picklist |
| rating | integer | — | Picklist |
| contactID | integer | — | Must match company |
| opportunityCategoryID | integer | — | Picklist |
| salesOrderID | integer | — | Read-only |

**Quotes Key Fields:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | long | ✓ | Read-only |
| name | string(100) | ✓ | |
| opportunityID | integer | ✓ | Read-only after create |
| effectiveDate | datetime | ✓ | |
| expirationDate | datetime | ✓ | Must be >= effectiveDate |
| billToLocationID | integer | ✓ | |
| shipToLocationID | integer | ✓ | |
| soldToLocationID | integer | ✓ | |
| companyID | integer | — | Read-only after create |
| contactID | integer | — | Must match company |
| quoteNumber | integer | — | Read-only |
| primaryQuote | boolean | — | One per opportunity |
| quoteTemplateID | integer | — | |
| paymentTerm | integer | — | Picklist |
| comment | string(1000) | — | |

### Services & Subscriptions
- `Services` - Recurring service definitions
- `ServiceBundles` - Grouped services
- `ServiceBundleServices` - Bundle-service associations
- `Subscriptions` - Recurring billing for assets
- `SubscriptionPeriods` - Billing period items (query only)
- `ServiceCalls` - Scheduled service instances
- `ServiceCallTickets` - Ticket assignments to service calls
- `ServiceCallTasks` - Task assignments to service calls
- `ServiceLevelAgreementResults` - SLA compliance data (query only)

### Knowledge Base & Documents
- `KnowledgeBaseArticles` - KB articles
- `KnowledgeBaseCategories` - KB categories (4 levels max)
- `Documents` - Document management
- `DocumentCategories` - Document categories (3 levels max)
- `AttachmentInfo` - Attachment metadata (query only)

### Tags & Classification
- `Tags` - Ticket/article tags (max 25,000 non-system)
- `TagGroups` - Tag groupings
- `TagAliases` - Tag aliases
- `TicketTagAssociations` - Ticket-tag links (max 30 per ticket)
- `ClassificationIcons` - Company classification icons (query only)
- `ActionTypes` - CRM note/to-do types

### Expense Management
- `ExpenseReports` - Expense submissions
- `ExpenseItems` - Expense line items

### Organizational Structure
- `OrganizationalLevel1` - Branch/Division (max 50 UDFs)
- `OrganizationalLevel2` - Line of Business
- `OrganizationalLevelAssociations` - Level1-Level2 pairings
- `OrganizatonalResources` - Resource-org associations (query only)

### Multi-Currency
- `Currencies` - Currency definitions
- `PriceListRoles` - External currency role rates
- `PriceListProducts` - External currency product prices
- `PriceListProductTiers` - External currency tier prices
- `PriceListServices` - External currency service prices
- `PriceListServiceBundles` - External currency bundle prices
- `PriceListMaterialCodes` - External currency material code prices
- `PriceListWorkTypeModifiers` - External currency work type modifiers
- `WorkTypeModifiers` - Work type rate modifiers

### User-Defined Fields
- `UserDefinedFieldDefinitions` - UDF definitions (max 500 per entity type)
- `UserDefinedFieldListItems` - List UDF values

### System & Utility
- `Version` - Autotask version (query only)
- `Modules` - Module availability (query only)
- `Countries` - Country definitions
- `TaxCategories` - Tax categories
- `TaxRegions` - Tax regions
- `Taxes` - Tax rates
- `PaymentTerms` - Payment terms
- `InvoiceTemplates` - Invoice templates (query only)
- `InternalLocations` - Internal locations (query only)
- `InternalLocationWithBusinessHours` - Business hours settings
- `HolidaySets` - Holiday sets
- `Holidays` - Holiday dates
- `Skills` - Resource skills (query only)
- `ShippingTypes` - Shipping carriers (query only)
- `NotificationHistory` - Notification log (query only)
- `Surveys` - Survey definitions (query only)
- `SurveyResults` - Survey responses (query only)
- `CompanySiteConfigurations` - Site config UDFs (max 500 UDFs)
- `ConfigurationItemTypes` - Asset types

### Audit & Logging
- `TicketHistory` - Ticket field changes (query only, filter by ticketID only)
- `DeletedTicketLogs` - Deleted ticket records (query only)
- `DeletedTicketActivityLogs` - Deleted ticket activity (query only)
- `DeletedTaskActivityLogs` - Deleted task activity (query only)
- `WebhookEventErrorLogs` - Webhook error logs

### Co-Management
- `ComanagedAssociations` - Co-managed account-resource links
- `ClientPortalUsers` - Portal user access

## Date-Time Format

All timestamps in UTC: `yyyy-mm-ddThh:mm:ss.ms`

Date-only fields force time to midnight (no timezone conversion).

## Boolean Values

Must be `true` or `false` - null or other values return errors.

## CRUD Operations

### POST (Create)
- Set `id` to `"0"` for new records
- Response returns `itemId` on success (HTTP 200)
- Errors return JSON array: `{"errors":["message"]}`
- Treat any non-200 response as error

### PUT (Update)
- Updates ALL properties; omitted fields set to null
- Must include `id` and all existing writable fields
- No JSON response body on success

### PATCH (Partial Update)
- Updates ONLY specified fields; omitted fields unchanged
- More efficient than PUT for partial changes
- Must include `id`

### DELETE
- URL: `/{EntityName}/{id}`
- No request body needed
- Success returns `itemId`

## Special Notes

### Rich Text Fields
- API returns text-only content
- Updating Rich Text fields loses formatting and images
- Affects: description, notes, resolution fields

### Read-Only Entities
Some entities are query-only:
- BillingCodes, BillingItems, BillingItemApprovalLevels
- InvoiceTemplates, QuoteTemplates
- InternalLocations, Modules, Version
- ResourceRoles, ResourceTimeOffBalances, ResourceTimeOffApprovers
- ServiceLevelAgreementResults, TicketHistory
- DeletedTicketLogs, DeletedTicketActivityLogs, DeletedTaskActivityLogs
- NotificationHistory, Surveys, SurveyResults
- Skills, ShippingTypes, ClassificationIcons
- SubscriptionPeriods, ContractServiceUnits, ContractServiceBundleUnits

### Entities with Create-Only Operations
- ContractServiceAdjustments
- ContractServiceBundleAdjustments
- InventoryStockedItemsAdd, InventoryStockedItemsRemove, InventoryStockedItemsTransfer
- TimeOffRequestsApprove, TimeOffRequestsReject
- BillingItemApprovalLevels
- PurchaseOrderItemReceiving

### Cost Data Permissions
Many cost-related fields return no data without proper permissions:
- Products: unitCost, markupRate
- BillingItems: ourCost, extendedCost
- ContractRoleCosts: rate
- TimeEntries: (indirect via billing)
- InventoryStockedItems: unitCost

## Best Practices

1. **Use webhooks over polling** - Near real-time, reduces API consumption
2. **Query by LastModifiedDate** - Return only changed records
3. **Serialize requests** - Minimize concurrency lock issues
4. **Use POST for complex queries** - Avoids 2048-char URL limit
5. **Monitor threshold usage** - Check `/ThresholdInformation` endpoint
6. **Don't use External fields** - Use UDFs for integration data
7. **Set Ticket.Source** - Identify integration-created tickets
8. **Copy API security level** - Don't modify the default system level

## Swagger UI

Access at: `[platform URL]/swagger/ui/index`

Use to browse entities, test queries, and explore field definitions interactively.

## Webhooks

Supported entities: Companies, Contacts, ConfigurationItems, Tickets, TicketNotes

Events: Create, Update, Delete, Deactivate

Requires `Can create WebHooks` permission on security level.

## Reference Documentation

Full documentation: https://www.autotask.net/help/developerhelp/Content/0_HOME/HOME.htm
