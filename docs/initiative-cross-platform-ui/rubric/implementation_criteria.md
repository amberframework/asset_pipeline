# Implementation Criteria (Universal)

These standards apply to every phase. The phase-specific `implementation.md` may extend them but must not contradict them.

---

## Branch and commits

- Work on the phase's dedicated branch: `phase-{NN}-{slug}` (e.g., `phase-01-design-token-foundation`). The Architect creates this branch from the latest `feature/utility-first-css-asset-pipeline` head BEFORE dispatching the Team Lead, so it already exists and is checked out when you receive your brief. Confirm with `git rev-parse --abbrev-ref HEAD` before your first commit.
- Do NOT branch further from the phase branch. All implementer + remediation commits land directly on `phase-{NN}-{slug}`.
- Commit incrementally. A single phase typically produces 3–10 commits, not one mega-commit.
- Commit subject: `[Phase {N}] {imperative summary, ≤ 72 chars}`. Example: `[Phase 1] Add DesignTokens unified type with web/native generators`.
- Commit body: explain *why*, not *what*. The diff shows what. Mention any non-obvious decisions or alternatives considered.
- Do not include `Co-Authored-By: Claude ...` unless the team lead has explicitly asked for it on this project.
- Do NOT amend a commit that has already been part of a handed-off chain. Do NOT force-push. Do NOT rebase shared history. If a commit needs correcting, write a new forward commit. The audit trail is the contract.
- Merging the phase branch back into the initiative branch and tagging the phase as passed are the Architect's responsibility, not yours. Your job ends when your handoff message is delivered.

---

## Code quality

- **Follow existing conventions in the file you are editing.** Do not introduce a new pattern when an established one exists 50 lines above.
- **Crystal style:** snake_case for methods/vars, PascalCase for types, kebab-case for shard names. Use `getter`/`setter`/`property` macros, not hand-written accessors.
- **No `puts` or `pp` left in committed code.** Use `Log.info { ... }` if logging is needed.
- **No commented-out blocks.** If you removed code, remove it. Git remembers.
- **Avoid speculative abstractions.** If you find yourself writing a generic system to handle two cases, write it for two cases. The third case rewrites the abstraction; the second does not.
- **No `TODO:` comments without a tracking issue.** Either fix it now or open a GitHub issue and reference it in the comment.

---

## Testing

- Every new public method, view widget, or renderer visitor gets at least one spec.
- Specs go in `spec/` mirroring the source path: `src/ui/views/foo.cr` → `spec/ui/views/foo_spec.cr`.
- Use `describe ... it ...` blocks. One `it` per behavior, not per method.
- For renderer changes, add an integration spec that asserts the rendered output (HTML for web, expected ObjC call sequence for native if practical).
- Existing test suite must remain green: `crystal spec` from repo root.
- If your phase adds platform-gated code, ensure each compile target still builds: at minimum, `crystal build --no-codegen src/asset_pipeline.cr` for default web, and the macOS/iOS sample builds documented in `samples/cross_platform/`.

---

## Documentation

- Every new public type, method, or compile flag gets a doc comment.
- Crystal doc-comment format: lines prefixed `#` directly above the symbol. Cite invariants and gotchas, not what the signature already says.
- Update top-level `README.md` only when the public API changes in a user-visible way.
- Update `CLAUDE.md` (repo root) when conventions for future agents change — adding a new platform flag, a new component category, etc.
- Phase-specific docs (added inside the phase folder) belong there, not at the repo root.

---

## Cross-platform invariants

When you add or modify a widget or renderer:

1. **The widget's public API must work on all four platforms** unless the widget is explicitly Tier 3 (platform-only). Tier 3 widgets must be guarded with `{% if flag?(:ios) %}` or equivalent and must produce a clear compile-time error on unsupported platforms (or fall through to a documented web fallback if one is wired).
2. **`test_id` must be honored** by every renderer for every widget. If you add a widget, the four renderers must each emit the appropriate accessibility identifier (`data-testid`, `setAccessibilityIdentifier:`, `setContentDescription`).
3. **Brand tokens must be the source of truth** for colors, spacing, type, radius, motion. Do not hard-code values in renderer visitors. If a value is genuinely platform-specific (e.g., NSVisualEffectMaterial constant), wrap it in a token and document the mapping.
4. **Accessibility is not optional.** New interactive widgets must have a focus indicator on web, a keyboard activation path on macOS, a VoiceOver label on iOS, and a TalkBack content description on Android.

---

## Working with the validator

You will not interact with the validator directly. They will receive a separate prompt with the validation rubric and your handoff message. You will see their report only if it fails (the team lead will forward it).

This means:

- **Make your work easy to validate.** If a check requires running a specific script, ensure that script exists and works. If a check requires looking at a screenshot, ensure the screenshot is generated.
- **Be honest in your handoff "Deviations" section.** A deviation that the validator catches and you didn't disclose is more expensive than one you disclosed up front.
- **Don't argue with future gate reports in the code.** If you think a future validator might misread something, document it clearly in code comments or in the handoff "Known concerns" section, not in a hidden assumption.

---

## When the brief is wrong

The `implementation.md` for your phase was written before code existed. It may be wrong about file paths, function signatures, or what's already in place. When you find a discrepancy:

1. **If the discrepancy is small** (a renamed file, a slightly different signature), proceed with the obvious correction and note it in your handoff `Deviations` section.
2. **If the discrepancy is large** (the brief assumes a system exists that doesn't, or a system the brief tells you to build already exists), **stop and return early** to the team lead with a description of what you found and what you think the brief should say instead. Do not freelance a large divergence.

---

## Definition of done (per phase)

Done means:

1. All scope items in `implementation.md` are implemented.
2. All existing tests still pass.
3. New tests for new functionality exist and pass.
4. Code is committed with proper subjects.
5. Your handoff message has been written and includes commit hashes.
6. You have not modified any file under `docs/initiative-cross-platform-ui/` other than appending to a phase's `notes.md` if explicitly invited to.

Done does **not** mean:

- The validator has reviewed it (that's the next step).
- You have re-run the validation rubric yourself (you should not).
- The team lead has approved the next phase (that's a separate decision).
