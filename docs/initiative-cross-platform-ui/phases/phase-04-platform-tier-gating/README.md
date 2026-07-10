# Phase 4 — Platform Tier Gating

**Tier:** 3 (Platform-Only Widgets) + verification of Tier 1/2 boundary
**Depends on:** Phase 3 (cannot verify Tier 2 defaults until SwiftUI is in place)
**Blocks:** Phase 6 (demo app needs to show off Tier 3 widgets)
**Estimated remediation budget:** 1 loop

---

## Why this phase exists

Today every widget in the library claims to work on every platform via a fallback rendering path. For widgets that are genuinely platform-native (ActionSheet, ContextMenu, HapticFeedback), this means the "fallback" on a non-supporting platform is a half-built approximation — neither a real ActionSheet nor an honest "this isn't available here" signal.

The user's intent:

- **Tier 1 (universal):** Brand-level concerns. Already universal. (Phase 1 made the tokens canonical.)
- **Tier 2 (platform default):** Native styling that comes through automatically. (Phase 3 made this real on Apple.)
- **Tier 3 (platform-only):** A widget that **only exists on certain platforms**. Using it on an unsupported platform should be a clear compile-time error unless the developer explicitly opts into a documented fallback.

This phase formalizes the Tier 3 contract and applies it.

## Scope summary

In scope:

- Tier 3 widget classification. The widgets identified for Tier 3:
  - **`ActionSheet`** — iOS-native, no macOS/web equivalent (macOS uses Sheets/popovers; web uses dialogs)
  - **`ContextMenu`** — macOS/iOS native; web equivalent is a custom dropdown (not as good)
  - **`HapticFeedback`** — iOS-only
  - **`MenuBarExtra`** — macOS-only
  - **`Toolbar` (NSToolbar/UIBarButtonItem-style)** — Apple-only; the web Toolbar is a different concept (kept as Tier 1)
  - **`PathControl`** — macOS-only
  - **`ColorPicker` native picker** — iOS/macOS native chrome; web uses HTML `<input type="color">`
  - **`DatePicker` / `TimePicker` native chrome** — iOS native chrome distinct from desktop date inputs
- Compile-time guarding. Tier 3 widget classes are wrapped in `{% if flag?(:ios) %}` / `{% if flag?(:macos) %}` etc., or they raise a clear `{% raise "..." %}` compile-time error when included in a build without the right flag.
- Documented fallbacks. For each Tier 3 widget where a sensible web fallback exists, provide one **as a separate explicit class** (e.g., `ActionSheetWithWebFallback`). The developer must reach for it intentionally. The default `ActionSheet` does not silently render a dialog on web.
- Web fallback implementations where chosen:
  - `ActionSheet` web fallback: a bottom sheet pattern (CSS + minimal JS) meeting accessibility standards (focus trap, escape to dismiss, ARIA role="dialog").
  - `ContextMenu` web fallback: a positioned dropdown (CSS + minimal JS, ARIA role="menu").
- Documentation: a new doc page `docs/initiative-cross-platform-ui/tier-matrix.md` (or extend `CLAUDE.md`) listing every widget with its Tier and platform support.
- A Crystal macro/helper: `Platform.requires(:ios)` that a developer can call in their own code to gate platform-only logic, mirroring the widget gating.
- Specs:
  - Compile-time error specs: building a snippet that uses `ActionSheet` on a non-iOS target produces a compile error with a useful message.
  - Web fallback behavior specs: bottom-sheet focus trap, ARIA roles correct, escape closes the sheet.

Out of scope:

- Adding new Tier 3 widgets (this phase only classifies existing ones; new widgets go through the same process).
- Migrating Tier 1/2 widgets that the validator finds aren't using SwiftUI defaults correctly (that's a phase 3 remediation, not phase 4).
- Android-side Tier 3 widget gating. Android currently has no widgets we'd classify as Tier 3-only — they're either Tier 2 (Material handles them) or absent. If a future Tier 3 Android widget arrives, the pattern established here applies.

## Acceptance summary

Phase 4 is done when:

- Every widget in the library is classified Tier 1 / 2 / 3 in `tier-matrix.md`.
- Building a sample that uses a Tier 3 widget on an unsupported platform fails at compile time with a message like: `ActionSheet is iOS-only. Use ActionSheetWithWebFallback or guard with {% if flag?(:ios) %}.`
- Web fallbacks for ActionSheet and ContextMenu render correctly, pass axe-core + IBM Equal Access audits, and meet WCAG 2.2 AA for focus management.
- Documentation is updated.
- Spec suite passes.

Detailed checks in `validation.md`.

## Risk notes

- The macro-based compile-time guard must produce a useful error message. A bare `{% raise %}` with a generic message is not enough.
- Existing sample apps and demos may use Tier 3 widgets without realizing it. The implementer must audit and either guard them or migrate to the explicit web-fallback class.
- The web fallback's JS must be self-contained (the library is a no-npm-no-bundler shop). Use vanilla JS, no framework.

## Briefing documents

- Implementer: `implementation.md`
- Validator: `validation.md`
- Universal: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`
