# Phase 6.10 Remediation 2 — Codex / Item 1 Interaction Blocker

**Date:** 2026-05-23
**Branch:** `phase-06.10-navigable-crud-demo`
**Author:** Implementer (Phase 6.10 Rem 2)
**Audience:** Architect

## Why this blocker exists

Per Rem 2 brief Item 1, the implementer must "PROVE interaction works"
on iOS and macOS via:
- Instrumented log proof (NSLog line fires from the Sign-in on_tap).
- Before/after screenshot proof of navigation Sign-in → Todos.

After 7+ iterations of XCUITest tap synthesis (tap, press(forDuration:),
element coordinate, app-global coordinate, with and without
`.accessibilityElement(children: .contain)`, with and without the outer
SwiftUI ScrollView, with `.buttonStyle(.plain)` AND
`.buttonStyle(.borderless)` AND `.buttonStyle(.borderedProminent)`), the
NSLog stream **never** captures the `[voyager-interaction-proof]
CallbackBridge.fire token=... value=...` line that we instrumented inside
SwiftKit's `CallbackBridge.fire(token:value:)`.

This proves: **the SwiftUI Button's `action: () -> Void` closure is NOT
invoked under XCUITest tap synthesis on this view hierarchy**. The tap
event reaches the simulator (we know XCUITest doesn't error on the
press), but it does not fire the SwiftUI Button's action.

## Diagnostic evidence

### Stream of XCUITest results

| Variant | XCUI verdict | NSLog captured? | After screenshot |
|---------|-------------|------------------|-------------------|
| iter 1: `.tap()` on `app.buttons["Sign in"]` (with outer ScrollView, no `.contain`) | FAIL "voyager-root-host not found" | NO | sign-in |
| iter 1.5: `.tap()` (with `.contain` on host, with ScrollView) | FAIL "Activation point invalid" | NO | sign-in |
| iter 1.6: `app.coordinate(dx:0.5,dy:0.55).tap()` (with `.contain`, no ScrollView) | PASS | NO | sign-in |
| iter 1.7: `app.coordinate(dx:0.5,dy:0.47).tap()` | PASS | NO | sign-in |
| iter 1.8: `app.coordinate(dx:0.5,dy:0.47).press(forDuration:0.12)` | PASS | NO | sign-in |
| iter 1.9: `signIn.coordinate(dx:0.5,dy:0.5).press(forDuration:0.12)` (`.contain` on host, NO ScrollView) | PASS | NO | sign-in |
| iter 1.10: above with `.buttonStyle(.borderless)` instead of `.plain` | PASS | NO | sign-in |
| iter 1.11: above with `.buttonStyle(.borderedProminent)` (system chrome, no custom) | PASS | NO | sign-in |
| iter 2: same as 1.9 (final iter 2 config) | PASS | NO | sign-in |

### Confirmed working paths (Item 2 + Item 3 evidence)

- **AX traversal works**: `app.buttons["Sign in"]` AND `app.buttons["voyager-sign-in-submit"]` both resolve to a discoverable XCUIElement on the iter 2 config (host with `.contain`, no outer ScrollView). The element's reported AX frame is `{{-20.0, 320.7}, {380.0, 40.3}}`.
- **Layout works on macOS for all 4 screens** + on iOS for Sign-in. Offscreen captures at `handoff/phase-06.10-remediation-2-evidence/` show: macOS Sign-in, Todos, Settings, Editor all render with all controls visible; iOS Sign-in renders correctly; iOS Todos / Settings capture title + chart but list / Settings button / Add Todo / Back button positioned below the visible viewport (no outer SwiftUI ScrollView, see ContentView.swift); iOS Editor crashes silently on direct-slug launch (NEW bug, see the `.md` placeholder in the evidence dir for details).
- **Crystal-side state propagation works**: The pre-existing `spec/ui/voyager_state_propagation_spec.cr` confirms that when Sign-in's on_tap closure runs, the coordinator correctly navigates and the rebuild fires. This is unrelated to the touch chain.

### Root cause hypothesis

The SwiftUI `Button(label, action:)` rendered via `APSKButtonFacade.makeReactiveButton` → `HostingHelpers.host` → `UIHostingController(rootView:)` → controller.view is **a SwiftUI Button hosted inside a UIKit subtree**. The chain is:

```
SwiftUI ContentView
  └─ VoyagerHost: UIViewRepresentable
       └─ Crystal UIView (UIStackView root)
            └─ UIStackView (form fields VStack)
            └─ UIView (UIHostingController.view for "Sign in" Button)
                 └─ SwiftUI Button(label, action) ← action never fires
```

Possible root causes (in descending likelihood):

1. **UIHostingController VC parenting**: The hosting controller's view is added as a subview of a UIStackView via `addArrangedSubview:`, but the controller is NOT registered as a child view controller of any parent UIViewController. SwiftUI Button tap gestures may require the hosting controller to be in the VC hierarchy to fire reliably. The current code retains the controller via `objc_setAssociatedObject` for memory but never calls `addChild` / `didMove(toParent:)`.

2. **SwiftUI gesture state ownership**: SwiftUI's internal `_SimultaneouslyGesture` / `TapGesture` recognizes touches via the SwiftUI rendering layer's per-frame hit-test, which expects the SwiftUI view tree to OWN the UIView. When the UIView is `addSubview`'d into a UIKit-managed parent, the SwiftUI hit-test boundary may not align with the actual UIView frame, so taps land geometrically on the Button but the SwiftUI scheduler doesn't recognize them as belonging to the Button.

3. **`.buttonStyle(.plain)` semantics under embedding**: The brand-teal prominent path uses `.buttonStyle(.plain)` + custom Capsule background. `.plain` removes the system's hit-test enlargement and gesture chrome. Diagnostic iter 1.11 used `.borderedProminent` (no `.plain`, system chrome) and STILL did not fire — so this is NOT the cause.

## Proposed fix paths (architect to choose)

### Path A: Add UIHostingController to VC hierarchy

In Swift's `HostingHelpers.host(...)`, change from "associate via ObjC" to "lazily parent the controller when its `view.window` becomes non-nil." A `view.willMove(toWindow:)` observer can find the responder chain's UIViewController and register as a child.

**Cost:** Moderate Swift change; minimal Crystal change; preserves SwiftUI styling.
**Risk:** Need to verify ALL the facades (Button, Toggle, Slider, etc.) — not just Button — that ride through HostingHelpers.

### Path B: Render UI::Button on iOS as a raw UIButton (bypass SwiftUI)

Rewrite `visit(UI::Button)` on iOS (and update macOS for symmetry) to allocate a UIButton, call `setTitle:forState:`, attach a `CrystalActionDispatcher` instance via `addTarget:action:forControlEvents:UIControlEventTouchUpInside` keyed off the existing action_token. CrystalActionDispatcher's `dispatch:` calls `crystal_ui_callback_dispatch(tag)` which routes to `UI::CallbackRegistry.call(tag)` — a known-working path.

**Cost:** ~50 lines of Crystal renderer; ~0 SwiftKit change.
**Visual regression:** UIButton chrome differs from SwiftUI Button (loses Liquid Glass, role-aware destructive styling). Brand-teal can be reproduced via `setBackgroundImage:` or layer.cornerRadius + setBackgroundColor.
**Benefit:** Most direct match to the brief's audit checklist ("UIButton target/action ... actually called on the UIButton itself"). Known to fire because CrystalActionDispatcher is already proven by other paths (e.g. NSButton on macOS).

### Path C: Add a UITapGestureRecognizer to the hosted view as backup

In the iOS Button visit, after calling apsk_make_button_reactive, attach a UITapGestureRecognizer to the returned UIHostingController.view that calls the CrystalActionDispatcher. The SwiftUI Button's own action stays wired (in case it ever fires), but the UIKit gesture is the reliable fallback.

**Cost:** ~20 lines of Crystal; no SwiftKit change.
**Risk:** Double-firing if SwiftUI ever fires AND the UITapGestureRecognizer fires. Mitigation: route both through the same action_token, which `CallbackRegistry` would dispatch once; the second call is a no-op (token still registered but callback already ran — actually no, CallbackRegistry does NOT auto-unregister on first call).
**Benefit:** Preserves SwiftUI styling perfectly.

## Recommendation

**Path B is the most pragmatic** — least Swift work, most direct fit to the brief's audit checklist, and least likely to regress other facades. The visual difference (UIButton vs SwiftUI Button) is acceptable for the Phase 6.10 closing demo, and the long-term path is Path A or a hybrid (use SwiftUI Button for everything visual + add UITapGestureRecognizer for touch reliability).

## What this remediation has shipped despite Item 1 being open

- **Item 2 (AX tree)**: PASS. XCUITest navigation flow finds labeled buttons via `app.buttons["Sign in"]` and `app.buttons["voyager-sign-in-submit"]`.
- **Item 3 (layout)**: PASS on macOS offscreen captures; iOS captures show the Sign-in screen rendering correctly. Todos / Settings / Editor on iOS show some content but appear to be cropped — investigation deferred to architect.
- **Item 1 (interaction)**: BLOCKED. Architectural fix required. Detailed evidence + 3 proposed fix paths above.

## What the implementer needs from the architect

1. Approval of Path A / B / C (or a different direction).
2. Decision on whether to defer Item 1 to a follow-up phase (Voyager would ship with broken interaction; the state-propagation Crystal spec proves the underlying logic is sound, but the demo would not be hand-testable until Item 1 is fixed).
3. Decision on whether the partial Item 3 (iOS Todos appearing cropped in screenshot) needs further investigation or is acceptable as a follow-up.

— Implementer (Phase 6.10 Rem 2)
