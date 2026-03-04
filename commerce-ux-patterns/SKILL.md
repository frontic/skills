---
name: commerce-ux-patterns
description: >
  Commerce UX patterns that drive conversion, increase average order value, and create a premium
  shopping experience. Covers the complete customer journey: product discovery, cart interactions,
  checkout flow, order confirmation, and post-purchase. Includes feedback patterns (toasts, inline,
  redirects), recommendation placement, urgency/scarcity cues, error recovery, and edge cases that
  are commonly missed. Maps each pattern to the Frontic blocks, components, and composables that
  implement it. Use this skill whenever building or improving any shopping flow — add-to-cart,
  checkout, cart page, product interactions, wishlist, empty states, order confirmation, or any
  feature where the user is browsing, buying, or managing purchases. Also trigger when the user
  mentions conversion, AOV, upsell, cross-sell, cart abandonment, or shopping experience — even if
  they don't explicitly say "UX patterns".
---

# Commerce UX Patterns

Every interaction in a storefront either builds confidence or creates doubt. This skill covers the patterns that separate a forgettable shop from one that converts — not through dark patterns, but through clarity, responsiveness, and thoughtful flow design.

The goal: make buying effortless while naturally increasing conversion rate and average order value. Every pattern here serves both the shopper (less friction, more confidence) and the business (more revenue, fewer abandoned carts).

## Frontic Implementation Map

Each pattern in this skill maps to concrete Frontic primitives. Use this as a quick reference — the details follow in each section.

| Pattern | Frontic block / component | Data composable |
|---------|--------------------------|-----------------|
| Product listing with filters | `category-page-01`, `filter-panel-01/02/03` | `useFronticSearch()` |
| Product detail page | `product-detail-01` | `useFronticBlock()` or `useFronticPage()` |
| Product cards in grids | `product-card-01` | `useFronticSearch().result.items` |
| Shopping cart | `cart-01` | `useCart()` (project composable) |
| Checkout flow | `checkout-01` | `useCart()`, form state |
| Search with filters/sort | `search-01` | `useFronticSearch()` |
| Navigation + mega-menu | `store-navigation-01/02` | `useFronticListing('MenuTree')` |
| Header/footer layouts | `header-01/02/03`, `footer-01/02/03` | Content collections |
| Toast notifications | Sonner (via `useNotify()`) | — |
| Favorites/wishlist | `useFavorites()` + `useFronticListing('FavoritesProducts')` | localStorage + API |

**Note on composables:** `useFronticSearch`, `useFronticPage`, `useFronticBlock`, and `useFronticListing` are provided by `@frontic/nuxt` (auto-imported). The project composables — `useCart()`, `useNotify()`, `useFavorites()` — need to be **created** in `app/composables/`. They don't exist in the bare skeleton. See the **nuxt-storefront-architect** skill for how to build them. For non-Nuxt projects, replace Frontic composables with raw `client.*` calls from the **frontic-implementation** skill.

All visible text must use `$t()` for i18n — never hard-code strings. Use kebab-case keys: `$t('product.buy.add-to-cart')`, `$t('cart.empty.title')`. See the **nuxt-storefront-architect** skill for the full i18n pattern.

## Core Principles

### 1. Every Action Gets Feedback

The user should never wonder "did that work?" — every interaction needs an immediate, visible response:

- **Optimistic updates** — Update the UI instantly, then sync with the backend. The cart count increments the moment they click "Add to Cart", not after the API responds.
- **Toast for background actions** — Adding to cart, adding to wishlist, removing an item. Toast confirms without interrupting the flow. Include an undo or "View Cart" action. In Frontic storefronts, use the `useNotify()` composable with `addToCartMessage()` for consistent toast formatting with product thumbnail, name, and price.
- **Inline for contextual feedback** — Form validation errors, stock warnings, price changes. Show them right where the user is looking.
- **Page transitions for major milestones** — Order placed → confirmation page. Payment failed → error state with clear recovery. Don't toast a successful order — it deserves its own page.

### 2. Never Dead-End the User

Every state — including empty and error states — should lead somewhere productive:

- Empty cart → Show recently viewed or popular items via `useFronticListing`, not just `$t('cart.empty.title')`
- Search with no results → Suggest alternatives, show popular categories, offer to broaden the search
- Out of stock → Offer notify-when-available, suggest similar products
- Payment failed → Explain what happened, suggest alternatives, keep the cart intact
- 404 product → Suggest similar products or redirect to the category

### 3. Reduce Decisions, Not Options

Don't remove choices — make the right choice obvious:

- Pre-select the first variant (the reference impl selects `product.variants[0]` on mount)
- Default to the most popular shipping method
- Show the recommended payment option first
- Use smart defaults for quantity (1, not empty)

## The Shopping Journey

### Product Discovery

**Search results and category pages** are where shopping intent forms. The `category-page-01` block and `useFronticSearch` composable handle the data layer. Optimize the UI for scanning and comparison:

- **Filters and sort** — `useFronticSearch` provides `state.available.filter` (UiFilter[] with labels, options, counts) and `state.available.sorting` (UiSort[] with labels). Wire these to a `SearchRefineSheet` or sidebar. Use `filterResult()`, `sortResult()`, `resetFilter()` to update results reactively.
- **Quick-add to cart** — For simple products (no variants), allow adding directly from the product card. Show a brief toast confirmation.
- **Quick-view** — For products with variants, offer a quick-view modal/drawer from the listing that shows variants and add-to-cart without full page navigation.
- **Wishlist toggle** — Heart icon on every product card. Toggle instantly (optimistic), toast to confirm with "View Wishlist" action. Implement with `useFavorites()` composable backed by localStorage.
- **Price visibility** — Always show the price on the card using `formatPrice(product.price)`. The `Price` type is `{ amount, precision, currency }`. If variants have different prices, show "From" + the lowest.
- **Badge hierarchy** — Use `<Badge color="promo">` for sale badges (most prominent, drives urgency), `<Badge color="new" variant="subtle">` secondary. Don't stack more than 2 badges.
- **Skeleton loading** — Show `ProductCardSkeleton` during `status === 'pending'`. Never show blank screens.
- **Recommendation sections** — "Trending", "Recently viewed" below the main grid. Don't compete with primary browsing.

### Product Detail Page (PDP)

The PDP is the decision point. The `product-detail-01` block implements the core layout. Key behaviors:

**Variant selection:**
- Show all variants visually (circular image thumbnails or Swatch components, not dropdowns)
- Disable unavailable variants rather than hiding them — hiding confuses users
- When selecting a variant, update the price, image, and availability instantly
- Link variants via `?sku=` query params so users can share or bookmark specific variants
- Pre-select a variant on mount: match `?sku=` param, or fall back to `variants[0]`

**Add to Cart:**
- Button must be visible without scrolling on mobile (sticky bottom bar)
- Use `<Button color="buy" size="xl">` — the add-to-cart button is the most important CTA on the page
- Show a loading state on the button during the API call
- On success: toast via `useNotify().addToCartMessage()` with product thumbnail, name, and formatted price
- On failure: inline error below the button
- After adding: keep the user on the PDP — don't redirect to cart

**Quantity:**
- Default to 1
- Use a `<Select>` stepper (the reference impl offers 1–10), not a free input
- If max quantity is limited, show it

**Conversion boosters on PDP:**
- **Urgency**: "Only 3 left in stock" (when genuinely low)
- **Social proof**: `<Rating>` + review count near the title
- **Shipping info**: `$t('product.shipping.free-over')` or estimated delivery date
- **Cross-sell**: "Complete the look" / "Frequently bought together" below the fold
- **Recently viewed**: Footer section via `useFronticListing`

### Cart

The cart is both a review step and a sales opportunity. The `cart-01` block implements the baseline. Key behaviors:

**Cart interactions:**
- **Quantity update** — Stepper with debounced API call. Show a subtle loading indicator on the line item, not a full-page spinner. Toast only on error.
- **Remove item** — Confirm with an undo toast (`$t('layout.toast.item-removed')` with "Undo" action), not a confirmation dialog.
- **Price change** — If price changed since added, highlight inline with old/new price. Don't silently update.
- **Out of stock** — Show item grayed out with clear message and "Remove" action. Don't auto-remove.

**Cart page layout:**
- Line items with thumbnail, title (linked to PDP via `product.link.path`), selected variant, unit price, quantity stepper, line total
- Order summary sidebar (desktop) or sticky bottom bar (mobile) with subtotal, shipping estimate, and checkout button
- Checkout button uses `<Button color="checkout">` and is always visible without scrolling

**Conversion boosters in cart:**
- **Free shipping threshold** — `$t('cart.shipping.free-threshold', { amount: remainingAmount })` with a progress bar. This is the single most effective AOV driver.
- **Cross-sell recommendations** — "You might also like" carousel below line items. 4-6 items. Allow quick-add.
- **Discount code input** — Visible but not prominent (expandable section). Don't make users hunt for it, but don't make it the focus.

**Empty cart:**
- Never just show `$t('cart.empty.title')` with nothing else
- Show recently viewed products or popular items via `useFronticListing`
- `$t('cart.empty.description')` + "Continue Shopping" button

### Checkout

Checkout is where trust and simplicity matter most. The `checkout-01` block provides a starting point.

**Flow structure:**
- **Single page preferred** for simple checkouts. Accordion sections: Contact → Shipping → Payment → Review.
- **Multi-step** for complex checkouts. Progress indicator with step labels. Allow navigating back.
- **Guest checkout first** — Don't force account creation. Offer it after order confirmation.

**Form UX:**
- **Inline validation** — Validate on blur. Show errors below the field. Highlight border in `destructive` color.
- **Smart defaults** — Pre-fill country from locale, suggest city from postal code.
- **Minimal fields** — Combined "Full name", no "Confirm email", phone only if needed for delivery.

**Shipping step:**
- Show methods with estimated delivery and price
- Pre-select the most popular option
- Use `RadioStack` for clear option selection
- If free shipping threshold is close, remind them

**Payment step:**
- Accepted payment methods with recognizable icons
- Pay button shows exact amount: `$t('checkout.pay-amount', { amount: formatPrice(total) })`
- Loading state on pay button — disable to prevent double-submit

**Error handling:**
- **Validation errors** — Scroll to first error, focus the field
- **Payment failure** — Stay on checkout page, clear message, suggest alternatives, keep form filled
- **Stock changed** — Modal with options: continue without item, go back to cart, or wait
- **Session timeout** — Restore cart on return, `$t('layout.toast.welcome-back')` toast

### Order Confirmation

This is the most emotionally positive moment — use it:

- Clear success state with checkmark animation
- Order number prominently displayed
- Full summary: items, shipping address, delivery estimate, total paid
- "Continue Shopping" button
- Email confirmation note
- Post-purchase recommendations (high-intent moment)
- Optional account creation: "Save your details for faster checkout next time"

### Wishlist / Favorites

Implemented with `useFavorites()` composable (localStorage) and `useFronticListing('FavoritesProducts', computed(() => ({ keys: keys.value })))` for product data:

- **Toggle** — Heart icon, instant toggle (optimistic), toast with "View Wishlist"
- **Wishlist page** — Grid matching product listing style. Each item has "Add to Cart" and "Remove"
- **Empty wishlist** — Recommendations or trending products
- **Stock alerts** — "Only 2 left" badge on low-stock wishlist items
- **Price drop** — Highlight reduced prices

## Feedback Pattern Reference

| Action | Feedback | Frontic Implementation |
|--------|----------|----------------------|
| Add to cart | Toast | `useNotify().addToCartMessage({ productName, productImage, price })` |
| Remove from cart | Undo toast | Timed toast (~5s) with "Undo" action |
| Update quantity | Inline loading | Subtle spinner on line item |
| Add to wishlist | Toast | `$t('layout.toast.added-to-wishlist')` with "View" action |
| Remove from wishlist | Undo toast | Same pattern as cart removal |
| Apply discount code | Inline | Success/error below input, update totals |
| Form validation error | Inline | Error text below field, `destructive` border |
| Payment processing | Button loading | Disable button, spinner, `$t('checkout.processing')` |
| Order placed | Page redirect | Full confirmation page |
| Payment failed | Inline error | Message above payment form, suggest alternatives |
| Out of stock (on add) | Inline error | Below the add-to-cart button |
| Out of stock (in cart) | Inline warning | Grayed item with message, "Remove" action |
| Session timeout | Restore + toast | Restore cart, `$t('layout.toast.welcome-back')` |

## Conversion Optimization Tactics

### Free Shipping Threshold
The single most effective AOV driver. Show it everywhere:
- **Product card**: `$t('product.shipping.free-over')`
- **Cart**: Progress bar showing how close they are
- **Mini-cart/drawer**: Same progress bar
- When reached: celebratory state `$t('cart.shipping.free-earned')`

### Recommendations Placement

| Location | Type | Goal | Data source |
|----------|------|------|-------------|
| PDP below fold | "Complete the look" | Increase items per order | `useFronticListing` |
| Cart page | "You might also like" | Increase AOV | `useFronticListing` |
| Empty cart | "Popular right now" | Recovery | `useFronticListing` |
| Order confirmation | "Based on your purchase" | Repeat purchase | `useFronticListing` |
| Search no-results | "Popular in [category]" | Prevent bounce | `useFronticSearch` |
| 404 page | "You might be looking for..." | Prevent bounce | `useFronticListing` |

### Urgency and Scarcity (Use Honestly)
Only show real data — fabricated urgency destroys trust:
- "Only X left in stock" — when genuinely low (< 5)
- "Sale ends [date]" — when there's a real deadline
- Never fake countdown timers, visitor counts, or "someone just bought this"

### Social Proof
- `<Rating>` + review count on product cards and PDP
- "X people bought this today/week" — only if real
- Customer photos in reviews when available

## Edge Cases to Always Handle

These are commonly missed. Build them in from the start:

| Scenario | Required behavior |
|----------|------------------|
| Cart is empty | Recovery UI with recommendations via `useFronticListing` |
| Last item in stock added | Disable add-to-cart, show `$t('product.stock.last-one')` |
| User clicks "Pay" twice | Disable button on first click, show processing state |
| Navigate back from checkout | Cart state preserved (persisted in composable) |
| Session expires | Cart restored on return, toast confirmation |
| Product discontinued in cart | Clear notice with "Remove" and alternative suggestions |
| Slow connection | Skeleton loading via `ProductCardSkeleton`, optimistic updates, no blank screens |
| Invalid discount code | Clear error, don't clear input (typo recovery) |
| Successful order | Redirect to confirmation page, clear cart state |
| Mobile long checkout form | Sticky CTA bar, progress indicator, `inputmode="numeric"` for card numbers |

## Related Skills

- **frontic-ui-composition** — Which components exist, how to install them, CVA variants and commerce colors, theming. Use it when choosing and customizing UI primitives.
- **nuxt-storefront-architect** — Data fetching with Frontic composables, page routing, content collections, i18n setup, project structure. Use it for implementation details and working code examples for each page type.
