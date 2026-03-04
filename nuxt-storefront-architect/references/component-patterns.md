# Component Patterns Reference

This reference contains the exact patterns for building each major page type and reusable component in the storefront.

## Table of Contents

1. [Product Detail Page](#product-detail-page)
2. [Product Card](#product-card)
3. [Category Page](#category-page)
4. [Brand Page](#brand-page)
5. [Home Page](#home-page)
6. [Search Page](#search-page)
7. [Search Refine Sheet](#search-refine-sheet)
8. [FAQ Page](#faq-page)
9. [Content Pages](#content-pages)
10. [Cart Components](#cart-components)
11. [Skeleton Loading](#skeleton-loading)

---

## Product Detail Page

The product page receives `ProductFull` from the catch-all router. It manages variant selection via `?sku=` query params, image galleries, quantity selection, and add-to-cart flow with toast notifications.

**Key behaviors:**
- On mount, selects variant matching `?sku=` query param, or falls back to first variant
- Shows 1 or 2 hero images depending on variant image count, plus remaining images in a 3-col grid
- Variant thumbnails are clickable circles with opacity state
- Add-to-cart triggers toast notification with product name, image, and price
- Blurred hero background image on desktop for visual depth

```vue
<script setup lang="ts">
const props = defineProps<{
  product: ProductFull
}>()

const { query } = useRoute()
const { addLineItem } = useCart()
const { addToCartMessage } = useNotify()
const selectedVariant = ref<ProductVariant | null>(null)
const quantity = ref(1)

onMounted(() => {
  if (
    query.sku &&
    typeof query.sku === 'string' &&
    props.product.variants?.some((variant) => variant.key === query.sku)
  ) {
    selectedVariant.value =
      props.product.variants.find((variant) => variant.key === query.sku) ?? null
  } else if (Array.isArray(props.product.variants) && props.product.variants.length > 0) {
    selectedVariant.value = props.product.variants[0] ?? null
  } else {
    selectedVariant.value = null
  }
})

const hasSecondImage = computed(() => {
  return selectedVariant.value?.images?.length && selectedVariant.value.images.length > 1
})

async function handleAddToCart(variant: ProductVariant, quantity: number) {
  await addLineItem(variant.key, quantity)
  addToCartMessage({
    productName: variant.name ?? '',
    productImage: variant.images?.[0]?.src,
    price: variant.price ? formatPrice(variant.price) : undefined,
  })
}
</script>

<template>
  <!-- Blurred background image (desktop only) -->
  <div class="absolute inset-0 top-28 z-0 hidden h-[40%] min-h-[340px] w-screen overflow-hidden sm:block">
    <NuxtImg :src="selectedVariant?.images?.[0]?.src" class="size-full object-cover opacity-10 blur-lg" />
  </div>

  <div class="relative z-10 mx-auto mb-12 flex max-w-7xl flex-col gap-12 sm:mt-20 sm:px-10 lg:px-5">
    <div class="grid grid-cols-2 gap-8 sm:grid-cols-12">
      <!-- Image gallery: 7/12 width -->
      <div v-if="selectedVariant" class="col-span-2 sm:col-span-7 lg:col-span-8">
        <!-- Hero images (1 or 2 columns) -->
        <div :class="hasSecondImage ? 'grid grid-cols-2 gap-2' : 'grid grid-cols-1 gap-2'">
          <div v-for="image in selectedVariant.images?.slice(0, 2) ?? []" :key="image.key"
            :class="hasSecondImage ? 'aspect-[0.75]' : ''" class="overflow-hidden">
            <NuxtImg :src="image.src" :alt="image.altText" height="600"
              class="bg-background object-contain p-2" />
          </div>
        </div>
        <!-- Remaining images in 3-col grid -->
        <div v-if="selectedVariant.images && selectedVariant.images.length > 2"
          class="col-span-12 mt-2 grid grid-cols-3 gap-2">
          <div v-for="image in selectedVariant.images?.slice(2) ?? []" :key="image.key">
            <NuxtImg :src="image.src" :alt="image.altText"
              class="size-full bg-white object-contain p-2 transition-transform duration-300 hover:scale-105" />
          </div>
        </div>
      </div>

      <!-- Product info: 5/12 width -->
      <div class="col-span-2 flex flex-col gap-4 px-5 sm:col-span-5 sm:px-0 lg:col-span-4">
        <h1 class="font-display text-3xl font-medium">{{ product.name }}</h1>
        <p v-if="product.description" class="text-muted-foreground text-lg font-light">
          {{ product.description.split('. ')[0] + (product.description.includes('.') ? '.' : '') }}
        </p>
        <p v-else class="text-muted-foreground font-light">
          {{ $t('product.details.description.missing') }}
        </p>
        <div v-if="selectedVariant?.price" class="text-2xl font-bold">
          {{ formatPrice(selectedVariant?.price) }}
        </div>

        <!-- Variant selector (circular thumbnails) -->
        <div v-if="Array.isArray(product.variants) && product.variants.length > 1"
          class="grid grid-cols-5 gap-4 pb-4">
          <div v-for="variant in product.variants" :key="variant.key"
            class="bg-background aspect-square size-16 cursor-pointer overflow-hidden rounded-full shadow-xs lg:size-20"
            @click="selectedVariant = variant">
            <NuxtImg :src="variant.images?.[0]?.src"
              class="bg-background size-full object-contain p-2 opacity-50 transition-all duration-300 hover:opacity-100"
              :class="{ 'opacity-100': selectedVariant?.key === variant.key }" />
          </div>
        </div>

        <!-- Quantity + Add to cart -->
        <div class="flex w-full items-center gap-4">
          <Select v-model="quantity">
            <SelectTrigger class="h-full border-none text-xl shadow-none">
              <SelectValue :placeholder="String(quantity)" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem v-for="i in 10" :key="i" :value="i">{{ i }}</SelectItem>
            </SelectContent>
          </Select>
          <Button v-if="selectedVariant" color="buy" size="xl" class="grow"
            @click="handleAddToCart(selectedVariant, quantity)">
            {{ $t('product.buy.add-to-cart') }}
          </Button>
        </div>
      </div>
    </div>

    <!-- Full description section -->
    <div class="mt-10 grid grid-cols-12 gap-8 px-5 sm:px-0">
      <h2 class="font-display col-span-12 text-2xl">
        {{ $t('product.details.sections.description') }}
      </h2>
      <p v-if="product.description" class="text-muted-foreground col-span-12 text-lg leading-relaxed font-extralight">
        {{ product.description }}
      </p>
    </div>

    <!-- Reviews -->
    <div v-if="product.reviews?.total && product.reviews.total > 0" class="px-5 sm:px-0">
      <ProductReviewList :reviews="product.reviews" />
    </div>
  </div>
</template>
```

---

## Product Card

Reusable card for grids. Shows primary image with hover-to-second-image transition. Variant thumbnails link directly to PDP with `?sku=` param.

```vue
<script setup lang="ts">
const props = defineProps<{
  product: ProductCard
}>()

const firstImage = computed(() => props.product.variants?.[0]?.images?.[0]?.src)
const secondImage = computed(() => props.product.variants?.[0]?.images?.[1]?.src)
const hasSecondImage = computed(() => !!secondImage.value)

// Preload second image for smooth hover transition
onMounted(() => {
  if (hasSecondImage.value && secondImage.value) {
    const img = new Image()
    img.src = secondImage.value
  }
})
</script>

<template>
  <div class="flex flex-col gap-2">
    <NuxtLink :to="product.link?.path">
      <div class="group relative aspect-[0.75] overflow-hidden bg-white shadow-xs">
        <NuxtImg :src="firstImage" :alt="product.name" class="size-full object-cover sm:p-4" />
        <NuxtImg v-if="hasSecondImage" :src="secondImage" :alt="product.name" :width="320"
          class="absolute inset-0 size-full object-cover opacity-0 transition-opacity duration-500 group-hover:opacity-100 sm:p-4" />
      </div>
    </NuxtLink>

    <!-- Variant color swatches -->
    <div v-if="Array.isArray(product.variants) && product.variants.length > 1">
      <div class="flex gap-2">
        <NuxtLink v-for="variant in product.variants" :key="variant.key"
          :to="product.link?.path + '?sku=' + variant.key">
          <div class="aspect-square size-6 cursor-pointer overflow-hidden bg-white">
            <NuxtImg :src="variant.images?.[0]?.src"
              class="size-full scale-400 object-contain blur-xs saturate-200" />
          </div>
        </NuxtLink>
      </div>
    </div>

    <!-- Product info -->
    <NuxtLink :to="product.link?.path" class="flex flex-col gap-1 text-xs">
      <p class="font-lighter font-display text-gray-700">{{ product.name }}</p>
      <p class="font-light text-gray-500 uppercase">{{ product.brand }}</p>
      <p v-if="product.price?.amount" class="text-muted-foreground font-light">
        {{ formatPrice(product.price) }}
      </p>
    </NuxtLink>
  </div>
</template>
```

---

## Category Page

Category pages use `useFronticSearch` with the category key for filtered product search. The pattern integrates the RefineSheet for sort/filter.

```vue
<script setup lang="ts">
const props = defineProps<{
  category: CategoryFull
}>()

const showRefineSheet = ref(false)
const { hideNavMenu } = useShopNav()

// Coordinate nav visibility with refine sheet
watch(showRefineSheet, (isOpen) => {
  hideNavMenu.value = isOpen
})

const { result, status, state, searchTerm, sortResult, filterResult, resetFilter } =
  useFronticSearch('ProductSearch', {
    categoryKey: props.category.key,
  })
</script>

<template>
  <CategoryContent :category="category" />
  <div class="mx-auto my-12 max-w-6xl px-5">
    <div class="flex items-center justify-between">
      <h1 class="font-display text-3xl font-light">{{ category.name }}</h1>
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
    </div>
    <div class="grid grid-cols-2 gap-4 md:grid-cols-4">
      <template v-if="status === 'pending'">
        <ProductCardSkeleton v-for="index in 6" :key="index" />
      </template>
      <template v-else-if="status === 'success' && result?.items?.length">
        <ProductCard v-for="product in result.items" :key="product.key" :product="product" />
      </template>
    </div>
  </div>
</template>
```

---

## Brand Page

Minimal — just name and description from Frontic data.

```vue
<script setup lang="ts">
defineProps<{
  brand: BrandFull
}>()
</script>

<template>
  <div class="mx-auto max-w-7xl px-5 py-12 sm:px-10 lg:px-5">
    <h1 class="font-display text-3xl font-medium">{{ brand.name }}</h1>
    <p v-if="brand.description" class="text-muted-foreground mt-4 text-lg font-light">
      {{ brand.description }}
    </p>
  </div>
</template>
```

---

## Home Page

Combines Frontic commerce data (menu tree categories) with structured content (YAML hero, featured items, new arrivals). Uses responsive grid breakpoints to show different category counts at different viewport sizes.

```vue
<script setup lang="ts">
const { locale } = useI18n()
const { listing: fullTree } = useFronticListing('MenuTree', {})

const contentCollection = computed(() => `home_${locale.value}`)
const { data: homeContent } = await useAsyncData(`home-${locale.value}`, () =>
  queryCollection(contentCollection.value as any).first(),
)

// Merge top-level categories with flattened children, adding images from content
const categories = computed(() => {
  const images = homeContent.value?.categoryImages ?? []
  const childrenFlat = fullTree.value?.items?.flatMap((item: any) => item.children?.items ?? [])
  return [
    ...(fullTree.value?.items?.slice(0, 4) ?? []),
    ...(childrenFlat?.slice(0, 4) ?? []).map((item: any, index: number) => ({
      ...item,
      image: { src: images[index] },
    })),
  ]
})
</script>

<template>
  <div class="flex min-h-screen flex-col gap-20">
    <!-- Hero banner with CTA overlay -->
    <div class="relative max-h-[680px] w-full overflow-hidden">
      <NuxtImg :src="homeContent?.hero?.image" :alt="homeContent?.hero?.imageAlt"
        class="max-h-[680px] w-full object-cover" />
      <div class="absolute inset-0 flex flex-col items-center justify-center gap-8">
        <h1 class="font-display max-w-2xl text-center text-4xl text-white">
          {{ homeContent?.hero?.title }}
        </h1>
        <Button class="border-slate-100 text-slate-100" variant="outline" size="lg">
          {{ homeContent?.hero?.button }}
        </Button>
      </div>
    </div>

    <!-- Category grid: 2 cols mobile, 4 cols tablet, 8 cols desktop -->
    <div class="flex flex-col gap-8 px-4 sm:px-12">
      <h2 class="font-display text-left text-2xl text-gray-800">
        {{ homeContent?.categories?.title }}
      </h2>
      <!-- Mobile: 2x2 grid (first 4) -->
      <div class="grid grid-cols-2 gap-4 md:hidden">
        <div v-for="item in categories.slice(0, 4)" :key="item.key">
          <NuxtLink :to="item.link?.path ?? ''" class="flex flex-col gap-2 text-left">
            <NuxtImg :src="item.image?.src" :alt="item.name"
              class="aspect-[0.75] w-full object-cover shadow-xs" />
            <p class="font-light text-slate-500 uppercase">{{ item.name }}</p>
          </NuxtLink>
        </div>
      </div>
      <!-- Tablet: 4 cols (all) -->
      <div class="grid-cols-4 gap-4 md:grid lg:hidden">
        <div v-for="item in categories" :key="item.key"><!-- same card --></div>
      </div>
      <!-- Desktop: 8 cols (all) -->
      <div class="hidden grid-cols-8 gap-4 lg:grid">
        <div v-for="item in categories" :key="item.key"><!-- same card --></div>
      </div>
    </div>

    <!-- Featured grid + New arrivals CTA -->
  </div>
</template>
```

---

## Search Page

Search uses `useFronticSearch` without a category key for global product search. Integrates with nav state to hide/show mobile nav when refine sheet opens.

```vue
<script setup lang="ts">
const { locale } = useI18n()
const showRefine = ref(false)
const searchInputRef = ref<HTMLElement | null>(null)

const { result, state, searchTerm, sortResult, filterResult, resetFilter } =
  useFronticSearch('ProductSearch', {})
const { hideNavMenu } = useShopNav()

// Load hero image from home content
const { data: homeContent } = await useAsyncData(`home-search-${locale.value}`, () =>
  queryCollection(`home_${locale.value}` as any).first(),
)

watch(showRefine, (isOpen) => {
  hideNavMenu.value = isOpen
})

function handleSearchFocus() {
  nextTick(() => {
    if (searchInputRef.value) {
      const y = searchInputRef.value.getBoundingClientRect().top + window.scrollY - 10
      window.scrollTo({ top: y, behavior: 'smooth' })
    }
  })
}
</script>
```

---

## Search Refine Sheet

The refine sheet is a reusable side panel that combines sorting, in-category search, and filter groups. It uses `v-model:open` for two-way binding and emits standardized events.

**Event contract:**
- `reset` — Reset a specific filter or all filters
- `filter` — Apply filter options to a field
- `sort` — Change sort order
- `search` — Update search term within category
- `close` — Close the sheet

```vue
<script setup lang="ts">
defineProps<{
  category?: string
  state: {
    active: { filter: Record<string, any>; count: { filter: number } }
    available: { filter: any[]; sorting: any[]; count: { result: number } }
  }
  searchTerm: string
}>()

const open = defineModel<boolean>('open')

const emit = defineEmits<{
  reset: [filterField?: string]
  filter: [filterField: string, filterOptions: string[]]
  sort: [sortBy: string]
  search: [term: string | number]
  close: []
}>()
</script>
```

Uses shadcn Sheet + ScrollArea + RadioGroup for sort + custom FilterText components for each filter group.

---

## FAQ Page

Loads structured FAQ data from content collection. Uses shadcn Accordion.

```vue
<script setup lang="ts">
const { locale } = useI18n()

const collectionName = computed(() => `faq_${locale.value}`)
const { data: faq } = await useAsyncData(`faq-${locale.value}`, () =>
  queryCollection(collectionName.value as any).first(),
)
</script>

<template>
  <div class="container mx-auto min-h-screen max-w-4xl px-5 py-20">
    <template v-if="faq">
      <h1 class="font-display mb-2 text-3xl font-light">{{ faq.title.line1 }}</h1>
      <h2 class="font-display mb-10 text-3xl font-light text-gray-500">{{ faq.title.line2 }}</h2>
      <Accordion type="single" collapsible>
        <AccordionItem v-for="(item, index) in faq.items" :key="index" :value="`faq-${index}`">
          <AccordionTrigger class="text-lg">{{ item.question }}</AccordionTrigger>
          <AccordionContent>
            <p class="leading-relaxed text-gray-600">{{ item.answer }}</p>
          </AccordionContent>
        </AccordionItem>
      </Accordion>
    </template>
  </div>
</template>
```

---

## Content Pages

Rendered automatically by the catch-all router. No dedicated component needed — just `<ContentRenderer>` with prose styling.

```vue
<!-- Inside [...slug].vue -->
<div v-else-if="isContentPage" class="container mx-auto min-h-screen max-w-4xl px-5 py-20">
  <h1 class="font-display mb-10 text-3xl font-light capitalize">{{ contentPage!.title }}</h1>
  <div class="prose prose-gray max-w-none">
    <ContentRenderer :value="contentPage!" />
  </div>
</div>
```

To add a new content page: create `content/en/my-page.md` and `content/de/meine-seite.md`. No code changes needed.

---

## Cart Components

### CartItem
Displays a single cart line item with quantity selector and remove button:
```vue
<script setup lang="ts">
const props = defineProps<{
  item: LineItem
  locked?: boolean
}>()

const emit = defineEmits<{
  update: [cartItemId: string, quantity: number]
  remove: [cartItemId: string]
  click: []
}>()
</script>
```

### CartEmpty
Empty cart state with optional recommendations:
```vue
defineProps<{
  cartRecoStatus?: string
  cartRecoList?: any
}>()

defineEmits<{ close: [] }>()
```

---

## Skeleton Loading

Always provide a skeleton component for async grids:

```vue
<!-- ProductCardSkeleton.vue -->
<template>
  <div class="flex flex-col gap-2">
    <Skeleton class="aspect-[0.75] w-full" />
    <Skeleton class="h-4 w-3/4" />
    <Skeleton class="h-3 w-1/2" />
    <Skeleton class="h-3 w-1/3" />
  </div>
</template>
```

Use conditional rendering based on `status`:
```vue
<template v-if="status === 'pending'">
  <ProductCardSkeleton v-for="index in 6" :key="index" />
</template>
```
