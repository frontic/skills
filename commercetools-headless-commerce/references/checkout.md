# Checkout & Orders

## Overview

Checkout in Commercetools converts a cart into an order. The flow: ensure the cart has a shipping address, shipping method, and payment attached, then create an order referencing the cart. Payment processing happens externally via a PSP (Payment Service Provider).

## Creating an Order (Storefront)

```
POST /me/orders
```

```json
{
  "id": "cart-uuid",
  "version": 8
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Cart ID |
| `version` | `Int` | Yes | Current cart version |

**Prerequisites:**
- Cart must have `shippingAddress` set
- Cart must have a `shippingMethod` set (via `shippingInfo`)
- Cart must have at least one line item
- For guest checkout: `customerEmail` must be set on the cart

**Response**: The full order object. The cart transitions to `cartState: "Ordered"` and can no longer be modified.

## Pre-Checkout: Shipping Methods

### Matching Cart

Get shipping methods available for the current cart:

```
GET /shipping-methods/matching-cart?cartId={cartId}
```

Returns only methods valid for the cart's shipping address, line items, and total. Requires the cart to have a `shippingAddress` with at least `country` set.

### Matching Location

Get shipping methods available for a specific location:

```
GET /shipping-methods/matching-location?country={countryCode}&currency={currencyCode}
```

Optional query params: `state`, `currency`. Useful for showing shipping options before the cart exists.

## Payment Flow

Commercetools does not process payments directly. Instead, payments are modeled as resources that track the state of external PSP interactions.

### Step 1: Create Payment

```
POST /me/payments
```

```json
{
  "amountPlanned": {
    "centAmount": 10497,
    "currencyCode": "EUR"
  },
  "paymentMethodInfo": {
    "paymentInterface": "stripe",
    "method": "card",
    "name": { "en": "Credit Card" }
  }
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `amountPlanned` | `Money` | Yes | Total amount to be paid |
| `paymentMethodInfo` | `Object` | No | Payment method details |
| `paymentMethodInfo.paymentInterface` | `String` | No | PSP identifier (e.g., `stripe`, `adyen`) |
| `paymentMethodInfo.method` | `String` | No | Method type (e.g., `card`, `paypal`) |
| `paymentMethodInfo.name` | `LocalizedString` | No | Display name |

### Step 2: Attach Payment to Cart

```json
{
  "version": 7,
  "actions": [
    {
      "action": "addPayment",
      "payment": {
        "typeId": "payment",
        "id": "payment-uuid"
      }
    }
  ]
}
```

### Step 3: Interact with PSP Externally

Handle the actual payment with the PSP (Stripe, Adyen, PayPal, etc.) outside of Commercetools. This typically involves:
- Creating a payment intent/session with the PSP
- Redirecting the customer or collecting card details
- Receiving confirmation from the PSP

### Step 4: Update Payment with Results (Server-Side)

After PSP confirmation, update the payment resource with transaction details:

```
POST /{projectKey}/payments/{paymentId}
```

```json
{
  "version": 1,
  "actions": [
    {
      "action": "addTransaction",
      "transaction": {
        "type": "Charge",
        "amount": { "centAmount": 10497, "currencyCode": "EUR" },
        "state": "Success",
        "interactionId": "stripe-pi-abc123"
      }
    }
  ]
}
```

**Transaction types**: `Authorization`, `CancelAuthorization`, `Charge`, `Refund`, `Chargeback`.

**Transaction states**: `Initial`, `Pending`, `Success`, `Failure`.

## Order Queries (Storefront)

### List My Orders

```
GET /me/orders
```

Supports standard query parameters: `limit`, `offset`, `sort`, `where`.

```
GET /me/orders?sort=createdAt desc&limit=10
```

### Get Single Order

```
GET /me/orders/{id}
```

## Server-Side Order Creation

For server-side order creation with full control:

```
POST /orders
```

```json
{
  "cart": {
    "typeId": "cart",
    "id": "cart-uuid"
  },
  "version": 8,
  "orderNumber": "ORD-2024-001",
  "paymentState": "Paid",
  "shipmentState": "Ready"
}
```

**OrderFromCartDraft fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `cart` | `ResourceIdentifier` | Yes | Reference to the cart |
| `version` | `Int` | Yes | Current cart version |
| `orderNumber` | `String` | No | Custom order number (must be unique) |
| `paymentState` | `String` | No | `BalanceDue`, `Failed`, `Pending`, `CreditOwed`, `Paid` |
| `shipmentState` | `String` | No | `Shipped`, `Delivered`, `Ready`, `Pending`, `Delayed`, `Partial`, `Backorder` |
| `orderState` | `String` | No | `Open`, `Confirmed`, `Complete`, `Cancelled` |

## Server-Side Order Updates

```
POST /orders/{id}
```

```json
{
  "version": 1,
  "actions": [
    { "action": "changeOrderState", "orderState": "Confirmed" }
  ]
}
```

**Order update actions:**

| Action | Key Fields | Description |
|---|---|---|
| `changeOrderState` | `orderState` | `Open`, `Confirmed`, `Complete`, `Cancelled` |
| `changePaymentState` | `paymentState` | `BalanceDue`, `Failed`, `Pending`, `CreditOwed`, `Paid` |
| `changeShipmentState` | `shipmentState` | `Shipped`, `Delivered`, `Ready`, `Pending`, `Delayed`, `Partial`, `Backorder` |
| `addDelivery` | `items`, `parcels`, `address` | Record a shipment delivery |
| `addReturnInfo` | `items`, `returnDate`, `returnTrackingId` | Record a return |

### addDelivery Example

```json
{
  "action": "addDelivery",
  "items": [
    { "id": "line-item-uuid", "quantity": 2 }
  ],
  "parcels": [
    {
      "trackingData": {
        "trackingId": "1Z999AA10123456784",
        "carrier": "UPS"
      }
    }
  ],
  "address": {
    "country": "DE",
    "city": "Berlin",
    "streetName": "Hauptstraße",
    "streetNumber": "1",
    "postalCode": "10115"
  }
}
```

### addReturnInfo Example

```json
{
  "action": "addReturnInfo",
  "items": [
    {
      "quantity": 1,
      "lineItemId": "line-item-uuid",
      "shipmentState": "Returned",
      "comment": "Defective product"
    }
  ],
  "returnDate": "2024-07-15T10:00:00.000Z",
  "returnTrackingId": "RET-12345"
}
```
