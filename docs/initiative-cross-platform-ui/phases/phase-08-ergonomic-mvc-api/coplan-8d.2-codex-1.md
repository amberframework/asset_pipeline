# Phase 8D.2 Co-Planning — Codex Response

**Date:** 2026-05-25
**Codex session:** medium reasoning, arg-form prompt, default model (gpt-5.5)
**Role:** Co-planner. Architect asked for engineering judgment on iOS bridge migration shape + risks.
**Source log:** `/tmp/codex-coplan-8d2.log`

---

## 1. Sub-phase shape

Codex: **Agree — 8D.2 stays one phase.** Narrow architectural change (move from compat shim to dispatcher-backed host model), validation risk is real but isn't a separate phase. Split EXECUTION ROLES inside the phase: code implementer → capture/test runner → owner hands-on. **For 8D.2, interaction is the point** — tagging without interaction proof would repeat 8D.1's open note.

**Architect adopts.** No further sub-phase splitting. Mid-stop pattern split is dispatch-mechanics only, not phase-mechanics.

## 2. Open questions

### Q1 — Initial slug resync: direct `mount_screen + replace_root`

Codex: **Use the direct pair.** Honest for this case: Swift isn't asking Crystal to perform an app action; it's telling Crystal "render this initial slug." There's no controller action, no `ActionResult` to translate. The dispatcher already exposes the right primitive. Don't add a new host-driven API in 8D.2 unless implementation proves duplicated policy.

**Architect adopts.** Brief specifies direct mount-before-replace_root with `@@suppress_route_changed` window.

### Q2 — `Voyager.dispatcher` class-var slot vs per-host

Codex: **Keep the class-var slot.** macOS+iOS coexisting in one process isn't a real deployment shape. Settle in the brief as an intentional demo-level singleton bridge, not the long-term cross-platform host model.

**Architect adopts.** Brief includes a "Future work" note: a real multi-host design would move action dispatch into captured host context.

### Q3 — XCUITest coverage in 8D.2

Codex: **Yes — add one XCUITest smoke.** Crystal-only coverage isn't enough because the bug being closed crosses Crystal → UIKit-rendered callback → dispatcher → coordinator → C callback → Swift DispatchQueue.main.async → SwiftUI state → voyager_render. Minimum: cold launch, tap Sign In, assert Todos root appears. Extend to Add Todo → Save → Todos if not flaky.

**Architect adopts.** Sign-in dispatch is the hard XCUITest minimum. Add Todo → Save extension is "nice-to-have" — brief lists as stretch goal, not gate.

### Q4 — `Voyager.state` global discipline on iOS

Codex: **Yes — iOS must assign `Voyager.state = state` during `initialize_runtime`.** Compat shim currently masks this by reassigning per-render. Once iOS stops calling the shim, that assignment disappears unless 8D.2 adds it. Order: assign state BEFORE constructing coord/dispatcher.

**Architect adopts.** Brief specifies this explicitly.

## 3. Risk additions

Codex adds R7-R11. Architect adopts all five into the brief:

- **R7** — `Voyager.state` divergence after compat shim path removed. Without explicit `Voyager.state = state` in `initialize_runtime`, screens read a lazily-created singleton ≠ bridge's pinned `@@state`.
- **R8** — `Voyager.state ||= State.new` lazy allocation could trigger before bridge assigns the pinned instance. Mitigation: assign before any screen build / dispatcher dispatch / callback registration.
- **R9** — Fresh renderer per render: Swift's `makeUIView` + defensive `updateUIView` can both call `VoyagerBridge.render(slug:)`. Same route renders > once after one mount. Probably okay because `FormState#register` is non-overwriting once a key exists — but Editor prefill + sign-in field registration must NOT depend on "exactly one render after mount."
- **R10** — Async Swift state update vs sync Crystal dispatch. Crystal already mounted next route before Swift renders it. Acceptable for Voyager because no second Crystal-side dispatch fires before the new UIView exists. Must be called out as supported-host assumption.
- **R11** — Crystal-only iOS bridge spec is awkward under normal spec flags. `bridge.cr` is behind `flag?(:ios)` and requires UIKit renderer. A default `crystal spec` invocation may not exercise the bridge. Mitigation: name the exact spec command in the brief, OR downgrade to host-helper spec + rely on XCUITest for the real bridge proof.

## 4. Implementation order

Codex 7-step sequence:
1. `VoyagerApp.bootstrap!` → `state = Voyager::State.new` → `Voyager.state = state`.
2. Add iOS bridge pins (`@@session`, `@@flash`, `@@dispatcher`). All allocations inside `initialize_runtime`.
3. Construct dispatcher → `mount_screen(coord.current)` → `Voyager.dispatcher = dispatcher`.
4. Replace `render_slug` internals: remove `Voyager.build_route(...)`, build `ScreenContext::Native` from dispatcher getters, call `registration_for(route.id).screen_class.new.build(ctx)`, preserve fresh `UIKit::Renderer.new` per render call.
5. Initial slug resync: depth=1+route mismatch → suppress callback → `dispatcher.mount_screen(route)` → `coord.replace_root(route)` → unsuppress in ensure pattern.
6. `coord.on_change` stays renderer-neutral (slug buffer + callback only, no mount).
7. Tests/evidence: Crystal spec (where feasible per R11), iOS simulator build, cold-launch XCUITest Sign In smoke, owner hands-on.

**Architect adopts verbatim.**

## 5. Closing-gate

Codex minimum bar:
- iOS bridge no longer calls `Voyager.build_route`.
- `Voyager.dispatcher` is non-nil after `voyager_init`.
- `Voyager.state` explicitly assigned on iOS.
- First render cold-launches without class-init crash.
- Sign In button works on simulator via XCUITest.
- At least one stateful action manually verified or tested (Add Todo → Save → Todos shows new item, OR Settings toggle rerenders).
- Existing dispatcher integration specs still pass.
- `git diff --check` passes.
- Production Swift C ABI unchanged.

Codex explicitly: **no pixel diff in 8D.2.** Defer to 8D.3 14-row capture matrix.

**Architect adopts.**

## 6. Anything I'm not seeing

Codex flags two architectural confusions in the scoping doc:

- **"Swift side untouched" vs "add XCUITest"** — production Swift + C ABI are frozen; **test Swift can change**. Brief must distinguish.
- **Proposed Crystal unit spec may overpromise.** Because `bridge.cr` is `flag?(:ios)`-gated and renderer-linked, naive `crystal spec` won't exercise it. Brief must name the exact spec command OR downgrade.
- **`@@renderer` is misleading** — `render_slug` creates a fresh renderer per call, so the pinned `@@renderer` doesn't participate in rendering. Brief should not imply a pinned renderer. (Architect: safe to remove the pin entirely as a small cleanup.)

**Architect adopts all three. Brief will:**
1. Restate frozen surface as "C ABI + production Swift" (test Swift is free).
2. Name the spec command pattern + downgrade if needed.
3. Remove the dead `@@renderer` pin OR document why kept.

---

**Architect verdict:** Co-plan is clean. No disagreements. Move to brief v1 directly.

— Architect (Claude Opus 4.7)
