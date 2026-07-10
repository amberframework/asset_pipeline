# Phase 6.12 — Library-Identity Pivot + macOS Polish

**Inserted:** 2026-05-24, after Phase 6.11 PASS_WITH_NOTES.
**Dependencies:** Phase 6.11 PASS_WITH_NOTES (tag `phase-06.11-pass-with-notes-2026-05-24`).
**Blocks:** Initiative final sign-off.

## Why this phase exists

Phase 6.11 closed PASS_WITH_NOTES with one architectural finding the owner explicitly elected to address (Option C) and several carryover items that depend on it landing first.

**The library-identity finding (full doc:** [`phase-06.11-iter-5-architectural-finding.md`](../../handoff/phase-06.11-iter-5-architectural-finding.md)**):**

The library's iOS renderer unconditionally installs `apsk_runtime_set_brand_tint(...)` with `Tokens.default.colors_light.brand_primary` on every render. `Tokens.default.brand_primary` is the library's amber identity. `HostingHelpers.host` then applies `.tint(amber)` to every SwiftUI root, so consumer apps that didn't ask for a brand (Voyager after Phase 6.11 Item 1's `brand.cr` deletion) STILL render Cancel buttons, `.bordered` chrome, and `.borderedProminent` defaults in amber.

The owner directive "stick with SwiftUI defaults" cannot be honored without addressing this at the library layer.

**Option C (owner-selected):** `Tokens.default.brand_primary` resolves to the platform's system accent (iOS systemBlue / macOS controlAccentColor / web -apple-system-blue / Android colorPrimary). Apps that want their own brand call `.with_brand(...)` explicitly. The asset_pipeline library no longer has "an amber look" by default; it inherits the platform's native accent.

This phase implements Option C across all renderers AND finishes the macOS polish items the Phase 6.11 reflection deferred:

- macOS window sizing (currently opens "arbitrarily extremely wide," width not user-resizable, no min height — owner-observed during Phase 6.10 hand-test).
- Dark mode behavior on the macOS NSWindow (analog of Voyager's iOS SceneDelegate appearance pinning).
- Cascade demo gets explicit `.with_brand(CascadeBrand)` to preserve its branded look (preventing Option C from accidentally stripping Cascade's identity).

Plus the Phase 6.11 deferred verification items that only make sense AFTER Option C lands:

- Legibility audit rewrite with code citations + measured pixel ratios (the Phase 6.11 iter-3 audit relied on over-broad "semantic auto-pass" claims Codex caught).
- Swipe-revealed iOS screenshots.
- 28-row behavior screenshots (the Phase 6.11 brief revision 2 Item 3 contract — never captured).

## Scope

**In scope:**

1. **Library-identity pivot (Option C).** `Tokens.default.brand_primary` semantically resolves to platform system accent. Implementation requires either (a) introducing a `Color::SYSTEM_ACCENT` sentinel that each renderer detects + maps to the platform-native accent path (preferred — preserves the brand-cascade infrastructure for apps that want a custom brand), OR (b) making `brand_primary` nilable with explicit nil meaning "system accent" (clearer semantic but bigger type ripple). Implementer chooses; architect-side Codex reviews the choice before dispatch.

2. **Renderer-level integration of (1).**
   - iOS `UIKit::Renderer#ensure_swiftkit_runtime!` (uikit_renderer.cr:4109-4112) detects system_accent and calls `apsk_runtime_clear_brand_tint` instead of `set_brand_tint` (so SwiftUI's environment `accentColor` resolves to UIColor.systemBlue).
   - macOS `AppKit::Renderer` analog (appkit_renderer.cr:~4014) — same logic, calls `apsk_runtime_clear_brand_tint` for system_accent.
   - Web renderer (`web_renderer.cr`) — emits CSS variable `--ap-color-brand-primary` as `-apple-system-blue` / `system-ui` color OR omits the variable entirely when system_accent (browser falls back to system accent).
   - Android renderer — stub path for now; document approach for future implementation.

3. **macOS window sizing + min height.** Voyager `samples/.../voyager/macos/host.cr` — the NSWindow currently opens at an arbitrary width and resists horizontal resize. Investigate + fix:
   - Sensible default content size (likely 800-1000 pt wide × 600-700 pt tall, matching iPad-ish proportions).
   - `styleMask` includes `.resizable` (verify horizontal resize works).
   - `contentMinSize` set so the window can't shrink below ~480 × 400 (the Phase 6.10 fluid-resize work assumed reflow handles narrow widths, but a hard floor prevents broken layouts at e.g. 200 pt wide).

4. **macOS dark mode.** Check whether Voyager's macOS host has an analog of the iOS `VoyagerSceneDelegate` env-var pin. If it forces appearance, document it. If it doesn't, verify the NSWindow follows system dark mode correctly with the new system-accent-by-default tokens.

5. **Cascade demo preservation.** Cascade IS a branded demo (deep teal); Option C would strip its identity if it consumes `Tokens.default` without override. Audit Cascade's brand setup (`samples/initiative-cross-platform-ui-demo/cascade/`) and ensure it explicitly calls `.with_brand(CascadeBrand.new)` so its branded look survives the library default change.

6. **Legibility audit rewrite (iOS, post-Option-C).** Recapture the 8 iPhone 17 Pro screenshots with Option C in effect. Rewrite `phase-06.11-evidence/legibility-audit.md` (or supersede with a Phase 6.12 version) with the discipline from [[audit-shortcut-trap]]:
   - Every claimed auto-pass row cites the `file:line` that produces the semantic-color render path.
   - Every NON-semantic row has measured pixel coordinates + WCAG ratio.
   - At least one element per screen-appearance is pixel-measured even when auto-pass is plausible (sanity check).
   - The Done card opacity=0.6 case stays explicitly measured.

7. **macOS legibility audit.** Same WCAG discipline applied to the macOS Voyager bin in 3 window sizes (narrow ~480, default ~880, wide ~1280) × light + dark.

8. **iOS swipe-revealed screenshots.** Capture `voyager-todos-swipe-revealed-{light,dark}.png` — required in Phase 6.11 iter-3 but never produced. Drive via XCUITest extension OR by-hand (architect's call; the brief allows either).

9. **iOS 14-row behavior screenshots.** The Phase 6.11 brief revision 2 Item 3 contract: 14 actions × light + dark = 28 captures of the functional CRUD flow (sign-in → add → save → toggle complete → swipe → edit → save → swipe → delete → settings → toggle filter → back → unfilter → back). These verify the framework reactivity from Phase 6.11 iter-2 actually works end-to-end on a built app.

**Explicitly out of scope:**

- Android renderer beyond the stub path.
- New widgets.
- Brand-override redesign (semantic contrast pairs) beyond what Option C requires.
- URL routing / deep links.
- Audit harness refactor.
- Additional Voyager screens.

## Acceptance

**Architectural:**

- `Tokens.default.brand_primary` no longer carries the library's amber identity. It resolves semantically to platform system accent.
- `grep -rE "amber|0\.[5-9][0-9]+.*0\.[3-6]" src/ui/design_tokens.cr` returns 0 hits for color literals (any amber default is gone).
- Cascade demo continues to render in its deep teal brand (preservation test).
- Voyager demo renders ALL chrome — buttons, toggles, links, `.bordered`, `.borderedProminent`, `.tint` cascade — in iOS system blue / macOS controlAccentColor.

**macOS:**

- `samples/.../voyager/macos/host.cr` NSWindow opens at a sensible default size (documented in implementer report; recommended 880×640 to match standard form-app proportions).
- Window is user-resizable in both axes.
- `contentMinSize` enforced (window cannot collapse to a broken state).
- Dark mode honored either via system following OR via documented env-var if intentional pinning matches iOS pattern.

**Legibility audits:**

- iOS: 8 screenshots + WCAG audit at `docs/initiative-cross-platform-ui/handoff/phase-06.12-evidence/ios-legibility-audit.md`. Every row has `file:line` citation OR measured ratio. Pass criteria: WCAG 2.2 AA (4.5:1 body, 3:1 large/UI).
- macOS: 6 screenshots (3 window widths × 2 appearances) + WCAG audit at `phase-06.12-evidence/macos-legibility-audit.md`. Same discipline.

**Behavior captures:**

- iOS swipe-revealed screenshots: 2 captures (`voyager-todos-swipe-revealed-light.png`, `voyager-todos-swipe-revealed-dark.png`).
- iOS 14-row behavior contract: 28 captures (14 actions × 2 appearances). Even if XCUITest extension is required, this is the closing functional evidence.

**Owner hand-test:**

- Owner taps through the 14-row contract on iPhone 17 Pro + clicks through the macOS Voyager bin equivalent. Confirms no remaining amber bleeds; confirms macOS window resize works; confirms dark mode propagates on macOS.

## Risk notes

- **Option C ripples across 4 renderer paths + Cascade demo.** The implementer must touch web/uikit/appkit renderers + design_tokens.cr + Cascade's brand wiring. The implementer-side Codex review must specifically check for missed paths.
- **Dark mode on macOS may have a different pinning mechanism than iOS** (no scene delegate; `NSApp.appearance` instead). The investigation step matters before the fix.
- **Cascade demo could silently regress.** If the implementer doesn't add explicit `.with_brand(CascadeBrand)` while shifting `Tokens.default`, Cascade renders in system blue instead of deep teal. This is a regression to detect before merge.
- **28-row behavior screenshots are the biggest evidence ask in any phase to date.** [[mid-stop-pattern-evidence-capture]] applies — split this into a separate capture agent dispatch after the code work lands.

## Briefing documents

- Implementer brief: `brief.md` (will be architect-Codex critiqued before dispatch)
- Universal rubrics: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`
- Reflection on close: `../../handoff/phase-06.12-reflection-{date}.md` (TBD)
