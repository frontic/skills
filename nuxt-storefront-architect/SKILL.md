---
name: nuxt-storefront-architect
description: >
  Architecture guide for building Nuxt 4 storefronts with @frontic/nuxt headless commerce,
  @nuxt/content for static content, @nuxtjs/i18n for localization, and Frontic UI registry
  components (built on reka-ui). Covers project bootstrapping with the Frontic CLI (presets, visual
  styles, commerce palettes), page routing via catch-all, data fetching with all 6 composables
  (useFronticPage, useFronticSearch, useFronticListing, useFronticBlock, useFronticContext,
  useFronticClient), four-tier content system, i18n, and installable blocks as starting points.
  Use this skill whenever the user wants to build, extend, or modify a Nuxt storefront — including
  adding pages (product, category, brand, search, content), building navigation, implementing
  filters/sort, setting up i18n, creating content collections, composables, or components. Also use
  when the user asks about storefront architecture decisions, data fetching patterns, or how to
  structure a headless commerce frontend. Trigger on any mention of storefront, e-commerce frontend,
  product pages, category pages, cart, favorites, navigation menus, content tiers, or Frontic
  integration — even if they don't say "storefront architect" explicitly.
---

# Nuxt Storefront Architect

This skill encodes the architecture and best practices for building a production-grade Nuxt 4 storefront. It's distilled from a reference implementation that solves the hard problems: catch-all routing with priority resolution, four-tier content management, full i18n, headless commerce integration, and responsive navigation with mobile drawers.

The patterns here aren't arbitrary — each one exists because it solved a real problem. They're not a plan to execute — every storefront has different requirements. Instead, treat this as a toolbox: when you need to build a product page, here's how it works well. When you need to decide where data lives, here's the decision framework. Pick what applies to the user's requirements and adapt the patterns to fit.

**Starting point:** New projects typically begin from a bare skeleton that provides infrastructure (Nuxt config, Tailwind, i18n setup, content collections, ESLint/Prettier) but no pages, components, composables, or utils. Everything described in this skill is something you **build** when needed, not something that's already there.

## Bootstrapping and the Design System

**The design system comes first.** Before installing any UI components, initialize the design system with `npx @frontic/ui init`. This creates `components.json` and writes commerce color tokens into `tailwind.css`. The CLI reads this config when installing components and applies style transformations at install time — a Button installed with `--style maia` looks fundamentally different from one installed with `--style vega`. Components installed without init (or with wrong settings) get the wrong styles baked in.

**Do NOT skip init and copy CSS manually.** The correct flow is always:

1. **Initialize the design system** — pick the style, palette, font, and base color that best match the target design
2. **Install components** — they arrive pre-styled to match the config
3. **Refine `tailwind.css`** — adjust individual CSS tokens (colors, fonts, radius) for anything the preset doesn't cover exactly

Going the other direction (copy raw CSS first, install components without init) means components get wrong style transformations and you fight against the system instead of building on it.

### New Store

Pick the style/preset/palette that matches the desired visual identity:

```bash
# Using a preset (bundles style + icons + font)
npx @frontic/ui init --preset reka-vega --commerce-palette warm

# Or pick each option
npx @frontic/ui init --style maia --font figtree --icon-library hugeicons --commerce-palette warm

# Or create an entirely new project
npx @frontic/ui create my-store --preset reka-vega --yes
```

Presets: `reka-vega` (clean/Inter), `reka-nova` (compact/Inter), `reka-maia` (soft/Figtree), `reka-lyra` (boxy/JetBrains Mono), `reka-mira` (compact/Inter). See the **frontic-ui-composition** skill for details on styles and palettes.

### Rebuilding from a Reference Project

When rebuilding an existing storefront or migrating to the bare skeleton, do NOT copy `tailwind.css` from the reference and install components on top. Instead:

1. **Analyze the reference project's visual identity** — look at `tailwind.css`, `components.json` (if it exists), font families, border-radius, color palette, spacing patterns
2. **Map to the closest Frontic UI configuration**:
   - Match the visual feel to a style (clean → vega, soft/rounded → maia, compact → nova/mira, sharp/technical → lyra)
   - Match the color temperature to a commerce palette (warm neutrals → warm, cool tones → cool, vibrant → bold, etc.)
   - Identify the fonts (display + body)
   - Identify the base gray (neutral, gray, zinc, stone, slate)
3. **Run `npx @frontic/ui init`** with the matched options
4. **Then refine** — compare the generated `tailwind.css` with the reference and adjust individual tokens (custom brand colors, specific OKLCH values, font declarations, radius) to match exactly

This gives you Frontic UI's full design system as a foundation with surgical refinements on top, instead of a manual CSS copy that the component system doesn't know about.

### Installing Components and Blocks

**Blocks** are pre-built page compositions (product-card-01, category-page-01, cart-01, etc.) that install as regular Vue files. They're useful as starting points — install the ones that match your requirements, then customize. Use the MCP tools `get_blocks` to browse by category, or `get_block_source` to inspect a block's source before installing.

```bash
# Example: install only what you need
npx @frontic/ui add @frontic/product-card-01 @frontic/footer-01
```

Use `npx @frontic/ui info --json` for a machine-readable dump of the project config. **Dark mode** is optional and off by default since 0.9.x.

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Framework | Nuxt 4.3+ | SSR, auto-imports, file-based routing |
| Commerce | @frontic/nuxt | Headless product/category/brand data |
| Content | @nuxt/content v3 | Structured YAML + Markdown collections |
| i18n | @nuxtjs/i18n | Multi-locale with route prefixes |
| UI primitives | Frontic UI registry (`registry.ui.frontic.com`) | Headless components built on reka-ui |
| Styling | Tailwind v4 + tailwind-merge + clsx | Utility-first CSS with class merging |
| Icons | lucide-vue-next | Consistent icon set |
| Images | @nuxt/image | Optimization, WebP/AVIF, lazy loading |
| State | Vue composables + localStorage | No global store needed |
| Validation | Zod | Content collection schemas |

## @frontic/nuxt Module Configuration

Configured in `nuxt.config.ts` under the `frontic` key. Check the project's config to see which options are set — don't assume defaults.

```typescript
frontic: {
  // --- Page routing ---
  contextDomain: 'demo-shop.com',     // Domain for slug construction in useFronticPage()
  redirectOn301: true,                 // Auto-redirect when Frontic returns 301 (default: true)
  throwOn404: true,                    // Auto-throw 404 error on missing pages (default: true)
                                       // Set to false to handle 404s yourself (custom not-found UI)

  // --- Component registry ---
  prefix: '',                          // Prefix for auto-imported ui/ components (e.g., 'Ui' → <UiButton />)
  componentDir: '@/components/ui',     // Where registry components live

  // --- Composables ---
  composables: true,                   // true = all, false = none, or pick specific:
                                       // ['block', 'listing', 'search', 'page', 'context', 'client']

  // --- API proxy (prevents CORS issues) ---
  proxy: true,                         // true = proxy at /api/stack, string = custom path, false = off

  // --- Context (locale/region) ---
  contextCookieName: 'fs-context',     // Cookie name for persisting context token
  contextCookieMaxAge: 31536000,       // Cookie max age in seconds (default: 1 year)
  disableContext: false,               // true = no auto-fetch, no cookie — manage context manually

  // --- Authentication ---
  fetchApiSecret: undefined,           // API secret for protected environments (dev/staging)
                                       // Server-only — never exposed to browser. Client requests
                                       // get the secret injected automatically via the proxy.
}
```

## Project Structure

A full-featured storefront might look like this. Your project will only have the parts that match its requirements — a content-focused site won't need `cart/` or `checkout/`, a catalog without brands won't need `brand/`.

```
app/
├── pages/
│   ├── [...slug].vue            # Catch-all for Frontic + content pages (most storefronts need this)
│   ├── search.vue               # If the store has search
│   ├── brands.vue               # If the store has brand listing
│   └── faq.vue                  # If there's a FAQ content collection
├── components/
│   ├── ui/                      # Registry components — created by `npx @frontic/ui add`
│   ├── layout/                  # Header, navbar, footer, drawer — install blocks or build custom
│   ├── product/                 # Product detail, cards, skeleton — if selling products
│   ├── category/                # Category listing, content banner — if browsing by category
│   ├── brand/                   # Brand detail, cards — if featuring brands
│   ├── home/                    # Homepage composition — if there's a landing page
│   ├── cart/                    # Cart items, empty state — if there's a cart
│   └── search/                  # Refine sheet, filters — if there's search
├── composables/                 # Create as features require (useCart, useFavorites, etc.)
├── lib/utils.ts                 # cn() — created automatically with first ui component install
├── utils/                       # formatPrice(), formatLabel() etc. — create as needed
├── types/index.d.ts             # Custom types — add as you build
├── layouts/default.vue          # Header + slot + footer + drawer
├── assets/css/tailwind.css      # Theme with OKLch color tokens
└── app.vue                      # NuxtLayout + NuxtPage (+ Toaster if using toasts)
content/
├── en/                          # English content (YAML + Markdown)
└── de/                          # German content (parallel structure)
i18n/locales/
├── en.json                      # UI strings — add keys as you add visible text
└── de.json
content.config.ts                # Zod-validated collection definitions
```

### What the Bare Skeleton Provides

The skeleton gives you infrastructure, not features: `app.vue`, `layouts/default.vue`, `assets/css/tailwind.css`, `content.config.ts` with navigation/faq/pages collections, content files (en + de), empty locale files, ESLint/Prettier config, and all dependencies. Pages, components, composables, utils, and types directories exist but are empty.

### Dependencies Between Pieces

Some things depend on others being in place first:
- **UI components** need `components.json` → run `npx @frontic/ui init` before `add`
- **The catch-all page** needs page-level components to render → build or install the components it references
- **Composables like `useNotify`** need `vue-sonner` → already in the skeleton's dependencies
- **i18n keys** should be added alongside the template that uses them — ESLint enforces `$t()` for all visible text

## Core Architecture: Routing

### How URL Resolution Works

URLs resolve through multiple layers, in priority order:

1. **Nuxt page files** — Explicit routes like `search.vue`, `brands.vue`, `cart.vue` are matched first by Nuxt's file-based router. This is automatic — no catch-all involvement.

2. **`[...slug].vue` catch-all** — Everything else flows through the catch-all, which resolves in this order:

   a. **Content page** — Check `@nuxt/content` collections for a matching slug. Content takes priority because it's locally defined and fast to resolve.

   b. **Frontic page** — If no content match, `useFronticPage()` resolves the URL against the commerce backend. The response includes an HTTP-like status code that determines what happens next.

   c. **Home** — If Frontic returns a 200 with no specific page type (an `EmptyPage`), this is the root URL — render the homepage.

   d. **Error** — If nothing matches, show an error page.

### Frontic Page Resolution and Status Codes

`useFronticPage()` returns `{ data, type, status, route }`. The `route` object contains a `RouteMeta` with an HTTP-like status code. This is not sent as an actual HTTP response — it's metadata that tells the page how to handle the result:

```typescript
// RouteMeta shape from Frontic
{
  code: 200 | 301 | 404,
  redirect?: PageRoute,  // Where to redirect (for 301)
  context?: { region, locale, suggested? },  // Context mismatch info
  alternates?: AlternateRoute[]  // i18n alternate URLs
}
```

**What the catch-all page handles vs. what the module handles:**

The `@frontic/nuxt` module automatically handles 301 redirects and 404 errors — you don't write this logic yourself. The module watches the `route.code` from `useFronticPage()` and acts on it:

- **`301`** — Module calls `navigateTo()` automatically (controlled by `redirectOn301`, default: `true`)
- **`404`** — Module calls `createError({ statusCode: 404 })` automatically (controlled by `throwOn404`, default: `true`)

The catch-all page only needs to handle the rendering cases:

- **`200` with `type`** (`Product`, `Brand`, `Category`) — Render the matching component with `data`
- **`200` without `type`** (`EmptyPage`) — This is the homepage

Both `redirectOn301` and `throwOn404` can be overridden per-call:

```typescript
// Override for a specific page — e.g., handle 404 yourself instead of auto-throwing
const { data, type, route } = await useFronticPage(slug, { throwOn404: false })
```

Priority: per-call option > `nuxt.config.ts` > default (`true`).

### The Page Type Union

Frontic's `Page` type is a discriminated union:

```typescript
type Page = EmptyPage | BrandPage | CategoryPage | ProductPage

// EmptyPage has only route (no type, no data) — used for homepage and error states
// BrandPage/CategoryPage/ProductPage have route + type + data
```

Use `type` to discriminate which component to render:

```vue
<template>
  <!-- Content page takes priority -->
  <ContentPage v-if="isContentPage" :page="contentPage!" />

  <!-- Frontic commerce pages -->
  <Product v-else-if="type === 'Product'" :product="data" />
  <Brand v-else-if="type === 'Brand'" :brand="data" />
  <Category v-else-if="type === 'Category'" :category="data" />

  <!-- Homepage (EmptyPage with 200) -->
  <Home v-else-if="isHome" />

  <!-- Error fallback -->
  <ErrorState v-else />
</template>
```

### When to Add a New Page File

The catch-all handles most URLs. Only add a new page file (`app/pages/foo.vue`) when:
- The page has unique data fetching that doesn't come from Frontic or content (e.g., `search.vue` uses `useFronticSearch`)
- The page needs a custom i18n route path (e.g., `brands.vue` maps to `/de/marken`)
- The page has fundamentally different UX from standard content or commerce rendering

## Four-Tier Content System

Content lives in four tiers, each with a clear purpose. Never mix tiers — if you're putting UI labels in YAML or product data in Markdown, you're doing it wrong.

| Tier | Source | What goes here | Example |
|------|--------|---------------|---------|
| **Dynamic** | Frontic API | Products, categories, brands, menu tree | `useFronticListing('MenuTree', {})` |
| **Structured** | `content/{locale}/*.yml` | Page-specific data with defined shapes | `home.yml`, `navigation.yml`, `faq.yml` |
| **Simple** | `content/{locale}/*.md` | Long-form content pages | `about.md`, `privacy.md`, `shipping.md` |
| **Interface** | `i18n/locales/*.json` | UI labels, buttons, error messages | `cart.title`, `product.buy.add-to-cart` |

### Content-First Build Order

When building content-rich pages (home, campaigns, about, landing pages), create the YAML content file and Zod schema **first**, then build the Vue component that queries it. Do NOT write the component with inline data and plan to migrate later — "later" never comes. The YAML file forces you to define the data shape before writing markup; the component then consumes it via `queryCollection`.

Build order for a content-rich page:
1. Define the content shape in `content/{locale}/page.yml` (both locales)
2. Add the Zod schema and collection to `content.config.ts`
3. Build the Vue component that queries the collection and renders from the result
4. Add only short UI labels (button text, section chrome) to i18n

### Common Anti-Patterns — Where Content Does NOT Belong

**Do NOT hardcode content data in Vue components.** Image URLs, product links, promotional copy, editorial quotes, and page-specific data must never be inline constants in `<script setup>`. They belong in `content/{locale}/*.yml` and are queried with `useAsyncData` + `queryCollection`. This includes images — hero banners, promo visuals, featured product images, and category grid images belong in structured YAML content alongside the text they accompany.

**Do NOT put editorial/page content in i18n files.** The i18n tier is strictly for UI chrome: button labels, form placeholders, error messages, navigation labels — short strings that appear across many pages and are reused. Hero headlines, promotional descriptions, brand philosophy text, editorial quotes, feature descriptions, campaign copy, and value propositions belong in **Structured content** (YAML). If a string only appears on one page and describes content rather than UI, it's not an interface string — even if it's short.

**`$t()` is a template constraint, not a content placement rule.** ESLint requires `$t()` for all visible text in templates — but this does not mean every string belongs in i18n. Content queried from YAML is rendered directly from the query result (e.g., `{{ homeContent.hero.title }}`), which already satisfies ESLint because it's a reactive expression, not raw text. Only wrap strings in `$t()` when they're genuine UI labels from i18n locale files.

**Decision rule:** If the content is editable by a non-developer (marketing copy, images, CTAs, headlines, descriptions), it must be in the content tier (YAML). If it's a short UI label reused across pages (button text, form labels, navigation), it goes in i18n. If it comes from the commerce backend, it comes from Frontic.

### Delegating Page Creation to Sub-Agents

When delegating content-rich page creation to sub-agents or task agents, include content tier constraints in the prompt explicitly. Sub-agents do not have access to skills — they only follow the prompt they receive. Saying "use `$t()` for all text" will be interpreted as "put everything in i18n." Instead, the prompt must specify: which content comes from YAML queries, which from i18n, and that image URLs belong in YAML — not inline.

### Content Collections with Zod Schemas

Every structured YAML file gets a Zod schema in `content.config.ts`. Use `localizedCollection()` and `localizedPages()` helpers to create `en` + `de` variants automatically (see `content.config.ts` in the skeleton for the pattern).

### Querying Content

Always append `_${locale.value}` to the collection name. Always include locale in the `useAsyncData` cache key.

```typescript
const { locale } = useI18n()

// Structured data (YAML)
const { data: homeContent } = await useAsyncData(`home-${locale.value}`, () =>
  queryCollection(`home_${locale.value}` as any).first(),
)

// Markdown pages — match by stem (file path)
const { data: contentPage } = await useAsyncData(
  `content-${slug.value}-${locale.value}`,
  () => queryCollection(`pages_${locale.value}` as any)
    .where('stem', '=', `${locale.value}/${slug.value}`)
    .first(),
)
```

## Data Sourcing: Frontic First

When building features that combine data from multiple sources (e.g., a cart item that has both commerce data and product details), always prefer Frontic for product presentation data:

| Data type | Source | Examples |
|-----------|--------|----------|
| **Product presentation** | Frontic | Title (localized), images, description, page route/URL, brand name, category |
| **Transactional data** | Commerce backend | Price, quantity, stock, discounts, tax, shipping, cart line item IDs |

This matters because:
- **Localization** — Frontic returns titles and descriptions in the correct locale for the current context. Commerce backends often store only one language or require separate locale handling.
- **Routing** — Frontic knows the URL structure. A cart item needs to link back to the product page — that route comes from Frontic, not the commerce backend.
- **API optimization** — Frontic APIs are tailored for frontend needs (right image sizes, relevant fields only). Commerce backend product data is often bloated or in a different shape.
- **Consistency** — Product details rendered from Frontic data look and behave the same everywhere (PDP, cart, favorites, search results).

**In practice**: When rendering a cart line item, use the commerce backend for `quantity`, `price`, and `lineItemId`, but fetch or resolve the product through Frontic for its `name`, `image`, and `link`. Don't rely on product data embedded in the cart response — it may be incomplete, unlocalized, or in a different format.

## Frontic Commerce Composables

All commerce data flows through six auto-imported composables. Read `references/frontic-patterns.md` for detailed usage examples.

| Composable | Use case | Returns |
|-----------|----------|---------|
| `useFronticPage()` | URL-based page resolution | `{ data, type, status, route }` |
| `useFronticSearch(name, params)` | Search/filter/sort/paginate | `{ result, state, searchTerm, filterResult, sortResult, resetFilter }` |
| `useFronticListing(name, params)` | Simple data listing | `{ listing, status }` |
| `useFronticBlock(name, key)` | Single item fetch (product detail, individual card) | `{ block, status, refresh, refetch }` |
| `useFronticContext()` | Store/region switching | `{ contexts, current, update }` |
| `useFronticClient()` | Low-level API access | Direct API client for advanced/custom queries |

**Key patterns**:
- `result` from `useFronticSearch` is a `ShallowRef` — access items via `result.items`. The `state` object gives you `active` (current filters/sort) and `available` (all options).
- `useFronticBlock` is used by doc blocks for fetching individual product data: `const { block, status } = useFronticBlock('ProductCard', productId)`. It supports `staleTime` for cache control.
- `useFronticClient` is rarely needed directly — use it only for custom API calls that don't fit the other composables.

## i18n Rules

Read `references/i18n-patterns.md` for the complete i18n guide.

**Non-negotiable rules:**
- All i18n keys use **kebab-case** with dot separators: `product.buy.add-to-cart`
- All visible text in templates uses `$t()` — raw text triggers ESLint errors
- Locale files: `i18n/locales/en.json` and `i18n/locales/de.json`
- Route localization via `defineI18nRoute({ paths: { de: '/german-path' } })`
- Content queries always append `_${locale.value}` to collection name
- `useAsyncData` keys always include locale to prevent cross-language cache pollution

## Component Patterns

Read `references/component-patterns.md` for detailed examples of each page type.

### UI Components — Frontic UI Registry

The `app/components/ui/` directory contains components from the **Frontic UI registry** (`registry.ui.frontic.com`), configured in `components.json`. These are headless reka-ui primitives with 8 commerce-specific components (Filter, Rating, Swatch, SwatchGroup, RangeSlider, RadioStack, MegaMenu, Format). They are auto-imported and excluded from ESLint/Prettier. Customize them when the change benefits the entire component library (e.g., adding a new color variant that every page will use). For context-specific needs, compose `ui/` components into project components in `app/components/` instead.

The registry also includes **20 installable blocks** — production-ready page compositions (product-card-01, product-detail-01, category-page-01, cart-01, checkout-01, search-01, store-navigation-01/02, header-01/02/03, footer-01/02/03, filter-panel-01/02/03, page-layout-01/02/03). Install blocks as starting points and customize them. Use the MCP tool `get_blocks` to browse by category (cart, category, checkout, layout, navigation, product, search), or `get_block_source` to inspect a block's full source code.

For detailed guidance on composing, extending, and creating UI components, see the **frontic-ui-composition** skill.

### Organization
Organize components by **feature domain** (not by type). Only create directories for features the project actually needs. Examples from a full-featured storefront:
- `product/` — Product.vue, ProductCard.vue, ProductCardSkeleton.vue
- `category/` — Category.vue, CategoryContent.vue
- `layout/` — Header, footer, drawer, navigation
- `cart/` — Cart items, empty state
- `search/` — Refine sheet, filters, pagination

Check the registry for blocks first (`get_blocks`) — they provide production-ready starting points for most of these domains.

### Skeleton Loading
Every grid that loads async data should show skeletons during `status === 'pending'`:
```vue
<template v-if="status === 'pending'">
  <ProductCardSkeleton v-for="index in 6" :key="index" />
</template>
<template v-else-if="status === 'success' && result?.items?.length">
  <ProductCard v-for="product in result.items" :key="product.key" :product="product" />
</template>
```

### ClientOnly for Hydration Safety
Wrap anything that reads from localStorage (cart count, favorites count) in `<ClientOnly>`:
```vue
<ClientOnly>
  <div v-if="favorites.length > 0" class="badge">{{ favorites.length }}</div>
</ClientOnly>
```

## Composable Patterns

Composables live in `app/composables/` and are auto-imported. Create them as the project's features require — a store with no cart doesn't need `useCart`, a store with no favorites doesn't need `useFavorites`.

### State Management Hierarchy
1. **`ref()` / `computed()`** — Local component state
2. **`useState()`** — Cross-component SSR-safe state (e.g., cart)
3. **`useLocalStorage()`** from @vueuse/core — Persistent user preferences (favorites)
4. **Frontic composables** — API-driven reactive state

### Server Safety
Always guard localStorage access:
```typescript
if (import.meta.server) return []
// or
if (import.meta.client) {
  onMounted(() => { /* localStorage access */ })
}
```

### Local Solutions vs. Backend Integrations

Commerce backend integrations (commercetools, Shopware, Shopify, etc.) are handled by separate skills that get added to the project when applicable. But the storefront should always have a working UI regardless of which backends are connected. This means providing local implementations as stand-ins — but with clear rules about what's a mock and what's production-ready.

**Local solutions OK for production:** favorites/wishlists in localStorage, UI preferences, filter/sort in URL params. **Mocks (require backend replacement):** cart, checkout, auth, orders, inventory, pricing. Mark mocks with `// MOCK:` + `console.warn` in dev, keep the same interface as the real integration, never store sensitive data client-side, scope to one composable.

## Styling and Code Conventions

- `cn()` from `app/lib/utils.ts` for conditional classes; semantic color tokens (`text-muted-foreground`, `bg-active`); `font-display` for headings; container `mx-auto max-w-6xl px-5`
- SFC order: `<script setup>` → `<template>` → `<style>`. Type imports: `import type { Foo }`. Prettier: single quotes, no semicolons, trailing commas. pnpm only.

### Auto-Imports

Components are auto-imported in `<template>` only (names follow folder path, duplicate segments skipped: `product/ProductCard.vue` → `<ProductCard />`). Utils, composables, types, and Vue APIs are auto-imported everywhere — never add manual imports for auto-imported items.

### Types and Utils — Where They Live

| Scope | Utils | Types |
|-------|-------|-------|
| Client/app only | `app/utils/` | `app/types/` |
| Server only | `server/utils/` | `server/types/` |
| Shared (client + server) | `shared/utils/` | `shared/types/` |

**Critical pitfall with `.d.ts` files**: Type files must use bare interfaces/types without `export` or `declare`. Adding `export` turns the file into a module and breaks auto-import for every type in it. If a type is needed on both client and server, move it to `shared/types/`.

## Verification — A Required Phase, Not an Afterthought

**"It starts" is not verification.** `pnpm dev` starting, `pnpm typecheck` passing, and `pnpm lint` showing zero errors tells you almost nothing about whether the site works. The site can pass all three and still be completely broken — hydration errors, missing data, failed API calls, blank pages, 500s on every route.

**Verify after each major phase** (layout shell, feature components, all pages wired), not just at the end. Catching errors early prevents them from compounding.

### Verification Steps (in order)

1. **Discover browser tools** — Run `ToolSearch` for chrome, playwright, browser, or screenshot. Check which MCP tools are available for browser automation. This determines whether you can verify programmatically or must rely on manual checks.
2. **Start the dev server** — `pnpm dev` in the background. Read the terminal output for startup errors.
3. **Visit key pages** — If browser MCP tools are available, navigate to home, a product page, a category page, and search. Take screenshots. If no browser tools, tell the user which URLs to check manually.
4. **Check server logs** — Look at the `pnpm dev` terminal for SSR errors (500s, failed API calls, missing modules, hydration mismatches).
5. **Check browser console** — If browser MCP tools are available, read console messages. Classify warnings as harmless or requiring action — do not ignore them.
6. **Test interactive flows** — Add to cart, switch locale/region, open mobile drawer, use search. Interactive features break silently.
7. **Run static checks** — `pnpm typecheck` and `pnpm lint` last, as confirmation — not as the primary verification.

**Do NOT treat typecheck + lint as sufficient.** They verify types and style, not functionality. A component that renders an empty div with correct types passes both checks.

## Detailed References

For building specific features, consult these reference files:

- **`references/component-patterns.md`** — How to build Product, Category, Brand, Home, Search pages with full code examples
- **`references/i18n-patterns.md`** — Complete i18n setup: keys, routing, content queries, locale files
- **`references/navigation-patterns.md`** — Desktop mega-menu, mobile drawer, hierarchical menu state
- **`references/frontic-patterns.md`** — Frontic composable usage, search/filter/sort, listings, context

## Related Skills

- **frontic-ui-composition** — Component discovery via MCP tools, CVA variants and commerce colors, design system setup (styles, presets, palettes), theming, and how to compose and customize UI primitives.
- **commerce-ux-patterns** — Interaction design guidance: feedback patterns (toast vs inline vs redirect), conversion optimization tactics, edge cases to handle, and how each UX pattern maps to Frontic blocks and components.
