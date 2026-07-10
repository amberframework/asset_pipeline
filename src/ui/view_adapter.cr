# Bridges a UI::View tree into the legacy Components stateful-component system,
# so view trees can be rendered as HTML by the existing component pipeline.

require "../components/base/stateful_component"
require "./renderers/web_renderer"
require "./state"

module UI
  # Bridges a UI::View tree into the existing component system.
  #
  # ViewAdapter wraps a view-builder block and renders it to HTML using
  # `Web::Renderer`. Each call to `render_content` invokes the builder to
  # get the current view tree, so state changes in captured variables
  # automatically produce updated output on the next render.
  #
  # ## Base class rationale
  #
  # ViewAdapter inherits from `Components::StatefulComponent` rather than
  # `Components::Reactive::ReactiveComponent` to avoid pulling in HTTP and
  # WebSocket dependencies (ReactiveHandler, ReactiveSession) in contexts
  # where they are not needed (e.g., static rendering, specs, CLI tools).
  #
  # For production real-time use, integrate with the reactive system by:
  #   1. Registering the adapter with `ReactiveHandler.register_component`
  #   2. Calling `mark_changed!` + broadcasting via `ReactiveHandler.broadcast_update`
  #
  # Example:
  #   counter = UI::State(Int32).new(0)
  #
  #   adapter = UI::ViewAdapter.new do
  #     stack = UI::VStack.new
  #     stack << UI::Label.new("Count: #{counter.value}")
  #     stack << UI::Button.new("Increment")
  #     stack.as(UI::View)
  #   end
  #
  #   adapter.render  # => HTML string from the view tree
  #   counter.value = 1
  #   adapter.render  # => updated HTML with "Count: 1"
  class ViewAdapter < Components::StatefulComponent
    @view_builder : Proc(View)

    # Takes a block that builds the view tree.
    # The block is called on each render to get the current view state.
    def initialize(&block : -> View)
      super()
      @view_builder = block
    end

    # Web rendering path -- called by the component system via `render`.
    # Builds a fresh view tree from the builder block, then renders it
    # to HTML through Web::Renderer.
    def render_content : String
      view = @view_builder.call
      renderer = Web::Renderer.new
      view.accept(renderer)
      renderer.output
    end

    # Convenience: mark the component as changed and return the fresh HTML.
    # In a reactive context, call this after state changes to get the
    # updated markup. For WebSocket push, follow with:
    #   ReactiveHandler.broadcast_update(component_id, html, state_to_json)
    def invalidate! : String
      mark_changed!
      render_content
    end
  end
end
