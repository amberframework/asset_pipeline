# iOS Voyager Todo Editor layout capture — UNAVAILABLE

The iOS app crashes silently when launched with
`VOYAGER_ROOT_SLUG=voyager-todo-editor` (verified 2026-05-23 via
both `SIMCTL_CHILD_VOYAGER_ROOT_SLUG` env and `-VoyagerRoot
voyager-todo-editor` launch arg). The app process spawns
(PID assigned), the SwiftUI scene logs Window did become application
key, then the process exits before the first screenshot can capture
the rendered editor screen. No crash indicators in `simctl spawn
log show` (no signal, no exception, no error keywords).

This is a NEW iOS-only bug surfaced during Rem 2 evidence capture
that is OUT OF SCOPE for Rem 2 (the brief covers sign-in / todos /
settings on iOS; editor was not in the explicit acceptance gate).
The macOS Voyager Todo Editor renders correctly — see
`phase-06.10-remediation-2-layout-macos-voyager-todo-editor.png`
in this same directory.

Investigation deferred to architect's next-phase scoping.
