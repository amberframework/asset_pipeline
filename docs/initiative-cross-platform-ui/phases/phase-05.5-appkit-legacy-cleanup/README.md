# Phase 5.5 — AppKit + UIKit Legacy Material Cleanup

**Inserted:** 2026-05-22, immediately after Phase 5 v2 PASS.
**Dependencies:** Phase 5 v2 PASS (tag `phase-05-v2-pass-2026-05-22`).
**Blocking:** None — Phase 6.5 + Phase 6 can run in parallel.

## Scope

Delete the 12 dead-code `_legacy_*` Category B methods — 6 in
`src/ui/renderers/appkit_renderer.cr` and 6 in
`src/ui/renderers/uikit_renderer.cr`:

- `_legacy_tab_view` (both renderers)
- `_legacy_alert` (both renderers)
- `_legacy_navigation_split_view` (both renderers)
- `_legacy_toolbar` (both renderers)
- `_legacy_sheet` (both renderers)
- `_legacy_popover` (both renderers)

Per the Phase 5 v2 architecture (`handoff/phase-05-v2-architecture-2026-05-22.md`
line 9-12) and the Phase 5 carry-forward handoff
(`handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md`), these methods
are NOT on any active visit dispatch path. All 6 widgets route through their
SwiftKit facades (`apsk_make_*`) at runtime — AppKit uses `apsk_make_sheet`,
UIKit uses `apsk_make_sheet_reactive`; otherwise the 5 remaining widget
names match. The `_legacy_*` bodies are preserved historical references
with no callers on the active dispatch path.

## Out of scope

- The `appkit_visual_effect_material(step : Symbol)` Symbol-keyed shim that
  Category C currently delegates to the renamed semantic helper. That shim
  preserves the Phase 5 R3 Symbol entry-point. Decision deferred (callers may
  still exist in samples / docs / specs).
- Web / Android renderer cleanup.
- Any production behavior change. This phase is dead-code deletion only.

## Acceptance

1. `grep -cE '_legacy_(tab_view|alert|navigation_split_view|toolbar|sheet|popover)' src/ui/renderers/appkit_renderer.cr` returns 0.
2. `grep -cE '_legacy_(tab_view|alert|navigation_split_view|toolbar|sheet|popover)' src/ui/renderers/uikit_renderer.cr` returns 0.
3. AppKit Category B facade count `apsk_make_(tab_view|alert|navigation_split_view|toolbar|sheet|popover)` remains 6 (no facade regression).
4. UIKit Category B facade count `apsk_make_(tab_view|alert|navigation_split_view|toolbar|sheet_reactive|popover)` remains 6 (no facade regression; UIKit uses sheet_reactive).
5. macOS host build still exits 0 (`make -C samples/cross_platform/macos_host build`).
6. iOS Crystal-lib build still exits 0 (`bash samples/cross_platform/ios_host/build_crystal_lib.sh simulator`).
7. Web semantic check still exits 0 (`crystal-alpha build --no-codegen src/asset_pipeline.cr`).
8. `crystal spec` exits with the Phase 5 v2 close-out baseline: exactly 4 failures and 0 errors. The 4 acceptable failures (from Phase 5 v2 validation report) are: `crystal spec spec/ui/views_spec.cr:3273`, `spec/components/phase2_verification_spec.cr:52`, `spec/components/phase2_verification_spec.cr:116`, `spec/components/phase2_verification_spec.cr:129`. Any other failure = regression = FAIL.
9. `crystal spec spec/ui/design_tokens/material_spec.cr` exits 0 (31 examples, 0 failures, 0 errors, 0 pending).

## Anticipated work size

≤ 5 commits. Could be 1 commit if all 6 deletions go in atomically. The
Implementer chooses cadence; the contract is the acceptance list.
