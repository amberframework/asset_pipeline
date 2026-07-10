# Generic themed surface used as a background for other content.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Surface — Generic themed surface used as a background for other content.
  class Surface < View
    property content : View? = nil
    property elevation : Float64 = 0.0
    property tonal_elevation : Float64 = 0.0
    property shape : Symbol = :rectangle  # :rectangle, :rounded, :circle

    def initialize(@content : View? = nil)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
