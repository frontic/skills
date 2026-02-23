# Checkout

## Overview

Checkout converts a cart into an order. The flow: ensure context has payment/shipping methods set, validate the cart, create the order, then handle payment.

## Checkout Flow

```
1. Build cart (add items, apply promotions)
2. Set payment method    → PATCH /store-api/context { paymentMethodId: "..." }
3. Set shipping method   → PATCH /store-api/context { shippingMethodId: "..." }
4. Set addresses         → PATCH /store-api/context { billingAddressId: "...", shippingAddressId: "..." }
5. Create order          → POST /store-api/checkout/order
6. Handle payment        → POST /store-api/handle-payment
7. (Async) Redirect      → User completes payment externally, returns to finishUrl
```

## Pre-Checkout: Available Methods

### Payment Methods

```
POST /store-api/payment-method
```

Body can include `{ "onlyAvailable": true }` to filter to only currently valid methods. Supports criteria for filtering/sorting.

### Shipping Methods

```
POST /store-api/shipping-method
```

Query param `?onlyAvailable=true` filters to methods valid for the current cart/context. Include associations for `prices` and `deliveryTime`:

```json
{
  "associations": {
    "prices": {},
    "deliveryTime": {}
  }
}
```

### Checkout Gateway (6.6+)

```
GET /store-api/checkout/gateway
```

Returns payment and shipping methods tailored to the current cart and context. This can include cart errors if the checkout is not valid.

## Creating an Order

```
POST /store-api/checkout/order
```

```json
{
  "customerComment": "Please leave at the door"
}
```

Optional fields: `customerComment`, `affiliateCode`, `campaignCode`.

**Prerequisites:**
- Customer must be logged in (or registered as guest with complete address data)
- Cart must have items
- Payment and shipping method must be set in context
- Billing and shipping addresses must be set

**Response**: The full order object including `id`, `orderNumber`, `stateMachineState`, `transactions`, and `deliveries`.

**Important**: Creating the order deletes the cart. A new cart is created for subsequent shopping.

## Handling Payment

After creating the order, initiate the payment flow:

```
POST /store-api/handle-payment
```

```json
{
  "orderId": "<order-id>",
  "finishUrl": "https://your-shop.com/checkout/finish",
  "errorUrl": "https://your-shop.com/checkout/error"
}
```

| Field | Required | Description |
|---|---|---|
| `orderId` | Yes | The order ID from `checkout/order` response |
| `finishUrl` | No | URL to redirect after successful payment |
| `errorUrl` | No | URL to redirect after failed payment |

### Payment Flow Types

**Synchronous payments** (e.g., invoice, prepayment):
- `handle-payment` processes immediately
- Response contains `redirectUrl: null` or no redirect
- Order payment state transitions to paid/authorized

**Asynchronous payments** (e.g., PayPal, credit card):
- `handle-payment` returns `{ "redirectUrl": "https://payment-provider.com/..." }`
- Redirect the user to this URL
- After payment, the provider redirects back to `finishUrl` or `errorUrl`
- Shopware receives a webhook/callback and updates the order payment state

### Handling the Redirect

```
const response = await fetch('/store-api/handle-payment', { ... })
const { redirectUrl } = await response.json()

if (redirectUrl) {
  // Async payment — redirect to payment provider
  window.location.href = redirectUrl
} else {
  // Sync payment — done, show confirmation
  router.push('/checkout/finish')
}
```

## Post-Order: Change Payment Method

If payment failed, the customer can retry with a different method:

```
POST /store-api/order/payment
```

```json
{
  "orderId": "<order-id>",
  "paymentMethodId": "<new-payment-method-id>"
}
```

Then call `handle-payment` again with the same order ID.

Check `paymentChangeable` in the order response to determine if changing is allowed.

## Cancel Order

```
POST /store-api/order/state/cancel
```

```json
{
  "orderId": "<order-id>"
}
```

Only works if the order state machine allows cancellation from the current state.
