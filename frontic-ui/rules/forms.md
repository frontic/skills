# Form Rules

Rules for building forms with Frontic UI. These ensure consistent layout, accessibility, and validation patterns.

## Contents

- Forms use FieldGroup + Field
- InputGroup requires InputGroupInput/InputGroupTextarea
- Buttons inside inputs use InputGroup + InputGroupAddon
- Option sets use ToggleGroup
- FieldSet + FieldLegend for grouping
- Field validation and disabled states

## Forms use FieldGroup + Field

Never use raw `<div>` with `space-y-*` for form layout.

```vue
<!-- Incorrect -->
<div class="space-y-4">
  <div>
    <label>Name</label>
    <Input />
  </div>
</div>

<!-- Correct -->
<FieldGroup>
  <Field>
    <FieldLabel for="name">Name</FieldLabel>
    <Input id="name" />
  </Field>
  <Field>
    <FieldLabel for="email">Email</FieldLabel>
    <Input id="email" type="email" />
    <FieldDescription>We'll never share your email.</FieldDescription>
  </Field>
</FieldGroup>
```

## InputGroup requires InputGroupInput/InputGroupTextarea

Never use raw `Input` or `Textarea` inside `InputGroup`.

```vue
<!-- Incorrect -->
<InputGroup>
  <Input placeholder="Search..." />
</InputGroup>

<!-- Correct -->
<InputGroup>
  <InputGroupInput placeholder="Search..." />
</InputGroup>
```

## Buttons inside inputs use InputGroup + InputGroupAddon

```vue
<!-- Incorrect -->
<div class="relative">
  <Input class="pr-10" />
  <Button class="absolute right-0 top-0">Go</Button>
</div>

<!-- Correct -->
<InputGroup>
  <InputGroupInput placeholder="Search..." />
  <InputGroupAddon>
    <Button size="sm">Go</Button>
  </InputGroupAddon>
</InputGroup>
```

## Option sets (2-7 choices) use ToggleGroup

Don't loop `Button` with manual active state management.

```vue
<!-- Incorrect -->
<div class="flex gap-2">
  <Button
    v-for="size in sizes"
    :key="size"
    :variant="selected === size ? 'default' : 'outline'"
    @click="selected = size"
  >
    {{ size }}
  </Button>
</div>

<!-- Correct -->
<ToggleGroup v-model="selected" type="single">
  <ToggleGroupItem v-for="size in sizes" :key="size" :value="size">
    {{ size }}
  </ToggleGroupItem>
</ToggleGroup>
```

## FieldSet + FieldLegend for grouping

Use for related checkboxes, radios, or form sections.

```vue
<!-- Incorrect -->
<div>
  <h3>Notifications</h3>
  <Checkbox id="email-notif" />
  <label for="email-notif">Email</label>
</div>

<!-- Correct -->
<FieldSet>
  <FieldLegend>Notifications</FieldLegend>
  <Field>
    <Checkbox id="email-notif" />
    <FieldLabel for="email-notif">Email</FieldLabel>
  </Field>
  <Field>
    <Checkbox id="sms-notif" />
    <FieldLabel for="sms-notif">SMS</FieldLabel>
  </Field>
</FieldSet>
```

## Field validation and disabled states

Validation and disabled states use both data attributes (for CSS styling) and ARIA attributes (for accessibility):

```vue
<!-- Validation error -->
<Field data-invalid>
  <FieldLabel>Email</FieldLabel>
  <Input aria-invalid />
  <FieldDescription>Please enter a valid email.</FieldDescription>
</Field>

<!-- Disabled -->
<Field data-disabled>
  <FieldLabel>Email</FieldLabel>
  <Input disabled />
</Field>
```

`data-invalid` / `data-disabled` go on `Field` (for styling). `aria-invalid` / `disabled` go on the control (for accessibility).
