# Orders & Documents

## Overview

Sales orders are the core transactional entity in Xentral. Orders can be created via V1 (import action) or V3, then managed through dispatch, partial orders, and related documents (invoices, delivery notes, credit notes). Purchase orders handle supplier-side procurement.

## V1 Sales Orders

### Import / Create

```
POST /api/v1/salesOrders/actions/import
```

```json
{
  "date": "2024-06-15",
  "externalOrderNumber": "SHOP-12345",
  "customer": {
    "id": 42
  },
  "project": {
    "id": 1
  },
  "financials": {
    "paymentMethod": {
      "id": 3
    },
    "currency": "EUR"
  },
  "delivery": {
    "shippingMethod": {
      "id": 2
    },
    "autoShipping": true,
    "autoCreateDocuments": true
  },
  "positions": [
    {
      "product": {
        "id": 101
      },
      "quantity": 2,
      "price": {
        "amount": 29.99,
        "currency": "EUR"
      },
      "discount": 0,
      "tax": {
        "vatCategory": "normal"
      }
    },
    {
      "product": {
        "id": 205
      },
      "quantity": 1,
      "price": {
        "amount": 49.50,
        "currency": "EUR"
      },
      "discount": 10,
      "tax": {
        "vatCategory": "reduced"
      }
    }
  ]
}
```

| Field | Required | Description |
|---|---|---|
| `date` | Yes | Order date (YYYY-MM-DD) |
| `externalOrderNumber` | No | External reference (e.g. shop order number) |
| `customer.id` | Yes | Xentral customer ID |
| `project.id` | Yes | Project / sales channel ID |
| `financials.paymentMethod.id` | Yes | Payment method ID |
| `financials.currency` | Yes | ISO 4217 currency code |
| `delivery.shippingMethod.id` | Yes | Shipping method ID |
| `delivery.autoShipping` | No | Auto-create shipping label |
| `delivery.autoCreateDocuments` | No | Auto-generate invoice/delivery note |
| `positions[].product.id` | Yes | Product ID |
| `positions[].quantity` | Yes | Order quantity |
| `positions[].price.amount` | Yes | Unit price |
| `positions[].price.currency` | Yes | Currency for this line |
| `positions[].discount` | No | Discount percentage (0-100) |
| `positions[].tax.vatCategory` | Yes | `normal`, `reduced`, or `taxfree` |

### Update

```
PATCH /api/v1/salesOrders/{id}
```

**WARNING**: Positions not included in the payload will be **deleted**. Always send the complete positions array when updating an order, including unchanged positions.

### View / List

```
GET /api/v1/salesOrders/{id}
GET /api/v1/salesOrders
```

List supports pagination, filtering, and ordering via query parameters:

```
GET /api/v1/salesOrders?filter[0][key]=status&filter[0][op]=equals&filter[0][value]=open&page[size]=25
```

### Actions

**Dispatch an order** (mark as shipped):

```
POST /api/v1/salesOrders/{id}/actions/dispatch
```

**Create a partial order** (split off a subset of positions):

```
POST /api/v1/salesOrders/{id}/actions/createPartialSalesOrder
```

**Delete an order**:

```
DELETE /api/v1/salesOrders/{id}
```

## V3 Sales Orders

### Create

```
POST /api/v3/salesOrders
```

```json
{
  "address": {
    "id": 15
  },
  "project": {
    "id": 1
  },
  "documentDate": "2024-06-15",
  "language": "de",
  "financials": {
    "paymentMethod": {
      "id": 3
    },
    "currency": "EUR"
  },
  "lineItems": [
    {
      "product": {
        "id": 101
      },
      "quantity": 2,
      "unitPrice": 29.99
    }
  ]
}
```

| Field | Required | Description |
|---|---|---|
| `address.id` | Yes | Customer address ID |
| `project.id` | Yes | Project / sales channel ID |
| `documentDate` | Yes | Document date (YYYY-MM-DD) |
| `language` | No | Language code (e.g. `de`, `en`) |
| `financials` | Yes | Payment method and currency |
| `lineItems` | Yes | Array of order line items |

### List

```
GET /api/v3/salesOrders
```

### Release

```
POST /api/v3/salesOrders/{id}/actions/release
```

### Line Items

```
GET  /api/v3/salesOrders/{id}/lineItems
POST /api/v3/salesOrders/{id}/lineItems
```

## Documents

### Invoices

```
GET    /api/v1/invoices              → List invoices
GET    /api/v1/invoices/{id}         → View invoice
POST   /api/v1/invoices              → Create invoice
PATCH  /api/v1/invoices/{id}         → Update invoice
DELETE /api/v1/invoices/{id}         → Delete invoice
```

### Delivery Notes

```
GET    /api/v1/deliveryNotes         → List delivery notes
GET    /api/v1/deliveryNotes/{id}    → View delivery note
POST   /api/v1/deliveryNotes         → Create delivery note
DELETE /api/v1/deliveryNotes/{id}    → Delete delivery note
```

### Credit Notes

```
GET    /api/v1/creditNotes           → List credit notes
GET    /api/v1/creditNotes/{id}      → View credit note
POST   /api/v1/creditNotes           → Create credit note
DELETE /api/v1/creditNotes/{id}      → Delete credit note
```

### Purchase Orders

```
GET    /api/v1/purchaseOrders        → List purchase orders
GET    /api/v1/purchaseOrders/{id}   → View purchase order
POST   /api/v1/purchaseOrders        → Create purchase order
PATCH  /api/v1/purchaseOrders/{id}   → Update purchase order
DELETE /api/v1/purchaseOrders/{id}   → Delete purchase order
```

### PDF Download

Any document endpoint returns a PDF binary when requested with `Accept: application/pdf`:

```
GET /api/v1/invoices/{id}
Accept: application/pdf
```

This works for invoices, delivery notes, credit notes, and purchase orders. The response `Content-Type` will be `application/pdf`.

```typescript
// Example: download invoice PDF
const response = await fetch(`${XENTRAL_BASE}/v1/invoices/123`, {
  headers: {
    'Authorization': `Bearer ${API_TOKEN}`,
    'Accept': 'application/pdf',
  },
})
const pdfBlob = await response.blob()
```
