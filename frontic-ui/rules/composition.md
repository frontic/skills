# Component Composition Rules

Rules for structuring and composing Frontic UI components correctly. These prevent accessibility bugs and ensure consistent rendering.

## Contents

- Items always inside their Group component
- Callouts use Alert
- Empty states use Empty component
- Toast notifications use sonner
- Choosing between overlay components
- Dialog, Sheet, and Drawer always need a Title
- Card structure
- Button loading states
- TabsTrigger inside TabsList
- Avatar needs AvatarFallback
- Use existing components instead of custom markup

## Items always inside their Group component

Menu items, select options, and command items must be wrapped in their Group component.

```vue
<!-- Incorrect -->
<SelectContent>
  <SelectItem value="apple">Apple</SelectItem>
  <SelectItem value="banana">Banana</SelectItem>
</SelectContent>

<!-- Correct -->
<SelectContent>
  <SelectGroup>
    <SelectLabel>Fruits</SelectLabel>
    <SelectItem value="apple">Apple</SelectItem>
    <SelectItem value="banana">Banana</SelectItem>
  </SelectGroup>
</SelectContent>
```

This applies to: `SelectGroup`, `DropdownMenuGroup`, `CommandGroup`, `ContextMenuGroup`, `MenubarGroup`.

## Callouts use Alert

```vue
<!-- Incorrect -->
<div class="rounded-md border p-4">
  <p class="font-medium">Warning</p>
  <p>This action cannot be undone.</p>
</div>

<!-- Correct -->
<Alert variant="destructive">
  <AlertTitle>Warning</AlertTitle>
  <AlertDescription>This action cannot be undone.</AlertDescription>
</Alert>
```

## Empty states use Empty component

```vue
<!-- Incorrect -->
<div class="flex flex-col items-center py-12">
  <p>No results found</p>
</div>

<!-- Correct -->
<Empty>
  <EmptyIcon><SearchIcon /></EmptyIcon>
  <EmptyTitle>No results found</EmptyTitle>
  <EmptyDescription>Try a different search term.</EmptyDescription>
</Empty>
```

## Toast notifications use sonner

```vue
<script setup>
import { toast } from 'sonner'

function handleClick() {
  toast.success('Item added to cart')
}
</script>
```

Never build custom toast UI.

## Choosing between overlay components

| Component | Use when |
|-----------|----------|
| `Dialog` | User must make a decision or provide input. Blocks interaction with the page. |
| `Sheet` | Showing supplementary content (filters, settings). Slides in from the side. |
| `Drawer` | Bottom sheet on mobile for quick actions. |
| `AlertDialog` | Confirming a destructive action. Has explicit cancel/confirm. |
| `Popover` | Contextual info attached to a trigger. Non-modal. |

## Dialog, Sheet, and Drawer always need a Title

```vue
<!-- Incorrect: no title -->
<DialogContent>
  <p>Are you sure?</p>
</DialogContent>

<!-- Correct -->
<DialogContent>
  <DialogHeader>
    <DialogTitle>Confirm action</DialogTitle>
  </DialogHeader>
  <p>Are you sure?</p>
</DialogContent>

<!-- If visually hidden -->
<DialogContent>
  <DialogHeader>
    <DialogTitle class="sr-only">Confirm action</DialogTitle>
  </DialogHeader>
  <p>Are you sure?</p>
</DialogContent>
```

## Card structure

Always use the full composition -- don't put everything in a single container.

```vue
<!-- Incorrect -->
<Card>
  <div class="p-6">
    <h3>Title</h3>
    <p>Description</p>
    <p>Content here</p>
    <Button>Action</Button>
  </div>
</Card>

<!-- Correct -->
<Card>
  <CardHeader>
    <CardTitle>Title</CardTitle>
    <CardDescription>Description</CardDescription>
  </CardHeader>
  <CardContent>
    <p>Content here</p>
  </CardContent>
  <CardFooter>
    <Button>Action</Button>
  </CardFooter>
</Card>
```

## Button loading states

Button has no `isPending` or `isLoading` prop. Compose with Spinner:

```vue
<Button :disabled="loading">
  <Spinner v-if="loading" data-icon="inline-start" />
  {{ loading ? 'Saving...' : 'Save' }}
</Button>
```

## TabsTrigger inside TabsList

```vue
<!-- Incorrect -->
<Tabs default-value="tab1">
  <TabsTrigger value="tab1">Tab 1</TabsTrigger>
  <TabsContent value="tab1">Content</TabsContent>
</Tabs>

<!-- Correct -->
<Tabs default-value="tab1">
  <TabsList>
    <TabsTrigger value="tab1">Tab 1</TabsTrigger>
  </TabsList>
  <TabsContent value="tab1">Content</TabsContent>
</Tabs>
```

## Avatar always needs AvatarFallback

```vue
<Avatar>
  <AvatarImage :src="user.avatar" :alt="user.name" />
  <AvatarFallback>{{ user.initials }}</AvatarFallback>
</Avatar>
```

## Use existing components instead of custom markup

| Instead of | Use |
|-----------|-----|
| `<hr>` or `<div class="border-t">` | `<Separator />` |
| Custom loading placeholder | `<Skeleton />` |
| Styled `<span>` for tags | `<Badge>` with commerce colors |
| Custom alert div | `<Alert>` |
| Custom empty state div | `<Empty>` |
