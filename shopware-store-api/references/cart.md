# Cart

## Overview

The cart is session-bound via `sw-context-token`. It is an in-memory object that gets recalculated on every mutation. The cart does not use the DAL — it exists as a whole blob, written and read atomically.

## Endpoints

### Fetch or Create Cart

```
GET /store-api/checkout/cart
```

Returns the current cart. Creates a new empty cart if none exists for the context token.

### Add Line Items

```
POST /store-api/checkout/cart/line-item
```

```json
{
  "items": [
    {
      "type": "product",
      "referencedId": "<product-id>",
      "quantity": 2
    }
  ]
}
```

Multiple items can be added in a single call. The `type` field determines the line item type:

| Type | Description | `referencedId` |
|---|---|---|
| `product` | Physical/digital product | Product ID |
| `promotion` | Discount code | Promotion code string |
| `credit` | Manual credit | — |
| `custom` | Custom line item | — |

For **promotion codes**, add them like:

```json
{
  "items": [
    {
      "type": "promotion",
      "referencedId": "SUMMER2024"
    }
  ]
}
```

**Response**: The full updated cart object.

### Update Line Items

```
PATCH /store-api/checkout/cart/line-item
```

```json
{
  "items": [
    {
      "id": "<line-item-id>",
      "quantity": 5
    }
  ]
}
```

The `id` is the line item ID from the cart (typically the product ID for product line items). Only include fields to update.

### Remove Line Items

```
POST /store-api/checkout/cart/line-item/delete
```

```json
{
  "ids": ["<line-item-id-1>", "<line-item-id-2>"]
}
```

Note: There is also a `DELETE /store-api/checkout/cart/line-item` endpoint (with `ids` as query param), but it is **deprecated**. Use the POST version above.

### Delete Entire Cart

```
DELETE /store-api/checkout/cart
```

Deletes the cart tied to the current context token.

## Cart Object Structure

The cart response contains:

```
{
  "name": "sales-channel-default",
  "token": "<context-token>",
  "price": {
    "netPrice": 100.00,
    "totalPrice": 119.00,
    "positionPrice": 119.00,
    "taxStatus": "gross",
    "calculatedTaxes": [...],
    "rawTotal": 119.00
  },
  "lineItems": [
    {
      "id": "<line-item-id>",
      "referencedId": "<product-id>",
      "type": "product",
      "label": "Product Name",
      "quantity": 2,
      "good": true,
      "removable": true,
      "stackable": true,
      "price": {
        "unitPrice": 59.50,
        "totalPrice": 119.00,
        "quantity": 2,
        "calculatedTaxes": [...],
        "taxRules": [...]
      },
      "cover": { "url": "..." },
      "payload": { /* product data */ },
      "children": []
    }
  ],
  "deliveries": [
    {
      "shippingMethod": { ... },
      "shippingCosts": { ... },
      "deliveryDate": { ... },
      "location": { ... }
    }
  ],
  "transactions": [
    {
      "paymentMethodId": "...",
      "amount": { ... }
    }
  ],
  "errors": { /* validation errors preventing checkout */ }
}
```

## Cart Calculation

The cart recalculates automatically on every mutation (add/update/remove). The calculation pipeline:

1. **Enrich** — Load product data, prices, images
2. **Process** — Calculate line item prices, shipping costs, taxes
3. **Validate** — Apply rule conditions, check stock, validate promotions
4. **Persist** — Store the updated cart

If validation finds issues (e.g. out-of-stock), they appear in `cart.errors`.

## Important Notes

- **Line item `id`**: For product line items, the `id` is usually the product ID. Use it for update/remove operations.
- **Stackable items**: If a product is stackable, adding it again increases quantity instead of creating a duplicate.
- **Cart merging**: When a guest logs in, their guest cart merges with any existing customer cart automatically.
- **Prices**: Are calculated server-side based on the customer group, tax rules, and currency from the context.
- **Promotions**: Automatic promotions apply during calculation without explicit add. Only manual codes need the `promotion` line item type.
