---
slug: home-screen-quick-actions
ui_view: UI::HomeScreenQuickActions
priority: P2
platforms: [iOS, iPadOS]
hig_page: ../../../apple-hig/pages/home-screen-quick-actions.md
validation_report: ../validation/reports/home-screen-quick-actions.md
---

# UI::HomeScreenQuickActions

> A metadata export surface for Home Screen quick actions. The long-press menu
> itself is system-owned; asset_pipeline owns the shortcut-item definitions and
> host export.

## Feel of the flow

Quick actions need to be small, literal, and immediately useful. They should
feel like front-door intents, not a tiny secondary navigation tree.

## Quickstart

```crystal
catalog = UI::QuickActionsCatalog.new

catalog.add_action(
  type: "com.assetpipeline.capture",
  title: "Capture Preview",
  subtitle: "Open today's HIG batch",
  system_image: "camera.viewfinder",
  user_info: {"slug" => "activity-rings"}
)

UI::HomeScreenQuickActions.export_manifest(catalog)
UI::HomeScreenQuickActions.export_plist_fragment(catalog)
```

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `type` | `String` | required | Stable identifier for the shortcut item. |
| `title` | `String` | required | Primary label shown in the long-press menu. |
| `subtitle` | `String?` | `nil` | Optional secondary line. |
| `system_image` | `String?` | `nil` | Optional SF Symbol name for the shortcut icon. |
| `user_info` | `Hash(String, String)` | `{}` | Small metadata payload for host routing. |

## What happens on each platform

- **iOS / iPadOS**: The catalog exports a manifest and an Info.plist fragment
  for `UIApplicationShortcutItems`.
- **macOS**: Not applicable.
- **Validation**: Skipped for screenshots because the quick-action surface is a
  Home Screen shell affordance rather than an in-app component.
