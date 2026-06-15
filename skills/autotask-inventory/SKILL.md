---
name: autotask-inventory
description: Use when managing Autotask inventory operations including stock levels, transfers between locations, purchase orders, receiving, serial numbers, and inventory reporting
---

# Autotask Inventory Management

## Overview

Autotask inventory tracks products at physical/virtual locations with support for stocking, transfers, receiving, and serial number management.

**Required:** Use `autotask-psa-api` skill for authentication and query syntax.

## Entity Relationships

```
Products
├── InventoryProducts (product-location associations)
│   ├── InventoryStockedItems (on-hand quantities)
│   └── InventoryItemSerialNumbers (serial tracking)
├── ProductVendors (vendor associations)
├── ProductTiers (pricing tiers)
└── ProductNotes

InventoryLocations (storage locations)
├── InventoryStockedItems
└── InventoryTransfers

PurchaseOrders
├── PurchaseOrderItems
└── PurchaseOrderItemReceiving
```

## Key Entities

| Entity | Purpose |
|--------|---------|
| `Products` | Product definitions (hardware, software, materials) |
| `InventoryLocations` | Physical/virtual storage locations |
| `InventoryProducts` | Product-location associations |
| `InventoryStockedItems` | On-hand quantities at locations |
| `InventoryItems` | Products with location associations |
| `InventoryItemSerialNumbers` | Serial number tracking |
| `InventoryTransfers` | Transfer transactions |
| `PurchaseOrders` | Procurement orders |
| `PurchaseOrderItems` | Line items on POs |
| `PurchaseOrderItemReceiving` | Receiving transactions |

## Stock Level Queries

### Inventory Products (Product-Location Associations)

```json
GET /InventoryProducts/query

{
  "IncludeFields": ["productID", "inventoryLocationID", "onHandUnits", "availableUnits", "reservedUnits", "pickedUnits", "unitsOnOrder", "quantityMinimum", "quantityMaximum", "bin", "referenceNumber"],
  "filter": [
    {"op": "exist", "field": "productID"}
  ]
}
```

**Key Fields:**
- `onHandUnits` - Read-only, calculated from stocked items
- `availableUnits` - Read-only
- `reservedUnits` - Read-only
- `pickedUnits` - Read-only
- `unitsOnOrder` - Read-only
- `quantityMinimum` - Required, must be >= 0
- `quantityMaximum` - Required, must be >= quantityMinimum
- `inventoryLocationID` - Read-only on update
- `productID` - Required on create

### Inventory Stocked Items (Detailed On-Hand)

```json
GET /InventoryStockedItems/query

{
  "IncludeFields": ["inventoryProductID", "onHandUnits", "availableUnits", "reservedUnits", "pickedUnits", "deliveredUnits", "transferredUnits", "removedUnits", "unitCost", "serialNumber", "statusID"],
  "filter": [
    {"op": "exist", "field": "inventoryProductID"}
  ]
}
```

**Key Fields:**
- All quantity fields are read-only
- `unitCost` - Can update, requires cost permissions
- `serialNumber` - Can update only for serialized products
- `statusID` - Can update only for serialized products (picklist)

**Serialized Items:** Sum of onHandUnits + reservedUnits + transferredUnits + removedUnits + pickedUnits + deliveredUnits = 1

**Non-serialized Items:** Sum equals purchaseOrderItemReceiving.quantityPreviouslyReceived

### Low Stock Alert (Below Reorder Point)

```json
GET /InventoryProducts/query

{
  "IncludeFields": ["productID", "inventoryLocationID", "onHandUnits", "quantityMinimum"],
  "filter": [
    {"op": "exist", "field": "productID"}
  ]
}
```

**Note:** Filter client-side where `onHandUnits <= quantityMinimum`

### Out of Stock Items

```json
GET /InventoryProducts/query

{
  "IncludeFields": ["productID", "inventoryLocationID", "onHandUnits"],
  "filter": [
    {"op": "eq", "field": "onHandUnits", "value": 0}
  ]
}
```

## Inventory Transfers

### Transfer History

```json
GET /InventoryTransfers/query

{
  "IncludeFields": ["productID", "fromLocationID", "toLocationID", "quantityTransferred", "transferDate", "transferByResourceID", "serialNumber", "notes"],
  "filter": [
    {"op": "gte", "field": "transferDate", "value": "2024-01-01"}
  ]
}
```

**Key Fields:**
- `fromLocationID` - Source location (required, must have inventory)
- `toLocationID` - Destination location (required, must be active, cannot equal fromLocationID)
- `quantityTransferred` - Must be <= quantityOnHand, must be > 0
- `serialNumber` - Required for serialized products, quantityTransferred must = 1
- `notes` - Defaults to "Updated using Web Services API" if empty
- `transferByResourceID` - Read-only

### Execute Transfer

```json
POST /InventoryStockedItemsTransfer

{
  "inventoryProductID": 12345,
  "newInventoryLocationID": 200,
  "quantityBeingTransfered": 5,
  "reasonForUpdate": "Transfer to new location"
}
```

**Key Fields:**
- `inventoryProductID` - Either this OR `inventoryStockedItemID` required
- `inventoryStockedItemID` - For specific stocked item
- `newInventoryLocationID` - Required (destination)
- `quantityBeingTransfered` - Required
- `reasonForUpdate` - Required if system setting enabled

**Note:** Create only - all fields return errors if queried.

## Stock Adjustments

### Add Stock

```json
POST /InventoryStockedItemsAdd

{
  "inventoryProductID": 12345,
  "vendorID": 67890,
  "quantityBeingAdded": 10,
  "determineCostUsing": 3,
  "determineNewPriceUsing": 3,
  "reasonForUpdate": "Manual stock addition"
}
```

**Key Fields:**
- `inventoryProductID` - Required
- `vendorID` - Required
- `quantityBeingAdded` - Must be 1 for serialized, non-zero for non-serialized
- `determineCostUsing` - Picklist: 1=AverageCost, 2=LastReceivedCost, 3=CatalogCost, 4=ManualEntry
- `determineNewPriceUsing` - Picklist: 1=CostOfItems, 2=PercentageOfCost, 3=CatalogPrice, 4=PercentageOfCatalog, 5=ManualEntry
- `serialNumber` - Required for serialized products
- `unitCost` - Required if determineCostUsing=4
- `returnPrice` - Required if determineNewPriceUsing=5
- `pricePercentage` - Required if determineNewPriceUsing=2 or 4
- `vendorInvoiceNumber` - Required if system setting enabled

**Note:** Create only - all fields return errors if queried.

### Remove Stock

```json
POST /InventoryStockedItemsRemove

{
  "inventoryProductID": 12345,
  "quantityBeingRemoved": 2,
  "reasonForUpdate": "Damaged goods"
}
```

**Key Fields:**
- `inventoryProductID` - Either this OR `inventoryStockedItemID` required
- `inventoryStockedItemID` - For specific stocked item (non-serialized only)
- `quantityBeingRemoved` - Required, cannot exceed available units
- `reasonForUpdate` - Required if system setting enabled

**Serialized Items:** Sets onHandUnits=0, removedUnits=1

**Non-serialized Items:** Removes from oldest stocked items first

**Note:** Cannot remove reserved, picked, delivered, or removed units.

## Purchase Orders

### Open POs

```json
GET /PurchaseOrders/query

{
  "IncludeFields": ["id", "vendorID", "status", "createDateTime", "submitDateTime", "latestEstimatedArrivalDate", "purchaseOrderNumber", "vendorInvoiceNumber", "shipToName", "shipToAddress1", "shipToCity", "shipToState", "shipToPostalCode"],
  "filter": [
    {"op": "noteq", "field": "status", "value": 5}
  ]
}
```

**Status Values:**
- 1=New (can add items)
- 2=Submitted (can receive)
- 3=ReceivedPartial (can receive)
- 4=ReceivedFull (limited updates)
- 5=Cancelled

**Key Fields:**
- `vendorID` - Required, must be Vendor type company
- `status` - Required, picklist
- `shipToName` - Required
- `shipToAddress1` - Required
- `purchaseOrderNumber` - Read-only, auto-generated
- `vendorInvoiceNumber` - Read-only after receipt
- `createDateTime` - Read-only
- `submitDateTime` - Read-only

### PO Line Items

```json
GET /PurchaseOrderItems/query

{
  "IncludeFields": ["orderID", "productID", "inventoryLocationID", "quantity", "unitCost", "memo", "estimatedArrivalDate"],
  "filter": [
    {"op": "eq", "field": "orderID", "value": 54321}
  ]
}
```

**Key Fields:**
- `orderID` - Required, must be PO with status=New
- `productID` - Either this OR `chargeID` required
- `chargeID` - Must have status=NeedToOrder/Fulfill
- `inventoryLocationID` - Required, must be active
- `quantity` - Required, must be >= 1
- `unitCost` - Required, must be >= 0.00

**Multi-currency:** `unitCost` assumed in vendor currency; `internalCurrencyUnitCost` returns internal currency.

### Receive PO Items

```json
POST /PurchaseOrderItemReceiving

{
  "purchaseOrderItemID": 99999,
  "quantityNowReceiving": 5,
  "receiveDate": "2024-01-15",
  "serialNumber": "SN001"
}
```

**Key Fields:**
- `purchaseOrderItemID` - Required, must be valid
- `quantityNowReceiving` - Required, must be > 0 for non-serialized, must be 1 for serialized
- `receiveDate` - Optional
- `serialNumber` - Required for serialized products, must be unique
- `receivedByResourceID` - Read-only
- `quantityPreviouslyReceived` - Read-only
- `quantityBackOrdered` - Read-only

**Constraints:**
- Sum of quantityNowReceiving + quantityPreviouslyReceived must be <= PO item quantity
- Associated PO must have status=Submitted or ReceivedPartial
- Vendor invoice number required if system setting enabled
- Can receive even after PO is "received in full"

**Note:** Create only - all fields return errors if queried.

## Serial Number Tracking

### Get Serial Numbers for Item

```json
GET /InventoryItemSerialNumbers/query

{
  "IncludeFields": ["inventoryItemID", "serialNumber", "status"],
  "filter": [
    {"op": "eq", "field": "inventoryItemID", "value": 12345}
  ]
}
```

### Search by Serial Number

```json
{
  "filter": [
    {"op": "eq", "field": "serialNumber", "value": "SN123456"}
  ]
}
```

## Location Management

### List All Locations

```json
GET /InventoryLocations/query

{
  "IncludeFields": ["id", "name", "isActive"]
}
```

### Stock Summary by Location

```json
GET /InventoryStockedItems/query

{
  "IncludeFields": ["inventoryLocationID", "productID", "quantityOnHand"],
  "filter": [
    {"op": "eq", "field": "inventoryLocationID", "value": 100}
  ]
}
```

## KPI Patterns

### Inventory Value

```javascript
// For each stocked item:
// value = quantityOnHand * product.unitCost
// Total inventory value = SUM of all item values
```

### Stock Turnover

```javascript
// turnover = quantitySold / averageQuantityOnHand
// Query billing items for quantitySold, stocked items for average
```

### Days of Supply

```javascript
// daysOfSupply = quantityOnHand / averageDailyUsage
// Track usage from billing items or ticket charges
```

### Reorder Alerts

```javascript
// Query all stocked items where quantityOnHand <= reorderPoint
// Generate purchase order recommendations
```

## Best Practices

1. **Verify product-location mapping** — Use InventoryProducts first
2. **Track serial numbers** — Important for warranty and asset tracking
3. **Use reorder points** — Automate low-stock alerts
4. **Audit transfers** — Keep transfer records for accountability
5. **Receive to correct location** — Specify inventoryLocationID when receiving
6. **Handle partial receives** — Track quantityOrdered vs quantityReceived
7. **Sync with assets** — Sold products should create ConfigurationItems

## Common Pitfalls

1. **Product vs InventoryProduct** — Products are definitions; InventoryProducts are location associations
2. **Quantity fields** — quantityOnHand, quantityOnOrder, quantityCommitted are separate
3. **Serial number format** — Must match expected format per product
4. **Transfer atomicity** — Transfer removes from source, adds to destination
5. **Receiving locations** — Must specify location when receiving PO items
6. **Multi-location products** — Same product can exist at multiple locations

## Reference

- API Skill: `autotask-psa-api`
- KPI Skill: `autotask-kpi-reporting`
- Full Documentation: https://www.autotask.net/help/developerhelp/Content/APIs/REST/Entities/InventoryStockedItems.htm
