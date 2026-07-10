---
name: accessibility
description: Build WCAG 2.2 AA compliant interfaces — focus management, ARIA utilities, motion preferences, color contrast, screen reader support
user-invocable: true
---

# WCAG 2.2 AA Accessibility

You are an accessibility specialist who ensures all components meet WCAG 2.2 Level AA. The asset pipeline has accessibility built into its defaults — focus rings, motion preferences, color contrast, and ARIA state utilities are all provided out of the box.

## Built-in Defaults

The CSS generator automatically includes these in the `@layer base` block:

### Focus Rings (WCAG 2.4.7 — Focus Visible)

All interactive elements get a visible focus indicator on keyboard navigation:

```css
:focus-visible {
  outline: 2px solid var(--color-blue-500);
  outline-offset: 2px;
}
```

No additional code needed. Every `<button>`, `<a>`, `<input>`, etc. will show a focus ring when tabbed to.

### Reduced Motion (WCAG 2.2.2 — Pause, Stop, Hide / 2.3.1 — Three Flashes)

Animations are disabled when users prefer reduced motion:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Forced Colors (WCAG 1.4.1 — Use of Color)

Focus indicators work in Windows High Contrast mode:

```css
@media (forced-colors: active) {
  :focus-visible {
    outline: 2px solid CanvasText;
  }
}
```

### Color Scheme

```css
:root { color-scheme: light dark; }
```

Tells the browser to adapt form controls, scrollbars, and system colors to the user's preference.

---

## Accessibility Utility Classes

### Screen Reader Content (WCAG 1.1.1 — Non-text Content)

```crystal
# Visually hidden but available to screen readers
span = Components::Elements::Span.new(class: "sr-only")
span << "Close dialog"

# Undo sr-only (e.g., on focus)
link = Components::Elements::A.new(href: "#main", class: "sr-only focus:not-sr-only")
link << "Skip to main content"
```

`sr-only` generates:
```css
.sr-only {
  position: absolute; width: 1px; height: 1px;
  padding: 0; margin: -1px; overflow: hidden;
  clip: rect(0, 0, 0, 0); white-space: nowrap; border-width: 0;
}
```

### Focus Ring Utilities

```
ring                  Default focus ring (3px)
ring-0               No ring
ring-1 through ring-8  Ring width 1-8px
ring-inset           Inset ring
outline-0 through outline-4  Outline width
outline-offset-0 through outline-offset-4  Outline offset
```

Example: `focus-visible:ring-2 focus-visible:ring-blue-500`

### Touch Target Size (WCAG 2.5.8 — Target Size)

Use min-width/min-height utilities to ensure touch targets are at least 44x44px:

```crystal
button = Components::Elements::Button.new("Tap me", type: "button")
button.add_class("min-w-11 min-h-11")  # 2.75rem = 44px
```

---

## ClassBuilder Accessibility Methods

The `ClassBuilder` has dedicated methods for accessibility-related states:

### Focus Visible (WCAG 2.4.7)

```crystal
classes = Components::CSS::ClassBuilder.new
  .base("btn", "btn-primary")
  .focus_visible("ring-2", "ring-blue-500", "outline-none")
  .build
```

Generates: `focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:outline-none`

CSS output: `.focus-visible\:ring-2:focus-visible { box-shadow: 0 0 0 2px ...; }`

### Motion Preferences (WCAG 2.2.2 / 2.3.1)

```crystal
classes = Components::CSS::ClassBuilder.new
  .base("transition-transform")
  .motion_safe("hover:scale-105")     # Only animate if user allows motion
  .motion_reduce("hover:shadow-lg")   # Alternative non-motion effect
  .build
```

CSS output wraps in `@media (prefers-reduced-motion: no-preference)` and `@media (prefers-reduced-motion: reduce)`.

### ARIA State Styling

Style elements based on their ARIA state — no JavaScript needed for visual changes:

```crystal
# Accordion item
classes = Components::CSS::ClassBuilder.new
  .base("accordion-trigger", "p-4", "border-b")
  .aria_expanded("bg-blue-50", "font-semibold")  # When expanded
  .build

# Tab
classes = Components::CSS::ClassBuilder.new
  .base("tab", "px-4", "py-2")
  .aria_selected("border-b-2", "border-blue-500", "text-blue-600")
  .build

# Checkbox label
classes = Components::CSS::ClassBuilder.new
  .base("checkbox-label")
  .aria_checked("text-green-600")
  .build

# Disabled element
classes = Components::CSS::ClassBuilder.new
  .base("btn")
  .aria_disabled("opacity-50", "cursor-not-allowed")
  .build
```

CSS output uses attribute selectors:
```css
.aria-expanded\:bg-blue-50[aria-expanded="true"] { background-color: ...; }
.aria-selected\:border-b-2[aria-selected="true"] { border-bottom-width: 2px; }
```

### Form Validation States

```crystal
classes = Components::CSS::ClassBuilder.new
  .base("input", "border", "rounded")
  .invalid("border-red-500", "text-red-900")
  .valid("border-green-500")
  .build
```

---

## Additional Modifier Prefixes

Beyond ClassBuilder methods, these modifiers work with any utility class:

| Prefix | CSS Selector | WCAG Criterion |
|--------|-------------|----------------|
| `focus-visible:` | `:focus-visible` | 2.4.7 Focus Visible |
| `focus-within:` | `:focus-within` | 2.4.7 (container) |
| `motion-safe:` | `@media (prefers-reduced-motion: no-preference)` | 2.2.2, 2.3.1 |
| `motion-reduce:` | `@media (prefers-reduced-motion: reduce)` | 2.2.2, 2.3.1 |
| `contrast-more:` | `@media (prefers-contrast: more)` | 1.4.6 Enhanced Contrast |
| `forced-colors:` | `@media (forced-colors: active)` | 1.4.1 Use of Color |
| `aria-expanded:` | `[aria-expanded="true"]` | 4.1.2 Name, Role, Value |
| `aria-selected:` | `[aria-selected="true"]` | 4.1.2 |
| `aria-checked:` | `[aria-checked="true"]` | 4.1.2 |
| `aria-disabled:` | `[aria-disabled="true"]` | 4.1.2 |
| `aria-hidden:` | `[aria-hidden="true"]` | 4.1.2 |
| `aria-pressed:` | `[aria-pressed="true"]` | 4.1.2 |
| `aria-busy:` | `[aria-busy="true"]` | 4.1.2 |
| `required:` | `:required` | 3.3.2 Labels or Instructions |
| `invalid:` | `:invalid` | 3.3.1 Error Identification |
| `valid:` | `:valid` | 3.3.1 |
| `checked:` | `:checked` | 4.1.2 |
| `indeterminate:` | `:indeterminate` | 4.1.2 |
| `read-only:` | `:read-only` | 3.3.2 |
| `placeholder-shown:` | `:placeholder-shown` | 3.3.2 |
| `pointer-coarse:` | `@media (pointer: coarse)` | 2.5.5 Target Size |
| `pointer-fine:` | `@media (pointer: fine)` | 2.5.5 |
| `inert:` | `:is([inert], [inert] *)` | 2.4.7 |
| `open:` | `:is([open], details[open])` | 4.1.2 |

---

## Element Validation

Element classes enforce accessibility-relevant attributes at construction time:

### Table Headers

```crystal
# Th validates scope attribute
th = Components::Elements::Th.new(scope: "col")  # Valid: row, col, rowgroup, colgroup
th << "Name"

# Invalid scope raises ArgumentError
Components::Elements::Th.new(scope: "invalid")  # => ArgumentError
```

### Form Labeling

```crystal
# Label with for attribute
label = Components::Elements::Label.new("Email", for: "email-input")
input = Components::Elements::Input.email("email")
input.set_attribute("id", "email-input")
input.set_attribute("aria-describedby", "email-help")

help = Components::Elements::Span.new(id: "email-help", class: "sr-only")
help << "Enter your email address"
```

### Images

```crystal
# Img validates loading and decoding
img = Components::Elements::Img.new(
  src: "/photo.jpg",
  alt: "A sunset over mountains",  # Always provide alt text
  loading: "lazy",                  # Valid: lazy, eager
  decoding: "async"                 # Valid: sync, async, auto
)

# Decorative images
img = Components::Elements::Img.new(src: "/decoration.svg", alt: "", role: "presentation")
```

### Links

```crystal
# A validates target and rel
link = Components::Elements::A.new(
  href: "https://example.com",
  target: "_blank",
  rel: "noopener noreferrer"  # Security + accessibility for external links
)
```

### Form Validation

```crystal
# Form validates method and enctype
form = Components::Elements::Form.new(method: "POST", action: "/submit")

# Input validates type-specific attributes
input = Components::Elements::Input.number("quantity")
input.set_attribute("min", "1")
input.set_attribute("max", "99")
input.set_attribute("required", "true")
input.set_attribute("aria-label", "Quantity")
```

---

## Accessible Component Patterns

### Skip Navigation

```crystal
skip = Components::Elements::A.new(href: "#main-content", class: "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:p-4 focus:bg-white focus:rounded")
skip << "Skip to main content"

# ... header/nav ...

main = Components::Elements::Main.new(id: "main-content")
```

### Landmark Regions

```crystal
# Use semantic elements — they map to ARIA landmarks automatically
Components::Elements::Header.new   # => banner
Components::Elements::Nav.new      # => navigation
Components::Elements::Main.new     # => main
Components::Elements::Aside.new    # => complementary
Components::Elements::Footer.new   # => contentinfo

# Add aria-label to distinguish multiple navs
Components::Elements::Nav.new(class: "breadcrumb").tap { |n| n.set_attribute("aria-label", "Breadcrumb") }
Components::Elements::Nav.new(class: "main-nav").tap { |n| n.set_attribute("aria-label", "Main navigation") }
```

### Accessible Accordion

```crystal
# Uses Details/Summary — native keyboard accessible
details = Components::Elements::Details.new(class: "accordion-item")
summary = Components::Elements::Summary.new(class: "accordion-trigger p-4 cursor-pointer")
summary << "Section Title"
details << summary

content = Components::Elements::Div.new(class: "accordion-content p-4")
content << "Section content here."
details << content
```

Style with ARIA/open states:
```crystal
trigger_classes = Components::CSS::ClassBuilder.new
  .base("accordion-trigger", "p-4", "cursor-pointer")
  .hover("bg-gray-50")
  .focus_visible("ring-2", "ring-blue-500")
  .build
```

### Accessible Dialog

```crystal
dialog = Components::Elements::Dialog.new(class: "modal", id: "confirm-dialog")
dialog.set_attribute("aria-labelledby", "dialog-title")
dialog.set_attribute("aria-describedby", "dialog-desc")

dialog.build do |d|
  h2 = Components::Elements::H2.new(id: "dialog-title")
  h2 << "Confirm Action"
  d << h2

  p = Components::Elements::P.new(id: "dialog-desc")
  p << "Are you sure you want to proceed?"
  d << p

  actions = Components::Elements::Div.new(class: "flex gap-4 justify-end")
  cancel = Components::Elements::Button.new("Cancel", type: "button")
  cancel.set_attribute("data-action", "click->dialog#close")
  confirm = Components::Elements::Button.new("Confirm", type: "button")
  confirm.add_class("btn-primary")
  actions.add_children(cancel, confirm)
  d << actions
end
```

### Accessible Data Table

```crystal
table = Components::Elements::Table.new
table.set_attribute("aria-label", "User accounts")

# Caption for context
caption = Components::Elements::Caption.new
caption << "Active user accounts as of February 2026"
table << caption

# Headers with scope
thead = Components::Elements::Thead.new
tr = Components::Elements::Tr.new
["Name", "Email", "Role", "Status"].each do |col|
  th = Components::Elements::Th.new(scope: "col")
  th << col
  tr << th
end
thead << tr
table << thead
```

### Live Region for Reactive Components

```crystal
# Announce updates to screen readers
status = Components::Elements::Div.new(
  class: "sr-only",
  role: "status"
)
status.set_attribute("aria-live", "polite")
status.set_attribute("aria-atomic", "true")
status << "3 new messages"
```

### Form Error Messages

```crystal
# Associate errors with inputs via aria-describedby
input = Components::Elements::Input.email("email")
input.set_attribute("id", "email")
input.set_attribute("aria-describedby", "email-error")
input.set_attribute("aria-invalid", "true")
input.add_class("border-red-500")

error = Components::Elements::Span.new(id: "email-error", class: "text-red-600 text-sm", role: "alert")
error << "Please enter a valid email address."
```

---

## WCAG 2.2 AA Checklist for Components

When building components, verify:

- [ ] **1.1.1** All images have `alt` text (or `alt=""` + `role="presentation"` for decorative)
- [ ] **1.3.1** Use semantic elements (Nav, Main, Header, Footer, H1-H6, Table with Th scope)
- [ ] **1.4.1** Information not conveyed by color alone (use icons, text, patterns too)
- [ ] **1.4.3** Text contrast ratio >= 4.5:1 (OKLCH colors are designed for this)
- [ ] **2.1.1** All functionality keyboard accessible (use native elements, not div-as-button)
- [ ] **2.4.1** Skip navigation link provided
- [ ] **2.4.7** Focus indicator visible (built-in via `:focus-visible` default)
- [ ] **2.5.8** Touch targets >= 44x44px (`min-w-11 min-h-11`)
- [ ] **3.3.1** Form errors identified with `aria-invalid` + `aria-describedby`
- [ ] **3.3.2** Labels provided for all form inputs (Label with `for`, or `aria-label`)
- [ ] **4.1.2** ARIA states match visual state (use `aria-expanded:`, `aria-selected:`, etc.)
