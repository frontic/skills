# MCP Server

The Frontic UI MCP server gives coding agents direct access to browse, search, view, and install components from the registry.

## Setup

Check if the `frontic-ui` MCP server is connected by looking for tools prefixed with `mcp__frontic-ui__`. If not running:

**Option 1: Auto-setup (recommended)**
```bash
npx @frontic/ui mcp init --client claude
# Also supports: --client cursor, --client vscode, --client codex, --client opencode
```

**Option 2: Manual `.mcp.json`**

Hosted (no install needed):
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

Local (stdio transport):
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

## Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `get_design_system` | Full design system overview: styles, presets, fonts, icons, commerce colors, block categories | **Start here** — understand what's available before building |
| `get_theme` | CSS custom property definitions (OKLCH) for light and dark mode | When you need exact color token values |
| `get_blocks` | Browse pre-built commerce blocks by category | Exploring what blocks exist for a page type |
| `get_block_source` | Full source code of all files in a block | Understanding how a block works before installing |
| `scaffold_storefront` | Step-by-step build plan with CLI commands and file structure | Starting a new storefront from scratch |
| `list_registry_items` | Browse all components/blocks with pagination, filter by type | Exploring what's available |
| `search_registry_items` | Fuzzy search by name/description | Looking for a specific component |
| `view_registry_items` | Full component source, deps, and metadata | Before using a component — see its props, variants, files |
| `get_item_examples` | Working demo code with complete Vue source | Need usage examples for a component |
| `get_add_command` | CLI install command for one or more items | Ready to install a component or block |
| `get_component_variants` | CVA variant keys, values, and defaults | Before using a component — discover available variant, size, color props |
| `get_audit_checklist` | Post-install QA checklist (Nuxt-specific) | After adding components, verify setup |
| `get_project_config` | Read `components.json` project config (local mode only) | Check the project's configured style and preferences |

## Workflows

### Starting a Storefront
1. `get_design_system` → see all styles, presets, options
2. `scaffold_storefront` → get a build plan with CLI commands
3. Execute the plan
4. `get_audit_checklist` → verify setup

### Adding a Component
1. `search_registry_items` → find what you need
2. `view_registry_items` → inspect source, props, variants
3. `get_component_variants` → see CVA variant keys/values/defaults
4. `get_item_examples` → usage patterns
5. `get_add_command` → get the install command, run it

### Adding Blocks
1. `get_blocks` → browse by category (cart, checkout, product, category, search, layout, navigation)
2. `get_block_source` → see all files in the block
3. `get_add_command` → get the install command, run it
4. Customize — blocks install as regular Vue files

## Configuring Registries

Custom registries can be added in `components.json`:

```json
{
  "registries": {
    "@custom": "https://registry.example.com/r/{name}.json"
  }
}
```

The `@frontic` registry is always available as a built-in.
