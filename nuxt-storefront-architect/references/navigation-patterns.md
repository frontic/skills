# Navigation Patterns Reference

Complete guide to building desktop and mobile navigation in the storefront.

## Table of Contents

1. [Navigation Architecture Overview](#navigation-architecture-overview)
2. [Desktop Navigation (Navbar + Mega-Menu)](#desktop-navigation)
3. [Mobile Navigation (Drawer)](#mobile-navigation)
4. [Navigation State Management](#navigation-state-management)
5. [Navigation Content from Collections](#navigation-content-from-collections)
6. [Layout Structure](#layout-structure)

---

## Navigation Architecture Overview

Navigation has two parallel implementations that share data but render differently:

| Viewport | Component | Trigger | Pattern |
|----------|-----------|---------|---------|
| Desktop (sm+) | `LayoutNavbar` | Always visible | Mega-menu with hover |
| Mobile (<sm) | `LayoutDrawerNav` | Floating action buttons | Full-screen drawer |

Both read from the same Frontic `MenuTree` data and content collections.

**Component tree:**
```
Layout (default.vue)
├── LayoutHeader
│   ├── LayoutHeaderUtility (always shown: teaser, store picker, locale)
│   ├── LayoutStoreLogo (mobile only)
│   └── LayoutNavbar (desktop: sm+ breakpoint)
│       ├── LayoutStoreLogo
│       ├── LayoutNavbarMenuMain           ← Top-level nav items
│       │   └── LayoutNavbarMenuContent    ← Mega-menu per category
│       │       ├── LayoutNavbarMenuSubItems
│       │       └── LayoutNavbarMenuAboutMenu
│       ├── LayoutNavbarSearch
│       ├── LayoutNavbarCart
│       └── LayoutNavbarFavorites
├── <slot /> (page content)
├── LayoutFooter
└── LayoutDrawerNav (mobile drawer)
    ├── LayoutDrawerNavTrigger            ← Floating buttons
    ├── LayoutDrawerMenuMenu              ← Hierarchical mobile menu
    │   └── LayoutDrawerMenuSubmenu
    ├── LayoutDrawerSearchSearch
    └── LayoutDrawerCartCart
```

---

## Desktop Navigation

### MenuMain — Top-Level Items

Reads the full category tree from Frontic and renders each item as either a direct link or a trigger for a mega-menu dropdown.

```vue
<script setup lang="ts">
import { navigationMenuTriggerStyle } from '@/components/ui/navigation-menu'

const { listing: fullTree } = useFronticListing('MenuTree', {})
</script>

<template>
  <div v-if="fullTree?.items && fullTree.items.length > 0" class="items-center gap-8">
    <NavigationMenuList>
      <NavigationMenuItem v-for="item in fullTree.items" :key="item.key">
        <!-- Direct link (no children) -->
        <NuxtLink v-if="!item.categoryId && item.path" v-slot="{ isActive, href, navigate }"
          :to="item.path" custom>
          <NavigationMenuLink :active="isActive" :href :class="navigationMenuTriggerStyle()"
            @click="navigate">
            {{ item.name }}
          </NavigationMenuLink>
        </NuxtLink>

        <!-- Category with mega-menu -->
        <div v-else>
          <NavigationMenuTrigger class="px-3">{{ item.name }}</NavigationMenuTrigger>
          <NavigationMenuContent>
            <LayoutNavbarMenuContent :category-id="item.key" :category="item" />
          </NavigationMenuContent>
        </div>
      </NavigationMenuItem>
    </NavigationMenuList>
  </div>
</template>
```

**Key decision**: Items with `categoryId` get a dropdown mega-menu. Items with just `path` get a direct link. This distinguishes informational pages from category browsing.

### MenuContent — Mega-Menu Panel

Two-column layout: left side has category links with hover underline animation, right side shows a category image with view-transition-name for smooth page transitions.

```vue
<script setup lang="ts">
import { ArrowRight } from 'lucide-vue-next'

const props = defineProps<{
  categoryId: string
  category?: MenuItem
}>()

const { closeMenu } = useMenuState()
</script>

<template>
  <div class="flex h-full">
    <!-- Left: category links -->
    <div class="flex h-full w-1/2 flex-col justify-between">
      <ul class="mt-8 flex flex-col gap-8">
        <!-- "Shop all" link with arrow -->
        <li>
          <NavigationMenuLink as-child>
            <NuxtLink class="font-display flex items-center gap-3 text-2xl leading-none
              transition-all duration-300 hover:translate-x-2" :to="category?.link?.path">
              <ArrowRight class="size-6" />
              {{ $t('actions.shop-all') }}
            </NuxtLink>
          </NavigationMenuLink>
        </li>
        <!-- Child categories with underline hover -->
        <li v-for="child in category.children?.items" :key="child.key">
          <NavigationMenuLink as-child>
            <NuxtLink :to="child.link?.path" class="group relative inline-block overflow-hidden pb-2">
              <div class="font-display relative z-10 text-2xl leading-none">{{ child.name }}</div>
              <div class="bg-inverted absolute bottom-0 left-0 h-0.5 w-0
                transition-all duration-300 group-hover:w-full" />
            </NuxtLink>
          </NavigationMenuLink>
          <LayoutNavbarMenuSubItems :categories="child.children" />
        </li>
      </ul>
      <!-- About menu at bottom -->
      <div class="mb-10">
        <LayoutNavbarMenuAboutMenu />
      </div>
    </div>

    <!-- Right: category image with view transition -->
    <div class="w-1/2">
      <div v-if="category?.image?.src" class="mt-8 h-full w-auto">
        <NuxtLinkLocale :to="category.link?.path" class="grid" @click="closeMenu">
          <NuxtImg :src="category.image?.src" :alt="category.image?.altText"
            class="col-span-full row-span-full aspect-3/4 w-full object-cover"
            :style="{ 'view-transition-name': `category-image-${category.key}` }" />
          <div class="z-10 col-span-full row-span-full grid pb-5 pl-4 md:p-10">
            <h3 class="text-background font-display self-end text-3xl lg:text-5xl"
              :style="{ 'view-transition-name': `category-title-${category.key}` }">
              {{ category.name }}
            </h3>
          </div>
        </NuxtLinkLocale>
      </div>
    </div>
  </div>
</template>
```

**View Transitions**: The `view-transition-name` on category images and titles enables smooth animations when navigating from the menu to a category page.

### AboutMenu — Static Links from Content

Loads navigation content from the content collection and renders footer-style about links.

```vue
<script setup lang="ts">
const { data: navContent } = useNavContent()
</script>

<template>
  <div v-if="navContent?.about">
    <p class="font-display mb-3 text-sm font-semibold">{{ navContent.about.title }}</p>
    <ul class="flex flex-col gap-2">
      <li v-for="link in navContent.about.links" :key="link.href">
        <NavigationMenuLink as-child>
          <NuxtLink :to="link.href" class="text-sm text-gray-500 hover:text-gray-900">
            {{ link.label }}
          </NuxtLink>
        </NavigationMenuLink>
      </li>
    </ul>
  </div>
</template>
```

---

## Mobile Navigation

### DrawerNavTrigger — Floating Action Buttons

Fixed at the bottom of the screen. Shows different icons based on current section. Cart button displays badge with item count.

```vue
<!-- Key behaviors: -->
<!-- - Shows/hides with scroll animation -->
<!-- - Cart badge wrapped in ClientOnly for hydration safety -->
<!-- - Checkout button appears when cart section is active -->
<!-- - Each button calls setSection() from useShopNav() -->
```

### DrawerMenu — Hierarchical Mobile Menu

Uses a stack-based approach for nested navigation. Helper functions handle the tree traversal.

**Key pattern**: Instead of nested components for each level, use a flat stack:

```typescript
// Conceptual pattern
const menuStack = ref<MenuItem[]>([])

function pushLevel(item: MenuItem) {
  menuStack.value.push(item)
}

function popLevel() {
  menuStack.value.pop()
}

// Current level is always the last item in the stack
const currentLevel = computed(() =>
  menuStack.value.length > 0
    ? menuStack.value[menuStack.value.length - 1]
    : rootMenu
)
```

### DrawerMenu Submenu

Shows back button, "Show all" link, and children:

```vue
<script setup lang="ts">
defineProps<{
  category: MenuItem
  children: MenuItem[]
}>()

defineEmits<{
  back: []
  show: []
  close: []
}>()
</script>

<template>
  <!-- Back button -->
  <!-- "Show all" link with ChevronRight -->
  <!-- Child items list -->
</template>
```

---

## Navigation State Management

### useShopNav — Section-Based Drawer State

```typescript
export function useShopNav() {
  const section = ref<'menu' | 'search' | 'cart' | 'account'>('menu')
  const open = ref(false)
  const hideNavMenu = ref(false)
  const showNavMenuInside = ref(false)

  const resetNav = () => {
    open.value = false
    section.value = 'menu'
  }

  const setSection = (newSection: 'menu' | 'search' | 'cart' | 'account') => {
    section.value = newSection
    open.value = true
  }

  return { section, open, hideNavMenu, showNavMenuInside, resetNav, setSection }
}
```

### useMenuState — Desktop Menu State

```typescript
export function useMenuState() {
  const menuState = ref('')
  const isOpen = ref(false)
  const closeMenu = () => {
    isOpen.value = false
    menuState.value = ''
  }
  return { menuState, isOpen, closeMenu }
}
```

### Cross-Component Coordination

When a filter/refine sheet opens, hide the mobile nav to prevent overlapping:

```typescript
const { hideNavMenu } = useShopNav()

watch(showRefineSheet, (isOpen) => {
  hideNavMenu.value = isOpen
})
```

---

## Navigation Content from Collections

Static navigation links (about pages, legal pages, footer groups) come from content collections, not Frontic.

### useNavContent Composable

```typescript
export function useNavContent() {
  const { locale } = useI18n()
  return useAsyncData(`navigation-${locale.value}`, () =>
    queryCollection(`navigation_${locale.value}` as any).first(),
  )
}
```

### Navigation YAML Schema

```yaml
# content/en/navigation.yml
header:
  teaser: "Free shipping on orders over 50 EUR"

about:
  title: "About"
  links:
    - label: "Our Story"
      href: "/about"
    - label: "Sustainability"
      href: "/sustainability"
    - label: "Careers"
      href: "/careers"
    - label: "Press"
      href: "/press"

footer:
  groups:
    - title: "About"
      links:
        - label: "Our Story"
          href: "/about"
    - title: "Support"
      links:
        - label: "FAQ"
          href: "/faq"
        - label: "Shipping & Returns"
          href: "/shipping"
  legalLinks:
    - label: "Privacy Policy"
      href: "/privacy"
    - label: "Imprint"
      href: "/imprint"
  newsletter:
    title: "Newsletter"
    description: "Subscribe to our newsletter"
    placeholder: "Your email"
    accept: "Subscribe"
    divider: "or"
```

---

## Layout Structure

The default layout provides the shell around every page:

```vue
<!-- app/layouts/default.vue -->
<template>
  <div class="w-full">
    <div><LayoutHeader /></div>
    <main class="mt-0"><slot /></main>
    <div><LayoutFooter /></div>
    <LayoutDrawerNav />
  </div>
</template>
```

**Important**: The drawer is outside `<main>` — it overlays the entire page. The header is outside `<main>` too, so pages don't need to account for header height (except the home hero which uses negative margin or absolute positioning).
