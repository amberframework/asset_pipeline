# Phase 10B.0 — Tier 2 Resolver + Reactivity Contract (v2)

**Sub-phase:** 10B.0 — make the Tier 2 translation contract real Crystal.
**Branch:** `phase-10-b-0` cut from `phase-10`.
**Status:** v2 — replaces v1 after Codex REVISE (5 HIGH findings); architectural pin-downs in architecture-decisions.md Decision 4.
**Predecessor:** 10-pre.2 closed. Parallel with 10A.0a + 10C.0.

---

## Critical context

Per **architecture-decisions.md Decision 4**, 5 architectural decisions are now pinned (not left to implementer):

1. **Reactivity loop is the actual dispatcher flow**, NOT "mutation → build." The correct flow: `controller mutation → UI::ActionResult::Rerender → ActionDispatcher mount → NavigationCoordinator publish → host on_change → screen rebuild → resolve runs`.
2. **`ScreenContext` gets a `platform` field** added in this slice. Both `ScreenContext` (web) and `ScreenContext::Native` get platform info threaded through.
3. **Override storage is a class-scoped registry**, NOT screen instance fields. Public API writes into `UI::Intent::Registry`.
4. **Capability declaration is a macro on widgets**: `declares_capabilities :swipe_actions, { ... }`. Registry validates declared capabilities ⊇ required capabilities at `override_intent` call time.
5. **No silent-fallback warnings.** Missing default → `UI::Intent::UnresolvableDefault` error. 10B.1a removes the error by introducing `UI::InlineActionRow`.

Per **Decision 6**: 10B.0 places specs in current `spec/` layout (not `spec/web/`). 10C.0 migrates them later.

## 1. What you are doing

Build the resolver + override registry + capability validation + reactivity contract in real Crystal. After 10B.0 closes:

- `src/ui/intent.cr` — `UI::Intent.resolve(intent_id, context) : View.class` (or typed factory).
- `src/ui/intent/registry.cr` — class-scoped override storage.
- `UI::App.override_intent(intent_id, widget_class)` — app-level override.
- `UI::Screen.override_intent(intent_id, widget_class)` — class-method on Screen subclasses (screen-scoped override).
- `declares_capabilities` macro on `UI::View`.
- `ScreenContext` extended with `platform : Symbol`.
- Resolver hooked for `:swipe_actions` — returns `UI::SwipeActionRow` for iOS/iPadOS/web_narrow; raises `UI::Intent::UnresolvableDefault` for macOS/web_wide (until 10B.1a).
- Specs proving: resolver behavior, precedence (screen > app > default), capability validation, reactivity invariant (rebuild path actually runs resolve again).

## 2. Read first

1. `docs/initiative-cross-platform-ui/phases/phase-10-distribution-and-rules/architecture-decisions.md` — **authoritative**.
2. `docs/initiative-cross-platform-ui/architecture/tier-2-translation-contract.md`.
3. `docs/initiative-cross-platform-ui/architecture/intent-routing-candidates.md` (post-10-pre.1 capability block).
4. **Actual file paths** (corrected from v1 Codex LOW-1): `src/asset_pipeline/amber_integration.cr` for `UI::Screen`; `src/asset_pipeline/native_app.cr` for `UI::App`; `src/asset_pipeline/action_dispatcher.cr` for the dispatcher; `src/ui/navigation_coordinator.cr` for the coordinator's `on_change`.
5. `src/asset_pipeline/native_context.cr` — `ScreenContext::Native`.
6. `src/ui/views/swipe_action_row.cr` — existing Class A widget.

## 3. Constraints

- Forward commits only on `phase-10-b-0`.
- Reactivity contract per Decision 4 #1 — specs MUST hit the real dispatcher flow, not synthetic spy/mock.
- ScreenContext extension is a public API change — preserve backwards compat where possible; document any breakage.
- Capability declaration via macro — `UI::SwipeActionRow` adopts the macro in this slice (one example proves the pattern).
- No widget implementation (that's 10B.1a–10B.5).
- Specs in current `spec/` layout (not `spec/web/`).
- `[[codex-as-architect-antagonist]]` + `[[reactivity-is-table-stakes]]` + `[[plan-what-to-understand-not-just-what-to-build]]` apply.

## 4. Deliverables

### Deliverable 1 — `src/ui/intent.cr` — Resolver

```crystal
module UI::Intent
  class UnresolvableDefault < Exception; end

  def self.resolve(intent_id : Symbol, context : ScreenContext, capabilities_required : Hash(Symbol, Bool)? = nil) : UI::View.class
    # Lookup precedence: screen > app > default.
    # Raises UnresolvableDefault if no widget for context.platform.
  end
end
```

The return type is `UI::View.class`. Implementer MUST prove a compiling call-site like `action_row_class = UI::Intent.resolve(:swipe_actions, ctx); row = action_row_class.new(...)`. If `View.class` doesn't work in practice (e.g., abstract class issues), substitute a typed factory descriptor + document the change.

### Deliverable 2 — `src/ui/intent/registry.cr` — Class-scoped registry

```crystal
module UI::Intent::Registry
  # App-level: keyed by app class + intent_id.
  @@app_overrides = {} of {UI::App.class, Symbol} => UI::View.class

  # Screen-level: keyed by screen class + intent_id.
  @@screen_overrides = {} of {UI::Screen.class, Symbol} => UI::View.class

  def self.register_app_override(app_class : UI::App.class, intent_id : Symbol, widget_class : UI::View.class)
    # Validate capabilities then store.
  end

  def self.register_screen_override(screen_class : UI::Screen.class, intent_id : Symbol, widget_class : UI::View.class)
    # Validate capabilities then store.
  end

  def self.resolve_for(intent_id : Symbol, context : ScreenContext) : UI::View.class?
    # Walk precedence: screen first (from context), then app, then default.
  end
end
```

### Deliverable 3 — `declares_capabilities` macro on `UI::View`

```crystal
class UI::View
  macro declares_capabilities(intent_id, capabilities)
    # Class-level registry write at class boot.
    # ::UI::Intent::Registry.declare_widget_capabilities({{@type}}, {{intent_id}}, {{capabilities}})
  end
end

class UI::SwipeActionRow < UI::View
  declares_capabilities :swipe_actions, {
    supports_edge_trailing: true,
    supports_role_destructive: :partial,  # iOS+web only
    supports_role_default: true,
    requires_visible_or_keyboard_alternative: false,  # unenforced today
  }
end
```

Registry validates `override.declared_capabilities ⊇ override.required_capabilities` at registration. Raises `UI::Intent::IncompatibleOverride` on mismatch.

### Deliverable 4 — `ScreenContext` platform extension

Add to `UI::ScreenContext` (and `::Native` variant):

```crystal
class UI::ScreenContext
  property platform : Symbol = :web_wide  # :ios, :ipados, :macos, :android, :web_wide, :web_narrow
end
```

Threading through:
- Web context: defaults to `:web_wide` (consumer apps detect viewport class downstream).
- Native context: set by the platform-specific App at construction.
- Document in code comment: how the platform value flows from app boot to screen build.

### Deliverable 5 — `UI::App` + `UI::Screen` override APIs

```crystal
class UI::App
  def self.override_intent(intent_id, widget_class)
    UI::Intent::Registry.register_app_override(self, intent_id, widget_class)
  end
end

class UI::Screen
  macro override_intent(intent_id, widget_class)
    # Class-level macro; writes into Registry at class load.
    ::UI::Intent::Registry.register_screen_override({{@type}}, {{intent_id}}, {{widget_class}})
  end
end
```

### Deliverable 6 — Hook `:swipe_actions`

`UI::Intent::Registry` defaults table for `:swipe_actions`:
- `:ios → UI::SwipeActionRow`
- `:ipados → UI::SwipeActionRow`
- `:web_narrow → UI::SwipeActionRow`
- `:macos → raises UnresolvableDefault` (until 10B.1a installs `UI::InlineActionRow`).
- `:web_wide → raises UnresolvableDefault` (until 10B.1a).
- `:android → raises UnresolvableDefault` (until 10B.1c).

### Deliverable 7 — Specs

`spec/ui/intent_spec.cr`:
- `resolve(:swipe_actions, ios_context)` returns `UI::SwipeActionRow`.
- `resolve(:swipe_actions, macos_context)` raises `UnresolvableDefault`.
- App override applies.
- Screen override beats app override.
- Capability validation rejects override missing a declared capability.
- AT LEAST ONE FAKE TEST INTENT to prove plurality (per Codex 10B.0 MED-4):
  - Register `:fake_test_intent` with a fake widget in test code; verify resolver finds it.

`spec/ui/intent_reactivity_spec.cr`:
- Integration test: dispatch a `UI::ActionResult::Rerender` → coordinator's `on_change` fires → screen rebuilds → resolve runs (verified via a counter or spy).
- Override change between renders: registry mutation between renders changes the resolved widget.
- State change + override change preserved.

Specs go in `spec/ui/...` (current layout; 10C.0 migrates).

### Deliverable 8 — Close handoff

`docs/initiative-cross-platform-ui/handoff/phase-10-b-0-close.md`:
- API surface summary.
- Spec coverage report.
- Reactivity flow proof (integration spec result).
- ScreenContext extension migration notes.
- Any architectural gaps surfaced.
- Codex content review verdict.

## 5. Workflow

1. `git checkout -b phase-10-b-0 phase-10`.
2. Read architecture-decisions.md fully.
3. Map the actual dispatcher → coordinator → on_change flow (read the cited files; verify the documented behavior).
4. Extend `ScreenContext` with `platform` (Deliverable 4) — small change first.
5. Build `UI::Intent::Registry` (Deliverable 2).
6. Build `UI::Intent.resolve` (Deliverable 1).
7. Add `declares_capabilities` macro + adopt on `UI::SwipeActionRow` (Deliverable 3).
8. Add app + screen override APIs (Deliverable 5).
9. Wire `:swipe_actions` defaults (Deliverable 6).
10. Specs (Deliverable 7) — write reactivity integration spec FIRST to drive correctness.
11. `crystal spec` passes. `crystal build src/asset_pipeline.cr` passes.
12. Close handoff.
13. Incremental commits per deliverable.
14. Standard footer.

## 6. Acceptance gate

- ✅ `UI::Intent.resolve` API exists + tested.
- ✅ `ScreenContext.platform` field exists + threaded through native + web context construction.
- ✅ Override registry class-scoped (not instance fields) + tested with precedence.
- ✅ `declares_capabilities` macro works on `UI::SwipeActionRow`; validation rejects malformed override.
- ✅ Reactivity integration spec PASSES — `ActionResult::Rerender` → coordinator publish → on_change → screen rebuild → resolve re-runs.
- ✅ Missing default raises `UnresolvableDefault` (no silent fallback).
- ✅ `crystal spec` passes.
- ✅ `crystal build src/asset_pipeline.cr` passes (no regression).
- ✅ Codex content review APPROVE.

## 7. Out of scope

- Widget implementations (10B.1a–10B.5).
- LSP/runner rules (10A.0a).
- Spec directory reorganization (10C.0).
- Catalog edits.
- Owner involvement.

— Architect (Claude Opus 4.7), 10B.0 brief v2 (post-Codex + architecture-decisions.md)
