# Context & Session Management

## Overview

The Shopware Store API is stateless. All session state is carried via the `sw-context-token` header. The context holds: current customer (if logged in), language, currency, country, payment method, shipping method, and addresses.

## Required Headers

Every Store API request needs:

```
sw-access-key: <sales-channel-access-key>
```

The access key is found in Administration > Sales Channels > [channel] > API Access.

Most requests also accept these optional headers:

| Header | Purpose |
|---|---|
| `sw-context-token` | Session token. Identifies the user/guest session. |
| `sw-language-id` | Override the language for this request. |
| `sw-currency-id` | Override the currency for this request. |

## Getting a Context Token

```
GET /store-api/context
```

Returns the current context. If no `sw-context-token` is provided, Shopware creates a new anonymous/guest session and returns a token in the `sw-context-token` response header.

**Always persist the returned `sw-context-token`** from every response (it can change after login, registration, or context switches). Store it in a cookie or server-side session.

## Modifying the Context

```
PATCH /store-api/context
```

Switch language, currency, payment method, shipping method, country, or addresses:

```json
{
  "currencyId": "...",
  "languageId": "...",
  "paymentMethodId": "...",
  "shippingMethodId": "...",
  "countryId": "...",
  "countryStateId": "...",
  "billingAddressId": "...",
  "shippingAddressId": "..."
}
```

All fields are optional. Only include the ones to change.

**Response** returns the updated context token. Always update the stored token.

## Context Token Lifecycle

| Event | What happens |
|---|---|
| First visit (no token) | `GET /context` returns new anonymous token |
| Guest adds to cart | Token stays the same, cart persists with it |
| Customer logs in | `POST /account/login` returns a **new** token tied to the customer |
| Cart merge on login | If guest had cart items, Shopware merges them into the customer's existing cart automatically (pass the guest token as `sw-context-token` when calling login) |
| Customer logs out | `POST /account/logout` invalidates the token. Get a fresh anonymous one via `GET /context` |
| Token expires | Shopware clears inactive context tokens periodically. Treat 403/context-not-found as "start new session" |

## Fetching Available Options

Use these endpoints to populate dropdowns for context switching:

| Endpoint | Purpose |
|---|---|
| `POST /store-api/language` | Available languages |
| `POST /store-api/currency` | Available currencies |
| `POST /store-api/country` | Available countries |
| `POST /store-api/country-state/{countryId}` | States for a country |
| `POST /store-api/payment-method` | Available payment methods (pass `onlyAvailable: true` in body to filter) |
| `POST /store-api/shipping-method` | Available shipping methods (pass `onlyAvailable: true` query param) |
| `POST /store-api/salutation` | Available salutations (for registration/profile forms) |

All of these accept criteria objects for filtering, sorting, and pagination in the request body.

## Base URL Pattern

All Store API endpoints are prefixed with `/store-api/`. Example:

```
https://your-shop.com/store-api/context
https://your-shop.com/store-api/checkout/cart
```
