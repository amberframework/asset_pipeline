# Architect First-Turn Protocol

This document is the operational layer beneath the system prompt. The system prompt establishes your identity, mission, hierarchy, and non-negotiables. This document tells you exactly what to do on your first turn — the reading order, the per-phase git rhythm, the bookkeeping rhythm, and the first actions before you respond to the owner.

Read this document at the start of every session, after the system prompt and before answering the owner's first message.

---

## Required reading (in this exact order)

1. **`origin.md`** — verbatim founding prompts from the project owner. Read BEFORE the formal plan so you absorb intent before execution detail. When the formal docs go silent on an ambiguity, this is where the spirit lives.
2. **`MASTER_PLAN.md`** — the strategic ledger you maintain. Phase sequence, dependencies, progress table. It points to per-phase folders but does not contain implementation detail.
3. **`rubric/trust_pair_protocol.md`** — how a Team Lead spawns implementers and validators. You read this so you can recognize when a Team Lead is operating correctly and write good Team Lead briefings.
4. **`rubric/implementation_criteria.md`**, **`rubric/validation_criteria.md`**, **`rubric/gate_report_schema.md`**, **`rubric/behavior-simulation-toolkit.md`** — the universal standards every implementer and validator is held to. The behavior-simulation-toolkit documents the shipped AXTest extensions A1–A7, the CDP-over-WebSocket web testing pattern, and XCUITest recipes — all already wired in the repo.
5. **`handoff/plan-quality-audit-2026-05-20.md`** — the quality audit that drove the first revision pass. Context, not contract.
6. **`phases/phase-01-design-token-foundation/README.md`** — the scope of the next phase you will orchestrate.

---

## What's already in place (do not rebuild)

- The AXTest framework's seven extensions (A1–A7: find by identifier, geometry read, value writer, focus, window resize, CGEvent keyboard, element screenshot) shipped and were verified end-to-end against a live TextEdit instance. Accessibility permission is already granted to the Terminal that runs `crystal spec`. See `spec/ui/ax_test/`.
- Web validation drives Chrome via Chrome DevTools Protocol over WebSocket from pure Crystal — pattern in `scripts/capture_amber_demo_screenshots.cr`. **Do not use Chrome MCP, do not use Playwright, do not use Puppeteer.**
- Existing axe-core and IBM Equal Access audit scripts under `scripts/`, a visual regression baseline directory under `test-results/`, and HIG validation samples under `samples/cross_platform/`. Each phase's `implementation.md` has an "Existing infrastructure to use (vs. rebuild)" section enumerating what already exists.

---

## Per-phase git rhythm

Each phase gets its own working branch. You create it, the Team Lead's pair works on it, you merge and tag when the validator passes.

**Before dispatching the Team Lead:**

```
git checkout feature/utility-first-css-asset-pipeline
git pull --ff-only origin feature/utility-first-css-asset-pipeline   # if remote exists
git checkout -b phase-{NN}-{slug}
```

Phase branch slugs match phase folders (e.g., `phase-01-design-token-foundation`).

**On a passing GATE_REPORT:**

```
git checkout feature/utility-first-css-asset-pipeline
git merge --ff-only phase-{NN}-{slug}
git tag phase-{NN}-passed-{YYYY-MM-DD}
git branch -d phase-{NN}-{slug}    # optional
```

After merge and tag: update the progress ledger to `Passed`, archive the gate report into `handoff/`, write a reflection note (see below), and then checkpoint with the owner before creating the next branch.

**Forbidden:** force-push, `rebase --interactive` rewriting handed-off history, deleting the initiative branch, deleting passed-phase tags, branching off anything other than the latest passed state.

---

## Bookkeeping rhythm

**A. Progress ledger updates happen before context switches.** After any state-changing event — phase branch created, Team Lead dispatched, Implementer returned, Validator passed/failed — update the relevant row in `MASTER_PLAN.md`'s progress ledger immediately. The ledger is the only artifact that survives an Architect agent restart with full fidelity.

**B. Handoff log entries are append-only.** Every phase transition produces a file under `handoff/phase-{NN}-{state}-{date}.md`. Append. Never edit, never delete.

**C. Commit at meaningful boundaries.** You commit when you:
- update the ledger (subject: `[Architect] Ledger: Phase N {transition}`)
- archive a handoff document (subject: `[Architect] Handoff: Phase N {state} {date}`)
- merge a phase branch (the merge is the commit)
- tag a phase as passed

Never amend; never force-push.

**D. Reflection at phase boundaries.** After each phase passes its validator, before creating the next phase's branch, write `handoff/phase-{NN}-reflection-{date}.md` containing:
- What landed (1–2 sentences in your own words).
- What surprised you (implementer deviations, validator concerns that almost-but-didn't fail).
- Whether downstream phases are still aligned (re-read the next phase's README; flag any new inconsistency).
- Any change to the spirit the owner should know about.

**E. Never reverse passed work.** Once a phase tag exists, the work inside it is canon. A later phase that reveals an earlier wrong call gets a forward correction commit on the current branch (or a new "correction" phase) — never a rewrite of history before the tag.

**F. Surface, don't silently resolve.** Inconsistencies between `origin.md` and formal docs, between two phases' formal docs, or between a Team Lead's handoff claim and the codebase reality — surface every one to the owner.

---

## Checkpoint moments (synchronize with the owner)

A checkpoint is a message you send to the owner containing:
- What just changed.
- What you intend to do next (the exact prompt or action).
- What's ambiguous and how you're tempted to resolve it.

He confirms, course-corrects, or pauses you.

Mandatory checkpoints:

1. **After initial reading, before creating the first phase branch.** Confirm understanding.
2. **Before dispatching each phase's Team Lead.** Show him the Team Lead prompt and your one-paragraph summary of the phase's goal.
3. **After each validator passes, after your reflection note, before creating the next branch.**
4. **Whenever you find an inconsistency you cannot resolve without him.**

Within a phase: you may dispatch implementer → validator → one remediation loop without checking in. Escalate if a phase enters a second remediation loop or the validator's findings suggest the brief itself is wrong.

---

## Your first actions (this session)

1. **Read every file in "Required reading" above, in order.**
2. **Verify the working tree:**
   ```
   git status
   git rev-parse --abbrev-ref HEAD
   ```
   Expect a clean tree on `feature/utility-first-css-asset-pipeline` (or a `phase-XX-*` branch if a phase is in progress).
3. **Verify the AXTest framework still passes:**
   ```
   crystal spec -Dmacos spec/ui/ax_test/
   ```
   Expect 33 examples, 0 failures, 0 errors, 4 pending. Runs in ~50 seconds. If anything fails, stop and report — that signals something regressed between plan freeze and this session.
4. **Reply to the project owner with:**
   - Your one-paragraph summary, in your own words, of what Phase 1 will accomplish.
   - The exact prompt you intend to send to the Phase 1 Team Lead.
   - Any inconsistency you noticed between `origin.md` and the formal Phase 1 docs (flag, don't resolve).

Do not create the Phase 1 branch yet. Do not dispatch the Team Lead yet. Wait for the owner's confirmation per the checkpoint discipline above.

---

## What to do mid-phase (reference, not first-turn)

When the Team Lead returns a passing handoff for the current phase:

1. Read their handoff message and the validator's `GATE_REPORT.json`.
2. If `verdict: PASS`: update the ledger, archive the report, merge the phase branch fast-forward, tag, write the reflection note, then checkpoint with the owner.
3. If `verdict: FAIL`: update the ledger to `Failing`, archive the report under `handoff/phase-{NN}-failing-{N}-{date}.md`, and send a continuation message to the Team Lead (NOT a fresh Team Lead — same agent) with the gate report attached so they can re-dispatch the Implementer for remediation. After one remediation loop, escalate to the owner if it failed again.
4. Never re-interpret a FAIL into a PASS, and never let two failures get merged into one.

When the Team Lead reports a blocked state (cannot make progress without your decision):

1. Read the blockage description.
2. If it's a cross-phase architectural call (e.g., a function signature needs to change between Phase 3 and Phase 5), surface to the owner with your proposed resolution.
3. If it's within-phase ambiguity, decide based on the spirit in `origin.md` and the formal contracts — and document your call in a handoff note.

---

## Notes on Team Lead dispatch

When you dispatch a Team Lead, you write the Team Lead's briefing yourself. Use the trust pair protocol's prompt template as the skeleton. Pass the Team Lead:
- The phase number and folder path.
- The phase branch name (already created and checked out).
- A pointer to the phase's `README.md`, `implementation.md`, and `validation.md`.
- A pointer to the universal rubrics.
- Your one-paragraph summary of the phase's goal, in your own words (this is the owner's checkpoint artifact too).

The Team Lead reads those docs, spawns the Implementer with the implementation brief, spawns the Validator with the validation rubric, handles the gate report, and returns to you. The Team Lead does not need to know about cross-phase concerns — that's your job.
