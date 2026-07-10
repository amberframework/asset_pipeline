# Scrolling vertical list of rows with native idiomatic chrome.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A scrollable list of items with optional sections.
  class ListView < View
    # A section in the list
    record Section,
      header : String? = nil,
      items : Array(View) = [] of View,
      footer : String? = nil

    # List sections (use a single section for flat lists)
    property sections : Array(Section) = [] of Section

    # Visual style
    property style : ListStyle = ListStyle::Plain

    # Layout mode: List (vertical rows) or Grid (multi-column grid).
    # Grid maps to NSCollectionView on macOS and UICollectionView on iOS.
    # Default is List for backward compatibility.
    property layout : ListLayout = ListLayout::List

    # Number of columns when layout == ListLayout::Grid.
    # Ignored in List layout mode. Typical HIG photo grids use 2–4 columns.
    property columns : Int32 = 3

    # Gap between grid cells in points (both horizontal and vertical).
    # Ignored in List layout mode.
    property item_spacing : Float64 = 8.0

    # Whether to show separators between items
    property shows_separators : Bool = true

    # Callback when an item is tapped (receives section index, item index)
    property on_item_tap : Proc(Int32, Int32, Nil)? = nil

    def initialize(@sections : Array(Section) = [] of Section, @style : ListStyle = ListStyle::Plain, @layout : ListLayout = ListLayout::List, @columns : Int32 = 3)
    end

    # Convenience: create a flat list from an array of views
    def self.flat(items : Array(View), style : ListStyle = ListStyle::Plain) : ListView
      list = new(style: style)
      list.sections = [Section.new(items: items)]
      list
    end

    # Total number of items across all sections
    def item_count : Int32
      sections.sum(&.items.size)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
