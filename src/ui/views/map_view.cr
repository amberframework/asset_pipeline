# Native map view bridging to MapKit on Apple platforms.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  record MapAnnotation,
    latitude : Float64,
    longitude : Float64,
    title : String = "",
    subtitle : String? = nil

  # MapView — Native map view bridging to MapKit on Apple platforms.
  class MapView < View
    property latitude : Float64 = 0.0
    property longitude : Float64 = 0.0
    property zoom_level : Float64 = 10.0
    property map_type : Symbol = :standard # :standard, :satellite, :hybrid
    property shows_user_location : Bool = false
    property annotations : Array(MapAnnotation) = [] of MapAnnotation

    def initialize
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
