# Store Discovery — Output Template

Use this template for the migration document. Fill every section based on crawl
observations. Mark sections "Not detected" when the store lacks a feature —
never omit the heading.

---

# Store Migration Plan: {Store Name}

**Source URL:** {url}
**Analysis date:** {date}
**Platform detected:** {platform or "Custom / Unknown"}
**Languages detected:** {list of locales}

---

## 1. Store Overview

### Business Profile
- **Industry / vertical:** {e.g., fashion, electronics, food & beverage}
- **Product range:** {brief description — e.g., "Women's and men's apparel, accessories, shoes"}
- **Market positioning:** {budget / mid-range / premium / luxury — infer from pricing, imagery, brand voice}
- **Target audience:** {infer from product range, language, design cues}

### Key Metrics (observed)
- **Approximate product count:** {estimate from category counts or pagination}
- **Number of top-level categories:** {count}
- **Number of languages/locales:** {count}
- **Has customer accounts:** {yes/no}
- **Has reviews/ratings:** {yes/no}

---

## 2. Data Architecture

### 2.1 Storages Required

| Storage | Justification | Notes |
|---------|--------------|-------|
| products | {why — e.g., "Product grid with variants on category pages"} | |
| categories | {why} | |
| brands | {why — or "Not needed" if no brand pages/filters} | |
| {additional} | {why} | |

### 2.2 Block Definitions

#### ProductCard
Minimal product representation for grids and listings.

| Field | Type | Source observation |
|-------|------|-------------------|
| name | string | Product title in grid |
| slug | string | Product URL segment |
| price | `{ amount, precision, currency }` | Price display on card |
| images | `Array<{ url, alt }>` | Product thumbnail(s) |
| badge | string \| null | "New", "Sale" labels |
| rating | number \| null | Star rating if displayed |
| reviewCount | number \| null | Review count if displayed |
| brand | `{ name, key }` \| null | Brand name on card |
| {additional fields} | | |

#### ProductFull
Complete product detail for PDP.

| Field | Type | Source observation |
|-------|------|-------------------|
| name | string | Product title |
| slug | string | URL segment |
| description | string | Product description / tabs |
| price | `{ amount, precision, currency }` | Price display |
| images | `Array<{ url, alt }>` | Gallery images |
| variants | `Array<ProductVariant>` | Color/size/material selectors |
| brand | `{ name, key, link }` \| null | Brand reference |
| categories | `Array<{ name, key }>` | Breadcrumb categories |
| attributes | `Record<string, string>` | Material, care instructions, etc. |
| rating | number \| null | Average rating |
| reviewCount | number \| null | Total reviews |
| {additional fields} | | |

#### CategoryFull
Category detail.

| Field | Type | Source observation |
|-------|------|-------------------|
| name | string | Category heading |
| slug | string | URL segment |
| description | string \| null | Category intro text |
| image | `{ url, alt }` \| null | Category hero image |
| parentKey | string \| null | Parent category for hierarchy |
| {additional fields} | | |

#### MenuTree
Navigation tree.

| Field | Type | Source observation |
|-------|------|-------------------|
| label | string | Menu item text |
| link | string | Target URL |
| children | `Array<MenuTree>` | Sub-items |
| depth | number | Nesting level observed |

#### {Additional blocks as needed}

### 2.3 Listing Definitions

| Listing | Embedded Block | Required Params | Filter Fields | Sort Fields | Observation |
|---------|---------------|-----------------|---------------|-------------|-------------|
| ProductSearch | ProductCard | — (optional categoryKey) | {from filter sidebar} | {from sort dropdown} | Main product grid |
| CategoryProducts | ProductCard | key: string | — | — | Category-specific products |
| BrandProducts | ProductCard | brandKey: string | {filters if any} | {sorts if any} | Brand page products |
| MenuTreeListing | MenuTree | — | — | — | Main navigation |
| {additional} | | | | | |

**Filter field details:**

| Listing | Field name | Type | Path | Query usage |
|---------|-----------|------|------|-------------|
| ProductSearch | price | range | amount | `{ type: "range", field: "price.amount", from, to }` |
| ProductSearch | {observed filter} | equals/range | {path} | `{ type: "...", field: "...", value: "..." }` |

**Sort field details:**

| Listing | Field name | Query usage |
|---------|-----------|-------------|
| ProductSearch | {observed sort} | `{ field: "...", order: "asc" }` |

### 2.4 Page Types

| URL pattern observed | Frontic page type | Route resolution |
|---------------------|-------------------|------------------|
| `/{locale}/{category-slug}` | CategoryPage | useFronticPage catch-all |
| `/{locale}/product/{slug}` or `/{locale}/p/{slug}` | ProductPage | useFronticPage catch-all |
| `/{locale}/brand/{slug}` | BrandPage | useFronticPage catch-all |
| `/{locale}/{content-slug}` | Content page (@nuxt/content) | Content collection |

### 2.5 Frontic Config Recommendations

```typescript
// nuxt.config.ts — frontic module
frontic: {
  contextDomain: '{detected domain}',
  redirectOn301: true,
  throwOn404: true,
  proxy: true,
}
```

**Locale handling:** {describe observed pattern — e.g., "URL prefix /en/, /de/ with locale switcher in header"}

---

## 3. Features Inventory

### Navigation & Discovery
- [ ] Mega menu / multi-level navigation — {detected / not detected}
- [ ] Search bar with autocomplete — {detected / not detected}
- [ ] Breadcrumb navigation — {detected / not detected}
- [ ] Product filters (faceted search) — {list observed filters}
- [ ] Sort options — {list observed sort options}
- [ ] Pagination / infinite scroll — {which type}

### Product Experience
- [ ] Product image gallery — {single / multi / zoom}
- [ ] Variant selection (color, size, etc.) — {list observed variant types}
- [ ] Product tabs (description, specs, reviews) — {list observed tabs}
- [ ] Related / recommended products — {detected / not detected}
- [ ] Recently viewed products — {detected / not detected}
- [ ] Product badges (new, sale, etc.) — {list observed badges}

### Cart & Checkout
- [ ] Mini cart / slide-out cart — {detected / not detected}
- [ ] Full cart page — {detected / not detected}
- [ ] Guest checkout — {detected / not detected}
- [ ] Customer accounts — {detected / not detected}

### Content & Engagement
- [ ] Customer reviews/ratings — {detected / not detected}
- [ ] Wishlist/favorites — {detected / not detected}
- [ ] Blog / editorial content — {detected / not detected}
- [ ] Newsletter signup — {detected / not detected}
- [ ] Social media links — {detected / not detected}
- [ ] Store locator — {detected / not detected}

### Technical
- [ ] Multi-language — {list locales}
- [ ] Multi-currency — {list currencies if detected}
- [ ] Cookie consent — {detected / not detected}
- [ ] PWA / mobile app banner — {detected / not detected}

---

## 4. Design System

### Recommended Init Command

```bash
npx @frontic/ui init \
  --style {closest style: vega|nova|maia|lyra|mira} \
  --font {closest font} \
  --icon-library {recommended icon library} \
  --commerce-palette {closest palette: default|warm|cool|bold|monochrome|nature|ocean|sunset|berry} \
  --theme-color "{oklch light:dark}" \
  {additional overrides}
```

### Color Palette

| Role | Observed color | OKLCH value | Frontic token |
|------|---------------|-------------|---------------|
| Primary / brand | {hex} | {oklch} | `--theme-color` |
| Buy / CTA | {hex} | {oklch} | `--commerce-buy` |
| Background | {hex} | {oklch} | `--background` |
| Text / foreground | {hex} | {oklch} | `--foreground` |
| {additional} | | | |

### Typography

| Element | Font family | Weight | Size (approx) |
|---------|------------|--------|----------------|
| Headings | {observed} | {observed} | {observed} |
| Body text | {observed} | {observed} | {observed} |
| Navigation | {observed} | {observed} | {observed} |
| Price | {observed} | {observed} | {observed} |
| Buttons | {observed} | {observed} | {observed} |

### Layout Patterns

| Pattern | Observation |
|---------|-------------|
| Content max-width | {e.g., ~1200px} |
| Product grid columns | {e.g., 4 on desktop, 2 on mobile} |
| Section spacing | {e.g., ~64px between sections} |
| Card border-radius | {e.g., 8px} |
| Button border-radius | {e.g., 4px / full-rounded} |

### Style Mapping Rationale

**Closest Frontic style:** {style} — because {reasoning based on observed border-radius, spacing, density}

**Closest commerce palette:** {palette} — because {reasoning based on CTA colors, accent use}

---

## 5. Migration Recommendations

### Priority Order

1. **Phase 1 — Foundation:** {storages, blocks, Frontic config, design system init}
2. **Phase 2 — Core pages:** {which pages to build first — usually category + PDP}
3. **Phase 3 — Commerce flows:** {cart, checkout, accounts — requires commerce backend skill}
4. **Phase 4 — Enhancements:** {reviews, wishlist, search, content pages}

### Complexity Assessment

| Area | Complexity | Notes |
|------|-----------|-------|
| Data architecture | {low/medium/high} | {why} |
| Navigation | {low/medium/high} | {why — e.g., "3-level mega menu requires MenuTree block"} |
| Product variants | {low/medium/high} | {why — e.g., "color + size matrix with dependent stock"} |
| Multi-language | {low/medium/high} | {why} |
| Design migration | {low/medium/high} | {why} |

### Evolution Opportunities

List areas where the new storefront can improve on the original:
- {e.g., "Current filter sidebar is cramped — redesign with slide-out filter panel"}
- {e.g., "Product images are low quality — implement zoom with high-res assets"}
- {e.g., "No quick-view on category page — add quick-view modal for faster browsing"}

### Related Skills for Implementation

| Phase | Skill | Purpose |
|-------|-------|---------|
| Foundation | `frontic-implementation` | Create blocks, listings, pages |
| Foundation | `frontic-ui-composition` | Initialize design system, install components |
| Core pages | `nuxt-storefront-architect` | Page structure, routing, composables |
| Commerce | `{commerce backend skill}` | Cart, checkout, accounts |
| UX polish | `commerce-ux-patterns` | Conversion patterns, feedback, edge cases |
