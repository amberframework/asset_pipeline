# Read-only rich-text view supporting attributed runs and inline images.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # RichText — Read-only rich-text view supporting attributed runs and inline images.
  class RichText < View
    record Span,
      text : String = "",
      font : Font = Font.new,
      color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0),
      bold : Bool = false,
      italic : Bool = false,
      underline : Bool = false,
      strikethrough : Bool = false,
      link : String? = nil

    property spans : Array(Span) = [] of Span
    property text_alignment : Alignment = Alignment::Leading

    def initialize
    end

    def add_span(text : String, bold : Bool = false, italic : Bool = false, color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0))
      @spans << Span.new(text: text, bold: bold, italic: italic, color: color)
    end

    def plain_text : String
      spans.map(&.text).join
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
