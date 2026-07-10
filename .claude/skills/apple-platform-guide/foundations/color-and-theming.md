---
title: Color and theming
topic: color
hig_pages:
  - color.md
  - dark-mode.md
---

# Color and theming

## What it means

Apple's color system is built around four ideas:

1. **System colors adapt.** System blue, system red, system gray — these are
   not fixed hex values. They shift subtly between light and dark appearance
   and between default and Increase Contrast. Using them is how your app feels
   "at home on the device."
2. **Accent color carries meaning.** One tint color represents interactive
   elements across your app (the tappable blue in Settings is the clearest
   example). Use it consistently — don't reuse that same color for
   non-interactive decorative text.
3. **Destructive red is semantic.** The HIG reserves system red for destructive
   actions and certain error states. Don't use it for accents, brand, or
   non-destructive emphasis.
4. **Dark mode is mandatory, not optional.** The HIG says "provide both light
   and dark colors" even if your app ships in a single appearance mode — Liquid
   Glass's adaptivity depends on both being defined.

Apple also defines context-specific palettes: labels (primary / secondary /
tertiary / quaternary), fills (same four levels), separators, and backgrounds.
These compose automatically with materials — e.g. a `secondaryLabel` over a
`regular` material will pick the right vibrancy automatically.

## How it's expressed in asset_pipeline

`UI::Color` is a plain RGBA record (source: `src/ui/view.cr`):

```crystal
record Color,
  r : Float64,
  g : Float64,
  b : Float64,
  a : Float64 = 1.0
```

No automatic light/dark swapping at the `Color` level — you resolve the right
value at theme construction time. The `UI::Theme` class centralizes this
(source: `src/ui/theme.cr`):

```crystal
theme = UI::Theme.apple_default
# theme.primary  → system blue
# theme.error    → system red (destructive)
# theme.secondary → system gray
```

`UI::Theme.apple_default` composes these HIG-matching tokens:

| Token | Value (light) | HIG name |
|-------|---------------|----------|
| `primary` | `(0.0, 0.478, 1.0)` | System Blue |
| `on_primary` | `(1.0, 1.0, 1.0)` | White |
| `secondary` | `(0.34, 0.34, 0.36)` | System Gray |
| `error` | `(1.0, 0.23, 0.19)` | System Red (destructive) |
| `background` | `(1.0, 1.0, 1.0)` | Light background |
| `on_background` | `(0.0, 0.0, 0.0)` | Primary label on light |
| `surface` | `(0.97, 0.97, 0.97)` | Grouped-background light |
| `outline` | `(0.78, 0.78, 0.78)` | Separator |

The full record set — including the `on_*` pairs, container variants, and the
Material Design equivalents when `material_baseline` is used — is in
`src/ui/theme.cr`.

**Dark-mode variants are planned.** `UI::Theme` today is a single appearance —
the renderer resolves the correct system color at paint time via
`labelColor` / `UIColor.label` etc., but there is no `Theme.apple_dark`
preset yet. For custom colors that must adapt, wait for the planned
`DynamicColor(light: Color, dark: Color)` type, or swap themes manually based
on the system trait.

### Using the theme

Rather than hard-coding colors in each view, consult the theme:

```crystal
theme = UI::Theme.apple_default

title = UI::Label.new("Settings")
title.font = UI::Font.new(size: theme.font_size_title, weight: :semibold)

delete = UI::Button.new("Delete account")
delete.foreground_color = UI::Color.new(
  r: theme.error.r, g: theme.error.g, b: theme.error.b
)
```

Note: `UI::Theme` uses `ThemeColor` (with `.r .g .b .a`) internally; `UI::Color`
is the record that views actually hold. The conversion is trivial but verbose —
a `ThemeColor#to_color` helper is planned.

### Accent color

There is no single "accent color" global in the API today. `theme.primary`
serves that purpose by convention — set it once at app startup and reference
it wherever you'd reach for an interactive accent.

## HIG citations

- **Color → Best practices**: "Make sure all your app's colors work well in
  light, dark, and increased contrast contexts." (`pages/color.md`)
- **Color → Best practices**: "Even if your app ships in a single appearance
  mode, provide both light and dark colors to support Liquid Glass adaptivity."
  (`pages/color.md`)
- **Color → Best practices**: "Avoid using the same color to mean different
  things. Use color consistently." (`pages/color.md`)
- **Buttons → Role**: a primary button uses the app's accent color; destructive
  uses system red. (`pages/buttons.md`)
- **Dark Mode**: See `pages/dark-mode.md` for the full light/dark contract.
