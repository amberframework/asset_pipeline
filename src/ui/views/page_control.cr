# Horizontal page-indicator dots commonly used under paged scroll views.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A horizontal row of dot indicators showing position in a paged list.
  #
  # Maps to UIPageControl on iOS/iPadOS. On macOS (where no native NSPageControl
  # exists), the AppKit renderer synthesizes an NSStackView of small circle
  # CALayer views — one filled, others outlined.
  #
  # HIG: "A page control displays a row of indicator images, each of which
  # represents a page in a flat list." — Page controls, abstract.
  #
  # HIG: "Center a page control at the bottom of the view or window." The host
  # is responsible for positioning; this view provides the control itself.
  class PageControl < View
    # Total number of pages (dots) to display.
    property total : Int32

    # Zero-based index of the currently selected page (filled dot).
    property current : Int32

    # Optional tint color for the current-page indicator.
    # When nil, UIPageControl defaults to UIColor.label (system-tracked).
    # HIG: "Avoid coloring indicator images. Custom colors can reduce the
    # contrast that differentiates the current-page indicator."
    property tint_color : Color? = nil

    # Optional tint color for non-current page indicators.
    # When nil defaults to a translucent version of the tint_color / system default.
    property page_indicator_tint_color : Color? = nil

    # Background style on iOS 14+.
    # :automatic  — shows background only during interaction (default).
    # :prominent  — always shows background; use when this is the primary nav.
    # :minimal    — never shows background; position-only display.
    property background_style : Symbol = :automatic

    def initialize(@total : Int32, @current : Int32 = 0)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
