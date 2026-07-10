# Phase 4 — Implementer Deviations from the Canonical Brief

This document records every place where my Phase 4 implementation
chose a path that is *equivalent but not literal* to the canonical
brief at
`docs/initiative-cross-platform-ui/phases/phase-04-platform-tier-gating/implementation.md`.
Architect adjudicates whether each is acceptable.

## 1. ContextMenu flag: `flag?(:macos) || flag?(:ios)` (not `flag?(:darwin)`)

**Canonical:** brief uses `{% if flag?(:darwin) %}` as the gate for
ContextMenu.

**Implementation:** uses `{% if flag?(:macos) || flag?(:ios) %}`.

**Rationale:** the existing codebase already standardises on
`flag?(:macos) || flag?(:ios)` (see `src/ui/menu_bar.cr` Phase 3 code).
Adding `:darwin` would re-introduce host-Darwin leakage (the macOS
Crystal compiler always reports `:darwin`) that the project explicitly
moved away from. The dispatch wrapper's "Wrapper factual corrections
that override `implementation.md` stale references" section calls this
out as an authoritative override.

**Codex Checkpoint 2 verdict:** acceptable; Codex specifically warned
against re-adding `:darwin`.

## 2. Compile-time raise mechanism: `macro new` (not class-body `{% raise %}`)

**Canonical:** brief shows the stub class body containing only
`{% raise <<-MSG ... MSG %}`.

**Implementation:** wraps the raise in a `macro new(*args, **kwargs)`
inside the stub class, and moves the stub class to
`src/ui/views/_gate_stubs/<widget>.cr` (required from the else-branch
of the gated file).

**Rationale:** Crystal's macro engine eagerly fires a nested
`{% raise %}` while expanding its enclosing `{% if/else %}` macro. The
brief's literal pattern fails at `require "asset_pipeline/ui"` on
non-iOS builds because the else-branch's `{% raise %}` triggers
during the outer if/else expansion — *not* at construction time.

Splitting the stub into a separate file (required conditionally) and
wrapping the raise in a method macro defers expansion to the
construction call site. This satisfies the brief's developer-facing
contract: writing `UI::ActionSheet.new(...)` without `-Dios` produces
the actionable error.

**Trade-off:** type-only references (e.g. `arr = [] of UI::ActionSheet`)
and `UI::ActionSheet.allocate` still compile. The original brief said
"naming this class is a compile error"; the practical contract is
"constructing this class is a compile error." Comments in the gated
files document this distinction. **Codex Checkpoint 2** flagged this
as a non-blocking caveat and accepted it.

## 3. iOS ActionSheet routing degrades N actions to 2

**Canonical:** brief says the iOS path routes through SwiftKit's
`.confirmationDialog` facade.

**Implementation:** routes through the existing
`ConfirmationDialogFacade` with a conservative mapping:
- first non-cancel action -> confirm button (`:destructive` style
  preserved)
- cancel-style action -> cancel button
- any additional actions are **dropped at render time**

**Rationale:** the Phase 3 facade exposes only two buttons. Extending
the SwiftKit Swift code with a multi-action facade is explicitly out
of scope per the wrapper's "Strict scope discipline" clause. The
limitation is documented in `src/ui/views/action_sheet.cr`'s class
comment and surfaces as a Phase 5 follow-up.

**Codex Checkpoint 2 verdict:** routing is honest; the limitation
is documented; Phase 5 is the correct landing site for a multi-action
SwiftKit facade.

## 4. MenuBar and StatusBar classes gated to Apple-family

**Canonical:** brief says to gate the ContextMenu reference in
`src/ui/menu_bar.cr` with `flag?(:darwin)`.

**Implementation:** gates the entire `class MenuBar` and `class
StatusBar` with `flag?(:macos) || flag?(:ios)`. Non-Apple builds get a
no-op `MenuBars` / `StatusBars` module that returns `false` on
`install` so existing call sites compile without change in behavior.

**Rationale:** UI::MenuBar's `Menu` record carries a non-nilable
`menu : ContextMenu` field. With ContextMenu now Tier 3, that field
cannot exist on non-Apple builds. Gating the whole class is the
cleanest expression of the Apple-family-only nature of these
shell-chrome models. **Codex Checkpoint 4** flagged this as a
regression risk; my position is that this is intentional and
acceptable for Phase 4 because:
1. `UI::MenuBars.install(...)` / `UI::StatusBars.install_item(...)`
   keep working on non-Apple builds (return false).
2. App code that calls `UI::MenuBar.new` on web was already
   non-functional (no menu bar exists on web); Phase 4 makes the
   contract explicit at compile time instead of silently failing at
   runtime.
3. The matching specs are now gated to match.

If a downstream consumer relies on `UI::MenuBar.new` on web for some
data-structure reason (not for actual menu installation), they can
either: build with `-Dmacos` for that build target, or use the new
`UI::ContextMenuWithWebFallback` and roll their own menu-bar shape on
top.

## 5. ContextMenuWithWebFallback carries a `trigger : View?`

**Canonical:** brief's HTML structure shows the trigger as a child of
the host but says "Crystal does NOT inject the trigger; the developer
wires it via the parent view. The host attribute is what the JS hooks."

**Implementation:** adds an optional `trigger : View?` property to
`UI::ContextMenuWithWebFallback`. When set, the web renderer emits the
trigger as the first non-style/non-script child of the host so the
fallback JS's `findTrigger(host)` walk lands on it.

**Rationale:** **Codex Checkpoint 4** identified that without an
in-Crystal way to wire the trigger, the fallback JS could never bind
contextmenu / Shift+F10 listeners — making the web fallback dead on
arrival. Adding a `trigger : View?` is the minimum Crystal-side API
change that lets the JS contract work. When the property is left
`nil`, the menu still renders and can be toggled programmatically by
setting `data-presented` (preserving the brief's "developer wires it"
semantic for callers that need that escape hatch).

**Codex Checkpoint 4 verdict:** this resolves the blocker the
checkpoint flagged.

## 6. Compile-error spec tempfiles live under `tmp/compile-check/`

**Canonical:** brief shows `/tmp/asset-pipeline-compile-check-...cr`.

**Implementation:** uses `<repo>/tmp/compile-check/` (inside the
project tree).

**Rationale:** Crystal's `require "../../src/ui"` only resolves
relative to the requiring file. A tempfile under `/tmp/` cannot find
`../../src/ui`. Placing the tempfile inside the project tree lets the
relative require work without forcing the spec to hard-code an
absolute path. The Atomic counter for parallel safety, ensure-block
cleanup, and combined IO::Memory for output+error match the canonical
brief's pattern verbatim.

## What I did NOT deviate on

- 10-commit topology — followed exactly.
- Required actionable text in compile errors (widget name, missing
  flag, fallback class name, example guard) — present in all three.
- 200-line vanilla-JS budget per fallback — action_sheet 140 lines,
  context_menu 188 lines.
- `--ap-*` CSS variable prefix throughout the new emissions — no
  `--amber-*` references in new code.
- `Platform.requires(:ios) { ... }` macro contract for app code — both
  the match-flag pass-through and the missing-flag compile error fire
  as specified.
- tier-matrix.md document location and structure — at
  `docs/initiative-cross-platform-ui/tier-matrix.md`, classifies every
  source file in `src/ui/views/`.
- CLAUDE.md "Tier model for cross-platform widgets" section —
  documents the convention + the stub-file split mechanic + the
  library-vs-app distinction.
