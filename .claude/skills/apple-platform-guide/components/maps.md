---
slug: maps
ui_view: UI::MapView
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/maps.md
validation_report: ../validation/reports/maps.md
---

# UI::MapView

> A native map surface for contextual geography, routing, and place detail. The
> component renders with `MKMapView` on iOS/iPadOS/macOS and should feel
> interactive first, decorated second.

## Feel of the flow

Reach for `UI::MapView` when location is the content, not a badge attached to
something else. A map should give people immediate orientation, a clear sense of
scale, and just enough annotation to support the task at hand. The HIG is blunt
about this: noninteractive chrome that sits on top of the map should stay quiet,
because people expect the map itself to pan, zoom, and remain legible.

Use it for venue context, neighborhood overviews, pickup / dropoff flows, route
inspection, or place selection. Do not use it as a decorative thumbnail when a
plain image would communicate the same information with less noise.

## Quickstart

```crystal
map = UI::MapView.new
map.latitude = 37.8024
map.longitude = -122.4058
map.zoom_level = 12.5
map.map_type = :standard
map.annotations << UI::MapAnnotation.new(
  latitude: 37.8024,
  longitude: -122.4058,
  title: "Coit Tower",
  subtitle: "Neighborhood walk"
)
map.accessibility_label = "Map centered on Coit Tower"
```

Renders as a live `MKMapView` on macOS, iOS, and iPadOS. No Liquid Glass
material is applied; maps are content surfaces, not presentation chrome.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `latitude` | `Float64` | `0.0` | Center latitude for the initial region. |
| `longitude` | `Float64` | `0.0` | Center longitude for the initial region. |
| `zoom_level` | `Float64` | `10.0` | Converted into a region span; larger values read as a tighter view. |
| `map_type` | `Symbol` | `:standard` | `:standard`, `:satellite`, or `:hybrid`. |
| `shows_user_location` | `Bool` | `false` | Enables the native user-location affordance. |
| `annotations` | `Array(MapAnnotation)` | `[]` | Adds native map pins with title / subtitle. |

## Light / dark appearance notes

The map styling itself belongs to MapKit. Your job is to make the surrounding
composition feel disciplined:

- Keep edge chrome out of the way so the map remains the primary surface.
- Let annotations do the emphasis work instead of layering cards and labels
  directly on top of the region.
- Use generous corner radius only when the map is clearly inset into a larger
  layout; otherwise let the surface breathe edge-to-edge.

The default `:standard` map type usually gives the best match to Apple's own
system map hierarchy. Switch to `:satellite` or `:hybrid` only when the task
benefits from imagery, not because it feels more dramatic.

## Customization / brand override

**Choose the map emphasis that supports the information on top of it.**
If your app has dense overlays or custom pins, prefer a calmer map treatment and
fewer labels. The HIG calls this out directly: the more information you add, the
more carefully you need to manage visual competition.

**Use annotations sparingly and intentionally.**
Two or three clear pins beat a noisy field of markers. Clustered, purposeful
annotations feel senior. Scattershot pins feel like debug output.

## What happens on each platform

- **iOS 26 / iPadOS 26**: Native `MKMapView` with gesture-driven pan / zoom /
  rotation. The component remains interactive by default.
- **macOS 26**: Native `MKMapView` with the same annotation model and a wider
  natural viewport for route or place-detail studies.

## HIG citations (validated)

- Maps: "In general, make your map interactive."
- Maps: "Pick a map emphasis style that suits the needs of your app."
- Maps: "Cluster overlapping points of interest to improve map legibility."

Validation report with side-by-side captures:
[validation/reports/maps.md](../validation/reports/maps.md)

## Related

- `UI::Popover` for place-detail cards or contextual filters anchored to map
  content.
- `UI::Sheet` for bottom cards that complement a map without covering it
  permanently.
