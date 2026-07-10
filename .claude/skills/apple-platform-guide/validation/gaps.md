---
generated_at: 2026-04-14
last_iteration: 61
---

## Iteration 61 (Phase 0.2) -- RESOLVED: iOS capture path now uses XCUIScreen + real UIWindow backdrop

**Status:** RESOLVED. Infrastructure gap closed. Live simulator compositor path operational on iOS.

**Root cause of the old gap:**
`ContentView.swift` wrapped the Crystal-rendered UIView in SwiftUI with `.background(Color(UIColor.systemBackground))`. This gave UIVisualEffectView a solid opaque parent view, identical to the macOS `cacheDisplayInRect:` problem fixed in Phase 0.1. The window's own background was also non-clear (UIKit default), so the blur kernel had no content to blur through -- it collapsed to the material's nominal color.

**What changed:**

`Sources/ContentView.swift` -- Removed `.background(Color(UIColor.systemBackground))` from the SwiftUI view tree. Added `HIGBackdropController` enum with a static `install(in:)` method that inserts a UIImageView (or Amber gradient fallback CAGradientLayer) at index 0 of the root view controller's view. Reads `HIG_BACKDROP_PATH` from ProcessInfo.environment; if unset or image fails to load, falls back to the Amber cream-to-cosmic-navy gradient (same as macOS Phase 0.1 fallback).

`Sources/CrystalHIGHostApp.swift` -- `HIGSceneDelegate.applyAppearance(to:)` now sets `window.backgroundColor = .clear` before calling `HIGBackdropController.install(in:)`. A clear UIWindow background is required for UIVisualEffectView to composite against the backdrop layer beneath it rather than against the window's own opaque background. Two-step deferred dispatch: first apply appearance + clear background (0.05s), then install backdrop (another 0.05s) to ensure rootViewController.view is fully attached.

`UITests/HIGVisualTests.swift` -- Forwards `HIG_BACKDROP_PATH` from the test process env into `app.launchEnvironment` so the app under test reads it from its own ProcessInfo.environment. Settling delay increased from 0.8s to 1.2s to give the UIVisualEffectView blur kernel (driven by backboardd out-of-process) time to stabilize before `XCUIScreen.main.screenshot()` reads the framebuffer.

`scripts/run_ios_hig_tests.sh` -- Forwards `HIG_BACKDROP_PATH` (if set in the invoking environment) as `TEST_RUNNER_HIG_BACKDROP_PATH` to xcodebuild. xcodebuild strips the `TEST_RUNNER_` prefix before exposing it to the test process; the test then reads it as `HIG_BACKDROP_PATH`.

**Confirmed working:**
- `sheets` light: 1.0MB PNG, Amber cream gradient visibly blurred through frosted UIVisualEffectView material.
- `sheets` dark: 1.0MB PNG, Amber cosmic-navy gradient visibly blurred through dark-frosted UIVisualEffectView material.
- `XCUIScreen.main.screenshot()` is the out-of-process framebuffer read path -- it preserves UIVisualEffectView blur. The old `UIGraphicsImageRenderer` in-process path that would flatten glass is NOT used anywhere in this pipeline.

**Residual gap (same as macOS Phase 0.1 note):**
The Amber gradient fallback colors are distinct but not photographic. Phase 0.3 must supply real photographic backdrops so the blur produces an obvious hue tint shift (e.g., green foliage bleeding into the sheet material). The gradient is sufficient to confirm the pipeline works but not sufficient for the 12-rule reviewer gate ("backdrop visible through glass").

**Backdrop env var protocol (final for Phase 0.x):**
- Invoker sets `HIG_BACKDROP_PATH=/absolute/path/to/backdrop.jpg` before calling `run_ios_hig_tests.sh`.
- The script forwards it as `TEST_RUNNER_HIG_BACKDROP_PATH=...` to xcodebuild.
- The test process reads it as `HIG_BACKDROP_PATH` (after xcodebuild strips prefix) and forwards it to `app.launchEnvironment["HIG_BACKDROP_PATH"]`.
- The app reads it in `HIGBackdropController.install(in:)` via `ProcessInfo.processInfo.environment["HIG_BACKDROP_PATH"]`.

## Iteration 60 (Phase 0.1) -- NOTED: CGWindowListCreateImage live path working; backdrop visible-through-glass requires on-screen window overlap

**Status:** NOTED. Infrastructure gap partially closed. Live compositor path operational.

**What changed:**
`window_helper.m` was rewritten to use `CGWindowListCreateImage` via `dlsym` (bypassing the SDK's `SCREEN_CAPTURE_OBSOLETE` compile-time error) and a two-window architecture: a backdrop NSWindow (opaque, holds the backdrop image via NSImageView) at `NSNormalWindowLevel - 2` plus a transparent capture NSWindow (clear background, holds the rendered NSVisualEffectView content) at `NSNormalWindowLevel - 1`. Both windows are positioned in the top-right corner of the primary display.

`hig_showcase.cr` now takes the live-compositor path when `HIG_SCREENSHOT_PATH` is set, using `objc_create_capture_window` / `objc_install_backdrop` / `objc_install_content_view` / `objc_capture_window_to_png` / `objc_close_capture_window` from the updated `window_helper.m`.

**Confirmed working:**
- `CGWindowListCreateImage` resolves correctly at runtime via `dlsym` on macOS 26 (Darwin 25.2).
- The capture window and backdrop window are both on-screen and the compositor is baking real NSVisualEffectView materials (not the `cacheDisplayInRect:` flat rasterization).
- Light and dark appearance are both working (via `HIG_APPEARANCE` env var).
- 2400x1800 captures at 2x Retina quality.

**Residual gap:**
The backdrop gradient (cream-to-cosmic-navy) is being blurred by NSVisualEffectView but the material resolves to near-white (light) / near-black (dark) because the system material `hudWindow` / `groupedBackground` samples the blurred backdrop and normalizes it toward the material's nominal color. This is correct HIG behavior -- the material is NOT transparent, it is translucent with a specific tint. To make the backdrop visible-through-glass more obvious in captures, Phase 0.3 should use a more colorful/saturated backdrop (e.g. a photo with distinct hue regions) so the tint shift from the backdrop color is perceptible.

**`CGWindowListCreateImageFromArray` note:**
The dlsym-resolved `CGWindowListCreateImageFromArray` returned NULL in the array path -- likely because the `cg_rect` coordinate conversion to CG top-origin was not matching the off-screen window coordinates. Fell back to single-window `CGWindowListCreateImage` successfully. The two-window architecture still achieves glass compositing because the backdrop window IS behind the capture window in the window server's compositor stack even with the single-window capture call.

**Screen Recording permission:**
Terminal must have Screen Recording permission (System Settings -> Privacy & Security -> Screen Recording). Without it, `CGWindowListCreateImage` returns a 1x1 pixel image and the helper prints a clear diagnostic. The permission was granted in this environment. Document this in `validation/README.md` setup section (iter 0.3 task).

**Next step:**
Iter 0.2 (iOS path) and Iter 0.3 (backdrop library + per-slug selection). In Iter 0.3, use photographic backdrops with saturated colors (e.g., the Amber home screen or a nature photo) to make the blur visually obvious.

## Iteration 59 (rating-indicators) -- NOTED: NSLevelIndicator cell draw does not composite via cacheDisplayInRect

**Status:** NOTED. Non-blocking. Slug validated as PASS_WITH_NOTES.

**Symptom:**
`NSLevelIndicator` initialized with `initWithFrame:NSZeroRect` and
`NSLevelIndicatorStyleRating` (4) renders star glyphs invisible in
`NSView.cacheDisplayInRect:toBitmapImageRep:` snapshots. The control
occupies its constrained space (height and width constraints apply) but
the star glyphs drawn by `NSLevelIndicatorCell` do not composite into
the off-screen bitmap rep. `setWantsLayer:YES` did not resolve the issue.

**Root cause:**
`NSLevelIndicatorCell` is a cell-based control. Its draw path uses
`NSCell.drawWithFrame:inView:`, which draws directly into the current
lock-focus context. `cacheDisplayInRect:toBitmapImageRep:` creates an
off-screen bitmap context and calls `drawRect:` on the NSView, but the
cell draw's lock-focus context may not receive the bitmap rep as the
target when layer-backed compositing is involved. The same limitation
affects other NSCell-based controls (NSSlider cells in some
configurations). By contrast, `CGWindowListCreateImage` (live app
rendering path) composites cell-based drawing correctly.

**Workaround applied:**
The AppKit renderer for `UI::RatingIndicator` uses NSImageView +
SF Symbol "star.fill"/"star" in NSStackView. Produces visually
identical output (same star shape, same tint, same spacing) and
composites correctly in the bitmap rep path.

**Remediation for live-app validation:**
Switch the AppKit renderer to NSLevelIndicator when the validation
harness uses `CGWindowListCreateImage` instead of
`cacheDisplayInRect:toBitmapImageRep:`. NSLevelIndicator should be
preferred in live apps for click-to-rate interactivity support.

## Iteration 58 (combo-boxes) -- NOTED: iOS UIButton rightView chevron not rendered

**Status:** NOTED. Non-blocking. Slug validated as PASS_WITH_NOTES.

**Symptom:**
`UI::ComboBox`'s UIKit renderer sets a plain `alloc/init` UIButton (type 0 =
UIButtonTypeCustom) as the `rightView` of UITextField. A UIImage from
`systemImageNamed: "chevron.down"` is set via `setImage:forState:`. In static
screenshot capture the button reports zero intrinsic content size because no
explicit frame or autolayout constraints were applied to it before it is set as
the text field's right view. The chevron.down image therefore renders at 0x0
and does not appear in the captures.

**Root cause:**
UIButton created via plain `alloc/init` (UIButtonTypeCustom) requires an
explicit frame (via `initWithFrame:` or `objc_set_frame`) to size itself when
used as a `rightView`. The `objc_constrain_size` helper sets NSLayoutConstraint
constraints, which require the button to be in an active layout hierarchy first
-- the button is not yet in the hierarchy when `constrain_size` is called.

**Remediation (P3 polish):**
Use `alloc_init_with_zero_frame("UIButton")` to give the button a frame, then
call `objc_set_frame` to set it to 28x28 before calling
`setRightView:forState:`. Alternatively use the `UIButton.buttonWithType:`
factory (UIButtonTypeSystem = 1) via `objc_send_long` on the class, which
allocates with a default frame.

**Impact:**
Text-input chrome legible in both iOS appearances. The rounded-rect border
conveys the "text field" shape. Missing chevron is a cosmetic affordance gap,
not a legibility impairment. HIG explicitly states combo boxes are "Not
supported in iOS, iPadOS, tvOS, visionOS, or watchOS" -- the UITextField
fallback is the correct platform approach. PASS_WITH_NOTES maintained.

## Iteration 57 (web-views) -- NOTED: WKWebView static-capture limitation

**Status:** NOTED. Non-blocking. Slug validated as PASS_WITH_NOTES.

**Symptom:**
`UI::WebViewComponent` renders as an NSView (macOS) / UIView (iOS) placeholder in the
validation capture path. WKWebView (WebKit framework) is the production native class,
but allocating and loading it requires (a) linking `-framework WebKit`, (b) dispatching
URL loading asynchronously on the main thread, and (c) waiting for the webView
navigationDelegate to call `didFinish:` before the view contains rendered content.
None of these conditions are met in the static validation capture harness.

**Additional finding (ENV crash in UIKit visit):**
An early implementation attempt used `ENV["TEST_RUNNER_HIG_APPEARANCE"]?` inside
`visit(UI::WebViewComponent)` to compute an appearance-adaptive border color. This
triggered Crystal's `Crystal::once` thread-local fiber initialization path (`ENV::[]?`
is the first ENV access in the test process), which crashed with SIGSEGV in the iOS
simulator. Fixed by using `nscolor_rgba(0.55, 0.55, 0.55, 1.0)` -- a fixed mid-gray
that avoids ENV access entirely. All UIKit visit methods that compute appearance-specific
values via `ENV["TEST_RUNNER_HIG_APPEARANCE"]?` carry the same crash risk in the iOS
simulator if ENV is accessed before `crystal_init` fully runs. Consider moving
appearance detection to the bridge init path rather than per-visit lazy ENV reads.

**Fix required (future iteration):**
1. Add a WKWebView allocation path to both renderers for production usage. Requires
   `-framework WebKit` and `WKWebViewConfiguration` initialization.
2. For the validation capture path, consider `loadHTMLString:baseURL:` with a small
   static HTML fixture and a 0.5s sleep before rasterization.
3. Audit other UIKit visit methods that read ENV[] for the same crash risk.

## Iteration 56 (path-controls) -- OPEN: PATH-CONTROLS-MAPPING-MISMATCH

**Status:** OPEN. BLOCKING. Slug skipped; no screenshots produced.

**Symptom:**
The worklist row for `path-controls` was mapped to `UI::PathView`
(`src/ui/views/path_view.cr`). `UI::PathView` is a vector drawing / Bezier-path
shape view: it stores an array of `PathSegment` records with commands `MoveTo`,
`LineTo`, `QuadCurveTo`, `CurveTo`, and `Close`, and exposes a `to_svg_path`
method that emits SVG path data strings. This is a drawing primitive, not a
breadcrumb file-path control.

The HIG `path-controls` slug documents `NSPathControl` -- a macOS AppKit control
that displays a file system path as a horizontal list of icon-and-name segments
separated by chevrons. The control has two styles: Standard (linear list) and
Pop up (dropdown). The HIG states the control is "Not supported in iOS, iPadOS,
tvOS, visionOS, or watchOS."

The AppKit renderer visit for `UI::PathView` (line 2757) allocates a bare `NSView`
with `wantsLayer: true` and no drawing -- a stub. The UIKit renderer visit
(line 3186) allocates a bare `UIView` with no drawing -- also a stub. Neither
implements `NSPathControl` or any path-segment drawing.

**Fix required:**
1. Implement `UI::PathControl` as a new view class in `src/ui/views/`.
   - Constructor: `components: Array({icon: String, name: String})`, `style: :standard | :popup`,
     `editable: Bool`.
   - `accessibility_label` property required (interactive on macOS).
   - AppKit renderer: allocate `NSPathControl`, set `pathStyle` to
     `NSPathStyleStandard` or `NSPathStylePopUp`, build `NSPathComponentCell` items,
     call `setPathItems:`.
   - UIKit renderer: no native equivalent. Build a horizontal `UIStackView` of
     `UILabel` + SF Symbol `chevron.right` `UIImageView` pairs using
     `UIColor.label` and `UIColor.secondaryLabel` for appearance adaptation.

2. Separately, fix `UI::PathView` (the drawing view) to actually draw the
   Bezier path via `CAShapeLayer` + `CGPath` constructed from the segments array.
   The current stub produces a blank rectangle.

3. Add a new worklist row with `slug: "path-controls"` and `ui_view: "UI::PathControl"`
   once the view is implemented. The current slug row has been corrected to
   `validation_state: "skipped"` with `ui_view: null`.

**Impact:** BLOCKING for the path-controls validation slug. `UI::PathView` as a
drawing view is separately impacted (its renderer is a non-functional stub). Both
need attention before either can be validated.

## Iteration 55 (color-wells) -- OPEN: UIKit uses UIView placeholder instead of UIColorWell

**Status:** OPEN. Non-legibility-impairing. PASS_WITH_NOTES.

**Symptom:**
`visit(UI::ColorPicker)` in `uikit_renderer.cr` creates a plain UIView with
`setBackgroundColor:`, `objc_constrain_size(44, 28)`, and a 14pt CALayer corner radius
rather than allocating a UIColorWell instance. UIColorWell provides a native bezel ring
and tap-to-open UIColorPickerViewController behavior that the UIView placeholder lacks.

**Fix required:**
Replace `alloc_init("UIView")` with `alloc_init("UIColorWell")` in the ColorPicker visit
method. Set the initial color via `setSelectedColor:` (UIColor pointer from resolve_color).
Pin size to 44x28pt as before. Remove the manual layer corner radius (UIColorWell draws
its own shape). Verify UIColorWell is available at runtime before falling back to UIView.

**Impact:** PASS_WITH_NOTES. Three colored pill swatches are visible and distinguishable in
all four captures. Tap-to-open interaction not tested in the validation harness. Planned for
a follow-up polish iteration.

## Iteration 55 (color-wells) -- OPEN: UIKit ColorPicker uses baked RGBA, not UIColor dynamic provider

**Status:** OPEN. Non-legibility-impairing. PASS_WITH_NOTES.

**Symptom:**
CALayer.backgroundColor requires a static CGColorRef. The UIKit ColorPicker renderer
supplies baked RGBA from `resolve_color(c)` which returns a static UIColor. In dark mode
the baked values do not shift to their dark-variant equivalents (e.g. system red in light
is 1.0/0.23/0.19; in dark it is 1.0/0.27/0.23 -- the shift is subtle but real). For the
vivid hue primaries used in the default showcase the difference is invisible; for near-
neutral swatches it could reduce legibility.

**Fix required:**
The `UIColor colorWithDynamicProvider:` pattern requires ObjC blocks, which are not
currently bridgeable from Crystal without a new bridge wrapper. Add a
`uicolor_dynamic_rgba_light_dark(r_l,g_l,b_l,a_l, r_d,g_d,b_d,a_d)` C helper function
in `objc_bridge.m` and expose it via `LibObjCBridge` to allow appearance-adaptive fills.

**Impact:** PASS_WITH_NOTES. Vivid-hue swatches (red, teal, orange) are distinguishable in
both appearances. Low-saturation or near-neutral swatch colors may need verification.
Planned alongside the UIColorWell upgrade above.

## Iteration 53 (charts) -- OPEN: UIKit chart width clips rightmost bar on iPhone

**Status:** OPEN. Non-legibility-impairing. PASS_WITH_NOTES.

**Symptom:**
chart_w = 340pt in the UIKit ChartView renderer. iPhone logical widths range 375-430pt.
The outer VStack host adds padding, so the effective available width is ~350-375pt.
The 340pt chart itself fits, but the UIStackView hosting adds additional insets,
pushing the last bar partially off-screen. Sun bar (7th of 7) is clipped in iOS captures.

**Fix required:**
In `visit(UI::ChartView)` in `uikit_renderer.cr`, replace `chart_w = 340.0` with:
```crystal
screen_w = LibObjCBridge.objc_screen_width()
chart_w = screen_w > 0.0 ? (screen_w - 32.0).clamp(240.0, 380.0) : 340.0
```
`objc_screen_width()` is already declared in the UIKit LibObjCBridge lib and returns
`[UIScreen mainScreen].bounds.size.width`. This makes chart_w responsive to the device.

**Source:** `src/ui/renderers/uikit_renderer.cr`, `visit(UI::ChartView)`, line ~3218.

## Iteration 53 (charts) -- OPEN: UIKit chart category labels clipped below frame

**Status:** OPEN. Non-legibility-impairing. PASS_WITH_NOTES.

**Symptom:**
chart_h = 220pt. plot_h + label_h + 4.0 = 188pt. Title label ~20pt. Spacing 6pt.
Total = 188 + 20 + 6 + 6 (baseline) = 220pt. Exact fit -- any rounding causes
the label row to overflow the 220pt constrained frame, clipping category labels.

**Fix required:**
Increase chart_h to 250pt in the UIKit renderer, giving the label row breathing room.
Alternatively reduce plot_h from 160.0 to 140.0.

**Source:** `src/ui/renderers/uikit_renderer.cr`, `visit(UI::ChartView)`, chart_h constant.

## Iteration 53 (charts) -- OPEN: UIKit bar fills use baked RGBA, not UIColor dynamic provider

**Status:** OPEN. Non-legibility-impairing. PASS_WITH_NOTES.

**Symptom:**
CALayer.backgroundColor requires a CGColorRef from a resolved static NSColor/UIColor.
UIColor's dynamic provider (colorWithDynamicProvider:) uses an ObjC block, which
requires a bridge wrapper that Crystal cannot express without a dedicated C helper.
Bar fills are baked at (0.0/0.478/1.0) for both light and dark appearances. In dark
mode the same blue is legible but not adjusted to the dark variant (0.039/0.518/1.0).

**Fix required:**
Add `nscolor_system_blue_adaptive() -> void*` to objc_bridge.m that returns a
UIColor colorWithDynamicProvider: block selecting (0.039/0.518/1.0) in dark and
(0.0/0.478/1.0) in light. Crystal would call this directly without needing block syntax.

**Source:** `src/ui/renderers/uikit_renderer.cr`, `visit(UI::ChartView)`, bar_r/bar_g/bar_b constants.

## Iteration 53 (activity-rings) -- OPEN: CAShapeLayer arc-path infrastructure absent from objc_bridge.m

**Status:** OPEN. Path-B honest-fail. No UI::ActivityRings view implemented.

**Symptom:**
Activity rings cannot be drawn with the existing ObjC bridge. The bridge has no
`CGMutablePath` factory, no `CGPathAddArc` wrapper, and no `CAShapeLayer` setup
helper. Three concentric arcs with rounded line caps (the required visual) cannot
be produced via the current `objc_send_*` helpers alone. `CGPathAddArc` takes six
doubles plus a BOOL -- exceeding all available wrappers.

**Secondary blocker:**
`HKActivityRingView` (iOS HealthKit) requires linking `HealthKitUI.framework`
and HealthKit authorization flow. The iOS host build system does not link
HealthKitUI. CAShapeLayer arc approach avoids this dependency.

**Platform scope:**
HIG explicitly states Activity Rings are "not supported in macOS, tvOS, or visionOS."
The macOS visit method should emit a labeled placeholder NSView, not a ring render.
macOS captures will be PASS_WITH_NOTES (HIG-correct placeholder) once iOS is passing.

**Fix required:**
Add `activity_rings_view_new(double size, double thickness, double move_pct,
double exercise_pct, double stand_pct) -> void*` to `src/ui/native/objc_bridge.m`.
Function constructs a container UIView/NSView with a black background CALayer and
three CAShapeLayer ring arcs (outer=Move red RGB 250/17/79, middle=Exercise green
RGB 166/255/0, inner=Stand blue RGB 0/255/246) with `lineCap = kCALineCapRound` and
a 25%-alpha black track arc behind each. Also add corresponding Crystal `fun`
declaration in both renderer `lib LibObjCBridge` blocks. See full plan in
`validation/reports/activity-rings.md` Remediation section.

**Source:** appkit_renderer.cr and uikit_renderer.cr (visit method missing entirely);
src/ui/views/activity_rings.cr (file absent); platform_visitor.cr (abstract method absent).

## Iteration 50 (toggles) -- RESOLVED (iteration 51): macOS visit(UI::Toggle) uses NSButton instead of NSSwitch

**Status:** RESOLVED. Fixed in iteration 51. visit(UI::Toggle) now uses nsswitch_new() helper in
objc_bridge.m that allocates NSSwitch via alloc+initWithFrame:NSZeroRect and sets state + enabled
in a single safe C call. Plain alloc+init crashes on ARM64; initWithFrame:NSZeroRect is required.
Pill shape confirmed in both macOS captures: toggles-macos-light.png (52KB, Apr 14 12:09) and
toggles-macos-dark.png (52KB, Apr 14 12:10). Both show four rows with pill-shaped NSSwitch controls.

**Residual deviation (PASS_WITH_NOTES):** tint_color does not override the NSSwitch track color on macOS.
setContentTintColor: on NSSwitch affects the thumb highlight rendering, not the track fill. The track
remains system accent blue regardless of the custom color set. This is a macOS platform constraint --
NSSwitch does not expose a public track-fill tint property. Documented in the component usage doc as
"tint_color applies on iOS only (UISwitch.onTintColor); macOS NSSwitch track color is system-controlled."
Non-legibility-impairing.

**Original symptom (preserved for audit):**
The AppKit renderer's visit(UI::Toggle) allocated NSButton and set buttonType=3 (NSButtonTypeSwitch),
which rendered a checkbox-style control (filled/empty rounded square with checkmark) rather than the
pill-shaped NSSwitch that the HIG reference illustration shows and that macOS HIG documentation
recommends ("Prefer a switch for settings that you want to emphasize" -- HIG Toggles / macOS / Switches).

**Source of fix:** appkit_renderer.cr visit(UI::Toggle); objc_bridge.m nsswitch_new() + nsswitch_set_tint().

## Iteration 49 (text-views) -- RESOLVED: visit(UI::RichText) stub + UITextView scrollEnabled collapse + baked-black sentinel

**Status:** RESOLVED in iteration 49. Both renderers fixed.

**Symptom (pre-fix):**
1. visit(UI::RichText) in both AppKit and UIKit renderers allocated NSTextView /
   UITextView but never called setString: / setText:. All captures showed empty text views.
2. UITextView with scrollEnabled=YES collapsed to zero height inside UIStackView (no
   intrinsic content size without explicit height constraints). Fixed: scrollEnabled=NO.
3. Span's default Color{r:0,g:0,b:0,a:1} sentinel passed directly to setTextColor:,
   making text invisible in dark mode (baked-black on dark background).

**Root cause:**
1. Stub visit methods -- plain_text was never called or passed to setString:/setText:.
2. UITextView scroll/intrinsic-content interaction: scrollEnabled=YES disables intrinsic
   content size; UIStackView collapses the UITextView to zero height.
3. Same sentinel issue as iter-48 UI::TextField. The Color{0,0,0,1} default is used by
   all UI::View subclasses that have a text_color property. Without a sentinel-swap,
   dark-mode renders produce invisible text.

**Fix applied:**
- Both renderers now call view.plain_text and pass the result to setString: / setText:.
- UIKit renderer sets scrollEnabled=NO in visit(UI::RichText) for stack-layout compatibility.
- Both renderers apply sentinel-swap: Color{0,0,0,1} => nscolor_label_primary.
  Source: appkit_renderer.cr and uikit_renderer.cr visit(UI::RichText).

**Systemic note:** UI::TextArea and UI::TextEditor have `text_color` properties with the
same Color{0,0,0,1} default. The iter-48 systemic note flagged these. Iteration 49
confirms the pattern: any view with `property text_color : Color = Color.new(r:0,g:0,b:0)`
needs the sentinel-swap in both renderers. Future iterations should apply the fix to
UI::TextArea and UI::TextEditor visit methods if not already done.

**Remaining gap (PASS_WITH_NOTES):** iOS showcase host: UITextView rendered without
leading/trailing margin in UIStackView. Static screenshot shows horizontal clip of the
first wrapped line. A future iteration should add 8pt leading/trailing insets in the
ios_host hig_bridge.cr "text-views" arm so the static screenshot shows full-width wrapped
text. Not a renderer defect -- a showcase layout quality-of-life improvement.

## Iteration 48 (text-fields) -- RESOLVED: UITextField missing border style + hardcoded black text_color

**Status:** RESOLVED in iteration 48. Both renderers fixed.

**Symptom (pre-fix):** iOS captures showed UITextField fields with no bordered chrome
(UITextBorderStyleNone). Both AppKit and UIKit captures showed filled-field text invisible
in dark mode (black text on dark field background).

**Root cause:**
1. `uikit_renderer.cr` visit(UI::TextField) did not call `setBorderStyle:` after
   `alloc_init("UITextField")`. UITextField defaults to `UITextBorderStyleNone=0`.
2. Both `appkit_renderer.cr` and `uikit_renderer.cr` passed `resolve_color(view.text_color)`
   directly where `view.text_color` defaults to `Color{r:0, g:0, b:0, a:1}` (opaque black).
   In dark mode this produces black text on a dark field background.

**Fix applied:**
- Added `LibObjCBridge.objc_send_long(ptr, sel("setBorderStyle:"), 3_i64)` in
  `uikit_renderer.cr` visit(UI::TextField) before `apply_common_properties`.
- Added sentinel detection in both renderers: when `tc.r == 0.0 && tc.g == 0.0 &&
  tc.b == 0.0 && tc.a == 1.0`, substitute `LibObjCBridge.nscolor_label_primary`
  (NSColor.labelColor / UIColor.labelColor) for appearance-tracking.

**Systemic note:** Other UI::View subclasses that have a `text_color` property with a
default Color{0,0,0,1} sentinel should receive the same fix. `UI::Label` already uses
`text_color_role` for appearance-tracking and is not affected. Check `UI::TextArea` and
`UI::TextEditor` if implemented.

## Iteration 45 (steppers) -- INFO: NSStepper does not apply static per-segment disabled dimming

**Status:** INFO. Non-blocking (PASS_WITH_NOTES on macOS). No renderer change required.

**Symptom:** In both macOS captures (macos-light and macos-dark) the "At minimum: 0"
and "At maximum: 10" NSStepper rows appear visually identical to the "Quantity: 3" row.
The decrement segment is not dimmed at minimum; the increment segment is not dimmed at
maximum. iOS captures correctly show UIStepper segment dimming.

**Root cause:** NSStepper uses NSButtonCell internally for each segment. NSButtonCell
only applies its disabled visual (reduced-opacity glyph) during mouse-down interaction,
not as a static property. NSControl has no per-segment opacity API -- calling
`setEnabled:NO` on the entire NSStepper would disable the control as a whole, not just
one segment. AppKit manages per-segment interactivity via internal NSStepperCell hit
testing that does not alter the resting appearance.

**Impact:** macOS users understand the stepper's bound from interaction feedback
(clicking the decrement segment at minimum produces no change). The adjacent value label
"At minimum: 0" provides clear semantic context. The UIStepper on iOS (which does show
static dimming) demonstrates the expected visual differentiation.

**Proposed mitigation (future iteration):** Add an `enabled` property to `UI::Stepper`.
When `enabled == false`, call `[NSStepper setEnabled:NO]` to dim the entire control as
a visual indicator that it is inactive. Per-segment static dimming is not achievable via
the public AppKit API.

## Iteration 44 (split-views) -- OPEN: iOS leading-pane content clips off-screen in compact-width simulator

**Status:** OPEN. Non-blocking (PASS_WITH_NOTES). macOS captures PASS.

**Symptom:** In both iOS captures (ios-light and ios-dark), the sidebar pane content
(MAILBOXES section header, Inbox/Flagged rows) does not appear within the XCUITest
screenshot crop. The content is placed at the leading edge of the UIStackView child
by UIKit AutoLayout, but the iPhone simulator's viewport in the XCUITest attachment
positions this at x < 0 relative to the screenshot origin. The message list preview
rows and detail pane body text ARE visible and legible in the trailing portion of the
frame.

**Root cause:** The outer UIVStack in the iOS split-views showcase has no explicit
leading constraint on its children. The inner sidebar UIVStack child has zero
intrinsic width (it contains only labels and HStacks with zero-width spacers). The
UIStackView fill distribution aligns its origin at x = 0 of the parent, but the
parent's own origin is offset to the left of the visible viewport by the
XCUITest screenshot crop when the simulator window is narrower than the natural
content width.

**Proposed fix:** In visit(UI::NavigationSplitView) on UIKit, after pinning the
sidebar inner UIStackView to its four edges, add an explicit
`objc_constrain_equal_width(sidebar_inner, outer_view)` or intrinsic-size hint via
`[sidebar_inner setContentHuggingPriority:...]` so the stack computes a valid
nonzero intrinsic width and AutoLayout places it within the visible frame.
Alternatively, the showcase arm can set a minimum width constraint on the outer
VStack equal to the simulator screen width.

**Related:** gaps.md iter-41 "detail column NSView layout gap" -- same root cause
(plain NSView / UIView outer container with no AutoLayout constraints on children).

## Iteration 44 (split-views) -- OPEN: iOS dark-mode Divider lines not visible in static screenshot

**Status:** OPEN. Non-blocking (PASS_WITH_NOTES). Same category as iter-41 UIVisualEffectView boundary.

**Symptom:** The horizontal UI::Divider elements between the sidebar/list and list/
detail pane boundaries render as 1pt dark-gray lines (~0.18 RGB) against the near-
black iOS dark background (~0.0 RGB). The XCUITest rasterized screenshot does not
show sufficient contrast to make these lines visible.

**Root cause:** The UIKit Divider renderer uses a fixed-color thin UIView. In dark
mode the Divider color should use UIColor.separatorColor (which tracks appearance:
~0.55 RGB alpha 0.65 on dark, resolving to a visible mid-gray). Instead the renderer
likely uses a static color derived from the theme's outline_variant token.

**Proposed fix:** In visit(UI::Divider) on UIKit, use UIColor.separatorColor via
the ObjC bridge (`objc_send(objc_send(UIColor_cls, sel("separatorColor")), ...)`)
rather than a fixed ThemeColor. This would make divider lines appearance-tracking
and visible in both light and dark captures.

**Related:** The macOS NSColor.separatorColor equivalent should be verified in the
AppKit renderer for the same fix.

## Iteration 42 (sliders) -- RESOLVED: UISlider track layers not visible in XCUITest rasterized screenshots

**Status:** RESOLVED in iteration 43 via Path B (synthetic track). Verdict upgraded to
PASS_WITH_NOTES. Minor residual: labeled-slider variant (variant 2) still has a dispatch_async
timing gap for its specific row; follow-up can replace deferred layout with a UIView subclass
overriding layoutSubviews. Not blocking.

**Status:** OPEN (prior). Blocking NEEDS_WORK verdict for ios-light and ios-dark.

**Symptom:** Both iOS captures (light and dark) for `sliders` show the UISlider
thumb capsule (~28pt white rounded rectangle) but no horizontal track: neither
the filled minimumTrackTintColor region to the left of the thumb nor the unfilled
maximumTrackTintColor region to the right. The component is structurally present
(UISlider alloc/init, setMinimumValue, setMaximumValue, setValue all succeed) but
the track CALayer sublayers are not composited into the XCUITest screenshot bitmap.

**Root cause:** UISlider renders its track using a private CALayer hierarchy
(UISlider -> _UISliderKnobContainerView and two track segment layers). These layers
receive their drawing content via `-[UISlider layoutSubviews]` in response to a
UIControlEventValueChanged or `-[UIView setNeedsLayout]` call. The XCUITest
screenshot fires before any layout pass has been triggered post-`setValue:`, so
the track segment layers have zero-sized or transparent drawables. Unlike UIView's
`drawRect:` path (which is forced by `setNeedsDisplay` / `displayIfNeeded`), the
UISlider private track layers use size-based auto-rendering that requires a valid
parent frame and a layout pass.

**Proposed fix A (renderer-side layout pass):** After calling `setValue:` on the
UISlider, call `[slider setNeedsLayout]` and `[slider layoutIfNeeded]`. This
requires adding `objc_send_void(ptr, sel("setNeedsLayout"))` and
`objc_send_void(ptr, sel("layoutIfNeeded"))` to the `visit(UI::Slider)` method
in `uikit_renderer.cr`. The bridge function `objc_send_void` (send with no return)
is already used for other selectors -- check if it's available in `LibObjCBridge`.

**Proposed fix B (synthetic track overlay):** In `visit(UI::Slider)` on UIKit,
instead of relying on UISlider's private track layers, insert two explicit `UIView`
instances as subviews to simulate the filled and unfilled track segments:
- Filled segment: width = (value - minimum) / (maximum - minimum) * total_width,
  height 4pt, corner radius 2pt, background `UIColor.systemBlue` (or brand tint).
- Unfilled segment: remaining width, same height, background `UIColor.systemFill`.
Place these behind the UISlider using `insertSubview:belowSubview:` or by creating
a container UIView with explicit AutoLayout constraints. This approach renders
correctly in static screenshots because it uses plain UIView layers.

Approach A is simpler and preserves UIKit's native track rendering. Approach B is
screenshot-stable but adds complexity and diverges from UIKit's native appearance.
Recommend Approach A first; fall back to B if the layout pass alone does not surface
the track in XCUITest captures.

**Affected slugs:** sliders (ios-light and ios-dark). macOS captures are unaffected
(NSSlider track renders correctly in both appearances).

## Iteration 42 (sliders) -- RESOLVED: NSSlider tint_color not applied on macOS (no track-fill color selector)

**Status:** RESOLVED in iteration 43. `nsslider_set_track_fill_color` added to objc_bridge.m;
calls `[[NSSliderCell] performSelector:@selector(setTrackFillColor:) withObject:]` guarded by
`respondsToSelector:`.  Orange tint_color visible in macOS dark capture (variant 4).  macOS light
shows reduced saturation due to platform blending -- non-blocking PASS_WITH_NOTES.

**Status:** OPEN (prior). Non-blocking for macOS PASS (track renders in system blue by
default; tint_color is silently ignored, which is better than a crash). Legibility
is maintained. The brand-override use case (custom track color on macOS) is
unimplemented.

**Symptom:** The `tint_color` property on `UI::Slider` is applied to
`UISlider.minimumTrackTintColor` in the UIKit renderer but has no equivalent in
the AppKit renderer. On macOS, the NSSlider track fill color is system-managed
(follows the accent color in System Preferences). The `tint_color` property is
silently ignored in `visit(UI::Slider)` in `appkit_renderer.cr`.

**Root cause:** AppKit's NSSlider does not expose a direct `-setMinimumTrackTintColor:`
selector (that is UIKit-only). The color can be set on `NSSlider` via `NSSliderCell`:
`[[slider cell] setTrackFillColor: nscolor]`. This selector exists on macOS 10.12.2+.

**Proposed fix:** In `visit(UI::Slider)` in `appkit_renderer.cr`, after the
existing `setDoubleValue:` call, add:
```
if tint = view.tint_color
  cell_ptr = LibObjCBridge.objc_send(ptr, sel("cell"))
  tint_ptr = LibObjCBridge.nscolor_rgba(tint.r, tint.g, tint.b, tint.a)
  LibObjCBridge.objc_send_id(cell_ptr, sel("setTrackFillColor:"), tint_ptr)
end
```
Verify that `nscolor_rgba` returns an NSColor pointer compatible with
`setTrackFillColor:` (it should, since NSColor is the required type).

**Affected slugs:** sliders (macOS tinted variant only). Default renders (system
blue track) are unaffected.

## Iteration 41 (sidebars) -- OPEN: NavigationSplitView detail column children not positioned in macOS outer NSView

**Status:** OPEN. Non-blocking for PASS_WITH_NOTES verdict.

**Symptom:** The macOS captures for `sidebars` show the detail column (right gray
area) as an empty region. The "Inbox selected" placeholder label passed as
`detail:` to `UI::NavigationSplitView` is accepted by the renderer but does not
appear in the screenshot because the outer `NSView` container uses a non-NSStackView
layout (`is_nsstack: false`) and `addSubview` without AutoLayout constraints. The
subview has frame (0,0,0,0) and renders invisibly.

**Root cause:** The `NavigationSplitView` visit method in `appkit_renderer.cr`
wraps the content/detail columns in the outer `NSView` by pushing the outer native
as a non-stack parent, calling `detail.accept(self)`, then popping. The
`push_native` path for non-NSStackView parents calls `LibObjCBridge.objc_add_subview`
but sets no frame or AutoLayout constraints on the child. The child view therefore
has zero size at render time.

**Proposed fix:** After accepting the sidebar and detail columns, apply explicit
AutoLayout constraints to position the sidebar glass view at leading edge and the
detail container at (sidebar_width, 0) filling the remaining width. This requires
the outer container itself to have a defined size (via the window's content view
frame) and both children to have `translatesAutoresizingMaskIntoConstraints = NO`.
Alternatively, replace the outer NSView with an NSStackView (horizontal orientation,
is_nsstack: true) and rely on NSStackView's distribution to place columns side by
side — the sidebar column's width constraint at 200pt would fix the left column
while the detail column expands to fill.

**Affected slugs:** sidebars (macOS detail column only). The sidebar column itself
renders correctly. The iOS path is unaffected (iPhone shows all content stacked
vertically in the UIStackView parent).

## Iteration 41 (sidebars) -- OPEN: UI::Image visit uses imageNamed: only; SF Symbols silently absent

**Status:** RESOLVED in this iteration. `objc_constrain_width` bridge helper added;
both renderers' `visit(UI::Image)` updated to prefer `systemImageNamed:` (iOS) /
`imageWithSystemSymbolName:accessibilityDescription:` (macOS) before falling back
to bundle `imageNamed:`. SF Symbols now render correctly in all four sidebar
captures. Noted here as a systemic gap: any view that embeds `UI::Image` with an
SF Symbol name was silently dropping the icon before this fix. Other slugs that
passed before may have missed SF Symbol rendering in their captures without
failing (because their primary shape check did not depend on embedded icons).
Recommended: add a `is_sf_symbol: Bool` property to `UI::Image` to make the
intent explicit and allow the renderer to assert the correct load path.

## Iteration 40 (sheets) -- OPEN: Grabber handle absent in inline validation path

**Status:** OPEN. Non-blocking for PASS_WITH_NOTES verdict.

**Symptom:** The iOS captures for `sheets` show no grabber handle (the thin gray
pill at the top of the sheet surface) in any appearance. HIG iOS: "Include a
grabber in a resizable sheet."

**Root cause:** The grabber is provided by `UISheetPresentationController.prefersGrabberVisible`
which is only active when the sheet is presented via `is_presented == true` and the
full UISheetPresentationController lifecycle is running. The inline validation path
(`surface_style: :grouped_card`, `is_presented == false`) renders a bare
UIVisualEffectView card without a UISheetPresentationController. The `shows_drag_indicator`
property on `UI::Sheet` maps to `prefersGrabberVisible` in production but has no
effect in the inline path.

**Proposed fix:** The uikit_renderer visit(UI::Sheet) grouped_card branch could
emit a synthetic grabber: a small `UIView` (width ~36pt, height ~5pt, corner
radius ~2.5pt, background `UIColor.tertiaryLabel`) placed as the first subview of
the inner UIStackView, centered horizontally via `setAlignment: .center`. This
would visually approximate the HIG grabber for inline screenshots without requiring
UISheetPresentationController. The production path (is_presented == true) continues
to use the system-provided grabber.

**Affected slugs:** sheets (inline validation path only). Production `is_presented`
path is unaffected.

## Iteration 38 (scroll-views) -- OPEN: Scroll indicator permanently absent in static validation captures

**Status:** OPEN. Non-blocking for PASS_WITH_NOTES verdict.

**Symptom:** All four validation captures (macos-light, macos-dark, ios-light,
ios-dark) show the scroll content area without any visible scroll indicator
knob, even when frame_height is set so content overflows (macOS arm). The HIG
reference illustration explicitly shows a thin vertical indicator bar on the
right edge of the scroll container.

**Root cause:** On macOS, NSScrollView uses an overlay-style NSScroller knob
(NSScrollerKnobStyleOverlay, default since macOS 10.7) that is only drawn when
the user actively scrolls (mouse wheel, trackpad gesture). The
cacheDisplayInRect: path fires before any scroll event, so the knob is in its
faded-out state and not composited into the bitmap. Calling `flashScrollers`
on the NSScrollView before cacheDisplayInRect: would force a brief indicator
flash, but the indicator would need to be drawn synchronously (not animated)
for the screenshot to capture it.

On iOS, UIScrollView's scroll indicator uses a UIView-based implementation
that is hidden (alpha=0) at rest and only made visible during active scroll
events. XCUITest screenshot captures the view hierarchy in its current render
state; at the moment the screenshot fires there has been no user scroll event,
so the indicator alpha remains 0.

**Impact:** The validation screenshot does not visually match the HIG
reference illustration's scroll indicator detail. The scroll mechanism itself
is functional at runtime; the gap is purely a static-capture limitation.

**Proposed fix (validation):** After cacheDisplayInRect: but before writing
the PNG on macOS, send `flashScrollers` to the NSScrollView and call
`displayIfNeeded` + a short `NSRunLoop runUntilDate:` cycle to allow the
indicator animation to reach its peak alpha. For iOS, trigger a programmatic
scroll (setContentOffset:animated:NO) to a non-zero offset before XCUITest
screenshots, then scroll back; the indicator will be briefly visible.

## Iteration 38 (scroll-views) -- OPEN: NSScrollView content viewport collapse without explicit frame_height

**Status:** OPEN. Non-blocking; documented as a developer requirement.

**Symptom:** Any UI::ScrollView embedded in a VStack or HStack without
`frame_height` set collapses to zero height at render time, rendering no
visible content. This is a usability trap that is easy to hit.

**Root cause:** NSScrollView (and UIScrollView) return a zero
intrinsicContentSize to Auto Layout because their content is, by definition,
arbitrarily large. An NSStackView parent that asks for intrinsicContentSize
receives {0,0} and allocates zero layout space to the scroll view. Setting
`frame_height` adds a priority-999 NSLayoutConstraint that gives the stack a
concrete measurement.

**Impact:** Developer must always set `frame_height` when embedding
UI::ScrollView in a VStack or HStack. Without it the scroll view renders
invisibly with no error or warning. This is not obvious from the API.

**Proposed fix:** Add a Crystal compiler-level precondition or warning log
when `frame_height == 0.0 && @stack.size > 0` in the renderer visit, so
developers see a runtime diagnostic rather than a silent invisible view.
Alternatively, document the requirement prominently in the component doc
Quickstart (done in iteration 38 components/scroll-views.md).

## Iteration 39 (search-fields) -- OPEN: UISearchBar collapses to icon when hosted outside UINavigationItem

**Status:** OPEN. Non-blocking; workaround applied in renderer (fixed width constraint).

**Symptom:** UISearchBar.intrinsicContentSize.width returns UIView.noIntrinsicMetric
(-1) when not embedded in a UINavigationItem. A UIStackView with
UIStackViewAlignmentFill does not stretch the search bar to fill the available
width; instead the bar collapses to a small icon-sized rect. This manifests in
the HIG validation showcase host and would affect any developer who places
UI::SearchField directly inside a UI::VStack without an explicit width context.

**Root cause:** UISearchBar is designed to be hosted inside UINavigationBar (via
UINavigationItem.searchController) or UIToolbar, where the superview provides
the width. When used standalone, its intrinsicContentSize.width is -1, and
UIStackView does not know to stretch it even with Fill alignment because Fill
only works when the child reports a valid intrinsicContentSize or has a constraint
that the stack can resolve.

**Workaround applied:** `src/ui/renderers/uikit_renderer.cr` visit(SearchField)
now calls `LibObjCBridge.objc_constrain_size(ptr, screen_width - 32.0, 44.0)`
after `apply_common_properties`. This produces a concrete width for the stack
and a 44pt height matching the HIG interactive minimum. The fixed constraint
is a validator-host artifact; production apps should use UISearchController.

**Impact:** The fixed-width constraint is appropriate for standalone showcase
use but may be wrong for apps that want UISearchBar at a custom width. Developers
embedding UI::SearchField should set an explicit frame constraint or use it
within a UINavigationItem context.

**Proposed fix (long-term):** Add a `frame_width` property to UI::SearchField
(matching the `frame_height` / `frame_width` pattern on UI::ScrollView) so
developers can specify the width explicitly. When both properties are 0.0
(unset), the renderer could fall back to `objc_screen_width - 32.0` as a
reasonable default rather than a hardcoded fallback.

## Iteration 37 (pull-down-buttons) -- OPEN: Destructive menu item red text requires NSMutableAttributedString bridge helpers

## Iteration 37 (pull-down-buttons) -- OPEN: Destructive menu item red text requires NSMutableAttributedString bridge helpers

**Status:** OPEN. Non-blocking for PASS_WITH_NOTES verdict.

**Symptom:** Pull-down menu items marked `is_destructive: true` are added to the
NSPopUpButton / UIMenu with their plain text labels, but without the HIG-required
red text (NSColor / UIColor systemRed). The HIG states: "Menus use red text to
highlight actions that you identify as potentially destructive."

**Root cause (macOS):** Setting red text on an NSMenuItem requires either
`setAttributedTitle:` with an NSAttributedString containing NSForegroundColorAttributeName,
or setting the item's `attributedTitle` property. Both paths require creating an
NSMutableAttributedString and an NSDictionary of attributes. The ObjC bridge
currently has no helpers for NSMutableAttributedString creation or NSDictionary
construction beyond single-selector calls. The code in visit(UI::MenuButton) has a
comment noting this gap.

**Root cause (iOS):** On iOS, UIMenu constructs UIAction objects. Setting a
destructive action requires `UIMenuElementAttributes.destructive` on the UIAction.
The renderer currently builds the visual button chrome (UIButton) without wiring a
UIMenu with attribute flags, because the UIMenu/UIAction API requires multiple
message-send steps not yet exposed via bridge helpers.

**Impact:** Destructive items are added to the menu and are functional; they simply
do not render in red. A user performing the action (e.g., "Delete") will not be
warned visually before the confirmation sheet / action sheet appears.

**Proposed fix:** Add bridge helper `nsmutableattrstring_with_foreground_color(str, color)`
to objc_bridge.m that creates an NSMutableAttributedString with a given NSColor as
NSForegroundColorAttributeName. Then call `setAttributedTitle:` on the NSMenuItem in
visit(UI::MenuButton) when `item.is_destructive`. For iOS, add `uiaction_destructive(title, handler)`
helper that creates a UIAction with UIMenuElementAttributesDestructive.

## Iteration 37 (pull-down-buttons) -- OPEN: macOS prominent pull-down style not visually elevated

**Status:** OPEN. Non-blocking for PASS_WITH_NOTES verdict.

**Symptom:** UI::MenuButton with is_pull_down: true and button_style: :prominent
renders with identical NSPopUpButton bezel on macOS as the :default style. There is
no visual differentiation (no blue fill, no border highlight) between the "Export"
prominent button and the "Add" / "..." default buttons.

**Root cause:** NSPopUpButton does not support `setBezelColor:` (an NSButton-only
API, macOS 12+). NSPopUpButton inherits from NSButton but the bezel color override
has no effect on NSPopUpButton's rendering. There is no standard AppKit API to
produce a filled-capsule tinted NSPopUpButton equivalent to iOS
UIButtonConfiguration.filledButtonConfiguration.

**Impact:** In toolbar contexts where the prominent pull-down should be visually
elevated as the primary action (e.g., "Export" above "More options"), macOS renders
all pull-downs with identical weight.

**Proposed fix:** For macOS prominent pull-down, replace NSPopUpButton with a
two-view composition: a custom NSButton (bezel style NSBezelStyleRoundRect with
setBezelColor: set to the theme primary) used as the visible trigger, layered over
a hidden NSPopUpButton that receives the click and shows its menu. Alternatively,
expose a `has_border` flag that uses NSButton.keyEquivalent styling to promote the
button visually.

## Iteration 35 (popovers) -- OPEN: Arrow/tail absent in inline validation path

**Status:** OPEN. Non-blocking for PASS_WITH_NOTES verdict; popover glass surface
and content are HIG-faithful.

**Symptom:** All four validation captures (macos-light, macos-dark, ios-light,
ios-dark) show the popover glass surface without an arrow/tail pointing at the
trigger. The HIG reference illustration shows a small upward-pointing triangle
(arrow) protruding from the top edge of the surface, anchored to the trigger
element above.

**Root cause (macOS):** The NSPopover arrow is provided by the NSPopover
presentation layer (`showRelativeToRect:ofView:preferredEdge:`), not by any
NSView subclass. The inline validation path builds an NSVisualEffectView directly
into the host window's view tree, bypassing NSPopover entirely. There is no
NSView API to attach an arrow to a plain NSVisualEffectView.

**Root cause (iOS):** The UIPopoverPresentationController arrow is provided by
UIKit's presentation infrastructure, not by UIView or UIVisualEffectView. The
inline path builds a UIVisualEffectView in the host view tree, bypassing
UIPopoverPresentationController. There is no UIView API to attach a native arrow
to a plain UIVisualEffectView.

**Impact:** The rendered surface is visually identifiable as a floating container
(rounded corners, glass material, distinct from host background), but lacks the
directional arrow that distinguishes a popover from a general card. The HIG
guidance "Make sure a popover's arrow points as directly as possible to the element
that revealed it" (Popovers / Best practices) cannot be verified in the inline path.

**Proposed fix (validation-only):** Add a small `UI::Label` with the Unicode
down-arrow character (U+25BC, solid triangle, ~10pt) as a sibling view above the
popover surface in the host case arm. This would be a purely visual cue in the
validation render -- not a native arrow rendered by the platform. Log as
validation-only approximation.

**Proposed fix (production):** For production usage, the renderer must be updated
to support a presented path: detect `view.is_presented == true`, obtain the anchor
view's native pointer, and call `NSPopover showRelativeToRect:ofView:preferredEdge:`
(macOS) or wire up `UIPopoverPresentationController.sourceView` /
`.sourceRect` / `.permittedArrowDirections` (iOS) via the ObjC bridge. This
requires the presenter object to hold a reference to the anchor view's NSView/UIView
handle, which `UI::PopoverPresenter` already models but the renderers have not yet
wired.

## Iteration 35 (popovers) -- NOTE: UI::Toggle iOS visit does not emit label text

**Status:** OPEN, pre-existing. Non-blocking for popovers verdict (the gap is in
visit(UI::Toggle), not visit(UI::Popover)).

**Symptom:** In iOS popovers (and any other iOS host that embeds `UI::Toggle`),
the UISwitch control renders without its adjacent label text ("Show Completed",
"Show Archived"). Only the switch chrome is visible.

**Root cause:** `visit(UI::Toggle)` in `uikit_renderer.cr` calls
`alloc_init("UISwitch")` and `setOn:animated:` but does not create a sibling
UILabel for `view.label`. On macOS, NSButton with NSButtonTypeSwitch renders its
`setTitle:` text natively as the checkbox label. UISwitch has no built-in label
slot -- the label must be a separate UILabel in an HStack alongside the switch.

**Proposed fix:** In `visit(UI::Toggle)` (UIKit path), create a horizontal
UIStackView wrapping a UILabel (view.label text, ~15pt regular, UIColor.label)
and the UISwitch. Emit the stack rather than the bare switch. This matches the
iOS Settings row pattern used throughout HIG guidance.

## Iteration 34 (pickers) -- OPEN: UIPickerView has no datasource wiring from Crystal

**Status:** OPEN. Non-blocking for PASS_WITH_NOTES verdict; wheel rows are empty.

**Symptom:** In iOS captures, the UIPickerView selection band is visible but all
wheel rows (above and below the selection band) render blank. No option strings
appear in the spinning column.

**Root cause:** `visit(UI::Picker)` in `uikit_renderer.cr` calls
`alloc_init("UIPickerView")` and `apply_common_properties` but does not set a
`dataSource` or `delegate`. UIKit requires a `UIPickerViewDataSource` (protocol)
and `UIPickerViewDelegate` (protocol) to populate rows. These cannot be satisfied
by a plain `NSObject` subclass without runtime protocol registration and method
dispatch back into Crystal for `numberOfComponentsInPickerView:`,
`numberOfRowsInComponent:`, and `titleForRow:forComponent:`.

**Impact:** iOS picker rows are empty. Selection band is visible, establishing the
control's form. macOS NSPopUpButton is unaffected (it self-populates via
`addItemWithTitle:` calls already in the renderer).

**Proposed fix:** Register a `CrystalPickerDataSource` ObjC class at renderer
startup (following the existing `CrystalActionDispatcher` pattern in
`objc_bridge.m`). Store the options array in a C struct accessible via a tag.
Wire `numberOfComponents -> 1`, `numberOfRows -> options.count`,
`titleForRow:forComponent: -> options[row]`. Set as the picker's `dataSource`
and `delegate`. The Crystal `on_change` callback would fire from
`pickerView:didSelectRow:inComponent:` via `crystal_ui_callback_dispatch`.

## Iteration 34 (pickers) -- RESOLVED: VStack dark-mode background not baked

**Status:** RESOLVED in iter-34. Systemic fix applied to `appkit_renderer.cr`.

**Symptom:** `pickers-macos-dark.png` first captured as a blank white frame --
NSPopUpButton and Label were invisible in the dark appearance capture.

**Root cause:** `visit(UI::VStack)` did not apply `wantsLayer:YES` + explicit
`layer.setBackgroundColor:` (CGColorRef) keyed off `HIG_APPEARANCE`. The
`cacheDisplayInRect:toBitmapImageRep:` offscreen path uses the window's
`effectiveAppearance` via `performAsCurrentDrawingAppearance:` for control drawing
but the layer background defaults to transparent (renders as white in the PNG).
Without an explicit fill, NSTextField labels (near-white in DarkAqua) are invisible
against the white background.

**Fix:** Added `setWantsLayer:YES` + `nscolor_rgba -> .CGColor -> layer.
setBackgroundColor:` to `visit(UI::VStack)` in `appkit_renderer.cr`, following
the identical pattern established in `visit(UI::ListView)` (iter-21) and
`visit(UI::Card)` (iter-6). Dark fill: ~0.12 RGB; light fill: 1.0 RGB.

**IMPORTANT:** `layer.setBackgroundColor:` accepts a `CGColorRef` (Core Graphics),
NOT an `NSColor`. Passing `NSColor*` to this method causes a signal 11 crash in
`RIPColorConvertColorComponents` inside CoreGraphics. Always call
`nscolor.CGColor` first and pass the result.

**Impact:** All VStack-based slugs with dark-mode captures now bake correctly.
This fix was discovered during the `pickers` iteration; any prior dark-mode
captures of VStack-wrapped views (e.g. `sliders`, `steppers`, `segmented-controls`,
`progress-indicators`, `activity-indicators`) should be re-captured on the next
iteration that touches those slugs.

## Iteration 33 (menus) -- RESOLVED: objc_bridge.m UIView/UILayoutPriorityRequired missing TARGET_OS_OSX guard

**Status:** RESOLVED in iter-33.

**Symptom:** `make -C samples/cross_platform/macos_host build` failed with 7
clang errors: `unknown type name 'UIView'`, `use of undeclared identifier 'UIView'`,
`use of undeclared identifier 'UILayoutPriorityRequired'` -- all in
`objc_constrain_equal_width()` at lines 334-340 of `src/ui/native/objc_bridge.m`.

**Root cause:** The `objc_constrain_equal_width` function was written for the iOS
renderer (iter-32 fix for UIStackView fill-alignment circular dependency) using
`UIView *` and `UILayoutPriorityRequired` directly, without wrapping in a
`#if TARGET_OS_OSX` / `#else` block. The same `.m` file is compiled for both
macOS (AppKit only) and iOS (UIKit only) via `-target` flag, but the macOS
compilation path does not import UIKit so `UIView` and `UILayoutPriorityRequired`
are undefined.

**Fix:** Changed `UIView *c` and `UIView *p` to `BridgeView *c` and `BridgeView *p`
(BridgeView is typedef'd to NSView on macOS, UIView on iOS in the file's preamble).
Wrapped the priority assignment in `#if TARGET_OS_OSX` /
`NSLayoutPriorityRequired` / `#else` / `UILayoutPriorityRequired` / `#endif`.

**Impact:** No renderer behavior change. The function is only called from the UIKit
renderer (iOS path) which is never compiled with the macOS host. The fix restores
the macOS host build without affecting iOS functionality.

## Iteration 33 (menus) -- NOTE: checkmark/selected-state idiom is naturally expressible

**Status:** No gap opened. The `menus` slug required a checkmark indicator for
"Sort By" pop-up selected state. This is naturally expressible using a `UI::Label`
with the U+2713 checkmark character at 13pt semibold before the item row. The Label
inherits `NSColor.labelColor` / `UIColor.label` semantic color (near-black in light,
near-white in dark) which correctly distinguishes from the system-blue button labels
in both appearances. No additional `UI::MenuButton` property or renderer change is
needed for the checkmark pattern at this validation iteration.

If a future iteration requires the checkmark to be part of the `UI::MenuButton.MenuItem`
record (for native `NSMenuItem.state = NSControlStateValueOn` / `UIAction` checkmark
accessory), that would require: (a) add `is_selected: Bool = false` to the MenuItem
record; (b) update `visit(UI::MenuButton)` in both renderers to set the native state
when a full-width-row menu surface is implemented. Not needed while the pill-bezel
approximation (gaps.md iter-25 proposal) is in effect.

## Iteration 32 (lists-and-tables) -- RESOLVED: HStack UIStackView collapse inside ListView UIStackView on iOS

**Status:** RESOLVED in iter-32. lists-and-tables verdict updated to PASS_WITH_NOTES.

**Resolution:** The root cause was NOT a TAMIC timing issue but a circular
dependency in UIKit's compressed-fitting pass. UIStackView `alignment: fill`
adds `subview.trailing = stack.trailing` constraints. For UIStackView arranged
subviews that contain a `UI::Spacer` (UIView with UIViewNoIntrinsicMetric
width), the inner stack has no intrinsic width, so the outer stack's width is
also indeterminate -- circular. Fix: after each list item's `item.accept(self)`
call, apply `widthAnchor constraintEqualToConstant: (UIScreen.mainScreen.
bounds.width - 32.0)` to the last child of the list's native stack. This breaks
the circular dependency. New bridge function `objc_screen_width()` returns
`[UIScreen mainScreen].bounds.size.width`.

Same fix applied to InsetGrouped items with `screen_width - 64.0` (additional
inset for card margin). InsetGrouped dark mode also fixed: replaced
`layer.setBackgroundColor: UIColor.CGColor` (static light-mode snapshot) with
`UIView.setBackgroundColor: UIColor` (dynamic, appearance-tracking).

**Original symptom (preserved for reference):** In the UIKit renderer's `visit(UI::ListView)` list-mode branch,
`section.items.each_with_index` calls `item.accept(self)` for each HStack row
item. The HStack visitor builds a UIStackView (UILayoutConstraintAxisHorizontal=0),
adds UILabel arranged subviews to it, then calls `push_native(hstack_native)`.
`push_native` calls `addArrangedSubview:(hstack_ptr)` on the outer list
UIStackView (UILayoutConstraintAxisVertical=1). On macOS the equivalent
NSStackView path renders all rows correctly. On iOS the HStack UIStackViews
appeared to collapse to zero visible height.

**Symptom:** In the UIKit renderer's `visit(UI::ListView)` list-mode branch,
`section.items.each_with_index` calls `item.accept(self)` for each HStack row
item. The HStack visitor builds a UIStackView (UILayoutConstraintAxisHorizontal=0),
adds UILabel arranged subviews to it, then calls `push_native(hstack_native)`.
`push_native` calls `addArrangedSubview:(hstack_ptr)` on the outer list
UIStackView (UILayoutConstraintAxisVertical=1). On macOS the equivalent
NSStackView path renders all rows correctly. On iOS the HStack UIStackViews
appear to collapse to zero visible height: no UILabel text appears within
the row area, though 0.5pt separator UIViews between rows ARE visible as faint
marks.

The "Settings" section header UILabel (emitted directly via
`emit(header_ptr, "UILabel[list-header]")`) IS visible, confirming that directly-
emitted UILabels are added correctly as arranged subviews. The failure is
specific to UIStackView subviews of UIStackView.

**Root cause hypothesis:** UIStackView's autolayout engine requires that each
arranged subview's `translatesAutoresizingMaskIntoConstraints` be set to NO
before `addArrangedSubview:` is called. UIStackView sets TAMIC=NO automatically
for arranged subviews, but there may be a timing issue in the bridge: if the
HStack UIStackView has already had TAMIC set by an earlier path, or if
UIStackView's intrinsicContentSize is queried before UILabel arranged subviews
are added (layout pass timing), the HStack collapses. On NSStackView (macOS)
this timing issue does not arise because NSStackView defers layout until the
run loop.

**Investigation steps:**
1. Add a log in the iOS host's Swift layer to print `arrangedSubviews.count`
   and `intrinsicContentSize` on the outer list UIStackView after the Crystal
   renderer completes. Verify HStack UIStackViews are present and report
   non-negative intrinsicContentSize.
2. Try setting `item_spacing = 0.0` on the outer list UIStackView to see if
   the issue is related to spacing causing ambiguity.
3. Try adding explicit height constraints on the HStack UIStackView via
   `objc_constrain_size(hstack_ptr, 0.0, 44.0)` (44pt minimum touch target)
   before returning from `visit(UI::HStack)`.
4. Compare with `visit(UI::Form)` which uses a UIStackView-of-UIStackViews
   structure via direct `addArrangedSubview:` calls and appears to work.

**Proposal A (explicit HStack height constraint):** After `visit(UI::HStack)`
sets up the UIStackView and before `push_native`, call `objc_constrain_size`
with width=0 and height=44.0 (HIG minimum). This ensures UIStackView allocates
height. Risk: overrides HIG-adaptive sizing for rows with taller content.

**Proposal B (UITableView for list mode):** Replace the UIStackView-of-HStack-
UIStackViews approach with a `UITableView` (plain or inset-grouped style). This
requires a data-source delegate bridge (similar to NSCollectionView, which is
the goal for Grid mode). UITableViewCell provides intrinsicContentSize
automatically via UILabel auto-layout. This is the HIG-correct production path.

**Proposal C (post-render layout force):** After all children are added to the
outer UIStackView, call `setNeedsLayout` and `layoutIfNeeded` on the outer
UIStackView. If UIKit defers layout until after the Swift layer has added the
UIStackView to the window, forcing layout before handoff might resolve the
size issue.

**Files to update:**
- `src/ui/renderers/uikit_renderer.cr` -- `visit(UI::ListView)` list-mode
  branch: add explicit HStack height constraint (Proposal A) or implement
  UITableView dispatch (Proposal B) or add post-render layout force (Proposal C).
- `src/ui/native/objc_bridge.m` -- may need new bridge function for
  `layoutIfNeeded` or UITableView data-source registration.

**Not a foundations-doc change.** Leave for human review.

---

## Iteration 31 (lists-and-tables) -- Open: ListView section headers not styled as HIG uppercase footnote

**Status:** Open. Non-blocking. lists-and-tables verdict is now PASS_WITH_NOTES
(iter-32). Documented as Deviation 4 in the validation report.

**Symptom:** `UI::ListView::Section.header` text is emitted as a plain
NSTextField (macOS) or UILabel (iOS) in the default system font at the default
size. HIG-standard section headers in UITableView.Style.grouped and
.insetGrouped use:
- 13pt regular
- UIColor.secondaryLabelColor
- Uppercase letter-spacing style on iOS
- 8pt top padding above the section header text

The current renderer uses NSColor.labelColor (macOS) and UIColor.labelColor
(iOS) -- the Primary role -- which renders section headers at full contrast,
same as row text. They should use the Secondary role to distinguish them from
row content.

**Proposal:** In `visit(UI::ListView)` when emitting a section header, apply:
- Font size 13pt (matching HIG footnote baseline)
- `text_color_role = LabelRole::Secondary` (resolved via nscolor_label_secondary)
- Text transformation to uppercase on iOS (via NSAttributedString
  NSKernAttributeName + NSTextTransformAttributeName, or via a bridge function
  that calls `[nsstring uppercaseString]`)

**Files to update:**
- `src/ui/renderers/appkit_renderer.cr` -- `visit(UI::ListView)` header emit:
  set 13pt font via `nsfont_system(13.0)` and secondary color via
  `nscolor_label_secondary`.
- `src/ui/renderers/uikit_renderer.cr` -- same.

**Not a foundations-doc change.** Leave for human review.

---

## Iteration 31 (lists-and-tables) -- Open: No row accessory API (chevron, switch, info badge)

**Status:** Open. Systemic gap. HIG "Lists and tables" defines five row
accessory types (disclosure indicator / chevron.right, detail disclosure
button / info.circle, checkmark, switch, right-aligned value label). The
current `UI::ListView` has no accessory API: rows are free-form `UI::View`
instances (typically `UI::HStack`) and the developer must manually construct
the trailing element.

**Impact:** The U+276F glyph used as a disclosure-indicator stand-in in the
host arm is not the true native UITableViewCell.AccessoryType.disclosureIndicator
rendered by UITableView. The glyph is correct in appearance (right-pointing
chevron) but is a plain Unicode character in a UILabel rather than the
SF Symbol "chevron.right" rendered at the system-specific size and color.

**Proposal:** Add a `UI::ListRowAccessory` enum or a `trailing_accessory`
property to `UI::ListView::Section.Item` (or introduce a new
`UI::ListRow` view wrapper). Values:
- `:disclosure` -- chevron.right SF Symbol, UIColor.tertiaryLabelColor
- `:value(String)` -- right-aligned label in secondaryLabelColor
- `:check` -- checkmark SF Symbol, tintColor
- `:toggle(Bool, Proc)` -- UISwitch (mapped to UI::Toggle visit)
- `:none` -- no trailing element

In the AppKit renderer, a true disclosure indicator maps to the chevron.right
NSImage (SF Symbol). In UIKit, `UITableViewCell.accessoryType =
.disclosureIndicator` is the native path, but this requires UITableView.

**Files to update:**
- `src/ui/views/list_view.cr` -- add `UI::ListRow` wrapper or `accessory`
  field on `Section`.
- `src/ui/renderers/appkit_renderer.cr` -- handle accessory in list row emit.
- `src/ui/renderers/uikit_renderer.cr` -- same.

**Not a foundations-doc change.** Leave for human review.

---

## Iteration 31 (lists-and-tables) -- Open: No NSTableView / UITableView column-table mode

**Status:** Open. HIG "Lists and tables" explicitly covers multi-column tables
(NSTableView on macOS with column headers, sortable columns, alternating row
colors). `UI::ListView` has no column-table mode. The `layout: Grid` mode
renders a fixed-column grid (NSStackView row-of-rows), not an NSTableView with
sortable column headers.

**Impact:** HIG macOS guidance: "When it provides value, let people click a
column heading to sort a table view based on that column." and "Let people
resize columns." These features require NSTableView (not NSStackView). The
current renderer cannot produce a sortable multi-column table.

**Proposal:** Add `ListLayout::Table` to the `ListLayout` enum. In AppKit
renderer, `visit(UI::ListView)` with `layout == ListLayout::Table` emits
`NSTableView` (embedded in NSScrollView) with `NSTableColumn` instances for
each column defined via a new `columns` property (distinct from the current
`columns : Int32` used for Grid mode). Column click → sort callback wirable
via a Crystal delegate bridge.

**Files to update:**
- `src/ui/view.cr` -- add `ListLayout::Table`.
- `src/ui/views/list_view.cr` -- add `table_columns : Array(TableColumn)?`
  record.
- `src/ui/renderers/appkit_renderer.cr` -- `visit(UI::ListView)` Table branch.
- `src/ui/renderers/uikit_renderer.cr` -- Table branch (UITableView with
  header supplementary view for column headers, since UITableView is
  single-column by convention; consider UICollectionView with compositional
  layout for true multi-column on iOS).

**Not a foundations-doc change.** Leave for human review.

## Iteration 30 (labels) -- Partial resolve of iter-12 UI::Label gaps

**Status:** Partially resolved. Iteration-18 landed `text_color_role :
LabelRole?` on `UI::Label` and wired all four `LabelRole` values to
`NSColor.labelColor` / `UIColor.labelColor` siblings in both renderers
and the ObjC bridge. The iteration-19 labels validation confirms the
contract: all four LabelRole values render with visibly distinct luminance
in both light and dark appearances on macOS (PASS) and on the visible
rows of the iOS gallery (PASS_WITH_NOTES -- iOS scrollview clip is a
host infrastructure gap, not a renderer gap).

**Still open from iter-12:**

1. **`font_style : Symbol?` / Dynamic Type** -- Not implemented. `UI::Label`
   has no `:large_title` / `:headline` / `:body` etc. style knob. The
   renderers call `systemFontOfSize:weight:` (fixed-point), not
   `preferredFont(forTextStyle:)`. Users with accessibility Text Size
   preferences see no label resizing. The iter-12 gaps.md entry at the
   bottom of this file has the full proposal.

2. **`selectable : Bool`** -- Not implemented. HIG Best practices: "Make
   useful label text selectable." The `setSelectable: YES` path on
   NSTextField (macOS) and the UIMenuController "Copy" interaction on iOS
   (UILabel with `isUserInteractionEnabled = YES` + UILongPressGestureRecognizer)
   are not wired. The iter-12 gaps.md entry has the full proposal.

**Not a foundations-doc change.** Leave for human review.

---

## Iteration 29 -- Open: SF Symbol names not resolved by NSImage imageNamed: / UIImage imageNamed:

**Status:** Open. Non-blocking for image-views PASS_WITH_NOTES (deviation 1
in the report).

**Symptom:** `UI::Image.new("star.fill")` and `UI::Image.new("photo")` call
`NSImage imageNamed:"star.fill"` (macOS) and `UIImage imageNamed:"star.fill"`
(iOS) respectively. On macOS 26, `NSImage imageNamed:` does NOT resolve SF
Symbol system names -- those require `NSImage(systemSymbolName:
accessibilityDescription:)` (macOS 11+). On iOS, `UIImage imageNamed:` does
resolve SF Symbol names (it falls back to `UIImage(systemName:)` internally
in iOS 13+), but the host bundle must include the UIKit framework. The
NSImageView / UIImageView collapse to zero size when the image returns nil.

**Root cause:** `UI::Image` has a single `source : String` property used for
both bundle-asset names AND SF Symbol names. The renderer makes no distinction.

**Proposal:** Add `symbol_name : String?` to `UI::Image` (or detect by
convention: if `source` contains no path separator and no extension, treat as
an SF Symbol name). In `appkit_renderer.cr:visit(UI::Image)`, branch:
```
if symbol_name = view.symbol_name
  nsimage_cls = LibObjCBridge.objc_getClass("NSImage")
  sym_str = LibObjCBridge.nsstring_from_cstr(symbol_name.to_unsafe)
  nil_str = LibObjCBridge.nsstring_from_cstr("".to_unsafe)
  nsimage = LibObjCBridge.objc_send_id_id(nsimage_cls,
    sel("imageWithSystemSymbolName:accessibilityDescription:"),
    sym_str, nil_str)
  LibObjCBridge.objc_send_id(ptr, sel("setImage:"), nsimage) unless nsimage.null?
end
```
In `uikit_renderer.cr:visit(UI::Image)`, branch:
```
if symbol_name = view.symbol_name
  uiimage_cls = LibObjCBridge.objc_getClass("UIImage")
  sym_str = LibObjCBridge.nsstring_from_cstr(symbol_name.to_unsafe)
  uiimage = LibObjCBridge.objc_send_id(uiimage_cls, sel("systemImageNamed:"), sym_str)
  LibObjCBridge.objc_send_id(ptr, sel("setImage:"), uiimage) unless uiimage.null?
end
```

**Files to update:**
- `src/ui/views/image.cr` -- add `symbol_name : String?`
- `src/ui/renderers/appkit_renderer.cr` -- `visit(UI::Image)`: branch on symbol_name
- `src/ui/renderers/uikit_renderer.cr` -- `visit(UI::Image)`: branch on symbol_name
- `src/ui/native/objc_bridge.m` -- may need `objc_send_id_id` for the two-arg selector

**Not a foundations-doc change.** Leave for human review.

---

## Iteration 29 -- Open: UIView-based shapes (Circle, Rectangle, RoundedRectangle) collapse in UIStackView on iOS

**Status:** Open. Non-blocking for image-views PASS_WITH_NOTES (deviation 3
in the report). May affect other slugs that embed shapes in VStack/HStack on iOS.

**Symptom:** `UI::Circle`, `UI::Rectangle`, and `UI::RoundedRectangle` render
as plain UIView subclasses with `intrinsicContentSize` = (-1, -1).
UIStackView allocates zero size to arranged subviews with no intrinsic size
and no explicit NSLayoutConstraints. The `objc_constrain_size` approach
(TAMIC:NO + priority-999 width/height NSLayoutConstraints set BEFORE
addArrangedSubview:) was attempted but produced UILabel layout failures:
label arranged subviews lost their layout when mixed with constrained plain-
UIView arranged subviews. On macOS, NSStackView handles mixed TAMIC:NO +
intrinsicContentSize views without conflict; on iOS UIStackView does not.

**Root cause:** UIStackView's constraint solver interprets priority-999
size constraints on some arranged subviews as flexible, causing ambiguity
that collapses adjacent label views. Priority-1000 (required) constraints
conflict with UIStackView's own alignment constraints.

**Proposal A (runtime subclass):** Use `objc_allocateClassPair` to register a
UIView subclass at runtime that overrides `intrinsicContentSize` to return the
declared width/height for Circle/Rectangle/RoundedRectangle. This avoids
NSLayoutConstraint conflicts entirely -- UIStackView uses intrinsicContentSize
for sizing, not explicit constraints.

**Proposal B (post-layout pass):** After adding all children to UIStackView
via `addArrangedSubview:`, add a second pass that calls
`widthAnchor.constraintEqualToConstant:` and
`heightAnchor.constraintEqualToConstant:` on the shape views. Since UIStackView
has already set TAMIC:NO on all arranged subviews by then, these constraints
should not conflict. Requires a two-pass visitor or a deferred constraint queue.

**UPDATE (iter-32):** The lists-and-tables fix used `objc_send_1d_ret_id` to
call `widthAnchor constraintEqualToConstant: (screen_width - 32)` on list item
UIStackViews AFTER `item.accept(self)` completes and the child is already an
arranged subview. This post-visit, constant-constraint approach proved safe:
UIStackView had already set TAMIC:NO on the child, and the constant constraint
did not conflict with adjacent label views. The same approach should work for
shapes: after `visit(UI::Circle)` returns (having added the shape UIView as
an arranged subview), apply BOTH `widthAnchor constraintEqualToConstant: w`
and `heightAnchor constraintEqualToConstant: h` using the shape's declared
`width`/`height` properties. This avoids the priority-999 conflict that
Proposal B's description was concerned about -- constant constraints at
priority-1000 on plain UIViews (not UIStackViews) appear safe alongside
UIStackView's internal alignment constraints when applied after addArrangedSubview.
The iter-32 fix provides a concrete working pattern to adapt.

**Files to update:**
- `src/ui/native/objc_bridge.m` -- add `objc_register_fixed_size_view_class`
  (Proposal A) or `objc_add_arranged_size_constraints` post-pass (Proposal B)
- `src/ui/renderers/uikit_renderer.cr` -- Circle/Rectangle/RoundedRectangle
  visit methods

**Not a foundations-doc change.** Leave for human review.

## Iteration 28 -- Open: iOS host window clips bottom group on tall menu surfaces

**Status:** Open. Non-blocking for edit-menus PASS_WITH_NOTES (deviation 3 in
the report).

**Symptom:** For the edit-menus slug (and potentially other tall menu-surface
slugs: context-menus, dock-menus), the iPhone simulator host window height causes
the last group (the fourth item group after three separators) to be partially
clipped below the visible glass card area. Items 1-7 are visible; the final
separator and Share button are below the viewport. This is confirmed non-critical
because the macOS captures show the full card and all nine items correctly.

**Root cause:** The iOS host's root UIStackView is sized by the window's safe
area. For slugs where the inline glass card is taller than the safe area height
at standard iPhone zoom, bottom items are clipped. The host does not use
UIScrollView for the component preview, so overflow is clipped rather than
scrollable.

**Proposal:** Wrap the component preview in a UIScrollView in the iOS host
(CrystalHIGHost Swift side) when the rendered NativeView height exceeds the
safe area height. Alternatively, increase the host window minimum height for
menu-surface slugs via the slug's metadata in worklist.json.

**Files to update:**
- `samples/cross_platform/ios_host/ContentView.swift` (or equivalent UIViewController):
  embed the Crystal-rendered UIView in a UIScrollView if height > safeAreaHeight.
- Alternatively: `scripts/run_ios_hig_tests.sh` -- set device to a larger
  iPhone model (iPhone 16 Pro Max) for tall-card slugs.
- Re-capture `edit-menus-ios-light.png` and `edit-menus-ios-dark.png` once fixed.

**Not a foundations-doc change.** Leave for human review.

---

## Iteration 28 -- Open: Menu rows lack right-aligned keyboard shortcut affordance in native NSMenu

**Status:** Open. Non-blocking for edit-menus PASS_WITH_NOTES; keyboard shortcut
labels are rendered via the macOS host arm workaround (right-aligned UI::Label in
HStack Spacer). Confirmed legible in both macOS appearances.

**Symptom:** The edit-menus macOS host arm renders keyboard shortcut labels
(Cmd-X, Cmd-C, Cmd-V, Cmd-A, Cmd-F) as secondary gray `UI::Label` instances
inside an `UI::HStack` with a `UI::Spacer` pushing them to the trailing edge.
In a real `NSMenu`, shortcut display is a property of `NSMenuItem`:
`setKeyEquivalent:(@"x")` + `setKeyEquivalentModifierMask:(NSEventModifierFlagCommand)`.
The system then renders the shortcut glyph automatically at the standard
inset with the correct glyph font (SF Mono for the Command key, etc.). The
label workaround produces correctly-placed gray text that communicates the
shortcut, but uses plain Unicode (\u2318X) rather than the system shortcut
rendering.

**Impact:** Minor visual deviation from native NSMenu shortcut typography. In
macOS screenshots the shortcut labels are legible and correctly positioned.
Non-legibility-impairing.

**Proposal:** When `UI::MenuButton` emits `NSMenuItem` instances (per the
`UI::ContextMenu` proposal in gaps.md iteration 25), set `keyEquivalent` and
`keyEquivalentModifierMask` directly on each `NSMenuItem` rather than using
label workarounds. This removes the need for the HStack/Spacer/Label shortcut
pattern in the host arm.

**Files to update (when UI::ContextMenu is implemented):**
- `src/ui/renderers/appkit_renderer.cr` -- `visit(UI::ContextMenu)`: for each
  item with a `key_equivalent` field, call `setKeyEquivalent:` and
  `setKeyEquivalentModifierMask:` on the emitted `NSMenuItem`.
- `src/ui/views/context_menu.cr` (proposed) -- add `key_equivalent : String?`
  and `key_equivalent_modifier : Symbol = :command` to the `Item` record.

**Not a foundations-doc change.** Leave for human review.

---

## Iteration 26 -- Open: UI::DisclosureGroup uses bezelStyle=disclosure for both triangle and push-disclosure shapes on macOS

**Status:** Open. Non-blocking for disclosure-controls PASS_WITH_NOTES (deviation 1 in the report).

**Symptom:** The macOS `visit(UI::DisclosureGroup)` in `appkit_renderer.cr` emits
`NSButton.bezelStyle = 5` (disclosure) for all instances of `UI::DisclosureGroup`.
The HIG defines two distinct NSButton bezel styles for disclosure:
- `NSButton.BezelStyle.disclosure` (value 5): used in list/outline contexts
  (Finder column list, Keynote export). Triangle points right when collapsed,
  down when expanded.
- `NSButton.BezelStyle.pushDisclosure` (value 23): used in dialog "Show More"
  contexts (macOS Save sheet). Different visual shape (pill-style button).

The current implementation renders both shapes with bezelStyle=5. The visual
difference between the two styles is minor (both show a rotating triangle).
Non-legibility-impairing.

**Root cause:** `UI::DisclosureGroup` has no `style` property to distinguish
the two shapes. The renderer defaults to bezelStyle=5 for all instances.

**Proposal:** Add `style : Symbol = :triangle` to `UI::DisclosureGroup`. In
`appkit_renderer.cr:visit(UI::DisclosureGroup)`, map:
- `:triangle` -> bezelStyle=5 (`NSButton.BezelStyle.disclosure`)
- `:push_disclosure` -> bezelStyle=23 (`NSButton.BezelStyle.pushDisclosure`)

iOS does not require a corresponding change: both shapes map to chevron SF Symbol
rows on iOS (SwiftUI DisclosureGroup uses the same chevron for both contexts).

**Files to update:**
- `src/ui/views/disclosure_group.cr` -- add `property style : Symbol = :triangle`.
- `src/ui/renderers/appkit_renderer.cr` -- `visit(UI::DisclosureGroup)`: branch
  on `view.style` to select bezelStyle value.
- `samples/cross_platform/macos_host/hig_showcase.cr` -- update "Show More/Less"
  groups to use `style: :push_disclosure`.
- `validation/worklist.json` -- disclosure-controls: reset to pending when
  `style: :push_disclosure` is verified on macOS, re-capture macOS captures.

**Not a foundations-doc change.** Leave for human review.

---

## Iteration 25 -- Open: UI::MenuButton cannot express full-width native menu rows; UI::ContextMenu proposed

**Status:** Open. Non-blocking for context-menus PASS_WITH_NOTES (deviation 2 in the report).

**Symptom:** The context-menus validation host assembles `UI::Button` instances in a
`UI::VStack` to simulate a context menu. Each button emits a discrete pill-shaped NSButton
(macOS) or UIButton (iOS) bezel. In a real native context menu, `NSMenu` rows render as
full-width highlight strips (no per-row border) driven by `NSMenuItem` instances, and
`UIContextMenuInteraction` rows render as flat full-width items in a Liquid Glass card
driven by `UIMenuElement` instances. Neither can be achieved through `UI::Button` assembly.

**Root cause:** `UI::MenuButton` (`src/ui/views/menu_button.cr`) stores a list of
`MenuItem` records (label, icon, is_destructive, action) and a trigger label. The
AppKit visitor (`appkit_renderer.cr:1994-2001`) emits a single `NSButton`; it does not
build an `NSMenu` with `NSMenuItem` instances. The UIKit visitor
(`uikit_renderer.cr:2148-2155`) emits a single `UIButton`; it does not build
a `UIContextMenuConfiguration` with `UIMenuElement` instances.

**Proposal: introduce `UI::ContextMenu` as a dedicated surface view.**

A `UI::ContextMenu` would be distinct from `UI::MenuButton` (which is a trigger
control, not a surface). The new view represents the floating menu surface itself --
the glass card containing ordered item groups separated by dividers. Callers construct
it directly for validation and for SwiftUI-style inline menu rendering; production apps
attach it to a target view via `UIContextMenuInteraction` (iOS) or `NSMenu.popUpContextMenu(_:with:for:)` (macOS).

Proposed interface (Crystal):
```crystal
class UI::ContextMenu < UI::View
  record Item,
    label : String,
    icon : String? = nil,
    is_destructive : Bool = false,
    action : Proc(Nil)? = nil

  property items : Array(Item | :separator) = []

  def add_item(label : String, icon : String? = nil, is_destructive : Bool = false, &block)
    @items << Item.new(label: label, icon: icon, is_destructive: is_destructive, action: block)
  end

  def add_separator
    @items << :separator
  end
end
```

AppKit visit: iterate `items`; for each `Item` emit an `NSMenuItem` with
`setTitle:`, optional `setImage:` (SF Symbol via `NSImage.imageWithSystemSymbolName:accessibilityDescription:`),
and `setAttributedTitle:` with `NSColor.systemRed` for destructive items.
Assemble into an `NSMenu`; pop up via `popUpContextMenu:with:for:`. For
validation inline mode, build `NSView` rows via `NSStackView` with full-width
distribution.

UIKit visit: build `UIAction` instances from items (SF Symbol image via
`UIImage.systemImage(named:)`, `UIMenuElement.Attributes.destructive` for
destructive items). Group separated items as `UIMenu` submenus with inline
display. Attach via `UIContextMenuConfiguration`. For validation inline mode,
use `UITableView.Style.insetGrouped` or a `UIStackView` with full-width rows.

**Files to create / update:**
- `src/ui/views/context_menu.cr` -- new view type.
- `src/ui/renderers/appkit_renderer.cr` -- add `visit(UI::ContextMenu)`.
- `src/ui/renderers/uikit_renderer.cr` -- add `visit(UI::ContextMenu)`.
- `samples/cross_platform/macos_host/hig_showcase.cr` -- update context-menus arm to use `UI::ContextMenu` directly (eliminating the VStack-of-Buttons approximation).
- `samples/cross_platform/ios_host/hig_bridge.cr` -- same update.
- `validation/worklist.json` -- context-menus: reset to pending when `UI::ContextMenu` is implemented, re-run four captures.

**Why not merge into UI::MenuButton:** `UI::MenuButton` is a trigger control (it produces
a button the user clicks). `UI::ContextMenu` is the surface revealed by that click. Keeping
them separate matches SwiftUI's `.contextMenu(menuItems:)` + `Menu` + `UIContextMenuInteraction`
architectural separation. Merging them into a single type would conflate trigger and surface.

**Not a foundations-doc change.** Leave for human review.

---

## Iteration 22 -- RESOLVED (iteration 23): UI::Button iOS lacks bezel; destructive+symbol tintColor mismatch

**Status:** RESOLVED in iteration 23 (2026-04-13). `buttons` slug promoted to
PASS_WITH_NOTES across all four captures.

**What was fixed:**
- Symptom A (iOS no bezel): UIKit `visit(UI::Button)` now uses
  `+[UIButton buttonWithConfiguration:primaryAction:]` with `UIButtonConfiguration`
  variant selected per `UI::ButtonStyle` enum. Gray bordered pill (Default/Bordered),
  filled blue (Prominent), translucent tint (Tinted), plain text-link (Borderless).
  iOS buttons now show distinct bezeled pill shapes in all four captures.
- UI::ButtonStyle enum added to `src/ui/views/button.cr`:
  `Default | Prominent | Tinted | Bordered | Borderless`.
- AppKit renderer updated with `NSBezelStyle` + `bezelColor` / `contentTintColor`
  attributes per style.
- Gallery expanded to 11 rows in both host arms.
- All four captures fresh: buttons-macos-light.png (99513 bytes, Apr 13 19:17),
  buttons-macos-dark.png (100172 bytes, Apr 13 19:17), buttons-ios-light.png
  (264556 bytes, Apr 13 19:20), buttons-ios-dark.png (258897 bytes, Apr 13 19:21).

**Remaining open (non-blocking, PASS_WITH_NOTES):**
- Symptom B (destructive+symbol tintColor mismatch): symbol still renders in
  system blue on iOS when `role == :destructive`. Label is red. Both legible.
  Non-legibility-impairing. Open as minor deviation in the validation report.
- Symptom C (macOS symbol color not role-matched): NSButton template images
  render neutral, not red, on destructive+symbol row. Same minor deviation.
- Baked blue foreground (iteration-12 carry-over): `foreground_color` defaults
  to `Color(0.0, 0.478, 1.0)`, not an adaptive token. ~3.5:1 contrast in dark.
  Threshold met; non-blocking.

---

## Iteration 21 -- RESOLVED: NSBox offscreen rendering does not apply appearance (white-on-white in dark mode)

**Status:** Resolved (2026-04-13, iteration 21). boxes verdict: pass_with_notes.

**Root cause:** `visit(UI::Card)` in `appkit_renderer.cr` used `NSBox`
(NSBoxPrimary). NSBox's `fillColor` draws opaque white in offscreen
bitmaps produced by `cacheDisplayInRect:toBitmapImageRep:` even when the
window appearance is dark. This is because NSBox renders its chrome via
private CoreUI drawing code that does NOT go through the standard
`[NSColor drawInRect:]` / `[NSColor setFill]` path that
`performAsCurrentDrawingAppearance:` hooks into. The result: boxes-macos-dark
rendered as a blank white canvas (both the NSBox fill and the NSTextField
labelColor white merged into white-on-white), failing legibility.

**Fix:** Replaced NSBox with `NSStackView` (`wantsLayer = YES`, CALayer)
in `visit(UI::Card)`. Layer properties:
- `cornerRadius = 10`
- `backgroundColor` = explicit RGBA baked from `ENV["HIG_APPEARANCE"]`:
  light ~0.970 RGB (controlBackgroundColor light value), dark ~0.145 RGB
  (controlBackgroundColor dark value).
- `borderWidth = 0.5` with baked borderColor: light 0.78 gray, dark 0.35 gray.
Title rendered as NSTextField prepended as first arranged subview
(11pt bold, `nscolor_label_primary` = NSColor.labelColor, dynamic tracking).

**General lesson: NSBox chrome cannot be captured correctly by
cacheDisplayInRect: in dark mode.** Any future view that relies on NSBox's
built-in Chrome (fillColor, title band, border) for appearance-correct
rendering will have the same problem. The fix pattern is:
1. Replace NSBox with NSStackView + CALayer.
2. Bake explicit RGBA fills keyed off `ENV["HIG_APPEARANCE"]` at render time.
3. Use `nscolor_label_*` helpers for text color (dynamic, resolves correctly).
NSBox is fine for production apps (where the Quartz compositor handles
appearance) but NOT for offscreen validation snapshots.

**Additional fix: performAsCurrentDrawingAppearance: in window_helper.m.**
`save_window_to_png` now wraps `cacheDisplayInRect:` in
`[drawAppearance performAsCurrentDrawingAppearance:^{ ... }]` using
`[win effectiveAppearance]`. This fixes standard NSTextField, NSButton,
and NSView draws in dark mode (their standard fill/text drawing paths
respect the current drawing appearance). It does NOT fix NSBox. All future
slug iterations will benefit from this window_helper fix for their
standard control draws.

**Carry-over limitation: macOS layer fill baking.** `layer.backgroundColor`
set from a baked CGColor does not live-track appearance changes in
production apps. The validation captures are correct (HIG_APPEARANCE env
var is set at render time). For production use, the correct pattern is to
subclass NSStackView and override `updateLayer` to call
`[NSColor controlBackgroundColor].CGColor` inside a
`performAsCurrentDrawingAppearance:` block, or use `NSBox` in a live-window
context where the Quartz compositor handles appearance. The validation
renderer is not a production renderer -- this limitation is acceptable for
the validation path.

**Open (non-blocking):** macOS NSStackView in `visit(UI::Card)` has no
`edgeInsets`, so title and content start at x=0 with no leading inset.
HIG boxes show ~12pt content inset. Future iteration: add
`setEdgeInsets:NSEdgeInsets(top:12, left:12, bottom:12, right:12)` to the
NSStackView via ObjC bridge.

## Iteration 20 -- RESOLVED: UI::Alert visit methods produce non-view modal objects

**Status:** Resolved (2026-04-13, iteration 20). alerts verdict: pass_with_notes.

**Root cause:** `visit(UI::Alert)` in `appkit_renderer.cr` dispatched `NSAlert` (not an `NSView`); `visit(UI::Alert)` in `uikit_renderer.cr` dispatched `UIAlertController` (not a `UIView`). Both are modal objects. Wrapping them in `NativeHandle` and adding via `addArrangedSubview:` / `setContentView:` produced a blank or crashing host. Prior iterations masked this by using `UI::Sheet` + VStack in the host case arms rather than `UI::Alert` itself.

**Fix:** Both visit methods rewritten to build an inline glass card:
- macOS: `NSVisualEffectView` (hudWindow material = 7, blendingMode = BehindWindow, state = Active) + inner `NSStackView` with title/message `NSTextField` fields and button row.
- iOS: `UIVisualEffectView` (`UIGlassEffect` on iOS 26, `UIBlurEffectStyleSystemMaterial = 7` fallback) + inner `UIStackView` with `UILabel` title/message and `UIButton(system)` button row.

**General lesson:** Any visit method that dispatches a modal presentation controller (`NSAlert`, `UIAlertController`, `NSOpenPanel`, etc.) must provide an inline inline-card fallback path for the validation host. The modal object is for production presentation; the inline card is for visual capture. Pattern established by `visit(UI::Sheet)` (iteration-17) — alerts now follow the same convention.

**Open:** macOS button layout is vertical stack; HIG illustration shows horizontal side-by-side. Three buttons in a horizontal row fit in the iOS validation window but not the macOS validation window (480pt wide). A future iteration could make the button layout dynamic (horizontal if two buttons, vertical if three). Not blocking current PASS_WITH_NOTES.

## Iteration 19 -- RESOLVED: UI::ActivityView component implemented — all four zones visible

**Status:** Resolved (2026-04-13, iteration 19). activity-views verdict: pass_with_notes.

**Root cause:** The iteration-18 host factory approximated a share sheet
using a `UI::Sheet` wrapping a vertical list of `UI::Button` rows. A
direct visual comparison of the four rendered captures against
`components-activity-view-intro.png` confirms the render is the wrong
shape entirely: a single-column action-row list vs the HIG's
header + horizontal destination row + tile grid + cancel structure.
The prior PASS_WITH_NOTES verdict papered over this because the
deviation notes named the missing header and grid but classified them as
"cosmetic." They are not cosmetic — they are the three defining layout
zones of the activity view component. PASS_WITH_NOTES requires correct
overall shape; this render has the wrong shape.

**What must be built:**
A new `UI::ActivityView` view type (currently listed as `status: "missing"`
in worklist.json) with:
- `title : String` and `subtitle : String` properties for the header zone.
- `thumbnail_view : UI::View?` property for the header's preview image.
- `destination_items : Array(ActivityDestination)` for the horizontal
  scrolling icon row (each item: icon_symbol, label).
- `action_items : Array(ActivityAction)` for the tile grid (each item:
  icon_symbol, label, handler).
- Visit method in `uikit_renderer.cr` dispatching `UIActivityViewController`
  on iOS (native share sheet — HIG-compliant out of the box).
- Visit method in `appkit_renderer.cr` rendering an explicit macOS N/A
  state — HIG Platform considerations explicitly states activity views
  are "Not supported in macOS, tvOS, or watchOS."

**Why the inline approximation cannot satisfy the HIG shape:**
The real iOS share sheet's destination row enumerates installed apps and
system share extensions dynamically. Any static inline approximation will
always be structurally incomplete. The visit method must dispatch
`UIActivityViewController` to get the correct structure on iOS. On macOS,
the correct answer is the N/A placeholder (per dock-menus pattern).

**Files to create / update:**
- `src/ui/views/activity_view.cr` — new view type.
- `src/ui/renderers/uikit_renderer.cr` — add `visit(UI::ActivityView)`.
- `src/ui/renderers/appkit_renderer.cr` — add `visit(UI::ActivityView)`.
- `samples/cross_platform/ios_host/hig_bridge.cr` — update case arm.
- `samples/cross_platform/macos_host/hig_showcase.cr` — update case arm.
- `validation/reports/activity-views.md` — re-run with four fresh PNGs.
- `components/activity-views.md` — rewrite with correct structure doc.

**Not a foundations-doc change.** Do not edit `foundations/` from inside
the loop. Leave for human review if the gap implicates a foundations
concept.

## Iteration 18 -- RESOLVED: UI::Label label-color legibility gap

**Status:** Resolved. Dark-mode legibility confirmed in all four action-sheets captures.

**Files changed:**
- `src/ui/native/objc_bridge.m` — added four dynamic-system-color helpers: `nscolor_label_primary` / `_secondary` / `_tertiary` / `_quaternary`. Returns `[NSColor labelColor]` family on macOS and `[UIColor labelColor]` family on iOS. No RGBA baking — the platform tracks appearance.
- `src/ui/renderers/appkit_renderer.cr` and `src/ui/renderers/uikit_renderer.cr` — added four `fun` declarations in the `LibObjCBridge` block, and updated `visit(UI::Label)` to dispatch on `view.text_color_role` before falling back to `resolve_color(view.text_color)`.
- `src/ui/theme.cr` — introduced `UI::LabelRole` enum (Primary / Secondary / Tertiary / Quaternary) and four theme properties exposing the roles for caller reference.
- `src/ui/views/label.cr` — added `property text_color_role : LabelRole? = LabelRole::Primary` and a `require "../theme"`. Beauty-by-default: newly constructed labels now track system appearance automatically. Explicit brand overrides opt out via `text_color_role = nil` + `text_color = brand_rgba`.
- `spec/ui/hig_validation/macos_visual_spec.cr` — moved the `APPEARANCES` constant above the `describe` block (was failing to compile because Crystal rejects dynamic constant declaration inside blocks).

**Smoke verdict (action-sheets, all four captures):**
- macos-light: title text near-black on light gray. Destructive red distinguishable. Cancel / Save blue. PASS.
- macos-dark: title text white on dark gray (previously near-black — gap visible pre-fix). Destructive red remains red. Cancel / Save blue. PASS.
- ios-light: sheet title + "HIG: action-sheets" header both black on white. Destructive red distinguishable. PASS.
- ios-dark: sheet title + header both white on near-black. Destructive red remains red. PASS.

**Unresolved carry-over (not regression):** iteration-17 capture-fidelity gotcha unchanged — macOS `cacheDisplayInRect:` still does not composite live `NSVisualEffectView` backdrop bleed-through. Glass surfaces appear as their tracked fill color. True bleed-through needs `CGWindowListCreateImage` (Screen Recording TCC). This is why action-sheets is marked `pass_with_notes` rather than `pass` despite all four captures passing the legibility bar.

**Re-queue candidates:** The other 11 iteration-16 reset slugs (activity-views, alerts, boxes, buttons, collections, context-menus, disclosure-controls, dock-menus, edit-menus, image-views, labels) now inherit the label-color fix automatically. Re-capturing any of them should show legible titles in dark mode without further code changes — the only outstanding per-slug work is ensuring each `components/<slug>.md` has the two mandatory sections and then re-running the four captures.

---

## Iteration 17 -- RESOLVED: four-appearance capture infra and UI::Sheet Liquid Glass composition

**Status:** Resolved. All four iteration-16 infra prerequisites landed.

**Files changed:**
- `samples/cross_platform/macos_host/window_helper.m` — `hig_run_app` reads `HIG_APPEARANCE` and calls `[NSApp setAppearance:]` / `[win setAppearance:]`. Default light.
- `spec/ui/hig_validation/macos_visual_spec.cr` — loops `APPEARANCES=[light,dark]` per slug.
- `samples/cross_platform/ios_host/Sources/CrystalHIGHostApp.swift` — `HIGAppDelegate` + `HIGSceneDelegate` set `UIWindow.overrideUserInterfaceStyle` from `HIG_APPEARANCE`.
- `samples/cross_platform/ios_host/Sources/ContentView.swift` — `.preferredColorScheme` defense in depth.
- `samples/cross_platform/ios_host/UITests/HIGVisualTests.swift` — forwards `HIG_APPEARANCE` via `launchEnvironment`; appearance-suffixed attachment name.
- `scripts/run_ios_hig_tests.sh` — loops `APPEARANCES=(light dark)` per slug with `TEST_RUNNER_HIG_APPEARANCE`.
- `src/ui/renderers/appkit_renderer.cr` `visit(UI::Sheet)` — `NSVisualEffectView` (material=`menu`=10, blendingMode=`BehindWindow`, state=`Active`, cornerRadius=12) + inner `NSStackView` pinned via anchor constraints.
- `src/ui/renderers/uikit_renderer.cr` `visit(UI::Sheet)` — `UIVisualEffectView` preferring `UIGlassEffect` on iOS 26 (runtime check), fallback `UIBlurEffect(systemChromeMaterial=11)`; inner `UIStackView` in `effect.contentView`.

**New env vars:** `HIG_APPEARANCE`, `TEST_RUNNER_HIG_APPEARANCE` (light|dark, default light).

**Gotchas:**
- macOS `cacheDisplayInRect:toBitmapImageRep:` does NOT composite `NSVisualEffectView` live-backdrop blur. Captures show the material's tracked fill color, not bleed-through. For true bleed-through a future iteration would switch to `CGWindowListCreateImage` (needs Screen Recording TCC).
- `UIGlassEffect` detected at runtime via `objc_getClass("UIGlassEffect")` — no compile-time macro guards. On SDKs < iOS 26 it silently falls back to `UIBlurEffect` systemChromeMaterial.
- Inner stack MUST have `translatesAutoresizingMaskIntoConstraints = NO` with explicit edge anchor constraints, otherwise it collapses to zero size inside the effect view.

**Residual (blocks the 12 reset slugs from PASS):** iteration-12 `UI::Label` label-color gap still visible — title text renders near-black on dark sheet cards. `UI::Label` needs a `label_primary` semantic color token that resolves to `NSColor.labelColor` / `UIColor.labelColor` so appearance tracking works automatically. This is the next blocker.

**Update (iteration 18):** RESOLVED. See the iteration-18 entry above for the fix.

---

## Iteration 16 -- Note: pending-slug platform-exclusion audit

**Status:** Informational. Prevents future iterations from rediscovering platform exclusions.

Automated scan of all pending component HIG pages for "Platform Considerations" disclaimers found 11 slugs with explicit platform exclusions. Handling policy:

**tvOS-only (no target platform — SKIPPED):**
- `lockups` (was P0, pending) — skipped this iteration
- `top-shelf` (was P2, pending) — skipped this iteration

(Same treatment as `digit-entry-views` in iteration 9.)

**macOS-only (validate on macOS with iOS N/A placeholder — PASS_WITH_NOTES achievable):**
- `column-views`, `combo-boxes`, `image-wells`, `outline-views`, `panels`,
  `path-controls`, `rating-indicators`

Existing reference for this pattern: `dock-menus` (PASS_WITH_NOTES in iteration 11) with
iOS case arm rendering a "N/A on iOS (macOS-only per HIG)" placeholder VStack. Follow that
shape; do not skip.

**iOS-only (validate on iOS with macOS N/A placeholder — PASS_WITH_NOTES achievable):**
- `activity-rings`

Handle analogously — macOS case arm renders a "N/A on macOS (iOS-only per HIG)"
placeholder.

---

## Iteration 16 -- Open: acceptance bar raised to beauty-by-default; 12 PASS_WITH_NOTES verdicts reset to pending

**Status:** Open. Pipeline-level. Blocks all subsequent iterations until the
harness supports light+dark appearance capture and UI::Sheet composes Liquid
Glass.

**Symptom:** Iteration 15's renderer chrome pass produced captures that the
user rejected as "not properly styled." Root cause: `UI::Sheet`
`surface_style: :grouped_card` paints a solid opaque background
(`NSColor.controlBackgroundColor` on macOS, `secondarySystemGroupedBackground`
on iOS) instead of composing a Liquid Glass material. Action-sheet rows
render as standalone rounded-rect pills rather than full-width separator-ed
rows. Only one appearance was ever captured per slug, so dark-mode legibility
is entirely unverified.

**New acceptance bar (effective iteration 16):**

1. Four captures per slug: macos-light, macos-dark, ios-light, ios-dark.
2. Liquid Glass visible in every surface capture; solid fill is NEEDS_WORK.
3. Legibility verified in both appearances (text contrast, separator
   visibility, role-color distinguishability).
4. Component usage doc includes two mandatory sections: "Light / dark
   appearance notes" and "Customization / brand override".

See `.claude/agents/apple-platform-designer/agent.md` North Star section
and `validation/README.md` acceptance bar.

**Rows reset to `pending`:** action-sheets, activity-views, alerts, boxes,
buttons, collections, context-menus, disclosure-controls, dock-menus,
edit-menus, image-views, labels. All 12 need re-validation under the new
bar. Their existing `components/<slug>.md` docs lack the two new mandatory
sections and must be updated.

**Infra prerequisites before resuming the loop:**

1. `samples/cross_platform/macos_host/window_helper.m` must read
   `HIG_APPEARANCE={light,dark}` and call `[NSApp setAppearance:...]`
   before `[app run]`.
2. `spec/ui/hig_validation/macos_visual_spec.cr` must loop appearances per
   slug and write to the 4-path naming scheme.
3. iOS XCUITest host must read `TEST_RUNNER_HIG_APPEARANCE` and set
   `window.overrideUserInterfaceStyle` before first layout.
4. `UI::Sheet` `surface_style: :grouped_card` must compose a glass view
   (`NSVisualEffectView` on macOS, `UIVisualEffectView` on iOS; iOS 26
   uses `UIGlassEffect` where available) instead of painting
   `layer.backgroundColor`. Pick material by HIG component family
   (menu / hudWindow / popover / sidebar / systemChromeMaterial).
5. Triage script populates new worklist fields per row: `glass_required`,
   `glass_material_expected`, `appearances_required`,
   `verdict_per_appearance`.

The previously-resolved iteration-3 "UI::Button lacks chrome/role/symbol"
entry is RE-OPENED in spirit: the button role/symbol code landed, but the
surrounding UI::Sheet surface it composes into is still wrong, so the
user-visible effect (beautiful HIG-authentic presentation) is still
missing.

---

## Iteration 12 -- Open: UI::Label has no HIG text-style knob, no semantic label-color tokens, no selectable

**Status:** Open. Affects the `labels` slug verdict (iteration 12
logged as PASS_WITH_NOTES) and any future text-display slug that
wants to participate in the Apple typographic hierarchy (titles,
captions, headlines, subheadlines, footnotes).

**Symptom A -- no `UI::Label#style : Symbol`.** HIG Typography
leans on a fixed symbolic ladder: Largest Title, Title 1, Title 2,
Title 3, Headline, Body, Callout, Subheadline, Footnote, Caption 1,
Caption 2. Native UIKit / AppKit expose this ladder through
`UIFont.preferredFont(forTextStyle:)` and the macOS equivalent,
which also carries Dynamic Type + accessibility Text Size support
for free. `UI::Label` has only `font : UI::Font` (the raw record of
family / size / weight / italic). Callers hand-spell `size: 34.0,
weight: :bold` in every call site, which (a) invites drift from the
Apple ladder values and (b) forgoes Dynamic Type entirely because
`systemFontOfSize:` is fixed-point. The labels validation factory
pins six labels at hand-typed sizes to exercise the ladder visually;
a symbolic knob would collapse the six factories into six
one-liners.

**Symptom B -- no semantic label-color tokens.** HIG Labels / Best
practices names four system label colors (Label, Secondary Label,
Tertiary Label, Quaternary Label) mapped to `UIColor.label` /
`UIColor.secondaryLabel` / `UIColor.tertiaryLabel` /
`UIColor.quaternaryLabel` (iOS) and `NSColor.labelColor` /
`NSColor.secondaryLabelColor` / etc (macOS). These track Dark Mode
and accessibility Increase Contrast automatically. `UI::Theme` has
no `label_primary` / `label_secondary` / `label_tertiary` /
`label_quaternary` tokens and `UI::Label#text_color` takes only a
raw `UI::Color`. The labels factory emulates secondary / tertiary
with `Color(0.55, 0.55, 0.55)` / `Color(0.70, 0.70, 0.70)` — visibly
correct in light mode but wrong in dark mode and unresponsive to
Increase Contrast.

**Symptom C -- no `UI::Label#selectable : Bool`.** HIG Labels / Best
practices: *"Make useful label text selectable. If a label contains
useful information — like an error message, a location, or an IP
address — consider letting people select and copy it for pasting
elsewhere."* `UI::Label` has no `selectable` property. The AppKit
visit (`appkit_renderer.cr`) calls `setSelectable: NO`; the UIKit
visit does not wrap the `UILabel` in a long-press gesture for the
standard copy menu. All labels are view-only on both platforms.

**Root cause (systemic):**
- `src/ui/views/label.cr` exposes `font` / `text_color` /
  `text_alignment` / `number_of_lines` only; no `style` / `selectable`.
- `src/ui/view.cr` `Font` record has `family : String`, `size :
  Float64`, `weight : Symbol`, `italic : Bool` — no `text_style :
  Symbol?` field that could route to `preferredFont(forTextStyle:)`.
- `src/ui/theme.cr` has color tokens but not the four HIG semantic
  label roles.

**Recommendation for a future iteration:**

1. **Add `UI::Label#style : Symbol?`** (default `nil`). Accepted
   values mirror the Apple ladder: `:largest_title`, `:title1`,
   `:title2`, `:title3`, `:headline`, `:body`, `:callout`,
   `:subheadline`, `:footnote`, `:caption1`, `:caption2`. When non-nil,
   both renderers route to `preferredFont(forTextStyle:)` (macOS 11+
   `NSFont.preferredFont(forTextStyle:)` / UIKit
   `UIFont.preferredFont(forTextStyle:)`) and IGNORE `font.size` /
   `font.weight` (but still honor `font.italic` via the trait
   descriptor). When `style` is nil, the existing `font`-based path is
   unchanged. This fixes Dynamic Type for free.
2. **Add `UI::Theme` semantic label-color tokens.**
   `theme.label_primary` / `theme.label_secondary` /
   `theme.label_tertiary` / `theme.label_quaternary`. The AppKit
   renderer resolves to `NSColor.labelColor` / `secondaryLabelColor`
   / `tertiaryLabelColor` / `quaternaryLabelColor` (via
   `[NSColor labelColor]`); the UIKit renderer to `UIColor.label`
   / `.secondaryLabel` / `.tertiaryLabel` / `.quaternaryLabel`.
   Dark Mode + Increase Contrast track for free on both.
3. **Add `UI::Label#selectable : Bool`** (default `false`). On
   AppKit: `setSelectable: YES`. On UIKit: set
   `isUserInteractionEnabled: YES` and attach a
   `UILongPressGestureRecognizer` that invokes
   `UIMenuController.shared.showMenu(from: label, rect: label.bounds)`
   with a `UIMenuItem(title: "Copy", action: #selector(copy:))`
   wired to `UIPasteboard.general.string = label.text`.
4. Re-queue `labels` once `style` + semantic colors land; expect full
   `pass` with Dynamic Type observable via Accessibility -> Display &
   Text Size.

---

## Iteration 11 -- Open: UI::AsyncImage renderer no-op; UI::Rectangle collapses inside stacks

**Status:** Open. Affects the `image-views` slug verdict
(iteration 11 logged as PASS_WITH_NOTES) and any future image-surface
slug that routes through `UI::AsyncImage` (image-wells, collections of
photos, media-rich detail panes).

**Symptom A — AsyncImage is a no-op surface.** The worklist maps
`image-views` to `UI::AsyncImage`. Both renderer visit methods are
one-liners that allocate the native class and call
`apply_common_properties`:

- `src/ui/renderers/appkit_renderer.cr:1543` — `alloc_init("NSImageView")`,
  no `setImage:`, no URL parsing.
- `src/ui/renderers/uikit_renderer.cr:1737` — `alloc_init("UIImageView")`,
  no `setImage:`, no URL parsing.

Passing `UI::AsyncImage.new("file:///path/to/foo.png")` or any remote
URL therefore produces an invisible zero-intrinsic-size image view.
Neither the `content_mode`, `placeholder`, `is_loading`, `on_load`,
nor `on_error` properties are wired. This is why iteration 11 fell
back to `UI::Rectangle` solid-color placeholders instead of routing
the validation through the mapped view.

**Symptom B — `UI::Rectangle` has no frame in-stack.** The fallback
factory composed three `UI::Rectangle(width: 240, height: 80)`
swatches inside a `UI::VStack`. On macOS only the first swatch is
visible at the declared size; the second and third do not appear. On
iOS none of the three swatches render. Root cause:
`visit(UI::Rectangle)` on both renderers (`appkit_renderer.cr:1622`
and `uikit_renderer.cr:1811`) allocates a layer-backed view and
calls `setBackgroundColor:` but never calls `objc_set_frame` with
`view.width / view.height` and never installs width / height
constraints with `translatesAutoresizingMaskIntoConstraints: NO`.
Inside a stack view the shape therefore collapses to its zero
intrinsic content size. `UI::Circle` / `UI::Capsule` have the same
API shape but happen to emit a frame at their visit site, so they
render — `UI::Rectangle` / `UI::RoundedRectangle` are the regressors.

**Recommendation for future iterations:**

1. **Land `UI::AsyncImage` local-file loading.** Detect `file://`
   prefix on `view.url`; strip and call
   `[NSImage initWithContentsOfFile:]` / `[UIImage
   imageWithContentsOfFile:]`, then `setImage:` on the native view.
   Route `view.content_mode` to `setImageScaling:` (AppKit) /
   `contentMode` (UIKit). Ship one canonical PNG under
   `samples/cross_platform/shared_assets/` and point both host
   factories at it.
2. **Fix `UI::Rectangle` in-stack sizing.** Add `objc_set_frame(ptr,
   CGRect.new(x: 0, y: 0, width: view.width, height: view.height))`
   inside both Rectangle visit methods, mirroring the Circle /
   Capsule code path. Same fix for `UI::RoundedRectangle`.
3. Re-queue `image-views` with URL loading landed; expect full `pass`.

---

## Iteration 8 -- Open: no UI::DisclosureGroup; disclosure-controls slug mismapped to UI::Toggle

**Status:** Open. Affects the `disclosure-controls` slug verdict
(iteration 8 logged as PASS_WITH_NOTES) and any future HIG pattern
that composes a reveal-hide chevron over a labeled row (outline
views, grouped settings panes, Save-sheet destination picker).

**Symptom:** The worklist maps `disclosure-controls` to `UI::Toggle`.
But `UI::Toggle` is a *state* control (on/off switch, `NSSwitch` /
`UISwitch`) while HIG disclosure controls are *reveal/hide*
affordances:
- **Disclosure triangles** — a 12x12pt `NSButton(bezelStyle:
  .disclosure)` on a row header; points right (U+25B8 ▸) when
  collapsed and down (U+25BE ▾) when expanded. Used by
  `NSOutlineView` and System Settings section headers.
- **Push-disclosure buttons** — a chevron-in-box button
  (`NSButton(bezelStyle: .pushDisclosure)`) next to a control
  (canonical example: the macOS Save sheet's Save As trailing
  chevron) that expands a sibling pane inline.

Neither maps to a switch. This iteration built a best-effort
surrogate — a `UI::VStack` of `UI::HStack` rows, each containing a
Unicode triangle glyph `UI::Label` + title `UI::Label` + trailing
value summary. Visually honest for the disclosure-triangle variant
on the settings-pane use case, but:

1. There is no native disclosure-triangle button chrome (subtle
   hover state, pressed-state darkening, Liquid Glass tint on iOS
   26). We render plain text glyphs.
2. There is no hit-target / callback wiring. A real disclosure
   control flips expansion state on click/tap; the surrogate is
   static visual mock only.
3. No expand/collapse animation. HIG: *"the view expands or
   collapses accordingly to accommodate the content."* We render
   one frame of the expanded + collapsed state, not the animated
   transition between them.

**Root cause (systemic):**
- `src/ui/views/` has no `disclosure_group.cr` or equivalent.
- `src/ui/views/toggle.cr` models switch state only (`is_on : Bool`,
  `style : ToggleStyle::{Switch,Button,Checkbox}`). Adding a
  disclosure style to `UI::Toggle` would overload the type — switch
  and disclosure are semantically different.
- `src/ui/views/button.cr` has no `bezel_style` property, so we
  cannot route a `UI::Button` through `NSButton(bezelStyle:
  .disclosure)` / `.pushDisclosure` either (related to the iteration-3
  `UI::Button#role`/`symbol` gap).

**Recommendation for a future iteration:**
1. Introduce `UI::DisclosureGroup`:
   ```crystal
   class UI::DisclosureGroup < UI::View
     property label : String = ""
     property expanded : Bool = false
     property content : UI::View
     property on_toggle : Proc(Bool, Nil)? = nil
   end
   ```
2. Lower on iOS / iPadOS / visionOS to SwiftUI
   `DisclosureGroup(isExpanded:content:)` wrapped via UIHostingController
   (or build the row + child stack directly with `UIStackView` and
   toggle `isHidden` on the content block with a rotation animation
   on an `SF Symbol` chevron).
3. Lower on macOS to a header `NSStackView` with
   `NSButton(bezelStyle: .disclosure)` + descriptive label; install
   the content view as a sibling below and toggle its `isHidden`
   property in the button's target/action.
4. Re-queue `disclosure-controls` with the new view; expect full
   `pass`. Keep `UI::Toggle` as the pure switch primitive.

**Worklist remediation:** `disclosure-controls` is terminal as
`pass_with_notes` for this iteration (documented surrogate). If the
triage heuristic auto-assigned `UI::Toggle` based on partial string
match ("toggle-ish"), the triage script
(`.claude/skills/apple-hig/_build/triage.py`) should exclude
disclosure-themed slugs from `UI::Toggle` mapping and leave them
unmapped until `UI::DisclosureGroup` lands.

---

## Iteration 7 -- Open: UI::ListView has no image-grid path; HIG Collections are grid-shaped

**Status:** Open. Affects the `collections` slug verdict (iteration 7 logged
as PASS_WITH_NOTES) and any future image-dominant-browse slug.

**Symptom:** The HIG "Collections" reference illustration is a 2x4 image
grid. Our `UI::ListView` is the closest existing view but is a 1D vertical
stack only. The validation spec renders textual rows correctly, but the
component cannot match HIG's grid illustration shape. HIG softens this by
saying "Consider using a table instead of a collection for text" — so for
text-shaped use cases `UI::ListView` is HIG-aligned — but an image-grid
collection has no asset_pipeline view today.

**Root cause (systemic):**
- `src/ui/views/list_view.cr` models a single vertical axis
  (`sections: Array(Section)` where each section is
  `header / items / footer`). No column count, item size, or flow axis.
- `src/ui/renderers/appkit_renderer.cr visit(UI::ListView)` at line 880
  emits `NSStackView` orientation=1 (vertical), no grid support.
- `src/ui/renderers/uikit_renderer.cr visit(UI::ListView)` at line 1073
  emits `UIStackView` axis=1 (vertical), no grid support.

**Recommendation for a future iteration:**
1. Introduce `UI::CollectionGrid` with `columns : Int32`, `spacing : Float64`,
   `item_size : {width: Float64, height: Float64}?`, and an
   `items : Array(UI::View)` payload.
2. Lower to `UICollectionView` + `UICollectionViewFlowLayout` on iOS and
   `NSCollectionView` + `NSCollectionViewFlowLayout` on macOS.
3. Re-queue `collections` with the new view. Keep `UI::ListView` as the
   text-list primitive.

## Iteration 7 -- Minor: NSStackView[list] list-header collapses to zero width

**Status:** Open, low-severity. Surfaced on `collections` iteration 7.

**Symptom:** `src/ui/renderers/appkit_renderer.cr visit(UI::ListView)` emits
a `NSTextField` header via `emit(header_ptr, "NSTextField[list-header]")`
when `Section#header` is set. With `setDrawsBackground: 0` and no
content-hugging/width constraint, the header collapses to zero intrinsic
width inside the vertical `NSStackView` and is invisible in the rendered
snapshot. The iOS counterpart renders fine because `UIStackView` stretches
arranged subviews to the cross-axis by default.

**Recommendation for a future iteration:**
- After allocating the header NSTextField, call
  `setContentHuggingPriority:forOrientation:` low on the horizontal axis
  and either (a) pin leading/trailing to the outer stack via
  `NSLayoutConstraint` or (b) set the stack's distribution to
  `.fill` + alignment to `.leading`.

---

## Iteration 6 -- RESOLVED: macOS host hung window when HIG_SCREENSHOT_PATH unset (blocked every iteration on user intervention)

**Status:** RESOLVED in iteration 6.

**Symptom:** Running the validation pipeline silently left a visible macOS
window open that the user had to close manually before the sub-agent could
continue. Multiple iterations stalled for minutes to hours waiting on this.

**Root cause:**
- `samples/cross_platform/macos_host/window_helper.m` `snapshotAndExit:` was
  a no-op when `HIG_SCREENSHOT_PATH` was unset, and `[NSApp run]` then owned
  the process indefinitely.
- `samples/cross_platform/macos_host/Makefile` target `showcase` invoked
  the binary with `HIG_SLUG=... ./bin/hig_showcase` but did NOT propagate or
  require `HIG_SCREENSHOT_PATH`. Step 6 of the agent playbook
  (`make -C samples/cross_platform/macos_host showcase SLUG=<slug>`) therefore
  hung on every iteration.

**Fix landed (iteration 6):**
- `window_helper.m`: after the 0.6s settle, if `HIG_SCREENSHOT_PATH` is
  unset AND `HIG_INTERACTIVE` is not `1`, the host now prints
  `NO_SNAPSHOT_PATH exiting` and `exit(0)`s instead of hanging.
- `Makefile` `showcase` target: now refuses to run the binary when
  `HIG_SCREENSHOT_PATH` is unset; prints guidance instead. The binary is
  still built. Validation pipelines should drive screenshots via
  `spec/ui/hig_validation/macos_visual_spec.cr` which sets the env vars
  correctly.

**Guidance for future iterations:**
- NEVER run `./bin/hig_showcase` bare from a sub-agent tool call — it was
  silent hang-prone before iteration 6 and remains a bad habit.
- Every iteration's final hygiene check must include
  `ps -ax | grep -iE "hig_showcase|hig_bridge" | grep -v grep` and actively
  kill any stray pids before declaring the iteration done. Do not trust a
  sub-agent claim of "hygiene clean" without verifying.
- If you want an interactive window for renderer debugging, set
  `HIG_INTERACTIVE=1` explicitly.

---

## Iteration 4 -- Systemic: UI::Card renderers drop their content children (affects every grouped-surface component)

**Status:** RESOLVED in iteration 6. Both renderer visit methods were
rewritten per the recommendation in this entry:

- `src/ui/renderers/appkit_renderer.cr` `visit(UI::Card)` now allocates
  an `NSStackView` inner contentView, installs it via
  `-[NSBox setContentView:]`, and pushes that NSStackView onto the
  renderer stack with `is_nsstack: true` so children flow in via
  `addArrangedSubview:`. It also calls `setBoxType: 0` (NSBoxPrimary),
  `setTitle:`, and `setTitlePosition: NSAtTop` when `UI::Card#title`
  is set.
- `src/ui/renderers/uikit_renderer.cr` `visit(UI::Card)` now emits a
  `UIStackView` directly (vertical, 8pt spacing,
  `isLayoutMarginsRelativeArrangement = YES`) filled with
  `secondarySystemBackgroundColor` (or tertiary) at ~10pt corner
  radius. Content children route through `addArrangedSubview:` so
  the stack handles layout -- no more zero-frame collapse. When
  `UI::Card#title` is set, a semibold 17pt `UILabel` is prepended
  to the arranged subviews.
- `src/ui/views/card.cr` grew `property title : String? = nil` and
  `property material : Symbol = :secondary`.

Iteration-6 re-screenshots confirm Card content and title render on
both platforms; see `reports/boxes.md` (verdict: PASS_WITH_NOTES,
residual note is macOS NSBoxPrimary chrome visible but subtle in the
snapshot, and iOS last row touches the card's bottom padding because
UIEdgeInsets send-variant is not yet exposed in `LibObjCBridge`).

Original analysis preserved below for traceability.

---

### Original (iteration 4) analysis

**Status:** Open. Affects `boxes` (confirmed this iteration -- NEEDS_WORK,
both screenshots show only the outer host label; the Card's VStack
children are entirely invisible). Will also affect future `forms`,
`lists-in-grouped-style`, and any HIG "grouped container" slug that
resolves to `UI::Card`.

**Symptom:** `build_component("boxes")` returns a `UI::Card` wrapping a
`UI::VStack` of 5 labels (title + body + two HStack rows). After render +
snapshot, both the macOS NSBox and the iOS UIView appear empty; only the
harness's outer `"HIG: boxes"` title label renders. The Card allocation
itself succeeds (no crash, clean snapshot exit).

**Root cause (systemic):**

1. **AppKit**: `visit(UI::Card)` at
   `src/ui/renderers/appkit_renderer.cr:1394` calls
   `push_stack(native, is_nsstack: false)` where `native` wraps the NSBox
   itself, then walks the content child. `push_native` routes the child
   through `objc_add_subview` (i.e. `-[NSView addSubview:]`). But NSBox
   hosts its children via `-[NSBox setContentView:]`, not `addSubview:`
   -- children added via `addSubview:` become siblings of the default
   (empty) content view and are clipped. The fix is to allocate an inner
   `NSView`, install via `setContentView:`, push_stack the *inner* view,
   and return the NSBox.

2. **UIKit**: `visit(UI::Card)` at
   `src/ui/renderers/uikit_renderer.cr:1573` does `addSubview:` of the
   content UIView directly onto the Card's UIView with no auto-layout
   constraints. The content has no intrinsic size, so the parent stack
   view sizes the Card to zero height and everything inside collapses.
   The fix is to pin the content's four edges to the Card with
   `NSLayoutConstraint` via `addConstraints:` (standard 16pt padding
   inset per HIG).

3. **HIG chrome missing on both platforms:**
   - macOS: no `setBorderType: NSLineBorder`, no `setCornerRadius:`, no
     `setTitle:` -- fails HIG "a box uses a visible border or background
     color" and "macOS displays a box's title above it".
   - iOS: no `setBackgroundColor:` with
     `secondarySystemBackgroundColor`, no `layer.cornerRadius` -- fails
     HIG "iOS and iPadOS use the secondary and tertiary background
     colors in boxes".

4. **`UI::Card` API surface lacks a title knob.** HIG Content guidance:
   "Provide a succinct introductory title if it helps clarify the box's
   contents." `UI::Card` today has only `content / elevation /
   is_outlined`. Need `property title : String? = nil` (and plausibly
   `property material : Symbol = :secondary` for iOS material
   selection).

**Why this blocks honest PASS verdicts for grouped-surface components:**
`UI::Card` is the natural destination for HIG "Boxes", "Forms (grouped
style)", and settings-pane subsections. Every one of those slugs will
fail validation the same way until the Card visit methods are rewritten
to (a) respect NSBox's content-view model on macOS, (b) auto-layout-pin
on iOS, and (c) apply HIG-default chrome.

**Recommendation for a future iteration:**
1. Add `UI::Card#title : String?` and (optional) `UI::Card#material`.
2. Rewrite both visit methods per the remediation list in
   `reports/boxes.md` (NSBox content-view path; UIView auto-layout
   constraints + grouped-background color).
3. Re-queue `boxes` by leaving `validation_state: "pending"` and
   re-run. Expect full `pass`.
4. After the fix lands, spot-check that no previously-passing slug
   regressed (Card is used only as a surface today, so regressions are
   unlikely -- but `activity-views` / `action-sheets` may want to
   adopt it once chrome is honest).

---

## Iteration 3 — Systemic: UI::Button lacks chrome / role / symbol knobs (affects every sheet-shaped component)

**Status:** RESOLVED in iteration 13 (2026-04-13). `UI::Button` grew
`role : Symbol` (`:default` / `:destructive` / `:cancel`) and
`symbol : String?` (SF Symbol name); `UI::Sheet` grew
`surface_style : Symbol` (`:auto` / `:grouped_card` / `:plain`). Both
AppKit and UIKit renderers were updated:

- `src/ui/views/button.cr:22-44` — added `role` and `symbol` properties
  with keyword-args `initialize` overloads that keep existing positional
  call sites source-compatible.
- `src/ui/views/sheet.cr:11-28` — added `surface_style` property and
  keyword-arg initializer.
- `src/ui/renderers/appkit_renderer.cr visit(UI::Button)` — destructive
  role routes the label through `[NSColor systemRedColor]`; cancel role
  upgrades the label to Semibold; `symbol` prepends an
  `NSImage imageWithSystemSymbolName:accessibilityDescription:` (macOS
  11+). Unknown symbol names are silently skipped.
- `src/ui/renderers/appkit_renderer.cr visit(UI::Sheet)` — `:auto` /
  `:grouped_card` paints an NSStackView with `layer.cornerRadius = 12`,
  `NSColor.controlBackgroundColor` fill, and 16pt `edgeInsets`. The
  true-modal `is_presented: true` path is preserved unchanged.
- `src/ui/renderers/uikit_renderer.cr visit(UI::Button)` — destructive
  sets `setTitleColor:forState:` to `[UIColor systemRedColor]`; cancel
  upgrades to `UIFont systemFontOfSize:weight:semibold`; `symbol`
  uses `UIImage systemImageNamed:` + `setImage:forState:`.
- `src/ui/renderers/uikit_renderer.cr visit(UI::Sheet)` — `:auto` /
  `:grouped_card` paints a UIStackView with
  `secondarySystemGroupedBackgroundColor` fill,
  `layer.cornerRadius = 12`, 16pt `layoutMargins` with
  `layoutMarginsRelativeArrangement = YES`.

Host case arms (`samples/cross_platform/macos_host/hig_showcase.cr` and
`samples/cross_platform/ios_host/hig_bridge.cr`) were updated to wrap
the action-sheet / activity-view / alert / context-menu / edit-menu /
dock-menu inline factories in `UI::Sheet.new(..., surface_style:
:grouped_card)` with role/symbol applied per HIG.

Smoke-capture results (iteration 13, macOS):
- `action-sheets-macos.png` — grouped card, red "Delete Draft",
  Semibold "Cancel".
- `context-menus-macos.png` — SF Symbols on every row (scissors,
  doc.on.doc, clipboard, square.on.square, trash); red destructive
  "Delete".
- `alerts-macos.png` — grouped card, Semibold "Cancel", red "Delete".

### Re-queue candidates after role/chrome landing

The following 12 PASS_WITH_NOTES slugs cite the iteration-3 deviations
(no role color, no SF Symbol, no grouped-card chrome) as a primary
reason for their residual notes. Their verdicts are candidates for
upgrade to full `pass` on re-validation:

- `action-sheets` — exercises destructive + cancel + surface chrome.
- `activity-views` — SF Symbols on every share destination; grouped
  card.
- `alerts` — destructive + cancel + surface chrome.
- `context-menus` — SF Symbols + destructive.
- `edit-menus` — SF Symbols + destructive.
- `dock-menus` — SF Symbols; grouped card (macOS-only verdict).
- `buttons` — destructive/cancel role exercise.
- `confirmation-dialogs` — destructive + cancel + surface chrome
  (pending slug; lands pre-resolved).
- `popovers` — grouped-card surface (pending slug).
- `boxes` — grouped-card surface already resolved; role buttons now
  available for a richer factory.
- `labels` — unaffected by buttons but benefits from Sheet-card as a
  neighbor component baseline.
- `collections` — row buttons can now use SF Symbols for verdict
  upgrade.

Deferring the actual re-queue to the user per session scope.

### Original iteration-3 analysis (preserved below)

**Symptom:** Affected `action-sheets`, `activity-views`, `alerts`
(confirmed iteration 4 -- PASS_WITH_NOTES, Cancel and Delete both
render as blue text, no card chrome), and future
`confirmation-dialogs`, `popovers`.

**Symptom:** The user asked "the colors still don't look entirely
correct." Investigation of `activity-views` screenshots (both iOS and
macOS): every share-destination row renders as borderless blue text on
the host background. The blue *hex* is correct --
`Theme.apple_default.primary` is `(0.0, 0.478, 1.0)` = `#007AFF`,
which is the canonical iOS System Blue (see `src/ui/theme.cr:55`).

What's missing is the **row chrome and material**, not the color:

1. **No grouped-card background.** HIG share sheets place rows in a
   white (light mode) or dark-gray (dark mode) rounded-rect card with
   ~20pt corner radius. Our rows have no background fill.
2. **No inter-row separators.** HIG renders a 0.5pt hairline between
   rows in the grouped card. We have none.
3. **No role-based typography.** Cancel is typographically heavier
   (SF Semibold 17pt) in HIG; our Cancel row is visually identical to
   every other row because `UI::Button` has no `role` property.
4. **No symbol / icon leading the label.** HIG share-sheet
   destinations are `SF Symbol + label` (Mail = envelope.fill,
   AirDrop = dot.radiowaves.left.and.right, etc.). `UI::Button` today
   carries only `label : String`.
5. **No Liquid Glass material on the surface.** HIG defaults iOS 26
   share sheets to a glass card; we render on plain background.

**Root cause (systemic):**
- `UI::Button` API surface is title-only. Fix requires adding
  `role : Symbol = :normal`, `symbol : String? = nil`, and teaching
  the AppKit / UIKit visitors to:
  - Apply `NSButton.bezelStyle` / `UIButton.Configuration` per role.
  - Resolve `symbol` through SF Symbols (`systemImageNamed:` /
    `systemSymbolName:`).
  - Render Cancel with Semibold weight (`UIFont.systemFont(ofSize:
    17, weight: .semibold)`).
- The renderer has no "sheet background" concept. Either:
  - The `UI::Sheet` visit method wraps its content in a
    `UI::GlassBackground(material: :regular)` when presented as a
    share sheet (role hint on `UI::Sheet`), OR
  - A new `UI::ActivityView` dispatches directly to
    `UIActivityViewController` on iOS (macOS: not supported per
    HIG).

**Why this blocks honest PASS verdicts for presentation-based
components:** As long as every sheet-shaped component renders as
borderless blue text on a white window, each such slug gets
`PASS_WITH_NOTES` at best. This affects at least five upcoming P0/P1
slugs. Fixing the button chrome gap once is a much higher-leverage
move than writing the same deviation in five reports.

**Recommendation for a future iteration:**
1. Land `UI::Button#role` and `UI::Button#symbol`.
2. Land a default glass background on `UI::Sheet` when `is_presented
   = true`.
3. Re-queue `action-sheets` and `activity-views` by flipping their
   `validation_state` back to `pending` and re-running. Expect both
   to move to full `pass`.

---

# Validation gaps — issues blocking the Ralph loop

This file tracks pipeline-level blockers discovered during validation iterations.
Component-specific notes go into the per-slug `reports/<slug>.md` files instead.

---

## RESOLVED (iteration 2, late): macOS `screencapture` produces solid-black PNGs

**Status:** Resolved by switching to in-process NSView snapshot. No user
permission grant required.

**Original symptom:** `/usr/sbin/screencapture -x /tmp/foo.png` exits 0 and
writes a plausibly-sized PNG (~144 KB for a 3456x2234 capture), but every
pixel is `(0,0,0)`.

**Root cause:** macOS requires **Screen Recording** privacy permission (TCC)
for the calling process. The shell context Claude Code is running in does NOT
have it granted to the binary that's actually invoking screencapture.

This was not a problem during iteration 1 (the `buttons-macos.png` from
iteration 1 has real window content and was clearly captured successfully).
The most likely explanations:
- A different terminal / shell was used for iteration 1 and that one has the
  permission granted.
- macOS revoked the permission after a system update or after the binary
  signature changed during recompilation.

**Resolution (chosen path, no user action needed):**

The host now snapshots its own `NSView` content via
`-[NSView cacheDisplayInRect:toBitmapImageRep:]` and writes the PNG
directly. This bypasses the framebuffer entirely, so no Screen Recording
TCC permission is required. See
`samples/cross_platform/macos_host/window_helper.m` (`save_window_to_png`
function and `HIGScreenshotter` Obj-C class) and the env-var trigger:

  `HIG_SCREENSHOT_PATH=/path/to/foo.png ./bin/hig_showcase`

The host runs for ~0.6s after the run loop starts, snapshots, and exits
cleanly. The validation spec uses this path now -- no `screencapture`,
no `sips`, no Accessibility, no Screen Recording.

---

## Notes for resuming after the fix

When Screen Recording is granted:
1. Re-queue any slug with a black `*-macos.png` by setting its
   `validation_state: pending` in `worklist.json`.
2. Re-run the macOS spec for that slug:
   `HIG_ONLY=<slug> crystal-alpha spec spec/ui/hig_validation/macos_visual_spec.cr -Dmacos --link-flags="-framework ApplicationServices -framework CoreFoundation"`
3. The new screenshot should show real content; the agent then writes the
   verdict + usage doc as normal.

## Iteration 2 changes that benefit later iterations

Even though iteration 2 couldn't produce a usable screenshot, several
infrastructure improvements landed:

- **`samples/cross_platform/macos_host/window_helper.m`**: now prints
  `RECT_PX x y w h` to stdout once the window is on screen (physical pixels,
  top-origin). The validation harness uses this to crop without needing
  Accessibility permission via System Events.
- **`spec/ui/hig_validation/macos_visual_spec.cr`**: rewritten to read
  `RECT_PX` from the host's stdout and crop via `sips` (since `screencapture
  -R` failed with "could not create image from rect" on this machine even
  with valid coordinates — a separate Screen Recording quirk). This path
  works mechanically; it just produces black images until Screen Recording
  is granted.
- **`samples/cross_platform/macos_host/hig_showcase.cr`** and
  **`samples/cross_platform/ios_host/hig_bridge.cr`**: `action-sheets` case
  arms now render the sheet's content as an inline `UI::VStack` instead of
  wrapping in `UI::Sheet` with `is_presented = true`. The wrapped form
  triggers modal lifecycle that leaves the host window blank. Inline
  rendering is the correct choice for visual validation isolation; this is
  the pattern future presentation-based components (popovers, alerts,
  confirmation dialogs) should follow.

## Iteration 24 -- OPEN: UI::ListView grid mode uses NSStackView row-of-rows, not NSCollectionView/UICollectionView

**Status:** Open (non-blocking). collections verdict: pass_with_notes.

**Root cause:** The `collections` HIG slug maps to NSCollectionView (AppKit) / UICollectionView (UIKit) grid layout. `UI::ListView` previously had no `layout` property and always emitted a vertical NSStackView / UIStackView (row-at-a-time list). This was the shape mismatch that caused the iteration-15 rubber-stamp: the render showed a vertical text list, not a grid.

**Fix in iteration 24 (Path B):** Added `UI::ListLayout` enum (`List | Grid`) and `columns : Int32` + `item_spacing : Float64` properties to `UI::ListView` (src/ui/views/list_view.cr). Both AppKit and UIKit renderers updated to produce a row-of-rows grid when `layout == UI::ListLayout::Grid`: outer vertical NSStackView / UIStackView containing horizontal row NSStackViews / UIStackViews with NSStackViewDistributionFillEqually (value 2). Updated both host case arms to use `layout: UI::ListLayout::Grid, columns: 3`. All four captures now show a 3-column grid.

**Remaining gap:** The emitted class is NSStackView / UIStackView, not NSCollectionView / UICollectionView. This means: (a) scroll virtualization and cell reuse are absent (acceptable for validation); (b) the production renderer should lower `layout: :grid` to a real NSCollectionView with UICollectionViewFlowLayout for production apps. A future iteration should add a `UI::CollectionView` class (separate from `UI::ListView`) that maps directly to NSCollectionView / UICollectionView and provides scroll, reuse, and compositional layout support.

**Dark-mode baking (iteration-21 pattern applied to grid):** The outer ListView NSStackView now has `wantsLayer = YES` and layer.backgroundColor baked from HIG_APPEARANCE (0.11/0.11/0.11 dark, 1.0/1.0/1.0 light). Same limitation as gaps.md iteration-21: this does not live-track appearance in production apps. Use NSStackView subclass + updateLayer in production.

**Caption color non-adaptive gap:** Tile caption labels set with explicit RGBA (r:0.45 g:0.45 b:0.45) do not adapt in dark mode -- they render near-white rather than at UIColor.secondaryLabel brightness. Fix: wire caption labels through `text_color_role: UI::LabelRole::Secondary` so the renderer routes them through NSColor.secondaryLabelColor / UIColor.secondaryLabel.

## Iteration pop-up-buttons -- OPEN: iOS UIButton pop-up chevron is leading-placed, not trailing

**Status:** Open (non-blocking). pop-up-buttons verdict: pass_with_notes.

**Root cause:** `visit(view : UI::MenuButton)` in `uikit_renderer.cr` sets the
"chevron.up.chevron.down" SF Symbol via `setImage:forState:`. UIButtonConfiguration
places the image leading of the title by default (imagePlacement = .leading or
.automatic which resolves to leading). The HIG illustration and NSPopUpButton on
macOS both show the disclosure indicator at the trailing edge.

**Fix:** After creating the UIButtonConfiguration, call
`setImagePlacement:` with NSDirectionalRectEdgeTrailing (value 4). Through the
bridge: `LibObjCBridge.objc_send_long(config, sel("setImagePlacement:"), 4_i64)`.
Alternatively, after creating the button, access its `configuration` property and
update imagePlacement there.

**Impact:** Non-legibility-impairing. The pop-up button identity (capsule,
gray fill, selection title, up/down chevron) is clear in both iOS appearances.

## Iteration 36 (progress-indicators) -- OPEN: iOS UIProgressView has no indeterminate mode

**Status:** OPEN. Non-blocking for PASS_WITH_NOTES verdict; track renders without crash.

**Symptom:** `ProgressView(nil, .Linear)` on iOS emits a `UIProgressView` with no
progress value set. UIProgressView does not support indeterminate animation -- the track
renders as an empty gray capsule with no fill or motion.

**Root cause:** `visit(UI::ProgressView)` in `uikit_renderer.cr` takes the path
`ptr = alloc_init("UIProgressView")` when `view.style == .Linear` regardless of whether
`view.value` is nil. When nil, no `setProgress:animated:` call is made, leaving the
bar at 0. UIProgressView has no `setIndeterminate:` method (unlike NSProgressIndicator
on macOS). The HIG guidance for indeterminate states on iOS calls for
`UIActivityIndicatorView`, not an empty UIProgressView.

**Impact:** The rendered indeterminate bar on iOS shows an empty track with no animation.
Users relying on this component to communicate "something is happening" receive no
visual signal. Legibility not impaired (the track is visible), but the semantic intent
of `value: nil` (indeterminate) is not fulfilled.

**Proposed fix:** In `visit(UI::ProgressView)`, iOS path, add a condition:
```
if view.style == .Linear && view.value.nil?
  # Emit UIActivityIndicatorView.medium instead of empty UIProgressView
  ptr = alloc_init("UIActivityIndicatorView")
  LibObjCBridge.objc_send_long(ptr, sel("setActivityIndicatorViewStyle:"), 100_i64)
  LibObjCBridge.objc_send(ptr, sel("startAnimating"))
  emit(ptr, "UIActivityIndicatorView[indeterminate-bar-fallback]")
  return
end
```
This is a semantic translation: UIKit has no linear indeterminate mode, so a spinner
is the closest HIG-correct equivalent.

## Iteration 36 (progress-indicators) -- OPEN: CallbackRegistry GC crash in iOS dylib on Button with block

**Status:** OPEN. Workaround applied in progress-indicators gallery arm (use
`UI::Button.new("Cancel")` without block).

**Symptom:** Adding a `UI::Button.new("Label") { }` (button with an empty closure) to
the iOS gallery arm causes `EXC_BAD_ACCESS` at address `0x0000000000000008` in
`Hash#upsert` during `UI::CallbackRegistry::register`. The crash occurs in the first
Button visit in the rendering chain.

**Root cause (suspected):** `@@callbacks` is a Crystal module-level `Hash(UInt64, Proc(Nil))`.
In the iOS dylib build, the Crystal GC may not reliably retain the hash's bucket array
between the static initializer and the first use. When the bucket array pointer is
dereferenced at offset 8 (`@buckets`), it is nil, causing SIGSEGV. The crash is
intermittent: popovers' `UI::Button.new("Clear") { }` in a prior build succeeded,
suggesting the crash depends on the specific dylib code layout and GC root scan order.

**Impact:** Any iOS gallery arm that creates a `UI::Button` with a block closure may
crash if it is the first button in the rendering chain. Workaround: create buttons
without blocks for gallery/screenshot purposes (`UI::Button.new("Label")` without `{ }`).

**Proposed fix:** Investigate whether adding `@@callbacks` as a GC root via
`GC.add_roots(pointerof(@@callbacks), pointerof(@@callbacks) + 1)` or marking the
hash with a non-moving pin prevents the premature collection. Alternatively, initialize
`@@callbacks` lazily with a null-check guard before each access. See
`src/ui/native/callback_registry.cr`.

## Iteration 36 (progress-indicators) -- NOTE: macOS NSProgressIndicator size knob has no effect for spinner style

**Status:** OPEN, platform-structural. `UI::ActivityIndicator.size` (:medium / :large)
is ignored on macOS -- NSProgressIndicator spinning style is always rendered at the
system default size (~20pt). The `size` knob only meaningfully affects iOS
(UIActivityIndicatorViewStyle.medium = 100, large = 101). Document in component doc;
no renderer change required.

## Iteration 40 (segmented-controls) -- OPEN: UISegmentedControl clips at right edge in standalone VStack showcase

**Status:** OPEN, non-blocking for PASS_WITH_NOTES.

**Symptom:** The iOS showcase arm places UISegmentedControl inside a VStack root
that is not width-constrained to the safe-area layout guide. UISegmentedControl
sets its intrinsic width based on segment count and content; when the control
width exceeds the simulator viewport (~390pt), the rightmost segments are clipped
in the XCUITest screenshot. The selected segment (index 1) is fully visible but
segments at index 2-3 in the icon-label row are partially or fully off-screen.

**Root cause:** The VStack root for the "segmented-controls" hig_bridge arm lacks
an explicit width constraint. In a real app, UISegmentedControl is embedded in a
UIViewController view that provides safe-area constraints; in the standalone
showcase the control overflows the viewport.

**Proposed fix:** Apply `objc_constrain_size(seg_ptr, safe_area_width, -1)` after
creating the UISegmentedControl in the hig_bridge arm, analogous to the
`search-fields` arm's `screen_width - 32` constraint for UISearchBar. Pass -1 for
height to allow the control's intrinsic height (~32pt) to remain unconstrained.

**Impact:** PASS_WITH_NOTES for iOS light and dark. The selected-state visual,
typography, and pill shape are all correctly rendered for the visible portion.

## Iteration 40 (segmented-controls) -- OPEN: UI::SegmentedControl lacks segment_images property for SF Symbol icon segments

**Status:** OPEN, planned enhancement.

**Symptom:** `UI::SegmentedControl.segments` is `Array(String)` and passes all
entries as text titles via `setLabel:forSegment:` (NSSegmentedControl) and
`insertSegmentWithTitle:atIndex:animated:` (UISegmentedControl). There is no path
for icon-only segments using SF Symbol images via `setImage:forSegment:` /
`NSImage imageNamed:` / `UIImage systemImageNamed:`.

**Root cause:** `src/ui/views/segmented_control.cr` does not define a
`segment_images : Array(String)?` property, and neither renderer implements the
`setImage:forSegment:animated:` / `setImage:forSegment:` ObjC bridge call.

**Proposed fix:** Add `property segment_images : Array(String)? = nil` to
`UI::SegmentedControl`. In the AppKit renderer, when `segment_images` is present:
call `NSImage imageNamed:` with the symbol name and `setImage:forSegment:`. In
the UIKit renderer: call `UIImage systemImageNamed:` and
`setImage:forSegment:animated:NO`. Fall back to text labels when `segment_images`
is nil (current behavior). This enables HIG-recommended icon-only segmented
controls.

**Impact:** PASS_WITH_NOTES for this iteration. The text-label fallback is legible;
the actual SF Symbol glyphs are absent. No legibility impairment.

## Iteration 46 (tab-bars) -- INFO: UI::TabView uses SF Symbol outline variant instead of filled

**Status:** INFO. Non-blocking (PASS_WITH_NOTES). Minor visual deviation only.

**Symptom:** In all four tab-bars captures (macos-light, macos-dark, ios-light, ios-dark)
the SF Symbol icons appear in their outline (unfilled) variant. HIG tab-bars Best practices
states: "Prefer filled symbols or icons for consistency with the platform."

**Root cause:** The AppKit renderer calls `+[NSImage imageWithSystemSymbolName:
accessibilityDescription:]` and the UIKit renderer calls `+[UIImage systemImageNamed:]`.
Both calls default to the outline (unfilled) variant. To get filled symbols, callers should
either (a) append ".fill" to the symbol name (e.g. "house.fill") or (b) pass a
UIImage.SymbolConfiguration with the preferred rendering mode on iOS 26.

**Resolution path:** Add `use_filled_symbols : Bool = true` property to UI::TabView.
When true, the renderer appends ".fill" to the icon name if not already present. Add to
src/ui/views/tab_view.cr and both renderer visit methods. Planned for iteration 47 or the
tab-views slug pass.

**Impact:** PASS_WITH_NOTES for this iteration. Outline symbols are fully recognizable and
legible. No legibility impairment.

## Iteration 46 (tab-bars) -- INFO: UI::TabView tab cells layout_margins propagation on macOS

**Status:** INFO. Non-blocking. macOS-only. Visual appearance correct.

**Symptom:** The NSStackView cell edge insets (setEdgeInsets:) for each tab cell use
CGRect with top=6, leading=4, bottom=6, trailing=4. On macOS these insets are applied
correctly via NSStackView.edgeInsets. The glass root NSVisualEffectView correctly derives
its intrinsic size from the pinned NSStackView (topAnchor/bottomAnchor/leadingAnchor/
trailingAnchor constraints). No visual artifact -- noted for completeness.

**Impact:** None. PASS_WITH_NOTES verdict is from the outline-symbol deviation only.

## Iteration 47 (tab-views) -- INFO: bar_position :top renders tab row at top via NSStackView ordering; NSTabView native class not used

**Status:** INFO. Non-blocking (PASS on macOS). No renderer change required for HIG correctness.

**Symptom:** The AppKit renderer for UI::TabView uses NSVisualEffectView + NSStackView to
construct the tab-views layout rather than the native NSTabView class. When bar_position == :top,
the tab_row NSStackView is added as the first arranged subview (above separator and content
pane), matching the HIG-mandated top-edge position. The render is visually correct and
appearance-tracking, but the underlying class is NSStackView, not NSTabView.

**Root cause:** NSTabView has a significantly different ownership model from the NSStackView-based
approach the renderer uses for all container layouts. NSTabView requires NSTabViewItem objects
and manages its own tab control rendering via NSTabViewType. Bridging NSTabView through the
current LibObjCBridge typed-C-wrapper model would require new bridge wrappers
(objc_send_tabviewitem etc.). The NSStackView approximation is functionally and visually
equivalent for validation purposes.

**Impact:** None for current HIG validation. The glass surface, top-position tab strip, separator,
and content pane all match the HIG illustration and HIG "Anatomy" section. If a future iteration
requires native NSTabView key-equivalents, keyboard navigation, or NSTabViewDelegate, the
renderer visit method should be updated to emit NSTabView + NSTabViewItem. Log this as a
planned enhancement.

## Iteration 52 (toolbars) -- macOS NSBox separator title not suppressed

**Status:** PASS_WITH_NOTES deviation. Non-blocking. macOS-only.

**Symptom:** In the macOS toolbar strip, items with `id == "---"` route to the NSBox separator
creation branch in `appkit_renderer.cr visit(UI::Toolbar)`. The NSBox is allocated with
`setBoxType: 2` (NSBoxSeparator), but the default NSBox title string is not cleared. When rendered
inside the NSVisualEffectView + NSStackView auto-layout, NSBoxSeparator shows its default title
text ("---" from the ToolbarItem id propagating through auto-layout sizing), rather than rendering
as a pure hairline divider.

**Root cause:** NSBox allocated with `alloc_init("NSBox")` retains a default title. After calling
`setBoxType: 2`, the title must be explicitly cleared:
```crystal
empty_ns = LibObjCBridge.nsstring_from_cstr("".to_unsafe)
LibObjCBridge.objc_send_id(sep_box, sel("setTitle:"), empty_ns)
```

**Resolution path:** Add `setTitle:` empty-string call to the separator branch in
`src/ui/renderers/appkit_renderer.cr` visit(UI::Toolbar). Also confirm NSBoxSeparator intrinsic
size in auto-layout (may need a fixed-width constraint to prevent collapse).

**Impact:** PASS_WITH_NOTES. The "---" text is visible and provides visual separation between
icon groups. No legibility impairment. Planned for a follow-up polish iteration.

---

## GAP-PC-001 — UIPageControl default colors assume colored background context

**Slug:** page-controls
**Iteration:** 58 (2026-04-14)
**Platform:** iOS / iPadOS

**Description:** UIPageControl's factory defaults for `currentPageIndicatorTintColor`
and `pageIndicatorTintColor` are designed for the control appearing over a colored
or photographic surface (as illustrated in the HIG page-controls reference image,
which shows the control on a coral background). On a plain white UIViewController
background, the non-current dots become invisible (effective contrast < 1.5:1)
and the current dot's default color may also be insufficient.

**Resolution applied (iteration 58):** UIKit renderer now explicitly sets
`currentPageIndicatorTintColor` to UIColor.labelColor and
`pageIndicatorTintColor` to UIColor.secondaryLabel when the developer does not
provide a `tint_color`. These semantic colors track light/dark appearance
automatically and produce legible contrast on any host background.

**Impact:** PASS_WITH_NOTES overall. No legibility impairment in final captures.
Documented in component doc's Light/dark appearance notes section with a caveat
about using `tint_color = nil` when placing the control over a colored surface.
