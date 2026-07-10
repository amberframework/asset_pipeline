# Boxed surface that groups related content with optional title and elevation.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Card — Boxed surface that groups related content with optional title and elevation.
  class Card < View
    property content : View? = nil
    property elevation : Float64 = 1.0
    property is_outlined : Bool = false

    # Optional introductory title displayed above / at the top of the card.
    # HIG Boxes - Content: "Provide a succinct introductory title if it
    # helps clarify the box's contents." On macOS the string is forwarded
    # to -[NSBox setTitle:]; on iOS the renderer prepends a headline
    # UILabel at the top of the content stack.
    property title : String? = nil

    # Material token selecting the grouped-container fill on iOS.
    # :secondary -> +[UIColor secondarySystemBackgroundColor]
    # :tertiary  -> +[UIColor tertiarySystemBackgroundColor]
    # Ignored on macOS (NSBox chrome is fixed by boxType).
    property material : Symbol = :secondary

    # Content padding inside the card surface.
    # Default: 21pt all sides (Fibonacci-golden Lg token).
    # HIG Boxes: content should not kiss the card corners -- use Lg (21pt) so
    # title and body have breathing room from all four edges.
    # Override with EdgeInsets.new(...) for tighter or wider insets.
    property content_padding : EdgeInsets = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)

    def initialize(@content : View? = nil)
      # Default container-query root name: enables descendant
      # `@container card (...)` rules and lets `render(Card.new)` emit
      # `container-type: inline-size; container-name: card;` inline so
      # the per-element render-output rubric finds the contract without
      # registered class CSS. Callers may override by assigning
      # `container_query_name = nil` or another name.
      @container_query_name = "card"
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
