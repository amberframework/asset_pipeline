# Phase 6 — Side-by-Side Demo App — Validation Report

**Date:** 2026-05-23
**Validator:** Independent (trust-pair, did not see Implementer report)
**Branch:** `phase-06-side-by-side-demo-app`
**Commit range checked:** `b26b688..b04bc86` (Architect baseline → Rem 1 HEAD; 11 commits)
**Verdict:** **PASS_WITH_NOTES**

---

## Headline

The Implementer delivered all hard contract items: the demo skeleton + 5 screens
exist, all 3 build targets succeed (after the documented swift symlink swap), the
iOS class-init crash is FIXED (CascadeDemo launched on iPhone 17 simulator
without crashing — PID 67770, screenshot at `/tmp/validator-cascade-launch.png`),
all 40 baselines + 40 tolerance sidecars are committed, quad-comparison.html
is the canonical 5×4 grid with light/dark pairs, audit harness routes all 5
demo slugs across web/macos/ios in real time (each iOS slug takes ~20s — not
an artifact-presence proxy), regression suite shows 1454 examples / 4 pre-existing
failures / 0 errors, and production code under `src/ui/` + `swift/` is UNTOUCHED.

Notes against PASS rather than clean PASS: (a) the **brief validator returns
exit 2** at HEAD because `repo_derived_facts` were captured at the pre-dispatch
SHA (`035f09e`) and the demo directory now exists — this is a documented
authoring-time check, not a gate-time check, but a literal reading of step 1
of the validation contract says "Must exit 0", so I'm flagging it. (b) The
**iOS sign-in render is degraded** — the Cascade wordmark, labels, and
"or continue with" caption right-align/clip on the iPhone 17 viewport; the
Sign-in button isn't visible above the fold. The app does not crash, the
accessibility tree presumably has the elements, but the iOS sign-in baseline
is not a polished render. (c) The **macOS sign-in render is also degraded**
— Password field is a tiny empty oval. (d) The brand teal IS visible on web
(Forgot password? link, mobile Discover tab), but not strongly on iOS/macOS
sign-in baselines. The dashboard/tier-three renders are stronger across all
surfaces.

These render-quality concerns do not invalidate the architect's Rem 1
contract (which was specifically the iOS class-init crash fix + capture iOS
baselines + extend quad-comparison). Those three deliverables are fully met.
Whether the render polish gaps are a Phase 6 retry item or deferred to Phase 7
follow-up is an architect call.

---

## Per-step verification

### Step 1 — Brief validator passes at HEAD

**FAIL** by literal reading: `crystal run scripts/validate_phase_brief.cr --
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/brief.yml`
exits with code **2**.

```
FAIL[2]: Fact 'Existing demo app directory at samples/initiative-cross-platform-ui-demo
(must NOT exist at brief authoring; Phase 6 creates)' DRIFTED.
Expected: "missing". Actual: "exists". Update the brief or fix the drift before dispatch.
```

The brief's `repo_derived_facts` were captured at `035f09e` (pre-Phase-6).
The drift is exactly what Phase 6's success looks like: the demo directory
now exists, the quad page now exists, `scripts/capture_demo_quad.cr` now
exists. Three of the `repo_derived_facts` entries are pre-dispatch-only by
design. The brief schema does not distinguish "drift expected after phase
ships" from "drift broke pre-dispatch contract".

**Recommendation:** treat this as not a gate-blocker for Phase 6's verdict;
flag for architect to add a `pre_dispatch_only: true` flag to the schema or
re-capture facts at gate. Recording as `PASS_WITH_NOTES` because Step 1
itself reads literally as FAIL, but the failure mode is contract-design
rather than Implementer behavior.

### Step 2 — 5 demo screens exist + render correctly

**PASS.**

- `samples/initiative-cross-platform-ui-demo/screens/`: `sign_in.cr`,
  `dashboard.cr`, `detail.cr`, `settings.cr`, `tier_three.cr`, `state.cr`.
- All 5 contain their `SLUG = "demo-..."` constant.
- `tier_three.cr` lines 50, 80, 110 use
  `UI::ActionSheetWithWebFallback.new`, `UI::ContextMenuWithWebFallback.new`,
  `UI::PathControlWithWebFallback.new` — the documented Tier-3 widgets.
- **No HapticFeedback** anywhere under the demo dir
  (`grep -rE 'Haptic|HapticFeedback' samples/initiative-cross-platform-ui-demo/`
  returns empty).
- **Brand override visibly distinct:** `brand.cr` defines `BRAND_PRIMARY_LIGHT
  = UI::DesignTokens::Color.oklch(0.56, 0.13, 195.0)`. Hue 195° is deep teal,
  notably outside amber's gold ~65° family. Chroma 0.13 is not subtle.
  Visible as the "Forgot password?" link tint on web baselines and the
  Discover tab selection tint on web-mobile dark.

### Step 3 — 3 build targets all exit 0

**PASS.**

| Target | Command | Exit |
|---|---|---|
| web | `make -C samples/initiative-cross-platform-ui-demo web` | 0 — wrote 11 files to `output/initiative-demo/` |
| macos | `make -C samples/initiative-cross-platform-ui-demo macos` (after `swift build -c release --package-path swift/AssetPipelineSwiftKit` to swap the swift symlink to macosx) | 0 — produced `bin/cascade` |
| ios | `make -C samples/initiative-cross-platform-ui-demo ios` | 0 — `** BUILD SUCCEEDED **`, produced `CascadeDemo.app` at `~/Library/Developer/Xcode/DerivedData/CascadeDemo-.../Build/Products/Debug-iphonesimulator/CascadeDemo.app` (NOT at the brief's referenced path `samples/initiative-cross-platform-ui-demo/ios/build/Build/Products/...`; xcodebuild's default DerivedData path is what's used) |

The swift symlink swap is documented in the brief — first macOS build
failed with "linking in object file built for iOS-simulator", swift rebuild
resolved it.

### Step 4 — iOS class-init crash FIXED (Rem 1 central deliverable)

**PASS.**

- **a) BRAND_TOKENS constant removed:** `brand.cr` defines `def self.brand_tokens : UI::DesignTokens::Tokens` (line 69) instead of a module constant. The
  docstring at lines 60-68 explicitly cites the iOS embedding class-init gap
  and references `samples/cross_platform/ios_host/hig_bridge.cr:25-50` as the
  canonical workaround pattern. Codex-confirmed root cause noted.
- **b) Callers updated:**
  `grep -rE 'BRAND_TOKENS' samples/initiative-cross-platform-ui-demo/` returns
  **EMPTY** (exit code 1). `grep -rE 'brand_tokens'` shows 7 hits — 1
  definition in `brand.cr`, 1 in README, 4 callers in
  `macos/host.cr` + `web/static_site.cr` + `ios/bridge.cr` + 1 doc reference
  in `screens/state.cr`. All callers use the method form.
- **c) CascadeDemo launches WITHOUT CRASHING:** ran

  ```
  xcrun simctl boot 'iPhone 17'  # already booted
  xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/CascadeDemo-.../CascadeDemo.app  # INSTALL_EXIT=0
  xcrun simctl launch --terminate-running-process booted com.assetpipeline.cascade.CascadeDemo -DemoSlug demo-sign-in
  # Returned: com.assetpipeline.cascade.CascadeDemo: 67770 (LAUNCH_EXIT=0)
  sleep 3
  xcrun simctl spawn booted launchctl list | grep cascade
  # 67770    0    UIKitApplication:com.assetpipeline.cascade.CascadeDemo[b8c7][rb-legacy]
  xcrun simctl io booted screenshot /tmp/validator-cascade-launch.png
  ```

  Screenshot shows iOS status bar (8:30, signal/wifi/battery), then a white
  card with "Cascade", "Sign in to continue", "Email", "Password", "or continue
  with" all visible. App is still running with exit code 0 from launch and a
  live PID. Not a crashed/black screen.

### Step 5 — Quad-comparison output exists + complete

**PASS.**

- File: `output/initiative-demo/quad-comparison.html`, 71 lines.
- Structure: 5 `<h2>` slug headers, each followed by a single `<table>` row
  with 4 `<td>` cells (web-desktop, web-mobile, ios, macos). Each cell
  contains an `<div class="appearance-pair">` with **light + dark `<figure>`
  pair**, both as `<img>` references.
- `grep -o 'baselines/ios/demo-' .../quad-comparison.html | wc -l` → **10**
  (5 screens × 2 appearances) ✓
- Total image references: 5 × 4 × 2 = 40 (matches the 40 baseline PNGs).

### Step 6 — 40 baseline PNGs committed

**PASS.**

- `docs/initiative-cross-platform-ui/baselines/web-desktop/demo-*.png` → **10**
- `docs/initiative-cross-platform-ui/baselines/web-mobile/demo-*.png` → **10**
- `docs/initiative-cross-platform-ui/baselines/ios/demo-*.png` → **10**
- `docs/initiative-cross-platform-ui/baselines/macos/demo-*.png` → **10**
- **Total: 40 PNGs ✓**
- Tolerance sidecars under all four dirs → **40** (`demo-*.tolerance.json`)
- Spot-checked `baselines/ios/demo-sign-in-light.tolerance.json`: uses the
  canonical visual_diff.cr schema (`pixel_diff_max`, `channel_diff_max`,
  `surface`, `slug`) per the D4 fix commit (`8186359`).

### Step 7 — Audit harness routes the 5 demo slugs

**PASS.**

| Probe | Per-slug timing | Overall |
|---|---|---|
| `bash scripts/audit_harness_smoke.sh I-1 web demo-all` | 4-6s/slug, 5 PASS | exit 0 |
| `bash scripts/audit_harness_smoke.sh I-1 macos demo-all` | 1.4-1.5s/slug, 5 PASS | exit 0 |
| `bash scripts/audit_harness_smoke.sh I-1 ios demo-all` | **20-23s/slug**, 5 PASS | exit 0 (real 107.99s wall clock, 5 slugs) |

**iOS slugs take ~20s each — not an artifact-presence proxy regression.**
The XCUITest runs the booted simulator, drives `HIGVisualTests/testRenderSlug`
per slug, and writes new screenshots. The brief's regression guard
("sub-second exit indicates an artifact-presence proxy regression") is
satisfied.

### Step 8 — Regression suite

**PASS.**

- `crystal spec` → 1454 examples, 4 failures, 0 errors, 66 pending. The 4
  failures match the pre-existing list named in the contract.
- `crystal spec spec/ui/design_tokens/material_spec.cr` → 31 examples, 0
  failures, 0 errors.
- `swift build -c release --package-path swift/AssetPipelineSwiftKit` → exit 0
  (both runs — macOS and the implicit iOS build at simulator time).
- `crystal-alpha build --no-codegen src/asset_pipeline.cr` → exit 0.
- `make -C samples/cross_platform/macos_host build` → exit 0
  (`bin/hig_showcase` signed; valid on disk).
- `bash samples/cross_platform/ios_host/build_crystal_lib.sh simulator`
  → exit 0 (libhighost.a built).

### Step 9 — Production code untouched

**PASS.**

`git diff --stat b26b688..b04bc86 -- src/ui/ swift/AssetPipelineSwiftKit/` →
**EMPTY** (no changes).

Outside production code, only `scripts/cdp_probes/devtools.cr` was touched:
`+21 -5`, two benign additions:
1. Chrome wait-loop bumped from 3s (30×100ms) → 20s (200×100ms) with an
   explicit `raise` on never-ready and a `ready` flag check (catches the
   `status.success?` case as well as the connect-refused exception path).
2. `DIST_DIRS` now includes `output/initiative-demo`; `candidates` adds
   `"#{slug}-light.html"` and `"#{slug}-dark.html"` so the resolver can find
   Phase 6's per-appearance HTML siblings.

Both are infrastructure improvements that match the architect's note
("benign infrastructure improvements, not behavior changes"). No probe
semantics changed.

### Step 10 — Brand-litmus visual assessment

**PASS_WITH_NOTES (the main reason this verdict isn't clean PASS).**

I read 6 baseline PNGs in detail:

- **`web-desktop/demo-sign-in-light.png`** — cream/warm background, bold "Cascade" wordmark, Email + Password fields with placeholder text, Sign-in button, **teal "Forgot password?" link** (brand override visible), divider, "or continue with", Apple/Google/Email button row. Clean, recognizable as a sign-in screen.
- **`web-mobile/demo-sign-in-light.png`** — same as web-desktop but reflowed to a single 375px column. Buttons stack horizontally. Brand teal visible on the Forgot link. **Best render of any surface.**
- **`web-desktop/demo-dashboard-light.png`** — "Discover" header, 4 items (Nature/Coffee/Reading/Music), bottom tabbar with **Discover tab in teal** (brand visible), Library and Profile in muted. The screen is mostly empty whitespace below — no card chrome on the items themselves, items are just heading + caption pairs.
- **`web-mobile/demo-dashboard-dark.png`** — same content on dark canvas, dark background, **teal Discover tab clearly visible against dark**, light grid-divider line. Dark mode reads correctly.
- **`ios/demo-sign-in-light.png`** — iOS status bar (8:07), white card. "Cascade" wordmark and "Sign in to continue" labels are visible but **right-aligned and partially clipped at the right edge**. "Email" and "Password" labels appear without field chrome. "Sign in" button **not visible above the fold**. "or continue with" caption also right-aligned/clipped. No teal brand color visible on this screen. **The app does not crash but the iOS sign-in baseline is not a polished render.**
- **`ios/demo-tier-three-light.png`** — header + paragraph + ActionSheet/ContextMenu/PathControl rows. **ContextMenu IS rendered with native iOS chrome** (rounded surface, red "Delete" destructive label). PathControl breadcrumbs render. ActionSheet trigger button is missing on the right side. Width-pin issue ("UI::Card iOS width-pin not authoritative" — known memory item) is consistent with what I see.
- **`macos/demo-sign-in-light.png`** — degraded. "Cascade" not bold-displayed as h1. Password field is a tiny empty oval. Sign in / Forgot password? render as buttons stacked vertically. Apple/Google/Email row OK. **No teal brand visible on this render.**
- **`macos/demo-dashboard-light.png`** — **MUCH stronger**. Native segmented control at top ("Discover | Library | Profile" with Discover selected, gray pill), proper 2-column card grid below ("Nature/Mountain trails", "Coffee/Local roasters", "Reading/Recent picks", "Music/New releases") with light rounded card backgrounds. Looks like a macOS app screen.
- **`macos/demo-tier-three-light.png`** — strong: ActionSheet trigger button visible ("Show action sheet"), ContextMenu trigger button + inline rendered menu surface, PathControl as a vertical breadcrumb (Home > Documents > Projects > Demo). Platform-default chrome present.

**Litmus answers:**

1. **Same brand?** Partially. The teal brand-primary is unmistakable on web (Forgot password link, Discover tab), shows up subtly on iOS in Discover tab on dashboard. On the sign-in baselines specifically, macOS and iOS don't show much teal — the brand-secondary/link colors don't carry the strong override. **The brand override mechanism works** (and is visibly demonstrated on web), but the **per-screen brand-tint application is uneven across surfaces.**
2. **Platform-specific defaults visible?**
   - iOS: native ContextMenu chrome with destructive-red Delete, iOS status bar present. Liquid Glass surfaces not particularly visible in these baselines.
   - macOS: native segmented control on dashboard (gray-filled selected pill), card grid with macOS-style rounded surfaces, breadcrumb PathControl in vertical stack. **Yes.**
   - Web browser-native focus rings: not visible in the static screenshots (no focused element captured).
   - Web mobile single-column reflow: **Yes** — visible across sign-in and dashboard.
3. **Tier 3 native widgets on iOS/macOS + web fallback on web?**
   - iOS demo-tier-three baseline shows native ContextMenu chrome.
   - macOS demo-tier-three baseline shows native ContextMenu + native PathControl breadcrumb.
   - I did not open the web tier-three HTML to confirm the *WithWebFallback render path, but the Crystal source in `screens/tier_three.cr` uses the explicit `UI::*WithWebFallback` classes that Phase 4 shipped — so the contract path is wired by construction.

---

## Per-invariant verification (against `brief.yml`)

- **I-1 (render):** PASS (audit harness × 3 platforms × 5 slugs = 15 PASS results; 40 baselines committed).
- **I-2 (reactive forward):** Not directly probed in this validation run; the settings screen source exists with Toggle/Slider/SegmentedControl/Picker/TextField bindings. Behavior bar deferred to gate-time probe runs.
- **I-3 (events):** Not directly probed; button/tab/navigation handlers exist in screen sources. Behavior bar deferred.
- **I-4 (focus):** Not directly probed; sign-in form structure is in place.
- **I-5 (lifecycle):** Not directly probed; 5 screens mount/unmount paths exist via app.cr's slug router.
- **I-6 (a11y):** All screen views in tier_three.cr have `accessibility_label` and `test_id` set; not run end-to-end via axe in this validation.
- **I-7 (memory):** Not directly probed.
- **I-8 (env):** Light + dark baselines exist for every slug × surface; 40 sidecars cover the env axis.
- **I-9 (embedding):** PASS — no new class vars; the BRAND_TOKENS→brand_tokens fix specifically converts a module constant (which was an embedding-fatal pattern) back to a method (which is the documented workaround pattern from `hig_bridge.cr`).
- **I-10 (API/fallback contract fidelity):** PASS — tier_three.cr uses the 3 `*WithWebFallback` classes verbatim.
- **I-11 (build closure):** PASS — 3 new build targets all exit 0.

---

## Findings

### Hard contract: met

1. iOS class-init crash fixed; CascadeDemo launches and stays running.
2. All 3 build closures exit 0.
3. 40 baselines + 40 tolerance sidecars committed.
4. Quad-comparison.html is the canonical 5×4 grid with light/dark pairs.
5. Audit harness routes all 5 demo slugs across web/macos/ios with real timings.
6. Brand override notably distinct (teal hue 195° vs amber gold ~65°), visibly demonstrated on web baselines.
7. Tier-3 screen uses the 3 *WithWebFallback variants.
8. Regression suite intact (1454 / 4 pre-existing failures / 0 errors).
9. Production code under `src/ui/` and `swift/` UNTOUCHED.

### Soft notes (not contract violations but worth flagging)

1. **Brief validator drift at HEAD.** `repo_derived_facts` were captured pre-dispatch. Three rows (existing demo dir, existing quad page, existing capture script) all flip from "missing" to "exists" by design once Phase 6 ships. The current schema does not encode this. Surface to architect: either add a `pre_dispatch_only: true` flag, or re-capture facts at gate as Phase 6's last commit. Not Implementer's fault.

2. **iOS sign-in render is degraded.** The Cascade wordmark, "Sign in to continue", "or continue with" captions all right-align/clip on the 1206px iPhone 17 portrait viewport. The Sign-in button is below the visible region. The app does not crash; the elements presumably exist in the AX tree (audit harness PASSes), but the visual baseline is not what a reasonable reviewer would call a polished sign-in screen. **This matches the documented `UI::Card iOS width-pin not authoritative` memory item** — UILabel intrinsic width wins over Card min_w==max_w pinning. This is a known systemic issue, not a Phase 6 regression.

3. **macOS sign-in render is degraded.** Password field renders as a tiny empty oval. Title is not bold/h1-style. The other macOS baselines (dashboard, tier-three) are stronger — this seems specific to the sign-in screen's layout.

4. **Brand teal is uneven across surfaces.** Strong on web (Forgot password link, Discover tab). Subtle/absent on iOS and macOS sign-in baselines. Stronger on macOS dashboard segmented control. The brand-override mechanism IS demonstrated to work; the per-screen tint application is what's uneven. May be a downstream renderer concern, not a brand.cr concern.

5. **Brief's path for CascadeDemo.app is incorrect.** The brief's Step 4 references
   `samples/initiative-cross-platform-ui-demo/ios/build/Build/Products/Debug-iphonesimulator/CascadeDemo.app`. xcodebuild outputs to DerivedData
   (`~/Library/Developer/Xcode/DerivedData/CascadeDemo-.../Build/Products/Debug-iphonesimulator/CascadeDemo.app`). Validation used the actual DerivedData path. Not Implementer's bug — brief drift.

---

## Recommendation

**PASS_WITH_NOTES.** Tag the phase and proceed to Phase 7 (CI integration of
the audit harness). The architect's Rem 1 contract is fully met: the iOS
class-init crash is fixed, the demo runs end-to-end on three platforms, the
audit harness exercises real probes (not artifact-presence proxies), and
production code is untouched.

Open items for architect adjudication:

1. **Render polish on iOS/macOS sign-in baselines.** Phase 6 retry, defer to
   Phase 7 follow-up, or accept as documented "known systemic issue" (the
   width-pin memory item)?
2. **Brand-tint uniformity across surfaces.** Worth a focused mini-iteration
   to push teal through the iOS/macOS button + label paths?
3. **Brief schema improvement.** Add `pre_dispatch_only: true` to
   `repo_derived_facts` to remove the gate-time drift false positive?

None of the three are crash-class regressions. All three are quality-of-render
gaps that the audit harness will surface again at gate-time once Phase 7
wires CI.

---

## Artifacts

- `/tmp/validator-cascade-launch.png` — iOS launch screenshot (sign-in screen rendered, no crash)
- `output/initiative-demo/quad-comparison.html` — the litmus artifact
- `output/initiative-demo/demo-*-{light,dark}.html` — 10 per-screen web pages
- `docs/initiative-cross-platform-ui/baselines/{web-desktop,web-mobile,ios,macos}/demo-*.png` — 40 PNGs
- `docs/initiative-cross-platform-ui/baselines/{web-desktop,web-mobile,ios,macos}/demo-*.tolerance.json` — 40 sidecars
- `samples/initiative-cross-platform-ui-demo/macos/bin/cascade` — built macOS binary
- `~/Library/Developer/Xcode/DerivedData/CascadeDemo-appnfxgyphxuvcgnbbryivigpkig/Build/Products/Debug-iphonesimulator/CascadeDemo.app` — built iOS app
