# Frontic Mapping Rules

Maps store observations to Frontic resources. Use these rules during the
"Data Architecture Mapping" phase after crawling.

## Table of Contents

1. [Storage Identification](#storage-identification)
2. [Block Field Templates](#block-field-templates)
3. [Listing Configuration Rules](#listing-configuration-rules)
4. [URL Pattern → Page Type](#url-pattern--page-type)
5. [Filter & Sort Field Rules](#filter--sort-field-rules)
6. [Multi-Language Mapping](#multi-language-mapping)
7. [Feature → Resource Decision Tree](#feature--resource-decision-tree)

---

## Storage Identification

Identify required storages from observations. Every storage must be justified
by something observed in the store.

| Observation | Storage | Confidence |
|-------------|---------|------------|
| Product grid, product detail page | `products` | Always required |
| Category navigation, breadcrumbs with hierarchy | `categories` | Required if >1 level hierarchy |
| Brand pages, brand filter, brand logo on products | `brands` | Required if brand pages exist |
| Review section on PDP, review count on cards | `reviews` | Only if reviews are a standalone section |
| Blog posts, editorial content | — (use @nuxt/content) | Not a Frontic storage |
| Static pages (About, FAQ, Terms) | — (use @nuxt/content) | Not a Frontic storage |

**Decision rule:** If a data entity is displayed across multiple pages (product
appears on category page AND PDP), it needs a storage. If it appears on only
one page (e.g., FAQ text), it's likely content, not a storage.

---

## Block Field Templates

### ProductCard (grid/listing display)

Always create this block. Map observed fields:

| Observed element | Field name | Type | Required |
|-----------------|-----------|------|----------|
| Product title in grid | `name` | string | Yes |
| URL to product page | `slug` | string | Yes |
| Price on card | `price` | `{ amount: number, precision: number, currency: string }` | Yes |
| Product thumbnail | `images` | `Array<{ url: string, alt: string }>` | Yes |
| "New" / "Sale" / "Bestseller" label | `badge` | string \| null | If badges visible |
| Star rating on card | `rating` | number \| null | If ratings on grid |
| Review count on card | `reviewCount` | number \| null | If count on grid |
| Brand name on card | `brand` | `{ name: string, key: string }` \| null | If brand shown |
| Color swatches on card | `swatches` | `Array<{ color: string, label: string }>` \| null | If inline swatches |
| Compare price / strikethrough | `comparePrice` | `{ amount, precision, currency }` \| null | If sale prices shown |

### ProductFull (PDP)

Always create this block. Extends ProductCard with:

| Observed element | Field name | Type | Required |
|-----------------|-----------|------|----------|
| Full description | `description` | string | Yes |
| Image gallery (multiple) | `images` | `Array<{ url, alt }>` | Yes |
| Color/size/material selectors | `variants` | `Array<{ id, sku, options, price, available }>` | If variants exist |
| Breadcrumb categories | `categories` | `Array<{ name, key }>` | If breadcrumbs shown |
| Product attributes / specs | `attributes` | `Record<string, string>` | If specs table exists |
| Brand with link | `brand` | `{ name, key, link }` \| null | If brand clickable |
| SKU / article number | `sku` | string \| null | If displayed |
| Availability text | `availability` | string \| null | If stock status shown |

### CategoryFull

Create if category pages exist with descriptive content.

| Observed element | Field name | Type |
|-----------------|-----------|------|
| Category heading | `name` | string |
| Category URL | `slug` | string |
| Category description / intro | `description` | string \| null |
| Category hero image | `image` | `{ url, alt }` \| null |
| Parent category (from breadcrumbs) | `parentKey` | string \| null |
| Subcategory count | `childCount` | number \| null |

### CategoryCard

Create if category grid/tiles appear (e.g., homepage featured categories).

| Observed element | Field name | Type |
|-----------------|-----------|------|
| Category name | `name` | string |
| Category URL | `slug` | string |
| Category image/thumbnail | `image` | `{ url, alt }` |

### BrandFull

Create only if dedicated brand pages exist.

| Observed element | Field name | Type |
|-----------------|-----------|------|
| Brand name | `name` | string |
| Brand URL | `slug` | string |
| Brand logo | `logo` | `{ url, alt }` \| null |
| Brand description | `description` | string \| null |

### BrandCard

Create if brand listing/grid appears.

| Observed element | Field name | Type |
|-----------------|-----------|------|
| Brand name | `name` | string |
| Brand URL | `slug` | string |
| Brand logo | `logo` | `{ url, alt }` |

### MenuTree

Always create — every store has navigation.

| Observed element | Field name | Type |
|-----------------|-----------|------|
| Menu item text | `label` | string |
| Link target | `link` | string |
| Submenu items | `children` | `Array<MenuTree>` |

**Depth rule:** Count the deepest nesting level in the mega menu. If 3+ levels,
note this as high complexity in the migration plan.

---

## Listing Configuration Rules

### When to Create Each Listing

| Listing | Create when... | Required params | Embedded block |
|---------|---------------|-----------------|----------------|
| ProductSearch | Store has product grid with filters or sort | — (optional `categoryKey`) | ProductCard |
| CategoryProducts | Category pages show products without general filters | `key: string` | ProductCard |
| BrandProducts | Brand pages exist with product grids | `brandKey: string` | ProductCard |
| MenuTreeListing | Navigation exists (always) | — | MenuTree |
| CategoryListing | Category index/overview page exists | — | CategoryCard |
| BrandListing | Brand index page exists | — | BrandCard |
| FavoritesProducts | Wishlist feature detected | `keys: Array<string>` | ProductCard |

**ProductSearch vs. CategoryProducts:** If the category page has its own filter
sidebar, use ProductSearch with optional `categoryKey`. If the category page
just shows products without filtering, use CategoryProducts with required `key`.

### Listing Parameter Rules

- Parameters that identify **which subset** of data: always required (e.g., `key`, `brandKey`)
- Parameters that accept **arrays of IDs**: typed as `Array<string>` (e.g., `keys` for favorites)
- The main search listing (ProductSearch): no required params, use optional `categoryKey` for scoping

---

## Filter & Sort Field Rules

### Mapping Observed Filters to Frontic Filter Fields

For each filter in the store's sidebar:

| Observed filter UI | Filter field name | Field type | Path | Query type |
|-------------------|------------------|------------|------|------------|
| Price range slider | `price` | blockField | `amount` | `range` |
| Color swatches / checkboxes | `attributes.color` | blockField | — | `equals` |
| Size selector | `attributes.size` | blockField | — | `equals` |
| Brand checkboxes | `brand` | blockField | `name` or `key` | `equals` |
| Material / fabric | `attributes.material` | blockField | — | `equals` |
| Rating stars | `rating` | blockField | — | `range` |
| Availability toggle | `availability` | blockField | — | `equals` |

**Path rule:** If the source field is nested (like `price.amount`), specify `path`.
Query usage becomes `field: "price.amount"`. If the field is flat, no path needed.

**Field source:** Always prefer `blockField` over `storageField`. Block fields are
already exposed and typed.

### Mapping Observed Sort Options

| Observed sort option | Sort field | Notes |
|---------------------|-----------|-------|
| "Price: Low to High" / "Price: High to Low" | `price.amount` | One field, direction at query time |
| "Newest" / "Latest" | `createdAt` or `publishedAt` | Check which field the store uses |
| "Name A-Z" | `name` | |
| "Best rating" | `rating` | |
| "Bestseller" / "Popularity" | `popularity` or `salesCount` | May need custom storage field |

**Critical:** Do NOT create separate sort fields for asc and desc (e.g., `price-asc`
and `price-desc`). Create ONE field; direction is chosen at query time.

---

## URL Pattern → Page Type

### Common URL Patterns

| URL pattern | Frontic page type | Route handling |
|-------------|-------------------|----------------|
| `/{locale}/{category}/{subcategory}` | CategoryPage | `useFronticPage` catch-all |
| `/{locale}/product/{slug}` or `/p/{slug}` | ProductPage | `useFronticPage` catch-all |
| `/{locale}/brand/{slug}` or `/brands/{slug}` | BrandPage | `useFronticPage` catch-all |
| `/search?q=...` | SearchPage | Dedicated route (not Frontic page) |
| `/cart` | CartPage | Dedicated route |
| `/checkout/*` | Checkout | Dedicated route |
| `/account/*` | Account | Dedicated route |
| `/blog/*` or `/magazine/*` | Content | `@nuxt/content` collection |
| `/about`, `/faq`, `/terms` | Content | `@nuxt/content` |

**Rule:** Only product, category, and brand pages resolve through `useFronticPage`.
Search, cart, checkout, account, and content have dedicated routes or use the
content system.

### Locale Detection

| Observation | Pattern | Config impact |
|-------------|---------|---------------|
| URL has `/en/`, `/de/`, `/fr/` prefix | Locale prefix routing | Set `contextDomain` per locale in config |
| Subdomain: `en.store.com`, `de.store.com` | Subdomain routing | Multiple `contextDomain` values |
| Query param: `?lang=en` | Query-based (unusual) | Custom middleware needed |
| No locale in URL, single language | Monolingual | Single `contextDomain` |

---

## Multi-Language Mapping

When multiple languages detected:

1. **Count languages** — from locale switcher or URL variants
2. **Note default language** — the language shown without locale prefix, or the first in the switcher
3. **Identify translated content** — product names, category names, navigation, UI strings
4. **Config impact:**
   - Each locale may need its own `contextDomain` or domain configuration
   - i18n routing uses URL prefix pattern (most common)
   - Content translations use locale-scoped collections in `@nuxt/content`

---

## Feature → Resource Decision Tree

For features that don't map directly to blocks/listings:

```
Feature: Customer Reviews
├── Reviews displayed on PDP?
│   ├── Yes, as a section/tab → Add `rating` + `reviewCount` fields to ProductFull
│   │   ├── Separate review listing below? → Create ReviewListing (param: productKey)
│   │   └── Just stars + count? → Fields on ProductFull are sufficient
│   └── No → Skip reviews
├── Reviews on product cards?
│   └── Yes → Add `rating` + `reviewCount` to ProductCard
└── Review storage needed?
    └── Only if reviews have their own listing/page (e.g., "All Reviews" page)

Feature: Wishlist
├── Heart icon on product cards? → Note for UI, no Frontic resource
├── Wishlist page exists? → Create FavoritesProducts listing (param: keys[])
└── Wishlist uses accounts? → Commerce backend handles persistence

Feature: Search
├── Search bar visible? → Note the feature
├── Autocomplete/suggestions? → Note for UI implementation
└── Search results page? → Uses ProductSearch listing (no extra resource)

Feature: Newsletter
└── Signup form? → Note for UI, handled by external service or backend

Feature: Blog/Magazine
└── Blog section? → @nuxt/content collection, NOT a Frontic storage
```
