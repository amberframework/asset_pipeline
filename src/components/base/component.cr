require "../elements/base/raw_html"
require "../css/component_css_registry"
require "../safe/safe_html"

module Components
  # Base class for all components
  # Components are reusable, composable units built from HTML elements
  abstract class Component
    # Unique identifier for this component instance
    getter component_id : String

    # Component attributes (props)
    getter attributes : Hash(String, String)

    # Component children
    getter children : Array(Component | Elements::HTMLElement | String | Elements::RawHTML)

    def initialize(**attrs)
      @component_id = generate_component_id
      @attributes = {} of String => String
      @children = [] of Component | Elements::HTMLElement | String | Elements::RawHTML

      # Process attributes
      attrs.each do |key, value|
        @attributes[key.to_s] = value.to_s
      end
    end

    # Add a child to the component
    def <<(child : Component | Elements::HTMLElement | String | Elements::RawHTML) : self
      @children << child
      self
    end

    # Add multiple children
    def add_children(*children : Component | Elements::HTMLElement | String | Elements::RawHTML) : self
      children.each { |child| self << child }
      self
    end

    # Build content using a block
    def build(&block : self -> Nil) : self
      yield self
      self
    end

    # Get an attribute value
    def [](name : String) : String?
      @attributes[name]?
    end

    # Set an attribute value
    def []=(name : String, value : String) : String
      @attributes[name] = value
    end

    # THE OUTPUT CONTRACT (docs/SAFE_HTML_V1.md). Every `Component` renders
    # to `SafeHTML`, not `String` — this is the type-level boundary that
    # makes "a component that hand-built unsafe markup and forgot to escape
    # a sink" a thing the compiler catches at the response-sink type, rather
    # than a thing a human has to notice at review time.
    #
    # This delegates to `render_safe_content`, which subclasses may override
    # directly (the preferred, migrated path — see `DataTableComponent` for
    # the exemplar). The default implementation bridges the legacy
    # `render_content : String` path through the loud, greppable
    # `SafeHTML.unsafe` escape hatch, so every existing hand-built component
    # keeps compiling and running unchanged — but its output is now
    # explicitly, auditably marked "not yet vouched for by the safe DSL."
    # `grep -rn 'reason: "legacy component' src/` finds every component
    # still on this bridge; that grep result is the migration progress list.
    def render : SafeHTML
      render_safe_content
    end

    # Override this in a migrated component to build `SafeHTML` directly via
    # the `Elements`/tag DSL (escaped by construction) instead of hand-built
    # `String.build`. See `docs/SAFE_HTML_V1.md` "migration guide".
    def render_safe_content : SafeHTML
      SafeHTML.unsafe(
        render_content,
        reason: "legacy component #{self.class} has not migrated to render_safe_content — see docs/SAFE_HTML_V1.md"
      )
    end

    # Render the component as raw HTML (for adding to elements)
    def to_raw_html : Elements::RawHTML
      render.to_raw_html
    end

    # Macro for registering component-level CSS.
    # CSS is stored as a class variable and registered with the global
    # ComponentCSSRegistry when the class is first loaded.
    #
    # Usage:
    #   class ButtonComponent < Components::StatelessComponent
    #     component_css <<-CSS
    #       .btn { display: inline-flex; align-items: center; }
    #       .btn-primary { background-color: var(--color-blue-500); }
    #     CSS
    #   end
    macro component_css(css_string)
      @@_component_css : String = {{css_string}}

      def self.component_css_string : String
        @@_component_css
      end

      Components::CSS::ComponentCSSRegistry.instance.register(
        {{@type.name.stringify}},
        @@_component_css
      )
    end

    # Abstract method to be implemented by subclasses
    abstract def render_content : String

    # Generate a unique component ID
    private def generate_component_id : String
      "component-#{Time.utc.to_unix_ms}-#{Random.rand(10000)}"
    end

    # Render children components/elements
    protected def render_children : String
      @children.map do |child|
        case child
        when Component
          child.render.to_s
        when Elements::HTMLElement
          child.render
        when Elements::RawHTML
          child.render
        when String
          escape_html(child)
        else
          child.to_s
        end
      end.join
    end

    # Escape HTML content
    protected def escape_html(content : String) : String
      content.gsub('&', "&amp;")
        .gsub('<', "&lt;")
        .gsub('>', "&gt;")
        .gsub('"', "&quot;")
        .gsub('\'', "&#39;")
    end

    # Ergonomic, in-component spelling of `SafeHTML.unsafe` — the loud,
    # greppable escape hatch (docs/SAFE_HTML_V1.md). `reason:` is mandatory.
    protected def raw(html : String, reason : String) : SafeHTML
      SafeHTML.unsafe(html, reason: reason)
    end

    # Convert to string (alias for render)
    def to_s(io : IO) : Nil
      io << render
    end
  end
end
