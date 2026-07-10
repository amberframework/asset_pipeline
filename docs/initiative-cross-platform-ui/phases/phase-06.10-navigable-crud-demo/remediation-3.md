# Phase 6.10 — Remediation 3 Brief

**Date opened:** 2026-05-23
**Authored by:** Architect (Seth-approved scope + path decisions)
**Branch:** `phase-06.10-navigable-crud-demo` (continue from `fddb3f1`)
**Codex protocol:** Per-iteration critique on EVERY iteration. No self-assessment. If Codex times out twice on the same iteration, STOP and escalate.
**Closing gate:** Owner hands-on verification on iOS Sim AND macOS bin.

---

## Why this remediation exists

Rem 2 (commits up to `fddb3f1`) proved Item 1 is an **architectural
bug**, not a wiring oversight: SwiftUI Buttons hosted in
`UIHostingController` instances added as UIStackView subviews never
fire their `action:` closures. 11 XCUITest variants with NSLog
instrumentation confirmed this — the diagnostic work is gold and
preserved at
`handoff/phase-06.10-remediation-2-codex-blocker.md`.

Rem 2 also delivered:
- **Item 2 PASS:** `.accessibilityElement(children: .contain)` on
  VoyagerHost + dropping the outer SwiftUI ScrollView made the
  AX subtree traversable; XCUITest finds labeled buttons.
- **Item 3 partial:** macOS all 4 screens correct; iOS Sign-in
  correct; iOS Todos/Settings/Editor content extends below viewport
  because the outer SwiftUI ScrollView had to be dropped for Item 2.

Rem 3 closes:
- **Item 1** via **Path A (VC parenting)** — architect's chosen direction.
- **Item 3 iOS overflow** via **framework default + explicit override** — both layers.
- **NEW: iOS Editor crash** surfaced during Rem 2 evidence capture — pulled into Rem 3 scope per architect.

---

## Scope — 3 items, all must close

### 1. Path A — UIHostingController VC parenting

**Root cause (confirmed):** SwiftUI's `Button` action closure requires
the hosting `UIHostingController` to be registered in the responder
chain via proper VC parenting (`addChild` + `didMove(toParent:)`).
Without it, SwiftUI's gesture scheduler never wires the action.

**Fix location:** `SwiftKit/Sources/.../HostingHelpers.swift` (or
wherever `HostingHelpers.host(...)` lives). The fix applies to ALL
SwiftUI facades that ride through HostingHelpers — Button, Toggle,
Slider, all reactive entry points. Fix once, fix everywhere.

**Required Swift change:**

```swift
extension HostingHelpers {
  static func host<Content: View>(_ rootView: Content) -> UIView {
    let controller = UIHostingController(rootView: rootView)
    let view = controller.view!

    // Register as child VC when the view enters a window.
    // The responder chain doesn't exist until then.
    let observer = WillMoveToWindowObserver { window in
      guard window != nil else { return }
      if let parent = view.findParentViewController() {
        parent.addChild(controller)
        controller.didMove(toParent: parent)
      }
    }
    objc_setAssociatedObject(view, &observerKey, observer, .OBJC_ASSOCIATION_RETAIN)
    objc_setAssociatedObject(view, &controllerKey, controller, .OBJC_ASSOCIATION_RETAIN)
    return view
  }
}

// UIView extension to walk responder chain
extension UIView {
  func findParentViewController() -> UIViewController? {
    var next: UIResponder? = self
    while let r = next?.next {
      if let vc = r as? UIViewController { return vc }
      next = r
    }
    return nil
  }
}
```

(The actual implementation must match the existing HostingHelpers
patterns. Use `view.willMove(toWindow:)` swizzling OR a wrapper
view-controller approach if associated-object observation doesn't
exist in the codebase. Whatever idiom HostingHelpers already uses for
lifecycle hooks, extend it.)

**Required proof artifacts (do not skip):**

- **Instrumented log proof on iOS** — the existing
  `voyager-interaction-proof` NSLog statement in
  `CallbackBridge.fire(token:value:)` must fire when the Sign-in
  button is tapped. Drive via XCUITest coordinate tap or
  `xcrun simctl ui booted gesture` if available, OR via the SwiftUI
  Button's known-good tap synthesis path that now works post-fix.
  Capture log stream via `xcrun simctl spawn booted log stream
  --predicate 'process == "VoyagerDemo"'`. Save to
  `handoff/phase-06.10-remediation-3-interaction-proof-ios.txt`.
- **Before/after navigation screenshots on iOS** — capture sign-in
  screen, drive the tap, capture again, confirm Todos screen
  rendered. Save to
  `handoff/phase-06.10-remediation-3-nav-proof-ios-{before,after}.png`.
- **Same proof on macOS** — same NSButton/SwiftUI-via-AppKit chain.
  Drive click via `cliclick`, AppleScript System Events, or AXTest's
  press helper. Capture log + screenshots. Save to
  `handoff/phase-06.10-remediation-3-{interaction-proof,nav-proof}-macos*`.
- **Cross-facade smoke check** — Path A fixes HostingHelpers; verify
  Toggle and Slider also work post-fix. Add a quick smoke test (e.g.
  add a debug Toggle to Voyager Settings if not already there) and
  capture log proof that its on_change fires when toggled.

**Remove the temporary NSLog after the proof captures are saved.**
Preserve the captures as the architect's audit trail.

**Acceptance:** All four proof artifacts present, log shows the
`voyager-interaction-proof` line, screenshots differ. The
diagnostic NSLog grep-token `voyager-interaction-proof` removed
from the tree.

### 2. iOS Todos/Settings/Editor overflow — both framework default + explicit override

Per architect decision, ship BOTH layers:

**Layer A (framework default):** The iOS host (VoyagerHost
UIViewRepresentable in `ContentView.swift`, or the framework's
equivalent host helper) should wrap the Crystal-rendered root in a
`UIScrollView` when the rendered content's height exceeds the host's
bounds. This means most iOS screens scroll gracefully by default
without authors thinking about it.

Implementation sketch:

```swift
struct VoyagerHost: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    let rendered = bridge.render(slug)
    let scroll = UIScrollView()
    scroll.addSubview(rendered)
    // pin rendered.leadingAnchor + topAnchor to scroll
    // pin scroll.contentLayoutGuide width to scroll.frameLayoutGuide width
    // (vertical scrolling only)
    return scroll
  }
}
```

UIScrollView is AX-traversable (XCUITest can walk through it without
the `.contain` modifier needed for SwiftUI ScrollView). Keeping it
on the UIKit side preserves Item 2's AX traversal win.

**Layer B (explicit override):** Voyager screen authoring opts into
explicit `UI::ScrollView` wrapping for screens that want it. For
Sign-in (which should NOT scroll — should fit on screen and look
intentional), authors can pass a flag or use a non-scrolling host
variant. For Todos / Settings / Editor (which can have arbitrary
content lengths), explicit `UI::ScrollView` wrapping makes the
intent visible.

**Recommendation for Voyager screens:**
- Sign-in: no UI::ScrollView; framework default handles overflow if
  needed (but the screen fits at iPhone 17 dimensions).
- Todos: wrap content in UI::ScrollView (list could grow).
- Settings: wrap content in UI::ScrollView (forward-compat for more
  options).
- Editor: wrap content in UI::ScrollView (forward-compat).

**Acceptance:** iOS sim screenshots show:
- Todos: chart + full list + Settings button + Add Todo all visible
  (either on-screen or scrollable into view).
- Settings: title + Hide-completed toggle + back button all visible
  (either on-screen or scrollable).
- Editor: title field + note field + completed toggle + Save/Cancel
  all visible (either on-screen or scrollable).

### 3. iOS Editor silent crash on direct-slug launch

**Symptom (per Rem 2 evidence capture):** Launching the Voyager iOS
app with starting route `voyager-todo-editor` crashes silently. No
log line, no crash dialog (or the crash dialog is dismissed too fast
for capture). The `.md` placeholder in
`docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-2-evidence/`
notes the symptom but doesn't diagnose.

**Investigation steps:**

1. Reproduce with verbose logging: `xcrun simctl spawn booted log
   stream --level=debug --predicate 'process == "VoyagerDemo"'`
   while launching.
2. Check the crash logs in `~/Library/Logs/DiagnosticReports/` or
   `~/Library/Logs/CoreSimulator/<sim-UUID>/`.
3. Likely candidates:
   - The Editor screen requires a state-loaded todo (it edits an
     existing todo); on a fresh launch with no state setup, the
     screen tries to access `state.current_todo.title` or similar
     and hits a `nil` dereference.
   - The TodoEditor screen's coordinator binding expects a route
     param (`:todo_id`) that the direct-slug launch doesn't provide.
   - A missing renderer visit (TextField with binding to nil) blows
     up in `apsk_text_field_bind_*`.

4. Once root cause identified, fix at the appropriate layer:
   - If state initialization issue: Voyager state initializer needs
     to handle the "no todo selected" case (e.g. create a blank one).
   - If route-param issue: route resolution needs a sensible default
     or error path.
   - If renderer issue: file a separate bug, propose a fix.

**Acceptance:** `VOYAGER_ROOT_SLUG=voyager-todo-editor` launch on iOS
sim either:
- Renders the editor with a blank or sensible default todo, OR
- Logs a clear error message and recovers (renders an empty Editor
  with a "no todo selected" message), NOT silently crashes.

---

## Codex protocol — NO EXCEPTIONS

Same as Rem 2. Every code-touching iteration gets a Codex review at
`handoff/phase-06.10-remediation-3-codex-N.md`. Self-assessment is
not acceptable. If Codex times out twice on the same iteration: STOP,
write `handoff/phase-06.10-remediation-3-codex-blocker.md`, escalate
to architect.

---

## Hands-on gate (unchanged)

After all 3 items close + Codex reviews complete, owner runs the
12-step iOS flow + 4-step macOS flow from `remediation-1.md`.
Architect closes the phase ONLY after owner's green signal.

---

## What's explicitly NOT in scope

- Cascade demo modifications.
- Audit-harness routing for `voyager-*` slugs.
- SwiftUI native `.swipeActions(edge:)` facade.
- Android renderer changes.
- URL routing / deep links.
- Adding new widgets.
- Path B (raw UIButton) — explicitly rejected by architect.

---

## Reporting

Write `handoff/phase-06.10-remediation-3-implementer-report.md`
covering per-item status, commit trail, proof artifact paths,
regression numbers, and the hand-test commands. Return to architect.
Do NOT declare the phase passed.

— Architect
