# Frontic UI CLI

Reference for the `@frontic/ui` command-line tool. All examples use `npx @frontic/ui` — substitute the correct runner for the project's package manager.

## Contents

- [Commands](#commands): init, create, add, diff, docs, info, search, view, build, migrate, skills, mcp
- [Templates](#templates): nuxt, vite
- [Presets](#presets): Named presets and encoded preset codes
- [Switching Presets](#switching-presets)

## Commands

### init

Initialize Frontic UI in an existing project.

```bash
npx @frontic/ui init
npx @frontic/ui init --preset reka-nova
npx @frontic/ui init --preset v1a2Dg5 --theme-color 0.75_0.11_120:0.88_0.10_120
npx @frontic/ui init --defaults  # shortcut: reka, vega, lucide, inter
```

| Flag | Description |
|------|-------------|
| `--preset <code>` | Named preset or encoded preset code |
| `--style <style>` | Visual style (vega, nova, maia, lyra, mira, oregon) |
| `--base <base>` | Component base (reka) |
| `--font <font>` | Font (inter, geist, figtree, jetbrains-mono, geist-mono, + 8 more) |
| `--icon-library <lib>` | Icon library (lucide, tabler, hugeicons, phosphor, remixicon) |
| `-b, --base-color <color>` | Base gray (neutral, gray, zinc, stone, slate) |
| `--commerce-palette <palette>` | Commerce color palette (default, warm, cool, bold, monochrome, nature, ocean, sunset, berry) |
| `--theme-color <oklch>` | Custom primary color (encoded OKLCH `light:dark`) |
| `--commerce-buy <oklch>` | Override buy token (encoded OKLCH `light:dark`) |
| `--commerce-checkout <oklch>` | Override checkout token |
| `--commerce-promo <oklch>` | Override promo token |
| `--commerce-discount <oklch>` | Override discount token |
| `--commerce-new <oklch>` | Override new token |
| `--commerce-price <oklch>` | Override price token |
| `--commerce-active <oklch>` | Override active token |
| `--commerce-info <oklch>` | Override info token |
| `--commerce-positive <oklch>` | Override positive token |
| `--commerce-warning <oklch>` | Override warning token |
| `--dark-mode / --no-dark-mode` | Include dark mode support (off by default) |
| `-t, --template <template>` | Project template (nuxt, vite) |
| `--monorepo` | Set up as monorepo |
| `-y, --yes` | Skip confirmation |
| `-d, --defaults` | Use defaults (nuxt, reka, vega, lucide, inter) |
| `-f, --force` | Force overwrite |
| `-s, --silent` | Mute output |

### create

Create a new project with Frontic UI.

```bash
npx @frontic/ui create my-store
npx @frontic/ui create my-store --preset reka-nova
npx @frontic/ui create my-store --preset v1a2Dg5 --commerce-palette warm
npx @frontic/ui create --open  # opens visual creator at ui.frontic.com/create
```

Accepts all `init` flags plus:
| Flag | Description |
|------|-------------|
| `--open` | Open visual creator in browser |

### add

Add components, blocks, or registry items to the project.

```bash
npx @frontic/ui add button card dialog
npx @frontic/ui add filter rating swatch
npx @frontic/ui add --all
npx @frontic/ui add @frontic/product-card-01
```

| Flag | Description |
|------|-------------|
| `-y, --yes` | Skip confirmation |
| `-o, --overwrite` | Overwrite existing files |
| `-a, --all` | Add all available components |
| `-p, --path <path>` | Custom installation path |
| `--dry-run` | Show what would happen without writing files |
| `--diff` | Show diffs of files that would change |
| `--view [path]` | Show full content of files that would be written |

#### Dry-run flags

Use these to inspect changes before they happen:

```bash
# Summary of what would change
npx @frontic/ui add button --dry-run

# Unified diff showing changes
npx @frontic/ui add button --diff

# Full file contents
npx @frontic/ui add button --view
```

### diff

Check for registry updates on installed components.

```bash
npx @frontic/ui diff           # Check all installed components
npx @frontic/ui diff button    # Check specific component
```

### docs

Get documentation, examples, and API links for components.

```bash
npx @frontic/ui docs button
npx @frontic/ui docs button dialog select
npx @frontic/ui docs button --json
npx @frontic/ui docs button --open  # opens in browser
```

### info

Display project configuration and installed components.

```bash
npx @frontic/ui info
npx @frontic/ui info --json
```

Shows: framework, style, base, font, icon library, tailwind config, path aliases, installed components with docs links.

### search (alias: list)

Search across registries for components and blocks.

```bash
npx @frontic/ui search @frontic -q "filter"
npx @frontic/ui search @frontic -q "product" --limit 20
```

### view

View registry item details as JSON.

```bash
npx @frontic/ui view button
npx @frontic/ui view @frontic/filter
```

### build

Build a custom registry from a `registry.json` file.

```bash
npx @frontic/ui build
npx @frontic/ui build ./registry.json --output ./public/r
```

### migrate

Run migrations on installed components.

```bash
npx @frontic/ui migrate --list          # List available migrations
npx @frontic/ui migrate icons           # Switch icon library
npx @frontic/ui migrate rtl             # Convert to logical properties for RTL
```

**Available migrations:**
- `icons` — Migrate between icon libraries (lucide → tabler, etc.)
- `rtl` — Convert directional Tailwind classes (`ml-*` → `ms-*`, `rounded-l` → `rounded-s`, etc.)

### skills

Install agent context files for coding assistants.

```bash
npx @frontic/ui skills list                     # List available skills
npx @frontic/ui skills add                      # Install all skills (Claude)
npx @frontic/ui skills add frontic-ui           # Install specific skill
npx @frontic/ui skills add --client cursor      # Install for Cursor
```

### mcp

Manage the MCP server for AI assistants.

```bash
npx @frontic/ui mcp init --client claude    # Set up MCP for Claude Code
npx @frontic/ui mcp init --client cursor    # Set up MCP for Cursor
npx @frontic/ui mcp init --client claude --local  # Use local stdio transport
npx @frontic/ui mcp                         # Start MCP server (stdio)
```

## Templates

```bash
npx @frontic/ui init --template nuxt
npx @frontic/ui init --template nuxt --monorepo
npx @frontic/ui init --template vite
```

## Presets

Presets bundle a style + icon library + font into a ready-to-use configuration.

**Named presets:**

| Preset | Style | Icons | Font |
|--------|-------|-------|------|
| `reka-vega` | Vega (classic) | Lucide | Inter |
| `reka-nova` | Nova (compact) | Hugeicons | Inter |
| `reka-maia` | Maia (soft/rounded) | Hugeicons | Figtree |
| `reka-lyra` | Lyra (sharp/boxy) | Hugeicons | JetBrains Mono |
| `reka-mira` | Mira (dense) | Hugeicons | Inter |
| `reka-oregon` | Oregon (bold/editorial) | Lucide | Geist |

**Encoded preset codes:** Compact base62 strings (e.g., `v1a2Dg5`) that encode style, base color, icon library, font, menu accent, menu color, commerce palette, radius, and dark mode. Generated from [ui.frontic.com/create](https://ui.frontic.com/create).

```bash
npx @frontic/ui init --preset reka-nova
npx @frontic/ui init --preset v1a2Dg5
```

## Switching Presets

Re-running `init --preset` on an existing project reconfigures everything including installed components:

```bash
npx @frontic/ui init --preset reka-nova
```

This updates `components.json`, re-applies CSS variables, and re-transforms all installed components to the new style.
