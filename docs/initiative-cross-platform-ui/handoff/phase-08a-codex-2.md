# Phase 8A — Codex review, iter 2 (Items 3 + 4: name property, name= emission, text:/name: kwargs)

**Commit reviewed:** b0880972 (HEAD of `phase-08a-amber-render-screen-form` at review time).
**Items:** 3 (name property + web name= emission) + 4 (text: / name: kwargs).
**Date:** 2026-05-24.

## Verdict

**APPROVE** — no blocking findings.

## Codex transcript (verbatim, abbreviated)

> No blocking findings.
>
> Verdict: APPROVE
>
> The constructor change preserves existing positional usage: `placeholder` remains the first optional positional arg, while `name:` and `text:` are keyword-only in `text_field.cr:41` and `secure_field.cr:16`. Existing zero/one-positional and block call sites compile in the targeted spec pass; the only failure was the unrelated pre-existing theme expectation.
>
> `name=` emission is guarded correctly for nil/empty and is non-mutating: `web_renderer.cr:284` and `web_renderer.cr:844` create fresh input elements and set the attribute once only when non-empty.
>
> The SecureField asymmetry looks acceptable for this iteration. It remains a distinct password input primitive, so no `secure_entry` toggle is needed; omitting `keyboard_type`/`inputmode` is consistent with password semantics and with the narrow Phase 8A Items 3/4 scope.
>
> The finding #7 regression spec does cover the setter path: it constructs the field, assigns `field.text = ...`, then renders and checks `value=` in `web_renderer_spec.cr:427`.
>
> Verification run:
> - `crystal spec spec/ui/renderers/web_renderer_spec.cr` passed 85/0.
> - Constructor-heavy targeted specs compiled; 1 unrelated theme failure remained.
> - `git diff-tree --check --no-commit-id -r b0880972` passed.

## Remediation

None required.

## Tokens used

~55k.
