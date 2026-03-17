# Customization

How to customize the look and feel of Frontic UI components.

## Contents

- [How It Works](#how-it-works)
- [Color Variables](#color-variables)
- [Commerce Color Tokens](#commerce-color-tokens)
- [Dark Mode](#dark-mode)
- [Changing the Theme](#changing-the-theme)
- [Adding Custom Colors](#adding-custom-colors)
- [Border Radius](#border-radius)
- [Customizing Components](#customizing-components)

## How It Works

Frontic UI components are styled through three layers:

1. **CSS custom properties** — Define color, radius, and font values in `:root` (and `.dark`)
2. **Tailwind theme mapping** — `@theme inline` maps CSS variables to Tailwind utilities
3. **Component variants** — CVA (class-variance-authority) provides type-safe variant props

This means you can customize at any level: change a CSS variable to affect all components, use Tailwind utilities via `class`, or extend CVA variants.

## Color Variables

Colors use OKLCH format for perceptual uniformity. Every color has a paired `-foreground` variable for accessible contrast.

```css
:root {
  --primary: oklch(21% 0.006 286);
  --primary-foreground: oklch(98% 0 0);
  --secondary: oklch(97% 0.001 286);
  --secondary-foreground: oklch(21% 0.006 286);
  /* ... */
}

@theme inline {
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
}
```

After mapping, use as Tailwind utilities: `bg-primary`, `text-primary-foreground`, `border-primary`, `ring-primary`.

### Standard color tokens

| Token | Purpose |
|-------|---------|
| `background` / `foreground` | Page background and default text |
| `primary` / `primary-foreground` | Primary buttons, links, accents |
| `secondary` / `secondary-foreground` | Secondary actions |
| `muted` / `muted-foreground` | Subtle backgrounds, placeholder text |
| `accent` / `accent-foreground` | Hover states, selected items |
| `destructive` / `destructive-foreground` | Delete, error actions |
| `border` | Default borders |
| `input` | Input field borders |
| `ring` | Focus ring color |
| `card` / `card-foreground` | Card backgrounds |
| `popover` / `popover-foreground` | Popover/dropdown backgrounds |
| `sidebar` / `sidebar-foreground` | Sidebar backgrounds |

## Commerce Color Tokens

Frontic extends the standard palette with 10 e-commerce semantic color tokens. Each has a `-foreground` pair and adapts to dark mode automatically:

| Token | Purpose | Component usage |
|-------|---------|-----------------|
| `buy` | Add-to-cart, purchase CTAs | `<Button color="buy">` |
| `checkout` | Checkout flow buttons | `<Button color="checkout">` |
| `promo` | Promotional badges, banners | `<Badge color="promo">` |
| `discount` | Discount codes, percentage-off | `<Badge color="discount">` |
| `new` | New product badges | `<Badge color="new">` |
| `price` | Price display styling | CSS: `text-price` |
| `active` | Active/selected state | `<Badge color="active">` |
| `info` | Informational callouts | `<Badge color="info">` |
| `positive` | Success states | `<Button color="positive">` |
| `warning` | Stock alerts, caution | `<Badge color="warning">` |

Commerce palettes set coordinated values for all 10 tokens: **default**, **warm**, **cool**, **bold**, **monochrome**, **nature**, **ocean**, **sunset**, **berry**.

```bash
npx @frontic/ui init --commerce-palette warm
# Or override individual tokens:
npx @frontic/ui init --commerce-palette warm --commerce-buy 0.35_0.08_45:0.42_0.08_45
```

## Dark Mode

Dark mode is **optional and off by default** since 0.9.x. Enable it:

```bash
npx @frontic/ui init --dark-mode
```

Dark mode works by adding the `.dark` class to `<html>` and defining dark-mode overrides in the CSS file:

```css
.dark {
  --background: oklch(10% 0.004 286);
  --foreground: oklch(98% 0 0);
  /* all dark overrides */
}
```

Component styles adapt automatically — no manual `dark:` prefixes needed when using semantic tokens.

## Changing the Theme

Use the visual creator at [ui.frontic.com/create](https://ui.frontic.com/create) to preview themes, then apply via preset code:

```bash
npx @frontic/ui init --preset v1a2Dg5
```

Or override the primary color directly:

```bash
npx @frontic/ui init --theme-color 0.75_0.11_120:0.88_0.10_120
```

The OKLCH encoding format is `lightness_chroma_hue:lightness_chroma_hue` (light:dark).

## Adding Custom Colors

1. Define the CSS variable in the global stylesheet (from `tailwind.css` in `components.json`):
2. Map it to Tailwind in `@theme inline`:

```css
:root {
  --brand: oklch(65% 0.25 290);
  --brand-foreground: oklch(100% 0 0);
}

@theme inline {
  --color-brand: var(--brand);
  --color-brand-foreground: var(--brand-foreground);
}
```

Now use as: `bg-brand`, `text-brand`, `text-brand-foreground`, etc.

To add a commerce color variant to a component, extend its CVA definition in `components/ui/<name>/index.ts`:

```typescript
color: {
  // existing colors...
  brand: 'bg-brand text-brand-foreground hover:bg-brand/90',
}
```

## Border Radius

Controlled by a single `--radius` variable. All scales derive from it:

```css
:root {
  --radius: 0.625rem;
}
```

## Customizing Components

Priority order for customization:

1. **Built-in variants** — Use existing CVA variants (`variant`, `color`, `size`) before anything else. Check with `npx @frontic/ui docs <component>` or the MCP `get_component_variants` tool.
2. **Tailwind `class` prop** — For layout adjustments (width, margin, padding). Never for color or typography overrides.
3. **Extend CVA variants** — Add new variants in `components/ui/<name>/index.ts` when the change benefits the whole project.
4. **Wrapper components** — For context-specific compositions, create a component in `components/` that composes `ui/` components.

### Checking for Updates

```bash
npx @frontic/ui diff                    # Check all components
npx @frontic/ui diff button             # Check specific component
npx @frontic/ui add button --diff       # Preview what would change
npx @frontic/ui add button --dry-run    # Summary of changes
```
