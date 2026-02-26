# Security — Commercetools BFF Implementation

Security checklist and patterns for Commercetools server-side (BFF) implementations. Use this reference to audit existing code or harden new implementations.

## Session Management

### Anonymous ID Cookie

The `anonymousId` cookie links a browser session to Commercetools carts, orders, and other resources. It must be treated as a session token.

**Requirements:**
- Generate server-side with `crypto.randomUUID()` — never trust a client-supplied value without validation
- Validate format with UUID regex before using in any API call
- Set `httpOnly: true`, `sameSite: 'lax'`, `secure: true` (disable only in dev via `!import.meta.dev` or equivalent)
- Clear on logout to prevent session reuse

```typescript
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export function getAnonymousId(event: H3Event): string {
  const id = getCookie(event, 'anonymous_id')
  if (id && UUID_REGEX.test(id)) return id

  const newId = randomUUID()
  setCookie(event, 'anonymous_id', newId, {
    httpOnly: true,
    secure: !import.meta.dev,
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 365,
    path: '/',
  })
  return newId
}
```

**Why UUID validation matters:** The `anonymousId` is interpolated into Commercetools query predicates like `anonymousId="${value}"`. Without validation, an attacker can inject arbitrary predicate logic (e.g., `" or 1=1 or "`) to access other users' carts.

### Customer Session Cookie

Customer sessions (customerId + email) must be tamper-proof. A plain JSON cookie lets any user forge a session for any customer ID.

**Requirements:**
- Sign the payload with HMAC-SHA256 using a server-side secret
- Verify signature with timing-safe comparison on every read
- Set `sameSite: 'strict'` (stricter than anonymous cookie because it protects authenticated state)
- Invalidate on logout by deleting the cookie

```typescript
import { createHmac, timingSafeEqual } from 'node:crypto'

function sign(payload: string, secret: string): string {
  return createHmac('sha256', secret).update(payload).digest('base64url')
}

function verifySignature(payload: string, signature: string, secret: string): boolean {
  const expected = sign(payload, secret)
  if (expected.length !== signature.length) return false
  try {
    return timingSafeEqual(Buffer.from(expected), Buffer.from(signature))
  } catch {
    return false
  }
}

// Cookie format: `{json_payload}.{hmac_signature}`
export function setCustomerSession(event: H3Event, data: CustomerSession | null) {
  if (data) {
    const payload = JSON.stringify(data)
    const signature = sign(payload, getSessionSecret())
    setCookie(event, 'customer_session', `${payload}.${signature}`, {
      httpOnly: true,
      secure: !import.meta.dev,
      sameSite: 'strict',
      maxAge: 60 * 60 * 24 * 30,
      path: '/',
    })
  } else {
    deleteCookie(event, 'customer_session', { path: '/' })
  }
}
```

**Secret management:** Use the Commercetools client secret or a dedicated `SESSION_SECRET` env var. Never hardcode secrets.

## Query Predicate Injection

Commercetools query predicates accept string interpolation. Any user-supplied value in a `where` clause is an injection vector.

**Vulnerable pattern:**
```typescript
// DANGEROUS: anonymousId comes from a cookie — attacker-controlled
const { body } = await apiRoot.carts().get({
  queryArgs: {
    where: [`anonymousId="${anonymousId}"`],
  },
}).execute()
```

If `anonymousId` is `" or customerEmail is defined or "`, the predicate becomes:
```
anonymousId="" or customerEmail is defined or ""
```
This returns all carts with an email set — a data breach.

**Safe pattern:** Validate all interpolated values against strict format rules before using them in predicates:

```typescript
// UUID validation prevents injection — only hex chars and dashes allowed
if (!UUID_REGEX.test(anonymousId)) {
  throw createError({ statusCode: 400, statusMessage: 'Invalid session' })
}
```

This applies to any value interpolated into `where` clauses: cart IDs, customer IDs, email addresses, shipping method IDs, etc.

## Input Validation

Validate all user input at the API boundary. Do not rely on Commercetools to reject bad input — error messages from the API may leak internal details.

### Email Validation

```typescript
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export function validateEmail(email: unknown): string {
  if (typeof email !== 'string' || !EMAIL_REGEX.test(email.trim())) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid email address' })
  }
  return email.trim().toLowerCase()
}
```

### String Validation (names, SKUs, IDs)

```typescript
export function validateString(
  value: unknown,
  fieldName: string,
  maxLength = 255,
): string {
  if (typeof value !== 'string' || !value.trim()) {
    throw createError({ statusCode: 400, statusMessage: `${fieldName} is required` })
  }
  if (value.length > maxLength) {
    throw createError({ statusCode: 400, statusMessage: `${fieldName} is too long` })
  }
  return value.trim()
}
```

### Quantity Validation

```typescript
export function validateQuantity(value: unknown): number {
  const qty = Number(value)
  if (!Number.isInteger(qty) || qty < 0 || qty > 99) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid quantity' })
  }
  return qty
}
```

### Address Validation

Validate every field of address objects. Commercetools requires `country` as an ISO 3166-1 alpha-2 code — validate that too if strict compliance is needed.

```typescript
export function validateAddress(addr: unknown): ValidatedAddress {
  if (!addr || typeof addr !== 'object') {
    throw createError({ statusCode: 400, statusMessage: 'Address is required' })
  }
  const a = addr as Record<string, unknown>
  return {
    firstName: validateString(a.firstName, 'firstName', 100),
    lastName: validateString(a.lastName, 'lastName', 100),
    streetName: validateString(a.streetName, 'streetName', 200),
    streetNumber: validateString(a.streetNumber, 'streetNumber', 20),
    postalCode: validateString(a.postalCode, 'postalCode', 20),
    city: validateString(a.city, 'city', 100),
    country: validateString(a.country, 'country', 2),
  }
}
```

## Rate Limiting

Authentication endpoints (login, register) are brute-force targets. Apply rate limiting keyed by IP address.

```typescript
const WINDOW_MS = 15 * 60 * 1000 // 15 minutes
const MAX_ATTEMPTS = 10

const attempts = new Map<string, { count: number; resetAt: number }>()

export function checkRateLimit(key: string): void {
  const now = Date.now()
  const entry = attempts.get(key)

  if (entry && now < entry.resetAt) {
    if (entry.count >= MAX_ATTEMPTS) {
      throw createError({ statusCode: 429, statusMessage: 'Too many attempts, try again later' })
    }
    entry.count++
  } else {
    attempts.set(key, { count: 1, resetAt: now + WINDOW_MS })
  }
}

// In login route:
const ip = getRequestIP(event, { xForwardedFor: true }) ?? 'unknown'
checkRateLimit(`login:${ip}`)
```

**Note:** In-memory rate limiting works for single-instance deployments. For multi-instance production, use Redis or a distributed rate limiter.

## Error Handling

### Never Leak Internal Details

Commercetools error responses contain internal project details, field names, and sometimes customer data. Never forward raw error messages to the client.

**Vulnerable pattern:**
```typescript
// DANGEROUS: Forwards Commercetools error details to the browser
catch (error: any) {
  throw createError({
    statusCode: error.statusCode || 500,
    statusMessage: error.message,         // may contain internal details
    data: error.body?.errors,             // leaks field names, project structure
  })
}
```

**Safe pattern:**
```typescript
export function safeError(error: unknown, fallbackMessage = 'An error occurred'): never {
  // Re-throw errors we already created (our own createError calls)
  if (error && typeof error === 'object' && 'statusCode' in error) {
    throw error
  }
  // Log the real error server-side, send generic message to client
  console.error('[API Error]', error)
  throw createError({ statusCode: 500, statusMessage: fallbackMessage })
}
```

**Exception:** It's safe to forward specific, known error conditions you've explicitly mapped:
```typescript
if (error.statusCode === 400 && error.message?.includes('duplicate')) {
  throw createError({ statusCode: 409, statusMessage: 'An account with this email already exists' })
}
safeError(error, 'Registration failed')
```

## Cookie Configuration Summary

| Cookie | httpOnly | secure | sameSite | maxAge | Clear on logout |
|---|---|---|---|---|---|
| `anonymous_id` | `true` | `true` (dev: `false`) | `lax` | 1 year | Yes |
| `customer_session` | `true` | `true` (dev: `false`) | `strict` | 30 days | Yes |

- **`lax`** for anonymous ID: allows the cookie to be sent on top-level navigations (e.g., returning from a payment provider redirect)
- **`strict`** for customer session: prevents the cookie from being sent on any cross-site request, protecting authenticated state from CSRF

## Security Audit Checklist

Use this checklist to audit any Commercetools BFF implementation:

### Session & Cookies
- [ ] `anonymousId` is generated server-side with `crypto.randomUUID()`
- [ ] `anonymousId` is validated against UUID regex before use in any API call or query predicate
- [ ] Customer session cookie is signed (HMAC or encrypted) — not plain JSON
- [ ] Session signature uses timing-safe comparison
- [ ] All cookies have `httpOnly: true`
- [ ] All cookies have `secure: true` in production
- [ ] Customer session cookie uses `sameSite: 'strict'`
- [ ] Logout clears both customer session and anonymous ID cookies

### Query Injection
- [ ] Every value interpolated into a `where` predicate is validated against a strict format (UUID, email regex, etc.)
- [ ] No raw user input is concatenated into query predicates

### Input Validation
- [ ] Email addresses validated with regex before login/register/setCustomerEmail
- [ ] String inputs (names, SKUs) have length limits
- [ ] Quantities are validated as integers within a reasonable range (0–99)
- [ ] Addresses have all required fields validated
- [ ] Route parameters (e.g., `lineItemId`) validated as non-empty strings

### Rate Limiting
- [ ] Login endpoint is rate-limited by IP
- [ ] Register endpoint is rate-limited by IP
- [ ] Rate limiter returns 429 with generic message (no details about limits)

### Error Handling
- [ ] No Commercetools error messages forwarded raw to the client
- [ ] All catch blocks use a safe error helper or map to known error messages
- [ ] Server-side logging captures the real error for debugging
- [ ] Known error conditions (duplicate email, invalid credentials) are mapped to user-friendly messages

### API Scopes
- [ ] Client credentials use minimum required scopes
- [ ] `manage_orders` covers both cart and order operations (no separate `manage_carts` scope)
- [ ] `manage_payments` is explicitly added if using payment features
- [ ] `manage_customers` is added if using customer signup/login via admin endpoints
- [ ] Scopes do not include `manage_project` or other admin-level permissions
