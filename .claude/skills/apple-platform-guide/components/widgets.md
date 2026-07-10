---
slug: widgets
ui_view: UI::Widgets
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/widgets.md
validation_report: ../validation/reports/widgets.md
---

# UI::Widgets

> A WidgetKit concept for Home Screen, Lock Screen, and desktop surfaces. It is
> not an in-app primitive, so asset_pipeline documents it as extension work
> rather than pretending it belongs in the regular view tree.

## Feel of the flow

Widgets are small, glanceable system-owned summaries. The important part for
this shard is eventually describing exported timeline content and intent, not
rendering a fake widget card inside a normal app window.

## What happens on each platform

- **iOS / iPadOS / macOS**: WidgetKit extension targets and timeline exports,
  rendered by the system.
- **Validation**: Skipped for local screenshots because the system owns widget
  presentation and placement.

## What the shard exports today

- `UI::Widgets#to_payload` for structured widget metadata.
- `UI::Widgets#export_widgetkit_scaffold` for a deterministic Swift/WidgetKit
  scaffold a host build step can turn into a real extension target.

## HIG citations (validated)

- Widgets are concise, glanceable extensions rather than in-app screens.
- Favor focused information and clear task entry points over dense UI chrome.
