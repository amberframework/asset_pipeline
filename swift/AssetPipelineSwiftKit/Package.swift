// swift-tools-version:5.9
import PackageDescription

// AssetPipelineSwiftKit — the Swift companion library that lets the
// Crystal-side AppKit and UIKit renderers reach SwiftUI defaults.
//
// Each Tier 1 / Tier 2 widget in the Crystal `UI::*` hierarchy gets a
// matching `@objc` facade class here (e.g. `APSKButtonFacade.makeButton`).
// The facade builds the SwiftUI view, wraps it in a hosting controller,
// and returns the controller's `.view` as a raw `UIView`/`NSView` pointer
// that the Crystal renderer can embed in its native parent tree.
//
// Build slices (validated by the iOS / macOS sample build scripts):
//
//   swift build -c release \
//     --triple arm64-apple-ios16.0-simulator \
//     --sdk $(xcrun --sdk iphonesimulator --show-sdk-path)
//
//   swift build -c release \
//     --triple arm64-apple-ios16.0 \
//     --sdk $(xcrun --sdk iphoneos --show-sdk-path)
//
//   swift build -c release \
//     --triple arm64-apple-macosx13.0 \
//     --sdk $(xcrun --sdk macosx --show-sdk-path)
//
// The package emits a static library so the Crystal sample build can `ar`
// it (or link it directly) alongside `libobjc_bridge.o` and the Crystal
// object files.
let package = Package(
    name: "AssetPipelineSwiftKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "AssetPipelineSwiftKit",
            type: .static,
            targets: ["AssetPipelineSwiftKit"]
        ),
    ],
    dependencies: [
        // Pinned to the 1.17.x minor line per Phase 3 implementation §10.2.
        // Phase 6 (quad-evidence snapshot tooling) and Phase 7 (visual
        // baselines) assume the same minor; coordinate any bump with both.
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            .upToNextMinor(from: "1.17.0")
        ),
    ],
    targets: [
        .target(
            name: "AssetPipelineSwiftKit",
            dependencies: [],
            path: "Sources/AssetPipelineSwiftKit"
        ),
        .testTarget(
            name: "AssetPipelineSwiftKitTests",
            dependencies: [
                "AssetPipelineSwiftKit",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Tests/AssetPipelineSwiftKitTests",
            // The `__Snapshots__/` baseline PNGs are read at runtime by
            // swift-snapshot-testing through the source-relative path
            // (`#file` lookup), so they live in the test bundle but
            // they're not declared as Swift Package resources. Excluding
            // the snapshot baseline directory keeps SwiftPM from emitting
            // "unhandled file" warnings on every build.
            exclude: ["SnapshotTests/__Snapshots__"]
        ),
    ]
)
