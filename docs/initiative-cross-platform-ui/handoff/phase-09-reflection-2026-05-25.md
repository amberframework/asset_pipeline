# Phase 9 — Architect Reflection

**Phase:** 9 — Apple-Native Intent Catalog + Tier 2 Translation Contract
**Date closed:** 2026-05-25 (PASS — clean)
**Branch merged:** `phase-09-intent-catalog` → `feature/utility-first-css-asset-pipeline`
**Final HEAD:** `e2d0230b`
**Tag:** `phase-09-pass-2026-05-25`

## Verdict

PASS. All 7 deliverables shipped, schema lint passes (92 entries validated), Apple-surface coverage gate is green (65 named APIs across 13 families, 0 MISSING), Codex content-level + implementer-level reviews both APPROVE.

## What shipped

7 documents in `docs/initiative-cross-platform-ui/architecture/`:

1. **`intent-catalog.md`** — 67 intents (1 Class A + 17 Class B + 9 Class C + 40 Class D). Every identifier is snake_case-of-Apple-name; 6 documented exceptions for HIG-named system features without single SwiftUI canonical names. 92 schema-validated rows (catalog + the 25 child rows under composed entries). All 12 common-schema fields populated per row; Class D rows carry 14 fields.

2. **`intent-routing-candidates.md`** — Class A's single entry (`:swipe_actions`) with 12-predicate capabilities block (trimmed from initial 17 after Codex flagged 4 unbacked claims), per-platform defaults table, override examples, capability validation pattern. Clear rationale for why only 1 Class A intent qualifies.

3. **`tier-2-translation-contract.md`** — four-part contract definition (intent_id + capabilities + defaults + override_registry), Class D direct-modifier shape, resolver pattern deferred to Phase 10, override capability validation rules, full implementation pseudocode for Phase 10, repo evidence citations.

4. **`translation-matrix.md`** — per-platform defaults for the 1 Class A intent + freshness reconciliation paragraph (canonical view count: 79 top-level + 3 gate stubs = 82 files; reconciled with `component-mapping-matrix` skill's 59, `tier-matrix.md`'s 78).

5. **`intent-backlog.md`** — 35 backlog items (1 P0, 16 P1, 18 P2) across A/B/C/D classes. Each entry: ID, intent, platform with gap, action, size, priority.

6. **`widget-intent-mapping.md`** — implementer-shipped audit of all 82 files in `src/ui/views/`. Every row has exact A/B/C/D class assignment (1 Class A + 1 Class C + 80 Class D — the layout primitives are Class D).

7. **`apple-surface-coverage.md`** — implementer-shipped checklist against 65 named SwiftUI/UIKit/AppKit APIs across 13 families. All 65 covered with catalog row links. 0 MISSING.

Plus: `scripts/lint_intent_catalog.cr` — Crystal lint script that validates the catalog schema (12 common fields + 2 Class D extras + em-dash sentinel + snake_case-of-Apple-name rule with exception support). Runs against the live catalog; exits 0 on pass.

## Numbers

- Catalog: **67 documented intents**, 92 schema-validated entries (the deltas are composed/nested entries inside larger rows).
- Widget audit: **82 source files** classified.
- Apple-surface coverage: **65/65** named APIs covered.
- Backlog: **35 items** (1 P0, 16 P1, 18 P2).
- Codex iterations: 4 content-level passes (REVISE → REVISE → REVISE → APPROVE) + 1 final approval pass = 5 Codex content reviews + the standard brief antagonist cycle.

## Lessons

### Codex content-level review caught vocabulary violations the architect missed

The Phase 9 catalog draft passed schema lint mechanically but had 11 identifier violations the architect ALSO violated (catalog content didn't follow its own snake_case-of-Apple-name rule). Codex caught this AFTER the schema-shape review was already approved.

The lesson: schema validation and content validation are different reviews. Schema validation checks that fields are present + valid; content validation checks that the values follow the rules. **An LSP-style lint can catch schema; only an antagonist who knows the rules can catch content.**

Phase 10 LSP rule families that enforce naming conventions need this same two-layer discipline: a syntactic checker (parse + field presence) PLUS a semantic checker (rule compliance with documented exceptions). The asset_pipeline lint script we shipped today does both — it parses YAML-style schema fields AND enforces the snake_case-of-Apple-name rule with the exception escape valve.

### The "exception process" was load-bearing

Brief §3 specified an exception process for intents where no Apple canonical name exists. I half-believed we'd never use it — turned out 6 of the 17 Class B accessibility intents needed exceptions. HIG names features ("Switch Control", "Voice Control", "Assistive Access") that don't have a SwiftUI modifier; the intent name lives at the contract level, not the API level.

The exception field (`apple_canonical_name_exists: false`) + justification + reviewer approval gates this cleanly. Without that escape, we'd have either invented fake API names (loophole) OR had to drop legitimate intents (gap). The brief got this design right.

### Implementer caught what architect + Codex content review missed

The architect did 3 Codex content-review iterations + a final approval pass. All confirmed APPROVE. Then the implementer ran the schema lint script (which the brief mandated they write) — and it found 11 violations the content reviews had let through.

The lesson: **mechanical lints catch things human-style reviews don't**. The schema lint script Phase 9 produced is the operational layer that Phase 10's LSP rules will inherit — same shape, broader rule set. Build the lint, run the lint, don't rely on human eyes alone.

### Class D was the right addition

Codex's BLOCKER 2 on scoping-9 v2 ("missing Class D for native modifier intents") was the most impactful planning correction. The original A/B/C taxonomy had Class A doing too much work — every modifier was potentially "routable" which inflated the contract surface. Class D's "direct 1:1 Crystal-to-SwiftUI-modifier translation, no contract" carries 40 of the 67 intents without ceremony. Class A holds 1.

The 1 vs 40 split is the real shape of the design space. If a future phase finds 2 or 3 more Class A candidates (`:reorder_list_items` is the most likely), we add them; the contract was built for that. But the framework doesn't pay routing overhead for behaviors that don't need it.

### Apple-vocabulary discipline pays for itself

The owner's binding directive — "speak Apple verbatim" — was costly in the catalog draft (every identifier had to be checked against a real Apple API name). Codex content review caught 13 identifier renames + 11 schema lint violations. That feels heavy.

But the payoff is real: when a Phase 10 LSP rule says "an author writing this Crystal code should be using the SwiftUI X modifier," the rule can cite the catalog row and the author can grep Apple's documentation for the same name. When the owner says "I want the Mail-app swipe behavior," they (or an AI agent) can grep the catalog for "swipe" and find `:swipe_actions` immediately. The vocabulary is the API surface for discovery, not just for documentation.

## What's open (carried to Phase 10)

- Backlog items B-001 through B-035 — buildable Phase 10+ work.
- `tier-matrix.md` staleness (omits `swipe_action_row.cr`) — not Phase 9 scope.
- Owner-screen intake loop — explicitly deferred per "work entirely through Phase 9." If owner screens reveal new intents, they become Phase 9B amendments.

## Bookkeeping

- 4 implementer/architect commits + 3 planning commits on `phase-09-intent-catalog`.
- 17 files: 7 architecture docs + 1 lint script + 9 planning artifacts (scoping v1/v2/v3, co-plan, antagonist iter 1, brief, brief critique, content review records).
- New memory candidates (saved separately if useful):
  - Schema lint + content review are separate layers.
  - Exception process design pattern: apple_canonical_name_exists: false + justification + reviewer approval.

— Architect (Claude Opus 4.7)
