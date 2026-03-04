# Frontic Composable Patterns Reference

Complete guide to using @frontic/nuxt composables for headless commerce data.

## Table of Contents

1. [Overview](#overview)
2. [useFronticPage — URL Resolution](#usfronticpage)
3. [useFronticSearch — Search, Filter, Sort](#usfronticsearch)
4. [useFronticListing — Simple Data Fetching](#usfronticlisting)
5. [useFronticContext — Store/Region/Locale](#usfronticcontext)
6. [Type System](#type-system)
7. [Common Patterns](#common-patterns)

---

## Overview

All four composables are auto-imported by `@frontic/nuxt`. Never import them manually. Generated types live in `.frontic/` — never edit those files.

**Nuxt config:**
```typescript
frontic: {
  contextDomain: 'ct.demo-shop.com',
  throwOn404: false,  // Return null instead of throwing for missing pages
}
```

**Route rules for ISR:**
```typescript
routeRules: {
  '/**': { isr: 60 },  // Incremental Static Regeneration, 60s TTL
}
```

---

## useFronticPage

Resolves the current URL to a commerce page (Product, Brand, or Category).

**Returns:**
```typescript
{
  data: Ref<ProductFull | BrandFull | CategoryFull | null>
  type: Ref<'Product' | 'Brand' | 'Category' | null>
  status: Ref<'pending' | 'success' | 'error'>
  route: Ref<FronticRoute>
}
```

**Usage in the catch-all router:**
```vue
<script setup lang="ts">
const { data, type, status } = useFronticPage()
</script>

<template>
  <template v-if="status === 'success'">
    <Product v-if="type === 'Product'" :product="data" />
    <Brand v-else-if="type === 'Brand'" :brand="data" />
    <Category v-else-if="type === 'Category'" :category="data" />
    <!-- Fallback to content/home -->
  </template>
</template>
```

**Key behavior:**
- Automatically reads the current route — no params needed
- Returns `null` for `type` when the URL doesn't match any commerce entity
- `throwOn404: false` in config means non-matching URLs return null instead of erroring
- `status` transitions: `pending` → `success` or `error`

---

## useFronticSearch

Full-featured search with filtering, sorting, and pagination. This is the workhorse for category pages and search pages.

**Signature:**
```typescript
useFronticSearch(name: string, params: MaybeRefOrGetter<object>, options?: object)
```

**Returns:**
```typescript
{
  result: ShallowRef<{ items: ProductCard[] }>  // Search results
  state: {
    active: {
      filter: Record<string, string[]>  // Currently applied filters
      count: { filter: number }         // Number of active filters
    }
    available: {
      filter: FilterOption[]            // All available filter options
      sorting: SortOption[]             // All available sort options
      count: { result: number }         // Total matching results
    }
  }
  searchTerm: Ref<string>              // Current search query (writable)
  filterResult: (field: string, options: string[]) => void  // Apply filter
  sortResult: (sortBy: string) => void                      // Change sort
  resetFilter: (field?: string) => void                     // Reset one or all filters
}
```

### Category page usage

```typescript
const { result, status, state, searchTerm, sortResult, filterResult, resetFilter } =
  useFronticSearch('ProductSearch', {
    categoryKey: props.category.key,  // Scope search to category
  })
```

### Global search page usage

```typescript
const { result, state, searchTerm, sortResult, filterResult, resetFilter } =
  useFronticSearch('ProductSearch', {})  // No category = global search
```

### Wiring to the RefineSheet

The RefineSheet emits standardized events that map directly to the search composable:

```vue
<SearchRefineSheet
  v-model:open="showRefineSheet"
  :state="state"
  :search-term="searchTerm"
  :category="category.name"
  @reset="resetFilter($event as any)"
  @filter="(field: string, options: string[]) => filterResult(field as any, options as any)"
  @sort="(sortBy: string) => sortResult(sortBy as any)"
  @search="(newTerm: string | number) => (searchTerm = String(newTerm).trim())"
  @close="showRefineSheet = false"
/>
```

### Accessing results

`result` is a `ShallowRef` — access items via `result.items`:

```vue
<div v-if="result?.items" class="grid grid-cols-2 gap-4 md:grid-cols-4">
  <ProductCard v-for="product in result.items" :key="product.key" :product="product" />
</div>
```

### Reading state for UI

```vue
<!-- Show result count -->
<span>{{ state.available.count.result }}</span>

<!-- Show active filter badge -->
<ClientOnly>
  <div v-if="state.active.count.filter > 0" class="badge">
    {{ state.active.count.filter }}
  </div>
</ClientOnly>

<!-- Iterate available sort options -->
<RadioGroup @update:model-value="handleSort">
  <div v-for="sortOption in state.available.sorting" :key="sortOption.key">
    <RadioGroupItem :id="sortOption.key" :value="sortOption.value" />
    <Label :for="sortOption.key">{{ sortOption.label }}</Label>
  </div>
</RadioGroup>

<!-- Iterate available filters -->
<div v-for="filter in state.available.filter" :key="filter.key">
  <SearchRefineFilterText
    :filter-field="filter.key"
    :filter-options="filter.options"
    :active-options="state.active.filter?.[filter.key] ?? []"
    @reset-filter="handleReset"
    @filter-result="handleFilter"
  />
</div>
```

---

## useFronticListing

Simple data fetching for lists that don't need search/filter/sort.

**Signature:**
```typescript
useFronticListing(name: string, params: MaybeRefOrGetter<object>)
```

**Returns:**
```typescript
{
  listing: Ref<{ items: T[] } | null>
  status: Ref<'pending' | 'success' | 'error'>
}
```

### Menu tree

```typescript
const { listing: fullTree } = useFronticListing('MenuTree', {})

// Access items
fullTree.value?.items?.forEach(item => {
  // item.name, item.key, item.link?.path, item.children?.items
})
```

### Brand listing

```typescript
const { listing: brands } = useFronticListing('BrandListing', {})

// In template
<div v-if="brands">
  <BrandCard v-for="brand in brands.items" :key="brand.key" :brand="brand" />
</div>
```

### Favorites with reactive params

```typescript
const keys = useLocalStorage<string[]>('favorites', [])

const { listing, status } = useFronticListing(
  'FavoritesProducts',
  computed(() => ({ keys: keys.value })),  // Reactive params!
)
```

### Category metadata

```typescript
const { listing: catMeta } = useFronticListing('CategoryMeta', {
  categoryKey: props.category.key,
})
```

---

## useFronticContext

Manages store, region, and locale context.

**Returns:**
```typescript
{
  contexts: Ref<ContextOption[]>  // Available stores/regions
  current: Ref<Context>           // Currently active context
  update: (context: Context) => void  // Switch context
}
```

**Usage in store picker:**
```vue
<script setup lang="ts">
const { contexts, current, update } = useFronticContext()
</script>

<template>
  <div v-for="ctx in contexts" :key="ctx.key">
    <button :class="{ active: ctx.key === current?.key }" @click="update(ctx)">
      {{ ctx.label }}
    </button>
  </div>
</template>
```

---

## Type System

Generated types are in `.frontic/` — never edit manually. Key types:

| Type | Source | Used by |
|------|--------|---------|
| `ProductFull` | `.frontic/` | Product detail page |
| `ProductCard` | `.frontic/` | Product cards in grids |
| `ProductVariant` | `.frontic/` | Variant selection |
| `CategoryFull` | `.frontic/` | Category page |
| `BrandFull` | `.frontic/` | Brand page |
| `BrandCard` | `.frontic/` | Brand cards in grids |
| `MenuItem` | `.frontic/` | Navigation menu items |
| `Price` | `.frontic/` | Price objects for formatting |
| `LineItem` | `app/types/index.d.ts` | Cart items (custom, not Frontic) |

**Custom types** go in `app/types/index.d.ts` (auto-imported).

---

## Common Patterns

### Skeleton loading while data fetches

```vue
<template v-if="status === 'pending'">
  <ProductCardSkeleton v-for="index in 6" :key="index" />
</template>
<template v-else-if="status === 'success' && result?.items?.length">
  <ProductCard v-for="product in result.items" :key="product.key" :product="product" />
</template>
```

### Hiding nav when overlay opens

```typescript
const { hideNavMenu } = useShopNav()

watch(showRefineSheet, (isOpen) => {
  hideNavMenu.value = isOpen
})
```

### Variant selection via URL query param

```typescript
const { query } = useRoute()

onMounted(() => {
  if (query.sku && typeof query.sku === 'string' &&
    props.product.variants?.some(v => v.key === query.sku)) {
    selectedVariant.value = props.product.variants.find(v => v.key === query.sku) ?? null
  } else {
    selectedVariant.value = props.product.variants?.[0] ?? null
  }
})
```

### Combining Frontic data with content data

The Home page pattern — merge API data (categories) with content data (images):

```typescript
const { listing: fullTree } = useFronticListing('MenuTree', {})
const { data: homeContent } = await useAsyncData(...)

const categories = computed(() => {
  const images = homeContent.value?.categoryImages ?? []
  const children = fullTree.value?.items?.flatMap(item => item.children?.items ?? [])
  return [
    ...(fullTree.value?.items?.slice(0, 4) ?? []),
    ...(children?.slice(0, 4) ?? []).map((item, i) => ({
      ...item,
      image: { src: images[i] },
    })),
  ]
})
```

### Price formatting

Use the `formatPrice()` utility from `app/utils/formatter.ts`:

```typescript
// In templates
{{ formatPrice(product.price) }}
{{ formatPrice(selectedVariant.price) }}

// In scripts (for toast messages)
const priceString = variant.price ? formatPrice(variant.price) : undefined
```
