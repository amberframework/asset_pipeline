---
slug: search-fields
ui_view: UI::SearchField
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/search-fields.md
validation_report: ../validation/reports/search-fields.md
---

# UI::SearchField

> A text input that lets people search a collection of content for specific
> terms, rendered by default as NSSearchField on macOS (rounded-rect bezel,
> system-standard search chrome) and UISearchBar on iOS 26 (pill shape with
> secondarySystemFill background and system-tint cancel button).

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A search field is not a generic text input -- it carries semantic meaning: "the
content below me is filterable." The leading magnifying-glass icon, the
contextual placeholder text, and the trailing clear button together signal to
users that this control narrows a collection rather than accepting arbitrary
input. Use `UI::SearchField` when the purpose is clearly filtering or locating
items in a list, sidebar, or view; use `UI::TextField` for everything else.

The HIG is specific about what this field should NOT do: the placeholder text
must describe the content domain, not simply say "Search." A field whose
placeholder reads "Shows, Movies, and More" tells the user immediately what the
search covers. A placeholder that reads "Search" is universally present and
conveys nothing. Per the HIG: "avoid using a term like Search for placeholder
text because it doesn't provide any helpful information."

(HIG: "Display placeholder text that describes the type of information people
can search for." -- Search fields / Best practices.)

## Quickstart

```crystal
# Empty state -- leading magnifying-glass + descriptive placeholder text.
sf = UI::SearchField.new("Shows, Movies, and More")
sf.accessibility_label = "Content search field"

# Filled state -- query text in primary color, trailing clear button appears.
sf_filled = UI::SearchField.new("Shows, Movies, and More")
sf_filled.text = "Apple HIG"
sf_filled.accessibility_label = "Content search field"

# With live-update callback (called on every keystroke).
sf_live = UI::SearchField.new("Shows, Movies, and More") do |query|
  filter_results(query)
end
sf_live.accessibility_label = "Live search field"

# iOS: show Cancel button when field has focus.
sf_ios = UI::SearchField.new("Shows, Movies, and More")
sf_ios.shows_cancel_button = true
sf_ios.accessibility_label = "Search with cancel"
```

Renders: NSSearchField on macOS (rounded-rect bezel, magnifying-glass leading
button, xmark.circle.fill clear button in filled state, all provided by AppKit).
UISearchBar on iOS 26 (pill-shaped secondarySystemFill background, magnifying-
glass leading icon, xmark.circle.fill clear button inside the pill, optional
Cancel text button outside the pill in system tint).

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `placeholder` | `String` | `"Search"` | Placeholder text visible when the field is empty; HIG mandates this describes the content domain, not just "Search" |
| `text` | `String` | `""` | The current query string; non-empty value shows the trailing clear button |
| `shows_cancel_button` | `Bool` | `true` | iOS only: whether UISearchBar shows the "Cancel" text button trailing outside the pill; ignored by NSSearchField on macOS |
| `is_searching` | `Bool` | `false` | Informational flag for the host view to know if a search is active; does not directly alter rendering but can be read to show/hide a spinner |
| `on_change` | `Proc(String, Nil)?` | `nil` | Called on every keystroke (NSSearchField: via NSControl target-action; UISearchBar: via UISearchBarDelegate) |
| `on_submit` | `Proc(String, Nil)?` | `nil` | Called when the user presses Return / Search key |
| `on_cancel` | `Proc(Nil)?` | `nil` | Called when the user taps the Cancel button on iOS |

**Theming**: `UI::SearchField` uses system-provided colors and does not
consume `UI::Theme` tokens directly. The field background (NSSearchField bezel
/ UISearchBar pill) tracks the system appearance automatically. See
`foundations/color-and-theming.md` for how to override `background` via the
base `UI::View` property if a branded background is required (note the caveats
below).

## Light / dark appearance notes

**macOS light:** NSSearchField renders with a rounded-rect bezel in
NSColor.controlBackgroundColor (near-white, ~0.93 RGB inside the bezel) set by
AppKit automatically. Bezel border is NSColor.separatorColor (light, ~0.77 RGB),
1pt. Leading magnifying-glass in NSColor.secondaryLabelColor (light, ~0.42 RGB).
Placeholder text in NSColor.placeholderTextColor (light). Query text in
NSColor.textColor (light, ~0.0 RGB), contrast ~21:1 against bezel background.
Trailing clear button (xmark.circle.fill) in NSColor.secondaryLabelColor when
the field contains text. NSAppearance is applied via `performAsCurrentDrawingAppearance`
which ensures the control draws in the Aqua appearance regardless of host context.

**macOS dark:** NSSearchField bezel tracks NSAppearanceName.darkAqua. Bezel
interior becomes darker (~0.18 RGB). Border adjusts to NSColor.separatorColor
dark (~0.25 RGB). Magnifying-glass and clear button in NSColor.secondaryLabelColor
dark (~0.56 RGB), readable against the dark interior. Query text in
NSColor.textColor dark (near-white, ~1.0 RGB), contrast ~17:1.

**iOS light:** UISearchBar pill background UIColor.secondarySystemFill (light,
~0.95 RGB). Leading magnifying-glass in UIColor.secondaryLabel (light, ~0.42 RGB).
Placeholder in UIColor.placeholderText (light). Query text in UIColor.label
(light, ~0.0 RGB), contrast ~21:1. Trailing clear button xmark.circle.fill in
UIColor.label. Cancel text in UIColor.link / UIColor.tintColor (system blue,
~0.0/0.48/1.0 RGB) when showsCancelButton is YES.

**iOS dark:** UISearchBar pill background UIColor.secondarySystemFill dark
(~0.11 RGB against ~0.05 RGB window background). Pill is distinguishable by
shape rather than high contrast -- this is the intended Apple dark-mode treatment.
Magnifying-glass in UIColor.secondaryLabel dark (~0.56 RGB). Query text in
UIColor.label dark (~1.0 RGB), contrast ~21:1. Clear button white-outlined
circle visible against dark field interior. Cancel text in UIColor.link dark
(~0.26/0.56/1.0 RGB), distinguishable from label text.

**SF Symbols used:** The magnifying-glass is the native system-provided "Search"
button on NSSearchField (AppKit-internal) and the `searchBarStyle` icon on
UISearchBar (UIKit-internal). Neither renderer explicitly loads an SF Symbol --
AppKit and UIKit own the icon rendering. The clear button uses the system xmark
glyph also owned by the platform. No `UI::Image` call is needed.

**Contrast caveats for brand overrides:** If you set a custom `background` color
on `UI::SearchField`, the system-provided placeholder and icon colors continue
to use their system semantic values. A dark brand background combined with
light system secondary label may produce insufficient contrast for the
magnifying-glass icon. Test both appearances after any `background` override.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up
HIG's legibility, hit targets, or appearance-tracking._

**Swap the tint accent (iOS Cancel button color) to your brand primary.**
```crystal
# UISearchBar inherits tintColor from its UIWindow / UIViewController.
# To set a per-instance tint on iOS, override the background on the enclosing
# view and let UISearchBar's Cancel button color follow.
# The preferred approach is to set UIWindow.tintColor in your app delegate
# (Swift/ObjC side), which UISearchBar respects automatically.
# On the Crystal side, keep the HIG default; hit targets (44pt height), spacing,
# and magnifying-glass chrome all remain HIG-correct.
sf = UI::SearchField.new("Search recipes")
sf.shows_cancel_button = true
# No Crystal-level tint override needed for the Cancel button: it inherits
# from the window's tintColor set on the Swift side.
sf.accessibility_label = "Recipe search"
```

**Replace the glass material with a flat brand surface (macOS only).**
```crystal
# NSSearchField by default draws its own bezel via AppKit's NSTextFieldCell.
# To give the search field a flat brand background instead, set background:
# on the surrounding container and rely on the field's own bezel for delineation.
# WARNING: overriding the bezel itself requires descending into NSTextFieldCell
# and is outside the UI::SearchField API surface.  For a branded but flat
# container around the field, wrap it in a UI::ZStack with a brand color:
brand_container = UI::ZStack.new
brand_container.background = UI::Color.new(0.12, 0.47, 0.71)  # brand blue
brand_container.corner_radius = 8.0

sf = UI::SearchField.new("Search by ingredient")
sf.accessibility_label = "Ingredient search"
brand_container << sf
# The NSSearchField's own bezel shows through the ZStack on macOS.
# Legibility warning: a dark brand background with the field's default light
# bezel may look visually mismatched; test in both appearances.
```

**Override typography while keeping HIG spacing.**
```crystal
# UI::SearchField does not expose a font knob (NSSearchField / UISearchBar
# own their internal typography).  To approximate a larger or smaller query
# text size, pair the search field with a UI::Label that shows the active
# query in a branded font for display purposes, while the hidden SearchField
# handles input:
sf = UI::SearchField.new("Search")
sf.accessibility_label = "Search input"

query_display = UI::Label.new("Apple HIG")
query_display.font = UI::Font.new(size: 24.0, weight: :light)
# query_display updates via sf.on_change callback.
# This is an advanced pattern for designs that want a large branded query
# display separate from the compact input field itself.
```

## Feel recipes
Short examples that map design intent to code.

**"I want the search field to start scanning immediately as the user types"**
-> Set `on_change` to a proc that calls your filter/search function. NSSearchField
fires NSControlTextDidChangeNotification on every keystroke; UISearchBar fires
`searchBar(_:textDidChange:)`. Both are wired through the Crystal `on_change` proc.
```crystal
sf = UI::SearchField.new("Filter items") do |query|
  list_view.filter(query)
end
sf.accessibility_label = "Item filter"
```

**"I want to show search suggestions as the user types"**
-> Place a `UI::ListView` immediately below the `UI::SearchField` in a `UI::VStack`
and toggle its `hidden` property based on whether the query is empty. Populate
the list via the `on_change` callback.
```crystal
sf = UI::SearchField.new("Search contacts") do |query|
  suggestions_list.hidden = query.empty?
  suggestions_list.items = ContactIndex.suggest(query)
end
sf.accessibility_label = "Contact search"
suggestions_list = UI::ListView.new
suggestions_list.hidden = true
container = UI::VStack.new(spacing: 0.0)
container << sf
container << suggestions_list
```

## What happens on each platform
- **iOS 26**: UISearchBar with `searchBarStyle = .default` -- pill-shaped
  secondarySystemFill background, magnifying-glass leading icon provided by
  UIKit, xmark.circle.fill clear button when text is present, optional "Cancel"
  text button in window tint color when `showsCancelButton` is YES.
- **iPadOS 26**: Same UISearchBar as iOS; placement follows HIG guidance of
  trailing-edge toolbar for global search, inline above lists for local filter.
  On iPad in split-view compact mode the field width adapts to the column width.
- **macOS 26**: NSSearchField with rounded-rect bezel (Aqua / DarkAqua),
  built-in magnifying-glass NSSearchFieldCell button, xmark.circle.fill clear
  button when field has text. Appearance tracks NSAppearance automatically.
  NSSearchField does not have a "Cancel" button; the user presses Escape to
  clear the field.

## HIG citations (validated)
- Search fields -- Abstract: "A search field is an editable text field that
  displays a Search icon, a Clear button, and placeholder text where people
  can enter what they are searching for."
- Search fields -- Best practices: "Display placeholder text that describes
  the type of information people can search for. For example, the Apple TV
  app includes the placeholder text Shows, Movies, and More. Avoid using a
  term like Search for placeholder text because it doesn't provide any helpful
  information."
- Search fields -- Best practices: "If possible, start search immediately when
  a person types. Searching while someone types makes the search experience
  feel more responsive because it provides results that are continuously
  refined as the text becomes more specific."
- Search fields -- Best practices: "Consider showing suggested search terms
  before search begins, or as a person types."
- Search fields -- Platform considerations -- iPadOS, macOS: "Put a search
  field at the trailing side of the toolbar for many common uses."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/search-fields.md](../validation/reports/search-fields.md)

## Related
- `UI::TextField` -- when the input is not for search/filter purposes
- `UI::ListView` -- the most common sibling: pair a SearchField above a ListView
  to filter its rows
- `recipes/filtered-list.md` -- multi-component pattern: SearchField + ListView
  + empty state label
