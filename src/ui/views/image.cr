# Static image view loading from an asset or local URL.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # An image view that displays a named image resource.
  #
  # The `source` is a logical image name resolved by the platform
  # renderer (e.g., an asset catalog name on iOS, a drawable on Android).
  class Image < View
    # Logical image source name
    property source : String

    # How the image content is scaled to fit
    property content_mode : ContentMode = ContentMode::Fit

    # Tint color applied over the image (nil means no tint)
    property tint_color : Color? = nil

    def initialize(@source : String)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
