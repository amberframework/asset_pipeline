# macOS path control showing a filesystem-style breadcrumb.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

{% if flag?(:macos) %}
  # Top-level namespace for the asset_pipeline cross-platform UI system.
  module UI
    enum PathControlStyle
      Standard
      PopUp
    end

    # Tier 3 — macOS-only. Use UI::PathControlWithWebFallback to render a
    # breadcrumb nav on every other target.
    #
    # On every other build, naming this class is a compile-time error
    # (see _gate_stubs/path_control.cr).
    class PathControl < View
      record Component,
        name : String,
        icon : String? = nil,
        url : String? = nil

      property components : Array(Component) = [] of Component
      property style : PathControlStyle = PathControlStyle::Standard
      property is_editable : Bool = false

      def initialize(
        @components : Array(Component) = [] of Component,
        @style : PathControlStyle = PathControlStyle::Standard
      )
      end

      def add_component(name : String, icon : String? = nil, url : String? = nil)
        @components << Component.new(name: name, icon: icon, url: url)
      end

      def path_string : String
        return "/" if @components.empty?
        "/" + @components.map(&.name).join("/")
      end

      def accept(visitor : PlatformVisitor)
        visitor.visit(self)
      end
    end
  end
{% else %}
  # PathControlStyle is universal data (no platform behavior); expose it
  # so non-macOS code can still annotate types. The gated stub for the
  # PathControl class itself lives in _gate_stubs/path_control.cr.
  module UI
    enum PathControlStyle
      Standard
      PopUp
    end
  end
  require "./_gate_stubs/path_control"
{% end %}
