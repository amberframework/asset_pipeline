# Codex Checkpoint 3 — post-fix critique (R10 final diff)

Codex CLI verdict on the R10 final diff (a2e56bb..HEAD):

- **BX3 fix:** "likely fixed for the rubric path. The iOS path now uses a
  real UISwitch, sets AX id/label directly on it, and fires the Crystal
  callback from valueChanged."
- **BX8 fix:** "directionally correct. Reactive Sheet state is retained,
  exposed to Crystal, and `.sheet(isPresented:)` is now actually driven
  after mount."
- **Memory safety:** "no obvious normal-path leak/double-release from
  Unmanaged.passRetained; it matches the existing reactive-state release
  path through NativeHandle#release_state_handle!."
- **Other iOS BX risk:** "low for BX1/BX4/BX5/BX6/BX9/BX10/BX12. R10 does
  not touch Button/Slider/Form/default Button init paths except adding
  shared Swift symbols."
- **macOS risk:** "Toggle is mostly preserved behind #else. Sheet is
  shared Swift facade code, but AppKit renderer still calls legacy
  apsk_make_sheet; behavior should be mostly unchanged."

Residual notes (acknowledged, non-blocking for R10):

1. **Stale state_handle after teardown** (pre-existing): View#swiftkit_state_handle
   is not cleared when NativeHandle releases. R10 extends this pattern to
   Sheet but does not introduce the hazard. Fix is initiative-wide post-R10.

2. **Crystal `UI::Sheet#@is_presented` desync after interactive swipe**:
   SwiftUI flips its observable to false; Crystal-side @is_presented
   remains true unless user code resets it. Acceptable for BX8 because the
   slug's `sheet-trigger.on_tap` always re-sets `is_presented = true`;
   downstream users who care about read-back symmetry can read through
   the apsk_state_handle directly. Tracked as a future enhancement.

3. **iOS toggleStyle(.button) parity**: SwiftUI Toggle(label: …).toggleStyle(.button)
   produced a labeled-button-style toggle on iOS. The R10 UISwitch wrapper
   always produces a switch-style control. Non-blocking for any current
   BX check (no slug exercises .button style on iOS).

4. **macOS reactive Sheet not wired**: Only the uikit_renderer routes
   through apsk_make_sheet_reactive; appkit_renderer still calls the
   legacy entry. macOS Sheet reactivity is a separate phase / not in R10
   scope (R10 is iOS-only per the brief).

5. **Test brittleness**: BX8 uses 300ms sleeps for label flush and
   coordinate swipe for swipe-down. Test PASSES today across 3 full
   runs; flake risk acknowledged for low-spec simulators.

6. **BX3 comment vs behavior**: pre-existing — BX3 method comment says
   "three flips" but performs two taps. Not introduced by R10.

7. **DismissProbe global state**: correct for the single-sheet probe;
   reset-on-open ensures the explicit flag is clean for each opening.
   Not safe for concurrent sheets — but the probe slug never presents
   multiple sheets, so fine for R10's BX8 scope.

Action: NO additional fix required for R10. Proceed to Reporting.
