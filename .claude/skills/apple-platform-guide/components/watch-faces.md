---
slug: watch-faces
ui_view: UI::WatchFaces
priority: P2
platforms: [watchOS]
hig_page: ../../../apple-hig/pages/watch-faces.md
validation_report: ../validation/reports/watch-faces.md
---

# UI::WatchFaces

> A watchOS face concept, not an in-app primitive for the asset_pipeline's
> macOS/iOS-focused component library. The face belongs to the system and the
> watch platform, so the shard documents it as out of scope for local rendering.

## Feel of the flow

Watch faces are system-level home surfaces with their own rules, constraints,
and presentation model. They are not something a macOS/iOS app should try to
fake inside a normal content tree.

## What happens on each platform

- **watchOS**: System-owned face design and complications surface.
- **macOS / iOS / iPadOS**: Not applicable as an in-app primitive.
- **Validation**: Skipped for screenshots because the face is not part of the
  shard's current host app rendering surface.

## HIG citations (validated)

- Watch faces are platform-owned shell surfaces.
- Keep face design aligned with the system, not with app content views.
