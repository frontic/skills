# Customer Account Operations

## Table of Contents

1. [Registration](#registration)
2. [Login / Logout](#login--logout)
3. [Profile Management](#profile-management)
4. [Addresses](#addresses)
5. [Password Recovery](#password-recovery)
6. [Order History](#order-history)
7. [Customer Account API Note](#customer-account-api-note)

---

## Registration

### customerCreate

```graphql
mutation customerCreate($input: CustomerCreateInput!) {
  customerCreate(input: $input) {
    customer { id firstName lastName email }
    customerUserErrors { field message code }
  }
}
```

**CustomerCreateInput fields:**

| Field | Type | Description |
|---|---|---|
| `email` | `String!` | Email address (required) |
| `password` | `String!` | Password (required) |
| `firstName` | `String` | First name |
| `lastName` | `String` | Last name |
| `phone` | `String` | Phone (E.164 format) |
| `acceptsMarketing` | `Boolean` | Marketing consent |

After registration, call `customerAccessTokenCreate` to log the customer in.

---

## Login / Logout

### customerAccessTokenCreate (Login)

```graphql
mutation customerAccessTokenCreate($input: CustomerAccessTokenCreateInput!) {
  customerAccessTokenCreate(input: $input) {
    customerAccessToken {
      accessToken
      expiresAt
    }
    customerUserErrors { field message code }
  }
}
```

**Input:** `{ email: String!, password: String! }`

**Response:** Returns `accessToken` (String) and `expiresAt` (DateTime). Store the token securely (httpOnly cookie recommended).

### customerAccessTokenRenew

```graphql
mutation customerAccessTokenRenew($customerAccessToken: String!) {
  customerAccessTokenRenew(customerAccessToken: $customerAccessToken) {
    customerAccessToken { accessToken expiresAt }
    userErrors { field message }
  }
}
```

Must be called **before** the token expires. For expired tokens, use `customerAccessTokenCreate` again.

### customerAccessTokenDelete (Logout)

```graphql
mutation customerAccessTokenDelete($customerAccessToken: String!) {
  customerAccessTokenDelete(customerAccessToken: $customerAccessToken) {
    deletedAccessToken
    deletedCustomerAccessTokenId
    userErrors { field message }
  }
}
```

---

## Profile Management

### customer Query

```graphql
query customer($customerAccessToken: String!) {
  customer(customerAccessToken: $customerAccessToken) {
    id
    firstName
    lastName
    email
    phone
    displayName
    acceptsMarketing
    numberOfOrders
    defaultAddress { id address1 city province country zip }
    addresses(first: 10) {
      edges { node { id address1 address2 city province country zip phone firstName lastName company } }
    }
  }
}
```

### customerUpdate

```graphql
mutation customerUpdate($customer: CustomerUpdateInput!, $customerAccessToken: String!) {
  customerUpdate(customer: $customer, customerAccessToken: $customerAccessToken) {
    customer { id firstName lastName email phone }
    customerAccessToken { accessToken expiresAt }
    customerUserErrors { field message code }
  }
}
```

**CustomerUpdateInput fields:**

| Field | Type | Description |
|---|---|---|
| `firstName` | `String` | First name |
| `lastName` | `String` | Last name |
| `email` | `String` | Email |
| `phone` | `String` | Phone (E.164, set to `null` to remove) |
| `password` | `String` | New password (**invalidates all existing tokens; new one returned**) |
| `acceptsMarketing` | `Boolean` | Marketing consent |

---

## Addresses

### customerAddressCreate

```graphql
mutation customerAddressCreate($customerAccessToken: String!, $address: MailingAddressInput!) {
  customerAddressCreate(customerAccessToken: $customerAccessToken, address: $address) {
    customerAddress { id address1 address2 city province country zip }
    customerUserErrors { field message code }
  }
}
```

**MailingAddressInput fields:**

| Field | Type | Description |
|---|---|---|
| `address1` | `String` | Street address or PO Box |
| `address2` | `String` | Apartment, suite, unit |
| `city` | `String` | City |
| `company` | `String` | Company name |
| `country` | `String` | Country name |
| `firstName` | `String` | First name |
| `lastName` | `String` | Last name |
| `phone` | `String` | Phone (E.164) |
| `province` | `String` | State/province |
| `zip` | `String` | Postal code |

### customerAddressUpdate

```graphql
mutation customerAddressUpdate($customerAccessToken: String!, $id: ID!, $address: MailingAddressInput!) {
  customerAddressUpdate(customerAccessToken: $customerAccessToken, id: $id, address: $address) {
    customerAddress { id address1 city province country zip }
    customerUserErrors { field message code }
  }
}
```

### customerAddressDelete

```graphql
mutation customerAddressDelete($customerAccessToken: String!, $id: ID!) {
  customerAddressDelete(customerAccessToken: $customerAccessToken, id: $id) {
    deletedCustomerAddressId
    customerUserErrors { field message code }
  }
}
```

### customerDefaultAddressUpdate

```graphql
mutation customerDefaultAddressUpdate($customerAccessToken: String!, $addressId: ID!) {
  customerDefaultAddressUpdate(customerAccessToken: $customerAccessToken, addressId: $addressId) {
    customer { id defaultAddress { id } }
    customerUserErrors { field message code }
  }
}
```

---

## Password Recovery

### Step 1: Request Recovery Email

```graphql
mutation customerRecover($email: String!) {
  customerRecover(email: $email) {
    customerUserErrors { field message code }
  }
}
```

Sends a password reset email. Rate-limited by IP — use `Shopify-Storefront-Buyer-IP` header for server-side calls.

### Step 2: Reset Password

**Option A — with parsed token and ID:**

```graphql
mutation customerReset($id: ID!, $input: CustomerResetInput!) {
  customerReset(id: $id, input: $input) {
    customer { id }
    customerAccessToken { accessToken expiresAt }
    customerUserErrors { field message code }
  }
}
```

`CustomerResetInput: { resetToken: String!, password: String! }`

**Option B — with full URL:**

```graphql
mutation customerResetByUrl($resetUrl: URL!, $password: String!) {
  customerResetByUrl(resetUrl: $resetUrl, password: $password) {
    customer { id }
    customerAccessToken { accessToken expiresAt }
    customerUserErrors { field message code }
  }
}
```

Both return a new `customerAccessToken`, automatically logging the customer in.

---

## Order History

Query orders via the `customer` query:

```graphql
query customerOrders($customerAccessToken: String!, $first: Int!) {
  customer(customerAccessToken: $customerAccessToken) {
    orders(first: $first, sortKey: PROCESSED_AT, reverse: true) {
      edges {
        node {
          id
          orderNumber
          name
          processedAt
          financialStatus
          fulfillmentStatus
          totalPrice { amount currencyCode }
          lineItems(first: 50) {
            edges {
              node {
                title
                quantity
                variant {
                  id
                  title
                  price { amount currencyCode }
                  image { url altText }
                  product { handle }
                }
              }
            }
          }
          shippingAddress { address1 city province country zip }
        }
      }
    }
  }
}
```

Order sort keys: `PROCESSED_AT`, `TOTAL_PRICE`, `ID`, `RELEVANCE`.

---

## Customer Account API Note

Shopify also offers a newer **Customer Account API** (GA since January 2024) using OAuth 2.0 authentication. It is a separate system — tokens from one cannot be used with the other. The mutations above are the **classic Storefront API** customer system, which still works but Shopify is encouraging the new API for new builds.

For admin-created accounts that need activation:

```graphql
mutation customerActivateByUrl($activationUrl: URL!, $password: String!) {
  customerActivateByUrl(activationUrl: $activationUrl, password: $password) {
    customer { id }
    customerAccessToken { accessToken expiresAt }
    customerUserErrors { field message code }
  }
}
```
