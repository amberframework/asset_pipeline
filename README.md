# Asset Pipeline

Asset Pipeline now covers two related jobs for Crystal applications:

1. a legacy web asset pipeline for import maps, JavaScript, and static assets
2. a native UI and host-integration layer for Apple platforms, with HIG-driven
   validation for macOS and iOS
3. a web-first design-system proof with semantic tokens, opinionated
   components, motion helpers, font handling, and screenshot validation

The native track is no longer hypothetical. As of April 17, 2026, the Apple
validation ledger reports:

- `61` implemented component or platform surfaces
- `49` auditable HIG studies passing with notes
- `16` intentionally skipped studies because they are system-owned shell or
  extension surfaces rather than in-app views
- `0` stale or invalid evidence rows in the current validation snapshot

## Installation

Add the shard to your `shard.yml`:

```yaml
dependencies:
  asset_pipeline:
    github: amberframework/asset_pipeline
    version: 0.36.0
```

Then run:

```bash
shards install
```

## What This Repo Does Now

### Native Apple UI

The shard includes a large native-first UI surface with AppKit and UIKit
renderers, host bridges, and validation studies for the Apple Human Interface
Guidelines.

Current native work includes:

- opinionated default components with HIG-tuned spacing and framing
- macOS and iOS showcase hosts for screenshot validation
- native platform services such as windows, menu bars, status items, quick
  actions, App Shortcuts, notifications, WidgetKit exports, and ActivityKit
  exports
- export-oriented scaffolds for system-owned surfaces instead of fake in-app
  stand-ins

### Legacy FrontLoader Asset Pipeline

The original FrontLoader flow is still here for import maps and web assets.
That part of the shard remains useful, but it is no longer the whole story.

### Web Design System

A vanilla-JS, token-driven design system that ships from the same Crystal shard
as the native renderers. No Node, no bundler, no Stimulus for canonical helpers.
Components render to strings; CSS variables drive light/dark themes; motion,
charts, and form flows are first-party SVG and JavaScript.

The current proof includes reusable Crystal wrappers for command palette,
schedule heatmap, payment/auth forms, theme switching, fields, pricing cards,
tabs, carousel, dialog, and timeline patterns. Chrome DevTools audits cover
keyboard behavior, sampled contrast, reduced motion, accessibility names, state
captures, axe-core, IBM Equal Access, and a light/dark screenshot matrix.

Agents start here, in order:

- Root agent instructions: `AGENTS.md`
- Design-system docs: `docs/web-design-system/README.md`
- Agent playbook: `docs/web-design-system/agent-playbook.md`
- Accessibility contract: `docs/web-design-system/accessibility-contract.md`
- Component API: `docs/web-design-system/component-api.md`
- Forbidden patterns: `docs/web-design-system/forbidden-patterns.md`
- Compiler command matrix: `docs/web-design-system/compiler-command-matrix.md`
- Refactor accountability: `docs/web-design-system/refactor-accountability.md`
- Phase 1 baseline: `docs/web-design-system/phase-1-baseline.md`

Reference:

- Visual language: `docs/web-design-system/visual-language.md`
- Evidence matrix: `docs/web-design-system/evidence.md`
- Agent DX gap analysis: `docs/web-design-system/agent-dx-gap-analysis.md`
- Agent DX roadmap: `docs/web-design-system/agent-dx-roadmap.md`
- Component catalog: `docs/web-design-system/component-catalog.md`
- Component contracts: `docs/web-design-system/component-contracts.md`
- Migration notes: `docs/web-design-system/migration.md`
- Demo generator: `examples/web_design_system_demo.cr`
- Static demo audit: `scripts/validate_web_demo.cr`
- Browser screenshot audit: `scripts/capture_web_demo_screenshots.cr`
- Axe-core accessibility audit: `scripts/axe_web_demo_audit.cr`
- IBM Equal Access accessibility audit: `scripts/ibm_web_demo_audit.cr`

## Native Apple Example

Here is the shape of the newer export-oriented API surface:

```crystal
shortcuts = UI::AppShortcuts.new(
  "Asset Pipeline",
  bundle_identifier: "com.example.asset-pipeline"
)

shortcuts.add_shortcut("Open Inbox") do |shortcut|
  shortcut.add_phrase("Open my inbox")
  shortcut.add_parameter("section", prompt: "Which section?", type: "string")
end

widgets = UI::Widgets.new("Asset Pipeline")
widgets.add_widget("Daily Summary", identifier: "daily-summary")

notifications = UI::NotificationsCatalog.new("Asset Pipeline")
notifications.add_category("exports") do |category|
  category.add_action("open", "Open Export", options: ["foreground"])
end

puts shortcuts.export_app_intents_scaffold
puts widgets.export_widgetkit_scaffold
puts notifications.export_swift_scaffold
```

## Where To Look

- Native UI source: `src/ui`
- macOS host showcase: `samples/cross_platform/macos_host/hig_showcase.cr`
- iOS host showcase: `samples/cross_platform/ios_host/hig_bridge.cr`
- Validation dashboard: `docs/apple-native-validation/index.html`
- Apple native status overview: `docs/APPLE_NATIVE_UI_STATUS.md`
- design-system web proof: `docs/web-design-system/README.md`
- Web/frontloader docs: `docs/FRAMEWORK_INTEGRATION.md`,
  `docs/USAGE_EXAMPLES.md`, `docs/API_REFERENCE.md`

## Apple Validation Workflow

The Apple work is validated with paired macOS and iOS studies against HIG
reference imagery. The validation artifacts live under:

```text
.claude/skills/apple-platform-guide/validation/
```

That folder contains:

- per-component reports
- evidence manifests
- generated screenshot pairs
- the current HTML dashboard and historical snapshots

For a browser-friendly stable path, open:

- `docs/apple-native-validation/index.html`
- `docs/apple-native-validation/history.html`

## Legacy FrontLoader Notes

For existing web-only users of Asset Pipeline:

- import maps and FrontLoader remain supported
- automatic cache clearing remains available
- the older docs are still the right reference for purely web-asset usage

Start with:

- `docs/FRAMEWORK_INTEGRATION.md`
- `docs/USAGE_EXAMPLES.md`
- `docs/API_REFERENCE.md`
- generated API docs in `docs/`

## Status

The Apple-native work is finally at the point where the repo should be treated
as a real native UI and host-integration project, not just an experiment with
screenshots. The remaining work is mostly around deeper platform packaging and
contributor ergonomics, not whether the core surface exists.
