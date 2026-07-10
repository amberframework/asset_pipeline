# Plan: Beauty Re-Validation + Capture Pipeline Rebuild

**Scope:** macOS + iOS. watchOS deferred (pending new Xcode target setup — captured as follow-up in `.claude/plans/hig-watchos-followup.md`).

**Goal:** The 39 "PASS_WITH_NOTES" rows don't match HIG fidelity. `UI::Sheet.new(...)`, `UI::Sidebar`, `UI::ActionSheet`, `UI::Chart` — none currently produce HIG-authentic Apple output, and none yet reflect the Amber brand. This plan rebuilds the capture pipeline, introduces the Amber brand system, establishes a Fibonacci-golden design scale, and inserts a design-critic agent gate so taste can't be rubber-stamped.

## Design system summary

- **Brand persona:** Amber (see `.claude/skills/apple-platform-guide/brand/amber.md`). Every case arm uses Amber content.
- **Typography:** HIG text styles exact.
- **Spacing:** Fibonacci-golden scale `{2, 4, 8, 13, 21, 34, 55, 89}` pt.
- **Radii:** φ-scaled `{0, 4, 10, 16, 26, ∞}` pt.
- **Palette:** Amber gold primary, plum accent, sage success, peach warning — applied via theme layer over HIG semantic defaults.

## New capture pipeline (Phase 0)

### macOS — live NSWindow + backdrop + `CGWindowListCreateImage`

Replace `cacheDisplayInRect:` snapshot with a real window capture. Each case arm renders into a live NSWindow positioned off-screen (e.g., at `NSPoint(x: -10000, y: -10000)` so it doesn't steal focus) but **`isVisible=YES` and `orderFront:`-ed** so CoreAnimation composites.

Before the tested content is added, a backdrop CALayer is installed behind it — a contextual background that Liquid Glass can blur through. Backdrops live at `.claude/skills/apple-platform-guide/validation/backdrops/` and are selected per slug (mail-list, finder-window, photo, etc.).

Capture with `CGWindowListCreateImage(windowID, kCGWindowImageBestResolution)` after one `CATransaction commit` + `dispatch_after(0.1s)` to let CoreAnimation settle.

One-time setup: macOS Screen Recording permission prompt (System Settings → Privacy & Security → Screen Recording → allow Terminal/iTerm/whatever runs the tests). Documented in `validation/README.md` setup section.

### iOS — XCUIScreen screenshot + backdrop UIWindow + backdrop layer

Replace host-process rasterization with screenshot inside the simulator. Each slug's test method:
1. Presents the tested content in a fresh UIViewController inside a full UIWindow.
2. Adds a backdrop UIImageView beneath it loaded from the backdrop library.
3. Runs `setNeedsLayout` + `layoutIfNeeded`, pumps one runloop tick.
4. Takes `XCUIScreen.main.screenshot()`.

Safe areas respected. Simulator frame preserved (status bar, home indicator).

### Backdrop library

Curated at `.claude/skills/apple-platform-guide/validation/backdrops/`. Generated from:
- Real macOS Finder / Mail screenshots (anonymized where needed).
- iOS Mail / Photos / Home Screen mocks.
- Apple HIG reference corpus (`apple-hig/images/`) for some.
- A few custom-designed Amber-themed mocks (Amber home screen wallpaper, Amber-app stub views to live behind sheets/menus).

Per-slug mapping added to `worklist.json` as `backdrop: <filename>`.

### Initial backdrop set (Phase 0 deliverable — user reviews)

1. `sheet-backdrop-amber-photo.jpg` — pastel anime-style hero image behind a Share sheet
2. `sidebar-backdrop-amber-inbox.png` — Amber's Inbox message list behind the sidebar
3. `menu-backdrop-amber-document.png` — an Amber document behind a context menu
4. `lock-screen-amber-dark.png` — for widgets / live activities
5. `home-screen-amber-wallpaper.jpg` — for widget captures
6. `finder-backdrop.png` — macOS Finder-style column behind column views / outline views

User reviews these 6 before Phase 2 kicks off.

## Design-critic gate

See `.claude/agents/design-critic/agent.md`. After every builder iteration, the orchestrator invokes the critic with the 4 captures + brand doc + rules. Critic returns verdict per appearance + rule grades + specific fixes.

Critic NEEDS_WORK cannot be overridden by the orchestrator. Builder re-captures until critic clears it.

## Raised acceptance bar (12 rules)

A slug reaches PASS when the critic grades all 12 rules PASS:
1. **Shape parity with HIG** — silhouette matches reference illustration.
2. **Liquid Glass** — backdrop visible through glass surfaces; no opaque fills.
3. **Amber palette** — primary/accent/destructive use Amber tokens; no baked RGBA.
4. **Spacing on Fibonacci-golden scale** — `{2, 4, 8, 13, 21, 34, 55, 89}` only.
5. **Radii on φ scale** — `{0, 4, 10, 16, 26, ∞}` only.
6. **HIG typography** — text styles exact (sizes + weights).
7. **SF Symbol fidelity** — filled where HIG shows filled, correct weight/scale/tint.
8. **Hit targets** — ≥44pt iOS, ≥28pt macOS.
9. **Amber content** — uses the content library from `amber.md`, not Lorem ipsum.
10. **Gallery depth** — ≥3 shape variants per slug.
11. **Dark-mode audit** — every rule holds independently in dark.
12. **Doc parity** — component doc matches what captures actually show; override section has working example.

## Execution phases

### Phase 0 — Foundation (3 iterations, autonomous)

- **Iter 0.1:** Capture pipeline — macOS `CGWindowListCreateImage` path with backdrop compositing. Test with one existing slug to validate the pipeline.
- **Iter 0.2:** Capture pipeline — iOS XCUITest path with UIWindow + backdrop layer.
- **Iter 0.3:** Backdrop library — generate/curate the 6 initial backdrops. Add `backdrop` field to worklist schema + `triage.py` + `build_index.py`. **USER REVIEW GATE: approve backdrops before Phase 2.**

### Phase 1 — Systemic cleanup (2 iterations, autonomous)

- **Iter 1.1:** Color audit — grep every `visit(...)` method in renderers for hardcoded RGBA (e.g., `Color.new(r: 0.0, g: 0.478`). Replace with Amber theme tokens via a new `UI::Theme` resolver. Theme layer sits between view properties and renderer — resolves tokens like `Theme.primary` → `#FFAD33` light / `#FFB84D` dark automatically.
- **Iter 1.2:** Spacing audit — grep for hardcoded spacing values not in the Fibonacci-golden set. Replace with named tokens (`Space.sm`, `Space.md`, etc.). Same for corner radii.

### Phase 2 — Glass surfaces first (8 iterations, builder+critic)

Re-validate every slug where `glass_required: true`:
sheets, action-sheets, alerts, popovers, menus, context-menus, dock-menus, edit-menus, sidebars, tab-bars, toolbars, activity-views.

Each iteration: builder rebuilds the case arm with Amber content + backdrop → critic reviews → loop until critic clears.

### Phase 3 — Fix the specifically-called-out regressions (5 iterations)

1. charts iOS — viewport clipping fix, proper width constraint.
2. split-views iOS — currently unusable; rebuild the compact collapse.
3. sidebars macOS — visual upgrade; current render is pathetic.
4. action-sheets — doesn't match HIG reference; rebuild with proper cancel-button treatment.
5. activity-views — tile polish (the 4-tile grid is shape-correct but unrefined).

### Phase 4 — Re-validate remaining rows (~20 iterations)

Every non-glass, non-regression slug: buttons, labels, image-views, text-fields, text-views, pickers, steppers, sliders, toggles, segmented-controls, pop-up-buttons, pull-down-buttons, disclosure-controls, lists-and-tables, collections, boxes, web-views, color-wells, combo-boxes, path-controls (skipped, needs Phase 5 new view), page-controls, rating-indicators, progress-indicators, search-fields, tab-views.

One slug per iteration. Critic gates each.

### Phase 5 — Build-deferred specialty views (7 iterations)

1. `UI::ActivityRings` — CAShapeLayer arc-path infrastructure + three concentric rings.
2. `UI::Gauge` — circular progress arc with value label.
3. `UI::ColumnView` — wraps NSBrowser + data-source protocol bridge (pattern from CrystalPickerDataSource iter-34).
4. `UI::OutlineView` — NSOutlineView + data-source bridge.
5. `UI::ImageWell` — NSImageWell + NSDraggingDestination protocol.
6. `UI::TokenField` — NSTokenField + NSTokenFieldDelegate.
7. `UI::PathControl` — NSPathControl (breadcrumb, separate from the shape-drawing UI::PathView).

Each builds + validates through builder-critic loop.

### Phase 6 — Platform extensions (see hig-platform-extensions.md)

### Phase 7 — watchOS follow-up (deferred)

Separate plan. Requires new Xcode target.

## Realistic iteration estimates

| Phase | Iterations | User touchpoints |
|---|---|---|
| 0 Foundation | 3 | 1 (backdrop approval) |
| 1 Systemic cleanup | 2 | 0 |
| 2 Glass surfaces | 8-12 (some multi-loop) | 0 (critic handles) |
| 3 Regressions | 5-8 | 1 (spot check) |
| 4 Remaining | 20-25 | 1-2 (spot checks) |
| 5 Specialty views | 7-10 | 1 (spot check) |
| 6 Extensions | 8-10 | 2 (persona review, extension scaffolding) |
| **Total** | **~60-70** | **~6** |

User time: ~1-2 hours spread across the project.

## Deliverable

At the end:
- Every component row PASS (not PASS_WITH_NOTES) against the 12-rule bar.
- Dashboard shows 4 compelling captures per row against HIG-reference backdrops with visible Liquid Glass.
- A designer reviewing the dashboard says "yes, that's Amber running on Apple platforms" row by row.
- The "Customization / brand override" section for each component shows how to eject from Amber while keeping structural discipline.
