# Static text label with semantic typography and accessibility metadata.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"
require "../theme"
{% if flag?(:macos) || flag?(:ios) %}
  require "../native/swiftkit_bridge"
{% end %}

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A read-only text label.
  #
  # Displays a single or multi-line string with configurable font,
  # color, alignment, and line limit.
  class Label < View
    # The text content to display
    #
    # Setting `text` after the renderer has emitted the SwiftUI hosting
    # view propagates through the SwiftKit bridge: the matching
    # `APSKLabelState.text` `@Published` field updates and SwiftUI
    # re-renders the hosted `Text` without a tree rebuild. Setters issued
    # before the view has been rendered are simply stored on the property;
    # the next render seeds the reactive state from the new value.
    getter text : String

    def text=(new_text : String) : String
      @text = new_text
      {% if flag?(:macos) || flag?(:ios) %}
        if sh = @swiftkit_state_handle
          LibSwiftKitBridge.apsk_label_set_text(sh, new_text.to_unsafe)
        end
      {% end %}
      new_text
    end

    # Font specification for the label text
    property font : Font = Font.new

    # Text color (brand / explicit RGBA override). Only consulted when
    # `text_color_role` is nil — otherwise the role resolves to the
    # appearance-tracking system color and this RGBA is ignored.
    property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)

    # Semantic Apple label-color role. When set, the AppKit / UIKit renderer
    # resolves to `NSColor.labelColor` / `UIColor.labelColor` (and secondary
    # / tertiary / quaternary variants) at render time, tracking appearance
    # automatically. Default is `LabelRole::Primary` — the beauty-by-default
    # HIG render. A host that wants a brand color sets `text_color_role = nil`
    # and sets `text_color` to the brand RGBA. Web / Android renderers ignore
    # this field.
    property text_color_role : LabelRole? = LabelRole::Primary

    # Text alignment within the label bounds
    property text_alignment : Alignment = Alignment::Leading

    # Maximum number of lines (0 means unlimited)
    property number_of_lines : Int32 = 0

    # Preferred wrapping width for native multi-line layout engines.
    #
    # UIKit's UILabel uses this to compute a stable multi-line intrinsic
    # content size when it is inside exact-width containers like UI::Card.
    # Other renderers may ignore it.
    property preferred_max_layout_width : Float64? = nil

    # Phase 6.11 — strikethrough toggle. Renderers map to:
    #   SwiftUI / UIKit / AppKit : `.strikethrough(true)`
    #   Web                       : `text-decoration: line-through`
    # Default `false` keeps existing labels visually unchanged. The
    # Voyager Todos screen sets this `true` on a row's title label when
    # the underlying todo is `completed`.
    property strikethrough : Bool = false

    def initialize(@text : String)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
