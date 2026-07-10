---
title: Sound and motion
topic: feedback
hig_pages:
  - motion.md
  - feedback.md
---

# Sound and motion

## What it means

Motion, haptics, and sound are feedback — they confirm an action happened or
communicate state change. Apple's guidance treats them as part of the same
system: a haptic tap on button activation, a springy transition when a sheet
appears, a subtle sound only when the user has actively engaged (never for
passive notifications without opt-in).

Three rules worth internalizing:

- **Spring over linear for interactive motion.** When the user initiates a
  transition (tap, drag, sheet dismissal), the motion should feel rubbery and
  physical — not a straight-line tween. System-provided transitions already do
  this; custom transitions should match.
- **Haptics on commit, not on scroll.** A haptic tap at the moment an action
  commits (button tap, toggle flip, swipe-to-delete confirmation) reinforces
  the interaction. Haptic noise during scroll or hover is irritating.
- **Sound requires opt-in context.** Play audio feedback only where the user
  has invoked it (recording a voice memo, completing a timer). Never surprise
  the user with sound on app launch, notification arrival, or passive UI
  events.

Respect Reduce Motion. When the setting is on, reduce the intensity or
duration of custom animations — or swap to a crossfade entirely.

## How it's expressed in asset_pipeline

**Motion and haptic APIs are not yet in asset_pipeline.** This section describes
the expected shape rather than existing functionality — treat it as a planned
surface rather than a reference.

Today:

- There is no `UI::Animation` / `UI::Transition` type.
- There is no haptic API. Buttons fire their `on_tap` handler; there's no
  hook to request a haptic.
- There is no sound-feedback API.

What happens today is that each renderer passes through to the native platform
transitions. When you present a `UI::Sheet`, the iOS renderer calls
`present(_:animated:completion:)` with `animated: true` — you get the system's
default springy sheet transition, including the Reduce Motion behavior, for
free. Same for popover, alert, and navigation-stack pushes.

This means: today, **use system-provided containers** and you inherit correct
motion and haptics. Don't try to hand-roll custom transitions in Crystal — you
won't have the primitives to do it well.

### Planned surface

When the animation API lands, expect something shaped like:

```crystal
# Planned — not yet implemented
UI::Animation.spring(response: 0.4, damping: 0.8) do
  my_view.opacity = 1.0
  my_view.minimum_height = 200.0
end

UI::Haptic.impact(.light)  # on commit
UI::Haptic.selection        # on segmented-control change
UI::Haptic.notification(.success)  # after successful save
```

And Reduce Motion handling will be automatic:

```crystal
# Planned — the animation is canceled or crossfaded
# when UIAccessibility.isReduceMotionEnabled is true.
```

Until those land, rely on native defaults and don't fight them.

## HIG citations

- **Motion**: use motion to "convey a sense of realism and continuity,"
  respect Reduce Motion, favor spring curves over linear for user-initiated
  transitions. (`pages/motion.md`)
- **Feedback**: haptic feedback should align with user action and system
  conventions; don't invent new haptic semantics when a system one exists.
  (`pages/feedback.md`)
- **Accessibility → Motion**: honor the Reduce Motion setting — provide a
  reduced or disabled variant of any custom animation.
  (`pages/accessibility.md`)
