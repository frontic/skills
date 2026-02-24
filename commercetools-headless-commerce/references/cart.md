# Cart Operations

## Overview

Carts in Commercetools are versioned resources. Every update requires the current `version` and an array of `actions`. The cart recalculates prices automatically on every update. "Me" endpoints operate on the authenticated user's cart; admin endpoints can manage any cart.

## Endpoints

### Create Cart

```
POST /me/carts
```

```json
{
  "currency": "EUR",
  "country": "DE",
  "customerEmail": "customer@example.com",
  "lineItems": [
    {
      "productId": "abc-123",
      "quantity": 2
    }
  ]
}
```

**MyCartDraft fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `currency` | `String` | Yes | Currency code (ISO 4217) |
| `customerEmail` | `String` | No | Email for guest checkout |
| `country` | `String` | No | Country code (ISO 3166-1 alpha-2) — affects tax/price selection |
| `locale` | `String` | No | Locale for localized fields (e.g., `en-US`) |
| `lineItems` | `[MyLineItemDraft]` | No | Initial line items |
| `billingAddress` | `BaseAddress` | No | Billing address |
| `shippingAddress` | `BaseAddress` | No | Shipping address |
| `shippingMethod` | `ResourceIdentifier` | No | Shipping method reference |
| `discountCodes` | `[String]` | No | Discount codes to apply |

**MyLineItemDraft fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `productId` | `String` | Yes (or `sku`) | Product ID |
| `sku` | `String` | Yes (or `productId`) | Product variant SKU |
| `variantId` | `Int` | No | Specific variant (if using `productId`) |
| `quantity` | `Int` | No | Quantity (default: 1) |

### Get Active Cart

```
GET /me/active-cart
```

Returns the most recently modified active cart for the authenticated customer/anonymous session. Returns `404` if no active cart exists.

### Update Cart

```
POST /me/carts/{id}
```

```json
{
  "version": 3,
  "actions": [
    {
      "action": "addLineItem",
      "productId": "abc-123",
      "quantity": 1
    },
    {
      "action": "setShippingAddress",
      "address": {
        "country": "DE",
        "firstName": "John",
        "lastName": "Doe",
        "streetName": "Hauptstraße",
        "streetNumber": "1",
        "postalCode": "10115",
        "city": "Berlin"
      }
    }
  ]
}
```

Multiple actions can be sent in a single request. They execute in order.

## Cart Update Actions

### Line Item Actions

**addLineItem** — Add a product to the cart:

```json
{
  "action": "addLineItem",
  "productId": "abc-123",
  "variantId": 1,
  "quantity": 2
}
```

Or by SKU:

```json
{
  "action": "addLineItem",
  "sku": "SKU-001",
  "quantity": 1
}
```

If the same product/variant already exists in the cart, quantities stack (no duplicate line items).

**removeLineItem** — Remove a line item (fully or partially):

```json
{
  "action": "removeLineItem",
  "lineItemId": "line-item-uuid",
  "quantity": 1
}
```

Omit `quantity` to remove the entire line item.

**changeLineItemQuantity** — Set exact quantity:

```json
{
  "action": "changeLineItemQuantity",
  "lineItemId": "line-item-uuid",
  "quantity": 5
}
```

Set `quantity: 0` to remove the line item entirely.

### Discount Code Actions

**addDiscountCode:**

```json
{
  "action": "addDiscountCode",
  "code": "SUMMER2024"
}
```

Maximum 10 discount codes per cart.

**removeDiscountCode:**

```json
{
  "action": "removeDiscountCode",
  "discountCode": {
    "typeId": "discount-code",
    "id": "discount-code-uuid"
  }
}
```

### Address Actions

**setShippingAddress:**

```json
{
  "action": "setShippingAddress",
  "address": {
    "country": "DE",
    "firstName": "John",
    "lastName": "Doe",
    "streetName": "Hauptstraße",
    "streetNumber": "1",
    "postalCode": "10115",
    "city": "Berlin",
    "email": "john@example.com"
  }
}
```

**setBillingAddress:**

```json
{
  "action": "setBillingAddress",
  "address": {
    "country": "DE",
    "firstName": "John",
    "lastName": "Doe",
    "streetName": "Hauptstraße",
    "streetNumber": "1",
    "postalCode": "10115",
    "city": "Berlin"
  }
}
```

**BaseAddress fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `country` | `String` | Yes | Country code (ISO 3166-1 alpha-2) |
| `firstName` | `String` | No | First name |
| `lastName` | `String` | No | Last name |
| `streetName` | `String` | No | Street name |
| `streetNumber` | `String` | No | Street number |
| `postalCode` | `String` | No | Postal/zip code |
| `city` | `String` | No | City |
| `region` | `String` | No | Region |
| `state` | `String` | No | State |
| `company` | `String` | No | Company name |
| `department` | `String` | No | Department |
| `apartment` | `String` | No | Apartment/suite |
| `pOBox` | `String` | No | PO Box |
| `phone` | `String` | No | Phone number |
| `mobile` | `String` | No | Mobile phone |
| `email` | `String` | No | Email address |
| `additionalStreetInfo` | `String` | No | Additional street info |

### Shipping & Payment Actions

**setShippingMethod:**

```json
{
  "action": "setShippingMethod",
  "shippingMethod": {
    "typeId": "shipping-method",
    "id": "shipping-method-uuid"
  }
}
```

**addPayment:**

```json
{
  "action": "addPayment",
  "payment": {
    "typeId": "payment",
    "id": "payment-uuid"
  }
}
```

**removePayment:**

```json
{
  "action": "removePayment",
  "payment": {
    "typeId": "payment",
    "id": "payment-uuid"
  }
}
```

### Other Actions

**setCustomerEmail:**

```json
{ "action": "setCustomerEmail", "email": "customer@example.com" }
```

**setCountry:**

```json
{ "action": "setCountry", "country": "DE" }
```

**setLocale:**

```json
{ "action": "setLocale", "locale": "de-DE" }
```

**recalculate** — Force price recalculation (useful after external price changes):

```json
{ "action": "recalculate", "updateProductData": true }
```

## Cart Object Structure

```json
{
  "id": "cart-uuid",
  "version": 5,
  "customerId": "customer-uuid",
  "anonymousId": "anon-uuid",
  "lineItems": [
    {
      "id": "line-item-uuid",
      "productId": "product-uuid",
      "name": { "en": "Product Name" },
      "variant": { "id": 1, "sku": "SKU-001" },
      "quantity": 2,
      "price": {
        "value": { "centAmount": 4999, "currencyCode": "EUR" }
      },
      "totalPrice": { "centAmount": 9998, "currencyCode": "EUR" },
      "discountedPricePerQuantity": []
    }
  ],
  "totalPrice": { "centAmount": 9998, "currencyCode": "EUR" },
  "shippingAddress": { "country": "DE", "city": "Berlin" },
  "billingAddress": null,
  "shippingInfo": {
    "shippingMethodName": "Standard",
    "price": { "centAmount": 499, "currencyCode": "EUR" }
  },
  "discountCodes": [
    { "discountCode": { "typeId": "discount-code", "id": "..." }, "state": "MatchesCart" }
  ],
  "cartState": "Active",
  "country": "DE",
  "locale": "de-DE"
}
```

## Important Notes

- **Duplicate line items stack**: Adding the same product/variant increases quantity on the existing line item instead of creating a new entry.
- **Max 10 discount codes**: A cart can hold at most 10 discount codes.
- **Automatic recalculation**: Prices, taxes, and discounts recalculate on every cart update.
- **Cart states**: `Active` (editable), `Merged` (merged into another cart), `Ordered` (converted to order).
- **Anonymous carts**: Carts created with anonymous tokens get an `anonymousId`. On login/signup, carts transfer to the customer automatically.
