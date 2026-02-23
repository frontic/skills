# Inventory & Warehouses

## Overview

Inventory management in Xentral revolves around warehouses, storage locations within those warehouses, and stock items at each location. Stock can be queried per product, added/retrieved at specific storage locations, or bulk-set across the system.

## Product Stock

Get stock levels for a specific product across all warehouses:

```
GET /api/v1/products/{id}/stocks
```

Returns stock quantities per warehouse and storage location.

## Warehouses

### List Warehouses

```
GET /api/v1/warehouses
```

### Create Warehouse

```
POST /api/v1/warehouses
```

```json
{
  "name": "Main Warehouse",
  "description": "Primary fulfillment center"
}
```

## Storage Locations

Storage locations are sub-resources of warehouses.

### List Storage Locations

```
GET /api/v1/warehouses/{warehouseId}/storageLocations
```

### View / Update / Delete

```
GET    /api/v1/warehouses/{warehouseId}/storageLocations/{id}
PATCH  /api/v1/warehouses/{warehouseId}/storageLocations/{id}
DELETE /api/v1/warehouses/{warehouseId}/storageLocations/{id}
```

## Storage Items (Stock)

Stock items represent the actual inventory at a given storage location.

### List Items

Available on both V1 and V2:

```
GET /api/v1/warehouses/{warehouseId}/storageLocations/{id}/items
GET /api/v2/warehouses/{warehouseId}/storageLocations/{id}/items
```

### Add Stock

Add stock to a specific storage location:

```
POST /api/v1/warehouses/{warehouseId}/storageLocations/{id}/items
```

```json
{
  "product": {
    "id": 101
  },
  "quantity": 50
}
```

### Retrieve Stock

Remove stock from a specific storage location:

```
POST /api/v1/warehouses/{warehouseId}/storageLocations/{id}/items/retrieve
```

```json
{
  "product": {
    "id": 101
  },
  "quantity": 10
}
```

## Set Total Stock

**WARNING**: This is a destructive operation. It sets the absolute stock level for products at storage locations. Any product/location combinations **not included** in the payload will have their stock **removed**.

```
PATCH /api/v1/storageLocations/setTotalStock
```

```json
{
  "items": [
    {
      "storageLocation": {
        "id": 5
      },
      "product": {
        "id": 101
      },
      "quantity": 100
    },
    {
      "storageLocation": {
        "id": 5
      },
      "product": {
        "id": 205
      },
      "quantity": 25
    }
  ]
}
```

Use this endpoint carefully. For incremental stock changes, prefer the add/retrieve endpoints on individual storage locations instead.

## Common Patterns

### Check Stock Before Order

```typescript
// Get all stock for a product
const { data: stocks } = await xentral('v1', `/products/${productId}/stocks`)

// Calculate total available
const totalStock = stocks.reduce((sum, s) => sum + s.quantity, 0)

if (totalStock < requiredQuantity) {
  throw new Error('Insufficient stock')
}
```

### Bulk Stock Sync

When syncing stock from an external system, use `setTotalStock` to overwrite all levels at once. Build the complete list of all products and their quantities per storage location before calling.

```typescript
// Build complete stock snapshot
const items = externalProducts.map(p => ({
  storageLocation: { id: storageLocationId },
  product: { id: p.xentralId },
  quantity: p.stockLevel,
}))

await xentral('v1', '/storageLocations/setTotalStock', {
  method: 'PATCH',
  body: { items },
})
```
