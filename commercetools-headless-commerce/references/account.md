# Account & Customer Management

## Table of Contents

1. [Sign Up](#sign-up)
2. [Sign In](#sign-in)
3. [Profile Management](#profile-management)
4. [Password Management](#password-management)
5. [Email Verification](#email-verification)
6. [Anonymous / Guest Checkout](#anonymous--guest-checkout)

## Key Types

```typescript
import type {
  Customer,
  CustomerSignInResult,
  MyCustomerDraft,
  MyCustomerSignin,
  CustomerUpdateAction,
  CustomerChangePassword,
  BaseAddress,
} from '@commercetools/platform-sdk'
```

---

## Sign Up

### Create Customer Account

**Me Endpoint (storefront):**

```typescript
import type { MyCustomerDraft } from '@commercetools/platform-sdk'

const customerDraft: MyCustomerDraft = {
  email: 'customer@example.com',
  password: 'SecureP@ss123',
  firstName: 'John',
  lastName: 'Doe',
  addresses: [
    {
      country: 'DE',
      firstName: 'John',
      lastName: 'Doe',
      streetName: 'Hauptstraße',
      streetNumber: '1',
      postalCode: '10115',
      city: 'Berlin',
    },
  ],
  defaultShippingAddress: 0,  // index into addresses array
  defaultBillingAddress: 0,
}

const { body: result } = await apiRoot
  .me()
  .signup()
  .post({ body: customerDraft })
  .execute()

// result: CustomerSignInResult
// result.customer: Customer
// result.cart?: Cart (transferred from anonymous session)
```

**MyCustomerDraft fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `email` | `string` | Yes | Email address |
| `password` | `string` | Yes | Password |
| `firstName` | `string` | No | First name |
| `lastName` | `string` | No | Last name |
| `middleName` | `string` | No | Middle name |
| `title` | `string` | No | Title (Mr., Mrs., etc.) |
| `dateOfBirth` | `string` | No | Date of birth (`YYYY-MM-DD`) |
| `locale` | `string` | No | Preferred locale |
| `addresses` | `BaseAddress[]` | No | Address list |
| `defaultShippingAddress` | `number` | No | Index into `addresses` array |
| `defaultBillingAddress` | `number` | No | Index into `addresses` array |

**Anonymous session transfer**: If the signup request is made with an anonymous OAuth token that has an existing cart, the cart transfers to the new customer automatically and is returned in the response.

---

## Sign In

### Login

**Me Endpoint (storefront):**

```typescript
import type { MyCustomerSignin } from '@commercetools/platform-sdk'

const credentials: MyCustomerSignin = {
  email: 'customer@example.com',
  password: 'SecureP@ss123',
  activeCartSignInMode: 'MergeWithExistingCustomerCart',
}

const { body: result } = await apiRoot
  .me()
  .login()
  .post({ body: credentials })
  .execute()

// result: CustomerSignInResult
// result.customer: Customer
// result.cart?: Cart
```

| Field | Type | Required | Description |
|---|---|---|---|
| `email` | `string` | Yes | Email address |
| `password` | `string` | Yes | Password |
| `activeCartSignInMode` | `string` | No | Cart merge behavior |
| `updateProductData` | `boolean` | No | Recalculate line item prices on merge |

**activeCartSignInMode values:**

| Value | Behavior |
|---|---|
| `MergeWithExistingCustomerCart` | Merge anonymous cart line items into the customer's existing active cart. Default. |
| `UseAsNewActiveCustomerCart` | Discard the customer's old active cart, use the anonymous cart as-is. |

**After login**: Rebuild the SDK client with a customer-scoped token (password flow) to use "Me" endpoints as the authenticated customer. Or, when using client credentials in a BFF, switch to querying by `customerId` instead of `anonymousId`.

---

## Profile Management

### Get Profile

```typescript
const { body: customer } = await apiRoot
  .me()
  .get()
  .execute()
```

Returns the full `Customer` object.

### Update Profile

```typescript
import type { CustomerUpdateAction } from '@commercetools/platform-sdk'

const actions: CustomerUpdateAction[] = [
  { action: 'setFirstName', firstName: 'Jane' },
  { action: 'setLastName', lastName: 'Smith' },
]

const { body: updatedCustomer } = await apiRoot
  .me()
  .post({ body: { version: customer.version, actions } })
  .execute()
```

**Profile update actions:**

| Action | Key Fields | Description |
|---|---|---|
| `setFirstName` | `firstName` | Update first name |
| `setLastName` | `lastName` | Update last name |
| `setMiddleName` | `middleName` | Update middle name |
| `setTitle` | `title` | Update title |
| `setDateOfBirth` | `dateOfBirth` | Update date of birth |
| `setLocale` | `locale` | Update preferred locale |
| `setCompanyName` | `companyName` | Update company name |

### Address Management Actions

**addAddress:**

```typescript
const action: CustomerUpdateAction = {
  action: 'addAddress',
  address: {
    country: 'DE',
    firstName: 'John',
    lastName: 'Doe',
    streetName: 'Neue Straße',
    streetNumber: '5',
    postalCode: '80331',
    city: 'Munich',
  },
}
```

The response includes the new address with an auto-generated `id`. Use this ID for subsequent operations.

**changeAddress** — Replace an existing address:

```typescript
const action: CustomerUpdateAction = {
  action: 'changeAddress',
  addressId: 'address-uuid',
  address: {
    country: 'DE',
    firstName: 'John',
    lastName: 'Doe',
    streetName: 'Updated Street',
    streetNumber: '10',
    postalCode: '80331',
    city: 'Munich',
  },
}
```

**removeAddress:**

```typescript
const action: CustomerUpdateAction = {
  action: 'removeAddress',
  addressId: 'address-uuid',
}
```

**setDefaultShippingAddress:**

```typescript
const action: CustomerUpdateAction = {
  action: 'setDefaultShippingAddress',
  addressId: 'address-uuid',  // set to undefined to unset
}
```

**setDefaultBillingAddress:**

```typescript
const action: CustomerUpdateAction = {
  action: 'setDefaultBillingAddress',
  addressId: 'address-uuid',  // set to undefined to unset
}
```

---

## Password Management

### Change Password (Logged In)

```typescript
const { body: updatedCustomer } = await apiRoot
  .me()
  .password()
  .post({
    body: {
      version: customer.version,
      currentPassword: 'OldPassword123',
      newPassword: 'NewSecureP@ss456',
    },
  })
  .execute()
```

After changing the password, the existing OAuth token is invalidated. The client must re-authenticate.

### Password Reset (Forgot Password)

**Step 1**: Request a password reset token (server-side admin endpoint):

```typescript
const { body: tokenResult } = await apiRoot
  .customers()
  .passwordToken()
  .post({
    body: { email: 'customer@example.com' },
  })
  .execute()

// tokenResult.value — send this to the customer via email
// Token has a configurable TTL (default: 30 minutes)
```

**Step 2**: Reset the password with the token:

```typescript
const { body: customer } = await apiRoot
  .customers()
  .passwordReset()
  .post({
    body: {
      tokenValue: 'token-from-email',
      newPassword: 'NewSecureP@ss456',
    },
  })
  .execute()
```

Or via the Me endpoint:

```typescript
const { body: customer } = await apiRoot
  .me()
  .password()
  .reset()
  .post({
    body: {
      tokenValue: 'token-from-email',
      newPassword: 'NewSecureP@ss456',
    },
  })
  .execute()
```

---

## Email Verification

### Step 1: Create Email Verification Token (Server-Side)

```typescript
const { body: tokenResult } = await apiRoot
  .customers()
  .emailToken()
  .post({
    body: {
      id: 'customer-uuid',
      version: customer.version,
      ttlMinutes: 1440,  // 24 hours
    },
  })
  .execute()

// tokenResult.value — send this to the customer via email
```

### Step 2: Confirm Email

```typescript
const { body: customer } = await apiRoot
  .me()
  .emailConfirm()
  .post({
    body: { tokenValue: 'token-from-email' },
  })
  .execute()

// customer.isEmailVerified === true
```

---

## Anonymous / Guest Checkout

Anonymous sessions use OAuth tokens with `anonymous` grant type (via `.withAnonymousSessionFlow()` on the client builder). No customer account is created.

### Flow

1. Build client with anonymous session or client credentials flow
2. Create a cart with `anonymousId` — persist the ID in a cookie (e.g., `crypto.randomUUID()`)
3. Set `customerEmail` on the cart for order confirmation
4. Set addresses, shipping method, attach payment
5. Create order from cart

### Resource Transfer on Signup/Login

When an anonymous user signs up or logs in, resources with the matching `anonymousId` transfer to the customer automatically:
- Active carts
- Orders (for order history)
- Payments

No manual merge step is required. The transfer happens as part of the signup/login response.

### Building an Anonymous Client

```typescript
import { ClientBuilder } from '@commercetools/ts-client'
import type { AnonymousAuthMiddlewareOptions } from '@commercetools/ts-client'

const anonymousAuth: AnonymousAuthMiddlewareOptions = {
  host: AUTH_HOST,
  projectKey: PROJECT_KEY,
  credentials: { clientId: CLIENT_ID, clientSecret: CLIENT_SECRET },
  scopes: ['manage_my_orders:my-project', 'manage_my_profile:my-project'],
  httpClient: fetch,
}

const client = new ClientBuilder()
  .withAnonymousSessionFlow(anonymousAuth)
  .withHttpMiddleware(httpOptions)
  .build()
```

The token is tied to an `anonymousId` that persists across requests for the token's lifetime.

### BFF Pattern Alternative

When using client credentials in server routes (BFF), manage anonymous IDs yourself:

```typescript
// Client generates anonymousId and stores in cookie
const anonymousId = crypto.randomUUID()

// Server creates cart with explicit anonymousId
const { body: cart } = await apiRoot.carts().post({
  body: {
    anonymousId,
    currency: 'EUR',
    customerEmail: 'guest@example.com',
    lineItems: [{ sku: 'SKU-001', quantity: 1 }],
  },
}).execute()

// On login, resources transfer automatically
const { body: signInResult } = await apiRoot.me().login().post({
  body: {
    email: 'customer@example.com',
    password: 'password',
    activeCartSignInMode: 'MergeWithExistingCustomerCart',
  },
}).execute()
// signInResult.cart now contains the merged cart
```
