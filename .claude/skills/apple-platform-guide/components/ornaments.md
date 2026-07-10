---
slug: ornaments
ui_view: UI::Ornaments
priority: P2
platforms: [visionOS]
hig_page: ../../../apple-hig/pages/ornaments.md
validation_report: ../validation/reports/ornaments.md
---

# UI::Ornaments

> A platform ornament concept for visionOS-style environments. It is not an
> in-app primitive for the asset_pipeline's current macOS/iOS target set, so
> the shard treats it as an external platform surface rather than a rendered
> component.

## Feel of the flow

Ornaments are spatial UI chrome, not standard content-view controls. For a
macOS/iOS-focused library, the honest move is to document the concept and keep
it out of the in-app component tree until the target platform actually needs
it.

## What happens on each platform

- **macOS / iOS / iPadOS**: Not applicable as an in-app primitive.
- **visionOS**: Belongs to spatial system chrome and should be bridged only if
  the target set expands there.
- **Validation**: Skipped for screenshots because this shard does not render
  ornament chrome in the current platform set.

## HIG citations (validated)

- Ornaments belong to spatial platform chrome, not ordinary content layout.
