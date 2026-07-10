---
title: Typography
topic: typography
hig_pages:
  - typography.md
  - accessibility.md
---

# Typography

## What it means

Apple's type system is SF Pro for Latin scripts, SF Pro Rounded for friendlier
contexts, and SF Mono for code. The system ships with a family of predefined
text styles — Large Title, Title 1/2/3, Headline, Body, Callout, Subheadline,
Footnote, Caption 1/2 — that each carry a recommended size, weight, and leading
for their platform. You don't pick "18pt semibold"; you pick "Title 2" and let
the system resolve it.

The HIG is explicit about defaults and minimums:

| Platform | Default size | Minimum size |
|----------|--------------|--------------|
| iOS, iPadOS | 17 pt | 11 pt |
| macOS | 13 pt | 10 pt |
| tvOS | 29 pt | 23 pt |
| visionOS | 17 pt | 12 pt |
| watchOS | 16 pt | 12 pt |

Three rules that recur:

- **Avoid light weights** (Ultralight, Thin, Light). They get hard to read at
  small sizes. Prefer Regular, Medium, Semibold, Bold.
- **Support Dynamic Type.** iOS, iPadOS, tvOS, visionOS, and watchOS let the
  user set a preferred text size. Your UI should follow it.
- **Font weight interacts with contrast.** A thin weight at 4.5:1 might still
  be hard to read — the WCAG contrast table in `pages/accessibility.md`
  demands 4.5:1 for text up to 17pt; bold text gets a lower bar of 3:1.

## How it's expressed in asset_pipeline

`UI::Font` is a record (source: `src/ui/view.cr`):

```crystal
record Font,
  family : String = "system",
  size : Float64 = 17.0,
  weight : Symbol = :regular,
  italic : Bool = false
```

Weight symbols: `:ultralight | :thin | :light | :regular | :medium | :semibold |
:bold | :heavy | :black`. The renderer maps these to `UIFont.Weight.*` on iOS
and `NSFont.Weight.*` on macOS.

Family: `"system"` picks SF Pro on Apple platforms. Set `family =
"-apple-system"` when you want the explicit system-font CSS keyword on web, or
`"SF Pro Rounded"` / `"SF Mono"` for the stylistic variants.

`UI::Theme` carries the four headline sizes:

```crystal
theme.font_size_body     # 16.0 (Apple: 17.0)
theme.font_size_title    # 22.0
theme.font_size_headline # 28.0
theme.font_size_caption  # 12.0
```

With `UI::Theme.apple_default`, `font_size_body` is 17.0 and `font_family` is
`"-apple-system"`.

### Dynamic Type

**Full Dynamic Type support is planned.** Today `UI::Font` holds a fixed point
size. A future `Font.preferred(style: :body)` constructor — which resolves
against the current system content-size category — is on the roadmap. In the
meantime, for iOS-native apps, wrap your font picking in a helper that reads the
trait collection:

```crystal
# Planned API — not yet wired:
# font = UI::Font.preferred(:body)          # respects Dynamic Type
# font = UI::Font.preferred(:large_title)
```

Until then, set sizes from `theme.font_size_*` and accept that the user's
Dynamic Type preference is not honored at runtime. The renderer still honors
the system font family.

### Choosing a text style

A rough map from HIG text styles to `UI::Font` config:

| HIG style | Size (iOS) | Weight |
|-----------|-----------|--------|
| Large Title | 34 | Regular |
| Title 1 | 28 | Regular |
| Title 2 | 22 | Regular |
| Title 3 | 20 | Regular |
| Headline | 17 | Semibold |
| Body | 17 | Regular |
| Callout | 16 | Regular |
| Subheadline | 15 | Regular |
| Footnote | 13 | Regular |
| Caption 1 | 12 | Regular |
| Caption 2 | 11 | Regular |

Example — labeling a settings row:

```crystal
title = UI::Label.new("Notifications")
title.font = UI::Font.new(size: 17.0, weight: :semibold)  # Headline

subtitle = UI::Label.new("Enabled for 3 apps")
subtitle.font = UI::Font.new(size: 15.0, weight: :regular)  # Subheadline
```

## HIG citations

- **Typography → Ensuring legibility**: the platform default/minimum size table.
  (`pages/typography.md`)
- **Typography → Ensuring legibility**: "In general, avoid light font weights. …
  prefer Regular, Medium, Semibold, or Bold." (`pages/typography.md`)
- **Typography → Conveying hierarchy**: "Adjust font weight, size, and color as
  needed to emphasize important information." (`pages/typography.md`)
- **Accessibility → Vision**: WCAG contrast-ratio requirements interact with
  font weight — 4.5:1 for text up to 17pt, 3:1 for text ≥18pt or bold.
  (`pages/accessibility.md`)
- **Typography → Supporting Dynamic Type**: cross-referenced in
  `pages/typography.md` — user-scalable text is a system-level accessibility
  guarantee.
