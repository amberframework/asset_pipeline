# Native chart view wrapping Swift Charts on Apple platforms and the equivalent on other targets.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  record ChartDataPoint,
    label : String = "",
    value : Float64 = 0.0,
    color : Color? = nil

  # ChartView — Native chart view wrapping Swift Charts on Apple platforms and the equivalent on other targets.
  class ChartView < View
    property chart_type : Symbol = :bar # :bar, :line, :pie
    property title : String = ""
    property data_points : Array(ChartDataPoint) = [] of ChartDataPoint
    property show_legend : Bool = true
    property show_grid : Bool = true

    def initialize
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
