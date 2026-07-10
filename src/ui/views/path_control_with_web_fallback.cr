# Tier-3 path control with a web-compatible fallback rendering on non-macOS targets.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"
{% if flag?(:macos) %}
  require "./path_control"
{% end %}

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Cross-platform companion to the macOS-only UI::PathControl.
  #
  # On -Dmacos: delegates to a held UI::PathControl instance so AppKit
  # renders the native NSPathControl chrome.
  #
  # On every other target: renders a semantic breadcrumb
  # `<nav aria-label="Breadcrumb"><ol>...</ol></nav>` with proper landmark
  # semantics (an improvement over the previous >-separated string the
  # web visitor used to emit).
  class PathControlWithWebFallback < View
    record Component,
      name : String,
      icon : String? = nil,
      url : String? = nil

    property components : Array(Component) = [] of Component
    property style : PathControlStyle = PathControlStyle::Standard
    property is_editable : Bool = false

    {% if flag?(:macos) %}
      @inner : UI::PathControl

      def initialize(
        @components : Array(Component) = [] of Component,
        @style : PathControlStyle = PathControlStyle::Standard,
      )
        inner_components = @components.map do |c|
          UI::PathControl::Component.new(name: c.name, icon: c.icon, url: c.url)
        end
        @inner = UI::PathControl.new(inner_components, @style)
      end

      def add_component(name : String, icon : String? = nil, url : String? = nil)
        @components << Component.new(name: name, icon: icon, url: url)
        @inner.add_component(name, icon, url)
      end

      def path_string : String
        @inner.path_string
      end

      def accept(visitor : PlatformVisitor)
        @inner.accept(visitor)
      end
    {% else %}
      def initialize(
        @components : Array(Component) = [] of Component,
        @style : PathControlStyle = PathControlStyle::Standard,
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
    {% end %}
  end
end
