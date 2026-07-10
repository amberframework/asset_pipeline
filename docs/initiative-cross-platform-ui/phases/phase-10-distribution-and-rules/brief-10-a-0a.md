# Phase 10A.0a — Crystal-Side Convention Runner + Family 1 Rules (v2)

**Sub-phase:** 10A.0a — substrate for convention enforcement + 5 naming rules.
**Branch:** `phase-10-a-0a` cut from `phase-10`.
**Status:** v2 — replaces v1 brief-10-a-0.md after Codex REVISE + owner ruling (architecture-decisions.md Decision 1).
**Predecessor:** 10-pre.2 closed. Parallel with 10B.0 and 10C.0.

---

## Critical context

Per **architecture-decisions.md Decision 1**: AmberLSP's CustomRule is YAML-regex-only. Owner ruled (2026-05-25): convention rules ship as a **Crystal-side runner**, not via AmberLSP. This brief reflects the runner approach.

Per **Decision 2**: 10A.0 split into 10A.0a (this) + 10A.0b (Family 2, sequential after 10C.0) + 10A.0c (Family 3, sequential after 10A.0a).

## 1. What you are doing

Build a Crystal-side convention runner + ship 5 Family 1 naming rules + ship the skill documentation. After 10A.0a closes:

- `scripts/lint_conventions.cr` — a Crystal program that walks repo files, applies all loaded rule classes, prints diagnostics, exits 0/1.
- `src/lsp_rules/family_1_naming/*.cr` — 5 rules (keep the `lsp_rules/` directory name for future AmberLSP-port viability).
- Each rule: a Crystal class with `check(file_path : String, content : String) : Array(Diagnostic)`.
- `.claude/skills/asset_pipeline--lint-conventions/SKILL.md` documenting the runner + rule families.
- shards (not shards-alpha — Codex MED-5 correction) install audit confirms skills ship.
- Minimal Crystal doc scaffolding on the ~90 public surface files: file header + module/class summary.

Family 2 (view-spec pair) defers to 10A.0b after 10C.0. Family 3 (architectural) defers to 10A.0c. Family 4 + Family 5 deep rules defer to 10A.final.

## 2. Read first

1. `docs/initiative-cross-platform-ui/phases/phase-10-distribution-and-rules/architecture-decisions.md` — **the authoritative architectural rulings**.
2. `docs/initiative-cross-platform-ui/phases/phase-10-distribution-and-rules/codex-critique-brief-10-a-0.md` (will be written from `/tmp/codex-brief-10-a-0.log` if needed; the architecture-decisions.md captures the relevant decisions).
3. `docs/initiative-cross-platform-ui/phases/phase-10-distribution-and-rules/scoping-10.md` v3 §"10A.0" (note: parts SUPERSEDED by architecture-decisions.md).
4. `[[codex-as-architect-antagonist]]`, `[[audit-scope-discipline]]`, `[[codex-background-stdin-trap]]`.
5. Existing AmberLSP rules (for pattern reference, not loader): `/Users/crimsonknight/open_source_coding_projects/amber_cli/src/amber_lsp/rules/` — sample 2 rules. The rule-class SHAPE is the inspiration; the loader mechanism is NOT used.
6. shards skill distribution: `/Users/crimsonknight/open_source_coding_projects/shards/src/docs.cr` (NOT `shards-alpha`).
7. CLAUDE.md Naming Conventions section.

## 3. Constraints (Hard Rules)

- Forward commits only on `phase-10-a-0a`.
- The runner is a Crystal program, NOT an AmberLSP plugin. AmberLSP is out of scope.
- Rules live in `src/lsp_rules/family_1_naming/` — directory name kept for future port viability.
- Each rule must: pass green on current asset_pipeline + Voyager source AND fire red on intentional violations.
- Minimal docs: file header (1-2 sentences) + class/module summary (1-2 sentences). NO per-method docs.
- `[[codex-as-architect-antagonist]]`: Codex content review before close.
- `[[complete-phase-arc-before-review]]`: no owner involvement.

## 4. Deliverables

### Deliverable 1 — Runner: `scripts/lint_conventions.cr`

Crystal program with this shape:

```crystal
#!/usr/bin/env crystal
# Phase 10A.0a — Convention rule runner.
#
# Walks the repo, applies loaded rule classes, emits diagnostics.
#
# Exit 0 if no violations; exit 1 if any. Invoked in CI + pre-commit.

require "./convention_rules"

# CLI options: --rules=family_1 (limit to one family) ; --files=path (limit scope)
# Default: scan src/, samples/, spec/ ; apply all loaded rule classes.

class Linter
  def initialize(@rules : Array(ConventionRule))
  end

  def lint(paths : Array(String)) : Array(Diagnostic)
    paths.flat_map do |path|
      content = File.read(path)
      @rules.flat_map { |r| r.check(path, content) }
    end
  end
end

# Diagnostic format:
struct Diagnostic
  property file_path : String
  property line : Int32
  property rule_name : String
  property message : String
  property suggested_fix : String?
end

# Output: human-readable + machine-parseable (one line per diagnostic).
# Format: <file>:<line>: [<rule_name>] <message> (suggested: <fix>)
```

The runner walks `src/`, `samples/`, `spec/` by default; CLI flag limits scope; rules are auto-loaded from `src/lsp_rules/family_N_*/`.

### Deliverable 2 — `src/lsp_rules/convention_rule.cr` — Base class

```crystal
abstract class ConventionRule
  abstract def check(file_path : String, content : String) : Array(Diagnostic)
  abstract def rule_name : String
end
```

### Deliverable 3 — Family 1: 5 naming rules

In `src/lsp_rules/family_1_naming/`:

1. `screen_file_suffix_rule.cr` — every file containing a `class FooScreen < UI::Screen` must be named `foo_screen.cr`.
2. `controller_file_suffix_rule.cr` — every file containing `class FooController < UI::Controller` must be named `foo_controller.cr`.
3. `screen_class_naming_rule.cr` — every `< UI::Screen` subclass name ends in `Screen`.
4. `controller_class_naming_rule.cr` — every `< UI::Controller` subclass name ends in `Controller`.
5. `view_subclass_under_views_dir_rule.cr` — every `< UI::View` subclass lives under `src/ui/views/` OR `samples/.../` (configurable allowlist).

For each: regex-based scan; emit Diagnostic per violation; document false-positive cases as regression fixtures.

### Deliverable 4 — Skill: `.claude/skills/asset_pipeline--lint-conventions/`

`SKILL.md`:
- How to invoke: `crystal run scripts/lint_conventions.cr`.
- What each rule checks (1-line per rule).
- How to add a new rule (point to base class).
- CI integration pattern.

### Deliverable 5 — shards install audit

Create a scratch consumer project; depend on asset_pipeline; run `shards install`; verify `.claude/skills/asset_pipeline--lint-conventions/` lands. Document any gaps.

### Deliverable 6 — Minimal doc scaffolding

For each of the ~90 public surface files (per scoping-10 v3 §"10A.0" minus `src/ui/views/screen.cr` which doesn't exist — Codex 10A.0 LOW-1):
- File header comment block: 1-2 sentences on file's purpose.
- Each public class/module: 1-2 sentence summary.

NO per-method docs. NO param/return docs. NO usage examples.

Note: 82 files in `src/ui/views/` + 6 in `src/asset_pipeline/` + `form_state.cr` + `design_tokens.cr` = ~90 files. Per Codex 10A.0 LOW-2: `design_tokens.cr` has multiple nested public units; if practical, each gets a short summary.

### Deliverable 7 — Close handoff

`docs/initiative-cross-platform-ui/handoff/phase-10-a-0a-close.md`:
- Runner invocation + exit codes verified.
- Rule list with green/red status on Voyager + intentional violations.
- Skill install audit result.
- Doc scaffold coverage (N of 90 files).
- Codex content review verdict.

## 5. Workflow

1. `git checkout -b phase-10-a-0a phase-10`.
2. Build the runner skeleton (Deliverable 1 + 2).
3. Add Family 1 rules one at a time. After each: run runner → verify green on current source.
4. Manually break a file → verify red.
5. Skill (Deliverable 4) + shards audit (Deliverable 5).
6. Doc scaffold sweep (Deliverable 6).
7. Close handoff.
8. Incremental commits.
9. Standard `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>` footer.

## 6. Acceptance gate

- ✅ `crystal run scripts/lint_conventions.cr` exits 0 on current asset_pipeline + Voyager source.
- ✅ Each of the 5 Family 1 rules fires RED on an intentional violation (verify by injection test).
- ✅ Skill installs correctly via shards in scratch project.
- ✅ Minimal doc scaffolding on the ~90 public files.
- ✅ Codex content review APPROVE.

## 7. Out of scope

- Family 2 (view-spec pair) — 10A.0b after 10C.0.
- Family 3 (architectural) — 10A.0c.
- Family 4 (test_id hygiene) — 10A.final.
- Family 5 (multi-target deep rules) — 10A.final. Family 5 directory rule ships in 10C.0.
- AmberLSP integration of any kind.
- Per-method Crystal doc comments — 10A.final.

## 8. What success looks like

After 10A.0a closes:
- A developer (or AI agent) can run `crystal run scripts/lint_conventions.cr` and get a diagnostic list.
- The CI workflow includes a lint job (10A.0a's responsibility to wire OR document as 10C.0's responsibility).
- Pre-commit hook documentation lets contributors run the linter locally.
- The skill discoverable in any shard-consuming project.

— Architect (Claude Opus 4.7), 10A.0a brief v2
