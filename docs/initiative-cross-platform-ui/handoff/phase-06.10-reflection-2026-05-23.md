# Phase 6.10 — Architect Reflection

**Phase:** 6.10 — Navigable CRUD Demo + Navigation Coordinator
**Date closed:** 2026-05-23 (PASS_WITH_NOTES)
**Branch:** `phase-06.10-navigable-crud-demo` (merged to feature branch)
**Final HEAD:** `15bc2bd`
**Tag:** `phase-06.10-pass-with-notes-2026-05-23`

## Verdict

PASS_WITH_NOTES. The phase brief — "navigable Todos CRUD demo + 3 navigation primitives + state-propagation litmus" — is met. The notes capture polish gaps and one architectural lesson that became visible only at the end of the arc.

## What shipped

### Library primitives (real framework work, reusable across demos)

- **`UI::NavigationCoordinator`** — reactive nav state with push / pop / replace_root / pop_to_root / on_change.
- **`UI::SwipeActionRow`** — iOS Mail-style row with leading + trailing actions; native UIKit + AppKit + web impls.
- **Route-host re-render hook** — `UI::Web.render_route_host` for web; macOS NSWindow `setContentView` swap; iOS UIHostingController content swap.
- **Path A — UIHostingController VC parenting** — `APSKAttachingHostingController` subclass installs a sentinel UIView in `viewDidLoad` that drives `addChild`/`didMove(toParent:)` on `didMoveToWindow`. Without this, SwiftUI Button `action:` closures don't fire when the hosting controller is added as a UIStackView subview. Fix applies to ALL SwiftUI facades (Button, Toggle, Slider).
- **AX tree traversal across SwiftUI/UIKit boundary** — `.accessibilityElement(children: .contain)` on the `UIViewRepresentable` host; outer SwiftUI ScrollView dropped (it collapses the AX subtree). XCUITest can now find labeled buttons in Crystal-rendered UIKit subtrees.
- **Device-aware framework utilities** — `UI::DeviceMetrics` reads window bounds on macOS, screen bounds on iOS; safe-area-aware tokens; size-class breakpoints (compact/regular); `root_fill: true` flag on root containers + `UI::Screen` semantic for full-screen layouts.
- **String-callback bridge** — Crystal `CallbackRegistry` extended for string values; Swift `CallbackBridge.fireString` trampoline; SwiftKit `TextFieldFacade` reactive entry points wired through. This is what makes Editor.save → Todos.list re-render work.
- **iOS class-init gap workaround in bridge.cr** — explicit `Thread.init + Fiber.init + Crystal::Once.init` at the top of `initialize_runtime` (per the pattern documented in [[crystal-ios-class-init-gap]]). Direct-slug iOS launches into screens that use `String#to_i?` no longer SIGSEGV.

### Voyager demo

4 screens (Sign-in, Todos, Todo Editor, Settings), web + macOS + iOS hosts, state-propagation litmus that passes at the Crystal contract level (5/0 spec) and demonstrably propagates Save → list update on iOS native after the Rem 4 string-callback bridge landed.

### Audit / verification

XCUITest at `samples/.../ios/UITests/VoyagerVisualTests.swift` with real `XCTAssertTrue(...)` on the propagated todo. Sign-in button frame verified within iPhone 17 Pro screen bounds. macOS resize evidence at 480/880/1280 pt window widths showing fluid reflow.

## Arc — Initial + 4 remediations

| Stage | Closed | Surfaced |
|-------|--------|----------|
| Initial dispatch | 3 primitives + Voyager screens + web host + state spec | macOS + iOS host source deferred |
| Continuation (D1 macOS + D2 iOS) | macOS bin builds; iOS app launches | iOS UIKit AX tree gap; iOS tap-doesn't-fire bug |
| Rem 1 | VStack/HStack default spacing; simplified VoyagerHost matching Cascade; Sign-in screen visually correct | Owner hand-test surfaced THREE deeper bugs: window not full-screen, fields overlapping, button at top |
| Rem 2 | XCUITest AX traversal via `.accessibilityElement(children: .contain)`; proven (via NSLog instrumentation in 11 XCUITest variants) that SwiftUI Buttons hosted in UIHostingController don't fire actions without VC parenting | Architectural fix needed; 3 paths proposed |
| Rem 3 | Path A VC parenting shipped; iOS host fills more of screen; Todos/Settings scroll via UIScrollView wrap; iOS Editor crash fixed (class-init gap) | Owner hand-test: window still not full-screen on iPhone 17 Pro; Save doesn't propagate to Todos list |
| Rem 4 + continuation | Save propagation via string-callback bridge; framework device-aware utilities; root_fill flag; macOS DeviceMetrics returns window bounds | Brand override produces low-contrast text on iOS + macOS; macOS window not width-resizable, opens "arbitrarily extremely wide"; SwiftUI defaults preferable over current brand override |

## What stayed open (handed to Phase 6.11)

- **iOS legibility under brand override** — Voyager's deep-indigo brand override produces white-on-off-white text on Todos screen. The library's brand-override path doesn't recompute on-brand text colors for contrast, only the brand color itself.
- **macOS window sizing** — window opens at arbitrary width, width not user-resizable, no min height. Framework gap in the macOS host pattern.
- **macOS legibility** — even more compounded than iOS; same root cause class plus the per-screen `HStack { title; Spacer; settings }` collapses oddly at narrow widths.
- **Functional polish** — type a todo, hit save, see it appear, toggle complete in-row, swipe-delete actually deletes, edit updates row. Owner specifically called out that "polish to ship-quality" is bigger than the brief.

These are scoped into Phase 6.11 — "iOS-first polish with SwiftUI defaults" — see `phases/phase-06.11-ios-polish-defaults/README.md`.

## Lessons (worth remembering)

### 1. NSLog grep-token instrumentation cracks native interaction bugs

[[native-interaction-instrumentation]] — Rem 2's diagnostic NSLog inside `CallbackBridge.fire` with a unique token (`voyager-interaction-proof`) is what unlocked Path A. Without that proof, we'd still be guessing at "matches Cascade pattern." Adopting this as a standing rule for native interaction work.

### 2. Owner hands-on testing is the only legitimate close criterion for native interactive demos

[[owner-hands-on-finds-real-bugs]] — each remediation's audit harness PASSed, but each owner hand-test surfaced a deeper layer (visual layout → AX tree → interaction wiring → frame correctness → brand-override contrast). Audit harness catches component-level rendering; only hand-test catches integration. Phase briefs for interactive native work must list hand-test as the closing gate.

### 3. Codex per-iteration discipline pays for itself

Rem 4's diagnostic NSLog (a password leak in `CallbackBridge.fireString`) would have shipped silently without Codex re-review. The protocol caught it before commit. Continuing the per-iteration Codex requirement for native work in Phase 6.11.

### 4. Architectural fixes ripple — diagnose deeply before implementing

The Implementer's first instinct in Rem 2 was to recommend Path B (raw UIButton bypass), which would have lost SwiftUI's HIG-native styling on iOS. Path A (VC parenting in HostingHelpers) was a smaller, deeper, more correct fix that benefited every SwiftUI facade, not just Button. [[plan-what-to-understand-not-just-what-to-build]] — when an architecture-level bug surfaces, take the architect-level fix, not the workaround.

### 5. Brand override needs contrast-pair recomputation

Naive brand override sets `brand_primary` to a new hue without telling the renderer to recompute the contrast-correct text color for surfaces using that brand color. Result: white text on off-white surfaces when the override clashes with system color defaults. Phase 6.11's "drop the override, use defaults" demonstrates the binding chain works; the right long-term fix is semantic contrast pairs in design tokens. Don't add brand-override docs/tutorials until this gap is closed.

## Bookkeeping

- 28 commits on `phase-06.10-navigable-crud-demo` (initial 12 + Rem 1: 5 + Rem 2: 4 + Rem 3: 4 + Rem 4: 4 = 28 ahead of `b1bd8ef`'s parent).
- 1 tag: `phase-06.10-pass-with-notes-2026-05-23` at `15bc2bd`.
- Handoff trail: 4 implementer reports + 11+ Codex review files + 1 blocker + 1 completion-blocker + this reflection + owner hands-on findings + 4 remediation briefs.
- Evidence captures in `phase-06.10-remediation-4-evidence/` and earlier per-rem directories.

— Architect (Claude Opus 4.7)
