---
name: css-styling
description: Style components with the CSS engine — ClassBuilder DSL, Styleable mixin, utility classes, design tokens, and component CSS
user-invocable: true
---

# CSS Styling with the Asset Pipeline

You are a CSS specialist who styles Crystal components using the asset pipeline's utility-first CSS engine. The engine generates CSS from class names, supports responsive breakpoints, pseudo-states, ARIA states, dark mode, and WCAG 2.2 AA accessibility defaults. Colors use the OKLCH color space.

## ClassBuilder DSL

Build CSS class strings with a fluent API. Classes are automatically registered with the ClassRegistry for CSS generation.

```crystal
classes = Components::CSS::ClassBuilder.new
  .base("flex", "items-center", "gap-4")
  .hover("shadow-lg")
  .focus_visible("ring-2", "ring-blue-500")
  .dark("bg-gray-800", "text-gray-100")
  .responsive { |r|
    r.sm("flex-col")
    r.lg("flex-row")
  }
  .build
# => "flex items-center gap-4 hover:shadow-lg focus-visible:ring-2 focus-visible:ring-blue-500 dark:bg-gray-800 dark:text-gray-100 sm:flex-col lg:flex-row"
```

### All ClassBuilder Methods

| Method | Purpose | CSS Output |
|--------|---------|------------|
| `.base(*classes)` | Foundation classes | Classes as-is |
| `.add(classes, condition?)` | Conditional add | Classes if condition true |
| `.when(condition, classes)` | Add if true | Classes if condition true |
| `.unless(condition, classes)` | Add if false | Classes if condition false |
| `.hover(classes)` | Mouse hover | `hover:` prefix |
| `.focus(classes)` | Any focus | `focus:` prefix |
| `.active(classes)` | Active/pressed | `active:` prefix |
| `.disabled(classes)` | Disabled state | `disabled:` prefix |
| `.dark(classes)` | Dark color scheme | `dark:` prefix |
| `.focus_visible(classes)` | Keyboard focus (WCAG 2.4.7) | `focus-visible:` prefix |
| `.focus_within(classes)` | Child has focus | `focus-within:` prefix |
| `.motion_safe(classes)` | No motion preference (WCAG 2.2.2) | `motion-safe:` prefix |
| `.motion_reduce(classes)` | Prefers reduced motion | `motion-reduce:` prefix |
| `.aria_expanded(classes)` | aria-expanded="true" | `aria-expanded:` prefix |
| `.aria_selected(classes)` | aria-selected="true" | `aria-selected:` prefix |
| `.aria_checked(classes)` | aria-checked="true" | `aria-checked:` prefix |
| `.aria_disabled(classes)` | aria-disabled="true" | `aria-disabled:` prefix |
| `.invalid(classes)` | Form invalid state | `invalid:` prefix |
| `.valid(classes)` | Form valid state | `valid:` prefix |
| `.responsive { \|r\| ... }` | Breakpoint variants | `sm:`, `md:`, `lg:`, `xl:`, `xxl:` |
| `.build` | Returns deduped class string | Registers with ClassRegistry |

### ResponsiveBuilder

Inside the `.responsive` block:

```crystal
.responsive { |r|
  r.sm("text-sm")      # >= 640px
  r.md("text-base")    # >= 768px
  r.lg("text-lg")      # >= 1024px
  r.xl("text-xl")      # >= 1280px
  r.xxl("text-2xl")    # >= 1536px
}
```

---

## Styleable Mixin

Include `Components::CSS::Styleable` in components for convenience methods.

### `css { |c| ... }`

Shorthand for ClassBuilder — creates builder, yields it, calls `.build`:

```crystal
class MyComponent < Components::StatelessComponent
  include Components::CSS::Styleable

  def render_content : String
    wrapper_classes = css { |c|
      c.base("card", "rounded-lg", "shadow-md")
      c.hover("shadow-xl")
      c.dark("bg-gray-800")
    }
    Components::Elements::Div.new(class: wrapper_classes).build { |d|
      d << "Content"
    }.render
  end
end
```

### `class_names(**options)`

Conditional class helper — includes class when value is truthy:

```crystal
class_names(
  "btn" => true,
  "btn-primary" => variant == "primary",
  "btn-disabled" => disabled?,
  "btn-lg" => size == "large"
)
# => "btn btn-primary" (if variant is "primary" and not disabled/large)
```

Values can be `String` (always included), `Bool`, or `Array(String)`.

### `variant_classes(base, variant?, size?, state?)`

Generates variant class strings:

```crystal
variant_classes("btn", "primary", "lg")
# => "btn btn-primary btn-lg"

variant_classes("alert", "success", nil, "dismissible")
# => "alert alert-success alert-dismissible"
```

### `merge_classes(*class_strings)`

Merge and deduplicate multiple class strings:

```crystal
merge_classes("flex gap-4", "flex items-center gap-8")
# => "flex gap-4 items-center gap-8"
```

---

## Design Tokens

Configured via `Components::CSS::Config`. Default values below.

### Colors (OKLCH)

Four color families, each with shades 50-950:

| Token | 50 (lightest) | 500 (base) | 950 (darkest) |
|-------|---------------|------------|---------------|
| `gray` | `oklch(0.985 0 0)` | `oklch(0.551 0 0)` | `oklch(0.13 0 0)` |
| `red` | `oklch(0.971 0.013 17.38)` | `oklch(0.637 0.237 25.331)` | `oklch(0.258 0.092 26.042)` |
| `blue` | `oklch(0.97 0.014 254.604)` | `oklch(0.623 0.214 259.815)` | `oklch(0.282 0.091 267.935)` |
| `green` | `oklch(0.982 0.018 155.826)` | `oklch(0.723 0.219 149.579)` | `oklch(0.266 0.065 152.934)` |

Full shade scale: 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950

Usage in utility classes: `bg-blue-500`, `text-gray-900`, `border-red-300`

### Spacing

| Token | Value | Token | Value |
|-------|-------|-------|-------|
| `0` | `0` | `8` | `2rem` |
| `px` | `1px` | `10` | `2.5rem` |
| `0.5` | `0.125rem` | `12` | `3rem` |
| `1` | `0.25rem` | `16` | `4rem` |
| `2` | `0.5rem` | `20` | `5rem` |
| `3` | `0.75rem` | `24` | `6rem` |
| `4` | `1rem` | `32` | `8rem` |
| `5` | `1.25rem` | `48` | `12rem` |
| `6` | `1.5rem` | `64` | `16rem` |
| `7` | `1.75rem` | `96` | `24rem` |

Usage: `p-4` (1rem padding), `mt-8` (2rem margin-top), `gap-2` (0.5rem gap)

### Breakpoints

| Name | Min-width | Usage |
|------|-----------|-------|
| `sm` | `640px` | `sm:flex` |
| `md` | `768px` | `md:grid-cols-2` |
| `lg` | `1024px` | `lg:text-lg` |
| `xl` | `1280px` | `xl:max-w-screen-xl` |
| `2xl` | `1536px` | `2xl:px-8` |

### Font Sizes

| Token | Value | Token | Value |
|-------|-------|-------|-------|
| `xs` | `0.75rem` | `xl` | `1.25rem` |
| `sm` | `0.875rem` | `2xl` | `1.5rem` |
| `base` | `1rem` | `3xl` | `1.875rem` |
| `lg` | `1.125rem` | | |

### Border Radius

| Token | Value |
|-------|-------|
| `none` | `0` |
| `sm` | `0.125rem` |
| `(default)` | `0.25rem` |
| `md` | `0.375rem` |
| `lg` | `0.5rem` |
| `xl` | `0.75rem` |
| `2xl` | `1rem` |
| `3xl` | `1.5rem` |
| `full` | `9999px` |

### Shadows

| Token | Description |
|-------|-------------|
| `sm` | Small shadow |
| `(default)` | Medium shadow |
| `md` | Medium-large shadow |
| `lg` | Large shadow |
| `xl` | Extra-large shadow |

---

## Utility Classes

The CSS parser (`Components::CSS::Engine::Parser`) handles 100+ utility patterns.

### Layout & Display

`block`, `inline-block`, `inline`, `flex`, `inline-flex`, `grid`, `hidden`

### Position

`relative`, `absolute`, `fixed`, `sticky`

### Flexbox

`flex-row`, `flex-col`, `flex-wrap`, `flex-nowrap`, `items-start`, `items-center`, `items-end`, `items-stretch`, `justify-start`, `justify-center`, `justify-end`, `justify-between`, `justify-around`, `gap-{size}`

### Spacing

Margin: `m-{size}`, `mx-{size}`, `my-{size}`, `mt-{size}`, `mr-{size}`, `mb-{size}`, `ml-{size}`
Padding: `p-{size}`, `px-{size}`, `py-{size}`, `pt-{size}`, `pr-{size}`, `pb-{size}`, `pl-{size}`

### Sizing

`w-{size}`, `h-{size}`, `min-w-{size}`, `max-w-{size}`, `min-h-{size}`, `w-full`, `w-screen`, `h-full`, `h-screen`

### Typography

`text-{size}` (xs-3xl), `font-{weight}` (thin/light/normal/medium/semibold/bold/extrabold/black), `leading-{height}`, `tracking-{spacing}`, `text-left`, `text-center`, `text-right`

### Colors

Background: `bg-{color}-{shade}` (e.g., `bg-blue-500`)
Text: `text-{color}-{shade}` (e.g., `text-gray-900`)
Border: `border-{color}-{shade}`
Accent: `accent-{color}-{shade}`
Caret: `caret-{color}-{shade}`

### Borders & Radius

`rounded`, `rounded-{size}`, `border`, `border-{width}`

### Effects

`shadow-{size}`, `opacity-{value}`, `z-{index}`

### Focus Ring

`ring`, `ring-{0-8}`, `ring-inset`, `outline-{width}`, `outline-offset-{size}`

### Accessibility

`sr-only` — visually hidden, available to screen readers (WCAG 1.1.1)
`not-sr-only` — undo sr-only

### Advanced

`container`, `scroll-p-{size}`, `scroll-m-{size}`, `touch-action-{value}`, `user-select-{value}`, `appearance-none`, `forced-color-adjust-{value}`

---

## Modifier Prefixes

All utility classes accept modifier prefixes for conditional application:

### Pseudo-states
`hover:`, `focus:`, `active:`, `disabled:`, `focus-visible:`, `focus-within:`

### Form validation
`invalid:`, `valid:`, `required:`, `checked:`, `indeterminate:`, `read-only:`, `placeholder-shown:`

### ARIA states
`aria-expanded:`, `aria-selected:`, `aria-checked:`, `aria-disabled:`, `aria-hidden:`, `aria-pressed:`, `aria-busy:`

### Media/environment
`dark:`, `motion-safe:`, `motion-reduce:`, `print:`, `contrast-more:`, `forced-colors:`, `pointer-coarse:`, `pointer-fine:`

### Responsive
`sm:`, `md:`, `lg:`, `xl:`, `2xl:`

### Container queries
`@sm:`, `@md:`, `@lg:`, `@xl:`, `@2xl:`

### Other
`open:`, `inert:`

---

## Component CSS

Register component-scoped CSS using the `component_css` macro:

```crystal
class ButtonComponent < Components::StatelessComponent
  component_css <<-CSS
    .btn {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.5rem 1rem;
      border-radius: 0.375rem;
      font-weight: 500;
      transition: all 150ms ease;
    }
    .btn-primary {
      background-color: var(--color-blue-500);
      color: white;
    }
    .btn-primary:hover {
      background-color: var(--color-blue-600);
    }
  CSS
end
```

### CSS Layer Structure

The generator outputs CSS in this cascade order:

```css
@layer reset, tokens, base, components, utilities;

@layer reset { /* CSS reset */ }
@layer tokens { :root { --color-blue-500: oklch(...); ... } }
@layer base { /* Default focus rings, motion preferences */ }
@layer components { /* component_css output */ }
@layer utilities { /* Generated utility classes */ }
```

Utilities always override component styles. Component styles override base. This is enforced by the `@layer` cascade.

### Custom Properties

`Config#to_custom_properties` generates CSS custom properties for all tokens:

```css
:root {
  color-scheme: light dark;
  --color-gray-50: oklch(0.985 0 0);
  --color-gray-100: oklch(0.967 0 0);
  /* ... all color tokens ... */
  --spacing-1: 0.25rem;
  --spacing-2: 0.5rem;
  /* ... all spacing tokens ... */
}
```

### Generating CSS

```crystal
# Configure
config = Components::CSS::Config.new
# Optionally customize: config.colors = { ... }

# Generate for all used classes
generator = Components::CSS::Engine::Generator.new(config)
css = generator.generate

# Or generate for specific classes
css = generator.generate_for_classes(["flex", "bg-blue-500", "hover:shadow-lg"])

# In Amber views
<%= css_styles(config: config) %>
```

### ClassRegistry

Tracks all CSS classes used across components. When `ClassBuilder#build` is called or `HTMLElement#add_class` is used, classes are registered automatically.

```crystal
registry = Components::CSS::ClassRegistry.instance
registry.used_classes          # Set of all used class names
registry.component_classes     # Per-component class tracking
registry.should_include?("bg-blue-500")  # Check safelist + usage
registry.add_to_safelist("btn-*")        # Always include matching classes
```
