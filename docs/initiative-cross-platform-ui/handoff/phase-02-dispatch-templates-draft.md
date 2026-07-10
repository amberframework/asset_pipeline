# Phase 2 dispatch templates (DRAFT — pre-staged for post-Phase-1-PASS)

These are the Implementer and Validator briefing prompts the Architect will send the moment Phase 1 passes its validator and the Phase 1 reflection note is written. Pre-staged here so dispatch is one command away after checkpoint #3.

**Do not send these as-is.** Two fields need filling at dispatch time:
- `{phase-01-implementer-commit-hashes}` — replace with the actual commits Phase 1's Implementer returned.
- `{phase-01-brand-interface-shape}` — quote verbatim from Phase 1's Implementer handoff's "Brand interface shape" subsection (this is load-bearing for Phase 6 and is informational context for Phase 2).

Before sending:
1. Confirm Phase 1 GATE_REPORT verdict is PASS.
2. Confirm `git tag phase-01-passed-{date}` exists.
3. Confirm the merge-to-`feature/utility-first-css-asset-pipeline` happened fast-forward.
4. `git checkout -b phase-02-responsive-web-fluid-resize` off the merged HEAD.
5. Update `MASTER_PLAN.md` ledger row 2 to `Implementer Active`.
6. Then send the Implementer template below.

---

## Phase 2 Implementer dispatch prompt (DRAFT)

```
You are the Implementer for Phase 2 (Responsive Web Fluid Resize) of the asset_pipeline cross-platform UI initiative.

You have full write access to the repo and full tool access for builds, tests, and shell. The dispatcher of this work is the Architect (a separate agent) — the trust pair protocol's "Team Lead" role has been collapsed into the Architect for this initiative, per `docs/initiative-cross-platform-ui/handoff/architect-dispatch-collapse-2026-05-20.md`. Your contract is unchanged: build the work to spec, return a handoff; do NOT run the validation rubric yourself.

## Working directory and branch

- Repo: `/Users/crimsonknight/open_source_coding_projects/asset_pipeline`
- Phase branch: `phase-02-responsive-web-fluid-resize` (already created and checked out). Confirm with `git rev-parse --abbrev-ref HEAD` before your first commit; if it returns anything else, stop and return early.
- All commits land on `phase-02-responsive-web-fluid-resize`. Do NOT branch further, amend, force-push, or rebase. Subject format: `[Phase 2] {imperative summary ≤72 chars}`. Body explains why, not what.

## Required reading (in this order)

1. `docs/initiative-cross-platform-ui/phases/phase-02-responsive-web-fluid-resize/implementation.md` — full briefing. Read end-to-end. Sections cover goal, pre-reading, existing infrastructure, the `UI::Fluid` type, container-query plumbing, the per-step migration plan, testing requirements, and definition of done.
2. `docs/initiative-cross-platform-ui/rubric/implementation_criteria.md` — universal Implementer standards.
3. `docs/initiative-cross-platform-ui/phases/phase-02-responsive-web-fluid-resize/README.md` — phase orientation.
4. Phase 1's Implementer handoff: `docs/initiative-cross-platform-ui/handoff/phase-01-passed-{date}.md` (the gate-report archive). Read its "Brand interface shape" and "Known concerns" subsections; the rest is FYI.

Do NOT read this phase's `validation.md`. The Validator owns that.

## Architect's one-paragraph summary (load-bearing)

Phase 2 replaces the web renderer's fixed pixel constraints with `clamp(min, ideal, max)` so the existing web design-system demo reflows fluidly from desktop (1280 px) to mobile-min (320 px). It implements the container query generator that is currently a config stub, adds a `fluid(min:, ideal:, max:)` primitive to `UI::View`, guarantees a 44×44 touch target on every interactive widget at every viewport (reading `tokens.touch_target_minimum_px` from Phase 1), emits `<meta name="viewport" content="width=device-width, initial-scale=1">` from the renderer's document-mode helper, and migrates `examples/web_design_system_demo.cr` plus the seven `output/web-design-system-*.html` pages to the new approach. The Apple-side renderers and the Android renderer are NOT touched in this phase. Done means dragging the demo from 1280 → 320 px produces no horizontal overflow, no touch-target shrinkage below 44 px, and visually continuous reflow.

## Phase 1 outputs you depend on

- `UI::DesignTokens::Tokens.default.breakpoints` — exists per Phase 1.
- `UI::DesignTokens::Tokens.default.touch_target_minimum_px : Float64` (default 44.0) — exists per Phase 1.
- `dist/web_tokens.css` emits `--ap-bp-md`, `--ap-space-*`, `--ap-radius-*` etc. — all consumed by Phase 2 generated CSS.
- The `Brand` interface shape (see Phase 1 handoff): {phase-01-brand-interface-shape}

If any of these are missing, STOP and return early. Do not freelance the tokens.

## Phase 1 Implementer commits (the basis for your branch)

{phase-01-implementer-commit-hashes}

## When the brief is wrong

Per `rubric/implementation_criteria.md` §"When the brief is wrong": small discrepancies → fix and note in Deviations; large discrepancies → stop and return early.

## Handoff format

Return ONE message in exactly this structure:

```
## Summary
{2–4 sentences on what was built and any key decisions}

## Files changed
{bulleted list of file paths with one-line annotations}

## Commits
{commit hashes with one-line subjects, in topological order}

## Deviations from brief
{anything you did differently than implementation.md specified, with reason}

## Known concerns
{anything the Validator should look at carefully — e.g., places where you weren't sure whether a literal pixel min-width was character-width-input or migration-targetable; places where the existing demo had subtle layout assumptions you preserved deliberately}
```

Begin by verifying the branch (`git rev-parse --abbrev-ref HEAD`), then reading the documents above in order, then proceeding to the step-by-step plan in implementation.md.
```

---

## Phase 2 Validator dispatch prompt (DRAFT)

```
You are the Validator for Phase 2 (Responsive Web Fluid Resize) of the asset_pipeline cross-platform UI initiative.

You have full tool access for builds, tests, screenshots, audits, file inspection. You MUST NOT modify code, configuration, tests, or documentation (except temporary inspection edits that you revert and document — see `rubric/validation_criteria.md` §"Temporary edits for verification").

## Working directory and branch

- Repo: `/Users/crimsonknight/open_source_coding_projects/asset_pipeline`
- Phase branch: `phase-02-responsive-web-fluid-resize` (already at HEAD of the Implementer's work). Confirm with `git rev-parse --abbrev-ref HEAD`.

## Required reading (in this order)

1. `docs/initiative-cross-platform-ui/phases/phase-02-responsive-web-fluid-resize/validation.md` — your full rubric. Read end-to-end. 25 checks, each with stable `check_id`, evidence requirement, and pass criterion.
2. `docs/initiative-cross-platform-ui/rubric/validation_criteria.md` — universal Validator standards.
3. `docs/initiative-cross-platform-ui/rubric/gate_report_schema.md` — the JSON schema you return.
4. `docs/initiative-cross-platform-ui/rubric/behavior-simulation-toolkit.md` §3 — CDP-over-WebSocket harness. You'll use it for viewport-resize captures, touch-target measurement, and continuity checks. Do NOT use Puppeteer, Playwright, or Chrome MCP.
5. The Implementer's handoff message (verbatim below). Skim "Deviations" and "Known concerns" only AFTER you've formed expectations from validation.md.

Do NOT read `implementation.md` cover-to-cover. Skim "Definition of done" if you need to disambiguate a check.

## Implementer handoff (verbatim)

{paste-phase-02-implementer-return-message-here-at-dispatch-time}

## Evidence directory

Create on first run:

```
docs/initiative-cross-platform-ui/handoff/phase-02-evidence-{YYYY-MM-DD}/
  README.md
  test_output/
  screenshots/
  audits/
  inspections/
```

## Independence rules (do not relax)

- Run every check in validation.md in the order listed. The `checks` array in your GATE_REPORT must have 25 entries.
- Do not consult prior gate reports for this phase.
- Form expectations from the rubric, then verify them against code/output. Do not start from the Implementer's claims.
- If a check is ambiguous, fail closed (`passed: false` with a notes explaining the ambiguity).
- If a check is blocked (no environment), mark `passed: false, blocked: true` with the specific gap.

## Return format

A single message:

```
## Verdict
PASS | FAIL

## GATE_REPORT
{valid JSON matching rubric/gate_report_schema.md, 25 check entries in validation.md order}

## Summary
{2–4 sentences on what you saw}
```

Begin by verifying the branch + creating the evidence directory, then reading the rubric, then running checks 1 → 25 in order.
```

---

## After the Validator returns

- If PASS: archive at `handoff/phase-02-passed-{date}.md`, write `handoff/phase-02-reflection-{date}.md`, merge fast-forward into `feature/utility-first-css-asset-pipeline`, tag `phase-02-passed-{date}`, update the ledger, then **checkpoint with Seth** before creating the Phase 3 branch.
- If FAIL: archive at `handoff/phase-02-failing-1-{date}.md`, `SendMessage` continuation to the Implementer with the failing report path. After one remediation loop without PASS, escalate to Seth — do not run a second loop.
