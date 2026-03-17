# Icon Rules

Rules for using icons in Frontic UI components.

## Import from the configured icon library

Check the project's `iconLibrary` field in `components.json` or `npx @frontic/ui info`. Don't assume `lucide-vue-next`.

| iconLibrary | Package | Import example |
|-------------|---------|----------------|
| `lucide` | `lucide-vue-next` | `import { SearchIcon } from 'lucide-vue-next'` |
| `tabler` | `@tabler/icons-vue` | `import { IconSearch } from '@tabler/icons-vue'` |
| `hugeicons` | `@hugeicons/vue` | `import { Search01Icon } from '@hugeicons/core-free-icons'` |
| `phosphor` | `@phosphor-icons/vue` | `import { MagnifyingGlass } from '@phosphor-icons/vue'` |
| `remixicon` | `@remixicon/vue` | `import { RiSearchLine } from '@remixicon/vue'` |

## Icons in Button use data-icon attribute

```vue
<!-- Incorrect -->
<Button>
  <SearchIcon class="mr-2 size-4" />
  Search
</Button>

<!-- Correct -->
<Button>
  <SearchIcon data-icon="inline-start" />
  Search
</Button>

<!-- Icon after text -->
<Button>
  Next
  <ArrowRightIcon data-icon="inline-end" />
</Button>
```

## No sizing classes on icons inside components

Components handle icon sizing via CSS targeting `[data-icon]`. Adding size classes creates conflicts.

```vue
<!-- Incorrect -->
<Button size="sm">
  <PlusIcon class="size-4" data-icon="inline-start" />
  Add
</Button>

<!-- Correct -->
<Button size="sm">
  <PlusIcon data-icon="inline-start" />
  Add
</Button>
```

## Migrate between libraries

When switching icon libraries:

```bash
npx @frontic/ui migrate icons
```

This transforms all icon imports across your installed components.
