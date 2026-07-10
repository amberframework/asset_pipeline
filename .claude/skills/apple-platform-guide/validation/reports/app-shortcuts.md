# UI::AppShortcuts

Status: implemented, validation skipped.

This row is intentionally shell-level rather than in-app. The shard now owns a
real App Shortcuts catalog plus export helpers for structured metadata and
deterministic AppIntents scaffold code, while the visible
Siri/Spotlight/Shortcuts surfaces remain system-owned.

Current judgment:

- shortcut catalog: real and useful
- host export + AppIntents scaffold: present
- screenshots: not applicable
