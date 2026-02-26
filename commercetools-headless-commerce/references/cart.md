# Cart Operations

## Overview

Carts in Commercetools are versioned resources. Every update requires the current `version` and an array of typed `CartUpdateAction`s. The cart recalculates prices automatically on every update. Use admin endpoints (`apiRoot.carts()`) in server routes; use "Me" endpoints (`apiRoot.me().carts()`) for client-scoped operations.

## Key Types

```typescript
import type {
  Cart,
  CartDraft,
  CartUpdateAction,
  LineItem,
  CentPrecisionMoney,
  TaxedPrice,
  BaseAddress,
} from '@commercetools/platform-sdk'
```

## Creating a Cart

### Admin Endpoint (Server-Side BFF)

```typescript
import type { CartDraft } from '@commercetools/platform-sdk'

const cartDraft: CartDraft = {
  currency: 'EUR',
  country: 'DE',
  anonymousId: 'anon-uuid',          // for anonymous sessions
  // customerEmail: 'guest@example.com', // for guest checkout
  lineItems: [
    { sku: 'SKU-001', quantity: 2 },
  ],
}

const { body: cart } = await apiRoot
  .carts()
  .post({ body: cartDraft })
  .execute()
```

### Me Endpoint (Client-Scoped)

```typescript
import type { MyCartDraft } from '@commercetools/platform-sdk'

const cartDraft: MyCartDraft = {
  currency: 'EUR',
  country: 'DE',
  lineItems: [
    { sku: 'SKU-001', quantity: 2 },
  ],
}

const { body: cart } = await apiRoot
  .me()
  .carts()
  .post({ body: cartDraft })
  .execute()
```

**CartDraft fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `currency` | `string` | Yes | Currency code (ISO 4217) |
| `customerEmail` | `string` | No | Email for guest checkout |
| `country` | `string` | No | Country code (ISO 3166-1 alpha-2) — affects tax/price selection |
| `locale` | `string` | No | Locale for localized fields (e.g., `en-US`) |
| `anonymousId` | `string` | No | Anonymous session ID (admin endpoint only) |
| `lineItems` | `LineItemDraft[]` | No | Initial line items |
| `billingAddress` | `BaseAddress` | No | Billing address |
| `shippingAddress` | `BaseAddress` | No | Shipping address |
| `shippingMethod` | `ShippingMethodResourceIdentifier` | No | Shipping method reference |
| `discountCodes` | `string[]` | No | Discount codes to apply |

**LineItemDraft fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `productId` | `string` | Yes (or `sku`) | Product ID |
| `sku` | `string` | Yes (or `productId`) | Product variant SKU |
| `variantId` | `number` | No | Specific variant (if using `productId`) |
| `quantity` | `number` | No | Quantity (default: 1) |

## Getting a Cart

### By Cart ID

```typescript
const { body: cart } = await apiRoot
  .carts()
  .withId({ ID: cartId })
  .get()
  .execute()
```

### Active Cart (Me Endpoint)

```typescript
const { body: cart } = await apiRoot
  .me()
  .activeCart()
  .get()
  .execute()
```

Returns the most recently modified active cart. Throws `404` if none exists.

### Query by Anonymous ID

```typescript
const { body: result } = await apiRoot
  .carts()
  .get({
    queryArgs: {
      where: [`anonymousId="${anonymousId}"`, `cartState="Active"`],
      sort: 'lastModifiedAt desc',
      limit: 1,
      withTotal: false,
    },
  })
  .execute()

const cart = result.results[0] // Cart | undefined
```

### Query by Customer ID

```typescript
const { body: result } = await apiRoot
  .carts()
  .get({
    queryArgs: {
      where: [`customerId="${customerId}"`, `cartState="Active"`],
      sort: 'lastModifiedAt desc',
      limit: 1,
      withTotal: false,
    },
  })
  .execute()
```

## Updating a Cart

All updates use the same pattern: send `version` + `actions` array.

```typescript
import type { CartUpdateAction } from '@commercetools/platform-sdk'

const actions: CartUpdateAction[] = [
  { action: 'addLineItem', sku: 'SKU-001', quantity: 1 },
]

const { body: updatedCart } = await apiRoot
  .carts()
  .withId({ ID: cart.id })
  .post({ body: { version: cart.version, actions } })
  .execute()
```

Multiple actions execute in order within a single request. This is more efficient than separate calls.

## Cart Update Actions

### Line Item Actions

**addLineItem** — Add a product to the cart:

```typescript
const action: CartUpdateAction = {
  action: 'addLineItem',
  sku: 'SKU-001',
  quantity: 2,
}
```

Or by product ID:

```typescript
const action: CartUpdateAction = {
  action: 'addLineItem',
  productId: 'product-uuid',
  variantId: 1,
  quantity: 2,
}
```

If the same product/variant already exists in the cart, quantities stack (no duplicate line items).

**removeLineItem** — Remove a line item (fully or partially):

```typescript
const action: CartUpdateAction = {
  action: 'removeLineItem',
  lineItemId: 'line-item-uuid',
  quantity: 1,   // omit to remove entirely
}
```

**changeLineItemQuantity** — Set exact quantity:

```typescript
const action: CartUpdateAction = {
  action: 'changeLineItemQuantity',
  lineItemId: 'line-item-uuid',
  quantity: 5,   // set to 0 to remove entirely
}
```

### Discount Code Actions

**addDiscountCode:**

```typescript
const action: CartUpdateAction = {
  action: 'addDiscountCode',
  code: 'SUMMER2024',
}
```

Maximum 10 discount codes per cart.

**removeDiscountCode:**

```typescript
const action: CartUpdateAction = {
  action: 'removeDiscountCode',
  discountCode: { typeId: 'discount-code', id: 'discount-code-uuid' },
}
```

### Address Actions

**setShippingAddress:**

```typescript
import type { BaseAddress } from '@commercetools/platform-sdk'

const address: BaseAddress = {
  country: 'DE',
  firstName: 'John',
  lastName: 'Doe',
  streetName: 'Hauptstraße',
  streetNumber: '1',
  postalCode: '10115',
  city: 'Berlin',
  email: 'john@example.com',
}

const action: CartUpdateAction = {
  action: 'setShippingAddress',
  address,
}
```

**setBillingAddress:**

```typescript
const action: CartUpdateAction = {
  action: 'setBillingAddress',
  address: billingAddress,
}
```

**BaseAddress fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `country` | `string` | Yes | Country code (ISO 3166-1 alpha-2) |
| `firstName` | `string` | No | First name |
| `lastName` | `string` | No | Last name |
| `streetName` | `string` | No | Street name |
| `streetNumber` | `string` | No | Street number |
| `postalCode` | `string` | No | Postal/zip code |
| `city` | `string` | No | City |
| `region` | `string` | No | Region |
| `state` | `string` | No | State |
| `company` | `string` | No | Company name |
| `department` | `string` | No | Department |
| `apartment` | `string` | No | Apartment/suite |
| `pOBox` | `string` | No | PO Box |
| `phone` | `string` | No | Phone number |
| `mobile` | `string` | No | Mobile phone |
| `email` | `string` | No | Email address |
| `additionalStreetInfo` | `string` | No | Additional street info |

### Shipping & Payment Actions

**setShippingMethod:**

```typescript
const action: CartUpdateAction = {
  action: 'setShippingMethod',
  shippingMethod: { typeId: 'shipping-method', id: 'shipping-method-uuid' },
}
```

**addPayment:**

```typescript
const action: CartUpdateAction = {
  action: 'addPayment',
  payment: { typeId: 'payment', id: 'payment-uuid' },
}
```

**removePayment:**

```typescript
const action: CartUpdateAction = {
  action: 'removePayment',
  payment: { typeId: 'payment', id: 'payment-uuid' },
}
```

### Other Actions

**setCustomerEmail:**

```typescript
const action: CartUpdateAction = {
  action: 'setCustomerEmail',
  email: 'customer@example.com',
}
```

**setCountry:**

```typescript
const action: CartUpdateAction = {
  action: 'setCountry',
  country: 'DE',
}
```

**setLocale:**

```typescript
const action: CartUpdateAction = {
  action: 'setLocale',
  locale: 'de-DE',
}
```

**recalculate** — Force price recalculation:

```typescript
const action: CartUpdateAction = {
  action: 'recalculate',
  updateProductData: true,
}
```

## Cart Object Structure

The `Cart` type from the SDK includes:

```typescript
interface Cart {
  id: string
  version: number
  customerId?: string
  anonymousId?: string
  customerEmail?: string
  lineItems: LineItem[]
  totalPrice: CentPrecisionMoney
  taxedPrice?: TaxedPrice
  shippingAddress?: Address
  billingAddress?: Address
  shippingInfo?: ShippingInfo
  discountCodes: DiscountCodeInfo[]
  cartState: 'Active' | 'Merged' | 'Ordered' | 'Frozen'
  country?: string
  locale?: string
  // ... additional fields
}
```

Key nested types:

```typescript
interface LineItem {
  id: string
  productId: string
  name: LocalizedString           // e.g. { en: "Product Name" }
  variant: ProductVariant         // includes sku, images, attributes
  quantity: number
  price: Price                    // unit price
  totalPrice: CentPrecisionMoney  // quantity × price
  discountedPricePerQuantity: DiscountedLineItemPriceForQuantity[]
}
```

## Important Notes

- **Duplicate line items stack**: Adding the same product/variant increases quantity on the existing line item instead of creating a new entry.
- **Max 10 discount codes**: A cart can hold at most 10 discount codes.
- **Automatic recalculation**: Prices, taxes, and discounts recalculate on every cart update.
- **Cart states**: `Active` (editable), `Merged` (merged into another cart), `Ordered` (converted to order), `Frozen` (read-only but not ordered).
- **Anonymous carts**: Carts created with `anonymousId` transfer to the customer automatically on login/signup.
- **Create-or-add pattern**: When creating a cart for an anonymous user, first query for an existing active cart. If found, add items to it instead of creating a duplicate:
  ```typescript
  const { body: existing } = await apiRoot.carts().get({
    queryArgs: {
      where: [`anonymousId="${anonId}"`, `cartState="Active"`],
      limit: 1,
    },
  }).execute()

  if (existing.count > 0) {
    // Add to existing cart
    return await apiRoot.carts().withId({ ID: existing.results[0].id }).post({
      body: {
        version: existing.results[0].version,
        actions: [{ action: 'addLineItem', sku, quantity }],
      },
    }).execute()
  }

  // Create new cart
  return await apiRoot.carts().post({
    body: { anonymousId: anonId, currency: 'EUR', lineItems: [{ sku, quantity }] },
  }).execute()
  ```
