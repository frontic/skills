# Crawl Playbook

Step-by-step extraction guide using Frontic MCP browser tools. Budget: 12-16
tool calls total. Every call must extract maximum value.

## Table of Contents

1. [Tool Reference](#tool-reference)
2. [Phase 1: Reconnaissance](#phase-1-reconnaissance)
3. [Phase 2: Category Page](#phase-2-category-page)
4. [Phase 3: Product Detail Page](#phase-3-product-detail-page)
5. [Phase 4: Supplementary Pages](#phase-4-supplementary-pages)
6. [Design Token Extraction](#design-token-extraction)
7. [Platform Detection](#platform-detection)
8. [Edge Case Handling](#edge-case-handling)

---

## Tool Reference

Three Frontic MCP browser tools are available:

| Tool | Purpose | Key params |
|------|---------|------------|
| `browser_screenshot` | Visual capture of a page | URL, viewport size, full-page option |
| `browser_extract` | Pull content by CSS selector | URL, up to 10 selectors per call |
| `browser_links` | List all links on a page | URL, grouped as internal/external |

**Budget rule:** Aim for 12-16 total calls. Each call should serve a clear
purpose documented below. If something is optional, only call it when the
previous phase revealed it exists.

---

## Phase 1: Reconnaissance

**Goal:** Understand the store's structure, detect platform, identify languages,
map the navigation tree.

### Call 1: Homepage Screenshot
```
browser_screenshot(url, viewport: 1440x900)
```
Observe:
- Overall layout style (clean/dense/magazine/minimal)
- Navigation structure (horizontal bar, mega menu, sidebar)
- Hero/banner section
- Featured products or categories
- Footer structure
- Color palette and typography (initial impression)

### Call 2: Homepage Links
```
browser_links(url)
```
From the link list, identify:
- **Category/collection URLs** — pick the largest or first main category for Phase 2
- **Brand page URLs** — if `/brands/` or `/brand/` paths exist
- **Product URLs** — pick one for Phase 3 (or get from category page)
- **Content pages** — blog, about, FAQ, terms
- **Account/cart URLs** — note for feature inventory
- **Locale variants** — `/en/`, `/de/`, etc. in link paths
- **External links** — social media, payment providers

### Call 3: Homepage Extract
```
browser_extract(url, selectors: [
  "nav, header nav, [role='navigation']",
  "html[lang], meta[name='language'], [data-locale]",
  "meta[name='generator'], meta[name='platform']",
  "[class*='hero'], [class*='banner'], .slideshow",
  "[class*='locale'], [class*='language'], [class*='country-select']",
  "[type='search'], [role='search'], [class*='search']",
  "footer, [role='contentinfo']",
  "[class*='newsletter'], [class*='subscribe']",
  "[class*='cookie'], [class*='consent']",
  "link[hreflang]"
])
```
Extract:
- Navigation HTML → count levels, count items
- Language/locale indicators → list languages
- Platform meta tags → detect CMS/platform
- Hero content → understand featured content approach
- Locale switcher → confirm multi-language setup
- Search presence → note feature
- Footer → payment methods, trust badges, contact info
- Newsletter → note feature
- Cookie consent → note for edge case handling
- Hreflang tags → confirm locale URL pattern

---

## Phase 2: Category Page

**Goal:** Understand product grid layout, filter/sort capabilities, variant
display, and pagination.

Pick the URL from Phase 1 links: choose the first main category (not a sale
or seasonal category — pick something structural like "Women", "Electronics",
"All Products").

### Call 4: Category Screenshot
```
browser_screenshot(category_url, viewport: 1440x900)
```
Observe:
- Grid layout (columns, card density)
- Filter sidebar (left? top? hidden behind toggle?)
- Sort dropdown
- Product card elements (image, title, price, badge, rating, swatches)
- Pagination or infinite scroll
- Breadcrumb navigation
- Category description or hero

### Call 5: Category Extract — Grid & Filters
```
browser_extract(category_url, selectors: [
  ".product-card, .product-item, [class*='product-grid'] > *, [class*='product-list'] > *",
  ".facets, [class*='filter'], [class*='refine'], .sidebar [class*='filter']",
  "select[class*='sort'], [class*='sort-by'], [class*='sorting']",
  ".pagination, [class*='pagination'], [aria-label='Pagination']",
  "[class*='breadcrumb'], nav[aria-label='Breadcrumb']",
  "[class*='result-count'], [class*='showing'], [class*='product-count']",
  "[class*='active-filter'], [class*='selected-filter'], [class*='applied']",
  "[class*='category-description'], [class*='category-hero']"
])
```
Extract:
- **Product card HTML** → identify fields shown (name, price, image, badge, rating, brand, swatches)
- **Filter sidebar** → list all filter groups (price, color, size, brand, material, etc.)
- **Sort options** → list available sorts (price, name, newest, rating, relevance)
- **Pagination** → type (numbered, load more, infinite scroll) and total pages
- **Breadcrumbs** → category hierarchy depth
- **Result count** → estimate product count
- **Active filters** → understand filter interaction pattern

### Call 6: Category Extract — Product Card Detail
```
browser_extract(category_url, selectors: [
  "[class*='product-card']:first-child, .product-item:first-child",
  "[class*='price'], .money",
  "[class*='badge'], [class*='label'], [class*='tag']",
  "[class*='swatch'], [class*='color-option']",
  "[class*='rating'], [class*='stars'], [class*='review-count']",
  "[class*='wishlist'], [class*='favorite'], [class*='heart']",
  "[class*='compare']",
  "[class*='quick-view'], [class*='quick-add']"
])
```
Extract per product card:
- Price format (single price, sale + compare, "from" price)
- Badge types visible
- Inline variant swatches
- Rating display format
- Wishlist/favorite button presence
- Compare feature presence
- Quick view/quick add presence

---

## Phase 3: Product Detail Page

**Goal:** Understand full product data model, variant system, tabs/sections,
cross-sells, and review display.

Pick a product URL from Phase 2 results or Phase 1 links.

### Call 7: PDP Screenshot
```
browser_screenshot(product_url, viewport: 1440x900, full_page: true)
```
Observe:
- Image gallery layout (single, carousel, grid, zoom)
- Variant selector UI (dropdowns, swatches, buttons)
- Price display (with/without tax, compare price)
- Add-to-cart area layout
- Tab sections below fold
- Related/recommended products section
- Review section layout

### Call 8: PDP Extract — Above Fold
```
browser_extract(product_url, selectors: [
  "[class*='product-title'], h1",
  "[class*='price'], .money, [class*='current-price']",
  "[class*='variant'], .swatch, [class*='option'], [class*='configurator']",
  "[class*='gallery'], [class*='product-image'], [class*='media']",
  "[class*='add-to-cart'], [type='submit'][class*='buy'], button[class*='cart']",
  "[class*='breadcrumb']",
  "[class*='sku'], [class*='article-number']",
  "[class*='availability'], [class*='stock'], [class*='delivery']",
  "[class*='brand'], [class*='manufacturer']",
  "[class*='share'], [class*='social']"
])
```
Extract:
- Product title format
- Price format and structure (amount, currency position, tax note)
- Variant selectors → list variant types (color, size, material, etc.)
- Gallery → count images, zoom support
- Add-to-cart button → text, states
- Breadcrumbs → category path
- SKU display
- Availability/stock information
- Brand display with link

### Call 9: PDP Extract — Below Fold
```
browser_extract(product_url, selectors: [
  "[role='tablist'], [class*='product-tab'], [class*='tab-content']",
  "[class*='description'], [class*='product-description']",
  "[class*='review'], [class*='rating'], [class*='testimonial']",
  "[class*='related'], [class*='recommend'], [class*='also-like'], [class*='cross-sell']",
  "[class*='recently-viewed']",
  "[class*='specification'], [class*='attribute'], [class*='detail-table']",
  "[class*='shipping'], [class*='delivery-info']",
  "[class*='trust'], [class*='guarantee'], [class*='usp']"
])
```
Extract:
- Tab names and content types
- Description format (plain text, HTML, features list)
- Review section → rating format, review count, review content preview
- Cross-sell section → type (related, recommended, also bought)
- Recently viewed → present or not
- Product specs/attributes → table with attribute names
- Shipping info display
- Trust badges/USPs

---

## Phase 4: Supplementary Pages

Only visit pages that Phase 1-3 revealed exist. Budget: 3-4 remaining calls.

### Conditional: Brand Page (if brand links found)
```
browser_screenshot(brand_url, viewport: 1440x900)
```
Observe: Does it have its own product grid, filters, brand description, brand hero?
This determines whether to create BrandFull block and BrandProducts listing.

### Conditional: Search Results (if search bar found)
```
browser_screenshot(search_url + "?q=test", viewport: 1440x900)
```
Observe: Does search have its own filter/sort? Autocomplete? Product grid format?

### Conditional: Locale Variant (if multi-language detected)
```
browser_extract(alternate_locale_url, selectors: [
  "h1, [class*='product-title']",
  "nav, [role='navigation']",
  "[class*='price']"
])
```
Confirm: Are product names translated? Navigation translated? Price/currency changes?

### Conditional: Cart Page (if cart link found)
```
browser_screenshot(cart_url, viewport: 1440x900)
```
Observe: Cart layout, cross-sells in cart, shipping calculator, coupon field.

### Conditional: Mobile Viewport
```
browser_screenshot(homepage_url, viewport: 390x844)
```
Observe: Mobile navigation (hamburger, bottom nav), mobile-specific layout changes.

---

## Design Token Extraction

Run these extractions during Phase 1-3 (combine with existing calls where
possible to stay within budget).

### Colors

From homepage and PDP screenshots, identify:

| Element to observe | Maps to |
|-------------------|---------|
| Primary CTA button (Add to Cart, Buy) | `--commerce-buy` token |
| Navigation background | Surface color |
| Page background | `--background` |
| Body text color | `--foreground` |
| Link/accent color | `--theme-color` (primary) |
| Sale/discount badge | `--commerce-discount` |
| "New" badge | `--commerce-new` |
| Promo banner background | `--commerce-promo` |
| Success messages (added to cart) | `--commerce-positive` |
| Error states | Destructive color |

### Typography

From screenshots and extracted HTML:

| Element | What to note |
|---------|-------------|
| `<h1>` on PDP | Heading font family, weight, approximate size |
| Body text / description | Body font family, weight, line height |
| Navigation items | Nav font family, weight, case (uppercase?) |
| Price display | Price font (often differs — bold, larger) |
| Buttons | Button text case, weight, letter-spacing |

### Spacing & Shape

| Element | What to note |
|---------|-------------|
| Product card | Border-radius, shadow, padding |
| Buttons | Border-radius, padding, height |
| Content sections | Vertical spacing between sections |
| Grid gaps | Space between product cards |
| Page max-width | Content container width |

### Style Preset Matching

Map observations to closest Frontic style:

| Observation | Likely style |
|-------------|-------------|
| Clean, neutral, medium spacing, subtle borders | **Vega** |
| Compact, tight padding, dense grids | **Nova** or **Mira** |
| Soft rounded corners, generous whitespace | **Maia** |
| Sharp corners, boxy, monospace-like feel | **Lyra** |
| Very compact, admin-like density | **Mira** |

### Commerce Palette Matching

| Observation | Likely palette |
|-------------|---------------|
| Warm oranges/reds for CTAs, earth tones | **Warm** |
| Cool blues/purples for CTAs | **Cool** |
| Bold saturated primary colors | **Bold** |
| Black/white/grey, minimal color | **Monochrome** |
| Green tones, natural feel | **Nature** |
| Blue-dominant, ocean/tech feel | **Ocean** |
| Orange/coral/pink warm tones | **Sunset** |
| Deep pink/magenta/berry tones | **Berry** |
| Standard balanced colors | **Default** |

---

## Platform Detection

Quick detection from Phase 1 extraction. Identify but do not change the
analysis approach — the skill is platform-agnostic.

### Detection Signals

| Signal | Platform |
|--------|----------|
| `meta[name="generator"]` = "Shopify" or `cdn.shopify.com` in sources | Shopify |
| `shopware` in class names, `/store-api/` in URLs | Shopware 6 |
| `woocommerce` in classes, `wp-content` paths | WooCommerce |
| `magento` in classes, `/rest/V1/` in URLs | Magento/Adobe Commerce |
| `prestashop` in classes or meta | PrestaShop |
| `bigcommerce` in meta or scripts | BigCommerce |
| No clear signal | Custom / headless / unknown |

Record the platform in the Store Overview section. It helps the customer
understand their current stack, but does not change the Frontic mapping.

---

## Edge Case Handling

### Cookie Consent Overlay
If the homepage screenshot shows a consent overlay blocking content:
1. Note "Cookie consent detected" in the analysis
2. Try `browser_extract` targeting accept button: `[class*='accept'], [class*='agree'], [class*='consent'] button`
3. If content is still blocked, rely more on `browser_links` (works regardless of overlays) and explain to the user

### SPA / Client-Side Rendered Store
If `browser_extract` returns minimal HTML (just a `<div id="app">`):
1. Rely primarily on `browser_screenshot` for visual analysis
2. Use `browser_links` which may still capture rendered links
3. Note "Client-side rendered — extract results limited" in the analysis
4. The visual analysis from screenshots is still sufficient for migration planning

### Geo-Blocked or Access Restricted
If screenshot returns an error or geo-block page:
1. Ask the user if they can provide screenshots instead
2. Accept screenshots and do visual-only analysis
3. Note which sections could not be analyzed

### Authentication Required (Cart, Account)
Skip pages behind authentication. Note them as:
- "Cart page: requires session — analyze from screenshot if user provides one"
- "Account area: not analyzed — note account features from visible UI (login link, account icon)"

### Very Large Catalogs
The skill analyzes **structure**, not catalog completeness. One category page
is enough to understand the grid/filter pattern. Do not attempt to visit
multiple categories unless they appear structurally different (e.g., one
category has filters, another doesn't).

### Non-Standard Layouts
If the store uses an unusual layout (e.g., single-page store, lookbook-style):
1. Still extract what you can with the standard phases
2. Note deviations in the Store Overview
3. Adjust block/listing recommendations accordingly — a lookbook store may
   not need ProductSearch with filters, for example
