# Checkout

## Hosted Checkout Model

Shopify uses **hosted checkout exclusively** via the Storefront API. There are no mutations for custom payment processing. The old `checkoutCreate` / `checkoutCompleteWithCreditCardV2` mutations were **removed in April 2025**.

## Checkout Flow

```
1. Build cart (cartCreate, cartLinesAdd, etc.)
2. Optionally: cartBuyerIdentityUpdate with customerAccessToken
   → Pre-fills address and saved payment methods at checkout
3. Query cart.checkoutUrl
4. Redirect buyer to checkoutUrl
5. Shopify handles: shipping selection, payment, order creation
6. Shopify redirects buyer to your thank-you page
```

### Getting the Checkout URL

```graphql
query getCheckoutUrl($cartId: ID!) {
  cart(id: $cartId) {
    checkoutUrl
  }
}
```

### Redirecting to Checkout

```typescript
const { cart } = await storefrontQuery(GET_CHECKOUT_URL, { cartId })

// Redirect to Shopify's hosted checkout
window.location.href = cart.checkoutUrl
```

## Key Details

- **checkoutUrl** is a field on the `Cart` object (`URL!` type)
- Fetch the URL **when the buyer clicks checkout**, not in advance (URLs can expire)
- If a `customerAccessToken` is set on the cart's `buyerIdentity`, checkout provides a logged-in experience (pre-filled addresses, saved payment methods)
- After checkout, Shopify redirects to a configurable confirmation URL
- Shopify Plus merchants can customize checkout with **Checkout UI Extensions** and **Shopify Functions**, but checkout itself remains hosted

## What You Cannot Do

- Process payments directly via the Storefront API
- Build a fully custom checkout page with payment form
- Intercept or modify the checkout flow server-side (only via Shopify Functions / UI Extensions)

## Pre-Checkout Optimization

Before redirecting to checkout, ensure the cart is complete:

```graphql
query preCheckout($cartId: ID!) {
  cart(id: $cartId) {
    checkoutUrl
    totalQuantity
    cost { totalAmount { amount currencyCode } }
    buyerIdentity { email customer { id } }
    lines(first: 100) {
      edges {
        node {
          quantity
          merchandise {
            ... on ProductVariant {
              availableForSale
              currentlyNotInStock
            }
          }
        }
      }
    }
  }
}
```

Check `availableForSale` on variants before redirecting to avoid checkout errors.
