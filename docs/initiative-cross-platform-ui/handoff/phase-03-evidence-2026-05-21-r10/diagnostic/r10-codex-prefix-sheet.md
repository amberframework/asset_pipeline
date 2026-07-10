# Codex Checkpoint 2B — Sheet pre-fix review

Verdict: **APPROVE direction; apply minor adjustments.**

Action items from review:
1. Hoist `ios_sheet_v` declaration before the primary/cancel button blocks
   in the slug (variable-ordering compile fix).
2. Keep legacy `makeSheet(...)` + `apsk_make_sheet(...)` ABI intact as a
   no-op shim; add new `makeReactiveSheet(...)` + `apsk_make_sheet_reactive(...)`.
3. Build SheetHost.body with `@ObservedObject var state: APSKSheetState`
   and bind `.sheet(isPresented: $state.isPresented)` INSIDE the body —
   not a prebuilt binding outside.
4. DO NOT add the AX-boundary workaround until the Gap-3 debug dump proves
   it is needed.
5. Update the ReactiveState.swift comment listing reactive widgets to
   include Sheet.
