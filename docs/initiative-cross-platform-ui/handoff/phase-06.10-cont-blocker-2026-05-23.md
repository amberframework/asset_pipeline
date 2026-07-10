# Phase 6.10 Continuation — iOS Sim Navigation Blocker

**Date:** 2026-05-23
**Branch:** `phase-06.10-navigable-crud-demo`
**HEAD:** `b075f29`
**Range:** `7fdd0c8` → `b075f29` (5 new commits)
**Reporter:** Implementer Continuation

## TL;DR

iOS host BUILDS + LAUNCHES + RENDERS the initial Sign In screen. Navigation does NOT work end-to-end. After investigation, the root cause is more likely **the UIKit renderer not bridging Crystal's accessibility_label / interaction wiring to UIKit's accessibility tree** than the NavigationCoordinator → SwiftUI @State chain (the latter has not been exercised because no tap ever reaches a Crystal Button).

## Status

**D1 (macOS host):** SHIPPED + green. `make -C samples/initiative-cross-platform-ui-voyager macos` exits 0. Offscreen screenshot capture at `/tmp/voyager-macos-signin.png` confirms the Sign In screen renders. Codex Checkpoint 1: no blockers.

**D2 (iOS host):** App builds + launches (`** BUILD SUCCEEDED **`, `** TEST SUCCEEDED **`), but **the navigation does NOT work end-to-end in the iOS Simulator.** All 4 screenshots from the testNavigationFlow XCUITest show the same Sign In screen at `/tmp/voyager-ios-step-{1,2,3,4}.png`. Tap → push → on_change → SwiftUI re-render chain is not propagating.

## What ships in this continuation (commits)

| SHA | Subject |
|-----|---------|
| `315ca03` | Voyager macOS host + Makefile macos target |
| `34dc2fd` | Voyager iOS bridge.cr + build_crystal_lib.sh |
| `(merged into D2)` | Voyager iOS Swift host (VoyagerApp + ContentView + Bridge) + project.yml + UITests |
| `b075f29` | Address Codex Checkpoint 2 blocker — lazy-allocate slug buffer (iOS class-init gap) |

## Manual iOS Sim verification — FAIL

The owner's primary success criterion: launch iOS Simulator + tap through Sign In → Todos → Settings → back → see filtered list. Observed:

- **Step 1 (launch):** Sign In screen renders. "Voyager" wordmark + "Sign in to manage your todos" subtitle + Email + Password fields + teal "Sign in" button all visible. Screenshot: `/tmp/voyager-ios-step-1.png`.
- **Step 2 (after `app.buttons["Sign in"].tap()`):** **Same Sign In screen.** No navigation occurred. `/tmp/voyager-ios-step-2.png` is byte-identical to step 1.
- **Step 3 (after Settings tap attempt):** Same Sign In screen.
- **Step 4 (after Back to Todos tap attempt):** Same Sign In screen.

The XCUITest `testNavigationFlow` reports PASS only because the test uses `waitForExistence(timeout: 5)` followed by `if … .tap()` without assertions — the buttons it queries never exist with the expected labels, so no tap fires, and the test concludes successfully without ever asserting state change. This is a test-quality bug independent of the navigation issue, but it masked the real failure.

## Root cause analysis (two suspect chains, only one can be diagnosed without further work)

### Suspect 1 (CONFIRMED — accessibility label mismatch on the rendered button)

`samples/initiative-cross-platform-ui-voyager/screens/sign_in.cr` line 58 sets:

```crystal
submit.accessibility_label = "Sign in to your account"
```

…while the UITest queries `app.buttons["Sign in"]`. XCUITest matches the accessibility label, not the visible button title. So the test query returned a non-existent element, `tap()` was never called, and the navigation chain was never exercised. **Step 2 never represented a tap.**

### Suspect 2 (UNTESTED — Crystal-Proc → on_change → Swift Combine chain may still be broken)

Even with the test fixed to tap the right element, the deeper question — whether a Crystal-side `Button.on_tap = -> { coord.push(...) }` Proc, fired from inside a UIKit `UIControl.touchUpInside` event, correctly:

  1. Reaches the Crystal Proc (CallbackRegistry pin survives across UIKit event dispatch)
  2. Calls `coord.push(...)` which mutates the routes array
  3. Fires the on_change callbacks synchronously
  4. The on_change callback invokes the Swift @convention(c) function pointer (`@@swift_route_changed_cb`)
  5. The Swift trampoline copies the slug string, hops to main queue, sends on the PassthroughSubject
  6. ContentView's `.onReceive` updates `@State var slug`
  7. SwiftUI re-evaluates body, VoyagerHost's updateUIView runs, swaps the container's subview to the freshly rendered route view

…remains UNTESTED. Any one of these 7 hops could be broken. Most likely candidates:

- **Hop 1:** Crystal's GC may collect the captured Proc once the UIKit button retains only the C function pointer that calls back into Crystal. The UIKit renderer's `visit Button` SHOULD register the Proc in `UI::CallbackRegistry` to keep it alive — but I did not audit whether that's the case in this code path under -Dios with `_main` hidden. The class-init gap could also have left `CallbackRegistry`'s class state uninitialised. Note: I added `UI::Probes::*.reset` calls in `initialize_runtime` but did NOT add a CallbackRegistry reset/init, which may be required.
- **Hop 4:** The `@@swift_route_changed_cb` is registered by `voyager_register_route_changed_callback` which Swift calls from `VoyagerBridge.initialize`. `initialize_runtime` runs once at first `voyager_render` call inside ContentView's onAppear; the C-level register call happens RIGHT AFTER `voyager_init` returns. There's no ordering bug there. But if the Proc-to-`(LibC::Char* -> Void)?` Crystal type didn't survive the C ABI round-trip — e.g. if Crystal stored only a thin closure pointer that doesn't compose with `@convention(c)` — the call could segfault. I did not test on a path that actually fires the callback.
- **Hop 7:** SwiftUI's UIViewRepresentable updates can be quirky when the underlying view changes identity. The VoyagerHost.updateUIView path I implemented removes subviews and adds a fresh Crystal-rendered view; this should work but I have not seen it execute.

## What's needed to close

### Immediate (15 minutes if Suspect 1 is the whole story)

1. Fix the SignInScreen button's accessibility label to match: `submit.accessibility_label = "Sign in"`. Or alternately, update the test query: `app.buttons["Sign in to your account"]`. The accessibility label IS the screen reader text; "Sign in" is sufficient.
2. Apply same audit to Settings link target on `screens/todos.cr` and the back button on `screens/settings.cr` (both must have predictable accessibility labels the UITest can query).
3. Re-run testNavigationFlow + manually verify in the simulator.

### Deep-dive (if Suspect 2 also bites — likely 2-4 hours)

1. Add a `CallbackRegistry` reset/init call to `VoyagerBridge.initialize_runtime` in `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr` if the registry uses class-var state that the iOS class-init gap silently skips.
2. Add Crystal-side `STDERR.puts` logging (writing to a NSLog-equivalent on iOS — see `samples/cross_platform/ios_host/hig_bridge.cr` for the workaround) inside `coord.on_change` callback to confirm hop 3 fires when a button is tapped.
3. Verify hop 4 (Swift trampoline invocation) by setting a Swift breakpoint in `VoyagerBridge.routeChangedThunk` and observing whether it's hit on tap.
4. If hop 5 fires but hop 6 doesn't, the issue is the Combine subject lifecycle — switch from PassthroughSubject to CurrentValueSubject so late subscribers see the last value, or restructure ContentView to use `@StateObject` + `@Published` instead of `.onReceive`.
5. If hop 7 doesn't fire, force the SwiftUI re-render by giving VoyagerHost an `.id(slug)` modifier in ContentView's body — that forces SwiftUI to discard + recreate the wrapper on slug change, which calls `makeUIView` fresh instead of `updateUIView`.

## What works (don't regress)

- `crystal spec`: 1490/4/0 (unchanged from baseline + 35 new spec). 4 pre-existing failures.
- Web build: `make -C samples/initiative-cross-platform-ui-voyager web` produces `output/voyager-demo/voyager-{light,dark}.html` correctly. The web-side state-propagation litmus PASSES (verified by prior Implementer; not re-verified here since no web changes).
- Cascade macOS build closure: unchanged.
- Cascade iOS build closure: unchanged.
- **Voyager macOS host**: builds + renders Sign In via offscreen capture at `/tmp/voyager-macos-signin.png`. Cannot conclude that navigation works on macOS without an AppKit interactive run (the screenshot path skips the run loop). The macOS host wires `coord.on_change` to `setContentView:`, which is a simpler chain than iOS — only Crystal-side, no SwiftUI involvement. **Likely works** but unverified end-to-end.

## Files touched in continuation

```
samples/initiative-cross-platform-ui-voyager/macos/host.cr                            (new, 122 lines)
samples/initiative-cross-platform-ui-voyager/Makefile                                 (modified, +macos + ios targets)
samples/initiative-cross-platform-ui-voyager/ios/bridge.cr                            (new, ~170 lines)
samples/initiative-cross-platform-ui-voyager/ios/build_crystal_lib.sh                 (new, mirror Cascade)
samples/initiative-cross-platform-ui-voyager/ios/Sources/Voyager-Bridging-Header.h    (new, 14 lines)
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerApp.swift             (new, 70 lines)
samples/initiative-cross-platform-ui-voyager/ios/Sources/VoyagerBridge.swift          (new, 65 lines)
samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift            (new, 95 lines)
samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift     (new, 95 lines)
samples/initiative-cross-platform-ui-voyager/ios/project.yml                          (new, 51 lines)
```

## Post-handoff follow-up: Suspect 1 fix attempted + new evidence

After writing the initial draft above, I applied the Suspect 1 fix (changed `submit.accessibility_label = "Sign in to your account"` to `"Sign in"` on `screens/sign_in.cr` plus aligned `screens/todos.cr` "Open settings" → "Settings" and `screens/settings.cr` back button to "Back to todos"). I also strengthened the UITest with `XCTAssertTrue(...waitForExistence)` so the test fails honestly instead of silently passing.

Rebuilt + reran `xcodebuild test -only-testing:VoyagerDemoUITests/VoyagerVisualTests/testNavigationFlow`:

```
VoyagerVisualTests.swift:67: XCTAssertTrue failed - Sign in button not found on launch
** TEST FAILED **
```

So even with the accessibility label aligned to the visible title, XCUITest cannot find the button. The exported accessibility tree from the failing test (`/tmp/voyager-attachments2/B7354E18-...txt`) shows:

```
Application, label: 'VoyagerDemo'
  Window (Main), 320x480
    Other, 320x480
      Other, 320x480
      Other, 320x480
        Other, 320x480
          Other, 320x480
            ScrollView, 320x480
              (NO CHILDREN)
```

**Diagnosis (revised):** The Crystal UIKit-rendered UIView subtree is NOT exposed to UIKit accessibility. The ScrollView's subview chain ends here — XCUITest cannot see the Button, the Labels, or the TextFields. This means accessibility_label set on the Crystal view side isn't being propagated to UIView.accessibilityLabel + isAccessibilityElement on the AppKit/UIKit-rendered counterparts, OR a parent container has `isAccessibilityElement = false` that masks children.

Also notable: window reports `{{0,0},{320,480}}` not the iPhone 17's actual `{0,0,1206,2622}`. The screenshot earlier showed the full screen — so this 320x480 may be a stale/early accessibility snapshot, or the SwiftUI host frame may be reporting wrong bounds to UIKit accessibility. Either way, the children of the ScrollView (where the Crystal-rendered UIView lives) are absent from the tree.

### Implications for next iteration

The accessibility-label alignment is correct and should stay. But the deeper fix requires AUDITING the UIKit renderer's `visit_button` / `visit_label` / `visit_text_field` to confirm they set:
  - `accessibilityLabel` on the UIView
  - `isAccessibilityElement = true` on leaf elements (Buttons, TextFields, Labels)
  - `isAccessibilityElement = false` on container Views (VStack-mapped UIView, root containers)
  - The accessibility tree isn't blocked by a parent with `accessibilityElementsHidden = true`

This is a Phase 6.10+ remediation, NOT a one-line fix. Until that lands, the iOS host's button taps are effectively a no-op from XCUITest's perspective — and likely also from VoiceOver's perspective. Manual physical taps in the Sim with a mouse may still work (the UIButton's touchUpInside fires regardless of accessibility), but I could not validate that without an interactive XCUITest path or manual driving via simctl coordinate taps (the simctl tool doesn't expose simulator coordinate tapping in the booted sim — the only path is via XCUITest, which is itself blocked).

I propose to commit the accessibility-label cleanups (correctness improvements regardless) + the UITest hardening as a partial step. **Net: the deferred work the prior Implementer flagged still needs another full iteration, scoped to UIKit-accessibility-tree audit + repair before testing the route-change chain.**

## Codex checkpoint trail

| # | Phase | Verdict | Notes |
|---|-------|---------|-------|
| 1 | D1 (macOS) | PASS (no blockers) | Code structure + link pattern + build all match Cascade |
| 2 | D2 (iOS) | BLOCKER → fixed in `b075f29` | Class-var Bytes.new(64) initializer skipped by iOS class-init gap → lazy-allocate in initialize_runtime |

## Recommended next step

Treat the accessibility-label mismatch as the leading hypothesis (Suspect 1). Apply the 15-minute fix above, re-run the UITest, AND manually launch in the Sim + finger-tap. If the navigation works, great. If not, fall back to the Suspect 2 deep-dive checklist.

— Implementer Continuation
