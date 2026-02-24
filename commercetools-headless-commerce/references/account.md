# Account & Customer Management

## Table of Contents

1. [Sign Up](#sign-up)
2. [Sign In](#sign-in)
3. [Profile Management](#profile-management)
4. [Password Management](#password-management)
5. [Email Verification](#email-verification)
6. [Anonymous / Guest Checkout](#anonymous--guest-checkout)

---

## Sign Up

### Create Customer Account

```
POST /me/signup
```

```json
{
  "email": "customer@example.com",
  "password": "SecureP@ss123",
  "firstName": "John",
  "lastName": "Doe",
  "addresses": [
    {
      "country": "DE",
      "firstName": "John",
      "lastName": "Doe",
      "streetName": "Hauptstraße",
      "streetNumber": "1",
      "postalCode": "10115",
      "city": "Berlin"
    }
  ],
  "defaultShippingAddress": 0,
  "defaultBillingAddress": 0
}
```

**MyCustomerDraft fields:**

| Field | Type | Required | Description |
|---|---|---|---|
| `email` | `String` | Yes | Email address |
| `password` | `String` | Yes | Password |
| `firstName` | `String` | No | First name |
| `lastName` | `String` | No | Last name |
| `middleName` | `String` | No | Middle name |
| `title` | `String` | No | Title (Mr., Mrs., etc.) |
| `dateOfBirth` | `Date` | No | Date of birth (`YYYY-MM-DD`) |
| `locale` | `String` | No | Preferred locale |
| `addresses` | `[BaseAddress]` | No | Address list |
| `defaultShippingAddress` | `Int` | No | Index into `addresses` array |
| `defaultBillingAddress` | `Int` | No | Index into `addresses` array |

**Response**: `CustomerSignInResult` containing `customer` and optionally `cart`:

```json
{
  "customer": {
    "id": "customer-uuid",
    "version": 1,
    "email": "customer@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "addresses": [...],
    "defaultShippingAddressId": "address-uuid",
    "defaultBillingAddressId": "address-uuid"
  },
  "cart": {
    "id": "cart-uuid",
    "version": 3
  }
}
```

**Anonymous session transfer**: If the signup request is made with an anonymous OAuth token that has an existing cart, the cart transfers to the new customer automatically.

---

## Sign In

### Login

```
POST /me/login
```

```json
{
  "email": "customer@example.com",
  "password": "SecureP@ss123",
  "activeCartSignInMode": "MergeWithExistingCustomerCart"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `email` | `String` | Yes | Email address |
| `password` | `String` | Yes | Password |
| `activeCartSignInMode` | `String` | No | Cart merge behavior |
| `updateProductData` | `Boolean` | No | Recalculate line item prices on merge |

**activeCartSignInMode values:**

| Value | Behavior |
|---|---|
| `MergeWithExistingCustomerCart` | Merge anonymous cart line items into the customer's existing active cart. Default. |
| `UseAsNewActiveCustomerCart` | Discard the customer's old active cart, use the anonymous cart as-is. |

**Response**: `CustomerSignInResult` (same shape as signup) with `customer` and `cart`.

After login, obtain a new customer-scoped OAuth token via the password flow to use "Me" endpoints as the authenticated customer.

---

## Profile Management

### Get Profile

```
GET /me
```

Returns the full customer object.

### Update Profile

```
POST /me
```

```json
{
  "version": 3,
  "actions": [
    { "action": "setFirstName", "firstName": "Jane" },
    { "action": "setLastName", "lastName": "Smith" }
  ]
}
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

```json
{
  "action": "addAddress",
  "address": {
    "country": "DE",
    "firstName": "John",
    "lastName": "Doe",
    "streetName": "Neue Straße",
    "streetNumber": "5",
    "postalCode": "80331",
    "city": "Munich"
  }
}
```

**changeAddress** — Replace an existing address:

```json
{
  "action": "changeAddress",
  "addressId": "address-uuid",
  "address": {
    "country": "DE",
    "firstName": "John",
    "lastName": "Doe",
    "streetName": "Updated Street",
    "streetNumber": "10",
    "postalCode": "80331",
    "city": "Munich"
  }
}
```

**removeAddress:**

```json
{
  "action": "removeAddress",
  "addressId": "address-uuid"
}
```

**setDefaultShippingAddress:**

```json
{
  "action": "setDefaultShippingAddress",
  "addressId": "address-uuid"
}
```

**setDefaultBillingAddress:**

```json
{
  "action": "setDefaultBillingAddress",
  "addressId": "address-uuid"
}
```

Set `addressId` to `null` to unset the default.

---

## Password Management

### Change Password (Logged In)

```
POST /me/password
```

```json
{
  "version": 3,
  "currentPassword": "OldPassword123",
  "newPassword": "NewSecureP@ss456"
}
```

### Password Reset (Forgot Password)

**Step 1**: Request a password reset token (server-side admin endpoint):

```
POST /customers/password-token
```

```json
{
  "email": "customer@example.com"
}
```

**Response**: Returns `{ "value": "token-string" }`. Send this token to the customer via email.

**Step 2**: Reset the password with the token:

```
POST /me/password/reset
```

```json
{
  "tokenValue": "token-from-email",
  "newPassword": "NewSecureP@ss456"
}
```

The token has a configurable TTL (default: 30 minutes).

---

## Email Verification

### Step 1: Create Email Verification Token (Server-Side)

```
POST /customers/email-token
```

```json
{
  "id": "customer-uuid",
  "version": 3,
  "ttlMinutes": 1440
}
```

**Response**: Returns `{ "value": "token-string" }`. Send this token to the customer via email.

### Step 2: Confirm Email

```
POST /me/email/confirm
```

```json
{
  "tokenValue": "token-from-email"
}
```

Sets `isEmailVerified: true` on the customer.

---

## Anonymous / Guest Checkout

Anonymous sessions use OAuth tokens with `anonymous` grant type. No customer account is created.

### Flow

1. Obtain an anonymous OAuth token (no email/password needed)
2. Create a cart — the cart gets an `anonymousId` automatically
3. Set `customerEmail` on the cart for order confirmation
4. Set addresses, shipping method, attach payment
5. Create order from cart

### Resource Transfer on Signup/Login

When an anonymous user signs up or logs in, resources with the matching `anonymousId` transfer to the customer automatically:
- Active carts
- Orders (for order history)
- Payments

No manual merge step is required. The transfer happens as part of the signup/login response.

### Anonymous OAuth Token

```
POST https://auth.{region}.commercetools.com/oauth/{projectKey}/anonymous/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&scope=manage_my_orders:{projectKey} manage_my_profile:{projectKey}
```

The token is tied to an `anonymousId` that persists across requests for the token's lifetime.
