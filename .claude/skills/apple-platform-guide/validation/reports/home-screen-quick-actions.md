# UI::HomeScreenQuickActions

Status: implemented, validation skipped.

This row is intentionally shell-level rather than in-app. The shard now owns a
real quick-actions catalog plus export helpers for manifest data and
`UIApplicationShortcutItems` plist fragments, while the long-press Home Screen
menu remains system-owned.

Current judgment:

- shortcut-item catalog: real and useful
- host export: present
- screenshots: not applicable
