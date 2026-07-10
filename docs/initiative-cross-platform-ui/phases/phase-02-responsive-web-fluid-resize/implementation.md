
# Phase 2 — Implementer Briefing: Responsive Web Fluid Resize

**Audience:** the implementer agent spawned for Phase 2.
**Read first:** `README.md` (this folder), then `../../rubric/implementation_criteria.md`, then this file.
**Branch:** `phase-02-responsive-web-fluid-resize` (already created by the Architect from the latest `feature/utility-first-css-asset-pipeline`; do not branch further).
**Validator contract:** `validation.md` (same folder). Do not read it cover-to-cover before starting; skim it once to know what evidence the validator will demand, then implement against this briefing.

---

## 1. Goal

Replace the web renderer's fixed pixel constraints with `clamp()` / `min()` / `max()` so the existing web design system demo reflows fluidly from desktop (1280 px) to mobile-min (320 px). Implement the container query generator that is currently a config stub. Add a `fluid(min:, ideal:, max:)` primitive to `UI::View`. Guarantee a 44×44 touch target minimum for every interactive widget at every viewport. Emit the viewport meta tag in every generated HTML page (so renderer callers do not have to hand-roll it). Migrate `examples/web_design_system_demo.cr` and the seven `output/web-design-system-*.html` pages to the new approach.

When done, dragging a browser window from 1280 → 320 px on the migrated demo produces:

- No horizontal overflow.
- No interactive widget shrinking below 44 × 44 CSS px.
- Visually continuous reflow (no large layout jumps except at intentional breakpoints).
- Card / form / split-view layouts adapt to **their container width**, not just the viewport.

---

## 2. Pre-reading checklist

Before writing any code:

- [ ] `README.md` (this folder) — scope and acceptance summary.
- [ ] `../../rubric/implementation_criteria.md` — universal standards.
- [ ] `../phase-01-design-token-foundation/README.md` — Phase 1 ships `UI::DesignTokens` with spacing, breakpoints, and touch-target tokens. You consume them; you do not redefine them.
- [ ] `src/ui/view.cr` — the `UI::View` base class. Look at `minimum_width`, `maximum_width`, `minimum_height`, `maximum_height` (lines 132–136). You are adding `fluid_width` / `fluid_height` alongside, not replacing.
- [ ] `src/ui/renderers/web_renderer.cr` — the file you are editing. Specifically:
  - Lines 2119–2131 — the `apply_common_styles` size constraint block. This is the central choke point.
  - Lines 638, 1202, 1434, 1460, 1786, 1810, 2120–2131 — every `min-width`/`max-width` literal.
  - Search for `\d+px` to enumerate every hard-coded pixel value.
- [ ] `src/components/css/config/css_config.cr` lines 47–48, 67, 347–356 — the `containers` config (stub).
- [ ] `src/components/css/engine/css_generator.cr` lines 114–119, 236–249 — container query plumbing **already exists** for utility class names with `@`-prefix modifiers (e.g. `@md:flex`). What is missing is the `container-type: inline-size` emission on the container element and a structured way for the renderer (not just utility classes) to request container queries.
- [ ] `src/components/css/engine/css_rule.cr` lines 11–65 — `with_container` API.
- [ ] `examples/web_design_system_demo.cr` lines 1–200 and around 1267 — the demo's CSS scaffolding and the `<head>` block. Viewport meta is already emitted by the demo itself; the renderer does not own it. Phase 2 moves viewport-meta responsibility into the renderer's document-mode helper so any caller (not just this demo) gets it for free.
- [ ] `output/web-design-system-demo.html` — actual current output. Inspect the existing dialog, card, and split-view markup so you know what the migration target looks like.
- [ ] `scripts/validate_web_demo.cr` (via `scripts/validate_amber_demo.cr`) — the static audit the validator runs.
- [ ] `scripts/capture_web_demo_screenshots.cr` — screenshot harness driving headless Chrome.
- [ ] `spec/ui/renderers/web_renderer_spec.cr` — existing spec patterns; mirror them.
- [ ] `spec/components/css/css_phase2_wcag_spec.cr` — existing WCAG spec; add to this file or a sibling for touch-target checks.

If `tokens.touch_target_minimum_px` (a `Float64` getter on the `Tokens` aggregate, default `44.0`) or `tokens.breakpoints` do not exist when you start Phase 2, **stop and return early** to the team lead. Phase 1 is a hard dependency; do not freelance the tokens.

---

## 2a. Existing infrastructure to use (vs. rebuild)

Phase 2 is largely a renderer migration: replace hard-coded pixel constraints with `clamp()`, wire container queries, enforce touch-target minimums. Most of what you need is already in the repo; the new artifacts are the `UI::Fluid` type, the container-query emission path, and the document-mode helper.

### Crystal source you extend (do not replace)

- `src/ui/view.cr` (lines 132–136) — existing `minimum_width`/`maximum_width`/`minimum_height`/`maximum_height` properties. Add `fluid_width`/`fluid_height` alongside; **do not remove** the existing properties (preserves callers).
- `src/ui/renderers/web_renderer.cr` — the file under migration. Specific known hard-coded pixel constraints at lines 638, 1202, 1434, 1460, 1786, 1810, and the central `apply_common_styles` block (lines 2119–2131). Search the full file for `\d+px` to enumerate the rest.
- `src/components/css/config/css_config.cr` (lines 47–48, 67, 347–356) — `containers` config stub. Phase 2 wires this stub up to real emission.
- `src/components/css/engine/css_generator.cr` (lines 114–119, 236–249) — utility-class container query plumbing already exists. Extend it to emit `container-type: inline-size` from renderer visit methods, not just from utility class names.
- `src/components/css/engine/css_rule.cr` (lines 11–65) — existing `with_container` API. Use it; do not write a parallel one.
- `examples/web_design_system_demo.cr` — the demo source. Phase 2 migrates the demo to the new clamp/container-query approach. The `<head>` block currently emits viewport meta from the demo; after Phase 2 the renderer's document-mode helper owns this responsibility.
- `output/web-design-system-*.html` — the seven generated pages the validator audits.
- `scripts/validate_web_demo.cr` — existing static auditor. Phase 2's output must keep it green.
- `scripts/capture_web_demo_screenshots.cr` — existing screenshot harness driving headless Chrome directly via CDP over WebSocket (see `../../rubric/behavior-simulation-toolkit.md` §3 and the canonical `scripts/capture_amber_demo_screenshots.cr` it re-exports). Validator reuses this; do not write a parallel one.
- `scripts/axe_web_demo_audit.cr` / `scripts/ibm_web_demo_audit.cr` — existing accessibility audit runners. Validator runs them; implementer ensures the output passes.
- `spec/ui/renderers/web_renderer_spec.cr` — existing renderer spec patterns.
- `spec/components/css/css_phase2_wcag_spec.cr` — existing WCAG spec. Touch-target specs append here.

### Crystal source you create

- `src/ui/fluid.cr` — the new `UI::Fluid` record.
- `spec/ui/fluid_spec.cr` — basic value-type spec.
- `spec/ui/renderers/document_mode_spec.cr` — spec for `UI::Web::Renderer#render_document`.

### Pinned versions and conventions

| Tool / convention | Value | Notes |
|---|---|---|
| Crystal compiler | `crystal-alpha` | Standard. |
| Headless browser | Chrome driven via CDP over WebSocket from Crystal (extend `scripts/capture_amber_demo_screenshots.cr`; see `../../rubric/behavior-simulation-toolkit.md` §3) | Validator reuses; do not introduce Puppeteer/Playwright/npm tooling. |
| Viewport set | 1280×800, 768×1024, 375×667, 320×568 | Standard across the initiative. |
| Color schemes | light, dark | Captured for every viewport in the validator pass. |
| Touch target minimum | `tokens.touch_target_minimum_px` (Float64, default 44.0) | Enforced at the renderer level; emitted as `min-block-size: 44px` / `min-inline-size: 44px` on every interactive widget. |
| CSS variable prefix | `--ap-*` | Inherited from Phase 1. |
| Container query syntax | CSS Container Queries Level 1 | `@container <name>? (min-width: ...)` with `container-type: inline-size` on the container. |

### Conventions enforced project-wide

- **Container element must declare `container-type: inline-size`** (or `size`) AND a `container-name` to be queryable. Validator check #20 (`fluid.container-type-emitted`) verifies this.
- **`@container` blocks** are emitted by `css_rule.cr`'s `with_container` API. Do not hand-roll `@container` strings.
- **Generated CSS must NOT contain literal pixel min/max-width** outside `clamp(...)` expressions or character-width inputs. Validator check #17 enforces.
- **Every generated HTML page must contain a `<meta name="viewport" content="width=device-width, initial-scale=1">`**. After Phase 2 this is emitted by `UI::Web::Renderer#render_document(view, title:)`. Renderer callers must not hand-roll the meta tag.

### What is genuinely new vs. extended

| New | Extended |
|---|---|
| `src/ui/fluid.cr` | `src/ui/view.cr` (new properties alongside existing) |
| `spec/ui/fluid_spec.cr` | `src/ui/renderers/web_renderer.cr` (hard-coded → clamp migration) |
| `spec/ui/renderers/document_mode_spec.cr` | `src/components/css/engine/css_generator.cr` (wire container-type emission) |
| `UI::Web::Renderer#render_document` method | `examples/web_design_system_demo.cr` (migrate to new approach) |
| (none) | `spec/components/css/css_phase2_wcag_spec.cr` (touch-target specs appended) |

---

## 3. Step-by-step implementation plan

Commit boundaries are marked `▸ Commit N`. Treat each as a reviewable unit.

### Step 1. Add the `Fluid` value type and `fluid_*` properties on `UI::View`

**Change:** Introduce `UI::Fluid` (a `record`) and add `fluid_width : Fluid?` / `fluid_height : Fluid?` properties on `UI::View`. Coexist with the existing `minimum_width` / `maximum_width` properties; do not remove them.

**Files touched:**
- `src/ui/fluid.cr` (new) — `UI::Fluid` record.
- `src/ui/view.cr` — add two properties next to lines 132–136.
- `src/ui.cr` (or whatever requires `view.cr`) — require the new file.
- `spec/ui/fluid_spec.cr` (new).

**Rationale:** `Fluid` is the data carrier. The renderer reads it; the View API surfaces it. Keeping it as its own type makes the value testable independent of any renderer.

**Good output:**

```crystal
# src/ui/fluid.cr
module UI
  # Responsive sizing value. Translates to `clamp(min, ideal, max)` on web,
  # and to the platform's idiomatic size class behavior on Apple/Android
  # (handled by later phases).
  record Fluid,
    min : String,
    ideal : String,
    max : String do
    # Construct from numeric pixel values. Pixels are emitted as `Npx`.
    def self.px(min : Number, ideal : Number, max : Number) : Fluid
      new(min: "#{min}px", ideal: "#{ideal}px", max: "#{max}px")
    end

    # Construct from a fluid `vw` ideal with px floor/ceiling.
    def self.vw(min_px : Number, ideal_vw : Number, max_px : Number) : Fluid
      new(min: "#{min_px}px", ideal: "#{ideal_vw}vw", max: "#{max_px}px")
    end

    # Render as a CSS `clamp()` expression.
    def to_css : String
      "clamp(#{min}, #{ideal}, #{max})"
    end
  end
end
```

### Step 2. Author the `fluid(...)` builder API on `UI::View`

**Change:** Add chainable builders so authors do not construct `UI::Fluid` literals.

**Files touched:**
- `src/ui/view.cr` — add `def fluid_width(min, ideal, max)` and `def fluid_height(min, ideal, max)` returning `self`.

**Rationale:** Matches existing View modifiers (`background`, `corner_radius`, etc.) that are chainable.

**Good output:**

```crystal
# Set a fluid horizontal size. Accepts CSS-compatible strings or numeric px.
def fluid_width(min : String | Number, ideal : String | Number, max : String | Number) : self
  @fluid_width = UI::Fluid.new(
    min: coerce_size(min),
    ideal: coerce_size(ideal),
    max: coerce_size(max),
  )
  self
end

private def coerce_size(value : String | Number) : String
  case value
  when Number then "#{value}px"
  else value.to_s
  end
end
```

### Step 3. Wire `fluid_*` into `apply_common_styles` in the web renderer

**Change:** In `web_renderer.cr` near lines 2119–2131, prefer `fluid_width` over `minimum_width`/`maximum_width` when both are set; emit `min-width: clamp(...)` / `max-width: clamp(...)`. The existing fixed-pixel constraints continue to work; `fluid_*` takes precedence.

**Files touched:**
- `src/ui/renderers/web_renderer.cr` — extend the size constraint block.
- `spec/ui/renderers/web_renderer_spec.cr` — add specs for fluid emission and precedence.

**Rationale:** A choke-point change. Every widget that uses the standard sizing path benefits. Widgets that hand-roll inline styles (Dialog, ActionPalette, etc.) are migrated in step 8.

**Good output (illustrative):**

```crystal
if fw = view.fluid_width
  el.add_style("width: #{fw.to_css}")
elsif min_w = view.minimum_width
  el.add_style("min-width: #{min_w}px")
end
if fw_max = view.fluid_width
  # width set above; no separate max-width emit
elsif max_w = view.maximum_width
  el.add_style("max-width: #{max_w}px")
end
```

The "good emission" smoke spec:

```crystal
it "emits clamp() for fluid_width" do
  v = UI::Box.new.fluid_width(min: 200, ideal: "60vw", max: 600)
  html = UI::Web::Renderer.new.render(v)
  html.should contain("width: clamp(200px, 60vw, 600px)")
end
```

▸ **Commit 1:** `[Phase 2] Add UI::Fluid type and fluid_width/fluid_height on View`

### Step 4. Sizing utility helpers in the web renderer

**Change:** Add private helpers `size_clamp(min_px, ideal_vw, max_px)` and `size_min(*sizes)` / `size_max(*sizes)` in `web_renderer.cr`. These are used internally by widget visit methods that need to switch from a literal pixel value to a fluid one without piping through the `Fluid` record.

**Files touched:**
- `src/ui/renderers/web_renderer.cr` — private methods, near the bottom of the class with the other helpers.

**Rationale:** The migration of inline styles (step 8) goes from `"padding: 24px"` to `"padding: clamp(16px, 4vw, 24px)"`. Helpers keep the call sites readable.

**Good output:**

```crystal
private def fluid_px(min : Number, ideal : Number, max : Number) : String
  "clamp(#{min}px, #{ideal}vw, #{max}px)"
end

private def fluid_with_floor(floor : Number, ideal : String, ceiling : Number) : String
  "clamp(#{floor}px, #{ideal}, #{ceiling}px)"
end
```

▸ **Commit 2:** `[Phase 2] Add fluid sizing helpers on web renderer`

### Step 5. Implement the container query generator

**Change:** The `Components::CSS::Config#containers` hash already feeds `@`-prefixed utility modifiers through `css_generator.cr` line 114–119. What's missing:

1. A `container-type: inline-size` declaration emitted on container parents. Today, `css_parser.cr` line 299 maps `container` utility to `container-type: inline-size`, but nothing emits a *containment context* on the rendered widget tree.
2. A renderer-level API to mark a view as a container query root so the web renderer emits `container-type: inline-size; container-name: <name>` on it.
3. Container query CSS blocks for at least three components (Card, Form, SplitView counterpart on web — `NavigationSplitView`).

**Files touched:**
- `src/ui/view.cr` — add `property container_query_name : String? = nil`.
- `src/ui/view.cr` — add a `container_query(name : String) : self` modifier method.
- `src/ui/renderers/web_renderer.cr` — in `apply_common_styles`, when `container_query_name` is set, emit `container-type: inline-size; container-name: <name>`.
- `src/components/css/engine/css_generator.cr` — confirm `@<name>` modifiers in utility classes resolve correctly when the name does not match a default breakpoint (treat as a raw container query: `@container <name> (min-width: ...)`).
- `src/components/css/component_css_registry.cr` (or the CSS source that ships Card/Form/SplitView component CSS) — add three `@container` blocks.

**Rationale:** Container queries were stubbed; this step makes them real. The plan honors the existing `@<bp>` syntax for utility classes and adds the missing wiring on the renderer side.

**Good output (CSS):**

```css
/* component CSS shipped with Card */
.am-card {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 480px) {
  .am-card__layout { flex-direction: row; gap: var(--ap-space-4); }
  .am-card__media { flex: 0 0 40%; }
}

@container card (min-width: 720px) {
  .am-card__layout { gap: var(--ap-space-6); }
}
```

**Good output (Crystal renderer):**

```crystal
if name = view.container_query_name
  el.add_style("container-type: inline-size")
  el.add_style("container-name: #{name}")
end
```

**Good output (spec):**

```crystal
it "emits container-type and container-name when set" do
  card = UI::Card.new.container_query("card")
  html = UI::Web::Renderer.new.render(card)
  html.should contain("container-type: inline-size")
  html.should contain("container-name: card")
end
```

▸ **Commit 3:** `[Phase 2] Implement container query generator and wire Card/Form/SplitView`

### Step 6. Document-mode helper: emit `<head>` with viewport meta

**Change:** Today, `web_renderer.cr` emits a fragment (root element only). Callers (e.g., `examples/web_design_system_demo.cr` line 1267) hand-roll the `<head>`. Add `UI::Web::Renderer#render_document(view : View, title : String) : String` that wraps the rendered root in a full HTML5 document including:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title}</title>
  {inject_theme_css}
</head>
<body>
  {root}
</body>
</html>
```

**Files touched:**
- `src/ui/renderers/web_renderer.cr` — new method.
- `spec/ui/renderers/web_renderer_spec.cr` — assert viewport meta is in the document-mode output.

**Rationale:** Every page generated through the renderer is now guaranteed to be responsive-meta correct. The existing demo continues to work as a fragment caller and will be migrated in step 9.

▸ **Commit 4:** `[Phase 2] Add Renderer#render_document with viewport meta`

### Step 7. Touch-target enforcement (single audit pass on emit)

**Change:** Add a post-pass over `apply_common_styles` for interactive widgets. The list of "interactive" view types is enumerable: `Button`, `IconButton`, `MenuButton`, `Toggle`, `Checkbox`, `Slider` (thumb), `Stepper` (minus/plus), `SegmentedControl` segment, `TextField`, `SearchField`, `DatePicker`, `TimePicker`, `ColorPicker`, `Link` (when styled as a button).

Strategy: in each visit method that today emits `width: 32px; height: 32px` (e.g., Stepper minus/plus at lines 807/817), replace with the touch-target floor. Centralize as:

```crystal
private def enforce_touch_target(el : Components::Elements::HTMLElement)
  min = tokens.touch_target_minimum_px # = 44.0 (Float64 getter on Tokens aggregate from Phase 1)
  el.add_style("min-width: #{min}px")
  el.add_style("min-height: #{min}px")
end
```

Call `enforce_touch_target(el)` at the end of each interactive widget's visit method, *before* `push_element`/`push_container`. Order matters: the visit method's own `width:`/`height:` declarations remain, but `min-width`/`min-height` override on small viewports.

**Files touched:**
- `src/ui/renderers/web_renderer.cr` — every interactive widget visit method.
- `spec/ui/renderers/web_renderer_spec.cr` — one spec per interactive widget asserting `min-width: 44px; min-height: 44px` is in the emitted style.

**Rationale:** Per-widget enforcement is more reliable than a regex audit pass because the visit method knows which element is the interactive target (vs. a wrapper). The validator's check then becomes "every interactive widget's HTML has min-width:44px min-height:44px in its style chain."

**Why not a regex audit:** A regex sweep on emitted CSS can't tell `<div>` (decorative) from `<button>` (interactive). Per-widget enforcement is precise.

**Good output (spec):**

```crystal
it "enforces 44x44 touch target on Button" do
  html = UI::Web::Renderer.new.render(UI::Button.new("Save"))
  html.should match(/min-width:\s*44px/)
  html.should match(/min-height:\s*44px/)
end
```

▸ **Commit 5:** `[Phase 2] Enforce 44x44 touch target on all interactive widgets`

### Step 8. Migrate hand-rolled inline styles in `web_renderer.cr`

**Change:** Sweep the file for the surviving hard-coded sizing literals identified during pre-reading. For each, decide:

- **Fluid candidate** (scales with viewport): replace literal with `fluid_px(...)`.
- **Container-stable** (fixed regardless of viewport, e.g., divider thickness `1px`): leave alone.
- **Touch-target affected** (decided in step 7): replace.

Concrete decisions to encode:

| Location | Today | After |
|---|---|---|
| `web_renderer.cr:638` Dialog | `min-width: 270px; max-width: 400px; padding: 24px` | `min-width: clamp(260px, 80vw, 270px); max-width: clamp(280px, 90vw, 400px); padding: clamp(16px, 4vw, 24px)` |
| `web_renderer.cr:1202` AlertDialog | same as above | same |
| `web_renderer.cr:1434` MenuButton menu | `min-width: 150px` | `min-width: clamp(150px, 40vw, 240px)` |
| `web_renderer.cr:1460` ContextMenu | `min-width: 220px` | `min-width: clamp(200px, 50vw, 280px)` |
| `web_renderer.cr:1786` ShareSheet | `max-width: 400px; padding: 16px` | `max-width: clamp(280px, 92vw, 480px); padding: clamp(12px, 3vw, 16px)` |
| `web_renderer.cr:1810` ShareDestinationItem | `min-width: 60px` | `min-width: 60px` (no change — small chip, not interactive root) |
| `web_renderer.cr:812` Stepper value | `min-width: 40px` | `min-width: clamp(40px, 12vw, 56px)` |
| `web_renderer.cr:1031` Form label | `min-width: 100px` | `min-width: clamp(80px, 22vw, 120px)` |
| `web_renderer.cr:1063` Sidebar (SplitView) | `width: #{sidebar_width}px` | `width: clamp(220px, 30vw, #{sidebar_width}px)`; *also* hide-on-small via container query at the SplitView wrapper |

**Files touched:**
- `src/ui/renderers/web_renderer.cr` — all of the above lines.
- `spec/ui/renderers/web_renderer_spec.cr` — assert the new clamp expressions appear.

**Rationale:** This is the bulk of the visual-change work. Tested by screenshot diff in validation.

▸ **Commit 6:** `[Phase 2] Migrate dialog/menu/sidebar/stepper sizes to clamp()`

### Step 9. Migrate `examples/web_design_system_demo.cr`

**Change:** The demo bakes large amounts of CSS as Crystal heredocs. Replace fixed `max-width: 1220px` and similar literal values with token-driven `clamp()` expressions. Where the demo currently uses media queries to switch from a one-column to a two-column card layout, add a parallel container query so panels nested inside narrow regions adapt to *their* width, not the viewport.

**Concrete migrations:**

- `.am-demo-container { max-width: 1220px; padding: 1rem; }` → `max-width: clamp(20rem, 92vw, 1220px); padding: clamp(0.75rem, 2.5vw, 1.5rem)`.
- All `.am-card`, `.am-form-card`, `.am-dashboard-grid` rules: add `container-type: inline-size; container-name: <component>`.
- Any `min-width` / `max-width` literal in the heredoc CSS: audit; convert fluid ones to `clamp()`.

**Files touched:**
- `examples/web_design_system_demo.cr` — every Crystal heredoc with sizing CSS.
- `examples/generate_static_site.cr` — if it has analogous literals, same treatment.
- Re-run the demo to regenerate every `output/web-design-system-*.html`.

**Rationale:** The demo *is* the validator's primary surface. If it does not reflow correctly, Phase 2 is not done.

**Good output:** running `crystal run examples/web_design_system_demo.cr` overwrites the seven pages. `git diff --stat output/web-design-system-*.html` shows substantive but proportional changes.

▸ **Commit 7:** `[Phase 2] Migrate web design system demo to clamp() and container queries`

### Step 10. Specs and audit-script updates

**Change:** Add new specs and extend the existing static audit:

- `spec/ui/renderers/fluid_emission_spec.cr` (new) — assert `clamp(...)` appears in expected places.
- `spec/ui/renderers/touch_target_spec.cr` (new) — one `it` per interactive widget verifying 44 × 44.
- `spec/ui/renderers/container_query_spec.cr` (new) — assert `container-type: inline-size` + `@container` block presence in generated CSS for Card / Form / SplitView.
- `spec/components/css/css_phase2_wcag_spec.cr` — extend with touch-target audit assertions on the generated demo HTML.
- `scripts/validate_amber_demo.cr` (the actual file `validate_web_demo.cr` redirects to) — add assertions:
  - No `min-width: \d{2,3}px` or `max-width: \d{2,3}px` literal in generated CSS unless inside a `clamp()`.
  - `<meta name="viewport"` present in every page (this already exists at line 71 of that script — confirm it still passes after migration).
  - At least one `@container` block in the generated CSS.

**Files touched:** as listed above.

**Rationale:** The validator runs these scripts. If you don't update them, the next phase has weaker safety nets.

▸ **Commit 8:** `[Phase 2] Specs and validator scripts for clamp/container/touch-target`

### Step 11. Regenerate baselines and verify the suite

**Change:** Re-run the demo generator. Run the full spec suite. Run the audit scripts. Capture screenshots at 1280/768/375/320 in light + dark (the existing screenshot harness in `scripts/capture_amber_demo_screenshots.cr` handles this — extend the viewport list if necessary).

**Files touched:**
- `output/web-design-system-*.html` (regenerated).
- `test-results/web-design-system/static-audit.json` (regenerated).
- `scripts/capture_amber_demo_screenshots.cr` — confirm the viewport list includes 320, 375, 768, 1280 in both schemes. Add 320 if missing.

**Rationale:** Hand-off artifact preparation. The validator looks here first.

▸ **Commit 9:** `[Phase 2] Regenerate demo HTML and screenshot baselines`

---

## 4. Sizing strategy reference

The implementer will reach for this section repeatedly. Internalize it.

### When to use `clamp(min, ideal, max)`

Use `clamp()` when the dimension should **scale smoothly** between two anchors as the viewport (or container) changes. The `min` is a hard floor (small phones); `max` is a hard ceiling (don't bloat on 4K); `ideal` is the curve that interpolates between them.

```css
/* Hero title that shrinks gracefully */
font-size: clamp(1.75rem, 4vw, 3rem);

/* Dialog that stays narrow on big screens, wide on phones */
width: clamp(280px, 90vw, 480px);

/* Padding that grows with viewport but never exceeds 32px */
padding: clamp(12px, 3vw, 32px);
```

**Rule of thumb for `ideal`:** if you want the value to track viewport width, use `Nvw`; if you want it to track container width, use `Ncqi`; if you want a fixed mid-point, use a px or rem.

### When to use `min()` or `max()`

Use `min()` when you want **the smaller of two values** to win — typical for capping a percentage at an absolute ceiling. Use `max()` when you want **the larger** — typical for guaranteeing a floor.

```css
/* Card never wider than 600px, but no wider than its parent */
width: min(100%, 600px);

/* Sidebar at least 240px, but grows with viewport */
width: max(240px, 25vw);
```

`min()` / `max()` are a two-argument simplification of `clamp()`. Prefer `clamp()` when you have all three anchors; prefer `min()` / `max()` when one anchor is genuinely irrelevant.

### When to use container queries vs media queries

| Use case | Tool |
|---|---|
| Page-level structure (sidebar visible? footer columns?) | **Media query** — `@media (min-width: 768px)` |
| Component-internal layout (card stacks vertically below 480px regardless of where it lives) | **Container query** — `@container card (min-width: 480px)` |
| Reduced-motion, dark-mode, print | **Media query** (these are user prefs, not space) |
| Touch-target sizing fork between cursor and finger | **Media query** — `@media (pointer: coarse)` |

A reusable Card component does not know whether it lives in a wide hero or a narrow sidebar. Container queries let it adapt to **its actual rendering width**. Media queries are for top-level layout decisions.

Concrete pairing in this codebase: `NavigationSplitView` uses a media query to collapse the sidebar; the `Card` widget uses a container query to switch from stacked to side-by-side layout. The same demo, resized, exercises both.

### Sizing decision flowchart

```
Is the value a hairline / divider / token-fixed thickness?
  YES → keep as px literal.
  NO  → continue.

Should the value adapt to container size (not page size)?
  YES → emit on a container; use `cqi` / `cqw` in `clamp()`,
        wrap component CSS in `@container <name> (...)` blocks.
  NO  → continue.

Should the value scale with viewport?
  YES → `clamp(floor_px, ideal_vw, ceiling_px)`.
  NO  → fixed `px` / `rem`.

Is this an interactive widget's outer hit area?
  YES → ALSO add `min-width: 44px; min-height: 44px;`.
```

---

## 5. `fluid()` API specification

### Signature

```crystal
class UI::View
  property fluid_width : UI::Fluid?
  property fluid_height : UI::Fluid?

  def fluid_width(min : String | Number, ideal : String | Number, max : String | Number) : self
  def fluid_height(min : String | Number, ideal : String | Number, max : String | Number) : self
end

record UI::Fluid, min : String, ideal : String, max : String do
  def self.px(min : Number, ideal : Number, max : Number) : Fluid
  def self.vw(min_px : Number, ideal_vw : Number, max_px : Number) : Fluid
  def to_css : String  # "clamp(min, ideal, max)"
end
```

### Example 1 — hero title width

```crystal
UI::Label.new("Cross-Platform UI")
  .font(UI::Font.new(size: 48.0, weight: :bold))
  .fluid_width(min: "20rem", ideal: "60vw", max: "48rem")
```

Renders as:

```html
<span style="width: clamp(20rem, 60vw, 48rem); font-size: 48px; font-weight: bold;">Cross-Platform UI</span>
```

### Example 2 — dialog body that scales with viewport

```crystal
UI::Dialog.new(title: "Save changes?")
  .fluid_width(min: 280, ideal: "90vw", max: 480)
```

Renders the dialog with `width: clamp(280px, 90vw, 480px)` (in addition to its own background/padding styles).

### Example 3 — sidebar with a sane ceiling

```crystal
UI::NavigationSplitView.new
  .sidebar_width(320)
  .fluid_width(min: 220, ideal: "28vw", max: 360)
```

The sidebar reflows from 220 px on mobile to 360 px on a 4K monitor, with a 28 % vw curve between.

### Example 4 — using the helper constructor

```crystal
btn = UI::Button.new("Save")
btn.fluid_width = UI::Fluid.px(min: 96, ideal: 144, max: 240)
```

Equivalent to chaining `.fluid_width(96, 144, 240)`.

---

## 6. Container query generator specification

### Renderer-side emission

When a `UI::View` has `container_query_name` set, `apply_common_styles` emits:

```css
container-type: inline-size;
container-name: <name>;
```

Both declarations are required. `inline-size` (vs `size`) is the right default because layout flowing in the inline direction is the common case; widgets that need to query block-size can extend later.

### Component CSS blocks

Ship `@container` blocks alongside the component's base CSS. Example for Card (shipped via `ComponentCSSRegistry`):

```css
.am-card {
  container-type: inline-size;
  container-name: card;
  display: flex;
  flex-direction: column;
  gap: var(--ap-space-3);
  padding: clamp(12px, 3vw, 20px);
}

@container card (min-width: 480px) {
  .am-card { flex-direction: row; }
  .am-card__media { flex: 0 0 40%; }
  .am-card__body { flex: 1 1 auto; }
}

@container card (min-width: 720px) {
  .am-card { gap: var(--ap-space-5); padding: clamp(20px, 3vw, 28px); }
}
```

### Required components

Phase 2 ships container-query layout switches for at least:

1. **Card** (`am-card`) — vertical stack below 480 px container, horizontal split above.
2. **Form** (`am-form`) — labels above fields below 360 px, labels beside fields at 480 px+.
3. **NavigationSplitView** (`am-split-view`) — sidebar overlays content below 768 px container; sidebar inline at 768 px+. (This component already has a media-query equivalent at the page level; the container query lets it work correctly when nested in a narrower region.)

### Utility-class integration

The existing `@<bp>:utility` modifier syntax in `css_generator.cr` continues to work. When `@sm:flex` is used in a class list, the rule is emitted inside `@container (min-width: 640px)`. Phase 2 adds **named container** queries (`@card:flex-row`) so a utility class can target a specific container. The generator change:

```crystal
when .starts_with?("@")
  raw = modifier.lchop("@")
  if raw.includes?(":")
    name, bp = raw.split(":", 2)
    if size = @config.containers[bp]?
      rule.with_container("#{name} (min-width: #{size})")
    end
  elsif bp = @config.containers[raw]?
    rule.with_container("(min-width: #{bp})")
  end
```

---

## 7. Touch-target enforcement strategy

**Approach:** per-widget enforcement at the end of each interactive widget's `visit` method in `web_renderer.cr`.

**Rejected alternative:** a single audit pass over the emitted HTML that injects `min-width:44px; min-height:44px` on every `<button>`, `<input>`, etc. Rejected because (a) it cannot distinguish decorative `<button>` from interactive ones, (b) it cannot handle widgets whose interactive surface is a child of the outer element (e.g., Toggle's `<input>` inside a styled `<label>`), and (c) the centralization buys little since the list of interactive widgets is bounded and known.

**Implementation:**

1. Add a private helper:

   ```crystal
   private def enforce_touch_target(el : Components::Elements::HTMLElement)
     # 44 default comes from tokens.touch_target_minimum_px (Float64 getter on
     # Tokens aggregate, Phase 1). Read from active tokens at emit time so brand
     # overrides cascade through.
     min = tokens.touch_target_minimum_px
     el.add_style("min-width: #{min}px")
     el.add_style("min-height: #{min}px")
   end
   ```

2. Call it at the end of each interactive widget's `visit` method, on the element that *is* the touch target. For widgets where the visible chip is small (e.g., a 16 × 16 close icon), enforce on the surrounding tappable area, not the icon glyph.

3. For Slider and Stepper, enforce on the **thumb** / **button**, not the track / value display.

**Widgets requiring enforcement:**

- `Button`, `IconButton`, `MenuButton`, `SegmentedControl` (each segment)
- `Toggle`, `Checkbox` (the visible swatch, since the `<input>` itself is screen-reader-only)
- `Slider` (thumb element)
- `Stepper` (minus and plus buttons)
- `TextField`, `SearchField`, `TextArea`
- `DatePicker`, `TimePicker`, `ColorPicker`
- `Link` when rendered as a `<button>`-styled action
- `TabBar` tab items
- `NavigationLink` rows
- Close/dismiss controls on `Dialog`, `AlertDialog`, `Sheet`, `ContextMenu`, `ActionPalette`

**Audit:** the validator runs a script that uses headless Chrome to compute the rendered bounding box of every selector with `[role="button"]`, `button`, `[type="checkbox"]`, etc., at each viewport. Any element returning width × height below 44 × 44 fails the check.

---

## 8. Migration plan for `examples/web_design_system_demo.cr` and `output/`

### Source migration (`examples/web_design_system_demo.cr`)

The demo is 1,632 lines, predominantly CSS heredocs registered through `ComponentCSSRegistry`. Migration order:

1. **Container scaffolding** (around lines 50–90) — `.am-demo-shell`, `.am-demo-container`, `.am-demo-nav`. Move `max-width: 1220px` to `clamp(20rem, 92vw, 1220px)`. Add `container-type: inline-size; container-name: demo-page` on `.am-demo-shell`.

2. **Card / panel components** — every `.am-card`, `.am-panel`, `.am-stat-tile` rule. Add container roots; add `@container` blocks at 480 / 720 break points.

3. **Form layouts** — every `.am-form-*` rule. Container-query switch between labels-above and labels-beside.

4. **Dashboard grid** — `.am-dashboard-grid`. Today it likely uses CSS grid; switch to a container-driven grid (`grid-template-columns: repeat(auto-fit, minmax(min(100%, 320px), 1fr))`) so cards reflow naturally without a media query.

5. **Pricing tier grid** — same treatment.

6. **Timeline / collaboration** pages — narrower scope; mostly verify max-widths.

7. **Patterns page** — keep largely as-is; it exists to *show* patterns, so resist over-fluidifying.

8. The `<head>` block (around line 1267) currently emits viewport meta by hand. After step 6 of the implementation plan, this can switch to `renderer.render_document(view, title: ...)`. Be cautious: the demo currently composes the document literally rather than through the renderer; the migration touches a lot of lines. **Option A:** leave the demo's hand-rolled `<head>` and just verify it includes viewport meta (low risk, no migration). **Option B:** route the demo through `render_document` (medium risk, demonstrates the new API). Pick **Option A** for Phase 2 to keep the diff focused; document the choice in the handoff so Phase 6 (the new demo app) can adopt Option B from scratch.

### Generated HTML (`output/web-design-system-*.html`)

Regenerate all seven pages by running:

```
crystal run examples/web_design_system_demo.cr
```

After regeneration, manually inspect at least the overview, pricing, and dashboard pages to confirm:

- No regression in visual hierarchy (the styling shifts but the brand still reads).
- `<meta name="viewport">` is present.
- Container queries appear in the generated `<style>` block (`grep -c '@container'` should be ≥ 3).

The `output/web-design-system-before-phase*` directories are existing baselines for prior phase work. Phase 2 does **not** create a new "before" snapshot directory; the validator captures fresh screenshots and diffs against the current state pre-merge.

---

## 9. Testing requirements

### New spec files

- `spec/ui/fluid_spec.cr` — `UI::Fluid` value type. Verifies `to_css`, `Fluid.px`, `Fluid.vw`.
- `spec/ui/renderers/fluid_emission_spec.cr` — verifies the web renderer emits `clamp(...)` when `fluid_width` / `fluid_height` is set; verifies precedence over `minimum_width` / `maximum_width`.
- `spec/ui/renderers/container_query_spec.cr` — verifies `container-type: inline-size; container-name: <name>` emission; verifies the Card / Form / NavigationSplitView component CSS contains `@container ... (min-width: ...)`.
- `spec/ui/renderers/touch_target_spec.cr` — one `it` per interactive widget asserting `min-width: 44px` and `min-height: 44px` are present.
- `spec/ui/renderers/document_mode_spec.cr` — verifies `Renderer#render_document` produces a valid HTML5 document containing `<!doctype html>`, `<meta name="viewport" content="width=device-width, initial-scale=1">`, `<title>{title}</title>`, and the rendered view as `<body>` content.

### Extensions to existing specs

- `spec/ui/renderers/web_renderer_spec.cr` — add cases for the migrated Dialog / Menu / Stepper sizing literals (verify the new `clamp(...)` strings appear).
- `spec/components/css/css_phase2_wcag_spec.cr` — add an assertion that every emitted interactive selector includes `min-width: 44px; min-height: 44px;`.
- `scripts/validate_amber_demo.cr` — add assertions for:
  - viewport meta presence (already covered at line 71; leave intact).
  - `clamp(` literal count ≥ 20 in concatenated generated CSS across pages.
  - `@container ` literal count ≥ 3.
  - No bare `min-width: \d{2,4}px` outside of `clamp()` in inline styles (regex sweep on raw HTML).

### Manual / build verification

- `crystal spec` — green.
- `crystal build --no-codegen src/asset_pipeline.cr` — clean.
- `crystal run examples/web_design_system_demo.cr` — regenerates pages without error.
- `crystal run scripts/validate_web_demo.cr` — exit code 0.

---

## 10. Definition of done

Phase 2 is done when **every** item is true:

- [ ] `UI::Fluid` type exists with `min` / `ideal` / `max` fields, `to_css`, `Fluid.px`, `Fluid.vw`.
- [ ] `UI::View` has `fluid_width` and `fluid_height` properties **and** chainable modifier methods.
- [ ] `web_renderer.cr` `apply_common_styles` emits `width: clamp(...)` when `fluid_*` is set; falls back to `minimum_*` / `maximum_*` otherwise.
- [ ] `UI::Web::Renderer#render_document(view, title)` exists and emits viewport meta.
- [ ] Container query name property on `UI::View`; renderer emits `container-type: inline-size; container-name: <name>`.
- [ ] Card / Form / NavigationSplitView ship `@container` CSS blocks switching layout at named break points.
- [ ] Every interactive widget's visit method calls `enforce_touch_target` on its tappable element.
- [ ] All hard-coded `min-width:` / `max-width:` / `width:` literals in `web_renderer.cr` (lines listed in step 8) are migrated to `clamp(...)`.
- [ ] `examples/web_design_system_demo.cr` heredoc CSS is migrated to `clamp(...)` and container queries.
- [ ] All seven `output/web-design-system-*.html` files regenerated.
- [ ] New specs exist and pass: `fluid_spec.cr`, `fluid_emission_spec.cr`, `container_query_spec.cr`, `touch_target_spec.cr`, `document_mode_spec.cr`.
- [ ] `crystal spec` — green.
- [ ] `crystal build --no-codegen src/asset_pipeline.cr` — clean.
- [ ] `crystal run scripts/validate_web_demo.cr` — exit code 0.
- [ ] Handoff message written, with commit hashes for each `▸ Commit N` boundary and any deviations called out explicitly.

You do **not** run the validation rubric in `validation.md` yourself. That's the validator's job.
