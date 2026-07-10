# Future Native Cascade Contract

Milestone 1 does not implement native renderer changes. Native renderers should
not be changed until the web proof is credible.

This is the shared contract future native work should honor.

## Cascade Order

1. Theme defaults
2. Component family defaults
3. Component variant
4. Instance overrides
5. Platform-specific patches

## Shared Intent

Native renderers should map semantic intent, not web CSS classes literally.

Examples:

- `danger.indicator` becomes a strong leading mark, destructive tint, or status
  accessory depending on platform conventions.
- `surface.elevated` becomes an equivalent grouped background/material/elevation.
- `border.focus` becomes the platform's accessible focus or keyboard highlight.
- `motion.duration.base` becomes the closest platform animation duration, or is
  disabled when reduced motion is active.

## Required Platform Decisions

For every built-in behavior that one platform provides and another lacks, the
renderer must document one of:

- equivalent behavior
- acceptable compromise
- explicit opt-out

Do this before native implementation, especially for navigation, dialogs,
focus, scroll behavior, row selection, chart accessibility, and font mapping.
