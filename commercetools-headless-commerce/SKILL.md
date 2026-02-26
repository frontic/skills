---
name: commercetools-headless-commerce
description: Build headless storefronts against the Commercetools API using the official TypeScript SDK (@commercetools/platform-sdk + @commercetools/ts-client). Use when working with Commercetools cart operations (create/update carts, line items, discount codes, shipping/billing addresses), checkout flow (order creation from cart, payment handling, shipping method selection), and customer account features (signup, login, profile management, addresses, password reset, email verification). Covers the stateful/write side of the API with full type safety, optimistic concurrency (versioned updates), SDK client builder patterns, and BFF security hardening (session signing, query injection prevention, input validation, rate limiting) — not product data fetching (use Frontic for that). Also use to audit existing Commercetools implementations for security pitfalls.
---

# Commercetools TypeScript SDK — Headless Commerce

Procedural guide for building headless storefronts using the official Commercetools TypeScript SDK. Covers **cart, checkout, and customer account** operations via the "Me" endpoints (storefront) and server-side admin endpoints. For product data, categories, and search use the Frontic skill instead.

## Architecture

```
Frontic Client       →  Product data, categories, search, product projections (read)
Commercetools SDK    →  Cart, checkout/orders, customer account, payments (write/session)
```

Both share the same Commercetools project. Frontic handles optimized product delivery; the Commercetools SDK handles session-bound and transactional operations.

## SDK Setup

### Dependencies

```bash
npm install @commercetools/platform-sdk @commercetools/ts-client
```

- **`@commercetools/ts-client`** — HTTP client with middleware chain (auth, HTTP, logging)
- **`@commercetools/platform-sdk`** — Typed API builder with full request/response types

### Client Builder

The SDK uses a middleware-based client builder. Choose the auth flow based on the use case:

```typescript
import { ClientBuilder } from '@commercetools/ts-client'
import type { AuthMiddlewareOptions, HttpMiddlewareOptions } from '@commercetools/ts-client'
import { createApiBuilderFromCtpClient } from '@commercetools/platform-sdk'

// --- Auth middleware options (choose ONE per use case) ---

// Option A: Client Credentials (server-to-server, admin operations)
const authOptions: AuthMiddlewareOptions = {
  host: 'https://auth.europe-west1.gcp.commercetools.com',
  projectKey: PROJECT_KEY,
  credentials: { clientId: CLIENT_ID, clientSecret: CLIENT_SECRET },
  scopes: ['manage_orders:my-project', 'manage_customers:my-project'],
  httpClient: fetch,
}

// Option B: Anonymous session (guest browsing & cart)
const anonymousAuthOptions: AnonymousAuthMiddlewareOptions = {
  host: 'https://auth.europe-west1.gcp.commercetools.com',
  projectKey: PROJECT_KEY,
  credentials: { clientId: CLIENT_ID, clientSecret: CLIENT_SECRET },
  scopes: ['manage_my_orders:my-project', 'manage_my_profile:my-project'],
  httpClient: fetch,
}

// Option C: Password flow (logged-in customer)
const passwordAuthOptions: PasswordAuthMiddlewareOptions = {
  host: 'https://auth.europe-west1.gcp.commercetools.com',
  projectKey: PROJECT_KEY,
  credentials: {
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    user: { username: email, password: password },
  },
  scopes: ['manage_my_orders:my-project', 'manage_my_profile:my-project'],
  httpClient: fetch,
}

// --- HTTP middleware (always the same) ---

const httpOptions: HttpMiddlewareOptions = {
  host: 'https://api.europe-west1.gcp.commercetools.com',
  httpClient: fetch,
}

// --- Build client & API root ---

const ctpClient = new ClientBuilder()
  .withClientCredentialsFlow(authOptions)   // or .withAnonymousSessionFlow() / .withPasswordFlow()
  .withHttpMiddleware(httpOptions)
  .withLoggerMiddleware()                   // optional, useful for debugging
  .build()

const apiRoot = createApiBuilderFromCtpClient(ctpClient)
  .withProjectKey({ projectKey: PROJECT_KEY })
```

### When to Use Which Auth Flow

| Flow | Builder Method | Use Case | Endpoints |
|---|---|---|---|
| Client Credentials | `.withClientCredentialsFlow()` | Server-side BFF routes, admin operations | `/carts`, `/orders`, `/customers`, `/payments` |
| Anonymous Session | `.withAnonymousSessionFlow()` | Guest browsing, anonymous carts (client-side) | `/me/carts`, `/me/orders` |
| Password | `.withPasswordFlow()` | Logged-in customer (client-side) | `/me/carts`, `/me/orders`, `/me/login` |

**Common pattern**: Use client credentials in your Nuxt/Next server routes (BFF) and handle anonymous/customer scoping yourself via query filters. This avoids managing per-user OAuth tokens server-side.

### Regions

| Region | Auth Host | API Host |
|---|---|---|
| Europe | `auth.europe-west1.gcp.commercetools.com` | `api.europe-west1.gcp.commercetools.com` |
| US | `auth.us-central1.gcp.commercetools.com` | `api.us-central1.gcp.commercetools.com` |
| Australia | `auth.australia-southeast1.gcp.commercetools.com` | `api.australia-southeast1.gcp.commercetools.com` |

## Endpoint Types

**"Me" endpoints** (storefront, scoped to current user/session):

```
/me/carts, /me/orders, /me/signup, /me/login, /me/password, /me/email/confirm
```

SDK: `apiRoot.me().carts()`, `apiRoot.me().orders()`, `apiRoot.me().signup()`, etc.

**Admin endpoints** (server-side, full access):

```
/carts, /orders, /customers, /payments, /shipping-methods
```

SDK: `apiRoot.carts()`, `apiRoot.orders()`, `apiRoot.customers()`, etc.

Use "Me" endpoints for storefront operations. Use admin endpoints for server-side order management, fulfillment, and back-office tasks.

## Core Workflows

### Anonymous Session → Cart → Login → Checkout

```
1. Build client with anonymous/client-credentials flow
2. apiRoot.carts().post({ body: cartDraft })              → Create cart
3. apiRoot.carts().withId({ ID }).post({ body: update })  → Add items
4. apiRoot.me().login().post({ body: credentials })       → Login (cart transfers)
   (rebuild client with customer-scoped token)
5. apiRoot.carts().withId({ ID }).post({ body: update })  → Set addresses
6. apiRoot.carts().withId({ ID }).post({ body: update })  → Set shipping
7. apiRoot.carts().withId({ ID }).post({ body: update })  → Attach payment
8. apiRoot.me().orders().post({ body: orderDraft })       → Create order from cart
```

### Guest Checkout (No Account)

```
1. Build client with anonymous/client-credentials flow
2. apiRoot.carts().post({ body: { currency, customerEmail } })  → Create cart with email
3. apiRoot.carts().withId({ ID }).post({ body: update })        → Add items
4. apiRoot.carts().withId({ ID }).post({ body: update })        → Set addresses & shipping
5. apiRoot.carts().withId({ ID }).post({ body: update })        → Attach payment
6. apiRoot.me().orders().post({ body: orderDraft })             → Create order
```

Anonymous carts get an `anonymousId`. On signup/login, resources with matching `anonymousId` transfer to the customer automatically.

## Reference Files

- **@references/cart.md**: Create/update carts, line items, discount codes, addresses, shipping method, payment attachment, cart structure
- **@references/checkout.md**: Order creation from cart, payment flow, shipping method selection, order queries, server-side order management
- **@references/account.md**: Signup, login, profile updates, addresses, password change/reset, email verification, anonymous-to-customer transfer
- **@references/security.md**: Security audit checklist, session hardening, query injection prevention, input validation, rate limiting, safe error handling

## Common Patterns

### Singleton API Root (Critical)

The SDK's auth middleware caches OAuth tokens internally — but only if you reuse the same client instance. **Never create a new client per request.** This causes a fresh token request to Commercetools auth on every API call, adding latency and unnecessary auth traffic.

```typescript
import { ClientBuilder } from '@commercetools/ts-client'
import type { AuthMiddlewareOptions, HttpMiddlewareOptions } from '@commercetools/ts-client'
import { createApiBuilderFromCtpClient } from '@commercetools/platform-sdk'

// Singleton — created once, reused across all requests
let _apiRoot: ReturnType<typeof createApiBuilderFromCtpClient> | null = null

export function getApiRoot() {
  if (_apiRoot) return _apiRoot

  const authOptions: AuthMiddlewareOptions = {
    host: AUTH_HOST,
    projectKey: PROJECT_KEY,
    credentials: { clientId: CLIENT_ID, clientSecret: CLIENT_SECRET },
    scopes: SCOPES.split(' '),
    httpClient: fetch,
  }

  const httpOptions: HttpMiddlewareOptions = {
    host: API_HOST,
    httpClient: fetch,
  }

  const client = new ClientBuilder()
    .withClientCredentialsFlow(authOptions)
    .withHttpMiddleware(httpOptions)
    .build()

  _apiRoot = createApiBuilderFromCtpClient(client)
    .withProjectKey({ projectKey: PROJECT_KEY })

  return _apiRoot
}
```

In Nuxt server routes, use `useRuntimeConfig()` inside the lazy initializer:

```typescript
export function getApiRoot() {
  if (_apiRoot) return _apiRoot

  const { commercetools } = useRuntimeConfig()
  // ... build client using commercetools config
  _apiRoot = createApiBuilderFromCtpClient(client)
    .withProjectKey({ projectKey: commercetools.projectKey })

  return _apiRoot
}
```
```

### Optimistic Concurrency with Retry

Every resource has a `version` field. All updates require the current version. In production, version conflicts (409) will happen — concurrent tabs, race conditions between add-to-cart clicks. Always wrap mutations in a retry loop that re-fetches the resource on conflict:

```typescript
import type { CartUpdateAction } from '@commercetools/platform-sdk'

/**
 * Execute a cart update with automatic retry on version conflicts.
 * Re-fetches the cart on each retry to get the latest version.
 */
async function updateCartWithRetry(
  cartId: string,
  buildActions: (cart: Cart) => CartUpdateAction[],
  maxRetries = 3,
): Promise<Cart> {
  const apiRoot = getApiRoot()

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const { body: cart } = await apiRoot
      .carts()
      .withId({ ID: cartId })
      .get()
      .execute()

    try {
      const { body: updated } = await apiRoot
        .carts()
        .withId({ ID: cartId })
        .post({ body: { version: cart.version, actions: buildActions(cart) } })
        .execute()
      return updated
    } catch (error: any) {
      if (error.statusCode === 409 && attempt < maxRetries - 1) continue
      throw error
    }
  }
  throw new Error('Max retries exceeded')
}

// Usage
const updatedCart = await updateCartWithRetry(cartId, () => [
  { action: 'addLineItem', sku: 'SKU-001', quantity: 1 },
])
```

The `buildActions` callback receives the freshly-fetched cart, so actions can depend on current cart state (e.g., checking existing line items before adding).

### Error Handling

The SDK throws errors with the Commercetools error shape. **Preserve the original status code** — don't wrap everything as 500. The client needs to distinguish between a 400 (bad input), 404 (not found), and 409 (version conflict) to react appropriately.

```typescript
try {
  const { body } = await apiRoot.carts().withId({ ID: cartId }).get().execute()
} catch (error: any) {
  // error.statusCode — HTTP status (400, 404, 409, etc.)
  // error.message — Error message
  // error.body.errors — Array of detailed errors with codes

  if (error.statusCode === 409) {
    // ConcurrentModification — re-fetch and retry (use updateCartWithRetry)
  }
  if (error.statusCode === 404) {
    // ResourceNotFound — cart expired or was deleted
  }
}
```

In BFF server routes, forward the SDK error status to the client:

```typescript
// Good — preserves the original error for the client to handle
catch (error: any) {
  throw createError({
    statusCode: error.statusCode || 500,
    message: error.message,
    data: error.body?.errors,  // forward Commercetools error details
  })
}

// Bad — masks all errors as 500, client can't distinguish causes
catch (error: any) {
  throw createError({
    statusCode: 500,
    message: error.message || 'Something went wrong',
  })
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

### Money Type

All monetary values use the `Money` type with `centAmount` (smallest currency unit):

```typescript
import type { Money } from '@commercetools/platform-sdk'

const price: Money = {
  centAmount: 4999,
  currencyCode: 'EUR',
}
// centAmount: 4999 with currencyCode: "EUR" = 49.99 EUR
```

### Resource Identifiers

References use typed `ResourceIdentifier`:

```typescript
import type { ShippingMethodResourceIdentifier } from '@commercetools/platform-sdk'

// By ID
const ref: ShippingMethodResourceIdentifier = {
  typeId: 'shipping-method',
  id: 'shipping-method-uuid',
}

// Or by key
const refByKey: ShippingMethodResourceIdentifier = {
  typeId: 'shipping-method',
  key: 'standard-shipping',
}
```

### Querying with Where Predicates

The SDK supports Commercetools query predicates for filtering:

```typescript
// Find active anonymous cart
const { body } = await apiRoot
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

const cart = body.results[0] // Cart | undefined
```

## Common Pitfalls

1. **Creating a new client per request** — The SDK's auth middleware caches OAuth tokens internally, but only within the same client instance. Creating a new `ClientBuilder` per API call means a fresh token request every time. Use the singleton pattern (see "Singleton API Root" above).

2. **Forgetting `.execute()`** — SDK methods return request builders, not promises. Always call `.execute()` to send the request. The response is `{ body, statusCode, headers }`.

3. **Not retrying on 409** — Version conflicts happen in production (concurrent tabs, quick double-clicks). Always wrap mutations in a retry loop that re-fetches the resource before each attempt. See `updateCartWithRetry` pattern above.

4. **Sending one action per request** — Commercetools supports multiple actions in a single update. Batch related actions to reduce round-trips, lower version conflict risk, and ensure atomicity:
   ```typescript
   // Good — one request, one version increment
   const actions: CartUpdateAction[] = [
     { action: 'setShippingAddress', address: shippingAddress },
     { action: 'setBillingAddress', address: billingAddress },
     { action: 'setCustomerEmail', email: 'guest@example.com' },
   ]

   // Bad — three requests, three version increments, three potential conflicts
   await updateCart({ action: 'setShippingAddress', address: shippingAddress })
   await updateCart({ action: 'setBillingAddress', address: billingAddress })
   await updateCart({ action: 'setCustomerEmail', email: 'guest@example.com' })
   ```

5. **Storing `cartId` instead of `anonymousId` as primary key** — Cart IDs become stale when carts expire, get merged, or transition to `Ordered`. The `anonymousId` is the stable identifier. Always query for the active cart by `anonymousId`:
   ```typescript
   // Resilient — always finds the current active cart
   const cart = await getActiveCartByAnonymousId(anonymousId)
   // Fragile — cart might be expired, merged, or ordered
   const cart = await getCartById(cartIdFromCookie)
   ```
   Store `anonymousId` in a long-lived cookie. Optionally cache `cartId` for performance, but fall back to the `anonymousId` query if the cart is gone.

6. **Using add/remove delta instead of `changeLineItemQuantity`** — Don't calculate quantity differences and call `addLineItem`/`removeLineItem` to adjust. Use the purpose-built action:
   ```typescript
   // Good — one atomic action
   { action: 'changeLineItemQuantity', lineItemId, quantity: 5 }
   // Bad — fragile delta calculation, potential race condition
   if (newQty > oldQty) addLineItem(sku, newQty - oldQty)
   else removeLineItem(lineItemId, oldQty - newQty)
   ```

7. **Masking SDK errors as 500** — The SDK throws structured errors with `statusCode`, `message`, and `body.errors[]`. Forward the original status code to the client so it can distinguish 400 (bad input), 404 (not found), and 409 (version conflict). Don't wrap everything as 500.

8. **Cart state after ordering** — Once `POST /me/orders` succeeds, the cart transitions to `cartState: "Ordered"` and is read-only. Create a new cart for subsequent shopping.

9. **Anonymous ID management** — Generate the `anonymousId` client-side (e.g., `crypto.randomUUID()`) and persist it in a cookie (30 days). Pass it when creating carts. On login, resources with matching `anonymousId` transfer automatically.

10. **Duplicate line items stack** — Adding the same SKU/product twice doesn't create two line items. It increases the quantity on the existing line item.

11. **SDK type imports** — Import types from `@commercetools/platform-sdk`, not from `@commercetools/ts-client`. The platform SDK has all domain types (`Cart`, `CartDraft`, `CartUpdateAction`, `Order`, `Customer`, etc.).

12. **Token scopes** — Client credentials tokens can access admin endpoints (`/carts`, `/orders`) but NOT "Me" endpoints (`/me/carts`). Anonymous/password tokens can access "Me" endpoints but have limited scope. Choose your auth flow accordingly.

## Security

Every BFF implementation that handles Commercetools sessions, authentication, and user input **must** be hardened against common web security pitfalls. The full security reference is in **@references/security.md** — read it when implementing or auditing any server-side Commercetools integration.

**Critical areas:**

1. **Session cookie signing** — Customer session cookies must be HMAC-signed. A plain JSON cookie lets attackers forge sessions for any customer ID.

2. **Query predicate injection** — Values interpolated into Commercetools `where` clauses (anonymousId, email, IDs) must be validated against strict format rules (UUID regex, email regex). Without validation, attackers can inject predicate logic to access other users' data.

3. **Input validation** — Validate all user input (email, strings, quantities, addresses) at the API boundary with length limits, type checks, and format validation. Don't rely on Commercetools to reject bad input.

4. **Rate limiting** — Login and register endpoints must be rate-limited by IP to prevent brute-force attacks.

5. **Error sanitization** — Never forward raw Commercetools error messages to the client. Map known errors to user-friendly messages and use a safe error helper for everything else.

6. **Cookie security** — All cookies must be `httpOnly`, `secure` in production, with appropriate `sameSite` settings (`strict` for auth cookies, `lax` for anonymous session).

After implementing any Commercetools BFF, run through the **Security Audit Checklist** in `@references/security.md` to verify all areas are covered.
