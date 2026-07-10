# Trust Pair Protocol

The team lead does not implement or validate work directly. The team lead delegates each phase to a **trust pair**: one **implementer** agent followed by one **validator** agent. The pair never communicates with each other — only with the team lead — so neither agent can rationalize away the other's findings.

This document specifies how the team lead spawns each agent, what briefing to attach, and how to handle each return state.

---

## Roles

### Implementer
Reads `phases/phase-XX-*/implementation.md`, performs the work, writes the code and tests, commits with a descriptive message, and returns a handoff message summarizing what changed (file paths, key decisions, anything that diverged from the brief).

### Validator
Reads `phases/phase-XX-*/validation.md`, runs every check in the rubric, captures evidence (test output, screenshots, audit reports, file inspections), and returns a `GATE_REPORT.json` (schema: `rubric/gate_report_schema.md`). The validator does not modify code.

### Team Lead
Orchestrates the dance. Maintains the progress ledger in `MASTER_PLAN.md`. Archives reports to `handoff/`. Does not write code. Does not run tests. Does not run audits. Only delegates and tracks.

---

## Spawning an implementer

Use the `Agent` tool with `subagent_type: "general-purpose"`. The implementer should be told it has full write access to the repo.

Prompt template:

```
You are the implementer for Phase {N} ({phase name}) of the asset_pipeline
cross-platform UI initiative.

Your full briefing is in:
  /Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-{NN}-{slug}/implementation.md

Read that document fully before starting. It contains:
- Goal statement
- Scope (what you must change) and Non-scope (what you must not touch)
- Detailed implementation steps
- Code conventions specific to this phase
- Test requirements
- Definition of done

Read also:
  docs/initiative-cross-platform-ui/rubric/implementation_criteria.md

It contains universal standards (commit format, code quality, test coverage,
documentation) that apply to every phase.

Work on the phase branch `phase-{NN}-{slug}` (already created and
checked out by the Architect before you were dispatched). Verify the
branch with `git rev-parse --abbrev-ref HEAD` before your first commit.
Do not branch further. Commit incrementally with messages following
the convention in implementation_criteria.md.

When done, return a single message with this structure:

  ## Summary
  {2–4 sentences on what was built and any key decisions}

  ## Files changed
  {bulleted list of file paths with one-line annotations}

  ## Commits
  {commit hashes with one-line subjects}

  ## Deviations from brief
  {anything you did differently than implementation.md specified, with reason}

  ## Known concerns
  {anything the validator should look at carefully}

Do NOT run the validation rubric yourself. The team lead will spawn a separate
validator agent for that. Your job is to build the work, not to grade it.
```

Continuing an implementer (after a failing gate report): use `SendMessage` to the same agent ID with:

```
The validator returned failures. The gate report is at:
  /Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-{NN}-failing-{N}-{date}.md

Read the report fully. Fix each `failed: true` check. Re-commit. When done,
return a summary in the same structure as before, noting which gate
checks you addressed.
```

---

## Spawning a validator

Use the `Agent` tool with `subagent_type: "general-purpose"`. The validator has full tool access but **must not edit code**.

Prompt template:

```
You are the validator for Phase {N} ({phase name}) of the asset_pipeline
cross-platform UI initiative.

Your rubric is in:
  /Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-{NN}-{slug}/validation.md

Read it fully before starting. It lists every check you must run, the
evidence to capture, and the pass/fail criteria.

Read also:
  docs/initiative-cross-platform-ui/rubric/validation_criteria.md

It contains universal validator standards (how to run tests, capture
screenshots, run accessibility audits, format the GATE_REPORT).

The implementer's handoff message is below. Use it to understand what
to look at, but do NOT take their word for it — verify every claim against
the rubric.

  {paste implementer's return message verbatim}

Branch under verification: the phase branch `phase-{NN}-{slug}` (already checked out by the Architect before you were dispatched). The implementer's commits are HEAD of this branch.

For each check in validation.md, run the check and record:
- check_id (from validation.md)
- required (true/false, from validation.md)
- passed (true/false)
- evidence (paths to screenshots, command output, file diffs, etc.)
- notes (what you saw, what surprised you, any caveats)

Capture screenshots and audit output to:
  docs/initiative-cross-platform-ui/handoff/phase-{NN}-evidence-{date}/

Return a single message with:

  ## Verdict
  PASS | FAIL

  ## GATE_REPORT
  {valid JSON matching the schema in rubric/gate_report_schema.md}

  ## Summary
  {2–4 sentences on what you saw}

You MUST NOT modify code, configuration, or test files. If a check
requires changing a value to run (e.g., changing a theme to verify
cascade), make the change, run the check, capture evidence, and then
revert. Note the revert in your evidence.

If a check is blocked (cannot be run because the environment is
missing something), mark it `passed: false, blocked: true` with a note
on what's missing. Do not skip checks silently.
```

---

## Return-state handling

When the implementer returns, the team lead must:

1. Update the progress ledger row in `MASTER_PLAN.md` to `Implementer Returned`, recording the commit hashes.
2. Read the implementer's return message and verify the commits exist.
3. Spawn the validator with the protocol above.

When the validator returns, the team lead must:

1. Parse the `## Verdict` line.
2. If `PASS`:
   - Update the ledger to `Passed`.
   - Save the GATE_REPORT and summary to `handoff/phase-{NN}-passed-{date}.md`.
   - If this phase has unblocked the next phase, the team lead **must wait for explicit human approval** before spawning the next phase's implementer. Phase transitions are checkpoints, not autopilot.
3. If `FAIL`:
   - Update the ledger to `Failing`.
   - Save the report to `handoff/phase-{NN}-failing-{N}-{date}.md` (where N is the failure iteration count, starting at 1).
   - Send a `SendMessage` to the implementer agent with the continuation prompt above.
   - Once the implementer returns again, restart the validation cycle (spawn a fresh validator — do not reuse the prior validator agent).

---

## Why this protocol

- **Independence of judgement.** The validator does not know what the implementer rationalized; they only see code and rubric. The implementer does not know what the validator will catch; they only see brief and standards. This is the cheapest way to surface "I'll do it now and document later" gaps.
- **No drift in the contract.** `implementation.md` and `validation.md` are written before either agent runs. Neither agent can negotiate the brief or the rubric mid-flight.
- **Reproducible failure analysis.** Every gate report is preserved in `handoff/`. Looking back at any phase, you can see exactly what the validator caught and how the implementer addressed it.
- **Team lead stays small.** The team lead never holds the full implementation context for any phase — they hold the briefings + the ledger. This is the key to running long-horizon work without context collapse.

---

## Anti-patterns to watch for

- **Implementer "validates" its own work.** If the implementer's return message says "I ran the tests and they pass," the team lead still spawns the validator. The validator runs the tests again. The implementer's word is not evidence.
- **Validator "fixes" code.** If the validator decides a check is "almost passing" and just needs a one-line change, that change must go to the implementer. A validator who edits code is no longer independent.
- **Team lead "merges" feedback.** If the validator finds three failures and the team lead thinks two of them are "really the same issue," the team lead does not consolidate. They forward the report verbatim.
- **Skipping a gate to save time.** Every phase's validation must run end-to-end before the next phase begins. There is no fast lane.
- **Reusing a validator across remediation loops.** Spawn a fresh validator each round. A validator that has already seen the code is no longer cold-eyed.
