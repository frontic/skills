# Account & Customer Management

## Table of Contents

1. [Registration](#registration)
2. [Login / Logout](#login--logout)
3. [Customer Profile](#customer-profile)
4. [Addresses](#addresses)
5. [Password Management](#password-management)
6. [Order History](#order-history)
7. [Wishlist](#wishlist)
8. [Newsletter](#newsletter)
9. [Guest to Registered Conversion](#guest-to-registered-conversion)

---

## Registration

### Register a Customer

```
POST /store-api/account/register
```

```json
{
  "email": "customer@example.com",
  "password": "SecureP@ss123",
  "firstName": "John",
  "lastName": "Doe",
  "acceptedDataProtection": true,
  "storefrontUrl": "https://your-shop.com",
  "salutationId": "<salutation-id>",
  "billingAddress": {
    "street": "Main Street 1",
    "zipcode": "12345",
    "city": "Berlin",
    "countryId": "<country-id>"
  }
}
```

**Required fields**: `email`, `password`, `firstName`, `lastName`, `acceptedDataProtection`, `storefrontUrl`, `billingAddress` (with `street`, `zipcode`, `city`, `countryId`).

**Optional fields**: `salutationId`, `title`, `birthdayDay`/`birthdayMonth`/`birthdayYear`, `shippingAddress` (defaults to billing if omitted), `guest`, `affiliateCode`, `campaignCode`.

**Guest registration**: Set `guest: true`. Guests don't need a password and can reuse email addresses.

**Response**: Returns the customer object and a new `sw-context-token` in the header.

### Double Opt-In

If enabled in the Sales Channel settings, registration sends a confirmation email. Confirm with:

```
POST /store-api/account/register-confirm
```

```json
{
  "hash": "<hash-from-email>",
  "em": "<sha1-of-email>"
}
```

Both values come from the confirmation email URL parameters.

### Fetch Reference IDs for Registration

Before building a registration form, fetch the available salutations and countries:

```
POST /store-api/salutation    → Returns salutationId values
POST /store-api/country       → Returns countryId values
POST /store-api/country-state/{countryId}  → Returns countryStateId values
```

---

## Login / Logout

### Login

```
POST /store-api/account/login
```

```json
{
  "username": "customer@example.com",
  "password": "SecureP@ss123"
}
```

**Response**: Returns a new `sw-context-token`. **Always update the stored token.** The old anonymous/guest token becomes invalid.

**Cart merging**: If the user had items in a guest cart before logging in, pass the guest's `sw-context-token` in the request header. Shopware merges both carts automatically.

### Logout

```
POST /store-api/account/logout
```

Invalidates the context token. Obtain a new anonymous token via `GET /store-api/context`.

---

## Customer Profile

### Get Current Customer

```
POST /store-api/account/customer
```

Returns the full customer object. Supports associations in the request body:

```json
{
  "associations": {
    "group": {},
    "defaultBillingAddress": { "associations": { "country": {} } },
    "defaultShippingAddress": { "associations": { "country": {} } },
    "salutation": {}
  }
}
```

Returns 403 if not logged in.

### Update Profile

```
POST /store-api/account/change-profile
```

```json
{
  "firstName": "John",
  "lastName": "Smith",
  "salutationId": "<salutation-id>",
  "title": "Dr.",
  "birthdayDay": 15,
  "birthdayMonth": 6,
  "birthdayYear": 1990
}
```

**Required**: `firstName`, `lastName`. Others are optional.

### Change Email

```
POST /store-api/account/change-email
```

```json
{
  "email": "new-email@example.com",
  "emailConfirmation": "new-email@example.com",
  "password": "CurrentPassword123"
}
```

### Delete Account

```
DELETE /store-api/account/customer
```

Deletes the customer profile, addresses, and wishlists. Orders and reviews are preserved.

---

## Addresses

### List Addresses

```
POST /store-api/account/list-address
```

Accepts criteria in request body for filtering/pagination.

### Create Address

```
POST /store-api/account/address
```

```json
{
  "firstName": "John",
  "lastName": "Doe",
  "street": "Main Street 1",
  "zipcode": "12345",
  "city": "Berlin",
  "countryId": "<country-id>",
  "countryStateId": "<state-id>",
  "phoneNumber": "+49123456789",
  "company": "ACME Inc.",
  "department": "Engineering",
  "additionalAddressLine1": "Building A",
  "additionalAddressLine2": "Floor 3"
}
```

**Required**: `firstName`, `lastName`, `street`, `city`, `countryId`.

### Update Address

```
PATCH /store-api/account/address/{addressId}
```

Same body as create. Only include fields to update.

### Delete Address

```
DELETE /store-api/account/address/{addressId}
```

Cannot delete addresses set as default billing or shipping.

### Set Default Addresses

```
PATCH /store-api/account/address/default-billing/{addressId}
PATCH /store-api/account/address/default-shipping/{addressId}
```

---

## Password Management

### Change Password (Logged In)

```
POST /store-api/account/change-password
```

```json
{
  "password": "CurrentPassword",
  "newPassword": "NewSecureP@ss",
  "newPasswordConfirm": "NewSecureP@ss"
}
```

### Password Recovery (Forgot Password)

**Step 1**: Request recovery email

```
POST /store-api/account/recovery-password
```

```json
{
  "email": "customer@example.com",
  "storefrontUrl": "https://your-shop.com"
}
```

**Step 2**: Reset with credentials from email

```
POST /store-api/account/recovery-password-confirm
```

```json
{
  "hash": "<hash-from-email>",
  "newPassword": "NewSecureP@ss",
  "newPasswordConfirm": "NewSecureP@ss"
}
```

### Check Recovery Link Expiry

```
POST /store-api/account/customer-recovery-is-expired
```

```json
{
  "hash": "<hash-from-email>"
}
```

---

## Order History

### List Orders

```
POST /store-api/order
```

```json
{
  "associations": {
    "stateMachineState": {},
    "transactions": { "associations": { "stateMachineState": {} } },
    "deliveries": { "associations": { "stateMachineState": {} } },
    "lineItems": { "associations": { "cover": {} } }
  },
  "sort": [{ "field": "createdAt", "order": "DESC" }],
  "limit": 10,
  "page": 1
}
```

Useful associations:
- `stateMachineState` — Order state (open, in_progress, completed, cancelled)
- `transactions.stateMachineState` — Payment state (open, paid, refunded, cancelled)
- `deliveries.stateMachineState` — Delivery state (open, shipped, returned)

### Download Digital Products

```
GET /store-api/order/download/{orderId}/{downloadId}
```

---

## Wishlist

Requires the wishlist feature to be enabled. Only available for logged-in customers.

```
POST   /store-api/customer/wishlist                    → Fetch wishlist (with criteria)
POST   /store-api/customer/wishlist/add/{productId}    → Add product
DELETE /store-api/customer/wishlist/delete/{productId}  → Remove product
POST   /store-api/customer/wishlist/merge              → Merge product IDs: { "productIds": ["..."] }
```

---

## Newsletter

```
POST /store-api/newsletter/subscribe      → Subscribe
POST /store-api/newsletter/confirm        → Confirm subscription (double opt-in)
POST /store-api/newsletter/unsubscribe    → Unsubscribe
POST /store-api/account/newsletter-recipient → Check subscription status (logged in)
```

---

## Guest to Registered Conversion

Convert a guest account to a registered customer:

```
POST /store-api/account/convert-guest
```

```json
{
  "password": "NewPassword123"
}
```

The guest must be logged in (have a valid context token from guest checkout).
