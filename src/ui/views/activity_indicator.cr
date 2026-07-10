# Indeterminate spinner indicating that work is in progress.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # An indeterminate activity/loading spinner.
  class ActivityIndicator < View
    # Whether the indicator is currently animating
    property is_animating : Bool = true

    # Size of the indicator (:small, :medium, or :large)
    property size : Symbol = :medium

    # Tint color
    property color : Color? = nil

    def initialize(@is_animating : Bool = true, @size : Symbol = :medium)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
