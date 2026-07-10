---
slug: live-activities
ui_view: UI::LiveActivities
priority: P2
platforms: [iOS, iPadOS]
hig_page: ../../../apple-hig/pages/live-activities.md
validation_report: ../validation/reports/live-activities.md
---

# UI::LiveActivities

> A system-owned ActivityKit surface for the Lock Screen and Dynamic Island.
> It is not an in-app primitive, so asset_pipeline treats it as extension and
> host configuration work rather than a renderable view.

## Feel of the flow

Live Activities are about exported state, compact glanceability, and a clean
handoff between the app and system surfaces. The shard should eventually model
the metadata and update contract, not fake the system card inside an app scene.

## What happens on each platform

- **iOS / iPadOS**: ActivityKit and WidgetKit extension work, rendered by the
  system on the Lock Screen and Dynamic Island.
- **macOS**: Not applicable as an in-app primitive.
- **Validation**: Skipped for local screenshots because the system owns the
  rendered surface.

## What the shard exports today

- `UI::LiveActivities#to_payload` for structured metadata export.
- `UI::LiveActivities#export_activitykit_scaffold` for a deterministic Swift
  scaffold a build step can hand off to ActivityKit / WidgetKit extension work.

## HIG citations (validated)

- Live Activities are system-presented, glanceable status surfaces.
- Keep content concise and update-driven rather than building full app chrome.
