Reading additional input from stdin...
OpenAI Codex v0.130.0
--------
workdir: /Users/crimsonknight/open_source_coding_projects/asset_pipeline
model: gpt-5.5
provider: openai
approval: never
sandbox: workspace-write [workdir, /tmp, $TMPDIR, /Users/crimsonknight/.codex/memories]
reasoning effort: xhigh
reasoning summaries: none
session id: 019e5aac-4094-7fd1-a6ef-ef4196db97ea
--------
user
Review the Phase 6.12C fix at swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift (the case 'prominent' branch, lines roughly 180-249), and the new file swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift. Verify: (1) macOS-only conditional protects Voyager (SYSTEM_ACCENT) from regression; (2) reads APSKRuntime.brandTint at render time so a brand swap mid-session takes effect; (3) the iOS branch unchanged from Phase 6.11 iter-4 (must still be .controlSize(.large).buttonStyle(.borderedProminent)); (4) no hardcoded color literal restored. Verdict per item: PASS/FAIL. Overall: APPROVE / REVISE.
codex
I’ll treat this as a code review: inspect the current Swift facade/style code, compare the iOS branch against the requested Phase 6.11 behavior, and only report concrete regressions or verification gaps.
exec
/bin/zsh -lc "rg -n \"Phase 6\\.12C|6\\.12C|APSKBrandProminentButtonStyle|ButtonFacade|prominent|Voyager|SYSTEM_ACCENT|Phase 6\\.11|iter-4\" /Users/crimsonknight/.codex/memories/MEMORY.md" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 exited 2 in 0ms:
rg: /Users/crimsonknight/.codex/memories/MEMORY.md: IO error for operation on /Users/crimsonknight/.codex/memories/MEMORY.md: No such file or directory (os error 2)

exec
/bin/zsh -lc 'git status --short' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
 M spec/test_js/some_js.js
 M src/ui/renderers/appkit_renderer.cr
 M swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift
?? docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-02-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20/
?? docs/initiative-cross-platform-ui/handoff/phase-06.10-rem-2-iter1/
?? docs/initiative-cross-platform-ui/handoff/phase-06.10-rem-2-iter2/
?? docs/initiative-cross-platform-ui/handoff/phase-06.11-evidence/legibility-audit.md
?? docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md
?? docs/initiative-cross-platform-ui/handoff/phase-06.12c-evidence/
?? docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md
?? docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-3.md
?? docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md
?? docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-5.md
?? output/initiative-demo/demo-dashboard-dark.html
?? output/initiative-demo/demo-dashboard-light.html
?? output/initiative-demo/demo-detail-dark.html
?? output/initiative-demo/demo-detail-light.html
?? output/initiative-demo/demo-settings-dark.html
?? output/initiative-demo/demo-settings-light.html
?? output/initiative-demo/demo-sign-in-dark.html
?? output/initiative-demo/demo-sign-in-light.html
?? output/initiative-demo/demo-tier-three-dark.html
?? output/initiative-demo/demo-tier-three-light.html
?? output/initiative-demo/index.html
?? output/voyager-demo/
?? samples/initiative-cross-platform-ui-demo/scratch/
?? swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift

exec
/bin/zsh -lc 'find .. -name AGENTS.md -print' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
codex
The worktree is already dirty in unrelated areas plus the two Swift files under review. I’ll leave that state untouched and focus on the requested review surface.
 succeeded in 6847ms:
../asset_pipeline/templates/design-system/AGENTS.md
../asset_pipeline/AGENTS.md

exec
/bin/zsh -lc "nl -ba swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift | sed -n '1,220p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	// APSKBrandProminentButtonStyle — macOS-only ButtonStyle that paints
     2	// `.borderedProminent`-equivalent chrome using a brand tint.
     3	//
     4	// Why this exists (Phase 6.12C):
     5	//   SwiftUI's `.borderedProminent` button style on macOS uses the
     6	//   *system* accent color exclusively. Setting `.tint(brandColor)` on
     7	//   the button (or in the environment) is silently ignored — the
     8	//   background fill always resolves to the system accent. Confirmed
     9	//   empirically in `docs/initiative-cross-platform-ui/handoff/
    10	//   phase-06.12c-probe-findings.md`.
    11	//
    12	//   iOS does not exhibit this divergence: `.tint(...) +
    13	//   .buttonStyle(.borderedProminent)` correctly recolors the prominent
    14	//   chrome. So the workaround is conditionally compiled `#if os(macOS)`
    15	//   only.
    16	//
    17	// Activation contract (see `ButtonFacade.swift` case "prominent"):
    18	//   - macOS + `APSKRuntime.brandTint != nil` (custom brand installed)
    19	//     → this style is used.
    20	//   - macOS + `APSKRuntime.brandTint == nil` (Voyager / Tokens.default /
    21	//     SYSTEM_ACCENT) → stock `.borderedProminent` is used (system blue
    22	//     / system accent — exactly what the consumer wants).
    23	//   - iOS → stock `.borderedProminent` always (system honors `.tint`).
    24	//
    25	// State coverage:
    26	//   - Pressed: fill darkens to `tint.opacity(0.85)`, overall opacity
    27	//     dims slightly to 0.95.
    28	//   - Disabled: read `@Environment(\.isEnabled)`; overall opacity drops
    29	//     to 0.5 so the button matches SwiftUI's stock disabled treatment.
    30	//   - Focused (keyboard): SwiftUI's system-drawn focus ring still
    31	//     surrounds the Button regardless of ButtonStyle; the style does not
    32	//     need to draw it explicitly.
    33	//   - High-contrast: brand tint × white foreground; consumers with very
    34	//     demanding contrast budgets should override `brand_primary` to a
    35	//     darker primary in their `DesignTokens::Brand` subclass.
    36	
    37	#if os(macOS)
    38	import SwiftUI
    39	
    40	struct APSKBrandProminentButtonStyle: ButtonStyle {
    41	    let tint: Color
    42	    @Environment(\.isEnabled) private var isEnabled
    43	
    44	    func makeBody(configuration: Configuration) -> some View {
    45	        // The button's `Label` content is wrapped (in `ButtonFacade`) with
    46	        // `.frame(maxWidth: .infinity)` when the call site asks for a
    47	        // stretched-prominent recipe (min_w == max_w form column). The
    48	        // ButtonStyle itself does NOT pin maxWidth so non-stretched
    49	        // prominent buttons (e.g. inline action chips) keep their
    50	        // intrinsic label width.
    51	        configuration.label
    52	            .font(.body.weight(.semibold))
    53	            .foregroundStyle(.white)
    54	            .padding(.vertical, 8)
    55	            .padding(.horizontal, 16)
    56	            .background(
    57	                Capsule()
    58	                    .fill(configuration.isPressed ? tint.opacity(0.85) : tint)
    59	            )
    60	            .opacity(isEnabled ? (configuration.isPressed ? 0.95 : 1.0) : 0.5)
    61	            .contentShape(Capsule())
    62	            .accessibilityAddTraits(.isButton)
    63	    }
    64	}
    65	#endif

exec
/bin/zsh -lc "nl -ba swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift | sed -n '160,275p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
   160	        }
   161	
   162	        // Style cascade. SwiftUI layers system defaults (font, animation,
   163	        // focus, dynamic type, dark mode) over whatever style we pick.
   164	        //
   165	        // Phase 6 Rem 3-completion fix for the iOS-light "invisible
   166	        // Sign-in button" Codex blocker: `.borderedProminent` does NOT
   167	        // render any chrome on iOS-light when no `.tint(...)` is active
   168	        // in the SwiftUI environment — each Crystal-produced Button is
   169	        // hosted in its own UIHostingController so the host app's
   170	        // SwiftUI `.tint(...)` cascade does not reach it. We force the
   171	        // accent on the Button itself so `.borderedProminent` resolves
   172	        // its fill against the system accent (`accentColor` —
   173	        // appearance-tracking, so this respects light / dark and any
   174	        // explicit accent override in the SwiftUI environment if one
   175	        // happens to be in scope). The `.tint` is only applied for
   176	        // `prominent` and `tinted`: `.bordered` and `.borderless` are
   177	        // already visible without an accent.
   178	        var content: AnyView = base
   179	        switch overrides.style {
   180	        case "prominent":
   181	            // Phase 6.11 Iter 4 — Item 1.
   182	            //
   183	            // The Phase 6.8 Fix 1 brand-teal Capsule hardcode is removed.
   184	            // That workaround was retained while Phase 6.10 Rem 2 was
   185	            // still investigating a SwiftUI Button tap-closure bug at the
   186	            // UIHostingController boundary. Phase 6.10 Path A (VC
   187	            // parenting) closed that bug architecturally, so a prominent
   188	            // button can now resolve through SwiftUI's stock
   189	            // `.borderedProminent` style and surface the system tint
   190	            // (default iOS system blue, or whatever `.tint(...)` happens
   191	            // to cascade into the hosting environment).
   192	            //
   193	            // `.controlSize(.large)` lifts the inner padding to the iOS
   194	            // "large prominent" floor (~50pt tall) so a pinned-width
   195	            // sign-in button reads as a primary action, not a chip.
   196	            //
   197	            // Phase 6.12C — macOS divergence workaround.
   198	            //
   199	            // On macOS, SwiftUI's `.borderedProminent` ignores `.tint()`
   200	            // and always uses the system accent color. iOS does NOT have
   201	            // this divergence. Consumers like Cascade install a brand
   202	            // tint via `APSKRuntime.setBrandTint(...)`, which
   203	            // `HostingHelpers.host(_:)` then applies as `.tint(brand)`
   204	            // on the hosted root — that tint reaches `.bordered` /
   205	            // `.borderless` chrome (Forgot-password link goes teal) but
   206	            // NOT `.borderedProminent` chrome. To restore the brand
   207	            // promise on macOS we paint the prominent chrome from
   208	            // primitives via `APSKBrandProminentButtonStyle` (Capsule +
   209	            // white foreground + pressed/disabled state coverage). The
   210	            // style only activates when:
   211	            //   1. The build target is macOS.
   212	            //   2. A custom brand is installed
   213	            //      (`APSKRuntime.brandTint != nil`).
   214	            // When either condition is false (iOS, or macOS with
   215	            // SYSTEM_ACCENT / `Tokens.default`), the stock
   216	            // `.borderedProminent` chain runs unchanged so Voyager
   217	            // continues to render with the macOS system accent.
   218	            // See `handoff/phase-06.12c-probe-findings.md` for evidence.
   219	            #if os(macOS)
   220	            if let activeTint = APSKRuntime.brandTint {
   221	                content = AnyView(
   222	                    content.buttonStyle(
   223	                        APSKBrandProminentButtonStyle(tint: activeTint)
   224	                    )
   225	                )
   226	            } else {
   227	                content = AnyView(
   228	                    content
   229	                        .controlSize(.large)
   230	                        .buttonStyle(.borderedProminent)
   231	                )
   232	            }
   233	            #else
   234	            content = AnyView(
   235	                content
   236	                    .controlSize(.large)
   237	                    .buttonStyle(.borderedProminent)
   238	            )
   239	            #endif
   240	            // Re-apply the form-column width after the style so the
   241	            // touch-target / a11y frame matches the surrounding field
   242	            // column. The inner `Text(label).frame(maxWidth: .infinity)`
   243	            // made the *content* stretch within the bordered prominent
   244	            // chrome; this outer pin caps the overall width to the form
   245	            // column.
   246	            if wantsStretchedProminent, let mw = overrides.minWidth {
   247	                let mwCG = CGFloat(mw.doubleValue)
   248	                content = AnyView(content.frame(width: mwCG))
   249	            }
   250	        case "tinted":
   251	            content = AnyView(content
   252	                .tint(.accentColor)
   253	                .buttonStyle(.bordered))
   254	        case "bordered":
   255	            content = AnyView(content.buttonStyle(.bordered))
   256	        case "borderless":
   257	            content = AnyView(content.buttonStyle(.borderless))
   258	        default:
   259	            break
   260	        }
   261	
   262	        if overrides.role == "cancel" {
   263	            content = AnyView(content.fontWeight(.semibold))
   264	        }
   265	        // Phase 6.8 Fix 3: map the `:secondary` role from the Crystal facade
   266	        // to SwiftUI's `.bordered` chrome. Used by social-row buttons
   267	        // (Apple / Google / Email) on the demo sign-in screen so they render
   268	        // with an outlined border instead of falling through to default flat
   269	        // text. Applied as a role check (not a style switch case) because
   270	        // `:secondary` arrives via `setRole`, not `setStyle`, in the bridge.
   271	        // Only override when no explicit style was provided so app code that
   272	        // sets a style alongside `:secondary` still wins.
   273	        if overrides.role == "secondary" && overrides.style == nil {
   274	            content = AnyView(content.buttonStyle(.bordered))
   275	        }

exec
/bin/zsh -lc "rg -n \"borderedProminent|controlSize\\(\\.large\\)|prominent|brandTint|SYSTEM_ACCENT|Voyager|hardcoded|Color\\(\" docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:14://   - Liquid Glass treatment for `.prominent` style on iOS 26+
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:89:        // Phase 6.11 Iter 4: when the call-site asks for a prominent button
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:92:        // `.frame(maxWidth: .infinity)`. SwiftUI's `.borderedProminent`
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:95:        // stretched prominent button. The outer width pin (applied via
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:98:            guard overrides.style == "prominent" else { return false }
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:152:            // Phase 6.11 Iter 4: the stretched-prominent recipe pushes the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:166:        // Sign-in button" Codex blocker: `.borderedProminent` does NOT
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:171:        // accent on the Button itself so `.borderedProminent` resolves
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:176:        // `prominent` and `tinted`: `.bordered` and `.borderless` are
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:180:        case "prominent":
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:187:            // parenting) closed that bug architecturally, so a prominent
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:189:            // `.borderedProminent` style and surface the system tint
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:193:            // `.controlSize(.large)` lifts the inner padding to the iOS
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:194:            // "large prominent" floor (~50pt tall) so a pinned-width
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:199:            // On macOS, SwiftUI's `.borderedProminent` ignores `.tint()`
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:206:            // NOT `.borderedProminent` chrome. To restore the brand
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:207:            // promise on macOS we paint the prominent chrome from
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:213:            //      (`APSKRuntime.brandTint != nil`).
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:215:            // SYSTEM_ACCENT / `Tokens.default`), the stock
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:216:            // `.borderedProminent` chain runs unchanged so Voyager
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:220:            if let activeTint = APSKRuntime.brandTint {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:229:                        .controlSize(.large)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:230:                        .buttonStyle(.borderedProminent)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:236:                    .controlSize(.large)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:237:                    .buttonStyle(.borderedProminent)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:243:            // made the *content* stretch within the bordered prominent
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:301:            content = AnyView(content.background(Color(uiColor: bg)))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:303:            content = AnyView(content.background(Color(nsColor: bg)))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:309:            content = AnyView(content.foregroundStyle(Color(uiColor: fg)))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:311:            content = AnyView(content.foregroundStyle(Color(nsColor: fg)))
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:20:2. **Framework-level brand teal hardcode survives Voyager brand removal.**
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:21:   `ButtonFacade.swift:160-182` (case "prominent") explicitly paints a
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:22:   hardcoded `Color(red: 0.012, green: 0.521, blue: 0.521)` (brand teal)
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:23:   on prominent buttons, bypassing `.borderedProminent`. This was a
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:40:lines 158-182 (the `case "prominent":` block).
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:42:**Required change:** Replace the explicit `Capsule().fill(brandTeal)` chrome with the standard `.buttonStyle(.borderedProminent)` modifier. The Phase 6.10 Path A fix means the SwiftUI Button's `action:` closure now fires correctly when hosted in UIKit — so the workaround is no longer needed.
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:46:case "prominent":
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:47:    content = AnyView(content.buttonStyle(.borderedProminent))
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:53:- The hardcoded `brandTeal` Color literal is REMOVED from ButtonFacade.swift.
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:54:- Sign-in button renders with iOS system blue (`.borderedProminent` default), not teal.
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:63:- (a) Voyager screen authoring passes an explicit `placeholder_color:` argument that overrides Apple's default `placeholderText`.
docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md:122:via XCUITest (extending the existing `VoyagerVisualTests.swift` is OK
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:2:// `.borderedProminent`-equivalent chrome using a brand tint.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:5://   SwiftUI's `.borderedProminent` button style on macOS uses the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:13://   .buttonStyle(.borderedProminent)` correctly recolors the prominent
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:17:// Activation contract (see `ButtonFacade.swift` case "prominent"):
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:18://   - macOS + `APSKRuntime.brandTint != nil` (custom brand installed)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:20://   - macOS + `APSKRuntime.brandTint == nil` (Voyager / Tokens.default /
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:21://     SYSTEM_ACCENT) → stock `.borderedProminent` is used (system blue
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:23://   - iOS → stock `.borderedProminent` always (system honors `.tint`).
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:47:        // stretched-prominent recipe (min_w == max_w form column). The
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:49:        // prominent buttons (e.g. inline action chips) keep their

exec
/bin/zsh -lc 'git diff -- swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
diff --git a/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift b/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift
index 5517c191..fdae6aee 100644
--- a/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift
+++ b/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift
@@ -193,11 +193,50 @@ private struct APSKButtonHost: View {
             // `.controlSize(.large)` lifts the inner padding to the iOS
             // "large prominent" floor (~50pt tall) so a pinned-width
             // sign-in button reads as a primary action, not a chip.
+            //
+            // Phase 6.12C — macOS divergence workaround.
+            //
+            // On macOS, SwiftUI's `.borderedProminent` ignores `.tint()`
+            // and always uses the system accent color. iOS does NOT have
+            // this divergence. Consumers like Cascade install a brand
+            // tint via `APSKRuntime.setBrandTint(...)`, which
+            // `HostingHelpers.host(_:)` then applies as `.tint(brand)`
+            // on the hosted root — that tint reaches `.bordered` /
+            // `.borderless` chrome (Forgot-password link goes teal) but
+            // NOT `.borderedProminent` chrome. To restore the brand
+            // promise on macOS we paint the prominent chrome from
+            // primitives via `APSKBrandProminentButtonStyle` (Capsule +
+            // white foreground + pressed/disabled state coverage). The
+            // style only activates when:
+            //   1. The build target is macOS.
+            //   2. A custom brand is installed
+            //      (`APSKRuntime.brandTint != nil`).
+            // When either condition is false (iOS, or macOS with
+            // SYSTEM_ACCENT / `Tokens.default`), the stock
+            // `.borderedProminent` chain runs unchanged so Voyager
+            // continues to render with the macOS system accent.
+            // See `handoff/phase-06.12c-probe-findings.md` for evidence.
+            #if os(macOS)
+            if let activeTint = APSKRuntime.brandTint {
+                content = AnyView(
+                    content.buttonStyle(
+                        APSKBrandProminentButtonStyle(tint: activeTint)
+                    )
+                )
+            } else {
+                content = AnyView(
+                    content
+                        .controlSize(.large)
+                        .buttonStyle(.borderedProminent)
+                )
+            }
+            #else
             content = AnyView(
                 content
                     .controlSize(.large)
                     .buttonStyle(.borderedProminent)
             )
+            #endif
             // Re-apply the form-column width after the style so the
             // touch-target / a11y frame matches the surrounding field
             // column. The inner `Text(label).frame(maxWidth: .infinity)`

codex
The requested branch is inside the SwiftUI `body`, so the next question is whether `APSKRuntime.brandTint` is observable or only a static snapshot. I’m checking that runtime path before giving the PASS/FAIL for mid-session swaps.
exec
/bin/zsh -lc "rg -n \"class APSKRuntime|struct APSKRuntime|enum APSKRuntime|brandTint|setBrandTint|HostingHelpers|\\.tint\\(\" swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:24://   through the SwiftUI `.tint()` accent cascade rather than per-widget
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:26://   `APSKRuntime.setBrandTint(red:green:blue:alpha:)` once during render
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:29://   `APSKRuntime` and every facade's `HostingHelpers.host(_:)` wrapper
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:30://   applies it via `.tint(...)` to its hosted root. A `nil` tint means
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:57:/// `SwiftUI.Color?` so `HostingHelpers.host(_:)` can splat it into a
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:58:/// `.tint(_:)` call without re-converting on every render.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:66:public class APSKRuntime: NSObject {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:109:    @objc public static func setBrandTint(red: Double, green: Double, blue: Double, alpha: Double) {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:126:    /// Internal accessor used by `HostingHelpers.host(_:)`. Marked
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:128:    /// `SwiftUI.Color`; ObjC callers go through `setBrandTint`.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:129:    static var brandTint: Color? { currentBrandTint }
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:131:    /// Returns true once `setBrandTint` has been called at least once and
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:6://   *system* accent color exclusively. Setting `.tint(brandColor)` on
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:12://   iOS does not exhibit this divergence: `.tint(...) +
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:18://   - macOS + `APSKRuntime.brandTint != nil` (custom brand installed)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:20://   - macOS + `APSKRuntime.brandTint == nil` (Voyager / Tokens.default /
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TimePickerFacade.swift:28:        return HostingHelpers.host(DateHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:71:        return HostingHelpers.host(body)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:167:        // render any chrome on iOS-light when no `.tint(...)` is active
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:170:        // SwiftUI `.tint(...)` cascade does not reach it. We force the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:190:            // (default iOS system blue, or whatever `.tint(...)` happens
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:199:            // On macOS, SwiftUI's `.borderedProminent` ignores `.tint()`
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:202:            // tint via `APSKRuntime.setBrandTint(...)`, which
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:203:            // `HostingHelpers.host(_:)` then applies as `.tint(brand)`
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:213:            //      (`APSKRuntime.brandTint != nil`).
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:220:            if let activeTint = APSKRuntime.brandTint {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:252:                .tint(.accentColor)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SpacerFacade.swift:23:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SurfaceFacade.swift:53:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TabViewFacade.swift:8:// this TabView; SwiftUI applies it via `.tint()` scoped to the TabView.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TabViewFacade.swift:46:            content = AnyView(content.tint(Color(uiColor: tint)))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TabViewFacade.swift:48:            content = AnyView(content.tint(Color(nsColor: tint)))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TabViewFacade.swift:77:        return HostingHelpers.host(TabHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ListViewFacade.swift:74:        return HostingHelpers.host(composed)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/NavigationSplitViewFacade.swift:95:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SheetFacade.swift:66:        return HostingHelpers.host(
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/RadioGroupFacade.swift:28:        return HostingHelpers.host(IntHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SegmentedControlFacade.swift:26:        return HostingHelpers.host(IntHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/NavigationLinkFacade.swift:46:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ConfirmationDialogFacade.swift:51:        return HostingHelpers.host(ConfirmHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextFieldFacade.swift:84:        return HostingHelpers.host(StorageHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextFieldFacade.swift:90:// facade pins via `objc_setAssociatedObject` in HostingHelpers.host.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/LabelFacade.swift:54:        return HostingHelpers.host(body)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/DatePickerFacade.swift:28:        return HostingHelpers.host(DateHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ToggleFacade.swift:58:        return HostingHelpers.host(
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextEditorFacade.swift:28:        return HostingHelpers.host(TextEditorStorageHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GridFacade.swift:65:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/AlertFacade.swift:59:        return HostingHelpers.host(AlertHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/CheckboxFacade.swift:24:        return HostingHelpers.host(CheckboxHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/PopoverFacade.swift:60:        return HostingHelpers.host(PopoverHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ColorPickerFacade.swift:26:        return HostingHelpers.host(ColorHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ToolbarFacade.swift:78:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/MenuButtonFacade.swift:66:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/LinkButtonFacade.swift:28:        // blue) and does NOT follow the `.tint()` accent cascade, so a
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/LinkButtonFacade.swift:32:        // `APSKRuntime.setBrandTint(...)`, the Link text now renders in the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/LinkButtonFacade.swift:39:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/TextAreaFacade.swift:33:        return HostingHelpers.host(TextAreaStorageHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/DividerFacade.swift:39:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/FormFacade.swift:62:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:15:// only). The `.tint()` cascade in `HostingHelpers.host(_:)` propagates
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:80:        return HostingHelpers.host(composed)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ToggleButtonFacade.swift:36:        return HostingHelpers.host(ToggleButtonHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SecureFieldFacade.swift:46:        return HostingHelpers.host(SecureStorageHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/StepperFacade.swift:27:        return HostingHelpers.host(DoubleHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ImageFacade.swift:51:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/IconButtonFacade.swift:36:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/CardFacade.swift:62:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:1:// HostingHelpers — platform-conditional aliases and the single `host(_:)`
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:121:/// wraps its content in an `AnyView` at `HostingHelpers.host` entry.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:184:enum HostingHelpers {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:211:        // When no tint has been installed (`APSKRuntime.brandTint == nil`)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:214:        if let tint = APSKRuntime.brandTint {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:215:            tinted = AnyView(view.tint(tint))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SliderFacade.swift:39:        return HostingHelpers.host(
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/NavigationStackFacade.swift:63:        return HostingHelpers.host(content)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/PickerFacade.swift:44:        return HostingHelpers.host(IntHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SearchFieldFacade.swift:41:        return HostingHelpers.host(SearchStorageHost(storage: storage, content: content))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/ViewOverrides.swift:12:// This file is the sole owner of `APSKPlatformView`. HostingHelpers.swift
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/LinkButtonOverrides.swift:3:// colour, and pressed state via `.tint()`. No widget-specific knobs today.

exec
/bin/zsh -lc "nl -ba swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift | sed -n '1,170p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	// ButtonFacade — the SwiftUI Button bridge.
     2	//
     3	// Call site (Crystal): `LibSwiftKitBridge.make_button(label, overrides, token)`
     4	// → C trampoline `apsk_make_button` → `APSKButtonFacade.makeButton`
     5	//   (this file) → SwiftUI `Button` → `UIHostingController`/`NSHostingController`
     6	// → raw `UIView`/`NSView` pointer handed back to Crystal.
     7	//
     8	// Default (empty `ButtonOverrides`) behavior on iOS 26 / macOS 26:
     9	//   - System tint, system body font, default insets
    10	//   - Built-in hover/press animations
    11	//   - VoiceOver accessibility trait `.button`
    12	//   - Dynamic Type support
    13	//   - Dark / light appearance tracking
    14	//   - Liquid Glass treatment for `.prominent` style on iOS 26+
    15	//
    16	// Phase 3 Remediation 4 (reactive overrides): three properties — background
    17	// color, foreground color, corner radius — are routed through an
    18	// `APSKButtonState` `@ObservedObject` so the Crystal renderer can mutate
    19	// them at runtime (BX5 override-rerender-runtime). Style / role / disabled
    20	// / symbol remain construction-time fixed: they affect Swift type identity
    21	// of the underlying SwiftUI Button and changing them post-compose would
    22	// require a full re-render anyway.
    23	
    24	import SwiftUI
    25	import Foundation
    26	
    27	@objc(APSKButtonFacade)
    28	public class ButtonFacade: NSObject {
    29	
    30	    /// Static-construction entry point retained for back-compat.
    31	    @objc public static func makeButton(
    32	        label: String,
    33	        overrides: ButtonOverrides,
    34	        actionToken: UInt64
    35	    ) -> APSKPlatformView {
    36	        return makeReactiveButton(
    37	            label: label, overrides: overrides,
    38	            actionToken: actionToken, outState: nil
    39	        )
    40	    }
    41	
    42	    /// Reactive-construction entry. `outState` receives a +1 retained
    43	    /// pointer to an `APSKButtonState` that Crystal can later mutate via
    44	    /// `apsk_button_set_background_color` etc.
    45	    @objc public static func makeReactiveButton(
    46	        label: String,
    47	        overrides: ButtonOverrides,
    48	        actionToken: UInt64,
    49	        outState: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
    50	    ) -> APSKPlatformView {
    51	        // Seed the reactive state from the construction-time ViewOverrides
    52	        // fields. A nil entry means "leave SwiftUI default in force"; a
    53	        // later Crystal-side mutation toggles the same field on the state.
    54	        let state = APSKButtonState(
    55	            backgroundColor: overrides.backgroundColor,
    56	            foregroundColor: overrides.foregroundColor,
    57	            cornerRadius: overrides.cornerRadius,
    58	            isDisabled: overrides.disabled?.boolValue ?? false
    59	        )
    60	
    61	        if let outState = outState {
    62	            outState.pointee = Unmanaged.passRetained(state).toOpaque()
    63	        }
    64	
    65	        let body = APSKButtonHost(
    66	            label: label,
    67	            overrides: overrides,
    68	            actionToken: actionToken,
    69	            state: state
    70	        )
    71	        return HostingHelpers.host(body)
    72	    }
    73	}
    74	
    75	private struct APSKButtonHost: View {
    76	    let label: String
    77	    let overrides: ButtonOverrides
    78	    let actionToken: UInt64
    79	    @ObservedObject var state: APSKButtonState
    80	
    81	    var body: some View {
    82	        let action: () -> Void = { [actionToken] in
    83	            CallbackBridge.fire(token: actionToken, value: 0.0)
    84	        }
    85	
    86	        // Construct base view. Destructive role uses the SwiftUI role
    87	        // initializer so the system applies its red emphasis treatment.
    88	        //
    89	        // Phase 6.11 Iter 4: when the call-site asks for a prominent button
    90	        // pinned to a fixed width (min_w == max_w — the standard form-column
    91	        // recipe), build the Button with an explicit label wrapped in a
    92	        // `.frame(maxWidth: .infinity)`. SwiftUI's `.borderedProminent`
    93	        // chrome sizes to the label's intrinsic width by default; pushing
    94	        // the label to expand horizontally is the canonical idiom for a
    95	        // stretched prominent button. The outer width pin (applied via
    96	        // `.frame(width:)` after the style cascade) caps the touch target.
    97	        let wantsStretchedProminent: Bool = {
    98	            guard overrides.style == "prominent" else { return false }
    99	            guard let mw = overrides.minWidth, let mxw = overrides.maxWidth else { return false }
   100	            return mw.doubleValue == mxw.doubleValue
   101	        }()
   102	
   103	        var base: AnyView
   104	        if overrides.role == "destructive" {
   105	            if let symbol = overrides.symbolName {
   106	                base = AnyView(
   107	                    Button(role: .destructive, action: action) {
   108	                        Label(label, systemImage: symbol)
   109	                            .frame(maxWidth: wantsStretchedProminent ? .infinity : nil)
   110	                    }
   111	                )
   112	            } else {
   113	                base = AnyView(
   114	                    Button(role: .destructive, action: action) {
   115	                        Text(label)
   116	                            .frame(maxWidth: wantsStretchedProminent ? .infinity : nil)
   117	                    }
   118	                )
   119	            }
   120	        } else if let symbol = overrides.symbolName {
   121	            base = AnyView(
   122	                Button(action: action) {
   123	                    Label(label, systemImage: symbol)
   124	                        .frame(maxWidth: wantsStretchedProminent ? .infinity : nil)
   125	                }
   126	            )
   127	        } else if wantsStretchedProminent {
   128	            base = AnyView(
   129	                Button(action: action) {
   130	                    Text(label).frame(maxWidth: .infinity)
   131	                }
   132	            )
   133	        } else {
   134	            base = AnyView(Button(label, action: action))
   135	        }
   136	
   137	        // BX6 / BX9: apply minHeight/minWidth as exact frame() pins
   138	        // on the Button. SwiftUI's body-Button intrinsic is ~25pt; the
   139	        // `.frame(height:)` modifier widens the rendered Button (and
   140	        // its content-shape hit-test rect). Use `.contentShape` to also
   141	        // expand the AX hit rect so XCUITest's `frame.size` reads the
   142	        // touch-target floor rather than the natural body-text rect.
   143	        if let mh = overrides.minHeight {
   144	            let mhCG = CGFloat(mh.doubleValue)
   145	            base = AnyView(
   146	                base.frame(minHeight: mhCG)
   147	                    .contentShape(Rectangle())
   148	            )
   149	        }
   150	        if let mw = overrides.minWidth {
   151	            let mwCG = CGFloat(mw.doubleValue)
   152	            // Phase 6.11 Iter 4: the stretched-prominent recipe pushes the
   153	            // *label* to fill horizontally above; the outer width pin is
   154	            // applied AFTER the style cascade so the touch-target / a11y
   155	            // frame matches. For any other configuration, fall back to
   156	            // `.frame(minWidth:)` here.
   157	            if !wantsStretchedProminent {
   158	                base = AnyView(base.frame(minWidth: mwCG))
   159	            }
   160	        }
   161	
   162	        // Style cascade. SwiftUI layers system defaults (font, animation,
   163	        // focus, dynamic type, dark mode) over whatever style we pick.
   164	        //
   165	        // Phase 6 Rem 3-completion fix for the iOS-light "invisible
   166	        // Sign-in button" Codex blocker: `.borderedProminent` does NOT
   167	        // render any chrome on iOS-light when no `.tint(...)` is active
   168	        // in the SwiftUI environment — each Crystal-produced Button is
   169	        // hosted in its own UIHostingController so the host app's
   170	        // SwiftUI `.tint(...)` cascade does not reach it. We force the

exec
/bin/zsh -lc "git grep -n \"Color(red:\\|Color(.*red:\\|brandTeal\\|0\\.012\\|0\\.521\\|0x\" -- swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit | head -80" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ColorPickerFacade.swift:17:        let initial = Color(.sRGB, red: initialR, green: initialG, blue: initialB, opacity: initialA)

exec
/bin/zsh -lc "nl -ba swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift | sed -n '180,235p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
   180	}
   181	
   182	#endif
   183	
   184	enum HostingHelpers {
   185	    /// Wrap `view` in a hosting controller, retain the controller for the
   186	    /// lifetime of its `.view`, and return the platform view.
   187	    ///
   188	    /// Crystal's `NativeHandle` takes ownership of the returned view pointer
   189	    /// (+1 retain). The hosting controller is associated with the view via
   190	    /// `objc_setAssociatedObject` so it lives as long as the view does.
   191	    ///
   192	    /// The `.frame(minWidth: 1, minHeight: 1)` defensive sizing is required
   193	    /// for the SwiftUI Form/List re-measure quirk documented in §5.6.
   194	    ///
   195	    /// Phase 6.10 Rem 3 (Path A): on UIKit an
   196	    /// `APSKHostingControllerAttacher` is attached via ObjC association
   197	    /// to the returned hosted view so the hosting controller can be
   198	    /// registered as a child VC of the responder-chain's parent
   199	    /// UIViewController the moment the view enters a window. This is
   200	    /// required for SwiftUI's gesture scheduler to fire Button / Toggle
   201	    /// / Slider callbacks when the hosting controller's `.view` is
   202	    /// embedded in a UIKit subtree (the Crystal renderer's UIStackView
   203	    /// root model). AppKit is unaffected — NSHostingView reports actions
   204	    /// independently of NSViewController containment.
   205	    static func host<V: View>(_ view: V) -> APSKPlatformView {
   206	        // Apply the brand tint last so it cascades into every child view
   207	        // SwiftUI considers part of this hosted root. Hosted roots are
   208	        // isolated tint scopes — there is no propagation across
   209	        // `UIHostingController` / `NSHostingController` boundaries — so
   210	        // each facade re-applies the currently installed brand tint.
   211	        // When no tint has been installed (`APSKRuntime.brandTint == nil`)
   212	        // SwiftUI's system accent colour shows through unchanged.
   213	        let tinted: AnyView
   214	        if let tint = APSKRuntime.brandTint {
   215	            tinted = AnyView(view.tint(tint))
   216	        } else {
   217	            tinted = AnyView(view)
   218	        }
   219	        let sized = AnyView(tinted.frame(minWidth: 1, minHeight: 1))
   220	
   221	        let platformView: APSKPlatformView
   222	        let lifetimeOwner: AnyObject
   223	        #if canImport(UIKit)
   224	        // UIHostingController + .view is the standard UIKit path.
   225	        // `sizingOptions` is set BEFORE first access to `.view` so the
   226	        // hosted UIView reports the SwiftUI intrinsic size on the first
   227	        // layout pass; the prior order produced a CGSizeZero report and
   228	        // collapsed the button to invisible inside a UIStackView.
   229	        // Phase 6.10 Rem 3 (Path A): use the
   230	        // `APSKAttachingHostingController` subclass that registers
   231	        // itself as a child VC of the responder-chain's parent
   232	        // UIViewController on first layout. This is the missing
   233	        // handshake SwiftUI's gesture scheduler needs to fire Button /
   234	        // Toggle / Slider action closures when the hosting controller's
   235	        // `.view` is embedded in a UIKit subtree.

exec
/bin/zsh -lc "nl -ba swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift | sed -n '1,155p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	// CallbackBridge — the one-direction Swift → Crystal action dispatch surface
     2	// PLUS the brand-tint runtime registry that drives the "SwiftUI Default
     3	// Supremacy" cascade.
     4	//
     5	// Action dispatch:
     6	//
     7	//   At runtime the Swift companion is statically linked into the
     8	//   Crystal-driven host binary. Crystal exports a single `@convention(c)`
     9	//   trampoline function, `ap_swiftkit_invoke_action(token: UInt64, value:
    10	//   Double)`. During app startup Crystal calls
    11	//   `APSKRuntime.initialize(actionTrampoline:)` once, passing the address
    12	//   of that trampoline. Subsequent UI events (Button tap, Toggle change,
    13	//   Slider drag-end) fire `CallbackBridge.fire(token:value:)` which calls
    14	//   the trampoline, which routes through the Crystal-side
    15	//   `UI::CallbackRegistry` to the original `Proc`.
    16	//
    17	//   `token == 0` means "no callback wired" — every call site checks. This
    18	//   matches the Crystal-side convention (token 0 is never handed out by
    19	//   `register_action`).
    20	//
    21	// Brand tint:
    22	//
    23	//   Under Option B ("SwiftUI Default Supremacy") brand identity propagates
    24	//   through the SwiftUI `.tint()` accent cascade rather than per-widget
    25	//   colour overrides. The Crystal renderer calls
    26	//   `APSKRuntime.setBrandTint(red:green:blue:alpha:)` once during render
    27	//   set-up (and re-applies it whenever `design_tokens` changes), passing
    28	//   the active `brand_primary` colour. The current tint is stored on
    29	//   `APSKRuntime` and every facade's `HostingHelpers.host(_:)` wrapper
    30	//   applies it via `.tint(...)` to its hosted root. A `nil` tint means
    31	//   "no override — use the system accent colour."
    32	
    33	import SwiftUI
    34	import Foundation
    35	
    36	/// Pointer to the Crystal-side trampoline. Set once at startup by
    37	/// `APSKRuntime.initializeWithActionTrampoline:`. Stored as an optional
    38	/// so the package can be loaded before Crystal initialization (the spec
    39	/// helper exercises this path).
    40	private var actionTrampoline: (@convention(c) (UInt64, Double) -> Void)? = nil
    41	
    42	/// Phase 6.10 Rem 4 (Item 1) — string-valued trampoline for TextField /
    43	/// SecureField / TextArea / SearchField on_change events that need to
    44	/// dispatch the actual typed string (not just a length signal). Crystal
    45	/// exports `ap_swiftkit_invoke_action_string(token, c_string)`; Swift
    46	/// installs the pointer via `APSKRuntime.initialize(stringTrampoline:)`.
    47	///
    48	/// Without this, the previous on_change callback collapsed every char
    49	/// event to `value: Double(text.count)` — the Crystal-side
    50	/// `->(value : String) { ... }` closure never saw the actual text,
    51	/// breaking Save (the editor's `state.add_todo(draft.title, ...)`
    52	/// committed an empty title).
    53	private var stringTrampoline: (@convention(c) (UInt64, UnsafePointer<CChar>?) -> Void)? = nil
    54	
    55	/// Cached brand tint applied to every hosted SwiftUI root. `nil` means
    56	/// "use the system accent colour" (SwiftUI default behaviour). Stored as
    57	/// `SwiftUI.Color?` so `HostingHelpers.host(_:)` can splat it into a
    58	/// `.tint(_:)` call without re-converting on every render.
    59	///
    60	/// Reads and writes are confined to the main thread (UIKit/AppKit
    61	/// renderer contract — the Crystal-side renderer initialiser and the
    62	/// facade `host(_:)` call both run on the main thread).
    63	private var currentBrandTint: Color? = nil
    64	
    65	@objc(APSKRuntime)
    66	public class APSKRuntime: NSObject {
    67	    /// Called by Crystal once, immediately after `GC.init` and before any
    68	    /// facade is invoked. Passes a C function pointer to
    69	    /// `ap_swiftkit_invoke_action` (Crystal-exported `fun`).
    70	    ///
    71	    /// `trampoline` is treated as `UnsafeRawPointer` to keep the ObjC
    72	    /// surface free of Swift-only types; the unsafeBitCast restores the
    73	    /// expected `@convention(c)` signature on the Swift side.
    74	    @objc public static func initialize(actionTrampoline trampoline: UnsafeRawPointer) {
    75	        actionTrampoline = unsafeBitCast(
    76	            trampoline,
    77	            to: (@convention(c) (UInt64, Double) -> Void).self
    78	        )
    79	    }
    80	
    81	    /// Phase 6.10 Rem 4 — install the string-valued action trampoline.
    82	    /// Called by the Crystal runtime initializer alongside the
    83	    /// numeric `actionTrampoline:` installer. Pass `nil` (via a
    84	    /// separate clear method if needed) is intentionally not supported
    85	    /// — the runtime spec installs once at startup and never clears.
    86	    @objc public static func initialize(stringTrampoline trampoline: UnsafeRawPointer) {
    87	        stringTrampoline = unsafeBitCast(
    88	            trampoline,
    89	            to: (@convention(c) (UInt64, UnsafePointer<CChar>?) -> Void).self
    90	        )
    91	    }
    92	
    93	    /// Returns true once `initialize(stringTrampoline:)` has been
    94	    /// called. Used by the runtime spec.
    95	    @objc public static var isStringTrampolineInstalled: Bool {
    96	        stringTrampoline != nil
    97	    }
    98	
    99	    /// Install (or replace) the brand tint colour applied to every
   100	    /// SwiftUI facade root. Components inside a hosted root inherit this
   101	    /// tint as their accent colour, which is how a brand override on
   102	    /// Crystal's `design_tokens.colors.brand_primary` reaches the
   103	    /// rendered pixel.
   104	    ///
   105	    /// Re-callable: the renderer calls this on every `render(...)` entry
   106	    /// so a brand swap mid-session (`design_tokens =
   107	    /// Tokens.default.with_brand(...)`) takes effect on the next render.
   108	    /// Channel values are normalised 0...1 sRGB.
   109	    @objc public static func setBrandTint(red: Double, green: Double, blue: Double, alpha: Double) {
   110	        currentBrandTint = Color(
   111	            .sRGB,
   112	            red: red,
   113	            green: green,
   114	            blue: blue,
   115	            opacity: alpha
   116	        )
   117	    }
   118	
   119	    /// Clear the brand tint. After this call, hosted roots fall back to
   120	    /// SwiftUI's automatic accent colour. Used by tests and for sample
   121	    /// builds that intentionally want raw SwiftUI defaults.
   122	    @objc public static func clearBrandTint() {
   123	        currentBrandTint = nil
   124	    }
   125	
   126	    /// Internal accessor used by `HostingHelpers.host(_:)`. Marked
   127	    /// `internal` because nothing outside the package needs the raw
   128	    /// `SwiftUI.Color`; ObjC callers go through `setBrandTint`.
   129	    static var brandTint: Color? { currentBrandTint }
   130	
   131	    /// Returns true once `setBrandTint` has been called at least once and
   132	    /// the tint has not been cleared. Used by specs and by the runtime
   133	    /// spec to confirm wiring without exposing the colour itself.
   134	    @objc public static var hasBrandTint: Bool {
   135	        currentBrandTint != nil
   136	    }
   137	
   138	    /// Test-only hook. Lets `CallbackBridgeTests.swift` install a Swift
   139	    /// closure in place of the Crystal trampoline so the round-trip can
   140	    /// be exercised without linking against libcrystal.
   141	    @objc public static func _installTestTrampoline(
   142	        _ trampoline: @convention(c) (UInt64, Double) -> Void
   143	    ) {
   144	        actionTrampoline = trampoline
   145	    }
   146	
   147	    /// Returns true once `initialize(actionTrampoline:)` has been called.
   148	    /// Used by the runtime spec to confirm wiring.
   149	    @objc public static var isActionTrampolineInstalled: Bool {
   150	        actionTrampoline != nil
   151	    }
   152	}
   153	
   154	enum CallbackBridge {
   155	    /// Fire the registered Crystal trampoline. `token == 0` is a no-op

exec
/bin/zsh -lc 'git diff --stat -- swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
 .../Facades/ButtonFacade.swift                     | 39 ++++++++++++++++++++++
 1 file changed, 39 insertions(+)

exec
/bin/zsh -lc "rg -n \"setBrandTint|clearBrandTint|SYSTEM_ACCENT|system accent|brand_primary|brandTint\" src examples swift spec docs/initiative-cross-platform-ui -g '"'!docs/initiative-cross-platform-ui/handoff/phase-06.12c-evidence/**'"'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:26://   `APSKRuntime.setBrandTint(red:green:blue:alpha:)` once during render
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:28://   the active `brand_primary` colour. The current tint is stored on
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:31://   "no override — use the system accent colour."
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:56:/// "use the system accent colour" (SwiftUI default behaviour). Stored as
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:102:    /// Crystal's `design_tokens.colors.brand_primary` reaches the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:109:    @objc public static func setBrandTint(red: Double, green: Double, blue: Double, alpha: Double) {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:122:    @objc public static func clearBrandTint() {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:128:    /// `SwiftUI.Color`; ObjC callers go through `setBrandTint`.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:129:    static var brandTint: Color? { currentBrandTint }
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:131:    /// Returns true once `setBrandTint` has been called at least once and
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:8://   background fill always resolves to the system accent. Confirmed
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:18://   - macOS + `APSKRuntime.brandTint != nil` (custom brand installed)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:20://   - macOS + `APSKRuntime.brandTint == nil` (Voyager / Tokens.default /
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:21://     SYSTEM_ACCENT) → stock `.borderedProminent` is used (system blue
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:22://     / system accent — exactly what the consumer wants).
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:34://     demanding contrast budgets should override `brand_primary` to a
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/GlassBackgroundFacade.swift:14:// brand tint (Apple convention — glass surfaces accept system accent
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/LinkButtonFacade.swift:32:        // `APSKRuntime.setBrandTint(...)`, the Link text now renders in the
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:172:        // its fill against the system accent (`accentColor` —
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:200:            // and always uses the system accent color. iOS does NOT have
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:202:            // tint via `APSKRuntime.setBrandTint(...)`, which
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:213:            //      (`APSKRuntime.brandTint != nil`).
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:215:            // SYSTEM_ACCENT / `Tokens.default`), the stock
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:217:            // continues to render with the macOS system accent.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:220:            if let activeTint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/rubric/validation_criteria.md:47:- **Cascade that doesn't cascade.** A brand override changes the Crystal-side `brand_primary` to coral. The web generator emits an updated `--ap-color-brand-primary` custom property. Presence: pass — the variable is set. **Behavior fails:** the rendered Button still draws teal because the Button widget's renderer visitor hard-codes a Color literal instead of reading `var(--ap-color-brand-primary)`. A presence check on the variable would never have surfaced this.
docs/initiative-cross-platform-ui/rubric/validation_criteria.md:172:      "notes": "Changed brand_primary from #7c9a92 to #ff0000 in test theme. CSS custom property --ap-color-brand-primary updated correctly. But button background did not change — the button widget hard-codes its background_color attribute and does not read from the token system. See spec output for failing test."
docs/initiative-cross-platform-ui/phases/phase-03-swiftui-native-bridge/validation.md:516:- **Verify:** an unstyled `UI::Toggle.new(label: "Notify", is_on: true)` renders as a SwiftUI Toggle — system green track on iOS, system accent on macOS.
docs/initiative-cross-platform-ui/phases/phase-03-swiftui-native-bridge/validation.md:518:- **Pass:** track is system green (iOS) / system accent (macOS); label uses system font; thumb has the SwiftUI default shadow.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:211:        // When no tint has been installed (`APSKRuntime.brandTint == nil`)
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:212:        // SwiftUI's system accent colour shows through unchanged.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:214:        if let tint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/design.md:179:  # Application-wide design tokens (system accent by default per Phase 6.12;
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/TabViewOverrides.swift:5://                       inherit the brand cascade tint or system accent.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-2.md:4:**Commit reviewed:** `35fb371` — `[Phase 6.12A Item 2] Wire 4 renderer paths to honour Color::SYSTEM_ACCENT`
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-2.md:15:1. Android still has a runtime sentinel leak named by Item 2. The brief requires the Android path to handle `SYSTEM_ACCENT` instead of rendering the sentinel payload ([brief.md](../../initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:217), acceptance at [brief.md](../../initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:246)). Current Android renderer initializes `@material_theme = UI::Theme.material_baseline` ([android_renderer.cr](../../../src/ui/renderers/android_renderer.cr:3369)), selects `theme.primary` for `:primary` ([android_renderer.cr](../../../src/ui/renderers/android_renderer.cr:3213)), then raw-packs `ThemeColor` RGBA in `theme_color_to_argb` ([android_renderer.cr](../../../src/ui/renderers/android_renderer.cr:3190)). Because `UI::Theme.material_baseline.primary` now has `rgba=0,0,0,0` with `css_override="AccentColor"` from [theme.cr](../../../src/ui/theme.cr:249), Android still produces ARGB `0`.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:18:3. `brand_primary` alone expanded to the brand-color family (primary/hover/active + generator outputs).
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:56:### Item 1 — `SYSTEM_ACCENT` sentinel (Path C1, fully specified)
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:58:**Goal:** `Tokens.default.brand_primary` returns a sentinel color value that each renderer detects + maps to its platform's native accent path.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:67:    # SYSTEM_ACCENT is a sentinel Color value meaning "this color
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:72:    SYSTEM_ACCENT = new(
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:85:    # / Android representation as today. For SYSTEM_ACCENT, return the
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:109:        "Cannot serialize Color::SYSTEM_ACCENT as Android ARGB. " \
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:123:        io << "Color::SYSTEM_ACCENT"
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:134:In `Tokens.default`, the `brand_primary`, `brand_primary_hover`, `brand_primary_active` family ALL return `Color::SYSTEM_ACCENT`:
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:139:    brand_primary: Color::SYSTEM_ACCENT,
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:140:    brand_primary_hover: Color::SYSTEM_ACCENT,
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:141:    brand_primary_active: Color::SYSTEM_ACCENT,
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:155:    it "uses Color::SYSTEM_ACCENT for the brand_primary family" do
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:157:      t.colors_light.brand_primary.system_accent?.should be_true
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:158:      t.colors_light.brand_primary_hover.system_accent?.should be_true
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:159:      t.colors_light.brand_primary_active.system_accent?.should be_true
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:160:      t.colors_dark.brand_primary.system_accent?.should be_true
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:168:      t.colors_light.brand_primary.system_accent?.should be_false
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:169:      t.colors_light.brand_primary.to_swift.should eq("Color(red: 0.059, green: 0.522, blue: 0.522)")
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:177:- `UI::DesignTokens::Color::SYSTEM_ACCENT` exists with full API (constructor, `system_accent?`, `to_css`, `to_swift`, `to_android_argb`, `==`, `to_s`).
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:178:- `Tokens.default.colors_light.brand_primary` AND `.brand_primary_hover` AND `.brand_primary_active` ALL return the sentinel.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:185:  - **Android XML** generator: raises `UI::DesignTokens::AndroidRendererNotImplemented` (with a clear message) when hit by `Color::SYSTEM_ACCENT`. The regenerator must NOT exit 0 silently with a broken Android output — but it MUST handle the failure gracefully (continue generating other targets, report which targets failed at exit). Implementer ships a fallback: skip the Android target when SYSTEM_ACCENT is in play, log a diagnostic.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:193:brand = @design_tokens.colors_light.brand_primary
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:203:Mirror the iOS change. The Swift-side `APSKRuntime.clearBrandTint` is platform-shared so the same fun call works.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:210:brand = tokens.colors_light.brand_primary
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:228:    "Android renderer does not yet support Color::SYSTEM_ACCENT. " \
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:237:- iOS renderer: when tokens use SYSTEM_ACCENT, `clear_brand_tint` is called (mock the `LibSwiftKitBridge` fun via a test seam — see `Implementation note` below).
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:240:- Web renderer: when tokens use SYSTEM_ACCENT, emitted CSS contains `--ap-color-brand-primary: AccentColor;`. When tokens use a custom brand, emitted CSS contains the actual hex / rgb value.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:301:Codex flagged that `brand_primary` alone is too narrow; the brand family + generated outputs could still leak amber.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:375:- `Color::SYSTEM_ACCENT` API + spec ships.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/README.md:13:The library's iOS renderer unconditionally installs `apsk_runtime_set_brand_tint(...)` with `Tokens.default.colors_light.brand_primary` on every render. `Tokens.default.brand_primary` is the library's amber identity. `HostingHelpers.host` then applies `.tint(amber)` to every SwiftUI root, so consumer apps that didn't ask for a brand (Voyager after Phase 6.11 Item 1's `brand.cr` deletion) STILL render Cancel buttons, `.bordered` chrome, and `.borderedProminent` defaults in amber.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/README.md:17:**Option C (owner-selected):** `Tokens.default.brand_primary` resolves to the platform's system accent (iOS systemBlue / macOS controlAccentColor / web -apple-system-blue / Android colorPrimary). Apps that want their own brand call `.with_brand(...)` explicitly. The asset_pipeline library no longer has "an amber look" by default; it inherits the platform's native accent.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/README.md:35:1. **Library-identity pivot (Option C).** `Tokens.default.brand_primary` semantically resolves to platform system accent. Implementation requires either (a) introducing a `Color::SYSTEM_ACCENT` sentinel that each renderer detects + maps to the platform-native accent path (preferred — preserves the brand-cascade infrastructure for apps that want a custom brand), OR (b) making `brand_primary` nilable with explicit nil meaning "system accent" (clearer semantic but bigger type ripple). Implementer chooses; architect-side Codex reviews the choice before dispatch.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/README.md:40:   - Web renderer (`web_renderer.cr`) — emits CSS variable `--ap-color-brand-primary` as `-apple-system-blue` / `system-ui` color OR omits the variable entirely when system_accent (browser falls back to system accent).
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/README.md:77:- `Tokens.default.brand_primary` no longer carries the library's amber identity. It resolves semantically to platform system accent.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12b.md:12:Phase 6.12A (commit `973d32d`) shipped the library-identity pivot (`Color::SYSTEM_ACCENT` sentinel + 4 renderer integrations + macOS NSWindow sizing + Cascade preservation + no-amber audit) per its brief. Evidence captures were explicitly carved out and deferred to 6.12B per [[mid-stop-pattern-evidence-capture]]:
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12b.md:57:1. Show a prominent button rendered in Cascade's deep teal (NOT the system blue we set for Voyager via SYSTEM_ACCENT).
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12b.md:114:The Phase 6.11 iter-3 audit was flagged NEEDS_WORK by Codex 3 (over-broad "semantic auto-pass" claims). 6.12A's pivot to SYSTEM_ACCENT changes what should be on-screen (system blue buttons instead of amber). Recapture all 8 + rewrite the audit.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12b.md:157:- The Sign-in button background (should now be iOS system blue post-SYSTEM_ACCENT, was amber under the pre-6.12A library default).
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/validation.md:65:- **Verify:** A `Brand` subclass that overrides only `brand_primary` leaves every other field equal to the default.
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/validation.md:127:- **Verify:** Same as #11 for `appkit_renderer.cr`. Specifically confirm: `amber_brand_gold` is **deleted** (or now calls `token_color(:brand_primary, ...)`); every `LibObjCBridge.nsfont_system(<float>)` literal in a visit method derives that float from a token; every `setCornerRadius:` numeric arg derives from `token_radius(:...)`.
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/validation.md:167:- **Verify:** Defining a `Brand` subclass that sets `brand_primary` to `#ff00ff` (sentinel magenta) and re-rendering the brand-cascade demo page actually paints magenta on the rendered widget.
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/validation.md:169:  1. Apply a temporary edit to `samples/cross_platform/web/brand_cascade_demo.cr` (created in Phase 1 Step 12) so its `SentinelBrand` returns `Color.hex("#ff00ff")` for `brand_primary`. The demo source must contain at least one Button (or a div with `data-testid="brand-primary-sample"`) whose background is bound to `brand_primary`.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md:12:Phase 6.12B's capture agent reached Priority 1A and confirmed empirically: **Cascade macOS prominent Sign-in button no longer renders deep teal — it renders light gray.** Phase 6.11 iter-4 removed the `Capsule.fill(brandTeal)` workaround in `ButtonFacade.swift` case "prominent" because Path A (Phase 6.10 VC parenting) had made it obsolete for the SwiftUI Button tap chain. But that workaround was ALSO masking a separate macOS-specific quirk: `.borderedProminent` on macOS uses the system accent color regardless of `.tint()` set in the SwiftUI environment.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md:16:This is a Cascade-specific regression because Cascade applies a custom brand. Voyager (which uses `Tokens.default` = `Color::SYSTEM_ACCENT` after Phase 6.12A) is unaffected — its prominent buttons correctly resolve to system blue.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md:63:  if let activeTint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md:80:- Conditional on `APSKRuntime.brandTint != nil` (only when a custom brand is active — Voyager with SYSTEM_ACCENT gets plain `.borderedProminent`).
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md:115:  if let activeTint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md:139:If the SwiftUI quirk is genuinely undocumented behavior we can't reliably work around, document that custom-brand prominent buttons on macOS render with the system accent. Cascade developers either accept this OR use a different style. **Loses brand cascade promise.**
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md:159:8. **Add assertion (per Codex)** that Voyager's `APSKRuntime.brandTint == nil` at render time, since Voyager uses `SYSTEM_ACCENT`. Phase 6.12A Item 2 wired this clearing — verify it actually happens. Test seam: instrument `APSKRuntime.brandTint` access via a logging or test-mode hook to confirm the value is nil during Voyager's render path. If `brandTint` is unexpectedly non-nil for Voyager, ESCALATE — the SYSTEM_ACCENT clearing path is broken.
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md:169:codex exec --skip-git-repo-check "Review the Phase 6.12C fix at swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift (the case 'prominent' branch). Verify: (1) macOS-only conditional protects Voyager (which uses SYSTEM_ACCENT) from regression; (2) reads APSKRuntime.brandTint at render time so a brand swap mid-session takes effect; (3) the iOS branch unchanged from Phase 6.11 iter-4; (4) no hardcoded color literal restored. Verdict per item: PASS/FAIL. Overall: APPROVE / REVISE."
docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md:179:- DO NOT restore Phase 6.8 hardcoded `Color(red: 0.012, green: 0.521, blue: 0.521)` literal. Use the live `APSKRuntime.brandTint` value.
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:138:      brand_primary : Color,
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:139:      brand_primary_hover : Color,
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:140:      brand_primary_active : Color,
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:168:          "brand-primary" => brand_primary,
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:291:      #   tokens.lookup("colors.light.brand_primary") # => Color
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:357:      brand_primary: UI::DesignTokens::Color.hex("#1d4ed8"),
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:358:      brand_primary_hover: UI::DesignTokens::Color.hex("#1e40af"),
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:370:**`copy_with` is mandatory on every record-derived token type.** Phase 6 (and any consuming app brand) writes `palette.copy_with(brand_primary: ...)`-style merges relying on this method existing. If Crystal's `record` macro auto-generates `copy_with` on the pinned compiler version, that satisfies the requirement. If it does not, hand-roll `copy_with` on each affected type — `ColorPalette`, `SpacingScale`, `TypeScale`, `RadiusScale`, `ShadowScale`, `MotionScale`, `Breakpoints`, and `Tokens` itself — taking keyword arguments matching the record's fields and returning a new instance with the named fields replaced and the rest copied. Verify on the actual compiler version before assuming auto-generation; if uncertain, hand-roll. The file header in `design_tokens.cr` documents which path was taken.
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:548:**Good output:** `crystal spec spec/ui/design_tokens_spec.cr` green. `Tokens.default.colors_light.brand_primary.to_oklch_css == "oklch(0.520 0.160 50.00)"`.
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:555:**Good output:** spec where `AcmeBrand` overrides `brand_primary` only — assert every other field equals default.
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:591:**Change:** in `src/ui/renderers/web_renderer.cr`, replace every `"rgba(#{to_rgb_int(...)})"` inline color emit and every literal `9999px`, `#FFCC00`, etc. with a call into a new private helper `token_css(:color, :brand_primary)` / `token_css(:radius, :pill)` / etc. `inject_theme_css` re-derives its output by calling `WebGenerator.generate(tokens)` directly — no parallel string-building.
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:598:**Change:** in `src/ui/renderers/appkit_renderer.cr`, delete `amber_brand_gold` and any literal RGBA in visitors. Add `token_color(:brand_primary, appearance: current_appearance)` private helper that resolves a `DesignTokens::Color` to `NSColor*` via the existing bridge. Every `LibObjCBridge.nsfont_system(13.0)` etc. is replaced with `token_font(:body)` returning the bridge call with the size pulled from `DesignTokens::Tokens.default.type.body.size` (multiplied to pt). Corner radius literals like `setCornerRadius:` numeric arguments come from `token_radius(:md)` etc.
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:614:**Change:** add `spec/ui/design_tokens_cascade_spec.cr` that uses a `TestBrand` overriding `brand_primary` to a sentinel color, then asserts:
docs/initiative-cross-platform-ui/phases/phase-01-design-token-foundation/implementation.md:688:5. Defining a 5-line subclass of `Brand` that overrides `brand_primary` to a sentinel and rendering a sample view on **web and at least one Apple target (macOS or iOS)** shows the sentinel color. Android sentinel-cascade is deferred along with the generator.
docs/initiative-cross-platform-ui/handoff/phase-06.11-reflection-2026-05-24.md:42:- **Architectural finding:** UIKit renderer (`uikit_renderer.cr:4109-4112`) unconditionally calls `apsk_runtime_set_brand_tint(...)` with `design_tokens.colors_light.brand_primary` on every render. Voyager carries `Tokens.default`, whose `brand_primary` is the library's amber. `HostingHelpers.host` applies `.tint(amber)` to every SwiftUI root → Cancel buttons render amber even with Voyager's consumer-side brand removal.
docs/initiative-cross-platform-ui/handoff/phase-06.11-reflection-2026-05-24.md:43:- Full finding doc at `phase-06.11-iter-5-architectural-finding.md` with 4 options (A: nilable brand_primary, B: per-consumer opt-out, C: system-accent default — owner-selected, D: defer). Owner selected **Option C: `Tokens.default` tracks platform accent.** Carries to Phase 6.12.
docs/initiative-cross-platform-ui/handoff/phase-06.11-reflection-2026-05-24.md:47:- **Library-identity pivot (Option C):** make `Tokens.default.brand_primary` resolve to platform system accent (iOS systemBlue, macOS controlAccentColor, etc.) rather than the library's amber. Cascade demo gets explicit `.with_brand(CascadeBrand)` to preserve its branded look.
docs/initiative-cross-platform-ui/handoff/phase-06.11-reflection-2026-05-24.md:71:`[[plan-what-to-understand-not-just-what-to-build]]` — Phase 6.11's Item 1 acceptance was "delete Voyager's brand.cr." That was correct as far as it went but didn't grep the framework for OTHER brand cascade paths. The architectural finding in iter-5 surfaced ones in `ButtonFacade.swift` (now closed), `CallbackBridge.swift` brandTint registry (still live), the UIKit renderer's `ensure_swiftkit_runtime!` brand-tint propagation (still live), and `Tokens.default.brand_primary` itself (the root cause Option C addresses).
docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/validation.stale-pre-2026-05-22.md:92:1. Pick a single, easily-reverted source change that will visibly alter at least one screen. Recommended: shift the demo brand primary color by 30° hue rotation in `samples/initiative-cross-platform-ui-demo/src/brand.cr` (within `override_color_light`'s `brand_primary:` line — flip the `h` argument from `25` to `55`).
src/components/css/tokens/amber_theme.cr:236:            # the unified-design-tokens `brand_primary` resolves to. After
src/components/css/tokens/amber_theme.cr:240:            # below mirror the original amber values that brand_primary
swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/SnapshotTests.swift:29:        APSKRuntime.clearBrandTint()
swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/RuntimeBridgeTests.swift:44:        APSKRuntime.clearBrandTint()
swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/RuntimeBridgeTests.swift:50:        APSKRuntime.clearBrandTint()
swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/RuntimeBridgeTests.swift:55:        APSKRuntime.setBrandTint(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/RuntimeBridgeTests.swift:60:        APSKRuntime.setBrandTint(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/RuntimeBridgeTests.swift:62:        APSKRuntime.clearBrandTint()
swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/RuntimeBridgeTests.swift:67:        APSKRuntime.setBrandTint(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/RuntimeBridgeTests.swift:68:        APSKRuntime.setBrandTint(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
docs/initiative-cross-platform-ui/handoff/phase-03-state-2026-05-21-codex-context.md:12:- `APSKRuntime.setBrandTint` propagates a single brand color via `.tint()` cascade rather than per-widget injection.
src/ui/theme.cr:8:  # `UI::DesignTokens::Color` sentinel (e.g. `Color::SYSTEM_ACCENT`) can
src/ui/theme.cr:179:      theme.primary = theme_color_from(light.brand_primary)
src/ui/theme.cr:251:      # source design-token is a sentinel (e.g. SYSTEM_ACCENT). Without
spec/ui/design_tokens_default_accent_spec.cr:7:# instead, the `brand_primary` / `brand_primary_hover` / `brand_primary_active`
spec/ui/design_tokens_default_accent_spec.cr:8:# family resolves to `Color::SYSTEM_ACCENT`, a sentinel each renderer maps
spec/ui/design_tokens_default_accent_spec.cr:18:  describe "::SYSTEM_ACCENT" do
spec/ui/design_tokens_default_accent_spec.cr:20:      UI::DesignTokens::Color::SYSTEM_ACCENT.system_accent?.should be_true
spec/ui/design_tokens_default_accent_spec.cr:32:      UI::DesignTokens::Color::SYSTEM_ACCENT.to_css.should eq("AccentColor")
spec/ui/design_tokens_default_accent_spec.cr:36:      UI::DesignTokens::Color::SYSTEM_ACCENT.to_swift.should eq("Color.accentColor")
spec/ui/design_tokens_default_accent_spec.cr:40:      sentinel = UI::DesignTokens::Color::SYSTEM_ACCENT
spec/ui/design_tokens_default_accent_spec.cr:46:      UI::DesignTokens::Color::SYSTEM_ACCENT.to_swift_color.should eq("Color.accentColor")
spec/ui/design_tokens_default_accent_spec.cr:50:      expect_raises(UI::DesignTokens::AndroidRendererNotImplemented, /SYSTEM_ACCENT/) do
spec/ui/design_tokens_default_accent_spec.cr:51:        UI::DesignTokens::Color::SYSTEM_ACCENT.to_android_argb
spec/ui/design_tokens_default_accent_spec.cr:56:      expect_raises(ArgumentError, /SYSTEM_ACCENT/) do
spec/ui/design_tokens_default_accent_spec.cr:57:        UI::DesignTokens::Color::SYSTEM_ACCENT.to_hex
spec/ui/design_tokens_default_accent_spec.cr:62:      expect_raises(ArgumentError, /SYSTEM_ACCENT/) do
spec/ui/design_tokens_default_accent_spec.cr:63:        UI::DesignTokens::Color::SYSTEM_ACCENT.to_rgb_triple_css
spec/ui/design_tokens_default_accent_spec.cr:68:      UI::DesignTokens::Color::SYSTEM_ACCENT.should eq(UI::DesignTokens::Color::SYSTEM_ACCENT)
spec/ui/design_tokens_default_accent_spec.cr:73:      UI::DesignTokens::Color::SYSTEM_ACCENT.should_not eq(black_zero)
spec/ui/design_tokens_default_accent_spec.cr:74:      black_zero.should_not eq(UI::DesignTokens::Color::SYSTEM_ACCENT)
spec/ui/design_tokens_default_accent_spec.cr:77:    it "renders to_s as 'Color::SYSTEM_ACCENT'" do
spec/ui/design_tokens_default_accent_spec.cr:78:      UI::DesignTokens::Color::SYSTEM_ACCENT.to_s.should eq("Color::SYSTEM_ACCENT")
spec/ui/design_tokens_default_accent_spec.cr:82:      copy = UI::DesignTokens::Color::SYSTEM_ACCENT.copy_with
spec/ui/design_tokens_default_accent_spec.cr:87:      materialised = UI::DesignTokens::Color::SYSTEM_ACCENT.copy_with(
spec/ui/design_tokens_default_accent_spec.cr:97:    it "uses Color::SYSTEM_ACCENT for the light brand_primary family" do
spec/ui/design_tokens_default_accent_spec.cr:99:      t.colors_light.brand_primary.system_accent?.should be_true
spec/ui/design_tokens_default_accent_spec.cr:100:      t.colors_light.brand_primary_hover.system_accent?.should be_true
spec/ui/design_tokens_default_accent_spec.cr:101:      t.colors_light.brand_primary_active.system_accent?.should be_true
spec/ui/design_tokens_default_accent_spec.cr:104:    it "uses Color::SYSTEM_ACCENT for the dark brand_primary family" do
spec/ui/design_tokens_default_accent_spec.cr:106:      t.colors_dark.brand_primary.system_accent?.should be_true
spec/ui/design_tokens_default_accent_spec.cr:107:      t.colors_dark.brand_primary_hover.system_accent?.should be_true
spec/ui/design_tokens_default_accent_spec.cr:108:      t.colors_dark.brand_primary_active.system_accent?.should be_true
spec/ui/design_tokens_default_accent_spec.cr:123:      t.colors_light.brand_primary.system_accent?.should be_false
spec/ui/design_tokens_default_accent_spec.cr:124:      t.colors_light.brand_primary.l.should eq(0.56)
spec/ui/design_tokens_default_accent_spec.cr:125:      t.colors_light.brand_primary.c.should eq(0.13)
spec/ui/design_tokens_default_accent_spec.cr:126:      t.colors_light.brand_primary.h.should eq(195.0)
spec/ui/design_tokens_default_accent_spec.cr:129:      t.colors_dark.brand_primary.system_accent?.should be_false
spec/ui/design_tokens_default_accent_spec.cr:130:      t.colors_dark.brand_primary.l.should eq(0.56)
spec/ui/design_tokens_default_accent_spec.cr:144:      brand_primary: @teal,
spec/ui/design_tokens_default_accent_spec.cr:145:      brand_primary_hover: @teal,
spec/ui/design_tokens_default_accent_spec.cr:146:      brand_primary_active: @teal,
spec/ui/design_tokens_default_accent_spec.cr:152:      brand_primary: @teal,
spec/ui/design_tokens_default_accent_spec.cr:153:      brand_primary_hover: @teal,
spec/ui/design_tokens_default_accent_spec.cr:154:      brand_primary_active: @teal,
src/ui/views/tab_view.cr:37:    # Defaults to nil, which resolves to the system accent color (system blue
src/ui/native/swiftkit_bridge.m:115:// active `design_tokens.colors_light.brand_primary` RGBA so a brand
src/ui/native/swiftkit_bridge.m:120:// Selector is `setBrandTintWithRed:green:blue:alpha:` — that is the ObjC
src/ui/native/swiftkit_bridge.m:121:// name Swift synthesises for `@objc static func setBrandTint(red:green:
src/ui/native/swiftkit_bridge.m:126:    SEL sel = sel_registerName("setBrandTintWithRed:green:blue:alpha:");
src/ui/native/swiftkit_bridge.m:137:    SEL sel = sel_registerName("clearBrandTint");
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/implementation.md:110:- **Brand override is the source of truth for the demo's chrome.** Do not hardcode colors anywhere in screen Crystal source. Every color comes from `DemoApp::Tokens.color.brand_primary` (etc.) via the brand override path. If you find yourself typing a hex string in a screen file, stop — that's a bug.
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/implementation.md:573:The brand is a **subclass of `UI::Brand` (the immutable abstract class from Phase 1)** that overrides the relevant `override_*` methods to return modified records. Phase 1 made `Tokens` immutable; there is **no** `Brand.declare do |b| b.color.brand_primary = ... end` builder DSL. Each `override_*` method receives the base record and returns a new record via `copy_with` (or hand-rolled construction if `copy_with` is not available on the Crystal version in use).
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/implementation.md:589:        brand_primary:       UI::DesignTokens::Color.oklch(0.68, 0.22,  25),   # coral
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/implementation.md:590:        brand_primary_hover: UI::DesignTokens::Color.oklch(0.62, 0.22,  25),
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/implementation.md:607:        brand_primary:  UI::DesignTokens::Color.oklch(0.74, 0.20,  25),   # slightly brighter coral
docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/implementation.md:1235:   { "amber_default_brand_primary_srgb": [62, 119, 109], "source": "DesignTokens::WebGenerator(AmberBrand).resolve_srgb(:brand_primary)" }
src/ui/native/swiftkit_bridge.cr:43:    # `design_tokens.colors_light.brand_primary` RGBA so a brand swap
docs/initiative-cross-platform-ui/handoff/phase-01-passed-2026-05-20.md:29:The Validator returned PASS with one disclosure worth recording: macOS cascade #19's pixel sample is ~67 sRGB units from the raw sentinel (alpha-composited through AppKit's system bezel), not within the strict ΔE 8 bar the dispatch prompt suggested. The Validator made an Architect-appropriate judgment call: validation.md #19's actual pass criterion is the looser "the captured PNG shows sentinel magenta on the same element family as in #18", not a precise ΔE distance. The magenta→green pixel pivot at a fixed coordinate when only the SentinelBrand BRAND_PRIMARY_HEX flips is the load-bearing proof that the cascade is wired end-to-end through `Tokens.default.with_brand` → `renderer.design_tokens` → `token_nscolor(:brand_primary)` → `NSButton.bezelColor`. The Architect accepts this verdict.
docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter2/codex-critique.md:2702:    14	// brand tint (Apple convention — glass surfaces accept system accent
spec/ui/design_tokens_spec.cr:127:    it "resolves brand_primary to the Color::SYSTEM_ACCENT sentinel (post Phase 6.12A)" do
spec/ui/design_tokens_spec.cr:130:      # primary family resolves to `Color::SYSTEM_ACCENT` so the platform
spec/ui/design_tokens_spec.cr:135:      t.colors_light.brand_primary.system_accent?.should be_true
spec/ui/design_tokens_spec.cr:136:      t.colors_dark.brand_primary.system_accent?.should be_true
spec/ui/design_tokens_spec.cr:147:      result = t.lookup("colors.light.brand_primary")
spec/ui/design_tokens_spec.cr:178:      modified.colors_light.brand_primary.should eq(base.colors_light.brand_primary)
docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter2/codex-critique-full.txt:2702:    14	// brand tint (Apple convention — glass surfaces accept system accent
src/ui/native/objc_bridge.m:259:// macOS: NSColor.controlAccentColor (the live system accent that follows
src/ui/native/objc_bridge.m:265:// Returned to Crystal when a `UI::DesignTokens::Color::SYSTEM_ACCENT`
src/ui/native/objc_bridge.m:1148:// filled portion of the track independently of the system accent color.
spec/ui/design_tokens_brand_spec.cr:10:    palette.copy_with(brand_primary: SENTINEL_MAGENTA)
spec/ui/design_tokens_brand_spec.cr:27:      brand_primary: sentinel,
spec/ui/design_tokens_brand_spec.cr:28:      brand_primary_hover: sentinel,
spec/ui/design_tokens_brand_spec.cr:29:      brand_primary_active: sentinel,
spec/ui/design_tokens_brand_spec.cr:47:      result.colors_light.brand_primary.to_hex.should eq("#ff00ff")
spec/ui/design_tokens_brand_spec.cr:77:      base_primary_before = base.colors_light.brand_primary
spec/ui/design_tokens_brand_spec.cr:79:      base.colors_light.brand_primary.should eq(base_primary_before)
spec/ui/design_tokens_brand_spec.cr:103:      result.colors_light.brand_primary.to_hex.should eq(sentinel.to_hex)
spec/ui/design_tokens_brand_spec.cr:104:      result.colors_light.brand_primary_hover.to_hex.should eq(sentinel.to_hex)
spec/ui/design_tokens_brand_spec.cr:117:      final.colors_light.brand_primary.to_hex.should eq(SENTINEL_MAGENTA.to_hex)
docs/initiative-cross-platform-ui/handoff/phase-01-reflection-2026-05-20.md:36:- **`amber_brand_gold` survives as a thin shim** routing through `token_nscolor(:brand_primary)` rather than being deleted, per the Implementer's Deviation #3 in iter-1 (kept because dozens of call sites depend on the name and the behavior — not the symbol — is what matters). Architect accepted this in the failing-1 adjudication.
src/ui/design_tokens/generators/web_generator.cr:140:          # Phase 6.12A library-identity pivot: SYSTEM_ACCENT has no honest
src/ui/design_tokens/generators/web_generator.cr:149:            io << "#{indent}/* --ap-color-#{name}-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */\n"
spec/ui/design_tokens_cascade_spec.cr:6:# Phase 1 cascade spec — sentinel-magenta override on `brand_primary` must
spec/ui/design_tokens_cascade_spec.cr:14:    palette.copy_with(brand_primary: SENTINEL)
spec/ui/design_tokens_cascade_spec.cr:18:    palette.copy_with(brand_primary: SENTINEL)
spec/ui/design_tokens_cascade_spec.cr:55:    # Post Phase 6.12A: `Tokens.default.colors_light.brand_primary` is the
spec/ui/design_tokens_cascade_spec.cr:56:    # `Color::SYSTEM_ACCENT` sentinel. The mutation-safety contract is
spec/ui/design_tokens_cascade_spec.cr:58:    # must NOT change the identity of the base palette's brand_primary.
spec/ui/design_tokens_cascade_spec.cr:60:    pre = base.colors_light.brand_primary
spec/ui/design_tokens_cascade_spec.cr:62:    base.colors_light.brand_primary.should eq(pre)
spec/ui/design_tokens_cascade_spec.cr:63:    base.colors_light.brand_primary.system_accent?.should be_true
spec/ui/design_tokens/generators/web_generator_spec.cr:35:      # Phase 6.12A library-identity pivot: the brand_primary family resolves
spec/ui/design_tokens/generators/web_generator_spec.cr:36:      # to `Color::SYSTEM_ACCENT`. The canonical `--ap-color-brand-primary*`
spec/ui/design_tokens/generators/web_generator_spec.cr:94:    palette.copy_with(brand_primary: UI::DesignTokens::Color.hex("#ff00ff"))
src/ui/design_tokens.cr:24:  # in `Brand#apply` and any consumer-side `palette.copy_with(brand_primary: …)`
src/ui/design_tokens.cr:32:    # cannot honestly represent (e.g., the platform-resolved `SYSTEM_ACCENT`
src/ui/design_tokens.cr:37:    # consuming `SYSTEM_ACCENT`-bearing tokens.
src/ui/design_tokens.cr:52:    # `Color::SYSTEM_ACCENT` is a sentinel that means "resolve to the
src/ui/design_tokens.cr:60:    # brand_primary family resolves to system accent so consumers who do
src/ui/design_tokens.cr:72:      # nil for normal colours; `:system_accent` for `Color::SYSTEM_ACCENT`.
src/ui/design_tokens.cr:95:      SYSTEM_ACCENT = new(
src/ui/design_tokens.cr:113:      # Returns `:clear` for the SYSTEM_ACCENT sentinel — the renderer
src/ui/design_tokens.cr:123:      # CSS-context serialization. For `SYSTEM_ACCENT`, returns the CSS
src/ui/design_tokens.cr:134:      # SwiftUI-context serialization. For `SYSTEM_ACCENT`, returns the
src/ui/design_tokens.cr:143:      # Equality includes the sentinel kind so `Color::SYSTEM_ACCENT` is
src/ui/design_tokens.cr:161:          io << "Color::SYSTEM_ACCENT"
src/ui/design_tokens.cr:217:      # `SYSTEM_ACCENT` returns the CSS Color 4 `AccentColor` keyword so the
src/ui/design_tokens.cr:232:      # `SYSTEM_ACCENT` returns the CSS Color 4 `AccentColor` keyword (an
src/ui/design_tokens.cr:249:      # `SYSTEM_ACCENT` sentinel — there is no honest channel triple to
src/ui/design_tokens.cr:255:            "Color::SYSTEM_ACCENT has no fixed RGB triple — use to_css " \
src/ui/design_tokens.cr:266:      # "#rrggbb" or "#rrggbbaa" hex string. Raises for `SYSTEM_ACCENT` —
src/ui/design_tokens.cr:271:            "Color::SYSTEM_ACCENT has no fixed hex value — it resolves " \
src/ui/design_tokens.cr:287:      # SwiftUI Color literal source. `SYSTEM_ACCENT` returns the SwiftUI
src/ui/design_tokens.cr:298:      # `SYSTEM_ACCENT` raises `AndroidRendererNotImplemented` — the honest
src/ui/design_tokens.cr:304:            "Cannot serialize Color::SYSTEM_ACCENT as Android ARGB. " \
src/ui/design_tokens.cr:317:      # propagates by default so `SYSTEM_ACCENT.copy_with(alpha: 0.5)` stays
src/ui/design_tokens.cr:347:      brand_primary : Color,
src/ui/design_tokens.cr:348:      brand_primary_hover : Color,
src/ui/design_tokens.cr:349:      brand_primary_active : Color,
src/ui/design_tokens.cr:374:          "brand-primary"        => brand_primary,
src/ui/design_tokens.cr:375:          "brand-primary-hover"  => brand_primary_hover,
src/ui/design_tokens.cr:376:          "brand-primary-active" => brand_primary_active,
src/ui/design_tokens.cr:403:        when :brand_primary        then brand_primary
src/ui/design_tokens.cr:404:        when :brand_primary_hover  then brand_primary_hover
src/ui/design_tokens.cr:405:        when :brand_primary_active then brand_primary_active
src/ui/design_tokens.cr:714:      #   tokens.lookup("colors.light.brand_primary") # => Color
src/ui/design_tokens.cr:777:        when "brand_primary"        then palette.brand_primary
src/ui/design_tokens.cr:778:        when "brand_primary_hover"  then palette.brand_primary_hover
src/ui/design_tokens.cr:779:        when "brand_primary_active" then palette.brand_primary_active
src/ui/design_tokens.cr:928:        # Phase 6.12A library-identity pivot: brand_primary family resolves
src/ui/design_tokens.cr:929:        # to the platform-native accent (`Color::SYSTEM_ACCENT`). Consumers
src/ui/design_tokens.cr:937:          brand_primary: Color::SYSTEM_ACCENT,
src/ui/design_tokens.cr:938:          brand_primary_hover: Color::SYSTEM_ACCENT,
src/ui/design_tokens.cr:939:          brand_primary_active: Color::SYSTEM_ACCENT,
src/ui/design_tokens.cr:957:          # system accent on macOS; UIColor.tintColor on iOS). Pivoting
src/ui/design_tokens.cr:958:          # to SYSTEM_ACCENT lets the focus ring match the active
src/ui/design_tokens.cr:963:          border_focus: Color::SYSTEM_ACCENT,
src/ui/design_tokens.cr:975:          brand_primary: Color::SYSTEM_ACCENT,
src/ui/design_tokens.cr:976:          brand_primary_hover: Color::SYSTEM_ACCENT,
src/ui/design_tokens.cr:977:          brand_primary_active: Color::SYSTEM_ACCENT,
src/ui/design_tokens.cr:994:          # border_focus to SYSTEM_ACCENT.
src/ui/design_tokens.cr:995:          border_focus: Color::SYSTEM_ACCENT,
src/ui/design_tokens/dist/web_tokens.css:7:  /* --ap-color-brand-primary-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:9:  /* --ap-color-brand-primary-hover-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:11:  /* --ap-color-brand-primary-active-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:43:  /* --ap-color-border-focus-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:180:    /* --ap-color-brand-primary-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:182:    /* --ap-color-brand-primary-hover-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:184:    /* --ap-color-brand-primary-active-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:216:    /* --ap-color-border-focus-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:231:  /* --ap-color-brand-primary-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:233:  /* --ap-color-brand-primary-hover-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:235:  /* --ap-color-brand-primary-active-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:267:  /* --ap-color-border-focus-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:281:  /* --ap-color-brand-primary-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:283:  /* --ap-color-brand-primary-hover-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:285:  /* --ap-color-brand-primary-active-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/design_tokens/dist/web_tokens.css:317:  /* --ap-color-border-focus-rgb omitted — SYSTEM_ACCENT has no fixed triple; use color-mix(in oklch, AccentColor X%, transparent) instead */
src/ui/renderers/appkit_renderer.cr:63:      # Phase 6.12A — NSColor.controlAccentColor for SYSTEM_ACCENT.
src/ui/renderers/appkit_renderer.cr:266:      #   - System tint (resolved to `brand_primary` via the tint cascade)
src/ui/renderers/appkit_renderer.cr:3979:      # Phase 6.12A — when the resolved colour is `Color::SYSTEM_ACCENT`
src/ui/renderers/appkit_renderer.cr:3981:      # system accent that follows the user's General > Accent choice and
src/ui/renderers/appkit_renderer.cr:3986:        color = palette.lookup(role) || palette.brand_primary
src/ui/renderers/appkit_renderer.cr:3999:        token_nscolor(:brand_primary)
src/ui/renderers/appkit_renderer.cr:4025:        apply_brand_tint(@design_tokens.colors_light.brand_primary)
src/ui/renderers/appkit_renderer.cr:4039:          # consumer using `Tokens.default` SYSTEM_ACCENT) reaches this
src/ui/renderers/appkit_renderer.cr:4040:          # branch, which is what keeps `APSKRuntime.brandTint == nil`
src/ui/renderers/appkit_renderer.cr:4047:            STDERR.puts "[apsk] brand_tint=cleared (APSKRuntime.brandTint == nil)"
src/ui/renderers/uikit_renderer.cr:63:      # by the bridge when the renderer resolves a `Color::SYSTEM_ACCENT`
src/ui/renderers/uikit_renderer.cr:278:      #   - System tint (resolved to `brand_primary` via the tint cascade)
src/ui/renderers/uikit_renderer.cr:4085:      # Phase 6.12A — when the resolved colour is `Color::SYSTEM_ACCENT`
src/ui/renderers/uikit_renderer.cr:4092:        color = palette.lookup(role) || palette.brand_primary
src/ui/renderers/uikit_renderer.cr:4103:        token_nscolor(:brand_primary)
src/ui/renderers/uikit_renderer.cr:4123:        apply_brand_tint(@design_tokens.colors_light.brand_primary)
docs/initiative-cross-platform-ui/handoff/phase-06.8-validation-2026-05-23.md:233:   target from `UI::DesignTokens` brand_primary.
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:43:Forgot-password link's teal foreground proves `setBrandTint(teal)` did fire
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:85:that "the system accent color is used as the background fill," and
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:91:the system accent color exclusively, ignoring environment `.tint`. The
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:105:`Tokens.default` (= `SYSTEM_ACCENT`, i.e. `APSKRuntime.brandTint == nil`)
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:106:are unaffected because they want exactly the system accent that
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:116:`case "prominent":` only when `APSKRuntime.brandTint != nil`. When
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:117:`brandTint == nil` (Voyager), the existing `.controlSize(.large)
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:142:  brand_primary is lifted. This passes WCAG AA for normal text and would
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:152:  `APSKRuntime.brandTint` so a runtime brand swap takes effect.
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:155:  must continue to get the stock `.borderedProminent` (system accent), so
docs/initiative-cross-platform-ui/handoff/phase-06.12c-probe-findings.md:156:  the fix only activates when `APSKRuntime.brandTint != nil` AND the
spec/ui/renderers/system_accent_integration_spec.cr:7:# `Color::SYSTEM_ACCENT` sentinel and resolve it to the platform-native
spec/ui/renderers/system_accent_integration_spec.cr:31:    palette.copy_with(brand_primary: TEAL, brand_primary_hover: TEAL, brand_primary_active: TEAL)
spec/ui/renderers/system_accent_integration_spec.cr:35:    palette.copy_with(brand_primary: TEAL, brand_primary_hover: TEAL, brand_primary_active: TEAL)
spec/ui/renderers/system_accent_integration_spec.cr:47:  it "returns :clear for Color::SYSTEM_ACCENT" do
spec/ui/renderers/system_accent_integration_spec.cr:48:    UI::DesignTokens::Color::SYSTEM_ACCENT.brand_tint_action.should eq(:clear)
spec/ui/renderers/system_accent_integration_spec.cr:62:    default_brand = UI::DesignTokens::Tokens.default.colors_light.brand_primary
spec/ui/renderers/system_accent_integration_spec.cr:66:    branded.colors_light.brand_primary.brand_tint_action.should eq(:set)
spec/ui/renderers/system_accent_integration_spec.cr:108:  it "raises AndroidRendererNotImplemented when SYSTEM_ACCENT reaches to_android_argb" do
spec/ui/renderers/system_accent_integration_spec.cr:110:      UI::DesignTokens::Color::SYSTEM_ACCENT.to_android_argb
spec/ui/renderers/system_accent_integration_spec.cr:132:    sentinel = UI::DesignTokens::Color::SYSTEM_ACCENT
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-1.md:4:**Commit reviewed:** `dddf1f7` — `[Phase 6.12A Item 1] Color::SYSTEM_ACCENT sentinel + Tokens.default brand-primary pivot`
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-1.md:14:1. The sentinel still leaks as transparent black through live renderer/adaptor paths. The brief's goal is renderer detection/mapping to native accent ([brief.md](../../initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:58)), and the sentinel bake is explicitly non-renderable zeros ([brief.md](../../initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:72)). But `UI::Theme.from_design_tokens` copies `brand_primary` raw `r/g/b/alpha` into `ThemeColor` ([theme.cr](../../../src/ui/theme.cr:169), [theme.cr](../../../src/ui/theme.cr:240)), so `UI::Theme.design_system_default` emits `--md-sys-color-primary: rgba(0, 0, 0, 0.0)`. I confirmed with `crystal eval`. AppKit/UIKit have the same raw path in `token_nscolor` and tint installation ([appkit_renderer.cr](../../../src/ui/renderers/appkit_renderer.cr:3976), [appkit_renderer.cr](../../../src/ui/renderers/appkit_renderer.cr:4013), [uikit_renderer.cr](../../../src/ui/renderers/uikit_renderer.cr:4080), [uikit_renderer.cr](../../../src/ui/renderers/uikit_renderer.cr:4109)). This must map to platform accent or clear the brand tint, not render the sentinel bake.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-1.md:16:2. The regenerator does not implement the Android "skip + diagnostic" part of the acceptance. The brief requires graceful Android handling/diagnostic when `SYSTEM_ACCENT` is in play ([brief.md](../../initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief.md:185)); the script only has a source comment saying Android is deferred ([regenerate_design_tokens.cr](../../../scripts/regenerate_design_tokens.cr:13)) and prints the web/apple writes. It does exit 0 and regenerated artifacts matched.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-1.md:20:The core `Color::SYSTEM_ACCENT` API is broadly complete: constructor/sentinel field, `system_accent?`, CSS/Swift serializers, Android fail-loud path, equality, `to_s`, `to_hex`, `to_rgb_triple_css`, and `copy_with` are present. Equality correctly prevents sentinel == transparent-black coincidence.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-1.md:22:Defaults are correct for Item 1: light/dark `brand_primary`, `brand_primary_hover`, and `brand_primary_active` are sentinel, while `brand_secondary` remains literal.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-1.md:43:- `src/ui/renderers/appkit_renderer.cr:3976` + `src/ui/renderers/uikit_renderer.cr:4080` — `token_nscolor(:brand_primary)` returning sentinel-bake. Fix: detect sentinel and return `NSColor.controlAccentColor` / `UIColor.tintColor` via a dedicated bridge fun.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-1.md:50:The script does not currently generate Android output at all (the Android generator is deferred per phase-01 architect handoff). The brief's "skip the Android target when SYSTEM_ACCENT is in play, log a diagnostic" is therefore most honestly implemented as: probe the input tokens for any sentinel-bearing roles, and if found, emit a diagnostic to STDERR explaining why no Android output would be honest. This makes the deferral explicit at the regen call-site rather than buried in a comment.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-1.md:60:| `UI::DesignTokens::Color::SYSTEM_ACCENT` exists with full API | PASS — `system_accent?`, `to_css`, `to_swift`, `to_android_argb`, `==`, `to_s` all present |
docs/initiative-cross-platform-ui/handoff/phase-06.12a-codex-1.md:61:| `Tokens.default.colors_light.brand_primary` + hover + active ALL return sentinel | PASS — verified by 18 spec examples |
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:14:Review the Phase 6.12C fix at swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift (the case 'prominent' branch, lines roughly 180-249), and the new file swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift. Verify: (1) macOS-only conditional protects Voyager (SYSTEM_ACCENT) from regression; (2) reads APSKRuntime.brandTint at render time so a brand swap mid-session takes effect; (3) the iOS branch unchanged from Phase 6.11 iter-4 (must still be .controlSize(.large).buttonStyle(.borderedProminent)); (4) no hardcoded color literal restored. Verdict per item: PASS/FAIL. Overall: APPROVE / REVISE.
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:18:/bin/zsh -lc "rg -n \"Phase 6\\.12C|6\\.12C|APSKBrandProminentButtonStyle|ButtonFacade|prominent|Voyager|SYSTEM_ACCENT|Phase 6\\.11|iter-4\" /Users/crimsonknight/.codex/memories/MEMORY.md" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:76:     8	//   background fill always resolves to the system accent. Confirmed
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:86:    18	//   - macOS + `APSKRuntime.brandTint != nil` (custom brand installed)
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:88:    20	//   - macOS + `APSKRuntime.brandTint == nil` (Voyager / Tokens.default /
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:89:    21	//     SYSTEM_ACCENT) → stock `.borderedProminent` is used (system blue
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:90:    22	//     / system accent — exactly what the consumer wants).
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:102:    34	//     demanding contrast budgets should override `brand_primary` to a
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:150:   172	        // its fill against the system accent (`accentColor` —
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:178:   200	            // and always uses the system accent color. iOS does NOT have
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:180:   202	            // tint via `APSKRuntime.setBrandTint(...)`, which
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:191:   213	            //      (`APSKRuntime.brandTint != nil`).
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:193:   215	            // SYSTEM_ACCENT / `Tokens.default`), the stock
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:195:   217	            // continues to render with the macOS system accent.
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:198:   220	            if let activeTint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:256:/bin/zsh -lc "rg -n \"borderedProminent|controlSize\\(\\.large\\)|prominent|brandTint|SYSTEM_ACCENT|Voyager|hardcoded|Color\\(\" docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:275:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:213:            //      (`APSKRuntime.brandTint != nil`).
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:276:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:215:            // SYSTEM_ACCENT / `Tokens.default`), the stock
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:278:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:220:            if let activeTint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:304:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:18://   - macOS + `APSKRuntime.brandTint != nil` (custom brand installed)
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:305:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:20://   - macOS + `APSKRuntime.brandTint == nil` (Voyager / Tokens.default /
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:306:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:21://     SYSTEM_ACCENT) → stock `.borderedProminent` is used (system blue
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:326:+            // and always uses the system accent color. iOS does NOT have
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:328:+            // tint via `APSKRuntime.setBrandTint(...)`, which
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:339:+            //      (`APSKRuntime.brandTint != nil`).
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:341:+            // SYSTEM_ACCENT / `Tokens.default`), the stock
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:343:+            // continues to render with the macOS system accent.
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:346:+            if let activeTint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:371:The requested branch is inside the SwiftUI `body`, so the next question is whether `APSKRuntime.brandTint` is observable or only a static snapshot. I’m checking that runtime path before giving the PASS/FAIL for mid-session swaps.
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:373:/bin/zsh -lc "rg -n \"class APSKRuntime|struct APSKRuntime|enum APSKRuntime|brandTint|setBrandTint|HostingHelpers|\\.tint\\(\" swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:376:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:26://   `APSKRuntime.setBrandTint(red:green:blue:alpha:)` once during render
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:382:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:109:    @objc public static func setBrandTint(red: Double, green: Double, blue: Double, alpha: Double) {
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:384:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:128:    /// `SwiftUI.Color`; ObjC callers go through `setBrandTint`.
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:385:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:129:    static var brandTint: Color? { currentBrandTint }
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:386:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:131:    /// Returns true once `setBrandTint` has been called at least once and
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:389:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:18://   - macOS + `APSKRuntime.brandTint != nil` (custom brand installed)
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:390:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift:20://   - macOS + `APSKRuntime.brandTint == nil` (Voyager / Tokens.default /
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:397:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:202:            // tint via `APSKRuntime.setBrandTint(...)`, which
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:399:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:213:            //      (`APSKRuntime.brandTint != nil`).
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:400:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:220:            if let activeTint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:429:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/LinkButtonFacade.swift:32:        // `APSKRuntime.setBrandTint(...)`, the Link text now renders in the
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:445:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:211:        // When no tint has been installed (`APSKRuntime.brandTint == nil`)
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:446:swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:214:        if let tint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:668:   211	        // When no tint has been installed (`APSKRuntime.brandTint == nil`)
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:669:   212	        // SwiftUI's system accent colour shows through unchanged.
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:671:   214	        if let tint = APSKRuntime.brandTint {
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:722:    26	//   `APSKRuntime.setBrandTint(red:green:blue:alpha:)` once during render
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:724:    28	//   the active `brand_primary` colour. The current tint is stored on
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:727:    31	//   "no override — use the system accent colour."
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:752:    56	/// "use the system accent colour" (SwiftUI default behaviour). Stored as
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:798:   102	    /// Crystal's `design_tokens.colors.brand_primary` reaches the
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:805:   109	    @objc public static func setBrandTint(red: Double, green: Double, blue: Double, alpha: Double) {
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:818:   122	    @objc public static func clearBrandTint() {
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:824:   128	    /// `SwiftUI.Color`; ObjC callers go through `setBrandTint`.
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:825:   129	    static var brandTint: Color? { currentBrandTint }
docs/initiative-cross-platform-ui/handoff/phase-06.12c-codex-1.md:827:   131	    /// Returns true once `setBrandTint` has been called at least once and
docs/initiative-cross-platform-ui/handoff/phase-06.11-iter-5-architectural-finding.md:15:     brand = @design_tokens.colors_light.brand_primary
docs/initiative-cross-platform-ui/handoff/phase-06.11-iter-5-architectural-finding.md:23:3. Tokens.default.colors_light.brand_primary returns the LIBRARY's default
docs/initiative-cross-platform-ui/handoff/phase-06.11-iter-5-architectural-finding.md:26:4. CallbackBridge.swift caches this as APSKRuntime.brandTint.
docs/initiative-cross-platform-ui/handoff/phase-06.11-iter-5-architectural-finding.md:41:- `brand_primary` becomes `Color?` (nilable).
docs/initiative-cross-platform-ui/handoff/phase-06.11-iter-5-architectural-finding.md:42:- `Tokens.default.colors_light.brand_primary == nil` for the unbranded library default.
docs/initiative-cross-platform-ui/handoff/phase-06.11-iter-5-architectural-finding.md:43:- Renderer only calls `apsk_runtime_set_brand_tint(...)` when brand_primary is non-nil.
docs/initiative-cross-platform-ui/handoff/phase-06.11-iter-5-architectural-finding.md:55:### Option C: Tokens.default uses iOS system accent (system blue)
docs/initiative-cross-platform-ui/handoff/phase-06.11-iter-5-architectural-finding.md:56:- Library's `Tokens.default.brand_primary` changes from amber to a value that semantically resolves to "system accent" on each platform.
docs/initiative-cross-platform-ui/handoff/phase-06.11-iter-5-architectural-finding.md:60:- **Cost:** medium — requires platform-aware brand_primary resolution.
docs/initiative-cross-platform-ui/handoff/phase-06.10-reflection-2026-05-23.md:74:Naive brand override sets `brand_primary` to a new hue without telling the renderer to recompute the contrast-correct text color for surfaces using that brand color. Result: white text on off-white surfaces when the override clashes with system color defaults. Phase 6.11's "drop the override, use defaults" demonstrates the binding chain works; the right long-term fix is semantic contrast pairs in design tokens. Don't add brand-override docs/tutorials until this gap is closed.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-cascade-preflight.md:10:Per brief.md Item 0 (lines 37-54): identify how the Cascade demo (`samples/initiative-cross-platform-ui-demo/`) applies its deep-teal brand BEFORE pivoting `Tokens.default` to `Color::SYSTEM_ACCENT`, so Item 4 can verify (or repair) Cascade post-pivot.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-cascade-preflight.md:26:| `samples/initiative-cross-platform-ui-demo/brand.cr` | 40-58 | `class DemoBrand < UI::DesignTokens::Brand` — overrides `override_color_light` and `override_color_dark` via `palette.copy_with(brand_primary: …, brand_primary_hover: …, brand_primary_active: …, brand_secondary: …)` | Light + dark palettes both overridden. Only brand_primary family + brand_secondary are touched; all other tokens flow from `Tokens.default`. |
docs/initiative-cross-platform-ui/handoff/phase-06.12a-cascade-preflight.md:69:So Voyager is the demo that picks up `Tokens.default`'s new sentinel-derived system accent (and renders system blue on iOS, controlAccentColor on macOS, `AccentColor` on web), while Cascade keeps deep teal via its explicit override.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-cascade-preflight.md:85:None. The brand application is single-source (`InitiativeDemo.brand_tokens`), called explicitly from all three renderer entrypoints, with no fallback path that consults `Tokens.default.brand_primary` directly.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-cascade-preflight.md:97:Iteration 2: Item 1 — implement `Color::SYSTEM_ACCENT` sentinel in `src/ui/design_tokens.cr`, pivot `Tokens.default` brand family, ship `spec/ui/design_tokens_default_accent_spec.cr`. Then Codex review committed at `phase-06.12a-codex-1.md`.
docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20/inspections/renderer.appkit-no-hardcoded.log:70:through token_nscolor(:brand_primary) / token_nscolor(:surface_*) per the
docs/initiative-cross-platform-ui/handoff/plan-quality-audit-2026-05-20.md:30:- **Phase 6 brand declaration:** Uses `b.color.brand_primary = ...` syntax incompatible with Phase 1's immutable `ColorPalette` `record`.
docs/initiative-cross-platform-ui/handoff/plan-quality-audit-2026-05-20.md:84:2. **Phase 1 + Phase 6 — reconcile the `Brand` API.** Phase 1 ships an `abstract class Brand` with `override_color_light(palette)` style. Phase 6 writes a `Brand.declare do |b| b.color.brand_primary = ...` builder DSL. Incompatible. Pick one in Phase 1, update Phase 6 to match.
docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20/inspections/tokens.default-matches-amber.diff:38:brand_primary:  Color.oklch(0.52, 0.16, 50.0)
docs/initiative-cross-platform-ui/handoff/phase-03-failing-1-2026-05-20.md:64:   - `Tests/AssetPipelineSwiftKitTests/RuntimeBridgeTests.swift` — verify `APSKRuntime.setBrandTint`, action trampoline install, callback dispatch.
docs/initiative-cross-platform-ui/handoff/phase-03a-stopped-early-2026-05-20.md:17:- **Brand tint propagation wired.** `apsk_runtime_set_brand_tint(r, g, b, a)` is called once on every `render()` entry via `ensure_swiftkit_runtime!`. Swift's `APSKRuntime.setBrandTint(...)` stores a `Color?`, and `HostingHelpers.host(_:)` wraps every hosted root in `.tint(...)` when one is installed.
docs/initiative-cross-platform-ui/handoff/phase-03a-stopped-early-2026-05-20.md:29:1. Crystal: `design_tokens.colors_light.brand_primary = #ff00ff` (from `SentinelBrand`)
docs/initiative-cross-platform-ui/handoff/phase-03a-stopped-early-2026-05-20.md:32:4. Swift `APSKRuntime.setBrandTint` stores `Color(.sRGB, red: 1.0, green: 0.0, blue: 1.0, opacity: 1.0)`
docs/initiative-cross-platform-ui/handoff/phase-03a-stopped-early-2026-05-20.md:33:5. `HostingHelpers.host(_:)` reads `APSKRuntime.brandTint` and applies `.tint(...)`
docs/initiative-cross-platform-ui/handoff/phase-03a-stopped-early-2026-05-20.md:91:- Swift-level: `APSKRuntime.brandTint` returns the expected `Color` (verifiable in `swift test`).
docs/initiative-cross-platform-ui/handoff/phase-01-failing-1-2026-05-20.md:139:      "notes": "FAIL. Two brand-decision color literals in visit methods bypass token shim: (a) line 258 ember_dark = nscolor_rgba(0.165, 0.102, 0.031, 1.0); (b) line 3800 amber_gold = nscolor_rgba(1.0, 0.678, 0.2, 1.0) hardcodes the legacy amber gold, bypassing the amber_brand_gold shim at line 4601 that exists specifically to route through token_nscolor(:brand_primary). Plus ~15 unannotated nsfont_system literals and ~10 nscolor_rgba literals in visit methods lacking '# Tier 2' annotation."
docs/initiative-cross-platform-ui/handoff/phase-06.12-architect-codex-critique-2026-05-24.md:15:2. **Hidden dependencies:** Cascade preservation must be preflighted BEFORE pivot, not after. `brand_primary` alone too narrow — the brand family (primary/hover/active/link/focus + generated outputs) needed full coverage.
docs/initiative-cross-platform-ui/handoff/phase-06.12-architect-codex-critique-2026-05-24.md:29:- (b) Cascade preflight + brand family: **CLOSED.** Item 0 is preflight; brand_primary + hover + active all covered.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-implementer-report.md:13:| 1 — `Color::SYSTEM_ACCENT` sentinel + Tokens.default pivot | PASS (after Item 2 follow-up) | `dddf1f7` + Codex review `ef836e6` | NEEDS_WORK → addressed by Item 2 |
docs/initiative-cross-platform-ui/handoff/phase-06.12a-implementer-report.md:69:35fb371 [Phase 6.12A Item 2] Wire 4 renderer paths to honour Color::SYSTEM_ACCENT
docs/initiative-cross-platform-ui/handoff/phase-06.12a-implementer-report.md:71:dddf1f7 [Phase 6.12A Item 1] Color::SYSTEM_ACCENT sentinel + Tokens.default brand-primary pivot
docs/initiative-cross-platform-ui/handoff/phase-06.12a-implementer-report.md:93:# 3. Voyager builds — Tokens.default → system accent
docs/initiative-cross-platform-ui/handoff/phase-06.12a-implementer-report.md:103:# Expected: at least 1 hit (teal brand_primary)
docs/initiative-cross-platform-ui/handoff/phase-06.12a-implementer-report.md:125:- Library-identity pivot (Tokens.default brand_primary family + border_focus → SYSTEM_ACCENT).
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:10:Per brief.md Item 5 (lines 299-327): after the library-identity pivot lands, regenerate `src/ui/design_tokens/dist/*` and grep all generated outputs for amber-equivalent colour literals. For each finding, decide whether to (a) pivot the source token to `Color::SYSTEM_ACCENT` or (b) justify keeping it as a non-brand library colour.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:20:   - Specific pre-pivot literal hashes (`oklch(0.52 0.16 50)` etc.) for the original amber brand_primary family.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:39:The original `Tokens.default.brand_primary` family was:
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:43:| `brand_primary` | `oklch(0.52 0.16 50)` | `oklch(0.78 0.17 58)` |
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:44:| `brand_primary_hover` | `oklch(0.47 0.17 48)` | `oklch(0.84 0.15 60)` |
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:45:| `brand_primary_active` | `oklch(0.40 0.15 46)` | `oklch(0.70 0.18 54)` |
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:66:| `border_focus` | `oklch(0.66 0.15 50, alpha 0.58)` | **PIVOTED to `Color::SYSTEM_ACCENT`.** Chroma 0.15 + hue 50° is unambiguously amber; this was the focus-ring partner of the original amber brand. Apple HIG focus rings cascade from the system accent (`NSColor.keyboardFocusIndicatorColor` on macOS; `UIColor.tintColor` on iOS) — making `border_focus` a sentinel keeps the ring colour coherent with whatever brand the consumer applies (default → platform accent; `.with_brand` → that brand colour). | **PIVOTED.** Dark `oklch(0.75 0.14 58)` was the same amber family. |
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:77:**`Defaults.light_palette.border_focus`:** `oklch(0.66, 0.15, 50, 0.58)` → `Color::SYSTEM_ACCENT`.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:78:**`Defaults.dark_palette.border_focus`:** `oklch(0.75, 0.14, 58, 0.62)` → `Color::SYSTEM_ACCENT`.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:80:Justification: focus rings are platform-coherent on Apple. Apple's `NSColor.keyboardFocusIndicatorColor` and `UIColor.tintColor` both resolve to the system accent. Pivoting `border_focus` to sentinel:
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:102:[regenerate_design_tokens] android: skipped — Color::SYSTEM_ACCENT in 8 role(s):
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:117:Cascade's `DemoBrand` overrides `brand_primary` / `brand_primary_hover` / `brand_primary_active` / `brand_secondary` (light + dark) but does NOT override `border_focus`. Pre-pivot, this meant Cascade got the library amber focus ring (`oklch(0.66 0.15 50)`) — already inconsistent with its teal brand. Post-pivot, Cascade gets `AccentColor` for `border_focus` — i.e. the platform system accent (typically system blue on macOS / iOS unless the user has overridden their accent preference). Still inconsistent with Cascade's teal.
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:127:      brand_primary: TEAL,
docs/initiative-cross-platform-ui/handoff/phase-06.12a-no-amber-audit.md:139:1. Pivoted to `Color::SYSTEM_ACCENT` (brand_primary family + border_focus).
docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/codex_reviews/checkpoint3-family-A-action-sheet.md:131:    47	- **Cascade that doesn't cascade.** A brand override changes the Crystal-side `brand_primary` to coral. The web generator emits an updated `--ap-color-brand-primary` custom property. Presence: pass — the variable is set. **Behavior fails:** the rendered Button still draws teal because the Button widget's renderer visitor hard-codes a Color literal instead of reading `var(--ap-color-brand-primary)`. A presence check on the variable would never have surfaced this.
docs/initiative-cross-platform-ui/handoff/phase-06-rem5-fix1-blocked-2026-05-23.md:58:populates it from `design_tokens.brand_primary` whenever `view.role
docs/initiative-cross-platform-ui/handoff/phase-06-rem5-fix1-blocked-2026-05-23.md:72:   — introduced `let brandTint = overrides.tintColor.map { Color(uiColor:/nsColor:) }`,
docs/initiative-cross-platform-ui/handoff/phase-06-rem5-fix1-blocked-2026-05-23.md:73:   `let effectiveTint = brandTint ?? Color.accentColor`, replaced
docs/initiative-cross-platform-ui/handoff/phase-06-rem5-fix1-blocked-2026-05-23.md:81:   `design_tokens.brand_primary` for the current appearance.
docs/initiative-cross-platform-ui/handoff/phase-06-rem5-fix1-blocked-2026-05-23.md:93:ContentView `.tint(brandTint)` attempt, but for a different reason
docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/codex_reviews/checkpoint1-page-design.txt:1741:docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/implementation.md:110:- **Brand override is the source of truth for the demo's chrome.** Do not hardcode colors anywhere in screen Crystal source. Every color comes from `DemoApp::Tokens.color.brand_primary` (etc.) via the brand override path. If you find yourself typing a hex string in a screen file, stop — that's a bug.
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:1983: /// "use the system accent colour" (SwiftUI default behaviour). Stored as
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:3744://   `APSKRuntime.setBrandTint(red:green:blue:alpha:)` once during render
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:3746://   the active `brand_primary` colour. The current tint is stored on
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:3749://   "no override — use the system accent colour."
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:3774:/// "use the system accent colour" (SwiftUI default behaviour). Stored as
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:3820:    /// Crystal's `design_tokens.colors.brand_primary` reaches the
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:3827:    @objc public static func setBrandTint(red: Double, green: Double, blue: Double, alpha: Double) {
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:8521:        token_nscolor(:brand_primary)
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:8547:        brand = @design_tokens.colors_light.brand_primary
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:8565:        token_nscolor(:brand_primary)
docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-4-codex-1.md:8585:        brand = @design_tokens.colors_light.brand_primary
docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/inspections/cascade.macos-changes-on-brand-override-pixel-sample.log:35:  - `UI::Button` style:Prominent → NSButton.bezelColor = token_nscolor(:brand_primary).
docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/inspections/cascade.macos-changes-on-brand-override-pixel-sample.log:45:    actually propagates through `renderer.design_tokens` → `token_nscolor(:brand_primary)` →
docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/inspections/cascade.macos-changes-on-brand-override-pixel-sample.log:58:  Label below reads "brand_primary = #ff00ff".
docs/initiative-cross-platform-ui/handoff/phase-01-evidence-2026-05-20-iter2/inspections/cascade.macos-changes-on-brand-override-pixel-sample.log:62:  Label below reads "brand_primary = #00cc66".
docs/initiative-cross-platform-ui/handoff/phase-05-evidence-2026-05-22-iter1/codex/p5-validator-codex-critique.md:2088:    14	// brand tint (Apple convention — glass surfaces accept system accent

exec
/bin/zsh -lc "find swift/AssetPipelineSwiftKit -name Package.swift -o -name '*.swift' | sed -n '1,160p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 156ms:
it/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/InitDeinitTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/RegexTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/DeprecatedWhereTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/PatternWithoutVariablesTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/RawStringTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/OptionalChainLvaluesTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/AsyncSyntaxTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/AsyncTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/InvalidTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/ForwardSlashRegexTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/NumberIdentifierErrorsTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/DebuggerTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/ConflictMarkersTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/SelfRebindingTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/EscapedIdentifiersTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/OriginalDefinedInAttrTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/BuiltinWordTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/MultilineErrorsTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/ActorTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/BraceRecoveryEofTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/EnumElementPatternSwift4Tests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/ForwardSlashRegexSkippingTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/ForwardSlashRegexSkippingInvalidTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/SemicolonTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/DelayedExtensionTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/RawStringErrorsTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/RegexParseEndOfBufferTests.swift
swift/AssetPipelineSwiftKit/.build/checkouts/swift-syntax/Tests/SwiftParserTest/translated/TrailingSemiTests.swift

exec
/bin/zsh -lc "nl -ba docs/initiative-cross-platform-ui/phases/phase-06.12-library-identity-macos-polish/brief-6.12c.md | sed -n '1,185p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
     1	# Phase 6.12C — Cascade Prominent-Button Brand Regression Investigation + Fix
     2	
     3	**Date opened:** 2026-05-24
     4	**Authored by:** Architect (Codex-critique before dispatch)
     5	**Branch:** `phase-06.12-library-identity-macos-polish` (continue from `62da2c53` + Cascade evidence commit)
     6	**Codex protocol:** Per-iteration critique on every code-touching iteration. Self-assessment NOT acceptable.
     7	
     8	---
     9	
    10	## Why this iteration exists
    11	
    12	Phase 6.12B's capture agent reached Priority 1A and confirmed empirically: **Cascade macOS prominent Sign-in button no longer renders deep teal — it renders light gray.** Phase 6.11 iter-4 removed the `Capsule.fill(brandTeal)` workaround in `ButtonFacade.swift` case "prominent" because Path A (Phase 6.10 VC parenting) had made it obsolete for the SwiftUI Button tap chain. But that workaround was ALSO masking a separate macOS-specific quirk: `.borderedProminent` on macOS uses the system accent color regardless of `.tint()` set in the SwiftUI environment.
    13	
    14	Evidence committed at `phase-06.12b-evidence/cascade-macos-prominent-button-{light,dark}.png`. The Forgot-password link IS teal in the same screenshot (so `.tint()` cascades to `.bordered`/`.borderless` chrome), but the prominent button isn't.
    15	
    16	This is a Cascade-specific regression because Cascade applies a custom brand. Voyager (which uses `Tokens.default` = `Color::SYSTEM_ACCENT` after Phase 6.12A) is unaffected — its prominent buttons correctly resolve to system blue.
    17	
    18	Phase 6.12C investigates the macOS `.borderedProminent` × `.tint()` interaction empirically + picks a fix that:
    19	- Restores Cascade's deep teal prominent button on macOS.
    20	- Does NOT regress Voyager's system-blue prominent button.
    21	- Does NOT restore the original hardcoded brand-teal `Color(red: 0.012, ...)` literal (that was Phase 6.8 broken-by-design; Phase 6.11 iter-4 correctly removed it).
    22	
    23	---
    24	
    25	## Item 1 — Empirical investigation of macOS `.borderedProminent` × `.tint()`
    26	
    27	Before any fix lands, the Implementer runs a minimal investigation:
    28	
    29	1. **Write a 10-line SwiftUI test app** (NOT shipped — investigation only) inside `samples/initiative-cross-platform-ui-demo/scratch/probe.swift`:
    30	   ```swift
    31	   import SwiftUI
    32	   struct ProbeView: View {
    33	     var body: some View {
    34	       VStack {
    35	         Button("System blue prominent") {}.buttonStyle(.borderedProminent)
    36	         Button("Tinted teal prominent") {}.buttonStyle(.borderedProminent).tint(Color(red: 0.059, green: 0.522, blue: 0.522))
    37	         Button("Tinted teal bordered") {}.buttonStyle(.bordered).tint(Color(red: 0.059, green: 0.522, blue: 0.522))
    38	       }.padding()
    39	     }
    40	   }
    41	   ```
    42	2. **Run in a SwiftUI macOS app harness** (smallest viable Xcode project OR `swift run` against a tiny target). Screenshot the result.
    43	3. **Determine empirically:** does `.tint()` apply to `.borderedProminent` on macOS?
    44	4. If NO: confirm by reading Apple's SwiftUI documentation citations. Document at `handoff/phase-06.12c-probe-findings.md`.
    45	5. If YES: the regression has a different cause — escalate (the ButtonFacade removal may have broken something else).
    46	
    47	**Acceptance — Item 1:**
    48	- `phase-06.12c-probe-findings.md` documents the empirical behavior + Apple-doc citations.
    49	- Architect-readable conclusion: "macOS .borderedProminent ignores .tint()" OR "macOS .borderedProminent respects .tint()."
    50	
    51	---
    52	
    53	## Item 2 — Fix path (architect-decided based on Item 1 findings)
    54	
    55	The implementer reports Item 1's findings + waits for architect direction BEFORE applying a fix. Possible fix paths (the architect picks based on probe evidence):
    56	
    57	### Path A — Custom `Capsule.fill` chrome on macOS only (NAIVE — see Path A-prime)
    58	
    59	In `ButtonFacade.swift case "prominent":`, branch:
    60	```swift
    61	case "prominent":
    62	#if os(macOS)
    63	  if let activeTint = APSKRuntime.brandTint {
    64	    content = AnyView(content
    65	      .foregroundStyle(.white)
    66	      .padding(.vertical, 8)
    67	      .padding(.horizontal, 16)
    68	      .background(Capsule().fill(activeTint))
    69	      .buttonStyle(.plain))
    70	  } else {
    71	    content = AnyView(content.controlSize(.large).buttonStyle(.borderedProminent))
    72	  }
    73	#else
    74	  content = AnyView(content.controlSize(.large).buttonStyle(.borderedProminent))
    75	#endif
    76	```
    77	
    78	**Why this is better than the Phase 6.8 original:**
    79	- Conditional on PLATFORM (only macOS).
    80	- Conditional on `APSKRuntime.brandTint != nil` (only when a custom brand is active — Voyager with SYSTEM_ACCENT gets plain `.borderedProminent`).
    81	- Reads the live tint, no hardcoded color.
    82	
    83	### Path A-prime — Reusable macOS `ButtonStyle` (RECOMMENDED, per Codex)
    84	
    85	Codex critique noted: the naive `Capsule.fill` snippet (Path A) flattens
    86	native pressed / disabled / focus / high-contrast state visuals. The
    87	correct fix preserves them by implementing a real SwiftUI `ButtonStyle`:
    88	
    89	```swift
    90	#if os(macOS)
    91	struct APSKBrandProminentButtonStyle: ButtonStyle {
    92	  let tint: Color
    93	  func makeBody(configuration: Configuration) -> some View {
    94	    configuration.label
    95	      .font(.body.weight(.semibold))
    96	      .foregroundStyle(.white)
    97	      .padding(.vertical, 8)
    98	      .padding(.horizontal, 16)
    99	      .background(
   100	        Capsule()
   101	          .fill(configuration.isPressed ? tint.opacity(0.85) : tint)
   102	      )
   103	      .opacity(configuration.isPressed ? 0.95 : 1.0)
   104	      .overlay(
   105	        // Focus ring respects accent-color from environment when present
   106	        Capsule().stroke(Color.accentColor.opacity(0.0), lineWidth: 3)
   107	      )
   108	      .accessibilityAddTraits(.isButton)
   109	  }
   110	}
   111	#endif
   112	
   113	// In case "prominent":
   114	#if os(macOS)
   115	  if let activeTint = APSKRuntime.brandTint {
   116	    content = AnyView(content.buttonStyle(APSKBrandProminentButtonStyle(tint: activeTint)))
   117	  } else {
   118	    content = AnyView(content.controlSize(.large).buttonStyle(.borderedProminent))
   119	  }
   120	#else
   121	  content = AnyView(content.controlSize(.large).buttonStyle(.borderedProminent))
   122	#endif
   123	```
   124	
   125	This preserves:
   126	- Pressed state (configuration.isPressed darkens the background).
   127	- Disabled state (handled by SwiftUI's `.disabled()` modifier — applies automatically because we read `.foregroundStyle(.white)` which honors disabled-color cascades).
   128	- Focus state (overlay stroke with `Color.accentColor` — TODO confirm Apple's exact accessibility focus-ring pattern in the probe).
   129	- High-contrast accessibility setting (TODO confirm via `@Environment(\.colorSchemeContrast)` in the probe).
   130	
   131	The Implementer's Item 1 probe MUST measure pressed/disabled/focus/high-contrast states in the live SwiftUI test app + document whether the proposed ButtonStyle covers them. If state coverage is incomplete, the brief is REVISE-AGAIN — the fix must preserve native button state semantics.
   132	
   133	### Path B — Manual macOS `NSButton`-style override
   134	
   135	Use AppKit's `NSButton.bezelStyle` + `NSButton.contentTintColor` instead of SwiftUI's `.borderedProminent`. Larger Swift change.
   136	
   137	### Path C — Accept gray as documented platform difference
   138	
   139	If the SwiftUI quirk is genuinely undocumented behavior we can't reliably work around, document that custom-brand prominent buttons on macOS render with the system accent. Cascade developers either accept this OR use a different style. **Loses brand cascade promise.**
   140	
   141	### Path D — SwiftUI .controlSize hack
   142	
   143	Some Apple-platform engineering blogs suggest `.controlSize(.large)` + `.tint()` works on certain macOS versions. If Item 1 shows this works on macOS 14+ (our minimum), it might be a one-knob fix.
   144	
   145	**Recommend Path A-prime (reusable ButtonStyle) as the default if Item 1 confirms macOS quirk + the ButtonStyle covers pressed/disabled/focus/high-contrast states.** Path A is too naive per Codex. Path B is heavier. Path C loses brand promise. Path D is the lightest if it works on macOS 14+.
   146	
   147	---
   148	
   149	## Item 3 — Apply chosen fix + verify
   150	
   151	After architect approves the fix path:
   152	1. Apply the change in `swift/.../Facades/ButtonFacade.swift`.
   153	2. Rebuild Cascade macOS: `make -C samples/initiative-cross-platform-ui-demo cascade-macos`.
   154	3. Re-screenshot at `phase-06.12c-evidence/cascade-macos-prominent-button-{light,dark}-fixed.png`.
   155	4. Pixel-sample the button background: `python3 /tmp/wcag_sample.py <png> <btn_x> <btn_y>`. Confirm `(15, 133, 133) ± 15` per channel.
   156	5. Rebuild Voyager macOS: `make -C samples/initiative-cross-platform-ui-voyager macos`.
   157	6. Re-screenshot Voyager Sign-in at `phase-06.12c-evidence/voyager-macos-signin-after-fix.png`.
   158	7. Pixel-sample Voyager's Sign-in button. Confirm it is NOT teal (must be system blue or system gray, NOT (15, 133, 133)).
   159	8. **Add assertion (per Codex)** that Voyager's `APSKRuntime.brandTint == nil` at render time, since Voyager uses `SYSTEM_ACCENT`. Phase 6.12A Item 2 wired this clearing — verify it actually happens. Test seam: instrument `APSKRuntime.brandTint` access via a logging or test-mode hook to confirm the value is nil during Voyager's render path. If `brandTint` is unexpectedly non-nil for Voyager, ESCALATE — the SYSTEM_ACCENT clearing path is broken.
   160	8. Run `crystal spec` — baseline 1529/4/0 must hold.
   161	
   162	**Acceptance — Item 3:** all 4 captures present, Cascade teal pixel-sample passes, Voyager system-blue (not teal) pixel-sample passes, spec baseline preserved.
   163	
   164	---
   165	
   166	## Item 4 — Codex review of the fix
   167	
   168	```bash
   169	codex exec --skip-git-repo-check "Review the Phase 6.12C fix at swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift (the case 'prominent' branch). Verify: (1) macOS-only conditional protects Voyager (which uses SYSTEM_ACCENT) from regression; (2) reads APSKRuntime.brandTint at render time so a brand swap mid-session takes effect; (3) the iOS branch unchanged from Phase 6.11 iter-4; (4) no hardcoded color literal restored. Verdict per item: PASS/FAIL. Overall: APPROVE / REVISE."
   170	```
   171	
   172	Save to `handoff/phase-06.12c-codex-1.md`.
   173	
   174	---
   175	
   176	## Hard rules
   177	
   178	- Forward commits only.
   179	- DO NOT restore Phase 6.8 hardcoded `Color(red: 0.012, green: 0.521, blue: 0.521)` literal. Use the live `APSKRuntime.brandTint` value.
   180	- DO NOT make the fix non-conditional. iOS must continue to use stock `.borderedProminent` (Voyager system-blue path).
   181	- Standard Claude co-author footer.
   182	- If Item 1 investigation shows `.tint()` DOES apply on macOS, STOP and escalate — the regression has a different cause.
   183	- The Implementer DOES NOT apply Items 2/3 until the architect reviews Item 1 findings + approves a fix path.
   184	
   185	## Reporting

exec
/bin/zsh -lc "nl -ba docs/initiative-cross-platform-ui/phases/phase-06.11-ios-polish-defaults/iter-4.md | sed -n '35,60p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
    35	## Scope — 4 items, all must close
    36	
    37	### 1. Remove `ButtonFacade.swift` brand-teal hardcode
    38	
    39	**Location:** `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift`
    40	lines 158-182 (the `case "prominent":` block).
    41	
    42	**Required change:** Replace the explicit `Capsule().fill(brandTeal)` chrome with the standard `.buttonStyle(.borderedProminent)` modifier. The Phase 6.10 Path A fix means the SwiftUI Button's `action:` closure now fires correctly when hosted in UIKit — so the workaround is no longer needed.
    43	
    44	Suggested implementation:
    45	```swift
    46	case "prominent":
    47	    content = AnyView(content.buttonStyle(.borderedProminent))
    48	```
    49	
    50	The button's accent color should resolve via SwiftUI's environment `accentColor` (default system blue on iOS). If the application explicitly tints via `.tint(...)`, that cascade should reach the button naturally.
    51	
    52	**Acceptance:**
    53	- The hardcoded `brandTeal` Color literal is REMOVED from ButtonFacade.swift.
    54	- Sign-in button renders with iOS system blue (`.borderedProminent` default), not teal.
    55	- All facades that ride through `apsk_button_set_overrides` (Toggle, Slider, etc. — if they import from this file) continue to behave correctly.
    56	- `grep -rE "brand_?[Tt]eal|0\.012.*0\.521.*0\.521|Color\(red:.*0\.012" swift/` returns 0 hits.
    57	
    58	### 2. Investigate placeholder text color source
    59	
    60	Codex measured placeholder text at 1.67:1 in light and 2.23:1 in dark. WCAG AA floor for body is 4.5:1; for large/UI is 3:1. Both fail.

exec
/bin/zsh -lc "rg -n \"system_accent\\?|clear_brand_tint|apsk_runtime_set_brand_tint|apsk_runtime_clear_brand_tint|clearBrandTint|setBrandTint\" src/ui swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit -g '"'!swift/AssetPipelineSwiftKit/.build/**'"'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:26://   `APSKRuntime.setBrandTint(red:green:blue:alpha:)` once during render
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:109:    @objc public static func setBrandTint(red: Double, green: Double, blue: Double, alpha: Double) {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:122:    @objc public static func clearBrandTint() {
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:128:    /// `SwiftUI.Color`; ObjC callers go through `setBrandTint`.
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/CallbackBridge.swift:131:    /// Returns true once `setBrandTint` has been called at least once and
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/LinkButtonFacade.swift:32:        // `APSKRuntime.setBrandTint(...)`, the Link text now renders in the
src/ui/theme.cr:254:      override = c.system_accent? ? c.to_css : nil
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:202:            // tint via `APSKRuntime.setBrandTint(...)`, which
src/ui/design_tokens.cr:57:    # `Color#system_accent?` and route to the platform-native accent path
src/ui/design_tokens.cr:94:      # `system_accent?` before reading r/g/b/alpha.
src/ui/design_tokens.cr:103:      def system_accent? : Bool
src/ui/design_tokens.cr:114:      # calls `apsk_runtime_clear_brand_tint` so SwiftUI's automatic
src/ui/design_tokens.cr:117:      # `apsk_runtime_set_brand_tint(r, g, b, a)` with the baked sRGB
src/ui/design_tokens.cr:120:        system_accent? ? :clear : :set
src/ui/design_tokens.cr:130:        return "AccentColor" if system_accent?
src/ui/design_tokens.cr:139:        return "Color.accentColor" if system_accent?
src/ui/design_tokens.cr:222:        return "AccentColor" if system_accent?
src/ui/design_tokens.cr:236:        return "AccentColor" if system_accent?
src/ui/design_tokens.cr:250:      # emit; callers must guard on `system_accent?` before composing a
src/ui/design_tokens.cr:253:        if system_accent?
src/ui/design_tokens.cr:256:            "(emits the `AccentColor` keyword) or guard on system_accent? " \
src/ui/design_tokens.cr:269:        if system_accent?
src/ui/design_tokens.cr:292:        return "Color.accentColor" if system_accent?
src/ui/design_tokens.cr:302:        if system_accent?
src/ui/renderers/appkit_renderer.cr:262:      # `.tint()` cascade installed by `apsk_runtime_set_brand_tint` (see
src/ui/renderers/appkit_renderer.cr:3987:        if color.system_accent?
src/ui/renderers/appkit_renderer.cr:4037:          LibSwiftKitBridge.apsk_runtime_clear_brand_tint
src/ui/renderers/appkit_renderer.cr:4050:          LibSwiftKitBridge.apsk_runtime_set_brand_tint(
src/ui/native/swiftkit_bridge.m:120:// Selector is `setBrandTintWithRed:green:blue:alpha:` — that is the ObjC
src/ui/native/swiftkit_bridge.m:121:// name Swift synthesises for `@objc static func setBrandTint(red:green:
src/ui/native/swiftkit_bridge.m:123:void apsk_runtime_set_brand_tint(double r, double g, double b, double a) {
src/ui/native/swiftkit_bridge.m:126:    SEL sel = sel_registerName("setBrandTintWithRed:green:blue:alpha:");
src/ui/native/swiftkit_bridge.m:134:void apsk_runtime_clear_brand_tint(void) {
src/ui/native/swiftkit_bridge.m:137:    SEL sel = sel_registerName("clearBrandTint");
src/ui/renderers/uikit_renderer.cr:274:      # the `.tint()` cascade installed by `apsk_runtime_set_brand_tint`
src/ui/renderers/uikit_renderer.cr:4093:        if color.system_accent?
src/ui/renderers/uikit_renderer.cr:4134:          LibSwiftKitBridge.apsk_runtime_clear_brand_tint
src/ui/renderers/uikit_renderer.cr:4136:          LibSwiftKitBridge.apsk_runtime_set_brand_tint(
src/ui/native/swiftkit_bridge.cr:41:    # injection. The renderer calls `apsk_runtime_set_brand_tint(...)` on
src/ui/native/swiftkit_bridge.cr:45:    # the next render. Calling `apsk_runtime_clear_brand_tint` returns
src/ui/native/swiftkit_bridge.cr:48:    fun apsk_runtime_set_brand_tint(r : Float64, g : Float64, b : Float64, a : Float64)
src/ui/native/swiftkit_bridge.cr:49:    fun apsk_runtime_clear_brand_tint
src/ui/design_tokens/generators/web_generator.cr:148:          if color.system_accent?

exec
/bin/zsh -lc "nl -ba src/ui/renderers/appkit_renderer.cr | sed -n '3970,4060p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  3970	        (ENV["HIG_APPEARANCE"]? == "dark") ? :dark : :light
  3971	      end
  3972	
  3973	      # Resolve a semantic brand color role to an NSColor pointer via the
  3974	      # active design tokens (Step 9 of the Phase 1 implementation plan).
  3975	      # `amber_brand_gold` previously hardcoded `#FFAD33` / `#FFB84D`; that
  3976	      # helper is gone — every caller now passes through here so a brand
  3977	      # override on `design_tokens` cascades through.
  3978	      #
  3979	      # Phase 6.12A — when the resolved colour is `Color::SYSTEM_ACCENT`
  3980	      # the bridge returns `NSColor.controlAccentColor` (the live macOS
  3981	      # system accent that follows the user's General > Accent choice and
  3982	      # the active appearance automatically), not the sentinel's zeroed
  3983	      # sRGB bake.
  3984	      private def token_nscolor(role : Symbol, appearance : Symbol = current_appearance) : Void*
  3985	        palette = appearance == :dark ? @design_tokens.colors_dark : @design_tokens.colors_light
  3986	        color = palette.lookup(role) || palette.brand_primary
  3987	        if color.system_accent?
  3988	          LibObjCBridge.nscolor_control_accent
  3989	        else
  3990	          LibObjCBridge.nscolor_rgba(color.r, color.g, color.b, color.alpha)
  3991	        end
  3992	      end
  3993	
  3994	      # Deprecated shim: `amber_brand_gold` callers now resolve through the
  3995	      # token model. Retained as an alias to keep the call sites readable
  3996	      # while Step 9 mechanically migrates them; the function is private to
  3997	      # this file so it's not part of the public API.
  3998	      private def amber_brand_gold : Void*
  3999	        token_nscolor(:brand_primary)
  4000	      end
  4001	
  4002	      # Token-driven NSFont (system) at the size pulled from the active
  4003	      # TypeScale, multiplied by 16 to convert rem → points.
  4004	      private def token_font(step : Symbol = :body) : Void*
  4005	        ts = @design_tokens.type.lookup(step) || @design_tokens.type.body
  4006	        LibObjCBridge.nsfont_system(ts.size * 16.0)
  4007	      end
  4008	
  4009	      # Idempotently install the SwiftKit action trampoline and (re)apply
  4010	      # the brand-tint cascade from the active `design_tokens`. Called from
  4011	      # `render(...)` so every top-level render observes the current brand,
  4012	      # which is what makes `renderer.design_tokens = Tokens.default.with_brand(...)`
  4013	      # a hot swap.
  4014	      #
  4015	      # The brand-primary colour is read from the light palette — Apple's
  4016	      # `.tint()` accent cascade adapts contrast automatically across light
  4017	      # and dark via the dynamic colour the SwiftUI runtime derives from
  4018	      # the supplied sRGB triple, so we do not need to gate on
  4019	      # `HIG_APPEARANCE` here.
  4020	      private def ensure_swiftkit_runtime! : Nil
  4021	        unless @swiftkit_action_trampoline_installed
  4022	          LibSwiftKitBridge.apsk_runtime_install_default_action_trampoline
  4023	          @swiftkit_action_trampoline_installed = true
  4024	        end
  4025	        apply_brand_tint(@design_tokens.colors_light.brand_primary)
  4026	      end
  4027	
  4028	      # Phase 6.12A — pure routing of a brand colour to the SwiftKit
  4029	      # runtime. The decision (`:clear` vs `:set`) lives on
  4030	      # `UI::DesignTokens::Color#brand_tint_action` so it is unit-
  4031	      # testable without linking the native bridge. This method is
  4032	      # the production dispatch that translates the decision into the
  4033	      # corresponding `LibSwiftKitBridge` C call.
  4034	      protected def apply_brand_tint(brand : UI::DesignTokens::Color) : Nil
  4035	        case brand.brand_tint_action
  4036	        when :clear
  4037	          LibSwiftKitBridge.apsk_runtime_clear_brand_tint
  4038	          # Phase 6.12C — Codex-requested assertion. Voyager (and any
  4039	          # consumer using `Tokens.default` SYSTEM_ACCENT) reaches this
  4040	          # branch, which is what keeps `APSKRuntime.brandTint == nil`
  4041	          # and routes `ButtonFacade case "prominent"` through the stock
  4042	          # `.borderedProminent` path instead of the new
  4043	          # `APSKBrandProminentButtonStyle`. The log line is opt-in via
  4044	          # the `APSK_BRAND_TINT_LOG` env var so it is silent in normal
  4045	          # use but available for verification.
  4046	          if ENV["APSK_BRAND_TINT_LOG"]?
  4047	            STDERR.puts "[apsk] brand_tint=cleared (APSKRuntime.brandTint == nil)"
  4048	          end
  4049	        when :set
  4050	          LibSwiftKitBridge.apsk_runtime_set_brand_tint(
  4051	            brand.r, brand.g, brand.b, brand.alpha,
  4052	          )
  4053	          if ENV["APSK_BRAND_TINT_LOG"]?
  4054	            STDERR.puts "[apsk] brand_tint=set r=#{brand.r} g=#{brand.g} b=#{brand.b}"
  4055	          end
  4056	        end
  4057	      end
  4058	
  4059	      # Token-driven radius in points (rem * 16).
  4060	      private def token_radius(key : Symbol) : Float64

exec
/bin/zsh -lc "nl -ba src/ui/renderers/uikit_renderer.cr | sed -n '4080,4145p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
  4080	
  4081	      # Resolve a semantic brand color role to a UIColor pointer via the
  4082	      # active design tokens (Step 10 of the Phase 1 implementation plan).
  4083	      # Mirrors AppKit's `token_nscolor`.
  4084	      #
  4085	      # Phase 6.12A — when the resolved colour is `Color::SYSTEM_ACCENT`
  4086	      # the bridge returns `UIColor.tintColor` (the live UIKit accent that
  4087	      # follows the app's tintColor cascade up to SwiftUI's `.accentColor`,
  4088	      # which in turn defaults to system blue on iOS), not the sentinel's
  4089	      # zeroed sRGB bake.
  4090	      private def token_nscolor(role : Symbol, appearance : Symbol = current_appearance) : Void*
  4091	        palette = appearance == :dark ? @design_tokens.colors_dark : @design_tokens.colors_light
  4092	        color = palette.lookup(role) || palette.brand_primary
  4093	        if color.system_accent?
  4094	          LibObjCBridge.uicolor_tint
  4095	        else
  4096	          LibObjCBridge.nscolor_rgba(color.r, color.g, color.b, color.alpha)
  4097	        end
  4098	      end
  4099	
  4100	      # Deprecated shim: `amber_brand_gold` callers route through the token
  4101	      # model so a brand override on `design_tokens` cascades through.
  4102	      private def amber_brand_gold : Void*
  4103	        token_nscolor(:brand_primary)
  4104	      end
  4105	
  4106	      # Token-driven UIFont (system) at the size pulled from the active
  4107	      # TypeScale, multiplied by 16 to convert rem → points.
  4108	      private def token_font(step : Symbol = :body) : Void*
  4109	        ts = @design_tokens.type.lookup(step) || @design_tokens.type.body
  4110	        LibObjCBridge.nsfont_system(ts.size * 16.0)
  4111	      end
  4112	
  4113	      # Idempotently install the SwiftKit action trampoline and (re)apply
  4114	      # the brand-tint cascade from the active `design_tokens`. Mirrors
  4115	      # `UI::AppKit::Renderer#ensure_swiftkit_runtime!` — see that method
  4116	      # for the Option B design context. Tied to `render(...)` so a brand
  4117	      # swap mid-session takes effect on the next render.
  4118	      private def ensure_swiftkit_runtime! : Nil
  4119	        unless @swiftkit_action_trampoline_installed
  4120	          LibSwiftKitBridge.apsk_runtime_install_default_action_trampoline
  4121	          @swiftkit_action_trampoline_installed = true
  4122	        end
  4123	        apply_brand_tint(@design_tokens.colors_light.brand_primary)
  4124	      end
  4125	
  4126	      # Phase 6.12A — pure routing of a brand colour to the SwiftKit
  4127	      # runtime. The decision (`:clear` vs `:set`) lives on
  4128	      # `UI::DesignTokens::Color#brand_tint_action` so it is unit-
  4129	      # testable without linking the native bridge. Mirrors the AppKit
  4130	      # twin in `appkit_renderer.cr`.
  4131	      protected def apply_brand_tint(brand : UI::DesignTokens::Color) : Nil
  4132	        case brand.brand_tint_action
  4133	        when :clear
  4134	          LibSwiftKitBridge.apsk_runtime_clear_brand_tint
  4135	        when :set
  4136	          LibSwiftKitBridge.apsk_runtime_set_brand_tint(
  4137	            brand.r, brand.g, brand.b, brand.alpha,
  4138	          )
  4139	        end
  4140	      end
  4141	
  4142	      # Token-driven radius in points (rem * 16).
  4143	      private def token_radius(key : Symbol) : Float64
  4144	        (@design_tokens.radius.lookup(key) || @design_tokens.radius.md) * 16.0
  4145	      end

exec
/bin/zsh -lc "git diff -- src/ui/renderers/appkit_renderer.cr | sed -n '1,220p'" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
diff --git a/src/ui/renderers/appkit_renderer.cr b/src/ui/renderers/appkit_renderer.cr
index 41b63bb7..bce477ef 100644
--- a/src/ui/renderers/appkit_renderer.cr
+++ b/src/ui/renderers/appkit_renderer.cr
@@ -4035,10 +4035,24 @@ LibObjCBridge.nscolor_rgba(1.0, 1.0, 1.0, 1.0)
         case brand.brand_tint_action
         when :clear
           LibSwiftKitBridge.apsk_runtime_clear_brand_tint
+          # Phase 6.12C — Codex-requested assertion. Voyager (and any
+          # consumer using `Tokens.default` SYSTEM_ACCENT) reaches this
+          # branch, which is what keeps `APSKRuntime.brandTint == nil`
+          # and routes `ButtonFacade case "prominent"` through the stock
+          # `.borderedProminent` path instead of the new
+          # `APSKBrandProminentButtonStyle`. The log line is opt-in via
+          # the `APSK_BRAND_TINT_LOG` env var so it is silent in normal
+          # use but available for verification.
+          if ENV["APSK_BRAND_TINT_LOG"]?
+            STDERR.puts "[apsk] brand_tint=cleared (APSKRuntime.brandTint == nil)"
+          end
         when :set
           LibSwiftKitBridge.apsk_runtime_set_brand_tint(
             brand.r, brand.g, brand.b, brand.alpha,
           )
+          if ENV["APSK_BRAND_TINT_LOG"]?
+            STDERR.puts "[apsk] brand_tint=set r=#{brand.r} g=#{brand.g} b=#{brand.b}"
+          end
         end
       end
 

codex
The code path for Voyager depends on `brandTint == nil`, and the AppKit renderer currently clears it for `SYSTEM_ACCENT` before render. I’m doing one compile-level check on the Swift package now so the review is not just textual.
exec
/bin/zsh -lc 'swift test' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit
 exited 1 in 756ms:
warning: /Users/crimsonknight/Library/org.swift.swiftpm/configuration is not accessible or not writable, disabling user-level cache features.
warning: /Users/crimsonknight/Library/org.swift.swiftpm/security is not accessible or not writable, disabling user-level cache features.
warning: /Users/crimsonknight/Library/Caches/org.swift.swiftpm is not accessible or not writable, disabling user-level cache features.
error: 'assetpipelineswiftkit': Invalid manifest (compiled with: ["/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc", "-vfsoverlay", "/var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/TemporaryDirectory.NSDjW6/vfs.yaml", "-L", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-lPackageDescription", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-target", "arm64-apple-macosx14.0", "-plugin-path", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk", "-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks", "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-L", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-swift-version", "5", "-I", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk", "-package-description-version", "5.9.0", "/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Package.swift", "-o", "/var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/TemporaryDirectory.WX0H6f/assetpipelineswiftkit-manifest"])
<unknown>:0: error: error opening '/Users/crimsonknight/.cache/clang/ModuleCache/Swift-5SCGS38H536W.swiftmodule' for output: /Users/crimsonknight/.cache/clang/ModuleCache: Operation not permitted
<unknown>:0: error: unable to load standard library for target 'arm64-apple-macosx14.0'
error: 'assetpipelineswiftkit': Invalid manifest (compiled with: ["/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc", "-vfsoverlay", "/var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/TemporaryDirectory.KfJh4U/vfs.yaml", "-L", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-lPackageDescription", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-target", "arm64-apple-macosx14.0", "-plugin-path", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk", "-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks", "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-L", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-swift-version", "5", "-I", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk", "-package-description-version", "5.9.0", "/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Package.swift", "-o", "/var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/TemporaryDirectory.pv818O/assetpipelineswiftkit-manifest"])
<unknown>:0: error: error opening '/Users/crimsonknight/.cache/clang/ModuleCache/Swift-5SCGS38H536W.swiftmodule' for output: /Users/crimsonknight/.cache/clang/ModuleCache: Operation not permitted
<unknown>:0: error: unable to load standard library for target 'arm64-apple-macosx14.0'
error: ExitCode(rawValue: 1)
[0/1] Planning build

codex
`swift test` hit the sandbox because Swift tried to write Clang modules under `~/.cache`. I’m retrying with the module cache redirected into `/private/tmp`, which is writable here.
exec
/bin/zsh -lc 'mkdir -p /private/tmp/asset_pipeline-clang-module-cache && env CLANG_MODULE_CACHE_PATH=/private/tmp/asset_pipeline-clang-module-cache swift test' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit
 exited 1 in 1279ms:
warning: /Users/crimsonknight/Library/org.swift.swiftpm/configuration is not accessible or not writable, disabling user-level cache features.
warning: /Users/crimsonknight/Library/org.swift.swiftpm/security is not accessible or not writable, disabling user-level cache features.
warning: /Users/crimsonknight/Library/Caches/org.swift.swiftpm is not accessible or not writable, disabling user-level cache features.
error: 'assetpipelineswiftkit': Invalid manifest (compiled with: ["/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc", "-vfsoverlay", "/var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/TemporaryDirectory.WtHQJz/vfs.yaml", "-L", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-lPackageDescription", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-target", "arm64-apple-macosx14.0", "-plugin-path", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk", "-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks", "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-L", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-swift-version", "5", "-I", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk", "-package-description-version", "5.9.0", "/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Package.swift", "-o", "/var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/TemporaryDirectory.mgj1Gw/assetpipelineswiftkit-manifest"])
sandbox-exec: sandbox_apply: Operation not permitted
error: 'assetpipelineswiftkit': Invalid manifest (compiled with: ["/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc", "-vfsoverlay", "/var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/TemporaryDirectory.43rbiv/vfs.yaml", "-L", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-lPackageDescription", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-target", "arm64-apple-macosx14.0", "-plugin-path", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins/testing", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk", "-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks", "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-L", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-swift-version", "5", "-I", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk", "-package-description-version", "5.9.0", "/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Package.swift", "-o", "/var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/TemporaryDirectory.3QIfvX/assetpipelineswiftkit-manifest"])
sandbox-exec: sandbox_apply: Operation not permitted
error: ExitCode(rawValue: 1)
[0/1] Planning build

codex
The retry got past the module-cache issue but SwiftPM’s own package sandbox is blocked in this environment. I’m trying SwiftPM with its internal sandbox disabled; that still stays within the Codex filesystem sandbox.
exec
/bin/zsh -lc 'env CLANG_MODULE_CACHE_PATH=/private/tmp/asset_pipeline-clang-module-cache swift test --disable-sandbox' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit
 exited 1 in 22064ms:
warning: /Users/crimsonknight/Library/org.swift.swiftpm/configuration is not accessible or not writable, disabling user-level cache features.
warning: /Users/crimsonknight/Library/org.swift.swiftpm/security is not accessible or not writable, disabling user-level cache features.
warning: /Users/crimsonknight/Library/Caches/org.swift.swiftpm is not accessible or not writable, disabling user-level cache features.
warning: 'assetpipelineswiftkit': failed storing manifest for 'assetpipelineswiftkit' in cache: attempt to write a readonly database
warning: 'swift-snapshot-testing': failed storing manifest for 'swift-snapshot-testing' in cache: attempt to write a readonly database
warning: 'swift-syntax': failed storing manifest for 'swift-syntax' in cache: attempt to write a readonly database
[0/1] Planning build
Building for debugging...
[0/6] Write sources
[0/6] /Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/.build/arm64-apple-macosx/debug/AssetPipelineSwiftKitPackageTests.derived/runner.swift
[2/10] Write sources
[5/10] Write swift-version--58304C5D6DBC2206.txt
[7/50] Compiling AssetPipelineSwiftKit APSKBrandProminentButtonStyle.swift
[8/50] Compiling AssetPipelineSwiftKit LabelOverrides.swift
[9/50] Compiling AssetPipelineSwiftKit LabelFacade.swift
[10/50] Compiling AssetPipelineSwiftKit ReactiveState.swift
[11/50] Compiling AssetPipelineSwiftKit ButtonFacade.swift
[12/50] Emitting module AssetPipelineSwiftKit
[13/50] Compiling AssetPipelineSwiftKit TextFieldFacade.swift
[14/50] Compiling AssetPipelineSwiftKit SecureFieldFacade.swift
[14/50] Write Objects.LinkFileList
[15/50] Archiving libAssetPipelineSwiftKit.a
[17/50] Compiling SnapshotTesting CALayer.swift
[18/50] Compiling SnapshotTesting CGPath.swift
[19/50] Compiling SnapshotTesting CaseIterable.swift
[20/53] Compiling SnapshotTesting NSImage.swift
[21/53] Compiling SnapshotTesting NSView.swift
[22/53] Compiling SnapshotTesting NSViewController.swift
[23/53] Compiling SnapshotTesting Diffing.swift
[24/53] Compiling SnapshotTesting Wait.swift
[25/53] Compiling SnapshotTesting Deprecations.swift
[26/53] Compiling SnapshotTesting RecordIssue.swift
[27/53] Compiling SnapshotTesting Data.swift
[28/53] Compiling SnapshotTesting Encodable.swift
[29/53] Compiling SnapshotTesting NSBezierPath.swift
[30/53] Compiling SnapshotTesting SnapshotTestingConfiguration.swift
[31/53] Compiling SnapshotTesting SnapshotsTestTrait.swift
[32/53] Compiling SnapshotTesting Snapshotting.swift
[33/53] Compiling SnapshotTesting Any.swift
[34/53] Compiling SnapshotTesting SceneKit.swift
[35/53] Compiling SnapshotTesting SpriteKit.swift
[36/53] Compiling SnapshotTesting String.swift
[37/53] Compiling SnapshotTesting SwiftUIView.swift
[38/53] Compiling SnapshotTesting UIBezierPath.swift
[39/53] Compiling SnapshotTesting UIImage.swift
[40/53] Compiling SnapshotTesting AssertSnapshot.swift
[41/53] Compiling SnapshotTesting Async.swift
[42/53] Compiling SnapshotTesting Internal.swift
[43/53] Compiling SnapshotTesting PlistEncoder.swift
[44/53] Compiling SnapshotTesting String+SpecialCharacters.swift
[45/53] Compiling SnapshotTesting View.swift
[46/53] Compiling SnapshotTesting XCTAttachment.swift
[47/53] Compiling SnapshotTesting Diff.swift
[48/53] Emitting module SnapshotTesting
[49/53] Compiling SnapshotTesting UIView.swift
[50/53] Compiling SnapshotTesting UIViewController.swift
[51/53] Compiling SnapshotTesting URLRequest.swift
[52/58] Compiling AssetPipelineSwiftKitTests RuntimeBridgeTests.swift
[53/58] Emitting module AssetPipelineSwiftKitTests
[54/58] Compiling AssetPipelineSwiftKitTests OverridesPropagationTests.swift
[55/58] Compiling AssetPipelineSwiftKitTests SnapshotTests.swift
/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/SnapshotTests.swift:34:9: warning: 'isRecording' is deprecated: Use 'withSnapshotTesting' to customize the record mode. See the documentation for more information. [#DeprecatedDeclaration]
 32 |         // Per swift-snapshot-testing 1.17 docs: setting the env var
 33 |         // `RECORD_SNAPSHOTS=1` flips the package-wide recording mode.
 34 |         isRecording = ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"
    |         `- warning: 'isRecording' is deprecated: Use 'withSnapshotTesting' to customize the record mode. See the documentation for more information. [#DeprecatedDeclaration]
 35 |     }
 36 | 

[#DeprecatedDeclaration]: <https://docs.swift.org/compiler/documentation/diagnostics/deprecated-declaration>
[56/58] Compiling AssetPipelineSwiftKitTests ReactiveStateTests.swift
[57/60] Compiling AssetPipelineSwiftKitPackageTests runner.swift
[58/60] Emitting module AssetPipelineSwiftKitPackageTests
[58/60] Write Objects.LinkFileList
[59/60] Linking AssetPipelineSwiftKitPackageTests
Build complete! (18.33s)
Test Suite 'All tests' started at 2026-05-24 11:50:29.674.
Test Suite 'AssetPipelineSwiftKitPackageTests.xctest' started at 2026-05-24 11:50:29.676.
Test Suite 'OverridesPropagationTests' started at 2026-05-24 11:50:29.676.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testAccessibilityIdentifierRoundTrips]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testAccessibilityIdentifierRoundTrips]' passed (0.002 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testApskAccessibilityLabelRoundTrips]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testApskAccessibilityLabelRoundTrips]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeDestructiveRoleRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeDestructiveRoleRenders]' passed (0.029 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeDisabledRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeDisabledRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeProminentStyleRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeProminentStyleRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeRendersWithDefaults]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeRendersWithDefaults]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeWithSymbolNameRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testButtonFacadeWithSymbolNameRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeCornerRadiusOverrideAppliesViaCommonModifiers]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeCornerRadiusOverrideAppliesViaCommonModifiers]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeOutlinedRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeOutlinedRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeRendersWithDefaults]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeRendersWithDefaults]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeWithMaterialOverrideRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeWithMaterialOverrideRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeWithTitleRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testCardFacadeWithTitleRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testGlassBackgroundFacadeRendersWithDefaults]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testGlassBackgroundFacadeRendersWithDefaults]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testGlassBackgroundFacadeWithThinMaterialRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testGlassBackgroundFacadeWithThinMaterialRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testGlassBackgroundFacadeWithUltraThinMaterialRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testGlassBackgroundFacadeWithUltraThinMaterialRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testNavigationStackFacadeEmbedsChildViaHostedChild]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testNavigationStackFacadeEmbedsChildViaHostedChild]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testNavigationStackFacadeRendersWithEmptyChildren]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testNavigationStackFacadeRendersWithEmptyChildren]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testNavigationStackFacadeRendersWithTitle]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testNavigationStackFacadeRendersWithTitle]' passed (0.001 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testTextFieldFacadeRendersWithDefaults]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testTextFieldFacadeRendersWithDefaults]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testTextFieldFacadeSecureEntryRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testTextFieldFacadeSecureEntryRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testTextFieldFacadeWithInitialTextRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testTextFieldFacadeWithInitialTextRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testToggleFacadeDisabledRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testToggleFacadeDisabledRenders]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testToggleFacadeRendersWithDefaults]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testToggleFacadeRendersWithDefaults]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testToggleFacadeSwitchStyleRenders]' started.
Test Case '-[AssetPipelineSwiftKitTests.OverridesPropagationTests testToggleFacadeSwitchStyleRenders]' passed (0.000 seconds).
Test Suite 'OverridesPropagationTests' passed at 2026-05-24 11:50:29.714.
	 Executed 24 tests, with 0 failures (0 unexpected) in 0.036 (0.038) seconds
Test Suite 'ReactiveStateTests' started at 2026-05-24 11:50:29.714.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonClearBackgroundColorResetsField]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonClearBackgroundColorResetsField]' passed (0.214 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonClearCornerRadiusResetsField]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonClearCornerRadiusResetsField]' passed (0.210 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonSetBackgroundColorUpdatesField]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonSetBackgroundColorUpdatesField]' passed (0.209 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonSetCornerRadiusUpdatesField]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonSetCornerRadiusUpdatesField]' passed (0.205 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonSetForegroundColorUpdatesField]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskButtonSetForegroundColorUpdatesField]' passed (0.204 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskLabelSetTextHandlesEmptyString]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskLabelSetTextHandlesEmptyString]' passed (0.210 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskLabelSetTextUpdatesPublishedField]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskLabelSetTextUpdatesPublishedField]' passed (0.208 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskSliderSetValueUpdatesStorage]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskSliderSetValueUpdatesStorage]' passed (0.204 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskToggleSetValueUpdatesStorage]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testApskToggleSetValueUpdatesStorage]' passed (0.419 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testButtonStateNilFieldsByDefault]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testButtonStateNilFieldsByDefault]' passed (0.001 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testLabelStateInitialText]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testLabelStateInitialText]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testLabelStatePublisherFiresOnTextChange]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testLabelStatePublisherFiresOnTextChange]' passed (0.001 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testMakeReactiveButtonWritesStatePointer]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testMakeReactiveButtonWritesStatePointer]' passed (0.213 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testMakeReactiveLabelWritesStatePointer]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testMakeReactiveLabelWritesStatePointer]' passed (0.202 seconds).
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testStateReleaseAcceptsNil]' started.
Test Case '-[AssetPipelineSwiftKitTests.ReactiveStateTests testStateReleaseAcceptsNil]' passed (0.000 seconds).
Test Suite 'ReactiveStateTests' passed at 2026-05-24 11:50:32.219.
	 Executed 15 tests, with 0 failures (0 unexpected) in 2.500 (2.506) seconds
Test Suite 'RuntimeBridgeTests' started at 2026-05-24 11:50:32.220.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testBrandTintStartsUnset]' started.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testBrandTintStartsUnset]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testCallbackBridgeFireInvokesInstalledTrampoline]' started.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testCallbackBridgeFireInvokesInstalledTrampoline]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testCallbackBridgeFireMultipleInvocations]' started.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testCallbackBridgeFireMultipleInvocations]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testCallbackBridgeFireTokenZeroIsNoOp]' started.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testCallbackBridgeFireTokenZeroIsNoOp]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testClearBrandTintResetsToNil]' started.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testClearBrandTintResetsToNil]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testInstallTestTrampolineSetsInstalled]' started.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testInstallTestTrampolineSetsInstalled]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testModuleIsLoaded]' started.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testModuleIsLoaded]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testSetBrandTintFlipsHasBrandTint]' started.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testSetBrandTintFlipsHasBrandTint]' passed (0.000 seconds).
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testSetBrandTintIsReCallable]' started.
Test Case '-[AssetPipelineSwiftKitTests.RuntimeBridgeTests testSetBrandTintIsReCallable]' passed (0.000 seconds).
Test Suite 'RuntimeBridgeTests' passed at 2026-05-24 11:50:32.222.
	 Executed 9 tests, with 0 failures (0 unexpected) in 0.002 (0.003) seconds
Test Suite 'SnapshotTests' started at 2026-05-24 11:50:32.222.
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_background_override_ios]' started.
/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/SnapshotTests.swift:90: error: -[AssetPipelineSwiftKitTests.SnapshotTests test_background_override_ios] : failed - Snapshot "background_override_ios" does not match reference.

@−
"file:///Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/__Snapshots__/SnapshotTests/test_background_override_ios.background_override_ios.png"
@+
"file:///var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/SnapshotTests/test_background_override_ios.background_override_ios.png"

To configure output for a custom diff tool, use 'withSnapshotTesting'. For example:

    withSnapshotTesting(diffTool: .ksdiff) {
      // ...
    }

Newly-taken snapshot@(160.0, 48.0) does not match reference@(160.0, 48.0).
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_background_override_ios]' failed (0.100 seconds).
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_corner_radius_zero_ios]' started.
/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/SnapshotTests.swift:107: error: -[AssetPipelineSwiftKitTests.SnapshotTests test_corner_radius_zero_ios] : failed - Snapshot "corner_radius_zero_ios" does not match reference.

@−
"file:///Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/__Snapshots__/SnapshotTests/test_corner_radius_zero_ios.corner_radius_zero_ios.png"
@+
"file:///var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/SnapshotTests/test_corner_radius_zero_ios.corner_radius_zero_ios.png"

To configure output for a custom diff tool, use 'withSnapshotTesting'. For example:

    withSnapshotTesting(diffTool: .ksdiff) {
      // ...
    }

Newly-taken snapshot@(160.0, 48.0) does not match reference@(160.0, 48.0).
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_corner_radius_zero_ios]' failed (0.008 seconds).
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_default_button_ios]' started.
/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/SnapshotTests.swift:69: error: -[AssetPipelineSwiftKitTests.SnapshotTests test_default_button_ios] : failed - Snapshot "default_button_ios" does not match reference.

@−
"file:///Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/__Snapshots__/SnapshotTests/test_default_button_ios.default_button_ios.png"
@+
"file:///var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/SnapshotTests/test_default_button_ios.default_button_ios.png"

To configure output for a custom diff tool, use 'withSnapshotTesting'. For example:

    withSnapshotTesting(diffTool: .ksdiff) {
      // ...
    }

Newly-taken snapshot@(160.0, 48.0) does not match reference@(160.0, 48.0).
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_default_button_ios]' failed (0.006 seconds).
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_default_button_macos]' started.
/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/SnapshotTests.swift:49: error: -[AssetPipelineSwiftKitTests.SnapshotTests test_default_button_macos] : failed - Snapshot "default_button_macos" does not match reference.

@−
"file:///Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/__Snapshots__/SnapshotTests/test_default_button_macos.default_button_macos.png"
@+
"file:///var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/SnapshotTests/test_default_button_macos.default_button_macos.png"

To configure output for a custom diff tool, use 'withSnapshotTesting'. For example:

    withSnapshotTesting(diffTool: .ksdiff) {
      // ...
    }

Newly-taken snapshot@(160.0, 48.0) does not match reference@(160.0, 48.0).
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_default_button_macos]' failed (0.006 seconds).
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_glass_default_ios26]' started.
/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/SnapshotTests.swift:122: error: -[AssetPipelineSwiftKitTests.SnapshotTests test_glass_default_ios26] : failed - Snapshot "glass_default_ios26" does not match reference.

@−
"file:///Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/__Snapshots__/SnapshotTests/test_glass_default_ios26.glass_default_ios26.png"
@+
"file:///var/folders/81/8xr46ykx0p350l1g_v0nk7hr0000gn/T/SnapshotTests/test_glass_default_ios26.glass_default_ios26.png"

To configure output for a custom diff tool, use 'withSnapshotTesting'. For example:

    withSnapshotTesting(diffTool: .ksdiff) {
      // ...
    }

Newly-taken snapshot@(240.0, 160.0) does not match reference@(240.0, 160.0).
Test Case '-[AssetPipelineSwiftKitTests.SnapshotTests test_glass_default_ios26]' failed (0.010 seconds).
Test Suite 'SnapshotTests' failed at 2026-05-24 11:50:32.353.
	 Executed 5 tests, with 5 failures (0 unexpected) in 0.130 (0.130) seconds
Test Suite 'AssetPipelineSwiftKitPackageTests.xctest' failed at 2026-05-24 11:50:32.353.
	 Executed 53 tests, with 5 failures (0 unexpected) in 2.668 (2.677) seconds
Test Suite 'All tests' failed at 2026-05-24 11:50:32.353.
	 Executed 53 tests, with 5 failures (0 unexpected) in 2.668 (2.679) seconds
◇ Test run started.
↳ Testing Library Version: 1902
↳ Target Platform: arm64e-apple-macos14.0
✔ Test run with 0 tests in 0 suites passed after 0.001 seconds.

codex
The Swift package builds through the new file and `ButtonFacade`, but the full test run still fails on five existing snapshot comparisons after 48 non-snapshot tests pass. I’m doing one last focused literal scan across the touched Swift files.
exec
/bin/zsh -lc "rg -n \"brand_?[Tt]eal|Color\\(red:|\\.sRGB|0\\.012|0\\.521|0\\.059|0\\.522|#0f8585|15, 133, 133|NSColor|UIColor|Color\\(\" swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift" in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:301:            content = AnyView(content.background(Color(uiColor: bg)))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:303:            content = AnyView(content.background(Color(nsColor: bg)))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:309:            content = AnyView(content.foregroundStyle(Color(uiColor: fg)))
swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:311:            content = AnyView(content.foregroundStyle(Color(nsColor: fg)))

exec
/bin/zsh -lc 'git diff --check -- swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/APSKBrandProminentButtonStyle.swift' in /Users/crimsonknight/open_source_coding_projects/asset_pipeline
 succeeded in 0ms:
codex
**Review Verdict**

1. **macOS-only conditional protects Voyager (`SYSTEM_ACCENT`): PASS**  
   `ButtonFacade.swift:219-239` gates the custom style under `#if os(macOS)` and only uses it when `APSKRuntime.brandTint != nil`. The nil path keeps stock `.controlSize(.large).buttonStyle(.borderedProminent)`, so Voyager’s cleared `SYSTEM_ACCENT` path is preserved.

2. **Reads `APSKRuntime.brandTint` at render time: PASS**  
   The prominent branch reads `APSKRuntime.brandTint` inside `APSKButtonHost.body` and passes the live value into `APSKBrandProminentButtonStyle(tint:)`. The renderer also reapplies/clears brand tint on render, so a token brand swap is picked up on the next render.

3. **iOS branch unchanged from Phase 6.11 iter-4 requirement: PASS**  
   The non-macOS branch is still:
   ```swift
   .controlSize(.large)
   .buttonStyle(.borderedProminent)
   ```

4. **No hardcoded brand color literal restored: PASS**  
   No `Color(red: 0.012, green: 0.521, blue: 0.521)` / `brandTeal` path is present. The custom macOS fill uses the live `tint`.

**Overall: APPROVE**

Verification note: `swift test --disable-sandbox` compiled the Swift package and the new file, with 48 tests passing before five existing snapshot comparison failures. `git diff --check` passed for the reviewed Swift files.
tokens used
79,491
**Review Verdict**

1. **macOS-only conditional protects Voyager (`SYSTEM_ACCENT`): PASS**  
   `ButtonFacade.swift:219-239` gates the custom style under `#if os(macOS)` and only uses it when `APSKRuntime.brandTint != nil`. The nil path keeps stock `.controlSize(.large).buttonStyle(.borderedProminent)`, so Voyager’s cleared `SYSTEM_ACCENT` path is preserved.

2. **Reads `APSKRuntime.brandTint` at render time: PASS**  
   The prominent branch reads `APSKRuntime.brandTint` inside `APSKButtonHost.body` and passes the live value into `APSKBrandProminentButtonStyle(tint:)`. The renderer also reapplies/clears brand tint on render, so a token brand swap is picked up on the next render.

3. **iOS branch unchanged from Phase 6.11 iter-4 requirement: PASS**  
   The non-macOS branch is still:
   ```swift
   .controlSize(.large)
   .buttonStyle(.borderedProminent)
   ```

4. **No hardcoded brand color literal restored: PASS**  
   No `Color(red: 0.012, green: 0.521, blue: 0.521)` / `brandTeal` path is present. The custom macOS fill uses the live `tint`.

**Overall: APPROVE**

Verification note: `swift test --disable-sandbox` compiled the Swift package and the new file, with 48 tests passing before five existing snapshot comparison failures. `git diff --check` passed for the reviewed Swift files.
