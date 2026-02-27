# Checkout & Orders

## Overview

Checkout in Commercetools converts a cart into an order. The flow: ensure the cart has a shipping address, shipping method, and payment attached, then create an order referencing the cart. Payment processing happens externally via a PSP (Payment Service Provider). The SDK provides full type safety for all checkout operations.

## Key Types

```typescript
import type {
  Cart,
  Order,
  OrderFromCartDraft,
  MyOrderFromCartDraft,
  Payment,
  PaymentDraft,
  MyPaymentDraft,
  PaymentUpdateAction,
  OrderUpdateAction,
  ShippingMethod,
} from '@commercetools/platform-sdk'
```

## Creating an Order (Storefront)

### Me Endpoint

```typescript
import type { MyOrderFromCartDraft } from '@commercetools/platform-sdk'

const orderDraft: MyOrderFromCartDraft = {
  id: cart.id,
  version: cart.version,
}

const { body: order } = await apiRoot
  .me()
  .orders()
  .post({ body: orderDraft })
  .execute()
```

**Prerequisites** (the API will reject the order if any are missing):
- Cart must have `shippingAddress` set
- Cart must have a `shippingMethod` set (via `shippingInfo`)
- Cart must have at least one line item
- For guest checkout: `customerEmail` must be set on the cart

After order creation, the cart transitions to `cartState: "Ordered"` and can no longer be modified.

## Pre-Checkout: Shipping Methods

### Matching Cart

Get shipping methods available for the current cart:

```typescript
const { body: shippingMethods } = await apiRoot
  .shippingMethods()
  .matchingCart()
  .get({
    queryArgs: { cartId: cart.id },
  })
  .execute()

// shippingMethods.results: ShippingMethod[]
```

Returns only methods valid for the cart's shipping address, line items, and total. Requires the cart to have a `shippingAddress` with at least `country` set.

### Matching Location

Get shipping methods available for a specific location (useful before cart exists):

```typescript
const { body: shippingMethods } = await apiRoot
  .shippingMethods()
  .matchingLocation()
  .get({
    queryArgs: {
      country: 'DE',
      currency: 'EUR',
      // state: 'BY',  // optional
    },
  })
  .execute()
```

### Setting Shipping Method on Cart

After the customer selects a shipping method:

```typescript
import type { CartUpdateAction } from '@commercetools/platform-sdk'

const actions: CartUpdateAction[] = [
  {
    action: 'setShippingMethod',
    shippingMethod: {
      typeId: 'shipping-method',
      id: selectedMethod.id,
    },
  },
]

const { body: updatedCart } = await apiRoot
  .carts()
  .withId({ ID: cart.id })
  .post({ body: { version: cart.version, actions } })
  .execute()
```

## Payment Flow

Commercetools does not process payments directly. Instead, payments are modeled as resources that track the state of external PSP interactions (Stripe, Adyen, PayPal, etc.).

### Step 1: Create Payment

**Me Endpoint (storefront):**

```typescript
import type { MyPaymentDraft } from '@commercetools/platform-sdk'

const paymentDraft: MyPaymentDraft = {
  amountPlanned: {
    centAmount: cart.totalPrice.centAmount,
    currencyCode: cart.totalPrice.currencyCode,
  },
  paymentMethodInfo: {
    paymentInterface: 'stripe',
    method: 'card',
    name: { en: 'Credit Card' },
  },
}

const { body: payment } = await apiRoot
  .me()
  .payments()
  .post({ body: paymentDraft })
  .execute()
```

**Admin Endpoint (server-side):**

```typescript
import type { PaymentDraft } from '@commercetools/platform-sdk'

const paymentDraft: PaymentDraft = {
  amountPlanned: {
    centAmount: cart.totalPrice.centAmount,
    currencyCode: cart.totalPrice.currencyCode,
  },
  paymentMethodInfo: {
    paymentInterface: 'stripe',
    method: 'card',
    name: { en: 'Credit Card' },
  },
}

const { body: payment } = await apiRoot
  .payments()
  .post({ body: paymentDraft })
  .execute()
```

| Field | Type | Required | Description |
|---|---|---|---|
| `amountPlanned` | `Money` | Yes | Total amount to be paid |
| `paymentMethodInfo.paymentInterface` | `string` | No | PSP identifier (e.g., `stripe`, `adyen`) |
| `paymentMethodInfo.method` | `string` | No | Method type (e.g., `card`, `paypal`) |
| `paymentMethodInfo.name` | `LocalizedString` | No | Display name |

### Step 2: Attach Payment to Cart

```typescript
const { body: updatedCart } = await apiRoot
  .carts()
  .withId({ ID: cart.id })
  .post({
    body: {
      version: cart.version,
      actions: [
        {
          action: 'addPayment',
          payment: { typeId: 'payment', id: payment.id },
        },
      ],
    },
  })
  .execute()
```

### Step 3: Interact with PSP Externally

Handle the actual payment with the PSP outside of Commercetools. This typically involves:
- Creating a payment intent/session with the PSP
- Redirecting the customer or collecting card details
- Receiving confirmation from the PSP via webhook

### Step 4: Update Payment with Transaction Results (Server-Side)

After PSP confirmation, update the payment resource with transaction details:

```typescript
import type { PaymentUpdateAction } from '@commercetools/platform-sdk'

const actions: PaymentUpdateAction[] = [
  {
    action: 'addTransaction',
    transaction: {
      type: 'Charge',
      amount: {
        centAmount: payment.amountPlanned.centAmount,
        currencyCode: payment.amountPlanned.currencyCode,
      },
      state: 'Success',
      interactionId: 'stripe-pi-abc123',  // PSP transaction ID
    },
  },
]

const { body: updatedPayment } = await apiRoot
  .payments()
  .withId({ ID: payment.id })
  .post({ body: { version: payment.version, actions } })
  .execute()
```

**Transaction types**: `Authorization`, `CancelAuthorization`, `Charge`, `Refund`, `Chargeback`

**Transaction states**: `Initial`, `Pending`, `Success`, `Failure`

## Complete Checkout Sequence (Example)

```typescript
// 1. Set shipping address
await apiRoot.carts().withId({ ID: cart.id }).post({
  body: {
    version: cart.version,
    actions: [{ action: 'setShippingAddress', address: shippingAddress }],
  },
}).execute()

// 2. Get available shipping methods
const { body: methods } = await apiRoot
  .shippingMethods()
  .matchingCart()
  .get({ queryArgs: { cartId: cart.id } })
  .execute()

// 3. Set selected shipping method (re-fetch cart for latest version)
const { body: cartV2 } = await apiRoot.carts().withId({ ID: cart.id }).get().execute()
await apiRoot.carts().withId({ ID: cart.id }).post({
  body: {
    version: cartV2.version,
    actions: [{
      action: 'setShippingMethod',
      shippingMethod: { typeId: 'shipping-method', id: methods.results[0].id },
    }],
  },
}).execute()

// 4. Create payment
const { body: payment } = await apiRoot.payments().post({
  body: {
    amountPlanned: cartV2.totalPrice,
    paymentMethodInfo: { paymentInterface: 'stripe', method: 'card' },
  },
}).execute()

// 5. Attach payment to cart
const { body: cartV3 } = await apiRoot.carts().withId({ ID: cart.id }).get().execute()
await apiRoot.carts().withId({ ID: cart.id }).post({
  body: {
    version: cartV3.version,
    actions: [{ action: 'addPayment', payment: { typeId: 'payment', id: payment.id } }],
  },
}).execute()

// 6. Process payment with PSP externally...

// 7. Record transaction result
await apiRoot.payments().withId({ ID: payment.id }).post({
  body: {
    version: payment.version,
    actions: [{
      action: 'addTransaction',
      transaction: { type: 'Charge', amount: payment.amountPlanned, state: 'Success', interactionId: 'pi_xxx' },
    }],
  },
}).execute()

// 8. Create order
const { body: cartFinal } = await apiRoot.carts().withId({ ID: cart.id }).get().execute()
const { body: order } = await apiRoot.me().orders().post({
  body: { id: cartFinal.id, version: cartFinal.version },
}).execute()
```

## Order Queries (Storefront)

### List My Orders

```typescript
const { body: orders } = await apiRoot
  .me()
  .orders()
  .get({
    queryArgs: {
      sort: 'createdAt desc',
      limit: 10,
      offset: 0,
    },
  })
  .execute()

// orders.results: Order[]
// orders.total: number
```

### Get Single Order

```typescript
const { body: order } = await apiRoot
  .me()
  .orders()
  .withId({ ID: orderId })
  .get()
  .execute()
```

## Server-Side Order Creation

For server-side order creation with full control over initial states:

```typescript
import type { OrderFromCartDraft } from '@commercetools/platform-sdk'

const orderDraft: OrderFromCartDraft = {
  cart: { typeId: 'cart', id: cart.id },
  version: cart.version,
  orderNumber: 'ORD-2024-001',     // optional, must be unique
  paymentState: 'Paid',            // optional
  shipmentState: 'Ready',          // optional
  orderState: 'Open',              // optional
}

const { body: order } = await apiRoot
  .orders()
  .post({ body: orderDraft })
  .execute()
```

**OrderFromCartDraft fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `cart` | `CartResourceIdentifier` | Yes | Reference to the cart |
| `version` | `number` | Yes | Current cart version |
| `orderNumber` | `string` | No | Custom order number (must be unique) |
| `paymentState` | `string` | No | `BalanceDue`, `Failed`, `Pending`, `CreditOwed`, `Paid` |
| `shipmentState` | `string` | No | `Shipped`, `Delivered`, `Ready`, `Pending`, `Delayed`, `Partial`, `Backorder` |
| `orderState` | `string` | No | `Open`, `Confirmed`, `Complete`, `Cancelled` |

## Server-Side Order Updates

```typescript
import type { OrderUpdateAction } from '@commercetools/platform-sdk'

const actions: OrderUpdateAction[] = [
  { action: 'changeOrderState', orderState: 'Confirmed' },
]

const { body: updatedOrder } = await apiRoot
  .orders()
  .withId({ ID: order.id })
  .post({ body: { version: order.version, actions } })
  .execute()
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

```typescript
const action: OrderUpdateAction = {
  action: 'addDelivery',
  items: [
    { id: 'line-item-uuid', quantity: 2 },
  ],
  parcels: [
    {
      trackingData: {
        trackingId: '1Z999AA10123456784',
        carrier: 'UPS',
      },
    },
  ],
  address: {
    country: 'DE',
    city: 'Berlin',
    streetName: 'Hauptstraße',
    streetNumber: '1',
    postalCode: '10115',
  },
}
```

### addReturnInfo Example

```typescript
const action: OrderUpdateAction = {
  action: 'addReturnInfo',
  items: [
    {
      quantity: 1,
      lineItemId: 'line-item-uuid',
      shipmentState: 'Returned',
      comment: 'Defective product',
    },
  ],
  returnDate: '2024-07-15T10:00:00.000Z',
  returnTrackingId: 'RET-12345',
}
```
