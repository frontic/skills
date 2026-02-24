---
name: commercetools-headless-commerce
description: Build headless storefronts against the Commercetools HTTP API. Use when working with Commercetools cart operations (create/update carts, line items, discount codes, shipping/billing addresses), checkout flow (order creation from cart, payment handling, shipping method selection), and customer account features (signup, login, profile management, addresses, password reset, email verification) via "Me" endpoints and OAuth2 authentication. Covers the stateful/write side of the API with optimistic concurrency (versioned updates) — not product data fetching (use Frontic for that).
---

# Commercetools HTTP API — Headless Commerce

Procedural guide for building headless storefronts against the Commercetools HTTP API. Covers **cart, checkout, and customer account** operations via the "Me" endpoints (storefront) and server-side admin endpoints. For product data, categories, and search use the Frontic skill instead.

## Architecture

```
Frontic Client       →  Product data, categories, search, product projections (read)
Commercetools API    →  Cart, checkout/orders, customer account, payments (write/session)
```

Both share the same Commercetools project. Frontic handles optimized product delivery; the Commercetools API handles session-bound and transactional operations.

## API Structure

### Base URL

```
https://api.{region}.commercetools.com/{projectKey}/...
```

Regions: `us-central1.gcp`, `europe-west1.gcp`, `australia-southeast1.gcp`.

### Authentication (OAuth2)

All requests require a Bearer token obtained via OAuth2 client credentials:

```
POST https://auth.{region}.commercetools.com/oauth/{projectKey}/anonymous/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&scope=manage_my_orders:{projectKey} manage_my_profile:{projectKey}
```

**Token types:**

| Token | Use Case | Scopes |
|---|---|---|
| Anonymous | Guest browsing & cart | `manage_my_orders`, `manage_my_profile` |
| Customer (password flow) | Logged-in customer | `manage_my_orders`, `manage_my_profile`, `view_published_products` |
| Admin (client credentials) | Server-side operations | `manage_orders`, `manage_customers`, etc. |

For customer login, use the password flow:

```
POST https://auth.{region}.commercetools.com/oauth/{projectKey}/customers/token
Content-Type: application/x-www-form-urlencoded

grant_type=password&username={email}&password={password}&scope=manage_my_orders:{projectKey} manage_my_profile:{projectKey}
```

### Required Headers

| Header | Required | Purpose |
|---|---|---|
| `Authorization` | Always | `Bearer {access_token}` |
| `Content-Type` | For POST/PUT | `application/json` |

## Endpoint Types

**"Me" endpoints** (storefront, scoped to current user/session):

```
/me/carts, /me/orders, /me/signup, /me/login, /me/password, /me/email/confirm
```

**Admin endpoints** (server-side, full access):

```
/carts, /orders, /customers, /payments, /shipping-methods
```

Use "Me" endpoints for storefront operations. Use admin endpoints for server-side order management, fulfillment, and back-office tasks.

## Core Workflows

### Anonymous Session → Cart → Login → Checkout

```
1. Get anonymous OAuth token                          → Anonymous session
2. POST /me/carts { currency: "EUR" }                → Create cart
3. POST /me/carts/{id} { addLineItem action }        → Add items
4. POST /me/login { email, password }                 → Login (cart transfers)
   (get new customer-scoped OAuth token)
5. POST /me/carts/{id} { setShippingAddress action }  → Set addresses
6. POST /me/carts/{id} { setShippingMethod action }   → Set shipping
7. POST /me/carts/{id} { addPayment action }          → Attach payment
8. POST /me/orders { id, version }                    → Create order from cart
```

### Guest Checkout (No Account)

```
1. Get anonymous OAuth token                           → Anonymous session
2. POST /me/carts { currency, customerEmail, ... }     → Create cart with email
3. POST /me/carts/{id} { addLineItem actions }         → Add items
4. POST /me/carts/{id} { setShippingAddress, ... }     → Set addresses & shipping
5. POST /me/carts/{id} { addPayment action }           → Attach payment
6. POST /me/orders { id, version }                     → Create order
```

Anonymous carts get an `anonymousId`. On signup/login, resources with matching `anonymousId` transfer to the customer automatically.

## Reference Files

- **[Cart operations](references/cart.md)**: Create/update carts, line items, discount codes, addresses, shipping method, payment attachment, cart structure
- **[Checkout & orders](references/checkout.md)**: Order creation from cart, payment flow, shipping method selection, order queries, server-side order management
- **[Account management](references/account.md)**: Signup, login, profile updates, addresses, password change/reset, email verification, anonymous-to-customer transfer

## Common Patterns

### API Client Wrapper

```typescript
async function commercetools<T>(
  endpoint: string,
  method: string = 'GET',
  body?: Record<string, unknown>
): Promise<T> {
  const token = await getAccessToken() // from OAuth2 flow

  const response = await fetch(
    `https://api.${REGION}.commercetools.com/${PROJECT_KEY}${endpoint}`,
    {
      method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: body ? JSON.stringify(body) : undefined,
    }
  )

  if (!response.ok) {
    const error = await response.json()
    throw new CommercetoolsError(error)
  }

  return response.json()
}
```

### Error Response Shape

```json
{
  "statusCode": 400,
  "message": "The cart is not valid.",
  "errors": [
    {
      "code": "InvalidOperation",
      "message": "The cart is not valid.",
      "action": { "action": "addLineItem", "productId": "..." }
    }
  ]
}
```

Common error codes:

| Code | Meaning |
|---|---|
| `InvalidOperation` | Action not allowed in current state |
| `ConcurrentModification` | Version conflict — re-fetch and retry |
| `ResourceNotFound` | Entity does not exist |
| `InvalidInput` | Missing or malformed fields |
| `DuplicateField` | Unique constraint violated (e.g., email) |

### Optimistic Concurrency (Versioning)

Every resource has a `version` field. All updates require the current version:

```json
{
  "version": 3,
  "actions": [
    { "action": "addLineItem", "productId": "...", "quantity": 1 }
  ]
}
```

If the version is stale, the API returns `409 ConcurrentModification`. Re-fetch the resource, get the latest version, and retry.

### Money Type

All monetary values use the `Money` type with `centAmount` (smallest currency unit):

```json
{
  "centAmount": 4999,
  "currencyCode": "EUR"
}
```

`centAmount: 4999` with `currencyCode: "EUR"` = 49.99 EUR.

### Resource Identifiers

References use `ResourceIdentifier`:

```json
{ "typeId": "product", "id": "abc-123" }
```

Or by key:

```json
{ "typeId": "shipping-method", "key": "standard-shipping" }
```
