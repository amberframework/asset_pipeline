# Phase 6.12A — Implementation Brief (revision 2, post-Codex critique)

**Date opened:** 2026-05-24
**Authored by:** Architect; revised after Codex returned REVISE on revision 1 with 5 findings (scope too large, hidden dependencies, C1 underspecified, acceptance not objectively verifiable, missing audit + Cascade preflight + Android resolution)
**Branch:** `phase-06.12-library-identity-macos-polish` (cut from feature branch at `45d2d58`)
**Codex protocol:** Per-iteration Codex review on every code-touching iteration. No self-assessment.

**Note on phase split:** Phase 6.12 splits into:
- **6.12A (THIS brief):** library-identity pivot + renderer integration + macOS sizing + Cascade preservation. Code-only. Closes when the implementer report verifies acceptance.
- **6.12B (separate brief, authored AFTER 6.12A merges):** 44-artifact evidence capture + 2 audit markdown files + owner hand-test gate. Dispatched as a capture+audit agent only (no code).

---

## Codex-revision-1 findings applied

1. Scope split into 6.12A code + 6.12B captures.
2. Cascade preservation moved BEFORE the pivot (Item 1).
3. `brand_primary` alone expanded to the brand-color family (primary/hover/active + generator outputs).
4. C1 sentinel API specified concretely (constructor, predicate, serialization, generator behavior, renderer mapping).
5. Objective acceptance — every claim now has a measurable artifact path or scripted probe.
6. Added a no-amber audit step over all generated outputs (CSS / Swift / Android).
7. Android deferral language resolved.

---

## Environment assumptions

1. iPhone 17 Pro simulator exists.
2. Branch HEAD `45d2d58` exists locally.
3. `crystal spec` baseline is 1497/4/0 at `45d2d58`. Preserve through every commit.
4. The diagnostic NSLog grep-token pattern (`voyager-(save-chain|interaction-proof)`) is documented in Phase 6.10 Rem 2 codex-blocker. Re-use as needed; final commit must have 0 hits.
5. `codex` CLI at `/opt/homebrew/bin/codex` for per-iteration review.
6. iOS appearance pinning: SceneDelegate reads `VOYAGER_APPEARANCE` env var. Use `SIMCTL_CHILD_VOYAGER_APPEARANCE=light/dark` if hand-testing pre-handoff.

---

## Item 0 (preflight) — Cascade audit BEFORE the pivot

Codex flagged: pivoting `Tokens.default` without first auditing Cascade's brand entrypoint could silently break Cascade. Item 0 happens first.

**Action:** Identify how Cascade applies its deep-teal brand. Grep for `CascadeBrand`, `with_brand`, brand application calls in:
- `samples/initiative-cross-platform-ui-demo/cascade/` (or `samples/initiative-cross-platform-ui-demo/`)
- The Cascade-specific Crystal entrypoints (web build, macOS host, iOS bridge).

Document at `handoff/phase-06.12a-cascade-preflight.md`:
- Exact file(s) + line(s) where Cascade's brand is set.
- Whether Cascade currently calls `Tokens.default.with_brand(CascadeBrand.new)` explicitly, OR implicitly relies on the library default having amber and overrides specific colors.
- For (b), the explicit `.with_brand(...)` call must be ADDED in Item 4 below as part of the pivot.

**Acceptance — Item 0:**

- Preflight doc committed.
- Cascade brand entrypoint identified by file:line.
- If implicit-default reliance is found, Item 4 below must add the explicit call.

### Item 1 — `SYSTEM_ACCENT` sentinel (Path C1, fully specified)

**Goal:** `Tokens.default.brand_primary` returns a sentinel color value that each renderer detects + maps to its platform's native accent path.

**Sentinel API (concrete spec):**

In `src/ui/design_tokens.cr` (or a sibling sentinel file):

```crystal
module UI::DesignTokens
  class Color
    # SYSTEM_ACCENT is a sentinel Color value meaning "this color
    # should resolve to the platform's native accent color at render
    # time" — UIColor.systemBlue on iOS, NSColor.controlAccentColor
    # on macOS, accent-color: auto / -apple-system-blue on web,
    # ?attr/colorPrimary on Android.
    SYSTEM_ACCENT = new(
      oklch: nil,           # no OKLCH source
      r: 0.0, g: 0.0, b: 0.0, alpha: 0.0,  # sentinel RGB (predicate-checked, not rendered)
      sentinel: :system_accent,
    )

    # Predicate so renderers can detect the sentinel without exposing
    # the @sentinel ivar to consumers.
    def system_accent? : Bool
      @sentinel == :system_accent
    end

    # Serialization behavior. For non-sentinel Colors, return CSS / Swift
    # / Android representation as today. For SYSTEM_ACCENT, return the
    # platform's accent token.
    #
    # Note (CSS): `AccentColor` (capitalized, no hyphen) is the CSS Color
    # Module Level 4 system color KEYWORD that resolves to the OS's
    # active accent color. This is distinct from `accent-color` (the
    # CSS PROPERTY that styles form controls). `to_css` returns the
    # KEYWORD so it can be used as a value in any color context.
    def to_css : String
      return "AccentColor" if system_accent?  # CSS Color Level 4 system keyword
      # ... existing rgb/oklch serialization unchanged
    end

    def to_swift : String
      return "Color.accentColor" if system_accent?  # SwiftUI environment accent
      # ... existing serialization unchanged
    end

    def to_android_argb : Int32
      # Sentinel — Android renderer must check `system_accent?` predicate
      # and emit a `?attr/colorPrimary` resource reference instead. The
      # Android XML/ARGB generator raises `AndroidRendererNotImplemented`
      # rather than producing a numeric ARGB (no honest fallback exists).
      raise AndroidRendererNotImplemented.new(
        "Cannot serialize Color::SYSTEM_ACCENT as Android ARGB. " \
        "Use ?attr/colorPrimary resource reference instead."
      ) if system_accent?
      # ... existing serialization unchanged
    end

    # Equality + debug output
    def ==(other : Color) : Bool
      return false unless other.is_a?(Color)
      @sentinel == other.@sentinel && (super)
    end

    def to_s(io : IO) : Nil
      if system_accent?
        io << "Color::SYSTEM_ACCENT"
      else
        # ... existing serialization
      end
    end
  end
end
```

**Tokens.default change (concrete):**

In `Tokens.default`, the `brand_primary`, `brand_primary_hover`, `brand_primary_active` family ALL return `Color::SYSTEM_ACCENT`:

```crystal
def self.default : Tokens
  palette_light = ColorPalette.new(
    brand_primary: Color::SYSTEM_ACCENT,
    brand_primary_hover: Color::SYSTEM_ACCENT,
    brand_primary_active: Color::SYSTEM_ACCENT,
    # ... non-brand colors unchanged
  )
  # ... same for palette_dark
end
```

**Spec to ship (concrete):**

`spec/ui/design_tokens_default_accent_spec.cr`:

```crystal
describe UI::DesignTokens::Tokens do
  describe ".default" do
    it "uses Color::SYSTEM_ACCENT for the brand_primary family" do
      t = UI::DesignTokens::Tokens.default
      t.colors_light.brand_primary.system_accent?.should be_true
      t.colors_light.brand_primary_hover.system_accent?.should be_true
      t.colors_light.brand_primary_active.system_accent?.should be_true
      t.colors_dark.brand_primary.system_accent?.should be_true
    end

    it "preserves opinionated brand when .with_brand is applied" do
      brand = UI::DesignTokens::Brand.new(
        primary: UI::DesignTokens::Color.hex("#0F8585")  # cascade-teal
      )
      t = UI::DesignTokens::Tokens.default.with_brand(brand)
      t.colors_light.brand_primary.system_accent?.should be_false
      t.colors_light.brand_primary.to_swift.should eq("Color(red: 0.059, green: 0.522, blue: 0.522)")
    end
  end
end
```

**Acceptance — Item 1:**

- `UI::DesignTokens::Color::SYSTEM_ACCENT` exists with full API (constructor, `system_accent?`, `to_css`, `to_swift`, `to_android_argb`, `==`, `to_s`).
- `Tokens.default.colors_light.brand_primary` AND `.brand_primary_hover` AND `.brand_primary_active` ALL return the sentinel.
- Same for `colors_dark`.
- `spec/ui/design_tokens_default_accent_spec.cr` passes.
- `crystal spec` baseline preserved (1497/4/0 + at least 2 new examples passing).
- **Generated output contract** (the regenerator MUST emit the following):
  - **Web CSS** (`src/ui/design_tokens/dist/web_tokens.css`): `--ap-color-brand-primary: AccentColor;` for `Tokens.default`. The hover + active variants emit the same `AccentColor` keyword (the browser resolves hover/active states from the accent automatically). When `Tokens.default.with_brand(...)` is applied with a non-sentinel brand, the values revert to the explicit hex/rgb as today.
  - **Apple Swift** (`src/ui/design_tokens/dist/AssetPipelineTokens.swift`): emit `static let brandPrimary: Color = Color.accentColor` for the sentinel. Non-sentinel brand emits `Color(red: …, green: …, blue: …)` as today.
  - **Android XML** generator: raises `UI::DesignTokens::AndroidRendererNotImplemented` (with a clear message) when hit by `Color::SYSTEM_ACCENT`. The regenerator must NOT exit 0 silently with a broken Android output — but it MUST handle the failure gracefully (continue generating other targets, report which targets failed at exit). Implementer ships a fallback: skip the Android target when SYSTEM_ACCENT is in play, log a diagnostic.
- `crystal run scripts/regenerate_design_tokens.cr` exits 0 for the iOS + macOS + web targets. Android target is documented as deferred per Phase 1 precedent + the regenerator's diagnostic.

### Item 2 — Renderer integration (4 paths)

**iOS (`src/ui/renderers/uikit_renderer.cr` around line 4109-4112):**

```crystal
brand = @design_tokens.colors_light.brand_primary
if brand.system_accent?
  LibSwiftKitBridge.apsk_runtime_clear_brand_tint
else
  LibSwiftKitBridge.apsk_runtime_set_brand_tint(brand.r, brand.g, brand.b, brand.alpha)
end
```

**macOS (`src/ui/renderers/appkit_renderer.cr` analog around line 4014):**

Mirror the iOS change. The Swift-side `APSKRuntime.clearBrandTint` is platform-shared so the same fun call works.

**Web (`src/ui/renderers/web_renderer.cr` CSS variable emission):**

In `inject_theme_css`, when emitting `--ap-color-brand-primary`:

```crystal
brand = tokens.colors_light.brand_primary
css_value = brand.system_accent? ? "AccentColor" : brand.to_css
io << "  --ap-color-brand-primary: #{css_value};\n"
```

(`AccentColor` is the CSS 4 system color that resolves to the OS's user-selected accent. Falls back gracefully in older browsers via the `accent-color: auto` property in the consumer CSS.)

**Android (`src/ui/renderers/android_renderer.cr` resolution):**

Codex flagged the original contradictory language. Resolution:

```crystal
if brand.system_accent?
  # Android: emit `?attr/colorPrimary` resource reference. The platform's
  # Material theme provides the accent. No further wiring needed for the
  # demo apps in this initiative (Voyager + Cascade do not ship Android
  # builds yet; Phase 1's cross-build precedent holds).
  raise UI::DesignTokens::AndroidRendererNotImplemented.new(
    "Android renderer does not yet support Color::SYSTEM_ACCENT. " \
    "Pass an explicit brand color via Tokens.default.with_brand(...)."
  ) if android_target_in_use?
end
```

**Spec to ship:**

`spec/ui/renderers/system_accent_integration_spec.cr` with focused unit tests:
- iOS renderer: when tokens use SYSTEM_ACCENT, `clear_brand_tint` is called (mock the `LibSwiftKitBridge` fun via a test seam — see `Implementation note` below).
- iOS renderer: when tokens use a custom brand, `set_brand_tint(r, g, b, a)` is called with that brand's values.
- macOS renderer: same two assertions.
- Web renderer: when tokens use SYSTEM_ACCENT, emitted CSS contains `--ap-color-brand-primary: AccentColor;`. When tokens use a custom brand, emitted CSS contains the actual hex / rgb value.

**Implementation note (test seam):** the `LibSwiftKitBridge` funs are top-level `@[Link]` C bindings. To mock them in spec, introduce an injection point — likely a class-level `@@bridge` ivar on the renderer that defaults to the real `LibSwiftKitBridge` but can be swapped to a test double. Implementer picks the exact pattern; Codex iteration review confirms.

**Acceptance — Item 2:**

- All 4 renderer paths landed per the specs above.
- `spec/ui/renderers/system_accent_integration_spec.cr` passes.
- `make -C samples/initiative-cross-platform-ui-voyager ios` exits 0.
- `make -C samples/initiative-cross-platform-ui-voyager macos` exits 0.
- `crystal run samples/initiative-cross-platform-ui-voyager/web/static_site.cr` exits 0.
- `crystal spec` baseline preserved (1497/4/0 + new examples).

### Item 3 — macOS Voyager NSWindow sizing + dark mode

**Goal:** `samples/.../voyager/macos/host.cr`:
- Default content size 880 × 640.
- `styleMask` includes `.resizable` (both axes).
- `contentMinSize` enforced (480, 400).
- Dark mode honored.

**Investigation step (Implementer reports findings first):**

Read current `macos/host.cr`. Identify:
- Current `setContentSize` value.
- Current `styleMask` flags.
- Whether `contentMinSize` is currently set.
- Whether appearance is pinned (env var analog to iOS) or system-follows.

Document at `handoff/phase-06.12a-macos-host-investigation.md`.

**Implementation:**

Apply the four changes per the investigation findings.

**Acceptance — Item 3 — objective probes:**

- `osascript -e 'tell application "voyager" to get bounds of window 1'` returns dimensions matching 880×640 (or whatever the default content size becomes; both width and height set).
- Calling `osascript -e 'tell application "voyager" to set bounds of window 1 to {0, 0, 1280, 800}'` succeeds AND a follow-up `get bounds` shows the resize was honored.
- Calling `osascript -e 'tell application "voyager" to set bounds of window 1 to {0, 0, 200, 200}'` FAILS or the window snaps to its min size (assertion: bounds reported are >= 480×400).
- Capture 3 screenshots at content sizes 480×400, 880×640, 1280×800 — save to `handoff/phase-06.12a-evidence/macos-resize-{narrow,default,wide}.png`. Visual confirmation of fluid reflow.
- Dark mode capture proves the NSWindow follows system or env-var per investigation finding.

### Item 4 — Cascade demo brand preservation (post Item 0 preflight)

**Goal:** Cascade continues to render deep teal after Tokens.default no longer has amber.

**Action depends on Item 0's preflight finding:**

- If Cascade already calls `Tokens.default.with_brand(CascadeBrand.new)` explicitly: Item 4 is a verification step (run Cascade builds, assert teal preserved).
- If Cascade implicitly relies on the library default: ADD the explicit `.with_brand(CascadeBrand.new)` call in the Cascade entrypoint identified by Item 0.

**Acceptance — Item 4 — objective probes:**

- Cascade web build (`crystal run ...cascade...`) emits CSS that contains the deep-teal hex value (or an OKLCH equivalent). Grep the generated `.html` for `#0F8585` or whatever Cascade's brand hex is. 0 hits = regression.
- Cascade macOS bin renders with deep teal prominent buttons. Capture at `handoff/phase-06.12a-evidence/cascade-macos-prominent-button.png` + pixel-sample the button background to assert teal (e.g. `(15, 133, 133)` ± 5 each channel via WCAG sampler script).
- Cascade iOS build (if available) — same pixel sample on the prominent button capture.
- No new spec failures in the Cascade-adjacent specs.

### Item 5 — No-amber audit across all generated outputs

Codex flagged that `brand_primary` alone is too narrow; the brand family + generated outputs could still leak amber.

**Audit step:**

Run the design-token regenerator + grep all outputs:

```bash
crystal run scripts/regenerate_design_tokens.cr

# Look for amber-ish color literals in generated outputs
grep -E "amber|orange|tan|peach" src/ui/design_tokens/dist/
grep -E "amber|orange|tan|peach" output/voyager-demo/

# Look for amber RGB values (the library's specific amber)
grep -rE "rgb\([23][0-9]{2},.*[0-9]{2},.*[0-9]{1,2}\)" src/ui/design_tokens/dist/ output/voyager-demo/
```

If amber-equivalents are found in generated outputs from a `Tokens.default`-only build, they're library defaults that didn't get pivoted. Identify the source token + decide:
- Should it ALSO become a sentinel?
- Or is it legitimately a non-brand library color (e.g. a warning-tone tan that's fine)?

Document in `handoff/phase-06.12a-no-amber-audit.md`.

**Acceptance — Item 5:**

- Audit doc committed.
- For each amber-equivalent finding, either (a) the source token is pivoted to sentinel + the doc explains why, or (b) the doc justifies keeping it as a non-brand color.

---

## Codex protocol — Implementer side

Every code-touching iteration gets a real Codex review at `handoff/phase-06.12a-codex-N.md`. Self-assessment NOT acceptable.

Iteration boundaries should match brief items 0-5 (not strict; Implementer can split or combine reasonably). Codex review per logical chunk.

If Codex times out twice: STOP, write `handoff/phase-06.12a-codex-blocker.md`, escalate.

---

## Build + verification commands

```bash
crystal spec

# Voyager iOS
make -C samples/initiative-cross-platform-ui-voyager ios IOS_DEST='platform=iOS Simulator,name=iPhone 17 Pro'

# Voyager macOS
make -C samples/initiative-cross-platform-ui-voyager macos
samples/initiative-cross-platform-ui-voyager/macos/bin/voyager voyager-todos

# Voyager web
crystal run samples/initiative-cross-platform-ui-voyager/web/static_site.cr

# Cascade builds (regression check)
# (paths depend on Item 0 preflight findings)

# Design-token regenerator (Item 5 audit input)
crystal run scripts/regenerate_design_tokens.cr

# WCAG / pixel sample
python3 /tmp/wcag_sample.py path/to/screenshot.png <fg_x> <fg_y> <bg_x> <bg_y>

# macOS osascript window probe (Item 3 acceptance)
osascript -e 'tell application "voyager" to get bounds of window 1'
```

---

## Acceptance you must meet before reporting done

- `crystal spec` baseline 1497/4/0 preserved (or improved).
- Cascade preflight doc + Cascade pixel-sample teal preserved.
- `Color::SYSTEM_ACCENT` API + spec ships.
- All 4 renderer paths integrated + spec passes.
- Voyager iOS Cancel button renders system blue (will be verified in 6.12B captures; for 6.12A, the absence of amber in the renderer's emitted CSS and the iOS renderer's clear_brand_tint call is the proof).
- macOS Voyager bin: 880×640 default, both-axes resizable, 480×400 floor — verified by osascript probes + 3 resize screenshots.
- No-amber audit committed.
- All code-touching iterations have Codex reviews.
- `grep -rE "voyager-(save-chain|interaction-proof)"` returns 0.

## Reporting

Implementer writes `handoff/phase-06.12a-implementer-report.md` covering per-item status (0-5), commit SHAs, Codex verdicts, regression numbers, all evidence paths.

Return to architect with: branch HEAD SHA, commit count + SHAs, Codex verdicts, evidence paths. Do NOT declare phase passed. Architect dispatches 6.12B (captures) after 6.12A merges. Final phase close after owner hand-test gate at 6.12B end.

## Hard rules

- Forward commits only.
- No scope expansion. The 44 evidence captures + 2 audit markdown + 14-row behavior contract are EXPLICITLY 6.12B scope, NOT 6.12A.
- Standard Claude co-author footer.
- If Path C1's sentinel approach is unworkable mid-implementation, STOP and escalate — do not pivot to C2 without architect approval.
- If Cascade preflight reveals an unanticipated brand-application path, STOP and report before continuing the pivot.
- Path B (raw UIButton bypass) still forbidden.

Iteration 1 starting move recommendation: ship Item 0 preflight FIRST (read-only Cascade audit) before touching `design_tokens.cr`. The findings shape Item 4.
