# UI::StatusBars

Status: implemented, validation skipped.

This row stays shell-level. On iOS and iPadOS the visible status bar is
system-controlled, so the shard exposes only appearance policy. On macOS the
repo also offers a lightweight `UI::StatusBar` helper for shell status items,
and that helper now installs into `NSStatusBar.systemStatusBar`.

Current judgment:

- status-bar policy: useful and minimal
- macOS status item: useful shell companion
- system chrome: owned by the OS shell
- screenshots: not applicable
