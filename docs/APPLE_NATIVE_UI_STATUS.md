# Apple Native UI Status

This document is the quickest way to understand the current state of the
Apple-native work inside `asset_pipeline`.

## Current Snapshot

As of April 17, 2026, the validation ledger reports:

- `61` implemented component or platform surfaces
- `49` auditable studies at `pass_with_notes`
- `16` skipped studies that are intentionally system-owned or platform-owned
- `0` pending or invalid evidence rows

The latest generated dashboard lives at:

- `docs/apple-native-validation/index.html`

## What Is Done

### In-app native UI

The shard now has real or shared-fallback implementations for the core HIG
families used to build Mac and iOS applications, including:

- buttons, toggles, sliders, search fields, text fields, text views
- sheets, alerts, action sheets, popovers, activity views
- toolbars, tab bars, tab views, segmented controls, page controls
- sidebars, split views, column views, outline views, path controls
- image views, image wells, token fields, maps, web views, video
- gauges, progress indicators, activity rings

### App shell and OS-owned surfaces

The shard also models or integrates:

- windows
- menu bars
- status bars / status items
- App Shortcuts
- Home Screen Quick Actions
- notifications
- widgets
- live activities

For system-owned surfaces, the goal is truthful modeling plus export or host
integration, not fake screenshots.

## Export-Oriented Surfaces

Several Apple capabilities now export deterministic Swift scaffold code so a
host app can turn metadata into real extension or OS registration code:

- `UI::AppShortcuts#export_app_intents_scaffold`
- `UI::Widgets#export_widgetkit_scaffold`
- `UI::LiveActivities#export_activitykit_scaffold`
- `UI::NotificationsCatalog#export_swift_scaffold`
- `UI::HomeScreenQuickActions.export_plist_fragment`

These are deliberately conservative. The shard owns the model, naming, and
repeatable export; the host app still owns final app-target wiring.

## Host Validation

The project uses two native hosts for visual validation:

- macOS host: `samples/cross_platform/macos_host/hig_showcase.cr`
- iOS host: `samples/cross_platform/ios_host/hig_bridge.cr`

These hosts render studies into validation screenshots so the repo can compare
default component taste against Apple reference material.

## What “Skipped” Means

Skipped rows are not abandoned work. They usually mean one of three things:

1. the HIG page is a foundation or pattern rather than a component
2. the surface is system-owned, such as notifications or widgets
3. the surface belongs to a platform outside the current app target, such as
   watch-specific or tvOS-specific chrome

That distinction matters because the right job for the shard is different in
each case.

## Where To Contribute

The best places to keep improving the project are:

- contributor-facing docs and examples
- packaging and host-app wiring for exported shell surfaces
- renderer ergonomics and shared layout primitives
- making the validation dashboard easier to navigate from the repo root
