# UI::Notifications

Status: implemented, validation skipped.

This row is intentionally shell-level rather than in-app. The shard now owns a
real UserNotifications bridge for local scheduling plus deterministic export
helpers for notification categories, actions, and Swift registration scaffold
code, while banners and Notification Center presentation remain system-owned.

Current judgment:

- runtime scheduling bridge: real and useful
- notification category/action export: present
- screenshots: not applicable
