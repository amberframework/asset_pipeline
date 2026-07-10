# Horizontal segmented selector for picking one option from a small set.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # SegmentedControl — Horizontal segmented selector for picking one option from a small set.
  class SegmentedControl < View
    property segments : Array(String) = [] of String
    property selected_index : Int32 = 0
    property on_change : Proc(Int32, Nil)? = nil

    def initialize(@segments : Array(String) = [] of String, @selected_index : Int32 = 0)
    end

    def initialize(@segments : Array(String), @selected_index : Int32 = 0, &block : Int32 -> Nil)
      @on_change = block
    end

    def selected_segment : String?
      if selected_index >= 0 && selected_index < segments.size
        segments[selected_index]
      end
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
