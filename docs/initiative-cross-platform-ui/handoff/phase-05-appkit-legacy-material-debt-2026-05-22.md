# Phase 5 — AppKit Legacy `setMaterial:` Known-Debt — 2026-05-22

**Status:** Architect-acknowledged out-of-scope; carry-forward to Phase 6.5+ cleanup.

## What

After Phase 5 R3 closed the 3 Codex-named AppKit `setMaterial:` scope-drift sites (NavigationSplitView 1828, ContextMenu 2813, ActivityView 3744), `grep -n 'setMaterial:' src/ui/renderers/appkit_renderer.cr` still surfaces **5 additional raw-integer `setMaterial:` calls** in `_legacy_*` methods:

| File:line range | Method | Hard-coded material |
|---|---|---|
| `_legacy_tab_view` | `_legacy_*` | Integer literal |
| `_legacy_alert` | `_legacy_*` | Integer literal |
| `_legacy_toolbar` | `_legacy_*` | Integer literal |
| `_legacy_sheet` | `_legacy_*` | Integer literal |
| `_legacy_popover` | `_legacy_*` | Integer literal |

(Exact line numbers shift with edits; grep at HEAD `f081205` for the current set.)

## Why these were not closed by R3

R3's named scope was only the 3 active-visit-path sites Codex identified (NavigationSplitView/ContextMenu/ActivityView). The 5 above live in `_legacy_*` methods that are NOT invoked from the active dispatch path; they're preserved as historical references for the facade migration. Per Phase 5 R3's Codex pre-merge critique, the active widgets in this list (TabView/Alert/Toolbar/Sheet/Popover) all route through the SwiftKit facade now via `apsk_make_*` paths — the `_legacy_*` body is dead code for runtime purposes.

Per `implementation.md` lines 85–89 (tokenize every hard-coded material site OR escalate), this is the formal escalation handoff. Architect's reasoning for acknowledging as out-of-scope:

1. **Not runtime-active.** None of the 5 `_legacy_*` methods is on the active `visit(...)` dispatch path. Removing or tokenizing them is dead-code cleanup, not behavioral change.
2. **Phase 5's actual architecture diverged from implementation.md's translation-table envisioning.** Implementation.md L555–569 imagined a UIKit→AppKit material-integer translation table. Phase 5 actually shipped SwiftKit facade enum routing — a more modern Swift-side approach. The R3 Symbol→NSVisualEffectMaterial helper is narrow (3 step values) by intent; broadening it for the 5 legacy methods would require either expanding the helper artificially OR migrating those methods to the SwiftKit facade path (which would be Phase 5 facade-migration work, not Phase 5 material-tokenization work).
3. **No consumer-visible regression risk.** The 5 sites are not on user-reachable code paths in the current renderer.

## What Phase 6.5+ must decide

When Phase 6.5 (audit infrastructure) ships or when a future cleanup phase touches the AppKit legacy methods:

- **Option A:** Delete the 5 `_legacy_*` methods entirely (they're dead code by Phase 5's facade migration).
- **Option B:** Migrate them to the SwiftKit facade path so they share the same material tokenization as the active path. Useful if these methods are intended as fallbacks for some flag-gated condition (verify; currently the architect believes they're not).
- **Option C:** Extend the R3 `appkit_visual_effect_material(step : Symbol) : Int64` helper with the additional Symbol mappings these legacy sites need + tokenize them via the helper. Lowest blast radius; preserves the dead code without expanding the Symbol space artificially.

Architect's recommendation: **Option A** (delete dead code) during whichever cleanup phase touches AppKit. Failing that, Option C as a 30-minute mechanical edit.

## Validator scope for Phase 5 iter 2

Phase 5 Validator iter 2 should treat these 5 hits as **architect-adjudicated known-debt**: `_legacy_*` methods are out of Phase 5's named scope; this handoff doc is the formal escalation per `implementation.md:85`. The validator confirms the doc exists + that the 5 hits are confined to `_legacy_*` methods (no leakage into active visit paths).

## Carry-forward marker

When Phase 6.5+ closes these, append a "Closed YYYY-MM-DD by Phase N commit SHA" line below.

(Currently open.)
