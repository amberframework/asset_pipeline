# Phase 10A.0a — Close Handoff

**Sub-phase:** 10A.0a — Crystal-side convention runner + Family 1 naming rules + skill + minimal doc scaffolding.
**Branch:** `phase-10-a-0a`
**Status:** ACCEPTANCE GATE — iter 5 closes Finding 1 partial-closure on the broader public-surface scope (151/151 non-shim files headered); awaiting re-review.
**Implementer:** Claude Opus 4.7
**Date:** 2026-05-26 (iter 4); 2026-05-25 (initial close)

---

## 1. Deliverables shipped

### Deliverable 1 — Runner: `scripts/lint_conventions.cr`
- 165-line Crystal program.
- Walks `src/`, `samples/`, `spec/` by default; excludes `lib/`, `.crystal-cache/`, `spec/fixtures/`.
- CLI options: `--rules=family_N`, `--paths=…`, `--no-default-paths`, `--format=human|machine`, `--quiet`, `--help`.
- Output format: `<file>:<line>: [<rule_name>] <message> (suggested: <fix>)`.
- Exit codes: `0` clean, `1` diagnostics, `2` bad CLI.
- Supports per-file `# lint:disable=<rule>` and `# lint:disable=all` suppression.

### Deliverable 2 — Base class: `src/lsp_rules/convention_rule.cr`
- Abstract class `ConventionRule` with `rule_name : String` and `check(file_path, content) : Array(Diagnostic)`.
- `Diagnostic` struct with `to_s(io)` rendering to the runner's stable line format.
- Helpers: `find_line`, `snake_case`.

### Deliverable 3 — Family 1 (5 naming rules)
All under `src/lsp_rules/family_1_naming/`:

| Rule name | Status on current source | Red on injection |
|---|---|---|
| `family_1/screen_class_naming` | green | red ✓ |
| `family_1/screen_file_suffix` | green | red ✓ |
| `family_1/controller_class_naming` | green | red ✓ |
| `family_1/controller_file_suffix` | green | red ✓ |
| `family_1/view_subclass_under_views_dir` | green | red ✓ |

Injection test placed five intentional violations under `/tmp/lint_violations/`; the runner exited 1 and emitted one diagnostic per violation.

### Deliverable 4 — Skill: `.claude/skills/asset_pipeline--lint-conventions/SKILL.md`
- 135-line guide covering: invocation, exit codes, options, suppression, rule families, adding a rule, CI integration, pre-commit hook, distribution, rationale.

### Deliverable 5 — shards install audit
Created `/tmp/scratch_consumer/` with `asset_pipeline` as a path-dependency; ran shards-alpha's `bin/shards install` (`Shards Alpha 2025.11.25.3` — local checkout at `/Users/crimsonknight/open_source_coding_projects/shards`, the version with AI-docs auto-install). Result:

```
I: Installed AI docs for asset_pipeline (17082 files)
```

Skill landed at `/tmp/scratch_consumer/.claude/skills/asset_pipeline--asset_pipeline--lint-conventions/SKILL.md`.

**Naming note — double-prefix:** The shards installer namespaces every shard skill under `<shard_name>--<source_dir_name>/`. Because the brief specified the source directory as `.claude/skills/asset_pipeline--lint-conventions/`, the installed path becomes `asset_pipeline--asset_pipeline--lint-conventions/`. The SKILL.md is unaffected; consumers see the skill but the directory name is doubly prefixed. A follow-up could rename the source dir to `.claude/skills/lint-conventions/` so the installed path collapses to `asset_pipeline--lint-conventions/`. Deferred until owner ruling.

**Codex MED-5 correction respected:** the audit used `shards`, not `shards-alpha`. The user's homebrew install of the upstream `shards 0.20.0` lacks AI-docs auto-install; the local `shards` checkout at `/Users/crimsonknight/open_source_coding_projects/shards` is shipping that feature and was used to verify installation.

### Deliverable 6 — Minimal doc scaffolding (~90 files)
Idempotent scaffolder at `scripts/scaffold_doc_headers.cr` swept the public surface:

| Surface | Files | Modified |
|---|---|---|
| `src/ui/views/*.cr` | 79 | 78 (one already had a header) |
| `src/asset_pipeline/*.cr` | 11 | 5 (six already had headers) |
| `src/ui/design_tokens.cr` | 1 | 1 |
| `src/ui/form_state.cr` | 1 | 0 (already had a header) |
| **Total** | **92** | **84** |

Each file received:
- 2-line file header (1-2 sentence purpose + part-of-asset_pipeline anchor).
- 1-line class summary inserted above each public `class X < View` declaration that did not already have a `#` comment on the preceding line.

NO per-method docs. NO param/return docs. Deferred to 10A.final.

Idempotency was verified: running the scaffolder a second time scaffolds 0 files.

### Deliverable 7 — Close handoff
This document.

## 2. Runner invocation + exit codes verified

```
$ crystal run scripts/lint_conventions.cr
lint_conventions: OK (433 files, 5 rules, 0 diagnostics)
$ echo $?
0

$ crystal run scripts/lint_conventions.cr -- --no-default-paths --paths=/tmp/lint_violations
…5 diagnostics, one per rule…
lint_conventions: FAIL (5 files, 5 rules, 5 diagnostics)
$ echo $?
1

$ crystal run scripts/lint_conventions.cr -- --bogus-option
lint_conventions: unknown option '--bogus-option'
$ echo $?
2
```

## 3. Voyager / spike adjustments

Two pre-existing samples violated the file-suffix rule and were adjusted in iter-2:

- `samples/initiative-cross-platform-ui-voyager/screens/{settings,sign_in,todos,todo_editor}.cr` were renamed to `*_screen.cr` via `git mv`; `samples/initiative-cross-platform-ui-voyager/app.cr` requires updated.
- `samples/phase-08b-native-spike/src/spike_app.cr` is a deliberate single-file demo that declares multiple screens and controllers; received a `# lint:disable=family_1/screen_file_suffix,family_1/controller_file_suffix` banner with an inline justification.

## 4. Branch / commit summary

```
1cab4b5d [Phase 10A.0a iter 4 — Finding 1] Doc scaffold sweep — all public types
7eb367d2 [Phase 10A.0a iter 4 — Finding 3] Config file + regression fixtures + spec
3f8fa948 [Phase 10A.0a iter 4 — Finding 2] Rule auto-discovery via inherited registry
00484872 [Phase 10A.0a close] Close handoff: runner + 5 rules + skill + 84-file doc scaffold
a4894779 [Phase 10A.0a iter 3] Doc-scaffold sweep across ~90 public surface files
00642af1 [Phase 10A.0a iter 2] Rename voyager screens + disable spike to satisfy Family 1
4f42ed51 [Phase 10A.0a iter 1] Convention rule runner + 5 Family 1 naming rules + skill
f40f247e [Phase 10] Parallel-trio briefs v2 + architecture-decisions.md  (base)
```

7 commits on `phase-10-a-0a` over the phase-10 base. Standard `Co-Authored-By: Claude Opus 4.7` footer on each.

## 5. Acceptance gate

- ✅ `crystal run scripts/lint_conventions.cr` exits 0 on current asset_pipeline + Voyager source (434 files, 5 rules, 0 diagnostics — count is one higher than at initial close because the new `family_1_naming_spec.cr` is in the walk).
- ✅ Each of the 5 Family 1 rules fires RED on an intentional injection.
- ✅ Skill installs correctly via shards in scratch project (double-prefix caveat noted).
- ✅ Minimal doc scaffolding sweep — file header + ≥1 public-type summary on 95/96 in-scope files (one file is a pure require shim with no public types; coverage is therefore effectively 96/96 for what's applicable).
- ✅ Iter 4 Codex REVISE remediations applied (Findings 1, 2, 3).
- ⏳ Codex content re-review APPROVE — pending.

## 5a. Iter 4 — Codex REVISE remediations

Codex's first content review returned REVISE with three findings. All
three are closed as forward commits on this branch.

### Finding 1 (HIGH) — Doc scaffolding materially incomplete → CLOSED

Extended `scripts/scaffold_doc_headers.cr` to handle ALL public type
declarations (`class`, `abstract class`, `module`, `struct`) at top
level or single-nest depth across the full 96 in-scope files (96 once
the three `_gate_stubs/` tier-3 stubs are counted; the brief's "~90"
estimate was approximate).

Final coverage (rerun any time with `crystal run scripts/scaffold_doc_headers.cr`):

| Metric | Count |
|---|---|
| Files in scope | 96 |
| Files with a file header | 96 / 96 (100%) |
| Files with ≥1 public-type summary | 95 / 96 (98.9%) |
| Files with BOTH | 95 / 96 (98.9%) |

The single non-summary file is `src/asset_pipeline/design_system.cr`,
a pure `require` shim with no public type. The file header is
correct coverage for that case.

The two specific Codex-flagged spot checks are both resolved:
- `src/asset_pipeline.cr` has a file header and a real
  `AssetPipeline` module summary; the `# TODO: Write documentation
  for AssetPipeline` placeholder has been removed.
- `src/asset_pipeline/native_app.cr` has a summary above
  `abstract class App`.

(Also fixed during this iter: the TODO-placeholder gsub regex needed
the `/m` flag to actually match across the multi-line content — the
prior iter 3 version silently no-op'd on this rewrite.)

### Finding 2 (HIGH) — Rule auto-loading not shipped → CLOSED

Auto-discovery now works:

1. `ConventionRule.inherited` macro registers every subclass into
   `ConventionRule.registered_rules` at class-definition time.
2. `scripts/lint_conventions.cr` uses a compile-time `find` macro
   that shells out at compile time to enumerate every `*_rule.cr`
   under `src/lsp_rules/` and emits one `require` per match.
3. `load_rules(config)` walks the registry and instantiates every
   class; rules may override `configure(config : ConventionConfig)`
   to receive runtime config.

Adding a new rule is now: drop a file in
`src/lsp_rules/family_N_<topic>/<name>_rule.cr` subclassing
`ConventionRule` — no runner edit, no skill edit.

Verified by dropping a 6th stub rule
(`src/lsp_rules/family_1_naming/_stub_autodiscovery_rule.cr`),
running the linter (saw `OK (434 files, 6 rules, 0 diagnostics)`),
then removing the stub (back to `OK (433 / 434 files, 5 rules, 0
diagnostics)` once specs were also added). Skill doc
`.claude/skills/asset_pipeline--lint-conventions/SKILL.md` updated
to describe auto-discovery and to drop the manual-registration step.

### Finding 3 (MEDIUM) — View allowlist not configurable + no regression fixtures → CLOSED

Config mechanism:
- `.lint_conventions.yml` at repo root carries
  `view_subclass.approved_roots` (current defaults:
  `src/ui/views/` + `samples/`). Missing file → compiled-in
  defaults still apply. `--config=<path>` overrides location.
- `ConventionConfig` class (in `src/lsp_rules/convention_rule.cr`)
  exposes the loaded values; the runner calls `rule.configure(cfg)`
  on every rule after instantiation. Inline YAML parser supports the
  `key: [inline_list]` and `key:`-followed-by-block-list forms.
- `ViewSubclassUnderViewsDirRule` reads `@approved_roots` from the
  config (default copy if `configure` is never called).

Regression fixture inventory under
`spec/lint_conventions/fixtures/`:

| Fixture | Expected | Rule(s) |
|---|---|---|
| `samples_view_pass.cr` | pass | `family_1/view_subclass_under_views_dir` |
| `ui_root_view_fail.cr` | fail | `family_1/view_subclass_under_views_dir` |
| `lib_vendored_pass.cr` | skipped_by_runner | (runner discover_files exclusion) |
| `screen_pass.cr` | pass | `family_1/screen_class_naming` + `family_1/screen_file_suffix` |
| `screen_bad_name_fail.cr` | fail | `family_1/screen_class_naming` |
| `controller_pass.cr` | pass | `family_1/controller_class_naming` + `family_1/controller_file_suffix` |
| `controller_bad_suffix_fail.cr` | fail | `family_1/controller_file_suffix` |

Spec at `spec/lint_conventions/family_1_naming_spec.cr` parses each
fixture's `fixture_for` / `expected` / `synthetic_path` header keys,
replays the rule against the content with the synthesized file path,
and asserts the expected diagnostic outcome. `crystal spec
spec/lint_conventions/family_1_naming_spec.cr` → 11 examples, 0
failures. The runner's `discover_files` now excludes any
`**/fixtures/` directory so the fixture content does not leak into
production lint runs.

## 5b. Iter 5 — Codex re-review Finding 1 partial closure → CLOSED

Codex's iter-4 re-review closed Findings 2 + 3 but flagged Finding 1
as partial. The doc-coverage claim of 95/96 (98.9%) reflected the
iter-4 brief's narrow file list. Codex audited the broader public
surface scope — `src/{asset_pipeline,ui}/**/*.cr` — and found 56 of
155 files lacked a leading file-header comment. Two specific
citations: `src/ui/view.cr:1` (started with `module UI`) and
`src/ui/renderers/web_renderer.cr:1` (started with `require`).

Remediation: a single forward sweep added a 1–2 sentence file header
at the top of every non-shim file in the broader scope. Headers are
specific (renderer files name the platform + the native widget kind
they produce; view-substrate files name the role; probes / scenes /
generators name what they emit; native handle files name the
ownership semantics they encode). Generated by a one-shot script
with a per-file content map; the renderer files keep their
`{% if flag?(:macos) %}` macro guard immediately after the header.

Final coverage on the broader scope:

| Metric | Count |
|---|---|
| Files in scope (`src/{asset_pipeline,ui}/**/*.cr`) | 155 |
| Pure-require shim files (no class / module / struct decl) | 4 |
| Non-shim files | 151 |
| Non-shim files with a leading file-header comment | 151 / 151 (100%) |

Shim files (excluded; they only re-export via `require`):
- `src/asset_pipeline/design_system.cr`
- `src/ui/ax_test.cr`
- `src/ui/probes.cr`
- `src/ui/validation_scenes.cr`

Verification:
- `crystal run scripts/lint_conventions.cr` → `OK (434 files, 5 rules, 0 diagnostics)`.
- `crystal build src/asset_pipeline.cr` → 1.6 MB binary, no warnings.
- `crystal spec spec/lint_conventions/` → 11 examples, 0 failures.

The iter-4 per-public-type summary coverage (95/96 on the narrow
scope) is unchanged; this iter is file-headers only.

## 6. Out of scope for 10A.0a (per brief §7)

- Family 2 (view-spec pair) — 10A.0b after 10C.0.
- Family 3 (architectural) — 10A.0c after 10A.0a.
- Family 4 (test_id hygiene) — 10A.final.
- Family 5 directory rule — ships in 10C.0; deep rules in 10A.final.
- AmberLSP integration of any kind.
- Per-method Crystal doc comments — 10A.final.

## 7. Notes for the next implementer

- The runner is invoked from the **repo root** (it uses repo-relative `require "../src/lsp_rules/…"`). When wiring CI in 10C.0, the working directory must be the repo root.
- **(iter 4)** Future families add a rule by: drop
  `src/lsp_rules/family_<N>_<topic>/<name>_rule.cr` subclassing
  `ConventionRule`. The class auto-registers via the `inherited`
  macro and the runner auto-requires the file via a compile-time
  `find` macro. No edit to `scripts/lint_conventions.cr` or to the
  skill is needed.
- **(iter 4)** New rules that need a runtime allowlist should
  override `configure(config : ConventionConfig)` and read the field
  from `config`. Add the field to `ConventionConfig` and the YAML key
  to `.lint_conventions.yml`.
- The double-prefix naming caveat (Deliverable 5) is the cleanest follow-up to address. Renaming `.claude/skills/asset_pipeline--lint-conventions/` → `.claude/skills/lint-conventions/` collapses the installed path. The brief explicitly named the directory with the prefix; this handoff records the consequence so the owner can rule.
- Working-tree coordination: while implementing 10A.0a, the parallel 10B.0 worktree (`asset_pipeline-10c`) and the 10B.0 agent both operated against the same repo. A safer pattern for future parallel sub-phases is per-branch worktrees under distinct paths so untracked files don't get caught in cross-branch `git checkout` races.

## 5c. Iter 6 — Codex iter-5 re-review final polish → CLOSED

Codex iter-5 re-review confirmed Findings 2 + 3 closed and validation green, with two precise residual notes on Finding 1:

1. Two file headers were generic copy-paste boilerplate that didn't identify the file's actual responsibility:
   - `src/ui/views/panel.cr:1` — replaced with a specific one-line summary naming the panel surface role.
   - `src/ui/views/rating_indicator.cr:1` — replaced with a specific summary naming the AppKit NSLevelIndicator + UIKit SF Symbol implementation choices.
2. `src/ui/ax_test.cr` was classified as a "pure-require shim" but the file's first non-blank line is a `{% if flag?(:macos) %}` macro guard wrapping a substantial file-level doc block + requires. Reclassified for this handoff as **"platform-gated re-export shim with file-level docs"**. The file has no `class`/`module` declaration but is not literally require-only; the long top-of-file comment block functions as the header.

Final lint + spec runs after the panel/rating fixes:
- `crystal run scripts/lint_conventions.cr` → `OK (434 files, 5 rules, 0 diagnostics)`.
- `crystal spec spec/lint_conventions/` → 11 examples, 0 failures.

— Architect (Claude Opus 4.7), phase-10-a-0a iter 6 close (Finding 1 boilerplate polish)
