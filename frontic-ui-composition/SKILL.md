---
name: frontic-ui-composition
description: >
  Guide for building e-commerce UIs with the Frontic UI component system — a component registry
  built on top of shadcn-vue (66 UI components: full shadcn-vue catalog + 7 commerce-specific
  components like Filter, Rating, Swatch, MegaMenu + 7 enhanced overrides + 20 blocks). Covers:
  using the Frontic UI MCP server (13 tools) to browse, search, view, and install components; the
  design system layer (5 visual styles, 5 presets, 9 commerce color palettes); CVA variants (color,
  variant, size) with commerce colors (buy, checkout, promo, discount, new, price, active, positive);
  composing components into pages; creating custom components; theming with OKLch CSS variables; and
  working with blocks (pre-built page templates). Use this skill whenever the user wants to add,
  customize, extend, or compose UI components for a storefront. Trigger on any mention of UI
  components, component variants, buttons, cards, filters, swatches, ratings, theming, brand colors,
  component registry, shadcn, reka-ui, headless components, MCP server for components, visual
  styles, presets, design system setup, or visual design for e-commerce — even if they don't
  explicitly say "Frontic UI". Also trigger when the user mentions shadcn, as Frontic UI is the
  registry used in this project.
---

# Frontic UI Composition Guide

Frontic UI is a component registry built on top of shadcn-vue. Every shadcn-vue component is available through the Frontic registry — the registry transparently proxies any component it doesn't override. On top of the full shadcn-vue catalog (~52 components), Frontic adds 7 commerce-specific components and 7 enhanced overrides of existing shadcn-vue components, plus 20 pre-built blocks and 2 utilities. That's **66 UI components** total, all installable via a single CLI.

Components are headless (reka-ui primitives), styled with Tailwind v4, and use CVA (class-variance-authority) for type-safe variants.

This skill covers how to discover, install, compose, customize, and extend these components to build production-grade storefront UIs.

## Design System Layer

Every Frontic project is built on a design system configuration stored in `components.json`. This file is **created by running `npx @frontic/ui init`** (or `npx @frontic/ui create`) — it doesn't exist in a bare skeleton. It records the project's visual style, base color, font, icon library, and path aliases. The CLI reads it when installing components and applies the correct style transformations.

### Visual Styles

Five visual styles transform Tailwind classes at install time — the same component source renders differently depending on the chosen style:

| Style | Character | Best for |
|-------|-----------|----------|
| **Vega** | Clean, neutral — the classic shadcn/ui look | General-purpose, familiar feel |
| **Nova** | Reduced padding and margins | Compact layouts, dense product grids |
| **Maia** | Soft and rounded, generous spacing | Premium, lifestyle brands |
| **Lyra** | Boxy and sharp | Technical, mono-font aesthetics |
| **Mira** | Compact | Dense interfaces, admin-style UIs |

### Presets

Presets bundle a style + icon library + font into a ready-to-use configuration:

| Preset | Style | Icons | Font |
|--------|-------|-------|------|
| `reka-vega` | Vega | Lucide | Inter |
| `reka-nova` | Nova | Hugeicons | Inter |
| `reka-maia` | Maia | Hugeicons | Figtree |
| `reka-lyra` | Lyra | Hugeicons | JetBrains Mono |
| `reka-mira` | Mira | Hugeicons | Inter |

### Commerce Color Palettes

Nine palettes control the OKLCH values for commerce tokens (buy, checkout, promo, etc.): **default**, **warm**, **cool**, **bold**, **monochrome**, **nature**, **ocean**, **sunset**, **berry**. Each palette sets coordinated light/dark values for all 10 commerce tokens. Individual tokens can also be overridden with custom OKLCH values via `--commerce-buy`, `--commerce-checkout`, etc.

### Creating a New Project

```bash
# Create with a preset (recommended)
npx @frontic/ui create my-store --preset reka-vega --yes

# Or customize everything
npx @frontic/ui create my-store --style maia --font figtree --icons hugeicons --palette warm

# Initialize in an existing project
npx @frontic/ui init --style vega --commerce-palette warm
```

**Key init flags:**
- `--style <style>` — Visual style (vega, nova, maia, lyra, mira)
- `--font <font>` — Font (inter, geist, etc.)
- `--icon-library <lib>` — Icons (lucide, tabler, hugeicons, phosphor, remixicon)
- `--commerce-palette <palette>` — Commerce color palette (default, warm, cool, bold, monochrome, nature, ocean, sunset, berry)
- `--theme-color <oklch>` — Custom primary color (encoded OKLCH `light:dark`)
- `--commerce-buy <oklch>`, `--commerce-checkout <oklch>`, etc. — Override individual commerce tokens
- `--dark-mode / --no-dark-mode` — Include dark mode support (off by default)
- `-b, --base-color <color>` — Base gray (neutral, gray, zinc, stone, slate)

### What `components.json` Contains

The init command generates `components.json` with project configuration. It stores the style, font, icon library, paths, and base color — but **not commerce colors**. Commerce color palettes are written directly as CSS custom properties into the project's stylesheet (e.g. `assets/css/tailwind.css`).

```json
{
  "$schema": "https://ui.frontic.com/schema.json",
  "style": "vega",
  "base": "reka",
  "font": "inter",
  "iconLibrary": "lucide",
  "typescript": true,
  "tailwind": {
    "css": "assets/css/tailwind.css",
    "baseColor": "neutral",
    "cssVariables": true,
    "darkMode": false
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "lib": "@/lib",
    "composables": "@/composables"
  }
}
```

### Dark Mode

Dark mode is **optional and off by default** since 0.9.x. Enable it during init or by adding the `.dark` class to `<html>` and defining dark-mode token overrides in `tailwind.css`.

## Frontic UI MCP Server

The Frontic UI MCP server gives you direct access to browse, search, view, and install components from the registry. This is the primary way to discover and add components — use it instead of memorizing component names.

### Ensuring the MCP Server is Running

Check if the `frontic-ui` MCP server is connected by looking for its tools (they start with `mcp__frontic-ui__`). If it's not running:

1. **Check for `.mcp.json`** in the project root. It should have a `frontic-ui` entry. The default uses the **hosted** MCP server (no npm install needed):
   ```json
   {
     "mcpServers": {
       "frontic-ui": {
         "type": "sse",
         "url": "https://mcp.ui.frontic.com/mcp"
       }
     }
   }
   ```
   Alternatively, use the **local** stdio transport:
   ```json
   {
     "mcpServers": {
       "frontic-ui": {
         "command": "npx",
         "args": ["@frontic/ui@latest", "mcp"]
       }
     }
   }
   ```

2. **If `.mcp.json` doesn't exist**, create it by running:
   ```bash
   npx @frontic/ui mcp init --client claude
   ```
   Then restart Claude Code. Also supports `--client cursor`, `--client vscode`, `--client codex`, `--client opencode`.

3. **Debug with `/mcp`** — Run the `/mcp` command in Claude Code to see the server status. It should show "Connected" with 12–13 available tools.

### MCP Tools Available

Once connected, these tools let you interact with the Frontic registry:

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `get_design_system` | Full design system overview: styles, presets, fonts, icons, commerce colors, block categories | **Start here** — understand what's available before building |
| `get_theme` | CSS custom property definitions (OKLCH) for light and dark mode | When you need exact color token values |
| `get_blocks` | Browse pre-built commerce blocks by category | Exploring what blocks exist for a page type |
| `scaffold_storefront` | Step-by-step build plan with CLI commands and file structure | Starting a new storefront from scratch |
| `list_registry_items` | Browse all components/blocks with pagination, filter by type | Exploring what's available |
| `search_registry_items` | Fuzzy search by name/description | Looking for a specific component (e.g., "filter", "swatch") |
| `view_registry_items` | Full component source, deps, and metadata | Before using a component — see its props, variants, files |
| `get_item_examples` | Working demo code with complete Vue source | Need usage examples for a component |
| `get_add_command` | CLI install command for one or more items | Ready to install a component or block |
| `get_component_variants` | CVA variant keys, values, and defaults for a component | Before using a component — discover available variant, size, color props |
| `get_block_source` | Full source code of all files in a block | Understanding how a block works before installing or customizing |
| `get_audit_checklist` | Post-install QA checklist (Nuxt-specific) | After adding components, verify setup |
| `get_project_config` | Read `components.json` project config (local mode only) | Check the project's configured style and preferences |

### Workflow: Starting a Storefront

1. **Design system** — Call `get_design_system` to see all available styles, presets, and options
2. **Scaffold** — Call `scaffold_storefront` with the desired preset and pages to get a build plan (includes a ready-to-use `components.json`)
3. **Execute** — Run the CLI commands from the scaffold plan
4. **Audit** — Call `get_audit_checklist` to verify everything is wired up

### Workflow: Adding a Component

1. **Search** — Use `search_registry_items` to find what you need
2. **View** — Use `view_registry_items` to inspect source, props, and variants; use `get_component_variants` to see CVA variant keys/values/defaults
3. **Examples** — Use `get_item_examples` if you need usage patterns
4. **Install** — Use `get_add_command` to get the install command, then run it
5. **Audit** — Use `get_audit_checklist` to verify setup

### Workflow: Adding Blocks

1. **Browse** — Use `get_blocks` with a category filter (cart, checkout, product, category, search, layout, navigation)
2. **View** — Use `get_block_source` to see all files in the block, or `view_registry_items` for metadata and dependencies
3. **Install** — Use `get_add_command` to get the install command, then run it
4. **Customize** — Blocks install as regular Vue files — adapt them to your project's data types and styling

## Commerce Colors

Frontic extends the standard shadcn/ui palette with 10 e-commerce semantic color tokens. Each token has a `-foreground` pair and adapts to dark mode automatically. These are set via `--commerce-palette` during init and stored as CSS custom properties (not in components.json):

| Token | Purpose | Used by |
|-------|---------|---------|
| `buy` | Add-to-cart buttons, purchase CTAs | Button `color="buy"` |
| `checkout` | Checkout flow buttons and highlights | Button `color="checkout"` |
| `promo` | Promotional badges, banners | Badge `color="promo"` |
| `discount` | Discount codes, percentage-off indicators | Badge `color="discount"` |
| `new` | New product badges, arrival indicators | Badge `color="new"` |
| `price` | Price display and currency formatting | CSS: `text-price` |
| `active` | Active/selected state indicators | Badge `color="active"` |
| `info` | Informational callouts | Badge `color="info"` |
| `positive` | Success states, confirmations | Button `color="positive"` |
| `warning` | Stock alerts, caution states | Badge `color="warning"` |

Not every color works on every component — buttons have `buy`, `checkout`, `destructive`, `positive` as color variants, while badges support the broader commerce set. Always check the component's CVA definition for available colors.

```vue
<Button color="buy" size="xl">{{ $t('product.buy.add-to-cart') }}</Button>
<Button color="checkout" size="xl" class="w-full">{{ $t('checkout.pay') }}</Button>
<Badge color="promo">{{ $t('product.badge.sale') }}</Badge>
<Badge color="new" variant="subtle">{{ $t('product.badge.new') }}</Badge>
```

## Available Components

The Frontic registry serves the **full shadcn-vue component catalog** — Checkbox, Dialog, Select, Table, Form, Input, and everything else you'd expect. If the user asks for any standard UI component (checkbox, dropdown, dialog, etc.), it's available via `npx frontic-ui add <name>`. No need to install shadcn-vue separately — the Frontic registry proxies it transparently.

### Commerce-Specific Components (Frontic-only)

These 7 components are unique to Frontic — not available in upstream shadcn-vue:

| Component | Purpose |
|-----------|---------|
| **Filter** | Faceted product filtering (color, size, price range) |
| **Rating** | Star rating display with half-star support |
| **Swatch** | Color/variant swatch selector |
| **SwatchGroup** | Grouped swatch selectors with labels |
| **RangeSlider** | Dual-handle range slider for price filtering |
| **RadioStack** | Stacked radio options for shipping, payment selection |
| **MegaMenu** | Multi-column navigation menu for product categories |

### Enhanced Overrides

These 7 shadcn-vue components have Frontic-specific enhancements (commerce colors, extra variants, additional sub-components). Frontic's version is installed instead of the upstream:

| Component | Enhancement |
|-----------|-------------|
| **Button** | Commerce colors (buy, checkout), variant/color separation, xl/icon sizes |
| **Badge** | Commerce colors (promo, discount, new, active), subtle variant |
| **Card** | Plain/boxed/elevated/inverted variants, CardImage sub-component |
| **Accordion** | Boxed and bordered variants |
| **Alert** | Semantic color variants |
| **Carousel** | Navigation dots and progress bar indicators |
| **Tabs** | Underline and pill variants |

### Utility

| Utility | Purpose |
|---------|---------|
| **Format** | Price and currency formatting (`formatPrice()`) |

```
search_registry_items({ registries: ["@frontic"], query: "filter" })
view_registry_items({ items: ["@frontic/filter"] })
```

## How the Registry Works

This is not a component library — it's how you build your component library. The registry provides well-structured starting points that you then own and adapt.

The Frontic registry serves as a superset of shadcn-vue. When you request a component, the registry first checks if Frontic has its own version (the 7 custom + 7 enhanced components). If not, it transparently proxies the request to shadcn-vue. This means every standard component (Checkbox, Dialog, Select, Form, Table, etc.) is available through `npx frontic-ui add <name>` — no need to configure a separate shadcn-vue registry.

Components install to `app/components/ui/{name}/` and are auto-imported by Nuxt. Once installed, they're yours — but treat `ui/` as a shared library. Every change affects every usage. Only modify `ui/` components when the change is intended for the whole library (e.g., adding a `color: 'brand'` variant to Button because every page needs it). For context-specific needs, compose `ui/` components into project components in `app/components/` instead.

**Style transformation**: When you install a component, the CLI reads `components.json` to determine the project's visual style and applies the correct Tailwind class transformations at install time. The same component source in the registry produces different styling for Vega vs Maia vs Lyra.

## How to Think When Building UI

Before writing any code, walk through this decision process:

### 1. What do I need?

Break the UI down into its parts. A product detail page isn't one component — it's images, rating stars, color swatches, a price display, an add-to-cart button, etc. Think in building blocks.

### 2. Does a block exist?

Check the registry for blocks first — they're production-ready compositions:

```
get_blocks({ category: "product" })
```

Blocks are the fastest way to get a working page. Install the block, then customize. Block categories: **cart**, **category**, **checkout**, **layout**, **navigation**, **product**, **search**.

### 3. Does it already exist in the project?

Check `app/components/ui/` (registry primitives) and `app/components/` (project compositions). If something close exists:

- **It fits as-is** → Use it directly.
- **It needs a library-wide change** → Add a variant or adjust the CVA definition. Check existing usages first — changing defaults affects everything.
- **It needs a context-specific change** → Don't modify the shared primitive. Build a project component in `app/components/` that composes the `ui/` component with the specific styling or behavior.

### 4. Is there something in the registry?

```
search_registry_items({ registries: ["@frontic"], query: "product" })
```

- **Component found** → Install it. Customize the styling and variants.
- **Block found** → Install it, break it apart, and adapt.
- **Nothing found** → Move to step 5.

### 5. Can I compose from existing components?

Most of what you need can be built by combining `ui/` components in a new project component (in `app/components/`, not `ui/`). A `ProductCard` is Card + Badge + Rating + Button. A filter sidebar is Sheet + ScrollArea + Filter + RangeSlider. Compose first — don't reinvent.

### 6. Create a new primitive (last resort)

Only if nothing covers the behavior you need. Follow the same three-layer pattern (reka-ui + CVA + Tailwind) so it stays consistent.

## Component Architecture

Every Frontic UI component follows the same three-layer pattern:

1. **reka-ui primitive** — Headless, accessible behavior (keyboard nav, ARIA, focus management)
2. **CVA variants** — Type-safe styling via `class-variance-authority`
3. **Tailwind classes** — Visual presentation via utility classes + `cn()` merging

### Anatomy of a Component

```vue
<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import { cn } from '@/lib/utils'
import { Primitive, type PrimitiveProps } from 'reka-ui'
import { type ButtonVariants, buttonVariants } from '.'

interface Props extends PrimitiveProps {
  variant?: ButtonVariants['variant']
  color?: ButtonVariants['color']
  size?: ButtonVariants['size']
  class?: HTMLAttributes['class']
}

const props = withDefaults(defineProps<Props>(), {
  as: 'button',
})
</script>

<template>
  <Primitive
    data-slot="button"
    :as="as"
    :as-child="asChild"
    :class="cn(buttonVariants({ variant, size, color }), props.class)"
  >
    <slot />
  </Primitive>
</template>
```

**Key patterns:**
- **`data-slot`** — Every component has a `data-slot` attribute for CSS targeting and testing
- **`cn()`** — Merges CVA variants with any custom classes passed via `props.class`
- **`Primitive`** — reka-ui's base component handling `as` (element type) and `asChild` (render as child)
- **Slots** — Components are composition-first — content goes through slots

### CVA Variant System

Variants are defined in the component's `index.ts`. Use `get_component_variants` to introspect a component's CVA config — it returns all variant keys, possible values, and defaults. Here's the Button as an example:

```typescript
export const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium transition-colors',
  {
    variants: {
      variant: {
        default: '...',
        subtle: '...',
        outline: '...',
        secondary: '...',
        ghost: '...',
        destructive: '...',
        link: '...',
        form: '...',
      },
      color: {
        primary: '...',       // Default color
        secondary: '...',
        inverted: '...',
        buy: 'shadow-md hover:shadow-xl hover:scale-105',
        checkout: '...',
        destructive: '...',
        positive: '...',
      },
      size: {
        default: 'h-10 px-4 py-2',
        xs: 'h-7 px-2 text-xs',
        sm: 'h-9 px-3 text-sm',
        lg: 'h-11 px-8',
        xl: 'h-14 px-10 text-lg',
        icon: '...',
        'icon-xs': '...',
        'icon-sm': '...',
        'icon-lg': '...',
      },
    },
    defaultVariants: {
      variant: 'default',
      color: 'primary',
      size: 'default',
    },
  }
)
```

**Using variants in templates:**
```vue
<Button variant="outline" color="buy" size="lg">{{ $t('product.buy.add-to-cart') }}</Button>
<Button variant="ghost" size="sm">{{ $t('actions.cancel') }}</Button>
<Button color="checkout" size="xl" class="w-full">{{ $t('checkout.proceed') }}</Button>
```

## Composing Components

Components compose through slots and sub-components:

### Sub-Component Pattern

```vue
<Card>
  <CardImage src="/product.jpg" alt="Product" />
  <CardHeader>
    <CardTitle>Product Name</CardTitle>
    <CardDescription>Short description</CardDescription>
  </CardHeader>
  <CardContent>
    <p>{{ formatPrice(product.price) }}</p>
  </CardContent>
  <CardFooter>
    <Button color="buy">{{ $t('product.buy.add-to-cart') }}</Button>
  </CardFooter>
</Card>
```

### Context Injection Pattern

```vue
<SwatchGroup v-model="selectedColor" variant="circle" size="lg">
  <SwatchGroupItem v-for="color in colors" :key="color" :value="color">
    <Swatch :color="color" />
  </SwatchGroupItem>
</SwatchGroup>
```

### Data-Slot Targeting

Use `data-slot` attributes for CSS customization without modifying component source:

```css
[data-slot="card"] [data-slot="button"] {
  @apply w-full;
}
```

## Theming — Design Tokens

All visual design flows through CSS variables in `app/assets/css/tailwind.css`. There are two layers:

1. **CSS variables** in `:root` (and `.dark`) — the actual color/size values
2. **`@theme inline`** block — maps CSS variables to Tailwind utilities

```css
/* Layer 1: Define the value */
:root {
  --brand: oklch(59% 0.19 276);
  --brand-foreground: oklch(100% 0 0);
}

/* Layer 2: Map to Tailwind */
@theme inline {
  --color-brand: var(--brand);
  --color-brand-foreground: var(--brand-foreground);
}

/* Now available as: text-brand, bg-brand, border-brand, ring-brand, etc. */
```

Always use semantic tokens instead of arbitrary values (`text-[#6366f1]`) or Tailwind built-ins (`text-blue-500`). Semantic tokens adapt to dark mode and keep the design system consistent.

### Color Categories

| Category | Variables | Purpose |
|----------|-----------|---------|
| **UI core** | `--background`, `--foreground`, `--primary`, `--secondary`, `--muted`, `--accent`, `--border` | Base layout and text |
| **Commerce** | `--buy`, `--checkout`, `--promo`, `--discount`, `--new`, `--price`, `--active`, `--info`, `--positive`, `--warning` | E-commerce semantics (each has a `-foreground` pair) |
| **Surface** | `--card`, `--popover`, `--sidebar` | Container backgrounds (each has a `-foreground` pair) |
| **Feedback** | `--destructive`, `--ring`, `--input` | Interactive state |

All values use OKLch for perceptual uniformity. When adding colors, use OKLch too.

### Adding a Custom Color

```css
:root {
  --magic: oklch(65% 0.25 290);
  --magic-foreground: oklch(100% 0 0);
}

@theme inline {
  --color-magic: var(--magic);
  --color-magic-foreground: var(--magic-foreground);
}
```

### Fonts

Fonts are configured in the `@theme` block (not `@theme inline` — font families are static):

```css
@theme {
  --font-family-sans: 'Inter', system-ui, sans-serif;
  --font-family-mono: 'JetBrains Mono', ui-monospace, monospace;
  --font-family-display: 'Playfair Display', serif;
}
```

The chosen font from the preset is configured automatically by the CLI during init. See the **nuxt-storefront-architect** skill for font loading setup in the Nuxt project.

### Border Radius

Controlled by a single `--radius` variable. All scales derive from it:

```css
:root {
  --radius: 0.625rem;
}

@theme inline {
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 4px);
}
```

## Blocks — Pre-Built Page Compositions

Blocks are production-ready compositions of multiple components. They're the fastest way to build storefront pages. Use the MCP server to discover them:

```
get_blocks({ category: "product" })
view_registry_items({ items: ["@frontic/product-detail-01"] })
```

**Block categories and available blocks:**

| Category | Blocks |
|----------|--------|
| **Layout** | header-01/02/03, footer-01/02/03, page-layout-01/02/03 |
| **Navigation** | store-navigation-01, store-navigation-02 |
| **Product** | product-card-01, product-detail-01 |
| **Category** | category-page-01, filter-panel-01/02/03 |
| **Cart** | cart-01 |
| **Checkout** | checkout-01 |
| **Search** | search-01 |

Each block includes all required sub-components. After installing, customize them freely — they're regular Vue files. Use `get_block_source` to inspect a block's full source code before installing.

## Customizing and Creating Components

- **`app/components/ui/`** — Registry components. Customize when the change benefits the entire library. Avoid creating new components here from scratch — if the registry later adds one with the same name, it will conflict.
- **`app/components/`** — Project components. Compositions that combine `ui/` components into higher-level pieces like `ProductCard` or `CheckoutSummary`. Organized by feature domain.

### Building Project Components

Check the registry for blocks first — they provide production-ready starting points:

```
search_registry_items({ registries: ["@frontic"], query: "product card" })
```

Typical composition — a `ProductCard` composing Card, Badge, Rating, and Button:

```vue
<!-- app/components/product/ProductCard.vue -->
<script setup lang="ts">
const props = defineProps<{
  product: ProductCard  // Type from .frontic/ generated types
}>()

const emit = defineEmits<{
  'add-to-cart': [product: typeof props.product]
}>()
</script>

<template>
  <Card class="group overflow-hidden">
    <div class="relative">
      <NuxtImg :src="product.cover?.src" :alt="product.name"
        class="aspect-square w-full object-cover transition-transform group-hover:scale-105" />
      <div v-if="product.badge" class="absolute top-2 left-2">
        <Badge :color="product.badge === 'Sale' ? 'promo' : 'new'">
          {{ product.badge }}
        </Badge>
      </div>
    </div>
    <CardHeader>
      <NuxtLink :to="product.link?.path">
        <CardTitle class="line-clamp-2 text-base">{{ product.name }}</CardTitle>
      </NuxtLink>
    </CardHeader>
    <CardContent>
      <Rating v-if="product.rating" :rating="product.rating" size="sm" />
      <p class="text-lg font-semibold">{{ formatPrice(product.price) }}</p>
    </CardContent>
    <CardFooter>
      <Button color="buy" class="w-full" @click="emit('add-to-cart', product)">
        {{ $t('product.buy.add-to-cart') }}
      </Button>
    </CardFooter>
  </Card>
</template>
```

### Creating New Primitives

Only if nothing in the registry covers the behavior. Follow the three-layer pattern:

1. **CVA variants** in an `index.ts` for type-safe styling
2. **Vue component** using `cn()` to merge variants with custom classes
3. **reka-ui primitive** (if interactive) for accessible behavior

Place in `app/components/ui/` only if truly generic. Otherwise, keep in `app/components/`.

## Utility: cn()

The `cn()` function from `app/lib/utils.ts` merges CVA variants with custom classes:

```typescript
import { clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

`twMerge` resolves Tailwind conflicts (`p-2` + `p-4` → `p-4`), while `clsx` handles conditionals.

## Related Skills

- **nuxt-storefront-architect** — Covers data fetching (`useFronticSearch`, `useFronticBlock`, `useFronticListing`), page routing, content management, i18n, and project structure. Use it when wiring components to data.
- **commerce-ux-patterns** — Guides interaction design: which feedback to use for each action (toast vs inline vs redirect), conversion optimization, and edge cases. Use it when deciding *how* a feature should behave.
