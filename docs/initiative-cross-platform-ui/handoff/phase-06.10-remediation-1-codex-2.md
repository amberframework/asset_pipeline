    52	                    .accessibilityIdentifier("voyager-root-host")
    53	            }
    54	            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    55	        }
    56	        .onReceive(VoyagerBridge.routeChanged) { newSlug in
    57	            if newSlug != slug {
    58	                slug = newSlug
    59	            }
    60	        }
    61	        .onAppear {
    62	            // Make sure VoyagerBridge.initialize runs so the route-changed
    63	            // callback is registered BEFORE any tap handler inside the
    64	            // Crystal view tree fires coord.push(...).
    65	            VoyagerBridge.initialize()
    66	        }
    67	    }
    68	}
    69	
    70	/// A persistent container UIView that hosts the Crystal-rendered view
    71	/// as its only subview. When `slug` changes, `updateUIView` rerenders
    72	/// from Crystal and swaps the child. SwiftUI's UIViewRepresentable
    73	/// contract is that `makeUIView` runs once per identity; `updateUIView`
    74	/// runs on every state change. Because we return a stable container,
    75	/// we have a place to swap children on slug changes.

codex
PASS: The two commits cover the requested remediation slice: UIKit now detects container views and clamps them to non-accessibility elements so labeled stacks do not hide descendants ([uikit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/uikit_renderer.cr:4214), lines 4214-4234), with the same container clamp mirrored for AppKit ([appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:4126), lines 4126-4138). The iOS form-default work is also present: `VStack` now defaults to `DEFAULT_SPACING_PT = 12.0` and uses that for both the property and initializer ([vstack.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/views/vstack.cr:17), lines 17-28), while the Voyager SwiftUI shell supplies edge-to-edge system background plus a 16pt horizontal gutter around the Crystal host ([ContentView.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:42), lines 42-54). I do not see a regression in the scoped files.
tokens used
32,054
PASS: The two commits cover the requested remediation slice: UIKit now detects container views and clamps them to non-accessibility elements so labeled stacks do not hide descendants ([uikit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/uikit_renderer.cr:4214), lines 4214-4234), with the same container clamp mirrored for AppKit ([appkit_renderer.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/appkit_renderer.cr:4126), lines 4126-4138). The iOS form-default work is also present: `VStack` now defaults to `DEFAULT_SPACING_PT = 12.0` and uses that for both the property and initializer ([vstack.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/views/vstack.cr:17), lines 17-28), while the Voyager SwiftUI shell supplies edge-to-edge system background plus a 16pt horizontal gutter around the Crystal host ([ContentView.swift](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:42), lines 42-54). I do not see a regression in the scoped files.
