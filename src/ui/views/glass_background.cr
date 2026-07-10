# Apple glass / translucency background using NSVisualEffectView / UIVisualEffectView.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # GlassBackground — Apple glass / translucency background using NSVisualEffectView / UIVisualEffectView.
  class GlassBackground < View
    property content : View? = nil
    property material : Symbol = :regular  # :thin, :ultra_thin, :regular, :thick, :chrome
    property is_vibrant : Bool = true

    def initialize(@content : View? = nil, @material : Symbol = :regular)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
