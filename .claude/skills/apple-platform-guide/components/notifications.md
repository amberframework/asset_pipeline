---
slug: notifications
ui_view: UI::Notifications
priority: P1
platforms: [macOS, iOS, iPadOS]
hig_page: ../../../apple-hig/pages/notifications.md
validation_report: ../validation/reports/notifications.md
---

# UI::Notifications

> A system-notification bridge for scheduling local notifications without
> pretending banners and Notification Center chrome belong inside the in-app
> view tree.

## Feel of the flow

Notifications are not a decorative extra. They are a delivery mechanism for
important state changes, reminders, and background results that need to reach
someone outside the app's current foreground context.

That means the shard should be opinionated about two things:

1. The payload should be concise and useful.
2. The system should keep ownership of the actual chrome.

`UI::Notifications` is therefore deliberately not a `UI::View`. It is a small
native service layer that requests authorization, schedules local
notifications, exports categories and actions, and clears pending requests
while leaving banner and Notification Center presentation to Apple's system
UI.

## Quickstart

```crystal
granted = UI::Notifications.request_authorization

if granted
  request = UI::NotificationRequest.new(
    "Export finished",
    "Your PNG batch is ready to review.",
    identifier: "export-finished",
    delay_seconds: 2.0,
    thread_id: "exports"
  )

  UI::Notifications.schedule(request)
end

catalog = UI::NotificationsCatalog.new("Asset Pipeline")
catalog.add_category("exports") do |category|
  category.add_action("open", "Open Export", options: ["foreground"])
end

catalog.export_manifest
catalog.export_swift_scaffold
```

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `identifier` | `String` | generated | Stable identifier for replacing or removing a pending request. |
| `title` | `String` | required | Primary notification title. |
| `subtitle` | `String?` | `nil` | Optional secondary title line. |
| `body` | `String` | required | Main body copy. |
| `delay_seconds` | `Float64` | `0.25` | Delivery delay for a local notification. |
| `repeats` | `Bool` | `false` | Whether the time interval trigger repeats. |
| `sound` | `Bool` | `true` | Whether the system default notification sound should play. |
| `badge` | `Int32?` | `nil` | Optional badge count. |
| `thread_id` | `String?` | `nil` | Optional grouping thread identifier. |

## What the shard exports today

- Runtime authorization and local-notification scheduling through
  `UI::Notifications`.
- Declarative categories and actions through `UI::NotificationsCatalog`.
- `export_manifest` for machine-readable notification registration metadata.
- `export_swift_scaffold` for deterministic Swift/UserNotifications starter
  code that a host app can adapt into real category registration.

## Light / dark appearance notes

The system owns the visual treatment. Validation for this capability should
focus on API truthfulness and platform wiring, not on recreating banner chrome
inside the showcase host.

## What happens on each platform

- **iOS / iPadOS**: Uses `UNUserNotificationCenter` for local notifications.
- **macOS**: Uses the same `UNUserNotificationCenter` stack for Notification
  Center delivery.
- **Validation**: The HIG row remains skipped for screenshots because banners
  and Notification Center surfaces are system-rendered, not part of the
  shard's in-app view tree.

## HIG citations (validated)

- Notifications should be timely, relevant, and clearly actionable.
- The system, not the app, owns notification presentation chrome.

## Related

- `UI::Snackbar` for in-app transient messaging.
- `UI::ActivityView` for foreground sharing flows.
