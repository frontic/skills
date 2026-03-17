---
name: frontic-ui
description: >
  Manages Frontic UI components and projects — adding, searching, fixing, debugging, styling,
  and composing e-commerce UI. Provides project context, component docs, and usage examples.
  Applies when working with Frontic UI, shadcn-vue, component registries, presets, --preset
  codes, or any project with a components.json file. Also triggers for "frontic-ui init",
  "create a storefront with --preset", "switch to --preset", component theming, commerce
  colors, reka-ui, visual styles, or design system configuration.
user-invocable: false
---

# Frontic UI

A Vue component registry for building e-commerce UI and design systems. Built on top of shadcn-vue and reka-ui. Components are added as source code to the user's project via the CLI.

> **IMPORTANT:** Run all CLI commands using the project's package runner: `npx @frontic/ui`, `pnpm dlx @frontic/ui`, or `bunx @frontic/ui` — based on the project's `packageManager`. Examples below use `npx @frontic/ui` but substitute the correct runner for the project.

## Current Project Context

```json
!`npx @frontic/ui info --json 2>/dev/null || echo '{"error": "No Frontic UI project found. Run @frontic/ui init first."}'`
```

The JSON above contains the project config and installed components. Use `npx @frontic/ui docs <component>` to get documentation and example URLs for any component.

## Principles

1. **Use existing components first.** Use `npx @frontic/ui search` to check the registry before writing custom UI. The Frontic registry includes the full shadcn-vue catalog plus commerce-specific components.
2. **Compose, don't reinvent.** Product page = Card + Rating + Swatch + Button. Checkout = Form + Card + RadioStack. Dashboard = Sidebar + Card + Table.
3. **Use built-in variants before custom styles.** `variant="outline"`, `size="sm"`, `color="buy"`, etc.
4. **Use semantic colors.** `bg-primary`, `text-muted-foreground`, `text-buy` — never raw values like `bg-blue-500`.

## Critical Rules

These rules are **always enforced**. Each links to a file with Incorrect/Correct code pairs.

### Styling & Tailwind → [styling.md](./rules/styling.md)

- **`class` for layout, not styling.** Never override component colors or typography via class.
- **No `space-x-*` or `space-y-*`.** Use `flex` with `gap-*`. For vertical stacks, `flex flex-col gap-*`.
- **Use `size-*` when width and height are equal.** `size-10` not `w-10 h-10`.
- **Use `truncate` shorthand.** Not `overflow-hidden text-ellipsis whitespace-nowrap`.
- **No manual `dark:` color overrides.** Use semantic tokens (`bg-background`, `text-muted-foreground`).
- **Use `cn()` for conditional classes.** Don't write manual template literal ternaries.
- **No manual `z-index` on overlay components.** Dialog, Sheet, Popover, etc. handle their own stacking.
- **Use commerce colors for e-commerce semantics.** `color="buy"` not a custom green class.

### Forms & Inputs → [forms.md](./rules/forms.md)

- **Forms use `FieldGroup` + `Field`.** Never use raw `div` with `space-y-*` for form layout.
- **`InputGroup` uses `InputGroupInput`/`InputGroupTextarea`.** Never raw `Input`/`Textarea` inside `InputGroup`.
- **Buttons inside inputs use `InputGroup` + `InputGroupAddon`.**
- **Option sets (2–7 choices) use `ToggleGroup`.** Don't loop `Button` with manual active state.
- **`FieldSet` + `FieldLegend` for grouping related checkboxes/radios.**
- **Field validation uses `data-invalid` + `aria-invalid`.** `data-invalid` on `Field`, `aria-invalid` on the control.

### Component Structure → [composition.md](./rules/composition.md)

- **Items always inside their Group.** `SelectItem` → `SelectGroup`. `DropdownMenuItem` → `DropdownMenuGroup`. `CommandItem` → `CommandGroup`.
- **Use `asChild` for custom triggers.** Frontic uses reka-ui which supports `asChild` like Radix.
- **Dialog, Sheet, and Drawer always need a Title.** `DialogTitle`, `SheetTitle`, `DrawerTitle` required for accessibility. Use `class="sr-only"` if visually hidden.
- **Use full Card composition.** `CardHeader`/`CardTitle`/`CardDescription`/`CardContent`/`CardFooter`. Don't dump everything in `CardContent`.
- **Button has no `isPending`/`isLoading`.** Compose with `Spinner` + `data-icon` + `disabled`.
- **`TabsTrigger` must be inside `TabsList`.** Never render triggers directly in `Tabs`.
- **`Avatar` always needs `AvatarFallback`.** For when the image fails to load.

### Use Components, Not Custom Markup → [composition.md](./rules/composition.md)

- **Use existing components before custom markup.** Check if a component exists before writing a styled `div`.
- **Callouts use `Alert`.** Don't build custom styled divs.
- **Empty states use `Empty`.** Don't build custom empty state markup.
- **Toast via `sonner`.** Use `toast()` from `sonner`.
- **Use `Separator`** instead of `<hr>` or `<div class="border-t">`.
- **Use `Skeleton`** for loading placeholders. No custom `animate-pulse` divs.
- **Use `Badge`** instead of custom styled spans. Use commerce colors: `<Badge color="promo">`.

### Icons → [icons.md](./rules/icons.md)

- **Icons in `Button` use `data-icon`.** `data-icon="inline-start"` or `data-icon="inline-end"` on the icon.
- **No sizing classes on icons inside components.** Components handle icon sizing via CSS. No `size-4` or `w-4 h-4`.
- **Import from the configured `iconLibrary`.** Check `components.json` — use `lucide-vue-next`, `@tabler/icons-vue`, `@hugeicons/vue`, etc.

### CLI

- **Never decode or fetch preset codes manually.** Pass them directly to `npx @frontic/ui init --preset <code>`.

## Key Patterns

These are the most common patterns that differentiate correct Frontic UI code. For edge cases, see the linked rule files above.

```vue
<!-- Form layout: FieldGroup + Field, not div + Label. -->
<FieldGroup>
  <Field>
    <FieldLabel for="email">Email</FieldLabel>
    <Input id="email" />
  </Field>
</FieldGroup>

<!-- Validation: data-invalid on Field, aria-invalid on the control. -->
<Field data-invalid>
  <FieldLabel>Email</FieldLabel>
  <Input aria-invalid />
  <FieldDescription>Invalid email.</FieldDescription>
</Field>

<!-- Icons in buttons: data-icon, no sizing classes. -->
<Button>
  <SearchIcon data-icon="inline-start" />
  Search
</Button>

<!-- Spacing: gap-*, not space-y-*. -->
<div class="flex flex-col gap-4">  <!-- correct -->
<div class="space-y-4">           <!-- wrong -->

<!-- Commerce colors on components. -->
<Button color="buy" size="xl">Add to Cart</Button>
<Badge color="promo">-20%</Badge>
<Badge color="new" variant="subtle">New</Badge>
```

## Component Selection

| Need | Use |
|------|-----|
| Button/action | `Button` with variant + `color` (buy, checkout, positive, destructive) |
| Form inputs | `Input`, `Select`, `Combobox`, `Switch`, `Checkbox`, `RadioGroup`, `Textarea`, `InputOTP`, `Slider` |
| Toggle between 2–5 options | `ToggleGroup` + `ToggleGroupItem` |
| Product filtering | `Filter`, `RangeSlider`, `Swatch`, `SwatchGroup` |
| Ratings | `Rating` with half-star support |
| Shipping/payment selection | `RadioStack` |
| Category navigation | `MegaMenu` |
| Data display | `Table`, `Card`, `Badge`, `Avatar` |
| Navigation | `Sidebar`, `NavigationMenu`, `Breadcrumb`, `Tabs`, `Pagination` |
| Overlays | `Dialog` (modal), `Sheet` (side panel), `Drawer` (bottom sheet), `AlertDialog` (confirmation) |
| Feedback | `sonner` (toast), `Alert`, `Progress`, `Skeleton`, `Spinner` |
| Command palette | `Command` inside `Dialog` |
| Layout | `Card`, `Separator`, `Resizable`, `ScrollArea`, `Accordion`, `Collapsible` |
| Empty states | `Empty` |
| Menus | `DropdownMenu`, `ContextMenu`, `Menubar` |
| Tooltips/info | `Tooltip`, `HoverCard`, `Popover` |

## Key Fields

The injected project context contains these key fields:

- **`aliases`** → use the actual alias prefix for imports (e.g. `@/`, `~/`), never hardcode.
- **`tailwind.cssVariables`** → when `true`, uses CSS custom properties for theming.
- **`tailwind.darkMode`** → whether dark mode is enabled (off by default for storefronts).
- **`tailwind.css`** → the global CSS file where custom CSS variables are defined. Always edit this file, never create a new one.
- **`style`** → component visual treatment (`vega`, `nova`, `maia`, `lyra`, `mira`, `oregon`).
- **`base`** → primitive library (`reka` — the only option in Frontic).
- **`iconLibrary`** → determines icon imports. `lucide-vue-next` for `lucide`, `@tabler/icons-vue` for `tabler`, etc.
- **`resolvedPaths`** → exact file-system destinations for components, utils, composables, etc.
- **`font`** → configured font (inter, geist, figtree, etc.).
- **`installedComponents`** → list of components already installed in the project.

See [cli.md — `info` command](./cli.md) for the full field reference.

## Component Docs, Examples, and Usage

Run `npx @frontic/ui docs <component>` to get the URLs for a component's documentation, examples, and API reference. Fetch these URLs to get the actual content.

```bash
npx @frontic/ui docs button dialog select
```

**When creating, fixing, debugging, or using a component, always run `npx @frontic/ui docs` and fetch the URLs first.** This ensures you're working with the correct API and usage patterns.

## Workflow

1. **Get project context** — already injected above. Run `npx @frontic/ui info` again if you need to refresh.
2. **Check installed components first** — before running `add`, check the `installedComponents` list from project context or list the `resolvedPaths.ui` directory.
3. **Find components** — `npx @frontic/ui search @frontic -q "filter"`.
4. **Get docs and examples** — run `npx @frontic/ui docs <component>` to get URLs, then fetch them.
5. **Install or update** — `npx @frontic/ui add`. When updating, use `--dry-run` and `--diff` to preview changes first.
6. **Review added components** — After adding a component, **always read the added files and verify they are correct**. Check for missing sub-components, incorrect composition, or violations of the [Critical Rules](#critical-rules). Also verify icon imports match the project's `iconLibrary`.
7. **Switching presets** — `npx @frontic/ui init --preset <code>` on an existing project re-transforms all installed components to the new style.

## Updating Components

When the user asks to update a component while keeping their local changes, use `--dry-run` and `--diff` to intelligently merge. **NEVER fetch raw files from GitHub manually — always use the CLI.**

1. Run `npx @frontic/ui add <component> --dry-run` to see all files that would be affected.
2. Run `npx @frontic/ui add <component> --diff` to see what changed upstream vs local.
3. Decide per file based on the diff:
   - No local changes → safe to overwrite.
   - Has local changes → read the local file, analyze the diff, and apply upstream updates while preserving local modifications.
4. **Never use `--overwrite` without the user's explicit approval.**

## Quick Reference

```bash
# Create a new project.
npx @frontic/ui create my-store --preset reka-vega
npx @frontic/ui create my-store --preset v1a2Dg5 --commerce-palette warm

# Initialize existing project.
npx @frontic/ui init --preset reka-nova
npx @frontic/ui init --preset v1a2Dg5 --theme-color 0.75_0.11_120:0.88_0.10_120

# Add components.
npx @frontic/ui add button card dialog filter rating swatch
npx @frontic/ui add --all

# Preview changes before adding/updating.
npx @frontic/ui add button --dry-run
npx @frontic/ui add button --diff
npx @frontic/ui add button --view

# Search registry.
npx @frontic/ui search @frontic -q "filter"

# Get component docs.
npx @frontic/ui docs button dialog select

# Project info.
npx @frontic/ui info

# Install agent skills.
npx @frontic/ui skills add

# Migrate icon library or add RTL support.
npx @frontic/ui migrate icons
npx @frontic/ui migrate rtl
```

**Named presets:** `reka-vega`, `reka-nova`, `reka-maia`, `reka-lyra`, `reka-mira`, `reka-oregon`
**Preset codes:** Base62 strings starting with `v1` (e.g. `v1a2Dg5`), from [ui.frontic.com/create](https://ui.frontic.com/create).
**Visual styles:** vega (classic), nova (compact), maia (soft/rounded), lyra (sharp/boxy), mira (dense), oregon (bold/editorial)
**Commerce palettes:** default, warm, cool, bold, monochrome, nature, ocean, sunset, berry

## Detailed References

- [rules/forms.md](./rules/forms.md) — FieldGroup, Field, InputGroup, ToggleGroup, FieldSet, validation states
- [rules/composition.md](./rules/composition.md) — Groups, overlays, Card, Tabs, Avatar, Alert, Empty, Toast, Separator, Skeleton, Badge, Button loading
- [rules/icons.md](./rules/icons.md) — data-icon, icon sizing, icon library imports
- [rules/styling.md](./rules/styling.md) — Semantic colors, commerce colors, variants, class, spacing, size, truncate, dark mode, cn(), z-index
- [cli.md](./cli.md) — Commands, flags, presets, templates, encoded presets
- [customization.md](./customization.md) — Theming, CSS variables, commerce color tokens, extending components
- [mcp.md](./mcp.md) — MCP server setup, 13 tools, workflows

## Related Skills

- **nuxt-storefront-architect** — Data fetching (`useFronticSearch`, `useFronticBlock`, `useFronticListing`), page routing, content management, i18n, project structure. Use it when wiring components to data.
- **commerce-ux-patterns** — Interaction design: feedback patterns (toast vs inline vs redirect), conversion optimization, and edge cases. Use it when deciding *how* a feature should behave.
- **create-frontic-ui-block** — Creating new blocks for the Frontic UI registry. Use it when authoring reusable, installable compositions.
