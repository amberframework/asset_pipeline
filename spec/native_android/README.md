# spec/native_android/

Platform-aware spec lane for Android-only specs.

**Status (Phase 10C.0):** empty. The Android native build path is
currently `attempted-blocked` per
`docs/initiative-cross-platform-ui/native-compile-matrix.md`
(`acrystal build -Dandroid` fails on `require "c/sys/epoll"` because the
`agent-crystal` Homebrew tap installs the macOS-targeted stdlib only;
Android requires a Linux Crystal compiler + the Android NDK).

When Android specs land, they go here. Run with `make test-android`
(today a placeholder that prints the matrix doc URL).

**Classification (per architecture-decisions.md Decision 5):** a spec
belongs in `spec/native_android/` when it exercises a
`flag?(:android)`-gated view, renderer, or JNI bridge path AND the
Android-specific assertions are the substantive payload of the file.
Multi-platform contract specs that pass under plain `crystal spec`
belong in `spec/web/`.

The Family 5 directory rule (`SpecPlatformDirectoryRule`) treats this
directory as an allowed location even when empty.

**Expected next landings:** Phase 10B.1c (Android Material 3 swipe
integration) and Phase 10B.3.x (Class C feature slices that include
Android JNI bridges).
