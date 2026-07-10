# Native video playback view bridging to AVPlayerViewController on Apple platforms.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # VideoPlayer — Native video playback view bridging to AVPlayerViewController on Apple platforms.
  class VideoPlayer < View
    property url : String = ""
    property is_playing : Bool = false
    property shows_controls : Bool = true
    property auto_play : Bool = false
    property muted : Bool = false
    property loop : Bool = false
    property poster_url : String? = nil

    def initialize(@url : String = "")
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
