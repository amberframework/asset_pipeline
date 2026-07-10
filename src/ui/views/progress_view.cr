# Determinate progress bar / circle for known-duration work.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A progress indicator showing determinate or indeterminate progress.
  class ProgressView < View
    # Current progress value (0.0 to 1.0). Nil = indeterminate.
    property value : Float64? = nil

    # Visual style of the progress indicator
    property style : ProgressStyle = ProgressStyle::Linear

    # Tint color for the progress track
    property tint_color : Color? = nil

    # Label displayed near the progress indicator
    property label : String = ""

    def initialize(@value : Float64? = nil, @style : ProgressStyle = ProgressStyle::Linear)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
