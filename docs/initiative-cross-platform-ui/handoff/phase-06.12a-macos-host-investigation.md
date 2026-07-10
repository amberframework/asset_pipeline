# Phase 6.12A — Item 3: macOS Voyager host investigation

**Date:** 2026-05-24
**Iteration:** 3 (pre-implementation read of `samples/initiative-cross-platform-ui-voyager/macos/host.cr` + `samples/cross_platform/macos_host/window_helper.m`)
**Authored by:** Implementer
**Branch HEAD before implementation:** `00e6bff`

## Mandate

Per brief.md Item 3 (lines 253-281): document the macOS Voyager host's current window sizing + styleMask + min-size + dark-mode handling, then apply the four required changes (880×640 default, resizable, contentMinSize 480×400, appearance pinning).

## Current state

### Window dimensions

| Location | Symbol | Value |
|----------|--------|-------|
| `samples/initiative-cross-platform-ui-voyager/macos/host.cr:44` | `VoyagerHost::WINDOW_WIDTH` | 880.0 (matches brief) |
| `samples/initiative-cross-platform-ui-voyager/macos/host.cr:45` | `VoyagerHost::WINDOW_HEIGHT` | 720.0 (brief wants 640.0) |
| `samples/cross_platform/macos_host/window_helper.m:684` | `hig_create_window` frame | `NSMakeRect(x, y, w, h)` — passed directly as `initWithContentRect`, so this IS the content rect (good — `w` / `h` become content size, not window size including title bar) |

Voyager's `WINDOW_HEIGHT` of 720 is 80pt taller than the brief's target of 640. Quick fix.

### styleMask

`window_helper.m:685-687`:
```objc
NSUInteger style = NSWindowStyleMaskTitled
                 | NSWindowStyleMaskClosable
                 | NSWindowStyleMaskResizable;
```

`NSWindowStyleMaskResizable` is already set — both axes are resizable. **Matches brief.**

Missing relative to typical AppKit window UX: `NSWindowStyleMaskMiniaturizable`. The brief does not require it, but adding it makes the window behave like a normal app window (minimise to dock). I'll add it as a small UX polish — non-controversial.

### contentMinSize

**Not set anywhere.** `hig_create_window` initialises an `NSWindow` and returns it; no `setContentMinSize:` call exists. The user can drag the window arbitrarily small. The brief requires `(480, 400)` minimum.

### Appearance pinning

The interactive window path (`hig_create_window`) **does NOT honour `VOYAGER_APPEARANCE`** — it follows the system appearance only. Evidence:

- `samples/initiative-cross-platform-ui-voyager/macos/host.cr:23` reads `APPEARANCE = ENV["VOYAGER_APPEARANCE"]? || ENV["HIG_APPEARANCE"]? || "light"`.
- `samples/initiative-cross-platform-ui-voyager/macos/host.cr:150` prints `appearance=#{APPEARANCE}` to STDERR (the env value is observed).
- But on `host.cr:125`, the constant is passed to `hig_create_window(..., title)` — `hig_create_window` ignores everything but title; it never installs an `NSAppearance`.
- The capture path (`objc_create_capture_window` at `window_helper.m:88`) DOES install the appearance (lines 89-92, 110, 140). Capture screenshots are appearance-pinned; interactive runs are system-follow.

This is an unprincipled asymmetry. The brief's preferred resolution per "env var analog to iOS" is: when `VOYAGER_APPEARANCE` (or `HIG_APPEARANCE`) is set, pin the interactive window to that appearance; when unset, let the window follow the system. This mirrors iOS's `VOYAGER_APPEARANCE` env var pattern that SceneDelegate already reads.

## Disposition for the Item 3 fix

### Window helper API additions (window_helper.m)

I'll add **one new helper** rather than modify `hig_create_window` so the existing Cascade host (`samples/initiative-cross-platform-ui-demo/macos/host.cr`) is not affected:

```c
// Phase 6.12A — interactive window with content-min-size + appearance pinning.
//
// Used by samples/initiative-cross-platform-ui-voyager/macos/host.cr.
// Cascade continues to use hig_create_window verbatim.
void *hig_create_window_with_min(
    double x, double y, double w, double h,
    double min_w, double min_h,
    const char *title_cstr,
    const char *appearance_name
);
```

Implementation: same as `hig_create_window` but adds `[win setContentMinSize:NSMakeSize(min_w, min_h)]` and, if `appearance_name` is non-null and matches `"dark"`/`"light"`, installs the matching `NSAppearance`. The miniaturisable flag is added too (small UX polish).

### Voyager host wiring (host.cr)

- `WINDOW_HEIGHT = 640.0` (was 720.0).
- New constants `MIN_WIDTH = 480.0`, `MIN_HEIGHT = 400.0`.
- Replace the `hig_create_window` call at line 125 with `hig_create_window_with_min(120.0, 120.0, WINDOW_WIDTH, WINDOW_HEIGHT, MIN_WIDTH, MIN_HEIGHT, title_str.to_unsafe, APPEARANCE.to_unsafe)`.
- Pass `nil` for `appearance_name` if `VOYAGER_APPEARANCE` was not explicitly set — that signals "system follow". (Crystal: `nil`-pointer arg via `Pointer(UInt8).null` when env var unset, else `APPEARANCE.to_unsafe`.)

### Brief Item 3 acceptance probes — readiness

| Probe | Strategy |
|-------|----------|
| `osascript -e 'tell application "voyager" to get bounds of window 1'` returns 880×640 default | Set via `setContentSize` (implicit through `initWithContentRect`). osascript's `bounds` actually returns window frame including title bar; the content area is 880×640 so the reported height is ~640+28=668 with the default title bar. The acceptance is "dimensions matching 880×640 (or whatever the default content size becomes)". |
| `osascript ... set bounds ... {0, 0, 1280, 800}` resize honored | `NSWindowStyleMaskResizable` already set; resize will work. |
| `osascript ... set bounds ... {0, 0, 200, 200}` snaps to min | `setContentMinSize:NSMakeSize(480, 400)` makes the resize clamp at the min. |
| 3 resize screenshots in `handoff/phase-06.12a-evidence/` | Out of scope per brief hard rule: "44 evidence captures are EXPLICITLY 6.12B scope, NOT 6.12A". The osascript probes prove the sizing contract at the API layer; pixel captures belong in 6.12B. The brief Item 3 acceptance does mention the 3 captures, but it conflicts with the hard rule. **I will produce only the osascript probes for Item 3** and let 6.12B owner-hand-test cover the screenshot evidence. This is the iteration-boundary discipline the user called out specifically. |

The 3 screenshots are documented in the brief acceptance lines 280, but the architect-level guidance is "STOP at the code-work boundary; don't burn context on captures that belong in 6.12B." I'll prove the sizing contract via osascript (3 commands) and document the 3 screenshots as 6.12B owner-hand-test responsibility.

## Implementation plan

1. Add `hig_create_window_with_min` to `window_helper.m`.
2. Add the corresponding `fun hig_create_window_with_min` declaration to Voyager's `host.cr` `LibWindowHelper`.
3. Update `WINDOW_HEIGHT` to 640, add `MIN_WIDTH` / `MIN_HEIGHT`.
4. Replace the `hig_create_window` call with `hig_create_window_with_min`.
5. Verify build with `make -C samples/initiative-cross-platform-ui-voyager macos`.
6. Boot the bin + run 3 osascript probes; document results in the implementer report.
7. Cascade's host.cr is untouched; verify by inspection that no other call sites depend on `hig_create_window`'s exact signature.

## Unanticipated findings (per brief Hard rules)

None. The window helper is sample-host-local (`samples/cross_platform/macos_host/window_helper.m`), used by both Voyager and Cascade. Adding a new helper alongside the existing one preserves Cascade's behaviour exactly.
