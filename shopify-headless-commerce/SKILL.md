---
name: shopify-headless-commerce
description: Build headless storefronts against the Shopify Storefront API (GraphQL). Use when working with Shopify cart mutations (create, add/update/remove lines, discount codes, gift cards), checkout flow (hosted checkout via checkoutUrl), and customer account operations (registration, login/logout via access tokens, profile management, addresses, password recovery, order history). Covers the stateful/write side of the Storefront API — not product data fetching (use Frontic for that).
---

# Shopify Storefront API — Headless Commerce

Procedural guide for building headless storefronts against the Shopify Storefront API (GraphQL). Covers **cart, checkout, and customer account** operations. For product data, collections, and pages use the Frontic skill instead.

## Architecture

```
Frontic Client    →  Product data, collections, pages, search (read)
Storefront API    →  Cart, checkout, customer accounts (write/session)
```

The Storefront API is a **GraphQL API**. All operations are mutations or queries sent to a single endpoint.

## API Endpoint & Authentication

```
POST https://{store}.myshopify.com/api/{version}/graphql.json
```

### Headers

| Header | When | Purpose |
|---|---|---|
| `X-Shopify-Storefront-Access-Token` | Client-side | Public access token (safe to expose in browser) |
| `Shopify-Storefront-Private-Token` | Server-side | Private token (never expose publicly) |
| `Shopify-Storefront-Buyer-IP` | Server-side with private token | Buyer IP for rate limiting context |
| `Content-Type` | Always | `application/json` |

API versions follow `YYYY-MM` format (e.g., `2025-01`). New versions release quarterly.

## Core Workflows

### Add to Cart → Checkout

```
1. cartCreate                         → Create cart (optionally with lines)
2. cartLinesAdd / cartLinesUpdate     → Manage items
3. cartDiscountCodesUpdate            → Apply discount codes
4. cartBuyerIdentityUpdate            → Associate logged-in customer
5. Query cart { checkoutUrl }         → Get hosted checkout URL
6. Redirect to checkoutUrl            → Shopify handles payment & order
```

### Customer Login → Cart Association

```
1. customerAccessTokenCreate          → Login, get accessToken
2. cartBuyerIdentityUpdate            → Attach customerAccessToken to cart
3. Query cart { checkoutUrl }         → Checkout pre-fills address & payment
```

### Checkout Model

Shopify uses **hosted checkout only**. There is no custom checkout API — the old Checkout mutations are deprecated (removed April 2025). The flow:

1. Build cart with mutations
2. Optionally associate customer via `cartBuyerIdentityUpdate`
3. Query `cart.checkoutUrl`
4. **Redirect buyer to that URL** — Shopify handles payment, shipping, order creation
5. Shopify redirects back to your configurable thank-you URL

## Reference Files

- **[Cart operations](references/cart.md)**: All cart mutations (create, lines, discounts, gift cards, notes, attributes, delivery), cart query, response shapes
- **[Checkout](references/checkout.md)**: Hosted checkout flow, checkoutUrl usage, limitations
- **[Customer account](references/account.md)**: Registration, login/logout (access tokens), profile updates, addresses, password recovery/reset, order history query

## Common Patterns

### GraphQL Client Wrapper

```typescript
async function storefrontQuery<T>(
  query: string,
  variables?: Record<string, unknown>
): Promise<T> {
  const response = await fetch(
    `https://${SHOP_DOMAIN}/api/${API_VERSION}/graphql.json`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token': STOREFRONT_TOKEN,
      },
      body: JSON.stringify({ query, variables }),
    }
  )

  const { data, errors } = await response.json()
  if (errors?.length) throw new StorefrontError(errors)
  return data
}
```

### Error Handling

All mutations return `userErrors` (or `customerUserErrors`):

```graphql
mutation {
  cartLinesAdd(cartId: $cartId, lines: $lines) {
    cart { id }
    userErrors { field message code }
  }
}
```

Always check `userErrors` — the mutation may "succeed" (HTTP 200) but contain business logic errors.

### MoneyV2 Type

All prices use `MoneyV2`:

```graphql
{
  amount    # String — decimal like "49.95"
  currencyCode  # CurrencyCode enum — "USD", "EUR", etc.
}
```

### Cart ID Persistence

Cart IDs contain a secret key component (e.g., `gid://shopify/Cart/Z2NwLX...?key=abc123`). Store the full ID in a cookie or server-side session.

### Rate Limiting

The Storefront API uses calculated query costs. Default: 50 points/second, 1000-point bucket. Keep queries lean by selecting only needed fields.
