# Phase 6.10 — Remediation 4 Brief

**Date opened:** 2026-05-23
**Authored by:** Architect (Seth-approved scope)
**Branch:** `phase-06.10-navigable-crud-demo` (continue from `b1bd8ef`)
**Codex protocol:** Per-iteration critique on EVERY iteration. No self-assessment. If Codex times out twice on the same iteration, STOP and escalate.
**Closing gate:** Owner hands-on verification on iPhone 17 Pro Sim AND macOS bin.

---

## Why this remediation exists

Owner hand-tested Rem 3's iOS build (iPhone 17 Pro) and confirmed:

**Working:**
- Sign-in tap fires + navigates to Todos (Path A is solid).
- Scroll-to-reveal works on Todos (Layer A UIScrollView wrap).
- Add Todo tap navigates to Editor.
- Save tap navigates back from Editor.
- Hardware keyboard input works in TextFields.
- (Soft keyboard sim issue was a Cmd+K simulator config quirk, NOT a library bug — disregard.)

**Broken (verbatim):**

1. **"The window does not actually take up the entire screen of the phone, like not even close. It's chopped off at the tops and bottoms. And I think if it wasn't, this content would actually fit and I'd be able to see like the added to do button on the screen. I don't know how else to describe this other than the aspect ratio is clearly wrong. Like we're clearly limiting the height too significantly."**

2. **"When I hit add to do, it takes me to the screen. Every input that I click on... I can type and I can hit save, but there's nothing appearing here in this list."** Save → Todos list re-render is broken.

**Owner direction:** *"I think what we need to do here is adjust our utilities to better account for the size of the device. And we know what these nice screens are. So we should account for it and build that in as part of what we're doing."*

Architect interpretation: ship **device-aware framework utilities** that respect the OS's runtime screen + safe-area APIs (NOT baked-in per-device dimensions). Tokens get semantic breakpoints; iOS host queries the device for actual bounds; screens consume utilities that adapt at runtime.

---

## Scope — 3 items, all must close

### 1. Save-propagation fix

**Symptom:** Editor.save → coord.pop → returns to Todos, but the new todo doesn't appear in the list. Crystal state-propagation spec passes (5/0), so the bug is at the Crystal→native render boundary, not in the state model.

**Investigation chain (do in order, stop when found):**

1. Is `Editor`'s Save button's `on_tap` Proc actually wired to a state mutation (`state.todos << new_todo` or equivalent)? Read `samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr` and follow the Proc.
2. After `state.todos << new_todo`, does the Editor call `coord.pop`?
3. Does `coord.on_change` fire after the pop? (NSLog instrument to verify.)
4. When `on_change` fires, does the iOS host's content swap actually call `Voyager.build_route(state, coord, :voyager_todos)` with the UPDATED state? Or is it building from a stale state reference?
5. If `build_route` is called with current state, does the Todos screen function read the live state and produce a tree with the new todo? (Verify by logging the tree's child count.)
6. If the tree contains the new row, does `VoyagerHost.updateUIView` actually swap the rendered UIView, or is it a no-op?

**Likely culprit (architect's hypothesis to test first):** SwiftUI's `UIViewRepresentable` uses `.id(slug)` to force fresh `makeUIView` on slug change. But popping from Editor back to Todos has the SAME slug as before — so `.id(slug)` doesn't force a rebuild, and `updateUIView` (if implemented as a no-op) silently keeps the stale view. The fix: include a state-version counter in the `.id()` AND/OR implement `updateUIView` to actually call `bridge.render(slug)` and replace the content view.

**Acceptance:** Owner taps Add Todo → types title → taps Save → returns to Todos → the new todo appears in the list immediately. Chart counts update. State-propagation litmus continues to pass for Settings → toggle → back → Todos.

### 2. Framework device-aware utilities (the big architectural piece)

**Owner's concern (verbatim):** "Adjust our utilities to better account for the size of the device."

**Architect's read:** Don't bake iPhone-model dimensions into design tokens (that creates a maintenance burden for every new device). Instead, ship utilities that:

- **Query the OS at runtime** for actual device bounds + safe areas (iOS:
  `UIScreen.main.bounds` + `view.safeAreaInsets`; macOS:
  `NSScreen.mainScreen.frame`).
- **Apply via semantic tokens** in `design_tokens.cr`: compact/regular/large
  size classes (matching Apple's `UITraitCollection.horizontalSizeClass` +
  `verticalSizeClass`) rather than device-named breakpoints.
- **Provide a `UI::Screen` wrapper** (or equivalent root convention) that
  iOS/macOS renderers know to extend to full window bounds with safe-area
  awareness. Authors write `UI::Screen.new(...)` and don't think about
  the host sizing.

**Required deliverables:**

A. **iOS host fills full device screen.** Fix `samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift` (and any equivalent framework helper in the SwiftKit bridge) to:
   - Use `.ignoresSafeArea(.all)` on the outer SwiftUI host so the Crystal-rendered content gets the full window.
   - OR explicitly set the UIWindow's `rootViewController.view` to fill `UIScreen.main.bounds`.
   - The library's iOS host pattern should produce full-screen-by-default. Black bars top/bottom is unacceptable.

B. **Safe-area-aware layout tokens.** Extend `src/ui/design_tokens.cr` (or a sibling utilities file) with:
   - `safe_area_top`, `safe_area_bottom`, `safe_area_leading`, `safe_area_trailing` semantic values that renderers resolve to the OS's actual safe-area insets at runtime.
   - Use cases: a sticky header that respects the status bar; a bottom action bar that respects the home indicator.

C. **Size-class breakpoints.** Add `compact_horizontal`, `regular_horizontal`, `compact_vertical`, `regular_vertical` semantic values that map to `UITraitCollection` size classes on iOS, NSWindow size thresholds on macOS, and viewport width on web.

D. **Root-fill utility.** Either:
   - Introduce `UI::Screen` as a new top-level view component that wraps a child and tells the renderer "I am a full-screen root, size me accordingly."
   - OR add a `root_fill: true` flag to existing root containers (VStack, ZStack) that triggers the same behavior.
   - Pick whichever has lower churn against existing code; `UI::Screen` is cleaner long-term but adds a new view type.

E. **Voyager screens use the new utilities.** Sign-in, Todos, Settings, Editor all wrap their content with the new root-fill pattern. Verify on iPhone 17 Pro that all 4 screens fill the screen edge-to-edge (no black bars top/bottom), respect safe areas (content not under the Dynamic Island or home indicator), and scroll where needed.

**Design constraint:** Do NOT hardcode iPhone 17 Pro dimensions (402×874). The library should work on iPhone 16, 17, 17 Pro, iPad, future devices — by reading the OS's runtime dimensions, not baking per-device numbers.

**Acceptance:**
- iPhone 17 Pro sim screenshot: all 4 Voyager screens fill the device screen edge-to-edge (no black bars), top respects Dynamic Island, bottom respects home indicator.
- Resize test on macOS: shrink the window to mobile width, content reflows; expand to desktop width, content reflows. (Existing fluid-resize from Phase 2 should already do this on web; verify it works on macOS native bin too.)
- `crystal spec` baseline preserved.

### 3. Off-screen Sign-in button frame (carry-over from Rem 3)

**Symptom:** Sign-in button reports AX frame `{-20, 320.7, 380, 40.3}` — extends 20pt off the left edge of the iPhone 17 Pro screen. Hand-tap works because most of the button is visible, but XCUITest can't synthesize taps because "activation point invalid."

**Likely cause:** Spacer or constraint conflict in the iOS layout pass — the button's width constraint is producing a wider-than-screen value with a negative leading offset. Investigate the Sign-in screen's VStack + button width path in the UIKit renderer.

**Acceptance:** Sign-in button frame's x-origin >= 0 and x+width <= screen width on iPhone 17 Pro. XCUITest can synthesize a tap on the button.

---

## Codex protocol — NO EXCEPTIONS

Every code-touching iteration gets a real Codex review at `handoff/phase-06.10-remediation-4-codex-N.md`. Self-assessment is NOT acceptable.

If Codex times out: retry. If twice on same iteration: STOP, write `handoff/phase-06.10-remediation-4-codex-blocker.md`, escalate.

---

## Hands-on gate (unchanged)

After all 3 items close + Codex reviews complete, owner runs the iOS Sim flow + macOS bin flow. Architect closes Phase 6.10 ONLY after owner's green signal.

---

## What's explicitly NOT in scope

- Cascade demo modifications.
- Audit-harness routing for `voyager-*` slugs.
- SwiftUI native `.swipeActions(edge:)` facade.
- Android renderer changes.
- URL routing / deep links.
- Adding new widgets beyond `UI::Screen` if chosen as the root-fill pattern.
- Path B (raw UIButton) — still rejected.
- Hardware-keyboard / soft-keyboard sim quirks (confirmed not a library bug).

---

## Reporting

Write `handoff/phase-06.10-remediation-4-implementer-report.md` covering per-item status, commit trail, proof artifact paths, regression numbers, hand-test commands. Return to architect.

**Required proof artifacts:**
- iPhone 17 Pro screenshots of all 4 Voyager screens showing edge-to-edge fill.
- Before/after screenshot of Todos AFTER saving a new todo (proves Save propagation).
- macOS window-resize captures showing fluid reflow.
- NSLog or Crystal-side logging proving the Save-propagation chain at each step (1-6 from Item 1 investigation).

— Architect
