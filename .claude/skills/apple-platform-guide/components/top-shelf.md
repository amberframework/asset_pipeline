---
slug: top-shelf
ui_view: UI::TopShelf
priority: P2
platforms: [tvOS]
hig_page: ../../../apple-hig/pages/top-shelf.md
validation_report: ../validation/reports/top-shelf.md
---

# UI::TopShelf

> A tvOS top-shelf surface for system-level featured content. It is not an
> in-app primitive for the asset_pipeline's macOS/iOS focus, so the shard keeps
> it documented as platform chrome rather than a renderable component.

## Feel of the flow

Top Shelf is a home-screen and launcher concept, not part of an app's content
tree. The useful design work here is in the exported metadata and featured
presentation intent, not in a fake in-app view.

## What happens on each platform

- **tvOS**: Belongs to the system launcher and should be modeled as top-shelf
  metadata or host configuration.
- **macOS / iOS / iPadOS**: Not applicable as an in-app primitive.
- **Validation**: Skipped for screenshots because Top Shelf is launcher-owned
  chrome, not a content view the shard can render locally.

## HIG citations (validated)

- Top Shelf is system-owned launcher presentation.
- Keep featured content concise and purposeful.
