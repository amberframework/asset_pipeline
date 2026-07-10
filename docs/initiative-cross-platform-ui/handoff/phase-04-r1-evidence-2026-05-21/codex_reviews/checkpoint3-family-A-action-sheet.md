   225	2. Pressing Tab from the first focusable advances through every action button in DOM order and lands on Cancel last.
   226	3. Pressing Tab from Cancel wraps to the first action button.
   227	4. Pressing Shift-Tab from the first action wraps to Cancel.
   228	5. At every step, `document.activeElement` is inside the `.ap-action-sheet__panel`. Focus never escapes the panel via Tab or Shift-Tab.
   229	6. When the sheet is dismissed (any path), `document.activeElement` returns to the element that was focused before the sheet was opened — captured in `focus.action-sheet-escape-closes`, `focus.action-sheet-backdrop-click-closes`, and the primary/cancel dismiss checks below.
   230	
   231	**This check does NOT pass on source inspection.** A `tabindex` audit or a grep for a focus-trap library is insufficient. The check passes only when the validator drives real Tab presses against the running page and records `document.activeElement` after each press.
   232	
   233	How: drive Chrome via CDP per `../../rubric/behavior-simulation-toolkit.md` §3.5. Use `Input.dispatchKeyEvent` for the Tab keystrokes — CDP-dispatched input is trusted (`isTrusted === true`) by default, which is the entire reason this protocol is used here; focus-trap libraries that gate on event trust will not respond to JS-side `dispatchEvent(new KeyboardEvent(...))`. Combine with `Runtime.evaluate` for polling `document.activeElement`. The full procedure:
   234	
   235	```
   236	1. Launch headless Chrome + open a CDP session (toolkit §3.2).
   237	2. Page.navigate to the action-sheet test page; poll readyState === "complete".
   238	3. Runtime.evaluate: stash the pre-open focused element on window:
   239	     window.__preOpenFocus = document.activeElement;
   240	     window.__focusTrace = [];
   241	4. Click the trigger button via Runtime.evaluate (trigger.click()).
   242	5. Runtime.evaluate: poll for [data-presented="true"] (50 ms interval, 2 s timeout).
   243	6. Send a Tab key via Input.dispatchKeyEvent
   244	   ({"type":"keyDown","key":"Tab","code":"Tab","windowsVirtualKeyCode":9,"nativeVirtualKeyCode":9,"modifiers":0})
   245	   followed by the matching keyUp (real OS-level trusted key). After each
   246	   send, via Runtime.evaluate push to the window-side array:
   247	     window.__focusTrace.push({
   248	       n: window.__focusTrace.length,
   249	       tag: document.activeElement?.tagName,
   250	       testid: document.activeElement?.getAttribute('data-testid'),
   251	       text: document.activeElement?.textContent?.slice(0, 40),
   252	       inside: !!document.activeElement?.closest('.ap-action-sheet__panel')
   253	     });
   254	7. Send Tab a total of (focusable_count + 2) times to guarantee at least one cycle wrap.
   255	8. Send Shift-Tab (focusable_count + 2) times (same Input.dispatchKeyEvent with modifiers: 8).
   256	9. Read window.__focusTrace via Runtime.evaluate (JSON.stringify(window.__focusTrace)).
   257	```
   258	
   259	Pass when:
   260	- Every entry in `__focusTrace` has `inside === true` (focus never escaped the panel).
   261	- The set of distinct `testid`s in the trace equals the set of focusable descendants of the panel exactly (every focusable visited at least once; no extras).
   262	- The trace exhibits cycling behavior: entry `[n+focusable_count]` equals entry `[n]` in the Tab phase, and equivalently for Shift-Tab. (Verify by comparing the (focusable_count + 1)-th entry to the 1st.)
   263	
   264	If `__focusTrace` is empty after the Tab sends, the page is rejecting untrusted events — confirm the recipe is using `Input.dispatchKeyEvent` and not JS-side `dispatchEvent`. CDP input is trusted by default; if a previous validator used `dispatchEvent(new KeyboardEvent(...))` and got an empty trace, that is a false-negative caused by the wrong synthesis path, not a real focus-trap failure.
   265	
   266	Evidence: `inspections/focus.action-sheet-focus-trap.json` — the full `__focusTrace` array, plus a derived `{focusable_count, distinct_testids_visited, cycle_detected_at_index}` summary.
   267	
   268	### focus.action-sheet-escape-closes
   269	
   270	**Required.** **Bar:** behavior. Pressing Escape while the sheet is presented:
   271	- Hides the sheet (`data-presented="false"`).
   272	- Removes the panel from the document's accessibility tree.
   273	- Fires the `ap:action-sheet:dismiss` CustomEvent with `detail.reason === 'escape'`.
   274	- Returns focus to the trigger element that opened the sheet.
   275	
   276	How: open the sheet from a trigger button. Before opening, stash `window.__trigger = document.activeElement` via `Runtime.evaluate`. Install an event listener: `root.addEventListener('ap:action-sheet:dismiss', e => window.__phase4DismissLog.push(e.detail))`. Press Escape via `Input.dispatchKeyEvent` (real trusted key — see `../../rubric/behavior-simulation-toolkit.md` §3.6; CDP input is trusted, JS-side `dispatchEvent` is not). Then read four things via `Runtime.evaluate`:
   277	```js
   278	({
   279	  dismiss_log: window.__phase4DismissLog,
   280	  data_presented: document.querySelector('.ap-action-sheet')?.getAttribute('data-presented'),
   281	  panel_ax_visible: (() => {
   282	    const p = document.querySelector('.ap-action-sheet__panel');
   283	    if (!p) return false;
   284	    // AX-tree visibility requires the element to not be aria-hidden AND not display:none
   285	    if (p.getAttribute('aria-hidden') === 'true') return false;
   286	    if (getComputedStyle(p).display === 'none') return false;
   287	    return true;
   288	  })(),
   289	  focus_restored: document.activeElement === window.__trigger,
   290	  active_testid: document.activeElement?.getAttribute('data-testid'),
   291	  trigger_testid: window.__trigger?.getAttribute('data-testid')
   292	})
   293	```
   294	
   295	Pass when **all four** booleans hold:
   296	- `dismiss_log` contains exactly one entry with `{ reason: 'escape' }` (no leaked dismiss events from earlier paths).
   297	- `data_presented === 'false'`.
   298	- `panel_ax_visible === false` (panel is gone from the AX tree — not merely visually hidden behind another layer).
   299	- `focus_restored === true` (the trigger is again `document.activeElement`).
   300	
   301	Evidence: `inspections/focus.action-sheet-escape-closes.json` — the evaluated object above.
   302	
   303	### focus.action-sheet-backdrop-click-closes
   304	
   305	**Required.** **Bar:** behavior. Clicking outside the panel (on the backdrop) dismisses the sheet, identical to the Escape behavior, with `detail.reason === 'backdrop'` in the CustomEvent. The click is a real synthetic mouse event at coordinates measured from `getBoundingClientRect()` on the backdrop element — **not** a JS-side `backdrop.click()`, which a well-behaved implementation may guard against.
   306	
   307	How: open the sheet from a known trigger, stash `window.__trigger`, install the dismiss-log listener. Read the backdrop's bounding rect via `Runtime.evaluate` (`JSON.stringify(...getBoundingClientRect())`); then dispatch a real synthetic click at the rect's center via `Input.dispatchMouseEvent` mousePressed + mouseReleased at `{x, y, button: "left", clickCount: 1}` (see toolkit §3.6). The click coordinate must be outside the panel's rect to genuinely test backdrop behavior — verify by reading both rects first. Then evaluate the same four-boolean assertion object from `focus.action-sheet-escape-closes` via `Runtime.evaluate`.
   308	
   309	Pass when **all four** hold: dismiss log contains one entry with `{ reason: 'backdrop' }`; `data_presented === 'false'`; panel absent from AX tree; trigger is the active element.
   310	
   311	If the synthetic click misses (the rect was wrong, the page intercepted at a higher z-index), the dismiss log will be empty AND `data_presented` will still be `'true'`. Distinguish "dismiss did not fire" from "wrong reason fired" — the former is a test-rig bug; the latter is a real implementation bug. Re-measure the rect, retry once, mark `blocked: true` with the captured rects if the issue persists.
   312	
   313	Evidence: `inspections/focus.action-sheet-backdrop-click-closes.json` — the assertion object plus the captured rects (`panel_rect`, `backdrop_rect`, `click_point`) for forensics.
   314	
   315	### conformance.action-sheet-positioning
   316	
   317	**Required.** **Bar:** conformance. The action-sheet panel is positioned at the bottom of the viewport on mobile (≤ 767 px) and centered on desktop (≥ 768 px). The bottom-position must honor `env(safe-area-inset-bottom)` (this matters on mobile Safari with the home indicator).
   318	
   319	How: load the action-sheet test page in headless Chrome via CDP (`Page.navigate` per `../../rubric/behavior-simulation-toolkit.md` §3.2) at three viewports (each set via `Emulation.setDeviceMetricsOverride`):
   320	1. 1280×800 (desktop): expect the panel centered. Measure `getBoundingClientRect()` for `.ap-action-sheet__panel`. Assert: `rect.left + rect.width/2` within ±2 px of viewport center; `rect.top + rect.height/2` within ±2 px of viewport center vertically.
   321	2. 375×667 (mobile): expect the panel docked to bottom. Assert: `rect.bottom` equals `window.innerHeight` exactly (the `safe-area-inset-bottom` defaults to 0 in headless Chrome); `rect.left === 0`; `rect.right === window.innerWidth`.
   322	3. 320×568 (mobile-min): same as 375×667 but at the smallest supported viewport. Assert the panel does not overflow horizontally and the title text does not wrap to more than three lines.
   323	
   324	Pass when: all positioning assertions hold at each viewport.
   325	
   326	Evidence: `inspections/conformance.action-sheet-positioning-{1280,375,320}.json` — each with the measured rect plus the asserted predicates.
   327	
   328	### conformance.action-sheet-touch-targets
   329	
   330	**Required.** **Bar:** conformance. Every action button and the Cancel button in the rendered action sheet measures ≥ 44 px in both width and height at the 375×667 viewport.

exec
/bin/zsh -lc "nl -ba docs/initiative-cross-platform-ui/rubric/validation_criteria.md | sed -n '27,70p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
    27	Every validator check in this initiative sits on one of three escalating bars. Phase rubrics declare which bar a given check is held to. The validator must read each check with this taxonomy in mind, because a check phrased as "verify X exists" without a stated bar is almost always being held to **behavior** or **conformance**, not the easy presence bar that the words alone suggest.
    28	
    29	### The three bars
    30	
    31	**Presence check.** "The element, file, CSS rule, symbol, or declaration exists." This is the lowest bar. It is satisfied by `grep`, by an AST walk, by reading a generated artifact. Presence is easy to automate and easy to false-pass: a button rendered with the right `data-testid` but no `onclick` wiring will pass a presence check trivially. Presence is **never sufficient on its own** for an interactive widget claim, a layout claim, or any claim that involves runtime wiring across a language boundary (Crystal → ObjC, Crystal → SwiftUI, Crystal → JS). Presence is sufficient for: static design tokens, generated CSS variables, file-existence assertions, module-load assertions, public-API surface assertions ("type `Foo` is declared as `abstract class`").
    32	
    33	**Behavior check.** "The element does the thing it claims to do, end to end." For a button: tap on the rendered surface (XCUITest tap, CDP `Input.dispatchMouseEvent` click or `Runtime.evaluate` `.click()` on web, AppKit synthetic event) fires the bound action handler, the bound state mutates, the next render reflects the new state, and any visible feedback (press animation, focus ring, haptic) plays. For a navigation: trigger the link, the next view becomes visible, the back affordance restores the previous view. For a modal: trigger open, the modal is in the accessibility tree; trigger each documented dismiss path (primary action, cancel, backdrop, escape key on web, swipe-down on iOS); confirm the modal is removed from the accessibility tree and focus returns to the trigger. Behavior is required for every Tier 2 and Tier 3 widget claim, every phase that wires a Crystal-side declaration to a native or web runtime, and every navigation flow.
    34	
    35	**Conformance check.** "The rendered output matches the design intent, not just the schema." Conformance is measured from rendered pixels and from the platform's runtime accessibility tree, never from the source. For a button: read `getBoundingClientRect()` on web or query the `XCUIElement.frame` on iOS and assert the hit-target measures at least 44×44 device-independent pixels — do not assert that the source declares `padding: 12px` and call it done. For a layout: capture screenshots at the declared breakpoints and confirm the headline does not overflow, the card grid reflows to a single column at 375 px, the safe-area inset is honored at the bottom of an iOS action sheet. For a color: render the page, sample the pixel, compute Lab distance against the token value; do not assert the CSS variable is set. Conformance is required for every visual claim, every "looks right" claim, every accessibility claim that depends on contrast, every visual regression baseline.
    36	
    37	### Examples of failures that slip past presence but get caught downstream
    38	
    39	These are illustrative, not exhaustive. Each names a real category of bug the cross-platform UI initiative has reason to expect.
    40	
    41	- **Wired-wrong action handler.** A Crystal `Button` view declares `on_click ProductsAction::Open.new` and the SwiftUI bridge renders the button into the iOS host with the correct `setAccessibilityIdentifier:`. Presence: pass — the button exists with the right testid. The `onClick` handler in the SwiftUI shim is mis-routed to `ProductsAction::Close.new` because the callback registry indexed by the wrong key. Tapping does nothing user-visible because Close on an unopened detail is a no-op. **Behavior check fails:** XCUITest taps the button, asserts the next view is Detail, asserts the state property changed — none of these hold.
    42	
    43	- **Cosmetically-correct, structurally-wrong modal.** An action sheet renders on iOS at the correct moment with the correct title and buttons. Presence: pass. The dismiss button is positioned in the lower-left because the SwiftUI modifier order in the bridge places `.padding()` before `.frame(maxWidth: .infinity)` instead of after, so the button hugs leading instead of centering. Behavior: pass — tapping the button dismisses the sheet. **Conformance check fails:** the rendered button's bounding box centerX is not within ±4 px of the sheet's centerX.
    44	
    45	- **Layout that fits but doesn't read.** A web demo at 320 px viewport has every element technically inside the viewport. Presence: every element is in the DOM. Conformance, naively: no horizontal scrollbar. **Real conformance fails:** the headline's `clamp(2rem, 6vw, 4rem)` was authored with the wrong ideal value, so at 320 px the headline computes to 1.92 rem and visually collapses; the same headline at 1280 px computes to 4 rem; the type ramp does not preserve scale ratio across breakpoints. The check that catches this measures `font-size` on the rendered element at each breakpoint and compares against the token scale.
    46	
    47	- **Cascade that doesn't cascade.** A brand override changes the Crystal-side `brand_primary` to coral. The web generator emits an updated `--ap-color-brand-primary` custom property. Presence: pass — the variable is set. **Behavior fails:** the rendered Button still draws teal because the Button widget's renderer visitor hard-codes a Color literal instead of reading `var(--ap-color-brand-primary)`. A presence check on the variable would never have surfaced this.
    48	
    49	- **Accessibility tree out of sync with the visual layer.** A custom Crystal widget renders the correct visible label. Presence and conformance on the visible label pass. **Behavior fails for accessibility:** VoiceOver focus order steps right past the widget because the bridge forgot to set `isAccessibilityElement = true` on the UIView, and the widget contributes nothing to the AX tree. The check that catches this is "drive the AX tree, not the visible tree."
    50	
    51	- **Compile-time gate that does not gate.** Phase 4 introduces a compile-time error when `UI::ActionSheet` is used outside an `{% if flag?(:ios) || flag?(:macos) %}` block. The macro is declared. Presence: pass. **Behavior fails:** the macro pattern-matches on the wrong AST node and never raises. The check that catches this writes a temp Crystal file using `UI::ActionSheet` from a non-Apple target, runs `crystal build --no-codegen` against it, and asserts the build fails with the expected error text.
    52	
    53	### When to apply each bar
    54	
    55	The table below maps common claim types to the bar required. Phase rubrics may add stricter bars, but they may not relax these defaults.
    56	
    57	| Claim type | Required bar |
    58	|---|---|
    59	| Static design token value, Crystal constant, or generated CSS variable exists with the right name. | Presence. |
    60	| Generated CSS file contains the expected `@layer`, `@media`, or `@container` rule. | Presence + textual contents check. |
    61	| Renderer-emitted CSS with computed sizing (`clamp()`, `min()`, container queries, `dvh`/`svh`). | Conformance — measure rendered sizes at the breakpoints the rule targets. |
    62	| Token value cascades into a rendered widget. | Behavior — modify the token, rebuild the demo or re-render, confirm the rendered widget reflects the change. |
    63	| Interactive widget (button, toggle, picker, slider, segmented control, switch). | Behavior + conformance. Hit-target measured ≥ 44×44 on touch platforms; tap fires the bound action; bound state reflects in the next render. |
    64	| Modal-like widget (action sheet, popover, sheet, confirmation dialog, context menu). | Behavior — every documented dismiss path; focus returns to trigger; element leaves accessibility tree on dismiss. Conformance — position and inset match spec at the declared viewport sizes. |
    65	| Navigation flow (sign-in → dashboard, tab switching, push/pop, present/dismiss). | Behavior — end-to-end through every documented step; back affordance restores prior state. |
    66	| Accessibility — focus order, ARIA roles, labels, keyboard traversal. | Behavior + conformance. Tab through the rendered output; assert the order observed equals the order expected. Query the AX tree, not the DOM. |
    67	| Accessibility — contrast. | Conformance — sample rendered pixels for foreground and background, compute WCAG contrast ratio against AA threshold (4.5:1 normal text, 3:1 large text). |
    68	| Visual regression baseline. | Conformance with explicit pixel/ΔE tolerance stated in the check. |
    69	| Layout reflow at viewport sizes. | Conformance — capture at each declared viewport, measure rendered element bounding boxes, confirm no overflow and no zero-sized interactive elements. |
    70	| Cross-platform brand parity ("looks like the same product"). | Conformance — capture matched-state screenshots on each platform, sample primary color at known coordinates, assert Lab distance is within the documented threshold. |

codex
No. The evidence does not prove “all 7 checks pass”; it proves 5 pass or mostly pass, and 1 required audit check correctly fails. The remaining nuance is that one PASS has a strict evidence-format gap.

**Strict issues:**
- `focus.action-sheet-focus-trap` is behaviorally convincing but not rubric-complete. The rubric asks for `distinct_testids_visited` matching the focusable descendants exactly, plus cycle evidence for Tab and Shift-Tab. The record uses labels because button `data-testid`s are null, and it only summarizes one `cycle_detected` predicate. The trace itself shows `Save -> Delete -> Cancel -> Save` and later Shift-Tab wrapping, but this should be amended rather than treated as clean rubric evidence. See [focus trace](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/inspections/focus.action-sheet-focus-trap.json:34) and the rubric requirement at [validation.md](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-04-platform-tier-gating/validation.md:259).
- The “pre/post deltas captured at every transition” claim is overstated. Escape/backdrop records solid post-dismiss state, but not a full pre snapshot: no recorded `data-presented=true`, empty dismiss log, panel visible/AX-visible before the action. Backdrop has pre rects; Escape only has `pre_escape_active_tag`. See [escape JSON](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/inspections/focus.action-sheet-escape-closes.json:24) and [backdrop JSON](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/inspections/focus.action-sheet-backdrop-click-closes.json:25).
- `conformance.action-sheet-positioning-320` omits bottom/full-width predicates, though the recorded rect proves them (`left=0`, `right=320`, `bottom=568`). This is an evidence-summary gap, not a failed behavior. See [320 positioning JSON](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/inspections/conformance.action-sheet-positioning-320.json:20).
- IBM PASS is acceptable under the repo’s existing IBM convention of failing only `VIOLATION + FAIL`, but the writeup’s “zero VIOLATION-level findings” wording is inaccurate. The JSON contains `VIOLATION/POTENTIAL` and `VIOLATION/MANUAL`; it has zero hard fail violations. See [IBM JSON](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/audits/fallback.action-sheet-ibm-equal-access-clean.json:24).

The two axe failures are correctly classified as real renderer-source bugs, not harness misreads. `color-contrast` is a serious axe finding against rendered buttons, with computed ratios below 4.5:1; the renderer sets action text to `var(--ap-color-brand-accent)` on near-white/panel surfaces at [web_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/web_renderer.cr:2704). `listitem` is also real: the renderer emits `<ul role="group">`, overriding list semantics for child `<li>` elements at [web_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/web_renderer.cr:2589).

So: R1 did its job by making the CDP probes operative and surfacing latent renderer bugs. Since R1 is test-infra only, those two fixes should be routed back to the Phase 4 implementer, while the R1 evidence should be tightened for focus-trap and pre/post recording.
tokens used
194,994
No. The evidence does not prove “all 7 checks pass”; it proves 5 pass or mostly pass, and 1 required audit check correctly fails. The remaining nuance is that one PASS has a strict evidence-format gap.

**Strict issues:**
- `focus.action-sheet-focus-trap` is behaviorally convincing but not rubric-complete. The rubric asks for `distinct_testids_visited` matching the focusable descendants exactly, plus cycle evidence for Tab and Shift-Tab. The record uses labels because button `data-testid`s are null, and it only summarizes one `cycle_detected` predicate. The trace itself shows `Save -> Delete -> Cancel -> Save` and later Shift-Tab wrapping, but this should be amended rather than treated as clean rubric evidence. See [focus trace](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/inspections/focus.action-sheet-focus-trap.json:34) and the rubric requirement at [validation.md](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-04-platform-tier-gating/validation.md:259).
- The “pre/post deltas captured at every transition” claim is overstated. Escape/backdrop records solid post-dismiss state, but not a full pre snapshot: no recorded `data-presented=true`, empty dismiss log, panel visible/AX-visible before the action. Backdrop has pre rects; Escape only has `pre_escape_active_tag`. See [escape JSON](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/inspections/focus.action-sheet-escape-closes.json:24) and [backdrop JSON](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/inspections/focus.action-sheet-backdrop-click-closes.json:25).
- `conformance.action-sheet-positioning-320` omits bottom/full-width predicates, though the recorded rect proves them (`left=0`, `right=320`, `bottom=568`). This is an evidence-summary gap, not a failed behavior. See [320 positioning JSON](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/inspections/conformance.action-sheet-positioning-320.json:20).
- IBM PASS is acceptable under the repo’s existing IBM convention of failing only `VIOLATION + FAIL`, but the writeup’s “zero VIOLATION-level findings” wording is inaccurate. The JSON contains `VIOLATION/POTENTIAL` and `VIOLATION/MANUAL`; it has zero hard fail violations. See [IBM JSON](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/audits/fallback.action-sheet-ibm-equal-access-clean.json:24).

The two axe failures are correctly classified as real renderer-source bugs, not harness misreads. `color-contrast` is a serious axe finding against rendered buttons, with computed ratios below 4.5:1; the renderer sets action text to `var(--ap-color-brand-accent)` on near-white/panel surfaces at [web_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/web_renderer.cr:2704). `listitem` is also real: the renderer emits `<ul role="group">`, overriding list semantics for child `<li>` elements at [web_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/web_renderer.cr:2589).

So: R1 did its job by making the CDP probes operative and surfacing latent renderer bugs. Since R1 is test-infra only, those two fixes should be routed back to the Phase 4 implementer, while the R1 evidence should be tightened for focus-trap and pre/post recording.
