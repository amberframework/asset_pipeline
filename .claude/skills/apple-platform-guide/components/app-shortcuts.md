---
slug: app-shortcuts
ui_view: UI::AppShortcuts
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/app-shortcuts.md
validation_report: ../validation/reports/app-shortcuts.md
---

# UI::AppShortcuts

> A declarative export surface for App Shortcuts metadata. The visible Siri,
> Spotlight, and Shortcuts surfaces remain system-owned; asset_pipeline owns
> the shortcut catalog and the export payload.

## Feel of the flow

App Shortcuts are not a renderable screen. They are a contract between the app,
the system, and the user's language. The important design move is to keep that
contract explicit: short titles, natural phrases, stable identifiers, and a
compact parameter model that can be exported cleanly.

## Quickstart

```crystal
shortcuts = UI::AppShortcuts.new(
  "Asset Pipeline",
  bundle_identifier: "com.example.asset-pipeline"
)

shortcuts.add_shortcut("Open Inbox") do |shortcut|
  shortcut.subtitle = "Jump to the inbox"
  shortcut.summary = "Open the inbox view"
  shortcut.icon = "tray.full"
  shortcut.add_phrase("Open my inbox")
  shortcut.add_phrase("Show the inbox")
  shortcut.add_parameter("section", prompt: "Which section?", type: "string")
end

shortcuts.to_payload
shortcuts.export_app_intents_scaffold
```

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `application_name` | `String` | required | Exported app name for the shortcut catalog. |
| `bundle_identifier` | `String?` | `nil` | Optional bundle identifier attached to the export payload. |
| `AppShortcut#identifier` | `String` | slugified title | Stable identity for the shortcut. |
| `AppShortcut#title` | `String` | required | Full user-facing name. |
| `AppShortcut#subtitle` | `String?` | `nil` | Optional supporting context. |
| `AppShortcut#summary` | `String?` | `nil` | Short description for the shortcut. |
| `AppShortcut#icon` | `String?` | `nil` | Optional SF Symbol name. |
| `AppShortcut#phrases` | `Array(String)` | `[]` | Natural-language invocation phrases. |
| `AppShortcut#parameters` | `Array(AppShortcutParameter)` | `[]` | Structured parameter metadata. |
| `AppShortcutParameter#name` | `String` | required | Parameter key exported in the payload. |
| `AppShortcutParameter#prompt` | `String?` | `nil` | Human-friendly prompt for the parameter. |
| `AppShortcutParameter#type` | `String?` | `nil` | Exported type hint for a future AppIntents bridge. |
| `AppShortcutParameter#default_value` | `String?` | `nil` | Optional default value. |
| `AppShortcutParameter#is_required` | `Bool` | `true` | Whether the parameter must be filled in. |

## What the shard exports today

- `to_payload` for a structured manifest-style JSON catalog.
- `export_app_intents_scaffold` for deterministic Swift/AppIntents starter
  code that host apps can adapt into a real `AppShortcutsProvider`.

## What happens on each platform

- **iOS / iPadOS / macOS**: The catalog exports machine-readable manifest data
  plus deterministic AppIntents scaffold code for a host build step or native
  shortcut extension target.
- **Validation**: Skipped for screenshots because App Shortcuts live in system
  surfaces like Siri, Spotlight, and Shortcuts rather than in the in-app view
  tree.
