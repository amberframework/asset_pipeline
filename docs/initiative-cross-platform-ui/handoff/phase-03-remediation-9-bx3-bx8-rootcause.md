# Phase 3 Remediation 9 — BX3 + BX8 root-cause investigation and partial fix

**Status:** R9 ships the BX8 library-level fix (Crystal class-variable init gap closed). BX3 is re-deferred with diagnostic evidence proving the Crystal/Swift callback chain works on coordinate taps; the failure is in the SwiftUI `XCUIElement.tap()` / AX-activate routing under the UIHostingController + UIViewRepresentable hosting topology. Two library-side fix attempts (`.accessibilityAction { ... }` and `.accessibilityAction(.default) { ... }`) were rejected by tests and by Codex critique.

## Headline

| Check | Pre-R9 | Post-R9 | Notes |
|-------|--------|---------|-------|
| BX1  | PASS | PASS | unchanged |
| BX2 (macOS) | PASS | PASS | unchanged |
| BX3 (iOS Toggle) | FAIL | **FAIL** | Crystal callback chain proven working on coord taps; `XCUIElement.tap()` AX path still broken. Two library fix attempts failed. See "BX3 deferral evidence" below. |
| BX4 | PASS | PASS | unchanged |
| BX5 | PASS | PASS | unchanged |
| BX6 | PASS | PASS | unchanged |
| BX7 | PASS | PASS | unchanged |
| BX8 (iOS Sheet) | FAIL (launch crash) | **FAIL** (different mode) | Original launch crash FIXED — host renders cleanly. Test still fails because it expects sheet content inline in the AX tree, but the iOS Sheet facade uses `.sheet(isPresented:)` and hides content until presented. Separate slug/test wiring issue. |
| BX9  | PASS | PASS | unchanged |
| BX10 (light + dark) | PASS | PASS | unchanged |
| BX11 (macOS) | PASS | PASS | unchanged |
| BX12 | PASS | PASS | unchanged |

`swift test` 53/53 PASS. `crystal spec` 1330 examples / 4 pre-existing failures unrelated to R9 (verified via stash-pop test on the R8 HEAD commit). All macOS AXTest specs pass.

## BX8 — root cause + fix

### Root cause as proven by data

The dismiss-reason Label in the sheet probe slug is constructed with `UI::Probes::DismissProbe.current_text` which returns the class variable `@@last_reason : String = "none"`. **The class-variable initialiser never runs on iOS** because:

- Crystal emits class-var initialisers into `__crystal_main`.
- The iOS embedding hides `_main` via `ld -r -unexported_symbol _main` in `build_crystal_lib.sh` (to avoid clashing with Swift's `@main`).
- SwiftUI enters Crystal through `crystal_render_slug`, not through `__crystal_main`.
- The class variable therefore holds its zero-initialised value (nil) instead of `"none"`.

Reading `@@last_reason` returns nil; `UI::Label.new(nil_string)` yields a Label whose `@text` field is a nil String pointer. Visiting that Label in the UIKit renderer calls `text.bytesize` on a nil String, which dereferences a near-zero pointer → `KERN_INVALID_ADDRESS at 0x4`. The original R8 crash signature (`strlen` from `apsk_nsstring`) was the same nil-text issue surfacing one frame deeper through the FFI when the original Crystal code didn't catch the nil before crossing the boundary.

### Diagnostic evidence chain (all in `/tmp/r9-evidence-bx8.md` and `/tmp/r9-codex-postdiag-bx8.md`)

1. Baseline reproduction confirmed (R8 launch crash still reproduces on `f469fd0` HEAD).
2. Staged instrumentation (`STAGE_A` … `STAGE_E`) in `visit(UI::Label)` showed crash happens AFTER `populate_label` completes and BEFORE `text = view.text` returns.
3. Custom `UI::Label.r9_raw_text_addr` debug method (loads `@text.as(Void*).address` with NO String method calls) revealed the dismiss-reason Label's `@text` slot holds `0x0000000000000000` from the moment of construction in the slug-build closure.
4. Construction-site instrumentation in `hig_bridge.cr` confirmed `DismissProbe.current_text` returns 0x0 — the class variable is nil at the very first read.
5. The "Confirm action" Label (a String literal, not a class variable) renders cleanly — confirming that String LITERALS (encoded in `.rodata`) work; only class-variable-backed Strings break.
6. Codex Checkpoint-2 critique (`/tmp/r9-codex-postdiag-bx8.md`) confirmed the chain rules out the prior R8 hypotheses (render_detached corruption, Array(View) type-erasure GC) and accepts the class-var init gap as the proven root cause.
7. Codex Checkpoint-3 critique (`/tmp/r9-codex-prefix-bx8.md`) approved the proposed fix scope.

### Fix (landed)

`samples/cross_platform/ios_host/hig_bridge.cr`:

```crystal
def self.initialize_runtime
  return if @@initialized
  GC.init
  # iOS-specific seeding — see commit message + handoff doc
  UI::Probes::DismissProbe.reset
  UI::Probes::ToggleProbe.reset
  UI::Probes::SliderProbe.reset
  UI::Probes::TapProbe.reset
  UI::Probes::FormRowProbe.reset
  UI::Probes::RuntimeOverrideProbe.reset
  @@initialized = true
end
```

Effect: host no longer crashes at launch with `HIG_SLUG=phase-03-sheet-focus-return`. Render produces the expected "Open sheet" trigger and the "none" mirror label.

### Remaining BX8 gap (NOT part of R9 root cause)

The test still fails because it asserts `app.buttons["sheet-primary"].exists` immediately after launch, but the iOS `UI::Sheet` facade uses `.sheet(isPresented: $storage.binding)` with `isPresented = false` by default — the content is hidden until the trigger button opens the sheet. Two follow-up items are required to make BX8 fully green:

1. Wire `ios_sheet_trigger.on_tap` in the slug builder to set `is_presented = true` on the Sheet (requires a Crystal-side Sheet state link or a new `is_presented_token` callback).
2. Update `testBX8_sheetDismissReturnsFocus` to tap the trigger before asserting sheet-primary.exists (the rubric in `validation.md` §BX8 specifies this flow).

Both are downstream test/wiring scope, not library-level R9 work.

### Generalised Crystal-iOS class-init gap (acknowledged, out-of-scope)

The same root cause affects three observed call sites:
- `UI::Probes::DismissProbe.@@last_reason` (and any other probe class vars) — fixed for the probes by `initialize_runtime` seeding.
- `STDERR` and any other lazy-initialised Crystal constants — `STDERR.const_read` calls `Crystal::once` → `Fiber::current` → `Thread::current` → `Thread::new` → `Thread::LinkedList(Fiber)#push` which crashes because the LinkedList is uninitialised.
- `Float::Printer::Dragonbox::ImplInfo_Float64` lookup table — uninitialised, so any `Float64#to_s` (and therefore Crystal `String#interpolation` containing a Float64) crashes.

Phase 5 / a future remediation should design a proper "Crystal runtime init from Swift" entry point that runs `__crystal_main`'s class-var/constant init phase without entering main's main-loop logic. Until then, downstream Crystal-iOS code must not touch lazy-initialised constants from Swift-driven entry paths.

## BX3 — root cause partial proof + deferral

### What is proven

The Crystal/Swift/SwiftUI callback chain works correctly. Instrumented evidence (in `/tmp/r9-evidence-bx3.md`) shows:

- A coordinate tap at the Toggle's geometric center (and at `nx=0.5`, `nx=0.9`, and the absolute window coord (72, 231)) **does flip the switch and propagates through the entire chain**: `BoolStorage.value` updates, `.onChange` fires, `CallbackBridge.fire(token, value)` runs, Crystal `ap_swiftkit_invoke_action` executes, `invoke_swiftkit` resolves the float_callbacks box, the registered Toggle on_change Proc fires with `v=1.0`, `UI::Probes::ToggleProbe.set(true)` runs, `ios_toggle_value.text="true"` triggers `Label#text=`, `apsk_label_set_text` mutates the `@Published APSKLabelState.text`, and the mirror Text re-renders showing "true".
- The captured JSON attachment shows toggle.value transitioning `0 → 1 → 0` and probe.label transitioning `false → true → false` across coord taps.

### What is NOT proven

The exact reason `XCUIElement.tap()` does not trigger the same chain. Two leading hypotheses:

1. SwiftUI's `XCUIElement.tap()` synthesises an AX-activate event that does NOT match the SwiftUI Toggle's internal isOn-flip path under the current UIHostingController + UIViewRepresentable hosting topology.
2. `.tap()` routes through UIKit's UISwitch action handler directly, but that action is not wired to the SwiftUI Binding under the inline hosting model.

Both interpretations point at the same scope: a hosting-topology change OR a UIKit UISwitch wrapper would be required. Per Codex Checkpoint-3, that is an architectural rewrite and is deliberately out-of-scope for R9.

### Fix attempts that failed

1. **`.accessibilityAction { storage.value.toggle() }`** inside the `Toggle(...)` modifier chain, after `.contentShape(Rectangle())`. Test still failed identically.
2. **`.accessibilityAction(.default) { storage.value.toggle() }`** applied at the OUTERMOST wrapper of `ToggleHost.body` (after `.toggleStyle(...)`, after `.disabled(...)`, before `CommonModifiers.apply`). The `.default` action-kind is documented as overriding the system's primary activation. Test still failed identically.

Both attempts were reverted. The `.accessibilityAction(...)` modifier does NOT divert `XCUIElement.tap()` under this hosting. Codex Checkpoint-3 acknowledged that beyond these two attempts, the next plausible fix (UIKit UISwitch wrapper / child-VC hosting / `.accessibilityRepresentation`) constitutes architectural rewrite.

### Recommended next steps (when BX3 is picked up again)

Per Codex's R9-final critique:

1. Add app-side `UIWindow.sendEvent` / `hitTest` logging to distinguish hypothesis 1 from hypothesis 2.
2. If hypothesis 1 holds, try `.accessibilityRepresentation { Toggle(...) }` or a custom AX element that overrides the activation kind.
3. If hypothesis 2 holds, replace the SwiftUI Toggle with a UIKit `UISwitch` wrapped in a `UIViewRepresentable` that binds to `@Published storage.value` directly. This is the architectural rewrite Codex flagged.

### Deferral checklist — completion status

Per the R9 dispatch brief's 7-point bar:

| # | Item | Status |
|---|------|--------|
| 1 | Baseline reproduction confirmed | YES (R8 failure mode reproduces on `f469fd0` HEAD) |
| 2 | Safe instrumentation captured | YES for Crystal-side callback chain (`/tmp/r9-evidence-bx3.md`); incomplete for the AX/tap delivery path (would require UIWindow.sendEvent logging) |
| 3 | Debugger evidence captured | N/A — BX3 does not crash; the test just observes wrong behaviour. Coord-tap-vs-element-tap diff IS the equivalent diagnostic. |
| 4 | Sanitizer / Guard Malloc | N/A — no memory corruption; not applicable to BX3 |
| 5 | Working-vs-failing differential | YES — coord taps flip switch + chain; element tap doesn't |
| 6 | Codex critique on captured evidence | YES (4 critique rounds: `/tmp/r9-codex-postdiag-bx3.md`, `/tmp/r9-codex-prefix-bx3.md`, plus follow-up on the second fix attempt) |
| 7 | At least one ownership/hit-test/lifetime experiment falsified or confirmed | YES — falsified R8's "binding doesn't fire" hypothesis; falsified two `.accessibilityAction(...)` library-side fixes |

R9 reports BX3 deferral with full evidence chain per Codex.

## Files changed

- `samples/cross_platform/ios_host/hig_bridge.cr` — `initialize_runtime` seeds probe class variables (BX8 fix).
- Validation: no other library changes land. All ToggleFacade.swift / uikit_renderer.cr / probes / etc. revert to pre-R9 state once instrumentation is removed.

## Artifacts kept (for audit)

- `/tmp/r9-evidence-bx3.md`
- `/tmp/r9-evidence-bx8.md`
- `/tmp/r9-codex-postdiag-bx3.md`
- `/tmp/r9-codex-postdiag-bx8.md`
- `/tmp/r9-codex-prefix-bx3.md`
- `/tmp/r9-codex-prefix-bx8.md`
- `/tmp/r9-codex-bx3-deferral.md`
- `/tmp/r9-bx3-attachments/*.json` (XCUITest captures from `testBX3_instrumentation` — the diagnostic-only test that was added during R9 and reverted)
- `/tmp/r9-baseline-bx3.xcresult`
- `/tmp/r9-postfix-regression.xcresult`
- Crash reports `~/Library/Logs/DiagnosticReports/CrystalHIGHost-2026-05-21-*.ips`
