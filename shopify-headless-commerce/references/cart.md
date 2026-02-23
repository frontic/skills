# Cart Operations

## Overview

Shopify carts are managed via GraphQL mutations. All cart mutations return a consistent payload: `{ cart, userErrors, warnings }`. The cart ID must be persisted client-side (cookie/session) — it contains a secret key component.

## cartCreate

```graphql
mutation cartCreate($input: CartInput!) {
  cartCreate(input: $input) {
    cart {
      id
      checkoutUrl
      totalQuantity
      cost {
        subtotalAmount { amount currencyCode }
        totalAmount { amount currencyCode }
      }
      lines(first: 100) {
        edges { node { id quantity merchandise { ... on ProductVariant { id title price { amount currencyCode } } } } }
      }
    }
    userErrors { field message code }
  }
}
```

**CartInput fields:**

| Field | Type | Description |
|---|---|---|
| `lines` | `[CartLineInput!]` | Line items (max 250) |
| `buyerIdentity` | `CartBuyerIdentityInput` | Customer identity |
| `attributes` | `[AttributeInput!]` | Custom key-value pairs (max 250) |
| `discountCodes` | `[String!]` | Discount codes (max 250) |
| `giftCardCodes` | `[String!]` | Gift card codes (max 250) |
| `note` | `String` | Cart note |
| `metafields` | `[CartInputMetafieldInput!]` | Metafields (max 250) |

**CartLineInput fields:**

| Field | Type | Description |
|---|---|---|
| `merchandiseId` | `ID!` | **Required.** Product variant GID |
| `quantity` | `Int` | Quantity (default: 1) |
| `attributes` | `[AttributeInput!]` | Line attributes (max 250) |
| `sellingPlanId` | `ID` | Subscription plan ID |

## cartLinesAdd

```graphql
mutation cartLinesAdd($cartId: ID!, $lines: [CartLineInput!]!) {
  cartLinesAdd(cartId: $cartId, lines: $lines) {
    cart { id totalQuantity lines(first: 100) { edges { node { id quantity } } } }
    userErrors { field message code }
  }
}
```

## cartLinesUpdate

```graphql
mutation cartLinesUpdate($cartId: ID!, $lines: [CartLineUpdateInput!]!) {
  cartLinesUpdate(cartId: $cartId, lines: $lines) {
    cart { id totalQuantity }
    userErrors { field message code }
  }
}
```

**CartLineUpdateInput fields:**

| Field | Type | Description |
|---|---|---|
| `id` | `ID!` | **Required.** Cart line ID |
| `merchandiseId` | `ID` | Replace product variant |
| `quantity` | `Int` | New quantity |
| `attributes` | `[AttributeInput!]` | Updated attributes (empty array removes all, omit to keep) |
| `sellingPlanId` | `ID` | Updated selling plan |

## cartLinesRemove

```graphql
mutation cartLinesRemove($cartId: ID!, $lineIds: [ID!]!) {
  cartLinesRemove(cartId: $cartId, lineIds: $lineIds) {
    cart { id totalQuantity }
    userErrors { field message code }
  }
}
```

## cartDiscountCodesUpdate

```graphql
mutation cartDiscountCodesUpdate($cartId: ID!, $discountCodes: [String!]!) {
  cartDiscountCodesUpdate(cartId: $cartId, discountCodes: $discountCodes) {
    cart {
      id
      discountCodes { code applicable }
      cost { totalAmount { amount currencyCode } }
    }
    userErrors { field message code }
  }
}
```

**Important**: This **replaces all** existing discount codes. Pass `[]` to remove all. Codes are case-insensitive. Max 250.

## cartGiftCardCodesUpdate

```graphql
mutation cartGiftCardCodesUpdate($cartId: ID!, $giftCardCodes: [String!]!) {
  cartGiftCardCodesUpdate(cartId: $cartId, giftCardCodes: $giftCardCodes) {
    cart { id appliedGiftCards { lastCharacters amountUsed { amount currencyCode } } }
    userErrors { field message code }
  }
}
```

**Important**: This **replaces all** existing gift card codes. Max 250.

## cartBuyerIdentityUpdate

```graphql
mutation cartBuyerIdentityUpdate($cartId: ID!, $buyerIdentity: CartBuyerIdentityInput!) {
  cartBuyerIdentityUpdate(cartId: $cartId, buyerIdentity: $buyerIdentity) {
    cart { id buyerIdentity { email phone countryCode customer { id } } }
    userErrors { field message code }
  }
}
```

**CartBuyerIdentityInput fields:**

| Field | Type | Description |
|---|---|---|
| `email` | `String` | Buyer email |
| `phone` | `String` | Buyer phone |
| `countryCode` | `CountryCode` | Country for pricing context |
| `customerAccessToken` | `String` | Token to associate authenticated customer |
| `companyLocationId` | `ID` | B2B company location |

## Other Cart Mutations

**cartNoteUpdate:**
```graphql
mutation cartNoteUpdate($cartId: ID!, $note: String!) {
  cartNoteUpdate(cartId: $cartId, note: $note) {
    cart { id note }
    userErrors { field message code }
  }
}
```

**cartAttributesUpdate:**
```graphql
mutation cartAttributesUpdate($cartId: ID!, $attributes: [AttributeInput!]!) {
  cartAttributesUpdate(cartId: $cartId, attributes: $attributes) {
    cart { id attributes { key value } }
    userErrors { field message code }
  }
}
```

**cartSelectedDeliveryOptionsUpdate:**
```graphql
mutation cartSelectedDeliveryOptionsUpdate($cartId: ID!, $selectedDeliveryOptions: [CartSelectedDeliveryOptionInput!]!) {
  cartSelectedDeliveryOptionsUpdate(cartId: $cartId, selectedDeliveryOptions: $selectedDeliveryOptions) {
    cart { id }
    userErrors { field message code }
  }
}
```

## Cart Query

```graphql
query cart($cartId: ID!) {
  cart(id: $cartId) {
    id
    checkoutUrl
    createdAt
    updatedAt
    totalQuantity
    note
    cost {
      subtotalAmount { amount currencyCode }
      totalAmount { amount currencyCode }
      checkoutChargeAmount { amount currencyCode }
    }
    lines(first: 100) {
      edges {
        node {
          id
          quantity
          merchandise {
            ... on ProductVariant {
              id
              title
              price { amount currencyCode }
              product { title handle }
              image { url altText }
            }
          }
          attributes { key value }
          cost {
            totalAmount { amount currencyCode }
            amountPerQuantity { amount currencyCode }
          }
        }
      }
    }
    buyerIdentity { email phone countryCode customer { id firstName lastName email } }
    attributes { key value }
    discountCodes { code applicable }
    appliedGiftCards { lastCharacters amountUsed { amount currencyCode } }
  }
}
```

## Cart Object Key Fields

| Field | Type | Description |
|---|---|---|
| `id` | `ID!` | Cart GID (includes secret key — persist the full value) |
| `checkoutUrl` | `URL!` | Redirect URL for Shopify hosted checkout |
| `totalQuantity` | `Int!` | Total items in cart |
| `cost.subtotalAmount` | `MoneyV2!` | Pre-tax, pre-discount total |
| `cost.totalAmount` | `MoneyV2!` | Final amount buyer pays |
| `cost.checkoutChargeAmount` | `MoneyV2!` | Amount due at checkout (excludes deferred) |
| `lines` | Connection | Cart line items |
| `discountCodes` | `[CartDiscountCode!]!` | Applied discount codes with `applicable` boolean |
| `appliedGiftCards` | `[AppliedGiftCard!]!` | Applied gift cards |
| `buyerIdentity` | `CartBuyerIdentity!` | Associated customer info |
