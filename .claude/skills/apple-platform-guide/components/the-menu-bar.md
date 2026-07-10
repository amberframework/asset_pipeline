---
slug: the-menu-bar
ui_view: UI::MenuBar
priority: P2
platforms: [macOS]
hig_page: ../../../apple-hig/pages/the-menu-bar.md
validation_report: ../validation/reports/the-menu-bar.md
---

# UI::MenuBar

> A shell-level description of the top-level menu structure your macOS app
> wants to install. The visible chrome still belongs to AppKit, but
> `UI::MenuBar` now installs that structure into the host application's main
> menu instead of stopping at a passive model.

## Feel of the flow

The menu bar is not part of the in-app content tree. It is the application's
top-level command surface, so the model should stay explicit, shallow, and easy
to scan.

`UI::MenuBar` gives an app a structured way to describe menus such as File,
Edit, View, and Help without pretending that the menu bar itself is a normal
view.

## Quickstart

```crystal
menu_bar = UI::MenuBar.new

menu_bar.add_menu("File") do |menu|
  menu.add_item("New", icon: "doc")
  menu.add_item("Open...", icon: "folder")
  menu.add_separator
  menu.add_item("Close", icon: "xmark")
end

menu_bar.add_menu("Edit") do |menu|
  menu.add_item("Copy", icon: "doc.on.doc")
  menu.add_item("Paste", icon: "clipboard")
end

menu_bar.install
```

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `menus` | `Array(Menu)` | `[]` | Ordered top-level menus. |
| `Menu#title` | `String` | required | Top-level title such as `File` or `View`. |
| `Menu#menu` | `UI::ContextMenu` | required | Command list displayed for that title. |
| `is_installed` | `Bool` | `false` | Tracks whether the current definition has been installed into the host menu bar. |

## What happens on each platform

- **macOS**: `install` now turns the Crystal model into a real `NSMenu`
  hierarchy on the application's main menu.
- **iOS**: No in-app menu bar chrome; this stays macOS-focused.
- **Validation**: Skipped for screenshots because the menu bar is system
  chrome, not a content-view component.

## HIG citations (validated)

- The menu bar organizes app-wide commands.
- Keep top-level menu structure shallow and easy to scan.
