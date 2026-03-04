# i18n Patterns Reference

Complete guide to internationalization in the Nuxt storefront.

## Table of Contents

1. [Key Naming Convention](#key-naming-convention)
2. [Locale File Structure](#locale-file-structure)
3. [Template Usage](#template-usage)
4. [Route Localization](#route-localization)
5. [Content Collection Queries](#content-collection-queries)
6. [Content File Organization](#content-file-organization)
7. [Adding a New Locale](#adding-a-new-locale)
8. [ESLint Enforcement](#eslint-enforcement)

---

## Key Naming Convention

All i18n keys use **kebab-case** with **dot separators** for nesting:

```
product.buy.add-to-cart        ✅ correct
product.buyAddToCart           ❌ camelCase not allowed
product.buy.addToCart          ❌ mixed case not allowed
product_buy_add_to_cart        ❌ underscores not allowed
```

**Category structure** (top-level groups):
```
about.*          — About section
actions.*        — Global action labels (shop-all, show-all)
brands.*         — Brands page
cart.*           — Cart UI (title, items, summary, empty)
context.*        — Store/region/language selection
control.*        — Filters, sort, search, pagination
default.*        — Utility patterns (in-brackets)
error.*          — Error states
favorites.*      — Favorites page
footer.*         — Footer content
layout.toast.*   — Toast notification messages
navigation.*     — Navigation labels
product.*        — Product detail page
search.*         — Search page
```

---

## Locale File Structure

Locale files live at `i18n/locales/{code}.json`. They're flat JSON objects with dot-separated keys representing nesting.

**Example (en.json):**
```json
{
  "actions": {
    "shop-all": "Shop all",
    "show-all": "Show all"
  },
  "cart": {
    "title": "Cart",
    "title-long": "Shopping Cart",
    "empty": {
      "title": "Your Cart is Empty",
      "description": "Discover our latest products and find something you love."
    },
    "items": {
      "singular": "item",
      "plural": "items"
    },
    "summary": {
      "count": "{count} items",
      "subtotal": "Subtotal",
      "total": "Total"
    }
  },
  "product": {
    "buy": {
      "add-to-cart": "Add to cart"
    },
    "details": {
      "sections": {
        "description": "Product Description"
      },
      "description": {
        "missing": "No description available for this product."
      },
      "reviews": {
        "title": "Customer Reviews",
        "count": "{count} reviews",
        "rating": "{rating}/5"
      }
    }
  },
  "search": {
    "counter": "{count} results for \"{term}\"",
    "no-results": "No results found.",
    "placeholder": "Search products...",
    "results": "Search Results",
    "suggestions": "Chair,Sofa,Table,Lamp,Rug,Shelf"
  }
}
```

**Interpolation patterns:**
- Named params: `{count}`, `{term}`, `{rating}`, `{category}`
- Comma-separated lists: `search.suggestions` splits on `,` in code
- Bracket wrapping: `default.in-brackets` = `"({text})"`

---

## Template Usage

### Basic translation
```vue
<h1>{{ $t('cart.title') }}</h1>
```

### With interpolation
```vue
<p>{{ $t('search.counter', { count: results.length, term: query }) }}</p>
<p>{{ $t('cart.summary.count', { count: lineItems.length }) }}</p>
<p>{{ $t('product.details.reviews.count', { count: reviews.total }) }}</p>
```

### In script setup
```typescript
const { t } = useI18n()
const suggestions = t('search.suggestions').split(',')
```

### Inline formatting with i18n
```vue
<!-- Use default.in-brackets for consistent "(value)" formatting -->
<span>{{ $t('default.in-brackets', { text: state.available.count.result }) }}</span>
```

### Escaping raw text (rare exceptions)
When raw text is truly needed (e.g., technical identifiers), disable the lint rule inline:
```vue
<!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
<span class="text-muted-foreground block text-sm font-light">
  REF: {{ selectedVariant.key }}
</span>
```

---

## Route Localization

For pages that need custom paths in other locales, use `defineI18nRoute()`:

```vue
<script setup lang="ts">
defineI18nRoute({
  paths: {
    de: '/marken', // /brands -> /de/marken
  },
})
</script>
```

**What this does:**
- English: `/brands` (default, uses filename)
- German: `/de/marken` (custom path from config)

**When to use:**
- Any page where the German (or other locale) URL should differ from the English filename
- Content pages don't need this — their URLs come from the markdown filename (`about.md` → `/about`, `ueber-uns.md` → `/de/ueber-uns`)

---

## Content Collection Queries

### Pattern: Always locale-suffix the collection name

```typescript
const { locale } = useI18n()

// ✅ Correct — locale in collection name AND cache key
const { data } = await useAsyncData(`home-${locale.value}`, () =>
  queryCollection(`home_${locale.value}` as any).first(),
)

// ❌ Wrong — no locale in collection name
const { data } = await useAsyncData('home', () =>
  queryCollection('home').first(),
)

// ❌ Wrong — no locale in cache key (stale data when switching locales)
const { data } = await useAsyncData('home', () =>
  queryCollection(`home_${locale.value}` as any).first(),
)
```

### Pattern: Reusable composable for navigation

```typescript
// app/composables/useNavContent.ts
export function useNavContent() {
  const { locale } = useI18n()
  return useAsyncData(`navigation-${locale.value}`, () =>
    queryCollection(`navigation_${locale.value}` as any).first(),
  )
}
```

### Pattern: Matching markdown pages by slug

```typescript
const slug = computed(() => {
  const parts = route.params.slug
  return Array.isArray(parts) ? parts.join('/') : parts || ''
})

const { data: contentPage } = await useAsyncData(
  `content-${slug.value}-${locale.value}`,
  () => queryCollection(`pages_${locale.value}` as any)
    .where('stem', '=', `${locale.value}/${slug.value}`)
    .first(),
)
```

---

## Content File Organization

Each locale gets its own directory under `content/`:

```
content/
├── en/
│   ├── home.yml            # Structured: hero, categories, featured
│   ├── navigation.yml      # Structured: header teaser, footer links
│   ├── faq.yml             # Structured: Q&A items
│   ├── about.md            # Simple: company story
│   ├── shipping.md         # Simple: delivery info
│   ├── privacy.md          # Simple: privacy policy
│   ├── contact.md          # Simple: contact info
│   └── imprint.md          # Simple: legal imprint
└── de/
    ├── home.yml            # Same schema, German content
    ├── navigation.yml
    ├── faq.yml
    ├── ueber-uns.md        # German filename = German URL slug
    ├── versand.md
    ├── datenschutz.md
    ├── kontakt.md
    └── impressum.md
```

**Important: Markdown filenames determine URL slugs.** `en/about.md` → `/about`, `de/ueber-uns.md` → `/de/ueber-uns`. There's no mapping file — the filename IS the route.

---

## Adding a New Locale

1. Add locale config to `nuxt.config.ts`:
```typescript
i18n: {
  locales: [
    // ... existing locales
    { code: 'fr', name: 'French', language: 'fr-FR', dir: 'ltr', file: 'fr.json' },
  ],
}
```

2. Create locale file `i18n/locales/fr.json` with all keys translated

3. Update `content.config.ts`:
```typescript
const LOCALES = ['en', 'de', 'fr'] as const
```

4. Create `content/fr/` directory with all YAML and Markdown files translated

5. Update `defineI18nRoute()` calls in pages that have custom paths:
```typescript
defineI18nRoute({
  paths: {
    de: '/marken',
    fr: '/marques',
  },
})
```

---

## ESLint Enforcement

These rules are configured in `eslint.config.mjs` and are non-negotiable:

```javascript
'@intlify/vue-i18n/no-missing-keys': 'error',    // Every key used must exist
'@intlify/vue-i18n/no-dynamic-keys': 'error',     // No computed key strings
'@intlify/vue-i18n/valid-message-syntax': 'error', // Valid ICU syntax
'@intlify/vue-i18n/no-raw-text': 'error',         // All text must use $t()
'@intlify/vue-i18n/key-format-style': ['error', 'kebab-case', {
  allowArray: false,
  splitByDots: true,
}],
```

**What this means in practice:**
- Every string visible to users must go through `$t()`
- No inline strings in templates (even "Loading...")
- Key names must be kebab-case with dot nesting
- Dynamic key construction is forbidden (prevents dead key detection)
