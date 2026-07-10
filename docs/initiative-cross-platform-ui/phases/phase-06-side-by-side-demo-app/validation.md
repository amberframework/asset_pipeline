
# Phase 6 — Side-by-Side Demo App — Validation Rubric

**You are the validator agent for this phase.** Read this document in full before running any check. The implementer has already declared their work done; your job is to verify, independently, against the checklist below.

---

## Validator scope reminder

Per `rubric/validation_criteria.md`:

- You read, run, inspect, and record. You do not modify code, tests, configuration, or documentation. (Exception: documented temporary edits that you cleanly revert; see the universal rubric.)
- You do not consolidate failures. Each check is reported independently.
- You do not skip checks. A blocked check is reported `blocked: true`, not silently omitted.
- You do not consult prior gate reports for this phase. A previous validator's verdict does not constrain yours.
- If a check is ambiguous, **fail closed** — mark `passed: false` and let the team lead adjudicate.

Form your expectations from this rubric and the universal criteria, then verify them. Do not read the implementer's commit messages before forming expectations.

---

## Pre-reading checklist

Before running any check, read in this order:

1. `docs/initiative-cross-platform-ui/MASTER_PLAN.md`
2. `docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/README.md`
3. `docs/initiative-cross-platform-ui/rubric/validation_criteria.md`
4. `docs/initiative-cross-platform-ui/rubric/gate_report_schema.md`
5. `docs/initiative-cross-platform-ui/rubric/behavior-simulation-toolkit.md` — all `nav.flow-end-to-end-*`, `tier3.action-sheet-open-and-dismiss-*`, and the upgraded `resize.macos` checks below drive the running app per the patterns there.
6. **This document, in full.**
7. The implementer's handoff message (after you have read this rubric, not before).

You do **not** need to read the implementation brief (`implementation.md`) before validating. The rubric is the contract; the brief is the implementer's guidance. If a check disagrees with the brief, the rubric wins.

---

## Evidence directory

Create `handoff/phase-06-evidence-{YYYY-MM-DD}/` with subdirectories:

```
handoff/phase-06-evidence-{YYYY-MM-DD}/
  README.md
  test_output/
  screenshots/
  audits/
  inspections/
```

All check `evidence` paths in `GATE_REPORT.json` are relative to this directory.

---

## Checks

There are **24 checks** in this phase. Checks marked **Required** affect the verdict; **Optional** are recorded but do not cause a FAIL.

---

### build.web (Required)

**check_id:** `build.web`

**What:** The web build produces all expected static files.

**How:**
```bash
cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline
rm -rf output/initiative-demo
crystal run samples/initiative-cross-platform-ui-demo/web/build_web.cr 2>&1 \
  | tee handoff/phase-06-evidence-{DATE}/test_output/build.web.log
ls output/initiative-demo/
```

**Pass criteria:**
- Build completes with exit code 0.
- `output/initiative-demo/` contains at least: `index.html`, `sign-in.html`, `dashboard-activity.html`, `dashboard-friends.html`, `dashboard-settings.html`, `detail.html`, `settings.html`, `tier3.html`, `theme.css`, and an `assets/` subfolder with placeholder SVGs.
- Each HTML file is non-empty (> 1 KB).

**Evidence:** `test_output/build.web.log`, `inspections/build.web.listing.txt` (output of `ls -la output/initiative-demo/`).

---

### build.macos (Required)

**check_id:** `build.macos`

**What:** The macOS build produces a runnable binary (or `.app` bundle), and the binary launches.

**How:**
```bash
cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-demo/macos
make clean
make build 2>&1 | tee {EVIDENCE}/test_output/build.macos.log
ls -la bin/
# Launch the binary in a captured window (with screenshot env var):
HIG_SCREENSHOT_PATH=/tmp/macos_launch_check.png DEMO_SCREEN=sign-in ./bin/demo_app &
sleep 3
# Capture window via screencapture; copy to evidence; kill the binary.
```

**Pass criteria:**
- `make build` completes with exit code 0.
- A binary exists at `bin/demo_app` (or equivalently named per the Makefile).
- Launching it produces a window containing the sign-in screen (verifiable by screenshot showing the wordmark + the two text fields + the Sign in button).
- The binary terminates cleanly when killed.

**Evidence:** `test_output/build.macos.log`, `screenshots/build.macos-launch.png`.

---

### build.ios (Required)

**check_id:** `build.ios`

**What:** The iOS build produces an `.app` that installs and launches on iPhone 17 Pro simulator without crash.

**How:**
```bash
xcrun simctl list devices | grep "iPhone 17 Pro"
# If multiple, pick the one matching iOS 26+; UDID into $IOS_UDID.
xcrun simctl boot "$IOS_UDID"

cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-demo/ios
make build 2>&1 | tee {EVIDENCE}/test_output/build.ios.log

xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/DemoApp.app
xcrun simctl launch booted com.assetpipeline.democross
sleep 4
xcrun simctl io booted screenshot {EVIDENCE}/screenshots/build.ios-launch.png
xcrun simctl terminate booted com.assetpipeline.democross
```

**Pass criteria:**
- `make build` completes with exit code 0.
- `xcrun simctl install` succeeds.
- `xcrun simctl launch` succeeds and the app remains running for at least 4 seconds (no immediate crash).
- The captured screenshot shows the sign-in screen with brand visible.

**Blocked criteria:** if iPhone 17 Pro simulator is not installed on the validation machine, mark `blocked: true` with notes; do not substitute silently.

**Evidence:** `test_output/build.ios.log`, `screenshots/build.ios-launch.png`.

---

### screen.sign-in.web (Required)

**check_id:** `screen.sign-in.web`

**What:** The sign-in screen renders on web at 1280×800, not blank, no console errors.

**How:** Drive Chrome via CDP per `../../rubric/behavior-simulation-toolkit.md` §3 (extend `scripts/capture_amber_demo_screenshots.cr`). `Page.navigate` to `file:///path/to/output/initiative-demo/sign-in.html`; `Emulation.setDeviceMetricsOverride` width=1280 height=800; `Page.captureScreenshot`; capture console errors per toolkit §3.8 (either subscribe to `Runtime.consoleAPICalled` / `Log.entryAdded` events, or pre-inject the `window.__consoleErrors` accumulator and read via `Runtime.evaluate` at the end).

**Pass criteria:**
- Page loads (no 404, no crash).
- Visible content includes: Demo wordmark, "Email" field, "Password" field, "Sign in" button.
- Console has zero errors (warnings OK).

**Evidence:** `screenshots/screen.sign-in.web-light-1280.png`, `inspections/screen.sign-in.web.console.log`.

---

### screen.sign-in.macos (Required)

**check_id:** `screen.sign-in.macos`

**What:** The sign-in screen renders on macOS.

**How:**
```bash
DEMO_SCREEN=sign-in ./bin/demo_app &
sleep 3
screencapture -l <window_id> {EVIDENCE}/screenshots/screen.sign-in.macos.png
kill %1
```

**Pass criteria:** Screenshot shows the sign-in layout with brand applied; no obviously blank or error-paneled window.

**Evidence:** `screenshots/screen.sign-in.macos.png`.

---

### screen.sign-in.ios (Required)

**check_id:** `screen.sign-in.ios`

**What:** The sign-in screen renders on iOS simulator. Viewport tag for all iOS captures in this phase is `iphone17pro` (canonical lowercase no-spaces form — see Phase 6 implementation `Viewport tag vocabulary` and the Phase 7 alignment).

**How:**
```bash
xcrun simctl launch booted com.assetpipeline.democross --DEMO_SCREEN=sign-in
sleep 3
xcrun simctl io booted screenshot {EVIDENCE}/screenshots/screen.sign-in.ios-iphone17pro-light.png
xcrun simctl terminate booted com.assetpipeline.democross
```

**Pass criteria:** Screenshot shows the sign-in layout. iOS-style UITextField appearance for the inputs; system blue or brand-coral button background.

**Evidence:** `screenshots/screen.sign-in.ios-iphone17pro-light.png` (and `-iphone17pro-dark.png` if dark scheme is also captured for this check).

---

### screen.dashboard.web (Required)

**check_id:** `screen.dashboard.web`

**What:** The dashboard (all three tabs) renders on web.

**How:** Navigate to each of `dashboard-activity.html`, `dashboard-friends.html`, `dashboard-settings.html` at 1280×800. Capture each.

**Pass criteria:** Each tab page shows the TabView shell + tab content. Activity shows a card grid; Friends shows a sectioned list; Settings shows a form preview.

**Evidence:** `screenshots/screen.dashboard.web-activity-1280.png`, `-friends-1280.png`, `-settings-1280.png`.

---

### screen.dashboard.macos (Required)

**check_id:** `screen.dashboard.macos`

**What:** The dashboard renders on macOS.

**How:** Launch macOS binary with `DEMO_SCREEN=dashboard-activity`, capture; repeat for friends and settings.

**Pass criteria:** Each tab visible. macOS-idiomatic TabView (NSSegmentedControl in toolbar or similar) per phase 3 SwiftUI bridge.

**Evidence:** 3 PNGs.

---

### screen.dashboard.ios (Required)

**check_id:** `screen.dashboard.ios`

**What:** The dashboard renders on iOS.

**How:** Launch iOS app with `DEMO_SCREEN=dashboard-activity`, capture; repeat for friends and settings.

**Pass criteria:** Each tab visible. iOS-idiomatic bottom UITabBar.

**Evidence:** 3 PNGs.

---

### screen.detail.web (Required)

**check_id:** `screen.detail.web`

**What:** The detail screen renders on web.

**How:** Navigate to `detail.html` at 1280×800. Capture.

**Pass criteria:** Hero image, transaction title, metadata rows, and three buttons (Edit, Share, Delete) all visible. Delete button visibly uses destructive (red) treatment.

**Evidence:** `screenshots/screen.detail.web-1280.png`.

---

### screen.detail.macos (Required)

**check_id:** `screen.detail.macos`

**What:** The detail screen renders on macOS.

**How:** `DEMO_SCREEN=detail ./bin/demo_app`, capture.

**Pass criteria:** As above. Native-feeling button group.

**Evidence:** PNG.

---

### screen.detail.ios (Required)

**check_id:** `screen.detail.ios`

**What:** The detail screen renders on iOS.

**How:** Launch with `DEMO_SCREEN=detail`, capture.

**Pass criteria:** As above. iOS NavigationStack back affordance visible.

**Evidence:** PNG.

---

### screen.settings.web (Required)

**check_id:** `screen.settings.web`

**What:** The settings screen renders on web.

**How:** Navigate to `settings.html` at 1280×800. Capture.

**Pass criteria:** All form widgets visible — multiple TextFields, Picker, ColorPicker (`<input type="color">` on web), Slider, two Toggles, TimePicker (`<input type="time">` on web), SegmentedControl, Stepper, Save and Cancel buttons.

**Evidence:** PNG.

---

### screen.settings.macos (Required)

**check_id:** `screen.settings.macos`

**What:** The settings screen renders on macOS.

**How:** `DEMO_SCREEN=settings ./bin/demo_app`, capture.

**Pass criteria:** As above. macOS-native pickers, sliders, switches.

**Evidence:** PNG.

---

### screen.settings.ios (Required)

**check_id:** `screen.settings.ios`

**What:** The settings screen renders on iOS.

**How:** Launch with `DEMO_SCREEN=settings`, capture.

**Pass criteria:** As above. iOS-native UISwitch, UIPickerView, UIDatePicker.

**Evidence:** PNG.

---

### screen.tier3.web (Required)

**check_id:** `screen.tier3.web`

**What:** The Tier 3 demo screen renders on web using the documented web fallbacks.

**How:** Navigate to `tier3.html` at 1280×800. Capture initial state. Tap the "Show action sheet" button; capture the resulting modal. Right-click a row in the list; capture the context menu.

**Pass criteria:**
- The action sheet appears as a bottom sheet (web fallback, not a system iOS action sheet — that wouldn't be possible).
- The context menu appears as a positioned dropdown.

**Evidence:** 3 PNGs (initial, action sheet open, context menu open).

---

### screen.tier3.macos (Required)

**check_id:** `screen.tier3.macos`

**What:** The Tier 3 demo screen on macOS uses native ContextMenu where applicable.

**How:** Launch macOS with `DEMO_SCREEN=tier3`. Capture initial. Right-click a list row; capture the native macOS context menu. Click the action-sheet button; capture the macOS Sheet that appears.

**Pass criteria:**
- macOS context menu (NSMenu) appears on right-click.
- A macOS sheet (NSPanel) appears where the iOS action sheet would.

**Evidence:** 2 PNGs.

---

### screen.tier3.ios (Required)

**check_id:** `screen.tier3.ios`

**What:** The Tier 3 demo screen on iOS uses native ActionSheet and ContextMenu.

**How:** Launch iOS with `DEMO_SCREEN=tier3`. Capture initial state. Tap "Show action sheet"; capture the system UIAlertController (.actionSheet) that appears. Long-press a list row; capture the UIMenuController context menu.

**Pass criteria:**
- Native iOS action sheet appears (system styling, not the web fallback).
- Native iOS context menu appears on long-press.

**Evidence:** 2 PNGs (action sheet, context menu).

---

### resize.web (Required)

**check_id:** `resize.web`

**What:** The web demo reflows correctly at 1280, 768, and 375 viewports — no horizontal overflow, no clipped touch targets, fluid transition.

**How:** For each viewport in {1280×800, 768×1024, 375×667}, navigate to `dashboard-activity.html`, `detail.html`, and `settings.html`. Capture each. Verify visually:
- No horizontal scroll bar at any viewport.
- All interactive elements meet 44×44 minimum touch target at 375 (phase 2 invariant).
- Layout has visibly different number of columns at different widths (grid collapses from 3 → 2 → 1 column).

**Pass criteria:** 9 screenshots (3 screens × 3 viewports), no overflow visible in any, touch targets are not clipped.

**Evidence:** 9 PNGs named `resize.web-{screen}-{viewport}.png`.

---

### resize.macos (Required)

**check_id:** `resize.macos`

**Bar:** conformance — the reflow is continuous, not stepped, and is verified at multiple intermediate widths (not just the endpoints).

**What:** The macOS app reflows correctly and continuously when its window is resized between wide and narrow extents.

**How:** Launch with `DEMO_SCREEN=detail`. Drive the resize via the System Events helper documented in `../../rubric/behavior-simulation-toolkit.md` §1.9 (the AX-native resize path requires extensions A2 + A3 which may not yet be wired; the System Events path is the supported fallback). For each width in the sequence, capture both a window screenshot AND the per-element bounding boxes of the three primary buttons (Edit, Share, Delete) via System Events geometry queries (toolkit §1.4 `element_rect`):

```bash
DEMO_SCREEN=detail ./bin/demo_app &
DEMO_PID=$!
sleep 2
for w in 1280 960 768 480 375; do
  osascript -e "tell application \"System Events\" to tell process \"demo_app\" to set size of front window to {$w, 800}"
  sleep 0.6   # let layout settle (≥ 1.5 × ease_emphasized duration; toolkit notes this is the
              # standard settle delay before measuring or capturing after a resize)
  screencapture -l $(./scripts/find_window_id.sh demo_app) -t png -o \
    handoff/phase-06-evidence-DATE/screenshots/resize.macos-detail-$w.png
  # Geometry: drive a Crystal helper script that attaches via UI::AXTest::App.connect(pid)
  # and reads each button's position+size via osascript element_rect helper (toolkit §1.4)
  crystal run scripts/capture_resize_bboxes.cr -- --pid=$DEMO_PID --width=$w \
    --out=handoff/phase-06-evidence-DATE/inspections/resize.macos-detail-bboxes.json
done
kill $DEMO_PID
```

If `scripts/capture_resize_bboxes.cr` does not yet exist, the validator may write a single-purpose helper in `handoff/phase-06-evidence-DATE/scripts/` for the run and discard it after — note the temporary helper in the check's `notes` field per `rubric/validation_criteria.md` §Temporary edits.

**Pass criteria:**
1. All five captures exist and are non-empty PNGs.
2. The detail screen's column count transitions from 2 (at 1280) to 1 (at 480 and below). The 768 capture may be on either side of the breakpoint per Phase 2's `clamp()` rules — record which.
3. No horizontal scroll bar appears at any width (verify via NSScrollView's hasHorizontalScroller property in the AX dump, or visually from the capture).
4. Every interactive element's measured bounding box has width > 0 and height ≥ 44 at every width — proves no element collapsed to zero or below the touch-target minimum during the reflow.
5. **Monotonic narrowing.** Sort the five widths descending; for each pair of adjacent widths `(w_i, w_{i+1})` with `w_i > w_{i+1}`, assert the Edit button's measured `frame.size.width` does not increase as the window narrows. A non-monotonic step (button gets wider as window gets narrower) usually indicates a layout-flip and fails the continuous-reflow contract.
6. The captures form a **continuous** progression — comparing the 960 capture to the 768 capture, no widget swaps to a completely different layout (the reflow should be a smooth narrowing, not a layout flip). Verify by visual review of the five captures in sequence; record the observation in notes.

**Evidence:** 5 PNGs (`resize.macos-detail-{1280,960,768,480,375}.png`), `inspections/resize.macos-detail-bboxes.json`.

### nav.flow-end-to-end-macos (Required)

**check_id:** `nav.flow-end-to-end-macos`

**Bar:** behavior — every navigation transition fires (driven by real `AXUIElementPerformAction` calls, not method invocations into Crystal) and produces the expected next view. Back-navigation restores the prior screen's state, not just its presence.

**What:** The full navigation flow (Sign in → Dashboard → tap a card → Detail → back → Dashboard → switch to Settings tab → Open settings → Settings) works end-to-end on macOS via the `UI::AXTest` harness, with state restoration on back-navigation verified.

**How:** Write a temporary AX behavior spec at `spec/samples/macos_nav_flow_e2e_spec.cr` modeled on `spec/ui/hig_validation/macos_visual_spec.cr`. Cross-reference `../../rubric/behavior-simulation-toolkit.md` §1 (AXTest), §1.5 (perform_action), §4.3 (navigation flow pattern). The spec launches `./bin/demo_app`, attaches via `UI::AXTest::App.connect(pid)`, and drives every transition through synthetic AX presses. For each step, locate by `AXIdentifier` (toolkit §1.4) — labels are localized; identifiers are not. After each press, **wait** for the next marker element (3 s timeout, fail closed) AND assert the prior marker is gone.

Step matrix:
```
 1. Locate AXButton with AXIdentifier "screen-sign-in-primary-cta". Capture pre-press AX tree marker
    snapshot. perform_action(button, "AXPress"). Wait for "screen-dashboard-activity-tab" AND
    confirm "screen-sign-in-primary-cta" is gone.
 2. From dashboard: scroll if needed so "screen-dashboard-activity-card-0" is hittable. Record the
    card's visible title via element.title — used later for back-restore assertion.
 3. perform_action(card-0, "AXPress"). Wait for "screen-detail-hero" AND confirm the detail screen's
    title matches the card title captured in step 2.
 4. Locate "screen-detail-back". perform_action(back, "AXPress"). Wait for
    "screen-dashboard-activity-card-0" to reappear. Assert the originally-tapped card is at the same
    scroll position (read AXChildren of the scroll container and confirm card-0 is at the same index)
    — this is the back-restore assertion that catches lost state.
 5. perform_action("screen-dashboard-settings-tab", "AXPress"). Wait for
    "screen-dashboard-settings-open-full".
 6. perform_action("screen-dashboard-settings-open-full", "AXPress"). Wait for "screen-settings-form".
 7. Capture final screenshot via app.screenshot(path, window_title: "Demo").
```

Run via: `crystal spec spec/samples/macos_nav_flow_e2e_spec.cr -Dmacos`.

**Pass criteria:**
1. Every step's wait succeeds within its 3-second timeout.
2. Every transition leaves the prior screen's marker absent from the AX tree.
3. Step 3's detail title equals step 2's card title (the click selected the right card).
4. Step 4's back-restore assertion holds (card-0 is at the same index in the scroll container as before navigation).
5. Final screenshot shows the Settings screen.

**Revert:** delete the temporary spec file. Confirm `git status --short` is clean.

**Evidence:** `test_output/nav.flow-end-to-end-macos.log`, `screenshots/nav.flow-end-to-end-macos-{step1..7}.png`, `inspections/nav.flow-end-to-end-macos-state.json` (the captured titles, indices, and per-step marker presence).

### nav.flow-end-to-end-ios (Required)

**check_id:** `nav.flow-end-to-end-ios`

**Bar:** behavior.

**What:** Same navigation flow on iOS via XCUITest, with state restoration on back-navigation verified.

**How:** Add a temporary XCUITest to `samples/initiative-cross-platform-ui-demo/ios/UITests/` named `NavFlowEndToEndTests.swift`. Reference `../../rubric/behavior-simulation-toolkit.md` §2 (XCUITest), §2.6 (tabs/nav/modals), §4.3. Drive every step via `XCUIElement.tap()` against `accessibilityIdentifier`-located buttons; for tab bar use the visible label (`app.tabBars.buttons["Activity"]`) per the SwiftUI TabView caveat documented in the toolkit. After each tap, **wait** for the next-screen marker via `waitForExistence(timeout: 3)` AND assert the prior screen's marker is gone (`XCTAssertFalse(prior.exists)`).

```swift
// Skeleton — full test wires identifiers from the demo's IDs map
let app = XCUIApplication()
app.launch()

// Step 1: sign-in CTA
let cta = app.buttons["screen-sign-in-primary-cta"]
XCTAssertTrue(cta.waitForExistence(timeout: 5))
cta.tap()
XCTAssertTrue(app.tabBars.buttons["Activity"].waitForExistence(timeout: 3))
XCTAssertFalse(cta.exists)

// Step 2: card-0 — capture title for back-restore assertion
let card0 = app.buttons["screen-dashboard-activity-card-0"]
XCTAssertTrue(card0.waitForExistence(timeout: 3))
let card0Title = card0.label   // capture before tap

// Step 3: tap card → detail
card0.tap()
let detailHero  = app.otherElements["screen-detail-hero"]
let detailTitle = app.staticTexts["screen-detail-title"]
XCTAssertTrue(detailHero.waitForExistence(timeout: 3))
XCTAssertEqual(detailTitle.label, card0Title)   // right card opened

// Step 4: back, verify card-0 still selected/visible at same position
app.buttons["screen-detail-back"].tap()
XCTAssertTrue(card0.waitForExistence(timeout: 3))
XCTAssertTrue(card0.isHittable)                  // not occluded
// scroll-position restore: capture frame.minY before nav, compare after — fixture writes it to a probe label

// Step 5–7: Settings tab → open full → form
app.tabBars.buttons["Settings"].tap()
app.buttons["screen-dashboard-settings-open-full"].tap()
let form = app.otherElements["screen-settings-form"]
XCTAssertTrue(form.waitForExistence(timeout: 3))

// Final screenshot
let shot = XCUIScreen.main.screenshot()
let att  = XCTAttachment(screenshot: shot)
att.name = "nav-flow-final.png"; att.lifetime = .keepAlways; add(att)
```

Run via `xcodebuild test -only-testing CrystalDemoUITests/NavFlowEndToEndTests/testFullFlow`.

**Pass criteria:**
1. Every `waitForExistence(timeout: 3)` returns true.
2. Step 3's `detailTitle.label == card0Title` (the tap selected the correct card).
3. Step 4's `card0.isHittable` after back (back-restore actually restored the scroll position).
4. Final screenshot shows the Settings form.

**Revert:** remove the temporary test file. Verify clean tree.

**Evidence:** `test_output/nav.flow-end-to-end-ios.log`, `screenshots/nav.flow-end-to-end-ios-{step1..7}.png`, `inspections/nav.flow-end-to-end-ios-state.json`.

### nav.flow-end-to-end-web (Required)

**check_id:** `nav.flow-end-to-end-web`

**Bar:** behavior — links resolve to the expected pages; clicks are real synthetic clicks on the rendered DOM (not `location.assign`); back-navigation restores prior state including scroll position.

**What:** Web flow: starting at `sign-in.html`, the Sign-in primary CTA links to `dashboard-activity.html`; the first card links to `detail.html`; the back link returns to `dashboard-activity.html`; the Settings tab is reachable via a link to `dashboard-settings.html`; the Open Settings button on that page links to `settings.html`. Each navigation is verified by (a) the URL changed to the expected target, (b) the new page's marker element is present, (c) no console errors were logged during the transition, (d) on back-navigation the prior page's scroll position is restored.

**How:** Drive Chrome via CDP per `../../rubric/behavior-simulation-toolkit.md` §3, §4.3 — launch headless Chrome, open a CDP session, enable `Page`, `Runtime`, and `Log`. For each step:

1. Read the trigger's `getBoundingClientRect()` via `Runtime.evaluate`.
2. Trigger the click: for normal links, `Runtime.evaluate` `document.querySelector('[data-testid="..."]').click()` is sufficient; for navigations that depend on a real trusted click (custom widgets), dispatch via `Input.dispatchMouseEvent` (mousePressed + mouseReleased) at the rect center (toolkit §3.3).
3. Wait for `window.location.pathname` to equal the expected target — poll via `Runtime.evaluate` at 50 ms intervals with a 2 s timeout.
4. Wait for the next-screen marker element via `Runtime.evaluate` (`document.querySelector('[data-testid="..."]')` returns non-null, 2 s timeout).
5. Collect console errors per toolkit §3.8 (either subscribe to `Log.entryAdded` / `Runtime.consoleAPICalled` events on the CDP socket, or read the pre-injected `window.__consoleErrors` accumulator); assert zero `error`-level entries were logged during the transition.

Before navigating from the dashboard to detail, scroll the dashboard to a non-zero position and stash `window.__priorScrollY = scrollY` via `Runtime.evaluate`. After back-navigation, assert `scrollY === window.__priorScrollY ± 4 px` (allowing one frame of rounding).

**Pass criteria:**
1. Every step's URL matches expected.
2. Every step's marker element is present after the wait.
3. Zero console errors logged during any transition.
4. No broken-image or 404 in `read_network_requests` for any transition.
5. Back-navigation restores scroll position to within ±4 px of the captured pre-nav `scrollY`.

**Evidence:** `inspections/nav.flow-end-to-end-web-urls.json` (the URLs visited in order), `inspections/nav.flow-end-to-end-web-state.json` (per-step `{marker_present, console_errors, scroll_y}`), `screenshots/nav.flow-end-to-end-web-{step1..8}.png`.

### tier3.action-sheet-open-and-dismiss-ios (Required)

**check_id:** `tier3.action-sheet-open-and-dismiss-ios`

**Bar:** behavior — the sheet opens AND every documented dismiss path closes it.

**What:** On iOS, the Tier 3 demo's `Show action sheet` button opens a native UIAlertController.actionSheet, and the sheet dismisses on (a) tapping the primary action, (b) tapping Cancel, and (c) tapping the backdrop (where iOS supports it).

**How:** XCUITest in the iOS sample's UITests target. The test launches with `DEMO_SCREEN=tier3`, finds the Show button, taps it; asserts the sheet's accessibility tree is present; performs each dismiss path in turn (resetting the sheet each time):
```swift
// pseudocode
app.buttons["screen-tier3-show-action-sheet"].tap()
XCTAssertTrue(app.sheets.element.waitForExistence(timeout: 2))
app.buttons["screen-tier3-action-primary"].tap()  // primary action dismisses
XCTAssertFalse(app.sheets.element.exists)
// re-open
app.buttons["screen-tier3-show-action-sheet"].tap()
app.sheets.buttons["Cancel"].tap()
XCTAssertFalse(app.sheets.element.exists)
// re-open
app.buttons["screen-tier3-show-action-sheet"].tap()
// backdrop tap: tap a known empty region above the sheet
app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
XCTAssertFalse(app.sheets.element.waitForExistence(timeout: 1))  // false = dismissed within timeout
```

**Pass criteria:** each dismiss path leaves the sheet absent from the accessibility tree; the Show button regains focus (verify with `app.buttons["screen-tier3-show-action-sheet"].hasKeyboardFocus` if available, else verify the element is hittable again).

**Evidence:** `test_output/tier3.action-sheet-open-and-dismiss-ios.log`, three pairs of screenshots `tier3.action-sheet-open-and-dismiss-ios-{primary,cancel,backdrop}-{open,dismissed}.png`.

### tier3.action-sheet-open-and-dismiss-web (Required)

**check_id:** `tier3.action-sheet-open-and-dismiss-web`

**Bar:** behavior — the web fallback fulfills the same contract as iOS, including focus restoration.

**What:** On web, the Tier 3 demo's action-sheet web fallback opens, dismisses via primary tap, cancel, backdrop click, and Escape key; focus returns to the trigger after dismiss.

**How:** `Page.navigate` to `tier3.html` via CDP per `../../rubric/behavior-simulation-toolkit.md` §3. For each dismiss path, `Runtime.evaluate` to install a JS event listener that records `ap:action-sheet:dismiss` events into `window.__phase6DismissLog`, then perform the path (Escape via `Input.dispatchKeyEvent`, backdrop via `Input.dispatchMouseEvent` at the measured backdrop center, primary/cancel via programmatic `.click()` through `Runtime.evaluate` — see toolkit §3.6):
1. Click the `screen-tier3-show-action-sheet` trigger; verify `data-presented="true"`; verify `document.activeElement` is inside the panel.
2. Click the primary action button; verify dismiss event fires; verify `data-presented="false"`; verify `document.activeElement` equals the original trigger.
3. Re-open. Click the Cancel button; same assertions with `reason: 'cancel'` (or whatever the fallback emits).
4. Re-open. Click the backdrop (`.ap-action-sheet__backdrop`); same assertions with `reason: 'backdrop'`.
5. Re-open. Press Escape; same assertions with `reason: 'escape'`.

**Pass criteria:** every dismiss path fires the dismiss event with the expected reason; the sheet is gone from the DOM (`data-presented="false"`); focus returns to the trigger.

**Evidence:** `inspections/tier3.action-sheet-open-and-dismiss-web.json` — array of four dismiss-path results with `{path, dismiss_event, post_state, active_element}`.

---

### quad.artifact (Required)

**check_id:** `quad.artifact`

**What:** `output/initiative-demo/quad-comparison.html` exists, is generated by `scripts/capture_demo_quad.cr`, and renders correctly in a browser.

**How:**
```bash
rm -rf output/initiative-demo/quad-evidence output/initiative-demo/quad-comparison.html
crystal run scripts/capture_demo_quad.cr 2>&1 | tee {EVIDENCE}/test_output/quad.artifact.log
ls -la output/initiative-demo/quad-comparison.html
```
Then open `output/initiative-demo/quad-comparison.html` in headless Chrome via CDP (`Page.navigate` to the `file://` URL per `../../rubric/behavior-simulation-toolkit.md` §3.2) and capture via `Page.captureScreenshot` with `captureBeyondViewport: true`.

**Pass criteria:**
- Script completes with exit code 0.
- The HTML file exists, is non-empty.
- Opening it in a browser shows a CSS grid with one section per screen (5 sections), each section showing captures at multiple viewports in light + dark.
- Every `<img>` tag resolves (no broken-image icons visible in the screenshot).

**Evidence:** `test_output/quad.artifact.log`, `screenshots/quad.artifact.png` (the rendered comparison page).

---

### brand.override-visible (Required)

**check_id:** `brand.override-visible`

**What:** The Demo demo's brand is recognizably different from the default amber brand. Measured objectively via CIE Lab ΔE on the primary button's dominant hue, **not** by an eyeball "are these the same brand?" comparison.

**How:**

1. Capture a screenshot of the sign-in screen on web at desktop viewport, light scheme, **with DemoBrand applied**. This capture already exists from `screen.sign-in.web-desktop-light`; reuse it. The "primary button" is the prominently positioned call-to-action button on the sign-in screen (per the implementation brief's sign-in layout).
2. Sample the dominant hue of the primary button background **at the center pixel of the button's bounding box**. Method:
   - Decode the captured PNG to RGB.
   - Locate the button's bounding box. If the demo's sign-in screen uses a known `data-testid="primary-cta"` (or accessibility identifier on native), use it; otherwise compute the bbox from a reference fixture (`inspections/sign-in-primary-button.bbox.json` written by the implementer's screenshot harness — see Phase 6 implementation handoff Known Concerns).
   - Read the RGB triple at the geometric center of that bounding box. This is the "Demo sample sRGB".
3. Compute the same center-pixel sRGB for the amber-default theme's primary button:
   - The amber-default expected sRGB is committed as a reference value in `inspections/amber-default-primary-button.rgb.json` (the implementer's handoff supplies this; if absent, derive it once by sampling the amber-default `web_tokens.css` `--ap-color-brand-primary` value through the same OKLCH→sRGB conversion used by the design-token generator).
   - This is the "Amber reference sRGB". No second screenshot capture is required — the reference is a number, not a PNG. (Capturing a second screenshot with amber applied is permitted as a sanity check, but optional.)
4. Convert both sRGB triples to CIE Lab via the standard sRGB → linear-sRGB → XYZ → Lab pipeline (D65 illuminant, 2° observer). Inline math:
   - Linearize each channel: `c_lin = (c/12.92)` if `c <= 0.04045` else `((c+0.055)/1.055)^2.4`.
   - sRGB linear → XYZ via the standard D65 matrix.
   - XYZ → Lab using `f(t) = t^(1/3)` for `t > (6/29)^3`, else `(1/3)(29/6)^2 t + 4/29`.
5. Compute Lab ΔE (use ΔE\*76 / Euclidean Lab distance — adequate at this scale; no need for CIEDE2000 unless the implementer's handoff already produced ΔE2000 values).

**Pass criteria:** ΔE > 30. A ΔE > 30 is "visibly distinct" — well past the JND threshold (~2.3) and past the "different category of color" threshold (~10). If the captures' computed ΔE ≤ 30, **fail** with a note showing both Lab triples and the computed distance.

**Sampling method spec (so a future validator gets the same answer):**

- Pixel sample is **a single pixel** at the geometric center of the button's bounding box. Do not average a region — a single center pixel is more robust against anti-aliasing.
- sRGB values are in the range `[0, 255]` per channel from the PNG; convert to `[0.0, 1.0]` before linearization.
- Use a deterministic Lab pipeline; do not lean on platform-specific colorimetric libraries that may apply ICC profile transforms. The PNG is assumed to be sRGB (matching the headless-Chrome capture profile used elsewhere in this validator).
- Record both sRGB triples, both Lab triples, and the computed ΔE in the evidence file.

**Evidence:** the existing Demo sign-in screenshot (`screenshots/screen.sign-in.web-desktop-light.png`), and `inspections/brand.override-visible.json` containing:

```json
{
  "demo_srgb": [223, 95, 73],
  "amber_srgb":    [62, 119, 109],
  "demo_lab":  [58.7, 47.2, 38.6],
  "amber_lab":     [47.1, -19.3, 0.4],
  "delta_e_76":    78.4,
  "threshold":     30,
  "passed":        true
}
```

No source-code modification is required (no comment-out / revert dance). The reference amber sRGB is a fixture, not a re-rendered screenshot.

---

### tier3.renders (Required)

**check_id:** `tier3.renders`

**What:** Combined verification that Tier 3 widgets behave correctly per platform.

**How:** Cross-reference the captures from `screen.tier3.web`, `screen.tier3.macos`, `screen.tier3.ios`. Verify:
- iOS shows native UIAlertController.actionSheet (recognizable system styling) and native UIMenuController context menu.
- macOS shows native NSMenu context menu and an NSPanel sheet (not an iOS-style action sheet).
- Web shows the documented `*WithWebFallback` variants — bottom-sheet pattern for action sheet, dropdown for context menu.

**Pass criteria:** All three platforms show the platform-appropriate widget per phase 4's contract. Web does not show a fake "system" action sheet — it explicitly uses the fallback class.

**Evidence:** Reference the already-captured tier3 PNGs in `notes` field; no new evidence needed.

---

### accessibility.web (Required)

**check_id:** `accessibility.web`

**What:** axe-core run on the web demo pages produces zero violations at "serious" or higher severity.

**How:**
```bash
# Use the existing axe runner pattern or write a one-off script that loads each
# demo page in headless chrome and runs axe-core.
crystal run scripts/axe_web_demo_audit.cr --pages=output/initiative-demo/sign-in.html,output/initiative-demo/dashboard-activity.html,output/initiative-demo/dashboard-friends.html,output/initiative-demo/dashboard-settings.html,output/initiative-demo/detail.html,output/initiative-demo/settings.html,output/initiative-demo/tier3.html \
  2>&1 | tee {EVIDENCE}/test_output/accessibility.web.log
```
(If the existing axe runner does not accept arbitrary paths, run it per-page in a loop, capturing each output to `audits/accessibility.web-{screen}-axe.json`.)

**Pass criteria:**
- axe-core completes for all 7 screens.
- Zero violations at "serious" or "critical" severity.
- "Moderate" and "minor" violations are listed in notes but do not cause failure (full audit is phase 7).

**Evidence:** `test_output/accessibility.web.log`, plus per-page `audits/accessibility.web-{screen}-axe.json`.

---

### specs (Required)

**check_id:** `specs`

**What:** The full Crystal spec suite passes, including the new cross-target spec for this phase.

**How:**
```bash
cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline
crystal spec 2>&1 | tee {EVIDENCE}/test_output/specs.log
crystal spec spec/samples/initiative_cross_platform_ui_demo_spec.cr -Dmacos 2>&1 \
  | tee -a {EVIDENCE}/test_output/specs.log
```
(For `-Dios`, run the spec under cross-compile no-codegen mode if a sim is not available: `crystal build --no-codegen spec/samples/initiative_cross_platform_ui_demo_spec.cr -Dios`.)

**Pass criteria:**
- Default suite: `0 failures, 0 errors`.
- Cross-target spec under macOS: `0 failures, 0 errors`.
- Cross-target spec compiles under `-Dios` (no-codegen acceptable).
- No new pending specs introduced in this phase (pending in other phases are not your concern).

**Evidence:** `test_output/specs.log`.

---

## Optional checks

The following are recorded but do not affect verdict.

### opt.dark-mode-parity (Optional)

**check_id:** `opt.dark-mode-parity`

**What:** Dark-mode captures of each screen on each platform read as the same brand as the light captures.

**How:** Cross-reference the dark captures already present in the quad comparison. Verify subjectively that dark variants look like the *same* brand, not a different one.

**Pass criteria:** Subjective; record observations.

---

### opt.fluid-resize-video (Optional)

**check_id:** `opt.fluid-resize-video`

**What:** Record a short screen capture of resizing the macOS demo window (or the web browser) between extents to verify the transition is fluid, not stepped.

**How:** Use macOS screen recording or `xcrun simctl io recordVideo` (not for resize but for reference).

**Pass criteria:** No visible layout-stepping or content-clipping during resize.

**Evidence:** `screenshots/opt.fluid-resize-video.mp4`.

---

## Summary table

| # | check_id | Required | What |
|---|----------|----------|------|
| 1 | `build.web` | yes | Web build produces output |
| 2 | `build.macos` | yes | macOS binary builds and launches |
| 3 | `build.ios` | yes | iOS app builds and launches on iPhone 17 Pro |
| 4 | `screen.sign-in.web` | yes | Sign-in renders on web |
| 5 | `screen.sign-in.macos` | yes | Sign-in renders on macOS |
| 6 | `screen.sign-in.ios` | yes | Sign-in renders on iOS |
| 7 | `screen.dashboard.web` | yes | Dashboard (3 tabs) on web |
| 8 | `screen.dashboard.macos` | yes | Dashboard (3 tabs) on macOS |
| 9 | `screen.dashboard.ios` | yes | Dashboard (3 tabs) on iOS |
| 10 | `screen.detail.web` | yes | Detail on web |
| 11 | `screen.detail.macos` | yes | Detail on macOS |
| 12 | `screen.detail.ios` | yes | Detail on iOS |
| 13 | `screen.settings.web` | yes | Settings on web |
| 14 | `screen.settings.macos` | yes | Settings on macOS |
| 15 | `screen.settings.ios` | yes | Settings on iOS |
| 16 | `screen.tier3.web` | yes | Tier 3 on web (with fallbacks) |
| 17 | `screen.tier3.macos` | yes | Tier 3 on macOS (native ContextMenu + Sheet) |
| 18 | `screen.tier3.ios` | yes | Tier 3 on iOS (native ActionSheet + ContextMenu) |
| 19 | `resize.web` | yes | Web reflows at 1280/768/375 |
| 20 | `resize.macos` | yes | macOS window reflows wide↔narrow |
| 21 | `quad.artifact` | yes | Quad-comparison HTML generated and viewable |
| 22 | `brand.override-visible` | yes | Coral brand visibly distinct from default amber |
| 23 | `tier3.renders` | yes | Combined Tier 3 verification across platforms |
| 24 | `accessibility.web` | yes | axe-core zero serious/critical |
| 25 | `specs` | yes | Crystal spec suite green |

(Counting `tier3.renders` and the per-platform `screen.tier3.*` checks separately is intentional — the per-platform checks verify rendering; `tier3.renders` verifies the cross-platform contract.)

Behavior + conformance checks added in the revision pass (numbered after the original 25):

| # | check_id | Required | Bar | What |
|---|----------|----------|-----|------|
| 26 | `nav.flow-end-to-end-macos` | yes | behavior | macOS nav flow end-to-end |
| 27 | `nav.flow-end-to-end-ios` | yes | behavior | iOS nav flow end-to-end |
| 28 | `nav.flow-end-to-end-web` | yes | behavior | Web nav flow end-to-end |
| 29 | `tier3.action-sheet-open-and-dismiss-ios` | yes | behavior | iOS action sheet open + every dismiss path |
| 30 | `tier3.action-sheet-open-and-dismiss-web` | yes | behavior | Web action-sheet fallback open + every dismiss path |

`resize.macos` is upgraded from a 2-capture check to a 5-capture continuous-reflow conformance check (same `check_id`, expanded scope).

Total: 30 required checks + 2 optional.

---

## Returning your report

Per `rubric/validation_criteria.md` — return a single message containing:

- `## Verdict` (PASS or FAIL)
- `## GATE_REPORT` (the full JSON, per `rubric/gate_report_schema.md`)
- `## Summary` (2–4 sentence prose)

Do not narrate the run inline. The evidence directory is the narrative.

If you marked any check `blocked: true`, briefly explain in the summary which environment dependency is missing — the team lead may be able to unblock and re-run rather than send the work back to the implementer.

---

End of phase 6 validation rubric.
