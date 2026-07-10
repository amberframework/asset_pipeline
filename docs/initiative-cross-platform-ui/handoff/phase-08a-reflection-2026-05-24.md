# Phase 8A — Architect Reflection

**Phase:** 8A — Amber `render_screen` + UI::Form Web POST Semantics
**Date closed:** 2026-05-24 (PASS — clean, not PASS_WITH_NOTES)
**Branch:** `phase-08a-amber-render-screen-form` (merging to feature branch)
**Final HEAD:** `32d064dc`
**Tag:** `phase-08a-pass-2026-05-24`

## Verdict

**PASS.** First phase this session to earn a clean PASS. Every brief item delivered with empirical evidence; 5/5 Codex APPROVE across iterations (2 with single REVISE-and-fix rounds); 0 REJECT; 0 blocker escalations; real browser POST proof closing the gate; +47 new spec examples; 0 regressions.

## What shipped

### Item 1 — `src/asset_pipeline/amber_integration.cr` (lifted from spike)

- `UI::ScreenContext` abstract base + `UI::ScreenContext::Web` concrete impl wrapping Amber's params/session/flash via delegation. Exposes scalar `params : Hash(String, String)` + `params_multi : Hash(String, Array(String))`.
- `UI::ScreenHelpers` mixin providing `compute_screen_html(ScreenClass) : String`.
- `UI::AmberConfig` module with `design_tokens : Tokens` class-property.
- `UI::Screen` abstract base class with `build(ctx) : UI::View`.
- Per-controller static shim ECR template + CLI generator (`bin/asset_pipeline_amber` or equivalent) — macro file-generation rejected by Codex.
- Codex iter 1 caught the `render_context:` API being positional; correction made it kwarg-only.

### Items 3 + 4 — `name:` + `text:` kwargs + web `name=` emission

- `UI::TextField` + `UI::SecureField` gained `name : String?` property and `text:`/`name:` constructor kwargs.
- Web renderer emits `name="..."` when set.
- Form re-display after failed submit now ergonomic: `UI::TextField.new(placeholder: "Email", name: "email", text: context.params["email"]? || "")`.

### Item 5 — `UI::Button::Type` enum + web submit-button emission

- `enum Type { Button, Submit, Reset }`, default `Type::Button` (existing behavior).
- Web renderer's `visit(UI::Button)` emits `type="submit"` / `type="reset"` based on property.
- UI::Form auto-promotes a SINGLE-button form's button to `Type::Submit` automatically; multi-button forms require explicit `type: :submit` on the intended submitter. Codex iter 4 follow-up expanded the auto-promotion scan to the ENTIRE form tree (not just flat children) per the section-form composition case.

### Item 2 — Extended `UI::Form` with web POST semantics

- `action : String?`, `method : String = "POST"`, `csrf_token : String?` properties.
- `children : Array(View)` for flat-form usage alongside the existing `sections` for grouped forms.
- Web renderer's `visit(UI::Form)` emits `<form action method>` wrapper + `<input type="hidden" name="_csrf">` when `action` is non-nil. Existing section/field rendering preserved.
- Native visit UNCHANGED — existing `Form { Section { ... } }` rendering on iOS/macOS keeps working.
- CSRF threading via `UI::RenderContext` passed to renderer (not Form mutation post-build).
- Codex iter 4 caught a too-narrow auto-promotion scan; corrected.

### Browser POST proof (the closing gate)

- Real headless Chrome 149 driven by Selenium.
- GET `/` returned the rendered Sign-in screen with CSRF meta + Amber session cookie.
- POST `/sign_in/submit` with form-encoded body (`_csrf=...&email=seth@example.com&password=password123`).
- HTTP 200 response with `✓ Signed in as seth@example.com.` flash notice rendered in the page.
- Evidence: `findings-browser-{get,submit}.png` + `findings-browser-network.json` (DevTools Network log) + `browser_post_proof.py` (archived driver script).
- Codex iter 5 verdict: "**APPROVE** — no blocking findings. The spike uses the production integration path... `sign_in_screen.cr:23` uses `UI::Form.new(action:, csrf_token:)`... Browser POST evidence is sufficient for the closing gate."

## What's open

Nothing carries forward from 8A itself. The Phase 8 plan keeps:
- 8B (native UI::App + UI::Controller + ActionDispatcher + FormState)
- 8C (`routes_for(UI::App)` registration helper if Phase 8 demos warrant it)
- 8D (Voyager migration to the new API + 14-row hand-test contract)
- 8E (docs + skill + tutorial)

## Lessons (worth saving)

### 1. Spike-then-design works

[[design-amber-first-not-after]] — the lesson from Phase 8 v1 REJECT was correct. The spike at `samples/phase-08-amber-spike/` surfaced 10 specific gaps before the design v2 / brief 8A was authored. Phase 8A then shipped without architectural surprises because every item was grounded in empirical evidence, not speculation.

### 2. Per-iteration Codex caught the right scale of bugs

Codex iter 1: `render_context:` should be kwarg-only (API ergonomics).
Codex iter 4: auto-promotion scan needs to walk the WHOLE form tree (sectioned forms can have buttons inside sections, not just at the top-level). 

Both are subtle, both would have shipped if Codex hadn't been a per-iteration gate. The protocol is paying for itself.

### 3. Browser POST proof beat curl as a closing gate

Phase 6.10/6.11 used curl for proof. Phase 8A's brief explicitly upgraded the gate to "real browser" because Codex's spike critique noted curl proves manual form construction, not browser workflow. Selenium-driven Chrome closed that gap — the Network log showing `<form>` submission with real `_csrf` from the meta tag is the empirical answer to "does this work for a human?"

### 4. EXTEND existing widgets, don't REPLACE

The Phase 8A brief almost shipped a new conflicting `UI::Form` type. Codex's brief critique caught that `UI::Form` already exists with section semantics. Extending it preserved cross-platform consistency and avoided a deprecation cycle. Lesson saved adjacent to [[plan-what-to-understand-not-just-what-to-build]].

## Bookkeeping

- 11 commits on `phase-08a-amber-render-screen-form` (10 work + 1 closeout).
- 5 Codex iteration reviews + Codex critique trail from brief authoring (4 revisions).
- Tag incoming: `phase-08a-pass-2026-05-24`.
- Spec: 1529/4/0 → 1576/4/0 (+47 examples, same 4 pre-existing failures).
- All hard rules complied: iOS/macOS/Android renderers untouched; no macro file-gen; no Form#csrf_token mutation; 0 `voyager-*` diagnostic tokens; standard co-author footer everywhere.

— Architect (Claude Opus 4.7)
