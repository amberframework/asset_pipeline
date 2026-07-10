# Phase 1 — Design Token Foundation

**Tier:** 1 (Brand)
**Depends on:** Nothing (foundational)
**Blocks:** All subsequent phases
**Estimated remediation budget:** 1 loop

---

## Why this phase exists

Today the library has *two* token systems that don't talk to each other:

- `src/ui/theme.cr` — `UI::Theme` record consumed by native renderers (RGB values, Material Design 3 semantic roles, Apple label references).
- `src/components/css/tokens/amber_theme.cr` — CSS custom properties generated for the web design system (OKLCH color space, currently a mix of `--amber-color-*` legacy names and `--ap-color-*` neutral names; this phase makes `--ap-*` canonical and drops the `--amber-*` aliases entirely).

The same brand decision (e.g., "primary is #7c9a92") has to be made in two places. There is no single source of truth, and the brand can't be overridden once without touching multiple renderers.

This phase establishes a unified `DesignTokens` model with per-platform generators. After this phase:

- A single Crystal source declares all Tier 1 brand decisions.
- Web CSS, Apple Swift constants, and Android resources are all generated from that source.
- Changing one token value cascades correctly to every renderer with zero edits to renderer code.

## Scope summary

In scope:

- New `UI::DesignTokens` type (and supporting subtypes) covering: **color palette + semantic roles**, **spacing scale**, **type scale (size + weight + line-height + tracking)**, **border radius scale**, **shadow/elevation scale**, **motion scale (durations, curves)**, **breakpoints**. The model is platform-agnostic and includes Android-equivalent fields so a future Android generator can read from the same source.
- A `Brand` interface that lets a consuming app declare a single brand override file. The override merges into the default tokens; unspecified fields fall back to defaults.
- Generators:
  - `DesignTokens::WebGenerator` → emits CSS custom properties (replaces/subsumes current `amber_theme.cr`)
  - `DesignTokens::AppleGenerator` → emits a Swift companion file with `enum DesignTokens` for SwiftUI consumption (sets up phase 3)
- Migration of existing **web, AppKit, and UIKit** renderer visitors to consume tokens via accessor methods, **not** by reading hard-coded values.
- Deprecation path for the existing `UI::Theme` record (kept as an adapter that reads from `DesignTokens`). The Android renderer continues to read through the legacy `UI::Theme` adapter until a future phase ships the Android generator + scrub.
- Specs for: token resolution, brand override merging, each generator's output stability.

Out of scope:

- Designing a brand. The default brand (existing Amber) carries over verbatim; this is plumbing, not visual design.
- Container queries (phase 2).
- Token-driven glass material strength (phase 5; tokens added here but the glass renderer wiring is phase 5's job).
- Removing the legacy `amber_theme.cr` file. Keep it as a thin re-export of the new generator's output to avoid breaking existing consumers in this phase. (Note: the `--amber-color-*` CSS variable aliases ARE dropped in this phase — only the Crystal file persists as a re-export.)
- **`DesignTokens::AndroidGenerator` and the Android XML dist artifacts** (`values{,-night}/colors.xml`, `values/dimens.xml`, `values/themes.xml`). Deferred to a follow-up phase per `../../handoff/phase-01-architect-scope-deferral-2026-05-20.md`. The `UI::DesignTokens` model itself still carries the Android-equivalent data so the future generator has nothing to re-derive.
- **Android renderer literal-scrub.** `android_renderer.cr` continues to read brand decisions via the `UI::Theme` adapter (which now wraps `DesignTokens.default`) until the deferred Android phase migrates its visit methods.

## Acceptance summary

Phase 1 is done when:

- Changing a single value in the canonical brand declaration changes the rendered output on web and at least one Apple target (macOS or iOS) sample app — verified by screenshot diff.
- The full spec suite passes.
- The web entry point and the macOS / iOS sample entry points build clean (`--no-codegen`). The Android sample is allowed to keep building against the legacy `UI::Theme` adapter unchanged.
- The validator confirms zero hard-coded color/spacing/type values remain in the **web, AppKit, and UIKit** renderer visit methods (everything reads via token accessors). The Android renderer is exempt for this phase per the scope deferral.

Detailed checks in `validation.md`.

## Risk notes

- The existing renderers are large (`appkit_renderer.cr` is 4,700 lines, `uikit_renderer.cr` ~5,200). Refactoring every visitor to read tokens is mechanical but voluminous. Implementer should plan to commit per-renderer to keep the diff reviewable.
- OKLCH ↔ RGB conversion needs to be deterministic and round-trip-stable for the validator's screenshot diffs to be meaningful. Use a vetted conversion (the existing `amber_theme.cr` already has one; verify it's correct before reusing).
- Brand-identity color conformance is held to a **visual-grade** bar (ΔE2000 ≤ 1.0) at the five canonical comparison points (`brand-primary`, `surface-canvas`, `text-primary`, `border-default`, `danger-indicator`), tighter than the implementation-grade round-trip arithmetic tolerance. See `../../handoff/phase-01-architect-scope-deferral-2026-05-20.md` §"Architect tolerance call" for the rationale.

## Briefing documents

- Implementer: `implementation.md`
- Validator: `validation.md`
- Universal: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`
