# UI::MenuBar

Status: implemented, validation skipped.

This row is intentionally shell-level rather than in-app. The Crystal API now
models top-level menus and installs them into the host application's main menu
on macOS. Screenshot validation remains skipped because the menu bar is system
chrome, not something the showcase host should fake inside the content tree.

Current judgment:

- menu structure: useful and minimal
- system chrome: owned by AppKit
- screenshots: not applicable
