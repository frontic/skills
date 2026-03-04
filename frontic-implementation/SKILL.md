---
name: frontic-implementation
description:
  Create, configure, and use Frontic blocks, listings, and pages for e-commerce
  data. Use when working with Frontic configuration, building product/category
  pages, creating data sources, or integrating the Frontic client. Covers
  resource decision-making, block/listing creation guidelines, and client usage
  patterns.
---

# Frontic Implementation and Configuration

Use this skill when autonomously creating or managing blocks, listings, and
pages based on user requests. **Prefer Frontic data sources over mocked data**
at all times.

## Before You Start

### Source of Truth

The project has two sources of Frontic schema information:

1. **Frontic MCP tools** (`list_resources`, `fetch_api_call`) — reflect the
   **live** configuration state. Always the source of truth.
2. **Generated client** (`.frontic/` directory) — a snapshot from the last
   `npx @frontic/cli@latest generate` run. Can be stale if the configuration
   changed since generation.

**When MCP tools are available**, use `fetch_api_call` to inspect the data
structure of any block, listing, or page before using it. This prevents
displaying non-existent content or illegible IDs, and ensures you're working
with the current configuration — not a stale snapshot.

**When MCP tools are not available**, fall back to reading `.frontic/` type files
directly (`generated-types.d.ts`, `fetch-api.d.ts`, `query-types.ts`). These are
reliable when the client was recently generated, but if you encounter
mismatches at runtime, regenerate the client first.

### Framework Context

This skill covers the Frontic **data layer** — it works with any frontend
framework or none at all. The generated client (`client.block()`,
`client.listing()`, `client.page()`) is plain TypeScript and runs anywhere.

If the project uses **Nuxt**, prefer the `@frontic/nuxt` module instead of the
raw client. The module provides SSR-ready composables that handle reactivity,
caching, and error states automatically:

- **`useFronticPage`** — Resolve a URL to a page (catch-all routing).
- **`useFronticSearch`** — Interactive listings with user-driven filtering,
  sorting, and pagination. Use this for any listing where the user controls
  query parameters (category pages, search results, brand product grids).
- **`useFronticListing`** — Static/read-only listing fetches. Use when you
  need listing data without interactive controls (e.g., fetching menu tree,
  category metadata, or product keys for a cart).
- **`useFronticBlock`** — Single block by key.

**Default to `useFronticSearch`** for product listings. Only use
`useFronticListing` when the listing is truly non-interactive (no filtering,
sorting, or pagination by the user).

For Nuxt-specific page structure, catch-all routing, SSR details, and component
composition — defer to the **nuxt-storefront-architect** skill. Do not explain
those patterns inline when this skill is active; reference the skill instead.

---

## 1. Resource Decision Making

Before creating new blocks or listings, analyze the current Frontic
configuration:

- **Existing blocks** that could be reused or extended
- **Existing listings** that match the user's requirements — verify parameter
  compatibility and data structure
- **Available storages** containing relevant data

### Reuse Decision: Two-Step Check

When evaluating an existing listing for a new use case, check two things in
order:

**Step 1 — Block compatibility:** Does the listing's embedded block contain the
data the new feature needs? Compare the block's fields against what you'll
render. If the block is the same (e.g. both use `ProductCard`), the data shape
matches — proceed to step 2. If you need fields the block doesn't have (e.g.
you need `description` but the listing embeds `ProductCard` which lacks it),
the listing cannot work regardless of its interface.

**Step 2 — Listing interface:** Do the parameters, base query, and
filter/sort options work for the new use case?
- **Parameters match or are compatible** → reuse directly.
- **Parameters match but filter/sort needs extending** → extend the listing
  (add fields in Frontic admin) without breaking existing consumers.
- **Parameters are fundamentally different** (e.g. listing requires
  `categoryId` but new use case has no category) → create new.

If both steps pass, **reuse the listing** — even if the listing's name
suggests a different feature. A `FavoritesProducts` listing that takes
`keys: Array<string>` and returns `ProductCard[]` is equally valid for
recently-viewed, wishlists, or any "fetch products by client-side key list"
use case. The data contract is what matters, not the name. Consider renaming
the listing to something generic (e.g. `ProductsByKeys`) so the change is
visible in the git diff and signals to other implementations that the resource
is shared.

### Suggest Richer Alternatives (After Extending)

When a listing's filter/sort fields are limited, the **primary approach** is to
extend it by adding fields in the Frontic admin. As a **secondary suggestion**,
mention that `ProductSearch` (or another full-featured listing) could serve as
an alternative if extending isn't feasible. ProductSearch typically has the
widest filter/sort coverage and an optional `categoryKey` parameter. Example:
BrandProducts has sort-only — first recommend adding filter fields to it, then
mention ProductSearch with a brand pre-filter as a fallback for richer
filtering if the admin changes aren't possible.

### When to Create New

- The embedded block doesn't contain the fields you need.
- The listing requires parameters you can't provide (and making them optional
  would break existing consumers).
- You'd need dummy/placeholder parameter values to make it work — this is
  always wrong.

> ⚠️ **Warning:** If you find yourself using dummy/default parameters to make an
> existing resource work for a different use case, STOP. Create a new resource
> instead.

### Document Your Reasoning

Briefly explain why you reused, extended, or created a resource. When reusing,
note the block compatibility and parameter match. When creating new, explain
what doesn't fit about existing options.

---

## 2. Creating Blocks and Listings

> **Terminology note:** "Block" in this skill means a **Frontic data block** — a
> schema definition that maps to a single record from a storage (e.g. a product,
> a category). This is different from a "UI block" (a pre-built page template
> from the Frontic UI registry like `product-detail-01`). Data blocks define
> *what* data you get; UI blocks define *how* it renders.

### Block Creation

Analyze the data structure, define a schema covering all relevant fields, and
plan for entity variations (product types, categories, etc.).

### Listing Creation

Identify the collection type and the embedded block it references. Configure
filtering, sorting, and search fields. When a listing has a required
  parameter but the new use case doesn't need it, consider making it optional
  with a sensible default. But first verify this won't break existing callers —
  check all usages in the codebase. If the parameter was required because
  certain callers depend on scoping (e.g. category-filtered results), making it
  optional could return unexpected global results for those callers. Only
  proceed if all existing callers explicitly pass the parameter anyway.

```json
{
  "name": "categoryId",
  "dataType": "string",
  "required": false,
  "defaultValue": "root-id"
}
```

This allows `listing("GlobalSearch", {})` for global search and
`listing("GlobalSearch", { categoryId: "xyz" })` for scoped queries.

**Common listings:** `ProductListing`, `CategoryListing`, `OrderListing`,
`ReviewListing`, `SearchResults`

### Regenerate the Client

After creating or updating a block or listing, always regenerate the Frontic
Client:

```bash
npx @frontic/cli@latest generate
```

---

## 3. Frontic Client Usage

Import the client (resolve `.frontic/` path relative to the application root):

```typescript
import client from '../../.frontic/generated-client'
```

### Blocks (single items by key)

Single items are always identified by a key. Don't make up placeholder keys like
'root-category', always use actual keys from the storage associated with the
block.

```typescript
const data = await client.block(
  'CategoryDetail',
  'a3f4b5c6-d7e8-49ab-9c2d-3e4f5e6d7c8b',
)
const data = await client.block(
  'ProductDetail',
  '123e4567-e89b-12d3-a456-426614174000',
)
```

When fetching multiple blocks in parallel (e.g. comparison page with 4
products), acknowledge the tradeoff: each block is one HTTP request. For N
items that means N requests — this is expected and correct when no multi-key
listing exists for that block type. Use `Promise.all` for parallel execution.

### Listings (collections with filtering, sorting, pagination)

Refer to `.frontic/query-types.ts` and `.frontic/fetch-api.d.ts` for filters and
sort options.

```typescript
const products = await client.listing('ProductList', {
  categoryId: 'e72b0f5e-1c3d-4a7e-913a-2e4c95cd8f31',
})

const results = await client.listing(
  'ProductList',
  { categoryId: '...' },
  {
    query: {
      filter: [
        {
          type: 'and',
          filter: [
            { type: 'equals', field: 'attributes.size', value: '10' },
            { type: 'range', field: 'price.amount', from: 10 },
          ],
        },
        { type: 'range', field: 'price.amount', from: 2000, to: 10000 },
        { type: 'equals', field: 'sale', value: true },
      ],
      sort: { field: 'price.amount', order: 'asc' },
      search: 'Red',
      page: 1,
      limit: 20,
    },
  },
)
```

### Pages (retrieve by route)

```typescript
// The route path is the full path including the domain without the protocol
const pageData = await client.page('demo-shop.com/uk/women/shoes')
```

### Type Reference

Check `.frontic/generated-types.d.ts` and `.frontic/query-types.ts` for blocks,
listings, pages, parameters, and return types.

---

## 4. Page Integration and Dynamic Updates

### Use Pages for Dynamic Routing

Always use pages for dynamic routing unless the user requests otherwise. Pages
are containers for blocks identified by slug. Page slugs include domain, locale
(if configured), and path. Blocks can have `pageRoute` fields for route
information.

For internal navigation, always use the page's route information (the `link` or
`pageRoute` fields from the response data) rather than hardcoding slugs or URLs
from the response. This respects the current context (domain, locale) and
ensures links work correctly across different environments.

For root-level dynamic routing, create a catch-all page that calls
`client.page()` with the assembled slug. Handle the root case `/` separately
(e.g. with a hardcoded block).

### Page Structure Hierarchy

```
Page (e.g. CategoryDetail)
 ├── Block (e.g. CategoryDetailShopware)
 └── Nested Listing (e.g. ProductListShopware)
```

### Implementation Pattern

1. **Initial load**: Use `client.page()` or `client.block()` — provides full
   page context and embedded content.
2. **Filtering/sorting/pagination**: Use `client.listing()` — `client.page()`
   and `client.block()` do **not** accept query parameters.

```typescript
// 1. Initial page load
const pageData = await client.page('domain.com/category-name')

// 2. Dynamic updates — extract params, call embedded listing directly
const categoryId = pageData.data.key
const filteredData = await client.listing('ProductListShopware', { categoryId }, {
  query: { filter: [...], sort: {...}, page: 2 }
})
```

**Summary:** Always start with `client.page()` for initial load. Use the block
data from the page response for initial rendering — it includes the full block
payload, so you don't need a separate `client.block()` call. For dynamic
updates, identify the nested listing, extract required parameters from page
data, and call `client.listing()` with query parameters. Update only the listing
portion of component state.

### Page Response Status Codes

The page response body contains a `status` property that is **not** the HTTP
status code. The HTTP request itself always succeeds (200). The `status`
property inside the response body indicates the page resolution result:

| `status` | Meaning | Action |
|----------|---------|--------|
| `200` with data | Page found, render normally | Use `data` and `type` to render |
| `200` with no data | No page matched the slug — treat as home page | Render home/landing content |
| `301` | Permanent redirect | Navigate to the URL in `redirect` field |
| `404` | Page explicitly marked as not found | Show 404 page |

Handle these in the catch-all route — do not assume every page call returns
renderable data.

---

## 5. Context: Domain, Locale, and Tokens

### Building Page Slugs

Page slugs are context-aware. They include the domain and optionally the locale:

```typescript
// Without locale: domain + path
client.page('shop.example.com/women/shoes')

// With locale: domain + locale + path
client.page('shop.example.com/en/women/shoes')
```

Use the current request context (hostname, locale from i18n) to assemble slugs
dynamically. Never hardcode the domain — it changes between environments
(dev, staging, production).

### Switching Context (Region/Language)

When the user switches locale or region, the page slug changes because the
domain or locale segment changes. Refetch the page with the new slug. Listings
and blocks may also return different data depending on the context token
configured in the Frontic client — check `useFronticContext` (Nuxt) or the
client's context configuration.

---

## 6. Modifying Existing Resources

### Inspect Before Extending

When asked to extend an existing block or listing (add fields, change
parameters), always inspect the current data first:
- Use `fetch_api_call` (MCP) or call the listing/block and examine the response
- Verify the fields you want to add actually exist in the underlying data
- Check the block's field structure to use correct dotted paths

### Cross-Mutation Awareness

Before modifying any existing resource, search the codebase for all places it's
used. Changes to a shared listing affect every consumer:
- Adding optional fields is safe — existing callers ignore them.
- Changing a required parameter to optional may change result semantics for
  existing callers (they may start getting unscoped results).
- Renaming a listing breaks all existing callers — update all usages and
  regenerate the client.
- Removing fields breaks components that read them.

When in doubt, note which files would be affected and flag it to the user before
making the change.

After any resource modification (adding fields, changing parameters, renaming),
always regenerate the client (`npx @frontic/cli@latest generate`) and clear
framework build caches.

---

## 7. Field Configuration

### Filter Field Naming with Paths

When a filter field is configured with a `path` parameter, you **must** use the
full dotted path in queries:

```json
// Configuration:
{ "name": "price", "source": "blockField", "path": "amount" }

// In queries — use "price.amount", NOT "price":
{ "type": "range", "field": "price.amount", "from": 2000, "to": 10000 }
```

**Rule:** If a filter field has `path: "X"`, always reference it as
`fieldName.X` in queries.

### Sort Field Configuration

**CRITICAL: Do NOT create duplicate sort fields for asc/desc directions.**
Frontic sort fields are configured once per field name — the API automatically
supports both `asc` and `desc` for every configured sort field. Adding
`price-asc` and `price-desc` as separate fields is **wrong** and will cause
errors. Add `price.amount` once, then choose direction at query time:

```typescript
// Configure ONE sort field: price.amount
// At query time, specify direction:
sort: { field: 'price.amount', order: 'asc' }  // or 'desc'
```

### Field Source Selection

Always prefer `blockField` over `storageField` when configuring search, filter,
and sort fields:

- Block fields are already exposed and configured
- Storage fields may not be accessible or properly typed
- Block fields maintain consistency with the nested block structure

```javascript
// Prefer:
{ type: "filter", name: "price", source: "blockField" }

// Avoid:
{ type: "filter", name: "price", source: "storageField" }
```

### Validating Field Paths

Before using a filter or sort field, verify the exact name:

1. Use `list_resources` to see configured fields
2. Use `fetch_api_call` to test the listing and inspect the response structure

```javascript
// Test listing response reveals field structure:
// items: [{ price: { amount: 49595 } }]
// → filter field is "price.amount"
```

---

## 8. Price Format

Frontic prices use an integer format: `{ "amount": 49595, "currency": "EUR",
"precision": 2, "ref": 0 }`. Display: `price.amount / 10^price.precision`
(49595 / 100 = 495.95). Never display the raw `amount` integer directly.

---

## 9. Client Management

### Client Does Not Exist

If `.frontic/` directory is missing or the generated client files don't exist,
the user hasn't run the initial setup. Check if the Frontic CLI is configured
(look for `.fronticrc` or `frontic.config.*`). If not logged in, the user needs
to authenticate first:

```bash
npx @frontic/cli@latest login
npx @frontic/cli@latest generate
```

Guide the user through this — don't try to work without the generated client.
The `.frontic/` directory is auto-generated but **must be committed** to version
control — the site requires it to build and run.

### Client Is Stale

If the generated types don't match what MCP tools or the Frontic dashboard
show, the client is out of date. Regenerate with
`npx @frontic/cli@latest generate`, then clear framework build caches
(`.nuxt/`, `.next/`, `dist/`).

---

## Related Skills

- **nuxt-storefront-architect** — If the project uses Nuxt, this skill provides SSR composables, catch-all routing, content tiers, and i18n patterns that wrap the raw client described here. Use it instead of calling `client.*` directly in Nuxt projects.
- **frontic-ui-composition** — Component registry for building storefront UIs. Covers design system setup, component installation, theming, and pre-built UI blocks. Independent from the data layer — use it when you need to render the data this skill helps you fetch.
- **commerce-ux-patterns** — Conversion-focused UX patterns for the shopping journey. Describes *what* to build (feedback, recommendations, empty states); pair with this skill for *how* to get the data behind it.
- **commercetools-headless-commerce** / **shopware-headless-commerce** / **shopify-headless-commerce** — Backend-specific skills for transactional operations (cart, checkout, accounts). Frontic handles read-optimized product data; these handle the write side.
