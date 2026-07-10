# Migration Notes

The alpha API can break. New examples should prefer canonical component
classes and variant parameters instead of preserving Bootstrap-like naming.

## Buttons

Before:

```html
<button class="btn btn-primary btn-lg">Save</button>
```

Now:

```crystal
Components::DesignSystem::Button.new(
  label: "Save",
  tone: "brand",
  emphasis: "solid",
  size: "lg"
)
```

Rendered direction:

```html
<button class="am-button am-button--brand am-button--solid am-button--lg">
  Save
</button>
```

## Cards

Before:

```html
<div class="card">
  <div class="card-body">...</div>
</div>
```

Now:

```crystal
card = Components::DesignSystem::Card.new(
  eyebrow: "Selected",
  title: "Strong state contract",
  selected: "true"
)
card << "Card content"
```

Rendered direction:

```html
<div class="am-card am-card--selected">
  <div class="am-card__body">...</div>
</div>
```

## Stimulus

Milestone 1 design-system helpers are vanilla JavaScript only. Existing
FrontLoader Stimulus docs are legacy framework-integration material, not the
canonical interaction direction for this web design-system proof.

## Charts

Existing examples that import Chart.js remain historical import-map examples.
The design-system proof uses first-party SVG for simple charts. If a full
chart library is needed later, isolate it behind a documented adapter and keep
the semantic wrapper.

## Legacy Examples

`examples/web_design_system_demo.cr` is the canonical Milestone 1 design-system
demo. Other examples in `examples/` predate this milestone and may still show
Stimulus, import-map, Chart.js, or Bootstrap-shaped patterns for legacy API
coverage. Treat those as historical integration examples, not the direction for
new design-system UI.
