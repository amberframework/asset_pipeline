# Plan: Platform Extensions (iOS + macOS)

**Scope:** macOS + iOS only. watchOS extensions (complications) deferred — see `hig-watchos-followup.md`.

Platform extensions aren't standard `UI::View` renders — they declare surfaces the OS renders on the user's behalf (Home Screen, Lock Screen, Dynamic Island, Spotlight, notification center). They need dedicated abstractions in `src/ui/extensions/` that compile to Swift extension target sources + Info.plist artifacts.

Every extension in this plan uses the Amber brand (`.claude/skills/apple-platform-guide/brand/amber.md`) so the validation captures read as a coherent product.

## Components in this plan

### Tier 1 — declarative surfaces (Info.plist / AppIntents)

- **`UI::Extensions::AppShortcut`** — wraps iOS `AppIntents.AppShortcutsProvider`. Compiles to a Swift stub declaring shortcut phrases + icons + intent targets. Amber's set: "Start focus ritual", "Note in vault", "Summon morning pages".
- **`UI::Extensions::QuickAction`** — wraps `UIApplicationShortcutItem` via Info.plist. Amber's long-press shortcuts: "New sketch · plus.square", "Vault search · magnifyingglass", "Quick capture · wand.and.stars".

### Tier 2 — widget family (WidgetKit)

- **`UI::Extensions::Widget`** with properties `timeline_provider`, `supported_families`, `entry_view : Proc(Entry) -> UI::View`. Compiles to WidgetKit extension target (`.appex`).
- Families supported (iOS): `.systemSmall`, `.systemMedium`, `.systemLarge`, `.systemExtraLarge`, `.accessoryRectangular`, `.accessoryCircular`, `.accessoryInline`.
- Families supported (macOS): `.systemSmall`, `.systemMedium`, `.systemLarge`, `.systemExtraLarge` (macOS widgets via Notification Center widget extension).
- Amber widget content: "Today's distortion · 3 tasks dreamed into being", "Focus streak · 7 days", "Current ritual · Morning pages".
- Captures: each family validated against a home-screen/lock-screen/notification-center backdrop.

### Tier 3 — live activities (ActivityKit)

- **`UI::Extensions::LiveActivity`** with `attributes`, `lock_screen_view`, `dynamic_island_compact`, `dynamic_island_expanded`, `dynamic_island_minimal`. Compiles to ActivityKit widget extension target.
- iOS only (ActivityKit doesn't exist on macOS).
- Amber's live activity: "Focus ritual in progress" with elapsed time, current mode, pause button.
- Captures per activity: 4 presentation states (lock screen, Dynamic Island compact, expanded, minimal) × 2 appearances = 8 captures per activity slug.

### Tier 4 — notification content

- **`UI::Extensions::NotificationContent`** — declares notification category + actions + expanded-content view. Uses `UNNotificationContentExtension` protocol. Applies on iOS; macOS has limited custom-notification support.
- Amber's notifications: "Ritual complete · 2h 14m of deep work logged", "Garden reminder · 3 thoughts ready to sprout".
- Captures: lock-screen banner, expanded tap, notification-center stacked.

## Architecture

```
src/ui/extensions/
  app_shortcut.cr           # UI::Extensions::AppShortcut
  quick_action.cr           # UI::Extensions::QuickAction
  widget.cr                 # UI::Extensions::Widget
  live_activity.cr          # UI::Extensions::LiveActivity
  notification_content.cr   # UI::Extensions::NotificationContent

src/generators/extensions/
  app_shortcut_provider.cr  # emits AppShortcutsProvider.swift + Info.plist
  quick_actions.cr          # emits Info.plist UIApplicationShortcutItems block
  widget_extension.cr       # emits WidgetKit extension target + .appex bundle
  live_activity_extension.cr
  notification_content_ext.cr
```

The `UI::View` tree inside each extension's `entry_view` / `lock_screen_view` / etc. is rendered by the existing AppKit/UIKit renderers. Only the extension *container* needs new code. This means Amber's VStack/Button/Label work inside widgets for free — we don't re-implement the view catalog inside extensions.

## Validation approach

Each extension slug gets a 4-appearance capture set, **composited against realistic surface mocks** rather than floating in a blank host:

- Widgets: composited against `home-screen-amber-wallpaper.jpg` (small family), notification-center mock (medium), lock-screen mock (accessory families).
- Live Activities: composited against a lock screen mock (dark) + a Dynamic Island crop of iPhone 14 Pro+ status area.
- Notifications: composited against a lock screen with banner + notification center with stacked notifications.
- App Shortcuts: composited against Spotlight search result mock + Shortcuts app row mock.

These mocks are part of the Phase 0 backdrop library.

## Acceptance bar

Same 12 rules from the beauty re-validation plan, **plus** extension-specific rules:

- **E1 — Extension target builds cleanly.** Generated Swift + Info.plist compiles as a shippable extension, not a shim.
- **E2 — Extension is identifiable as Amber.** Palette + typography + content match `amber.md`.
- **E3 — Surface-specific constraints respected.** Widget size constraints hit exactly (e.g., small widget is 158×158pt @1x on iOS). Dynamic Island leading/trailing regions don't overlap system chrome.
- **E4 — Content at reduced scales remains legible.** Accessory widgets (circular, inline) have minimum 11pt text, high contrast. Dynamic Island compact has at most 2 tokens of information.

Design-critic agent applies both the base 12 rules AND these 4 extension-specific rules.

## Execution order (8 iterations)

1. **E.1 — `UI::Extensions::AppShortcut`** — simplest (all declaration, no visual).
2. **E.2 — `UI::Extensions::QuickAction`** — similar pattern to 1.
3. **E.3 — Widget extension scaffolding** — the generator that emits a full WidgetKit extension target. Validate with a single `.systemSmall` Amber widget ("Focus streak").
4. **E.4 — Widget families: medium, large, extra_large.** Iterate over each.
5. **E.5 — Widget accessory families: rectangular, circular, inline.** Validate against lock screen + Apple Watch–style mocks.
6. **E.6 — `UI::Extensions::LiveActivity`** — Dynamic Island + lock screen.
7. **E.7 — `UI::Extensions::NotificationContent`** — expanded-content extension.
8. **E.8 — Sweep pass:** re-run critic against all extension slugs together to check Amber coherence across the whole extension surface.

## What needs user intervention

- Amber persona approval (done — `brand/amber.md` landed).
- Backdrop aesthetic approval for the 3 new extension-specific backdrops: home-screen wallpaper, lock-screen dark, Dynamic Island crop. (User review gate after Phase 0 of the beauty plan.)
- Developer signing identity — **not needed for validation**, only for actual device installs. Validation runs in simulator.
- One-time: confirm Amber's live-activity activity type name and widget bundle identifier prefix (e.g., `com.amber.framework.widget`).

## Deliverable

- Shippable extension generators that consumers can use in their own Amber-based apps.
- Dashboard coverage of every extension family against realistic surface mocks.
- Amber coherent across extensions AND main-app views — a reviewer should perceive a single brand, not "app" and "widget" as separate products.
