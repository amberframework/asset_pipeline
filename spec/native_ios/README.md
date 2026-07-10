# spec/native_ios/

Platform-aware spec lane for iOS-only specs.

**Status (Phase 10C.0):** empty. The iOS native build path is currently
`attempted-blocked` per `docs/initiative-cross-platform-ui/native-compile-matrix.md`
(the standalone `acrystal spec -Dios` path pulls macOS-built libgc; the
repo's working iOS build uses `--cross-compile` + `libcascade.a` + Xcode
via `samples/initiative-cross-platform-ui-demo/ios/build_crystal_lib.sh`).

When iOS specs land, they go here. Run with `make test-ios` (today a
placeholder that prints the matrix doc URL).

**Classification (per architecture-decisions.md Decision 5):** a spec
belongs in `spec/native_ios/` when it exercises a `flag?(:ios)`-gated
view, renderer, or bridge path AND the iOS-specific assertions are
the substantive payload of the file. Multi-platform contract specs
that pass under plain `crystal spec` belong in `spec/web/`.

The Family 5 directory rule (`SpecPlatformDirectoryRule`) treats this
directory as an allowed location even when empty.

**Expected next landings:** Phase 10B (Tier 2 native iOS widgets) and
Phase 10D (Voyager + intent exerciser hands-on test) may add iOS specs
here once the iOS spec runner is unblocked.
