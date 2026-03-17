---
name: store-discovery
description: >
  Crawl and analyze any existing online store to produce a Frontic migration plan — storages,
  blocks, listings, pages, features inventory, and design system extraction (colors, typography,
  Frontic UI style preset). Uses browser MCP tools to systematically inspect live stores. ALWAYS
  use this skill when the user shares a store URL or screenshots and wants to understand, analyze,
  migrate, rebuild, or scope it for Frontic. Also use when a user describes an existing store's
  features and asks what Frontic resources are needed, or when onboarding a new client with an
  existing storefront. Trigger even without explicit mention of "store discovery" — any request
  to understand an existing shop's structure, features, or design for a Frontic build qualifies.
  Triggers: analyze this store, migrate to Frontic, rebuild this, check out their site, store
  audit, scope the project, feature inventory, competitor analysis, like this but better, crawl
  this URL, design extraction, or a store URL with a question about architecture.
---

# Store Discovery

Systematically analyze an existing online store and produce a Frontic migration
plan. The output covers three areas: what data architecture is needed (storages,
blocks, listings, pages), what features exist, and what the design system looks
like — everything a team needs to start building the new storefront.

## When This Skill Applies

- User pastes a store URL and asks for analysis or migration planning
- User wants to onboard an existing store to Frontic
- User asks "what would it take to rebuild this?"
- User wants to understand a competitor's store structure
- User provides screenshots of a store and asks for feature/design analysis

## Workflow

Follow these six steps in order. Do not skip steps or reorder them.

### Step 1: Receive Input

Accept the store URL from the user. If they provide screenshots instead of a
URL, skip the crawling phases and go straight to analysis using the images.

Before starting, confirm:
- Is the URL accessible (not behind auth or geo-block)?
- Does the user want full analysis or just specific aspects?

### Step 2: Reconnaissance (Homepage)

Read `references/crawl-playbook.md` — Phase 1.

Three browser calls on the homepage:
1. **Screenshot** — visual overview of layout, branding, design
2. **Links** — discover the full site structure (categories, brands, content)
3. **Extract** — navigation HTML, platform meta, locale info, search presence

From this phase, determine:
- Platform (Shopify, Shopware, WooCommerce, custom)
- Languages/locales available
- Navigation depth and structure
- Which supplementary pages exist (brands, blog, search)
- Pick a category URL and product URL for the next phases

### Step 3: Systematic Crawl

Read `references/crawl-playbook.md` — Phases 2-4.

**Category page** (3 calls):
- Screenshot → grid layout, filter sidebar, card design
- Extract → product card fields, filter groups, sort options, pagination
- Extract → detailed card elements (price format, badges, swatches, ratings)

**Product detail page** (3 calls):
- Screenshot (full page) → gallery, variants, tabs, cross-sells, reviews
- Extract above fold → title, price, variants, gallery, add-to-cart, breadcrumbs
- Extract below fold → tabs, description, reviews, related products, specs

**Supplementary pages** (3-4 calls, conditional):
- Brand page → only if brand links found in Phase 2
- Search results → only if search bar found
- Locale variant → only if multi-language detected
- Cart page → only if cart link found
- Mobile viewport → if design analysis is the primary goal

**Budget:** 12-16 total browser calls. Do not exceed this. Every call must
have a clear purpose tied to a specific analysis need.

### Step 4: Data Architecture Mapping

Read `references/frontic-mapping-rules.md`.

Map every observation from Step 2-3 to Frontic resources:

**Storages** — identify which backend data sources are needed. Common set:
products (always), categories (if hierarchical nav), brands (if brand pages).
See the storage identification table in the reference.

**Blocks** — for each storage, define which blocks are needed and what fields
they carry. Use the block field templates in the reference as starting points,
then add/remove fields based on what the store actually shows.

Rules:
- Always create both a Card block (for grids) and a Full block (for detail pages)
- Field names use camelCase
- Price fields always use `{ amount: number, precision: number, currency: string }` format
- Variant fields use `Array<{ id, sku, options, price, available }>`
- Image fields use `Array<{ url: string, alt: string }>`
- Only include fields for data you observed — do not speculatively add fields

**Listings** — define which collection queries are needed. Key decision:

```
Does the category page have its own filter sidebar?
├── Yes → Use ProductSearch with optional categoryKey parameter
└── No  → Use CategoryProducts with required key parameter
```

For each listing, specify: embedded block, required parameters, filter fields
(with type and path), and sort fields.

**Pages** — map observed URL patterns to Frontic page types. Only product,
category, and brand pages use `useFronticPage` catch-all routing. Search,
cart, checkout, and content pages have dedicated routes.

### Step 5: Design System Extraction

Read `references/crawl-playbook.md` — Design Token Extraction section.

From screenshots and extracted content, systematically identify:

**Colors:**
- Primary/brand color → `--theme-color`
- Buy/CTA button color → `--commerce-buy`
- Background and text colors → `--background`, `--foreground`
- Sale/discount color → `--commerce-discount`
- New/promo colors → `--commerce-new`, `--commerce-promo`

**Typography:**
- Heading font family and weight
- Body text font family and weight
- Navigation font treatment (case, spacing, weight)
- Price display font (often different from body)

**Spacing & shape:**
- Card border-radius → influences style preset choice
- Button border-radius
- Section spacing
- Grid gaps
- Content max-width

**Style preset matching:**
Match the overall visual impression to the closest Frontic style (vega, nova,
maia, lyra, mira) and commerce palette (default, warm, cool, bold, monochrome,
nature, ocean, sunset, berry). Use the matching tables in the crawl playbook.

Produce a concrete `npx @frontic/ui init` command with all flags.

### Step 6: Produce Migration Document

Read `references/output-template.md` and fill every section.

The output document has five sections:
1. **Store Overview** — business profile, key metrics, platform
2. **Data Architecture** — storages, blocks with fields, listings with params/filters/sorts, page types, config recommendations
3. **Features Inventory** — checklist of all detected features
4. **Design System** — init command, color palette, typography, layout patterns, style rationale
5. **Migration Recommendations** — phased priority order, complexity assessment, evolution opportunities, related skills

Every section must be filled. If a feature was not detected, mark it
"Not detected" — do not omit the row.

The evolution opportunities section is where you add real value: identify
concrete areas where the new storefront can improve on the original. The user
wants "like this but better" — this is the "better" part.

---

## Key Principles

### Budget Your Browser Calls
12-16 calls maximum. The temptation is to visit every page type — resist it.
One category page reveals the grid/filter pattern. One PDP reveals the product
data model. Supplementary pages only when previous phases indicate they exist
and differ structurally.

### Map Observations, Not Assumptions
Only recommend Frontic resources for things you actually observed in the store.
If you didn't see a brand page, don't create BrandFull and BrandProducts. If
the filter sidebar only has price and color, don't speculatively add size and
material filters.

### Distinguish Frontic Resources from Content
Not everything is a Frontic block or listing:
- Blog posts → `@nuxt/content`
- Static pages (About, FAQ) → `@nuxt/content`
- Cart, checkout, accounts → Commerce backend (not Frontic)
- Newsletter signup → External service integration

Frontic handles **read-optimized product/category/brand data**. Write operations
(cart, orders, accounts) belong to the commerce backend skill.

### Design Evolution, Not Replication
The user wants "like this but better." The design analysis captures what exists
so the team understands the starting point. The evolution opportunities section
is where you suggest concrete improvements. Frame these as opportunities, not
criticisms of the existing store.

### One Store, Multiple Skills
This skill produces the **plan**. Other skills handle implementation:
- `frontic-implementation` → Create the blocks, listings, and pages
- `frontic-ui-composition` → Initialize design system and install components
- `nuxt-storefront-architect` → Build the Nuxt storefront structure
- Commerce backend skills → Cart, checkout, account flows
- `commerce-ux-patterns` → Conversion optimization and UX polish

Reference these skills in the Migration Recommendations section so the team
knows what to use next.

---

## Edge Cases

### Cookie Consent Overlays
If the screenshot shows a consent overlay:
- Note it in the analysis
- Try extracting content anyway — some overlays don't block the DOM
- If content is blocked, `browser_links` still works and provides structural data

### SPA / Client-Side Rendered
If `browser_extract` returns minimal HTML:
- Rely on `browser_screenshot` for visual analysis
- `browser_links` may still capture rendered links
- Note "Client-side rendered — limited HTML extraction" in the analysis

### Geo-Blocked or Unavailable
If the URL is inaccessible:
- Ask the user for screenshots
- Do visual-only analysis from provided screenshots
- Note which sections could not be fully analyzed

### Authentication-Required Pages
Skip cart, account, and checkout pages. Note them as "requires authentication"
in the features inventory. If the user provides screenshots of these pages,
include them in the analysis.

### Non-Standard Store Layouts
Lookbook stores, single-page stores, or highly custom layouts:
- Still follow the workflow — extract what you can
- Adjust resource recommendations (a lookbook may not need ProductSearch)
- Note structural differences in the Store Overview
