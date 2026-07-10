# Phase 3 Remediation 5 — Blockers & Build-Config Notes

Date: 2026-05-21
Branch: `phase-03-swiftui-native-bridge`
Author: implementer (Remediation 5 dispatch)

## Summary

Remediation 5's stated scope was build-config-only: link
`swiftkit_simulator.a` (plus SwiftUI + Combine) into the iOS
`CrystalHIGHost` target so the 15 reactive `apsk_*` symbols introduced in
Remediation 4 resolve at link time. That portion **succeeded** — every
`apsk_*` symbol now resolves, including the new reactive entry points
(`apsk_label_set_text`, `apsk_button_set_background_color`,
`apsk_toggle_set_value`, `apsk_slider_set_value`, `apsk_state_release`,
etc.).

But the iOS `xcodebuild build` **still fails** on a pre-existing,
orthogonal blocker: Crystal's standard library transitively pulls in
OpenSSL + zlib through `web_renderer → components →
reactive_handler/reactive_session`, and the iOS Simulator SDK does not
expose OpenSSL-named symbols (only BoringSSL, under different names).
`libz.tbd` is available in the SDK, but link still fails because no
`-lz` flag is set AND the SSL refs cannot be resolved at all from the
system SDK.

This blocker predates Remediation 5 and is **independent of the
reactive bridge work**. It was not exposed earlier because the iOS app
was never actually linked since `hig_bridge.cr` started requiring
`src/ui/probes` and (transitively) the full Crystal `src/ui` tree —
commit `1a77437` notes "Xcode build verification is currently blocked
by the iOS 26.5 platform gap on the dispatch host". With Xcode 26.5 +
iOS 26.5 simulator now installed, the latent transitive dependency on
OpenSSL surfaces at link time.

---

## What landed in Remediation 5

`samples/cross_platform/ios_host/project.yml` `OTHER_LDFLAGS` extended:

```yaml
- -Wl,-force_load,$(PROJECT_DIR)/build/swiftkit_simulator.a
- -framework SwiftUI
- -framework Combine
```

`build_crystal_lib.sh` was already producing
`build/swiftkit_simulator.a` from a prior dispatch — no script change
was required. The Swift facade static archive is built via
`swift build -c release --triple arm64-apple-ios-simulator --sdk
$(xcrun --sdk iphonesimulator --show-sdk-path)` against
`swift/AssetPipelineSwiftKit/Package.swift`.

`xcodegen generate` was re-run; the regenerated `.xcodeproj` is
gitignored (`samples/cross_platform/ios_host/.gitignore` excludes
`*.xcodeproj/`), so only `project.yml` is tracked.

**Reactive-bridge link verification:** `nm libhighost.a` shows 15
undefined `_apsk_*` symbols (the reactive entry points + the Phase 3a
facade entry points). `nm swiftkit_simulator.a` shows all 15 as defined
text symbols. With `-Wl,-force_load,...swiftkit_simulator.a` in the
link line, the linker error trace contains zero `_apsk_*` undefineds —
confirming the force-load resolves them as expected.

---

## Blocker 1: Crystal stdlib OpenSSL/zlib refs on iOS

`xcodebuild build` fails with 9 undefined symbols, all from Crystal
stdlib code paths reachable through `require "../../../src/ui"`:

```
_ERR_error_string  ← OpenSSL::SSL::Error#fetch_error_details
_ERR_get_error     ← OpenSSL::SSL::Error#fetch_error_details
_SSL_get_error     ← OpenSSL::SSL::Error#initialize
_SSL_write         ← OpenSSL::SSL::Socket#unbuffered_write
_crc32             ← Digest::CRC32
_deflate           ← Compress::Deflate::Writer#consume_output
_deflateInit2_     ← Compress::Deflate::Writer#initialize
_zError            ← Compress::Deflate::Error#initialize
_zlibVersion       ← Compress::Deflate::Writer#initialize
```

The OpenSSL refs come from `src/components/reactive/reactive_handler.cr`
and `src/components/reactive/reactive_session.cr` (each `require
"http/server"` + `require "openssl"`). These are pulled into the iOS
binary through this chain:

```
samples/cross_platform/ios_host/hig_bridge.cr
  └─ require "../../../src/ui"                            (src/ui.cr)
       └─ require "./ui/renderers/web_renderer"           (line 14)
            └─ require "../../components"                 (src/components.cr)
                 └─ require "./components/reactive/*"     (pulls SSL + HTTP)
```

The zlib refs (`Compress::Deflate`, `Digest::CRC32`) come from the
same `src/components` transitive include path (HTTP server gzip).

### Why the system SDK won't resolve them

The iPhoneSimulator SDK at
`/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/usr/lib`
ships:

- `libz.tbd` (and versioned variants) — would resolve `_deflate`,
  `_crc32`, etc., **if `-lz` were in OTHER_LDFLAGS**. Adding `-lz`
  is harmless and resolves the 5 zlib symbols.
- `libboringssl.tbd` — exports BoringSSL symbols (`BORINGSSL_*`,
  not `SSL_*` / `ERR_*`). Crystal's `LibSSL` bindings call the
  OpenSSL ABI by name and will not link against boringssl.

No `libssl.tbd` or `libcrypto.tbd` exists in the SDK. The iOS Simulator
SDK has never shipped OpenSSL.

### Resolution paths (none in scope for build-config-only)

1. **Cross-compile OpenSSL for iOS Simulator** and add to
   `/tmp/crystal-cross-deps/ios-simulator/lib`, then add `-lssl
   -lcrypto -lz` to OTHER_LDFLAGS. The brief explicitly forbids this
   ("Don't freelance an OpenSSL cross-compile").

2. **Conditional `{% unless flag?(:ios) %}` guards** around the HTTP /
   SSL requires in `src/components/reactive/` so the iOS cross-compile
   does not pull them in. This is the right long-term fix — the
   reactive HTTP handler is never called on iOS — but it is production
   code change and the brief says "No production-code changes. This is
   build-config-only."

3. **Make `src/ui.cr` not require `web_renderer` when `flag?(:ios)`**.
   Same constraint — production code change.

### Recommendation for Phase 4

Option 2 (conditional guards) is correct architecturally. The
reactive WebSocket handler is a web-only feature; iOS / macOS native
hosts never instantiate `ReactiveSession`. Wrap the
`require "./components/reactive/*"` block in
`{% unless flag?(:ios) || flag?(:android) %}` and the entire blocker
disappears. This should be done as a Phase 4 (or follow-up
Remediation 6) task; it is one file edit in `src/components.cr` plus
a smoke verification.

---

## What Validator iter 6 should know

- **Reactive bridge link succeeded.** All 15 `apsk_*` reactive symbols
  resolve. The `-Wl,-force_load,...swiftkit_simulator.a` plus
  `-framework SwiftUI -framework Combine` wiring works.

- **iOS app link still fails**, but on pre-existing OpenSSL/zlib refs
  unrelated to the reactive bridge. This is **not a regression of
  Remediation 5** — it would have surfaced the first time anyone tried
  to link the iOS app on a machine with iOS 26.5 SDK and an actual
  simulator destination. The macOS host links because macOS ships
  `/usr/lib/libssl.dylib` and `/usr/lib/libz.dylib` in the system
  search path.

- **iOS XCUITest BX1 not run.** `xcodebuild test
  -only-testing:CrystalHIGHostUITests/Phase03BehaviorTests/testBX1_action_tap_probe`
  cannot run until the link blocker is resolved.

- **macOS BX1 invariant is intact.** Remediation 4's macOS evidence
  (`crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr
  -Dmacos ...`) still observes `"0" → "1" → "2" → "3"` on the counter
  label. The reactive bridge works end-to-end on macOS. The iOS path
  is build-blocked, not behavior-blocked.

- **No production-code or macOS changes** were made in this
  remediation. The only tracked diff is the OTHER_LDFLAGS extension in
  `samples/cross_platform/ios_host/project.yml`.

---

## Commits landed (Remediation 5)

- `[Phase 3 Remediation 5] Link swiftkit_simulator.a + SwiftUI/Combine
  into iOS CrystalHIGHost (OTHER_LDFLAGS)` — `project.yml` edit.

The other two commits the dispatch envisioned
(`build_crystal_lib.sh` extension and `.xcodeproj` regeneration) were
not needed: `build_crystal_lib.sh` was already producing
`swiftkit_simulator.a`, and `.xcodeproj` is gitignored.
