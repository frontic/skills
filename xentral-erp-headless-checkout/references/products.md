# Products

## Overview

Products (articles) are managed primarily through V1 for create/delete and V2 for view/update/list operations. Products support sub-resources for media, pricing, stock, storage locations, free fields, cross-selling, and matrix configurations.

## Product CRUD

### Create (V1)

```
POST /api/v1/products
```

```json
{
  "name": "Premium T-Shirt",
  "description": "High-quality cotton t-shirt with custom print",
  "shortDescription": "Cotton t-shirt",
  "project": {
    "id": 1
  }
}
```

| Field | Required | Description |
|---|---|---|
| `name` | Yes | Product name |
| `description` | No | Full product description |
| `shortDescription` | No | Short product description |
| `project.id` | Yes | Project / sales channel ID |

### List (V1 / V2)

```
GET /api/v1/products
GET /api/v2/products
```

Both support pagination, filtering, and ordering. V2 offers improved filtering capabilities.

```
GET /api/v2/products?filter[0][key]=name&filter[0][op]=contains&filter[0][value]=shirt&page[size]=25&order[0][field]=name&order[0][dir]=ASC
```

### View (V2)

```
GET /api/v2/products/{id}
```

Returns the full product object with all fields.

### Update (V2)

```
PATCH /api/v2/products/{id}
```

```json
{
  "name": "Premium T-Shirt v2",
  "description": "Updated description"
}
```

Only include fields to update.

### Delete (V1)

```
DELETE /api/v1/products/{id}
```

## Sub-Resources

### Media

Upload and manage product images/files.

```
POST /api/v1/products/{id}/media      → Upload media
GET  /api/v1/products/{id}/media      → List media
```

### Sales Prices

```
GET /api/v1/products/{id}/salesPrices
```

Returns price tiers, customer group prices, and currency-specific pricing.

### Purchase Prices

```
GET   /api/v1/products/{id}/purchasePrices
PATCH /api/v1/products/{id}/purchasePrices
```

### Stocks

```
GET /api/v1/products/{id}/stocks
```

Returns stock levels across all warehouses and storage locations. See [Inventory](inventory.md) for detailed stock management.

### Storage Locations

```
GET /api/v1/products/{id}/storageLocations
```

Returns which storage locations hold this product.

### Free Fields

Custom fields attached to the product:

```
PATCH /api/v1/products/{id}/freeFields
```

```json
{
  "freeField1": "custom value",
  "freeField2": 42
}
```

### Cross-Selling

Link related products:

```
POST /api/v1/products/{id}/crossSelling
```

```json
{
  "relatedProduct": {
    "id": 205
  },
  "type": "similar"
}
```

### Matrix Products

Matrix products have configurable options (e.g. size, color) with values that generate variants.

**Options** (e.g. "Size", "Color"):

```
GET  /api/v1/products/{id}/matrixProductOptions
POST /api/v1/products/{id}/matrixProductOptions
```

```json
{
  "name": "Size",
  "sortOrder": 1
}
```

**Option Values** (e.g. "S", "M", "L"):

```
GET  /api/v1/products/{id}/matrixProductOptions/{optionId}/values
POST /api/v1/products/{id}/matrixProductOptions/{optionId}/values
```

```json
{
  "name": "M",
  "sortOrder": 2
}
```
