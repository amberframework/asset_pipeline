---
slug: virtual-keyboards
ui_view: UI::VirtualKeyboards
priority: P2
platforms: [iOS, iPadOS, tvOS, visionOS]
hig_page: ../../../apple-hig/pages/virtual-keyboards.md
validation_report: ../validation/reports/virtual-keyboards.md
---

# UI::VirtualKeyboards

> A system input concept rather than an in-app view. asset_pipeline should not
> render keyboard chrome as a component for its current macOS/iOS preview work;
> it should only describe keyboard intent when a host surface needs it.

## Feel of the flow

The keyboard is part of text input infrastructure, not a card, panel, or scene
that the app should fake. For this shard, the honest boundary is to keep the
keyboard itself system-owned and focus on the fields, focus states, and input
behavior around it.

## What happens on each platform

- **iOS / iPadOS**: System-owned keyboard chrome and input mode behavior.
- **tvOS / visionOS**: System input surfaces as defined by the host platform.
- **macOS**: Not an in-app primitive in this shard's target set; text input
  uses the host platform's own keyboard model.
- **Validation**: Skipped for screenshots because the keyboard is not a
  renderable in-app component.

## HIG citations (validated)

- Let the system own keyboard presentation.
- Design around focus, input mode, and text entry ergonomics.
