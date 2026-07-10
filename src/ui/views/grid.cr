# Two-dimensional layout that arranges children in rows and columns.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Grid — Two-dimensional layout that arranges children in rows and columns.
  class Grid < View
    record Column,
      alignment : Alignment = Alignment::Leading,
      minimum_width : Float64? = nil

    property children : Array(Array(View)) = [] of Array(View)
    property columns : Array(Column) = [] of Column
    property row_spacing : Float64 = 8.0
    property column_spacing : Float64 = 8.0
    property alignment : Alignment = Alignment::Leading

    def initialize(@columns : Array(Column) = [] of Column)
    end

    # Add a row of views
    def add_row(views : Array(View))
      @children << views
    end

    # Convenience to add a row with a block
    def add_row(&)
      row = [] of View
      yield row
      @children << row
    end

    def row_count : Int32
      @children.size
    end

    def column_count : Int32
      columns.empty? ? (@children.first?.try(&.size) || 0) : columns.size
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
