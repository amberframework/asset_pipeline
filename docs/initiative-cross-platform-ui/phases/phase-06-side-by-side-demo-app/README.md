# Phase 6 — Side-by-Side Demo App

**Tier:** Composition of Tier 1/2/3
**Depends on:** Phases 1–5 (everything they build must be in place for the demo to be representative) **AND Phase 6.5** (the audit harness Phase 6's Implementer must use during development per the audit-first lesson in `handoff/planning-retrospective-2026-05-22.md` Principle 6)
**Blocks:** Phase 7 (CI integration of the audit infrastructure Phase 6.5 ships)
**Estimated remediation budget:** 1 loop

> **2026-05-22 update:** Phase 6 was originally scoped to run before Phase 7. The planning retrospective surfaced this as conflicting with the audit-first lesson — Phase 6 would have repeated Phase 3's pattern of shipping then chasing gate-time regressions. Phase 6.5 was inserted to ship reusable audit infrastructure BEFORE Phase 6 begins; Phase 6's Implementer runs that harness during development. Phase 7's scope was narrowed to "integrate Phase 6.5's harness into CI."
>
> **Brief authoring constraint:** Phase 6's brief MUST be authored as YAML against `schemas/phase_brief.schema.json` and pass `scripts/validate_phase_brief.cr` before dispatch.

---

## Why this phase exists

The existing `samples/cross_platform/` HIG validation studies are **fine-grained per-component reference shots**. They're great for "does our Button look like Apple's Button?" — but they don't show "does our entire app feel like the same brand on web, iOS, and macOS?"

The user's stated litmus test: *"I should be able to look at them side by side and tell that they represent the same brand."* That requires a single demo app, with multi-screen flow, rendered on every platform.

This phase builds that demo app.

## What the demo app contains

A small but representative product:

1. **Sign-in screen** — Brand wordmark, two text fields, primary button, secondary text link, social-auth row. Covers: typography, input styling, button states, link affordance.
2. **Dashboard (3-tab)** — TabView/TabBar. Tab 1: card grid of items. Tab 2: list with section headers. Tab 3: profile/settings form. Covers: navigation idioms, tab styling, card surfaces (glass where appropriate), list/grid layout responsiveness.
3. **Detail view** — Triggered from card or list item. Hero image, title, description, action buttons. Covers: navigation push/pop, image scaling, multi-column layout on wide viewports.
4. **Settings/form screen** — Toggles, picker, segmented control, slider, color picker, button row. Covers: form widgets, native platform pickers where applicable.
5. **Tier 3 demo screen** — A screen that specifically uses platform-only widgets. Action sheet (iOS), context menu (macOS/iOS), path control (macOS). On web, the screen uses the explicit `*WithWebFallback` variants from phase 4. (HapticFeedback was scoped out of Phase 4 and remains out of scope for Phase 6 — adding it would require shipping a new widget type. If the demo benefits from it, surface to architect to add a Phase 6.5 or 7 follow-up.)

The screens are connected via a navigation stack. The flow is: sign-in → dashboard → (from card) detail; (from settings tab) settings; (from dashboard) tier-3 demo.

## Scope summary

In scope:

- New folder: `samples/initiative-cross-platform-ui-demo/`.
- Single Crystal source declaring the demo app (one file or a small set of view modules).
- Build configurations:
  - `make web` → outputs a static HTML site to `output/initiative-demo/`.
  - `make macos` → outputs a runnable `.app`.
  - `make ios` → outputs a runnable iOS simulator app.
- A simple branding file declaring the demo brand (palette, type, radius, motion) — distinct from the default amber brand, so that "brand override works" is visibly demonstrated.
- Screenshot harness: a script `scripts/capture_demo_quad.cr` (or similar) that:
  - For each of the 5 screens
  - At each of the standard viewports for web (1280, 768, 375)
  - On iOS simulator (iPhone 17 Pro)
  - On macOS (resizable: captured at wide and narrow)
  - In light and dark mode
  - Produces a **quad-comparison HTML page** at `output/initiative-demo/quad-comparison.html` that shows the four user-facing surfaces side-by-side per screen. The "quad" is: web-desktop (1280px), web-mobile (375px), iOS sim (iPhone 17), macOS host. Android consumers see the web target via the Tier-3 `*WithWebFallback` path — Android is NOT a fifth surface. See `brief.yml` decision #8 for full quad definition.
- A README at `samples/initiative-cross-platform-ui-demo/README.md` explaining how to build and view the demo.

Out of scope:

- Real-world content (the demo uses lorem-ipsum, placeholder images, no live data).
- Auth/networking (sign-in is visual-only).
- Animation polish beyond what Tier 2 defaults provide.
- Wrapping Phase 6.5's harness into GitHub Actions / CI (that's Phase 7). NOTE: capturing the NEW baseline PNGs for the demo screens IS in Phase 6's scope per the brief — Phase 6 invokes Phase 6.5's `regenerate_baselines.sh` to populate baselines/ as screens land (audit-first principle). Phase 7 then wraps the populated harness into CI.
- Comparing the demo to existing per-component HIG studies. They serve different purposes; both are kept.

## Acceptance summary

Phase 6 is done when:

- The demo builds and runs on web (resized through 1280/768/375 fluidly), iOS simulator, macOS (resized fluidly).
- The quad-comparison page is generated and shows the five screens side-by-side across platforms in light + dark.
- A reasonable reviewer looking at the quad-comparison can:
  - Identify all four as the same brand.
  - See platform-specific defaults: iOS shows Liquid Glass on appropriate surfaces; web shows browser-native focus rings; macOS uses NS-style title bars; mobile web reflows to single column.
- The Tier 3 screen visibly uses native widgets on iOS/macOS and the documented web fallback on web.
- Spec suite passes.

Detailed checks in `validation.md`.

## Risk notes

- The demo is the integration test for everything before it. If phases 1–5 weren't really done, phase 6 surfaces it. Budget time for "actually we need to remediate phase X" discoveries.
- The quad-comparison HTML page is the artifact the user will look at to declare the initiative successful. Layout matters — make it easy to compare like-for-like.
- Image placeholders should be license-clean (use a consistent placeholder service or local SVG assets, not random photos).
- The brand override file should be visibly *different* from the default amber brand so that "brand override works" is obvious. A subtle palette tweak isn't enough; pick a notably different primary color.

## Briefing documents

- Implementer: `implementation.md`
- Validator: `validation.md`
- Universal: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`
