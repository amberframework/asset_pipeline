# Phase 6.11 — Codex Review 2 (Iteration 2)

**Date:** 2026-05-23
**Iteration scope:** Items 2 + 3 — iOS WCAG legibility audit + 14-row Todos behavior contract (framework-reactivity changes for Button reactive `disabled=`, Label `strikethrough`, iOS swipe-reveal scroll-row, Voyager screen authoring, `NavigationCoordinator#republish`).
**Diff snapshot:** `/tmp/p611-iter2-diff.patch` (699 lines, 16 files modified — one unrelated dirty fixture `spec/test_js/some_js.js` excluded from this iteration's commits).
**Author of this review:** `codex exec` (codex-cli 0.130.0).

## Codex invocation

```bash
codex exec --skip-git-repo-check "Review the diff at /tmp/p611-iter2-diff.patch against \
  docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/brief.md Items 2 \
  (WCAG legibility audit) and 3 (14-row functional Todos contract — toggle/swipe/edit/delete/Settings filter). \
  The diff is the Implementer's framework-reactivity work (Button/Label runtime mutators in Swift + Crystal, \
  swipe action wiring in renderers, screen authoring updates). Verdict per item: PASS / PROGRESS / REGRESSION \
  / NEEDS_WORK. Cite specific lines. Flag any new diagnostic NSLog / debug logging that must not ship (Phase \
  6.10 Rem 4 had a P1 password leak via leftover NSLog — check rigorously). Flag any incomplete code paths \
  (early returns, missing branches, unreachable code) that indicate the work isn't done."
```

Run took one attempt, ~125K tokens.

## Codex verdicts

| Item | Verdict |
|---|---|
| Item 2 — WCAG legibility audit | **NEEDS_WORK** |
| Item 3 — 14-row Todos contract | **NEEDS_WORK** |

Crucially: **NO REGRESSIONS** flagged. **NO diagnostic NSLog / `os_log` / `print` / password-leak / `voyager-save-chain` / `voyager-interaction-proof` patterns** in the diff.

## Codex findings (verbatim summary)

### Item 3 — Likely iOS rendering ambiguity in new swipe row

> The ObjC helper claims the row height is derived from content/action height, but the implementation only pins `stack.heightAnchor` to the scroll view frame and only constrains scroll width, not height ([patch](/tmp/p611-iter2-diff.patch:263) lines 263-264, [patch](/tmp/p611-iter2-diff.patch:297) lines 297-331). The UIKit renderer also only derives/passes `row_width` ([patch](/tmp/p611-iter2-diff.patch:451) lines 451-512), and Voyager rows only set min/max width ([todos.cr](samples/initiative-cross-platform-ui-voyager/screens/todos.cr:217) lines 217-220). A `UIScrollView` has no useful intrinsic height in a stack, so rows can collapse or become ambiguous. That blocks rows 7-10 of the brief's contract.

**Disposition:** Open finding. The behavior contract for rows 7-10 (swipe → reveal Edit/Delete, tap Edit, save edits, tap Delete) cannot be visually confirmed without simulator screenshots. The Crystal build compiles and the iOS bundle links, but the height-anchor argument is logically sound — `UIScrollView` lacks intrinsic content size, so a sibling Auto Layout pass needs an explicit height somewhere. This needs an iteration-3 fix (likely: pin `cv.heightAnchor` constant on the content view OR pin `scroll.heightAnchor` to the inner stack's content `greaterThanOrEqualTo`).

### Item 2 — Audit evidence not captured

> The brief requires 8 iPhone screenshots and `legibility-audit.md` with actual ratios ([brief.md](docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/brief.md:83) lines 83-87). The patch adds no `phase-06.11-evidence` files and no audit table. Also, the new filtered Done card dims a 13pt label with `opacity = 0.6` ([patch](/tmp/p611-iter2-diff.patch:134) lines 134-137), which is no longer a pure semantic-color shortcut under the brief's rule ([brief.md](docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/brief.md:79) lines 79-81). It needs measured contrast in light and dark.

**Disposition:** Open finding. Evidence collection is part of step 5 of the completion protocol; whatever this completion agent can capture from its seat will be deposited under `docs/initiative-cross-platform-ui/handoff/phase-06.11-evidence/`. The `opacity = 0.6` dimming is a brief-specific concern that should be re-audited once captures exist.

### Incomplete fallback path — `visit(UI::SwipeActionRow)` empty UIView early return

> `visit(UI::SwipeActionRow)` silently emits an empty `UIView` and returns if `render_detached(view.content)` fails ([patch](/tmp/p611-iter2-diff.patch:455) lines 455-463). For this phase, that would hide the row and actions while still producing "something," which is the wrong failure mode for a required 14-row functional contract.

**Disposition:** The fallback was added defensively but the failure mode is silent. Should be revisited in iter-3.

### Positive coverage

> blank/whitespace Save disabling is implemented defensively ([todo_editor.cr](samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr:98) lines 98-107, 130-132), edit/save copies draft state back only on Save ([todo_editor.cr](samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr:109) lines 109-120), checkbox toggling republishes the route ([todos.cr](samples/initiative-cross-platform-ui-voyager/screens/todos.cr:192) lines 192-201), and delete republishes after mutation ([todos.cr](samples/initiative-cross-platform-ui-voyager/screens/todos.cr:234) lines 234-241).

### Spec evidence Codex ran

> `spec/ui/voyager_state_propagation_spec.cr` passed 5/0, `spec/components/examples/example_components_spec.cr` passed 49/0.

## Decision

Per the completion-agent protocol step 3:

- All Codex verdicts are NEEDS_WORK, **not REGRESSION**.
- **NO diagnostic-log regressions** introduced.
- → Proceed to commit, document NEEDS_WORK dispositions in the implementer report.

The owner-hand-test gate (architect's call after capturing evidence) will decide whether the NEEDS_WORK items get an iteration-3 remediation or close as scoped.

## Diagnostic-log scrub

Confirmed clean:
```bash
grep -nE "NSLog|os_log|print\(|fputs" /tmp/p611-iter2-diff.patch  # 0 hits
grep -nE "voyager-(save-chain|interaction-proof)" /tmp/p611-iter2-diff.patch  # 0 hits
```
