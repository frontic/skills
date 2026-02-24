---
name: xentral-erp-headless-checkout
description: Integrate with the Xentral ERP REST API for managing sales orders, products/articles, inventory/stock levels, customers, addresses, invoices, delivery notes, credit notes, purchase orders, and warehouses. Use when building ERP integrations that need to create or sync orders, manage product catalogs, track stock across warehouses/storage locations, or maintain customer records. Covers API versions V1, V2, and V3.
---

# Xentral ERP REST API

Procedural guide for integrating with the Xentral ERP REST API. Covers sales orders, products, inventory/stock management, customers, and related documents (invoices, delivery notes, credit notes, purchase orders).

## API Structure

```
Base URL: https://{instance}.xentral.biz/api/{version}/{resource}
```

Three API versions coexist:

| Version | Status | Usage |
|---|---|---|
| V1 | Maintenance | Most endpoints, import actions, document CRUD |
| V2 | Updated | Products, customers with improved filtering |
| V3 | Newest | Sales orders, customers with latest features |

Use the newest version available for each resource. Some operations are only available on specific versions.

## Authentication

All requests require a Bearer token in the `Authorization` header. Obtain the token from the Xentral admin panel under API settings.

### Required Headers

| Header | Value | Required |
|---|---|---|
| `Authorization` | `Bearer {api-token}` | Always |
| `Content-Type` | `application/json` | For POST/PATCH |
| `Accept` | `application/json` | Always (or `application/pdf` for document downloads) |

## Response Envelope

All JSON responses follow this structure:

```json
{
  "meta": {
    "totalCount": 42,
    "page": 1,
    "pageSize": 10
  },
  "data": [ ... ],
  "extra": { },
  "links": {
    "first": "...?page[number]=1",
    "last": "...?page[number]=5",
    "next": "...?page[number]=2"
  }
}
```

Single-resource responses return `data` as an object instead of an array.

## Pagination

```
GET /api/v1/{resource}?page[number]=1&page[size]=25
```

| Parameter | Default | Max | Description |
|---|---|---|---|
| `page[number]` | 1 | — | Page number |
| `page[size]` | 10 | 50 | Items per page |

## Filtering

Array-based query parameters with indexed filters:

```
GET /api/v1/{resource}?filter[0][key]=status&filter[0][op]=equals&filter[0][value]=open&filter[1][key]=createdAt&filter[1][op]=greaterThan&filter[1][value]=2024-01-01
```

| Operator | Description | Example value |
|---|---|---|
| `equals` | Exact match | `open` |
| `notEquals` | Not equal | `cancelled` |
| `contains` | Substring match | `shirt` |
| `startsWith` | Prefix match | `INV-` |
| `endsWith` | Suffix match | `-2024` |
| `greaterThan` | Greater than | `100` |
| `greaterThanOrEquals` | Greater than or equal | `100` |
| `lessThan` | Less than | `50` |
| `lessThanOrEquals` | Less than or equal | `50` |
| `between` | Range (comma-separated) | `10,100` |
| `in` | Multiple values (comma-separated) | `open,processing` |

## Ordering

```
GET /api/v1/{resource}?order[0][field]=createdAt&order[0][dir]=DESC
```

Multiple sort fields use incrementing indices: `order[0]`, `order[1]`, etc. Direction values: `ASC`, `DESC`.

## Rate Limiting

**100 requests per minute** per API token. Exceeding the limit returns `429 Too Many Requests`. Implement exponential backoff or request queuing for bulk operations.

## Error Format

Errors follow IETF RFC 9457 (Problem Details for HTTP APIs):

```json
{
  "type": "https://developer.xentral.com/docs/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "violations": [
    {
      "field": "positions[0].quantity",
      "message": "This value should be greater than 0."
    }
  ]
}
```

## Reference Files

- **[Orders & documents](references/orders.md)**: Sales order import/create (V1/V3), update, dispatch, partial orders, invoices, delivery notes, credit notes, purchase orders, PDF downloads
- **[Products](references/products.md)**: Product CRUD (V1/V2), media, sales/purchase prices, stocks, storage locations, free fields, cross-selling, matrix products
- **[Inventory & warehouses](references/inventory.md)**: Product stock levels, warehouse management, storage locations, stock items, add/retrieve stock, set total stock
- **[Customers & addresses](references/customers.md)**: Customer CRUD (V2/V3), person vs company types, addresses (billing/delivery/masterdata), contact persons

## Common Patterns

### Authentication Setup

```typescript
const XENTRAL_BASE = 'https://myinstance.xentral.biz/api'
const API_TOKEN = process.env.XENTRAL_API_TOKEN

async function xentral<T>(
  version: 'v1' | 'v2' | 'v3',
  path: string,
  options: { method?: string; body?: unknown; accept?: string } = {}
): Promise<T> {
  const { method = 'GET', body, accept = 'application/json' } = options

  const response = await fetch(`${XENTRAL_BASE}/${version}${path}`, {
    method,
    headers: {
      'Authorization': `Bearer ${API_TOKEN}`,
      'Content-Type': 'application/json',
      'Accept': accept,
    },
    body: body ? JSON.stringify(body) : undefined,
  })

  if (!response.ok) {
    const error = await response.json()
    throw new XentralApiError(error)
  }

  if (accept === 'application/pdf') {
    return response.blob() as T
  }

  return response.json()
}
```

### PDF Download

Any document endpoint (invoice, delivery note, credit note, purchase order) returns a PDF when the `Accept` header is set to `application/pdf`:

```typescript
// Download an invoice as PDF
const pdf = await xentral('v1', `/invoices/${invoiceId}`, {
  accept: 'application/pdf',
})

// Download a delivery note as PDF
const pdf = await xentral('v1', `/deliveryNotes/${deliveryNoteId}`, {
  accept: 'application/pdf',
})
```

This works on any `GET /api/v1/{documentResource}/{id}` endpoint.

### Paginated Fetching

```typescript
async function fetchAll<T>(version: 'v1' | 'v2' | 'v3', path: string): Promise<T[]> {
  const results: T[] = []
  let page = 1
  let totalPages = 1

  while (page <= totalPages) {
    const response = await xentral<{
      meta: { totalCount: number; page: number; pageSize: number }
      data: T[]
    }>(version, `${path}?page[number]=${page}&page[size]=50`)

    results.push(...response.data)
    totalPages = Math.ceil(response.meta.totalCount / response.meta.pageSize)
    page++
  }

  return results
}
```
