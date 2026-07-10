# Plan (deferred): watchOS HIG coverage

**Status:** deferred pending new Xcode target setup. Trigger: user adds "pick this up now" to the queue.

## Scope when we resume

- New Xcode target: `samples/cross_platform/watchos_host/` with a WatchKit app + extension.
- Renderer: `src/ui/renderers/watchkit_renderer.cr` (visitor pattern, like AppKit/UIKit).
- Capture pipeline: XCUIScreen.main.screenshot on watchOS simulator, composited against watch-face mocks.
- Components newly in scope: `complications` (ClockKit/WidgetKit), the watchOS flavors of sheets/alerts/lists, plus watchOS-specific `DigitalCrownView`.

## What needs to happen first

1. User confirms Apple Developer signing identity (for paired-device testing if wanted) or simulator-only.
2. Scaffold the watchOS Xcode target programmatically (same pattern used for iOS host).
3. Build `UI::WatchKit::Renderer` — this is non-trivial because watchOS uses WatchKit views, not UIKit.
4. Add `watchos_light` / `watchos_dark` to the capture matrix — captures become 6-up instead of 4-up, or watchOS gets its own slug set.
5. Re-queue `complications`, `watch-faces` (guidance only, no code), and a new `digital-crown` slug.

## Open questions

- Does asset_pipeline actually target watchOS developers, or is this aspirational? If aspirational, this deferred plan is documentation; if actual, it's a Q2 roadmap item.
- User has a personal Apple Watch — do we validate on-device or simulator-only? Device testing requires signing + paired-device debug configuration.
- Does watchOS content follow Amber persona, or does watchOS need its own sub-persona (e.g., "Amber micro" — even tighter voice for the small screen)?

## Recommendation

Hold this plan until the macOS + iOS validation is PASS-bar clean across the board. watchOS is a multiplier on work already in motion — finishing what's started is higher leverage.
