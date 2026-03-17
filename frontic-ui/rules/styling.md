# Styling Rules

Rules for styling Frontic UI components with Tailwind CSS.

## Contents

- Semantic colors
- Commerce colors for e-commerce
- Built-in variants first
- class for layout only
- No space-x-* / space-y-*
- Prefer size-* over w-* h-*
- Prefer truncate shorthand
- No manual dark: color overrides
- Use cn() for conditional classes
- No manual z-index on overlay components

## Semantic colors

Always use semantic color tokens. Never use raw Tailwind colors.

```vue
<!-- Incorrect -->
<div class="bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-50">

<!-- Correct -->
<div class="bg-background text-foreground">
```

```vue
<!-- Incorrect -->
<p class="text-gray-500">Secondary text</p>

<!-- Correct -->
<p class="text-muted-foreground">Secondary text</p>
```

## Commerce colors for e-commerce

Use commerce color tokens for e-commerce semantics instead of custom colors:

```vue
<!-- Incorrect -->
<Button class="bg-green-600 hover:bg-green-700 text-white">Add to Cart</Button>

<!-- Correct -->
<Button color="buy">Add to Cart</Button>
```

```vue
<!-- Incorrect -->
<span class="bg-red-100 text-red-800 rounded px-2">-20%</span>

<!-- Correct -->
<Badge color="discount">-20%</Badge>
```

Available commerce colors: `buy`, `checkout`, `promo`, `discount`, `new`, `price`, `active`, `info`, `positive`, `warning`.

## Built-in variants first

Use component variants before adding custom classes:

```vue
<!-- Incorrect -->
<Button class="border border-input bg-background hover:bg-accent">Cancel</Button>

<!-- Correct -->
<Button variant="outline">Cancel</Button>
```

## class for layout only

The `class` prop is for layout adjustments (width, margin, grid placement). Never override component colors or typography.

```vue
<!-- Incorrect: overriding component styling -->
<Button class="bg-blue-500 text-white text-lg font-bold">Buy</Button>

<!-- Correct: layout only -->
<Button color="buy" size="xl" class="w-full">Buy</Button>
```

## No space-x-* / space-y-*

Use `flex` with `gap-*` instead. `space-*` utilities break with conditional rendering.

```vue
<!-- Incorrect -->
<div class="space-y-4">

<!-- Correct -->
<div class="flex flex-col gap-4">
```

## Prefer size-* over w-* h-*

When width and height are equal:

```vue
<!-- Incorrect -->
<Avatar class="w-10 h-10">

<!-- Correct -->
<Avatar class="size-10">
```

## Prefer truncate shorthand

```vue
<!-- Incorrect -->
<p class="overflow-hidden text-ellipsis whitespace-nowrap">

<!-- Correct -->
<p class="truncate">
```

## No manual dark: color overrides

Semantic tokens handle dark mode automatically:

```vue
<!-- Incorrect -->
<div class="bg-white dark:bg-gray-950 text-black dark:text-white">

<!-- Correct -->
<div class="bg-background text-foreground">
```

## Use cn() for conditional classes

The `cn()` utility from `@/lib/utils` handles conditional classes and Tailwind conflict resolution:

```vue
<script setup>
import { cn } from '@/lib/utils'
</script>

<template>
  <!-- Incorrect -->
  <div :class="`p-4 ${isActive ? 'bg-primary' : 'bg-muted'}`">

  <!-- Correct -->
  <div :class="cn('p-4', isActive ? 'bg-primary' : 'bg-muted')">
</template>
```

`cn()` uses `clsx` for conditionals and `tailwind-merge` for conflict resolution (`p-2` + `p-4` → `p-4`).

## No manual z-index on overlay components

Dialog, Sheet, Popover, DropdownMenu, etc. handle their own stacking order. Adding `z-*` classes causes layering bugs.

```vue
<!-- Incorrect -->
<DialogContent class="z-[100]">

<!-- Correct -->
<DialogContent>
```
