# AmbientScene — Phase 6 validation builder. Produces a UI::View tree representing
# an ambient / wallpaper-like screen for renderer visual-regression captures.

require "../view"
require "../views/label"
require "../views/divider"
require "../views/image"
require "../views/hstack"
require "../views/vstack"
require "../views/spacer"

module UI
  module ValidationScenes
    # AmbientScene -- lightweight single-control showcase.
    #
    # Plain Crystal class (NOT a UI::View subclass). Call `.build` to get a
    # UI::View tree the renderer can walk.
    #
    # For components that don't need rich context: labels, boxes, dividers,
    # cards, text-fields (in isolation), search-fields, etc. Renders a
    # minimal window chrome (title bar with Amber wordmark) and a generous
    # centered content area with 55pt padding from window edges.
    #
    # focal_position values:
    #   :centered  -- focal centered with 55pt padding from all window edges
    #
    # Padding: 55pt from window edges (xxl token) so the focal component has
    # generous breathing room and is not confused with window chrome.
    #
    # Example:
    #   scene = AmbientScene.new(focal: label_view, focal_position: :centered)
    #   view_tree = scene.build
    #   renderer.render(view_tree)

    class AmbientScene
      property focal : View
      property focal_position : Symbol # :centered
      property context_label : String? # optional context hint shown in small gray text above focal

      def initialize(
        @focal : View,
        @focal_position : Symbol = :centered,
        @context_label : String? = nil,
      )
      end

      # Build the full scene tree. Returns a UI::View tree ready for rendering.
      def build : View
        # ----------------------------------------------------------------
        # MINIMAL TITLE BAR -- Amber wordmark only
        # ----------------------------------------------------------------
        amber_icon = Image.new("sparkles")
        amber_icon.minimum_width = 16.0
        amber_icon.minimum_height = 16.0
        amber_icon.content_mode = ContentMode::Fit
        amber_icon.accessibility_label = "Amber icon"
        amber_icon.tint_color = Color.new(r: 1.0, g: 0.678, b: 0.2) # Amber gold

        wordmark = Label.new("Amber")
        wordmark.font = Font.new(size: 13.0, weight: :semibold)
        wordmark.accessibility_label = "Amber app wordmark"

        top_bar = HStack.new(spacing: 6.0)
        top_bar << amber_icon.as(View)
        top_bar << wordmark.as(View)
        top_bar << Spacer.new.as(View)
        top_bar.padding = EdgeInsets.new(top: 10.0, trailing: 21.0, bottom: 10.0, leading: 21.0)

        top_bar_divider = Divider.new(:horizontal)

        # ----------------------------------------------------------------
        # CONTENT AREA -- focal centered with 55pt padding (xxl token)
        # ----------------------------------------------------------------
        content = build_centered_content

        top_bar.minimum_width = 1200.0
        top_bar.maximum_width = 1200.0
        top_bar.minimum_height = 44.0
        top_bar.maximum_height = 44.0

        page = VStack.new(spacing: 0.0)
        page.alignment = Alignment::Fill
        page.minimum_width = 1200.0
        page.maximum_width = 1200.0
        page.minimum_height = 900.0
        page.maximum_height = 900.0
        page << top_bar.as(View)
        page << top_bar_divider.as(View)
        page << content

        page.as(View)
      end

      private def build_centered_content : View
        inner = VStack.new(spacing: 13.0)
        inner.alignment = Alignment::Leading

        # Optional context label (small gray, above the focal)
        if ctx = @context_label
          ctx_lbl = Label.new(ctx)
          ctx_lbl.font = Font.new(size: 11.0, weight: :regular)
          ctx_lbl.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
          ctx_lbl.accessibility_label = "Context: #{ctx}"
          inner << ctx_lbl.as(View)
        end

        inner << @focal

        # Center focal horizontally with spacers
        h_centered = HStack.new(spacing: 0.0)
        h_centered.alignment = Alignment::Fill
        h_centered.minimum_width = 1090.0
        h_centered.maximum_width = 1090.0
        h_centered.minimum_height = 746.0
        h_centered << Spacer.new.as(View)
        h_centered << inner.as(View)
        h_centered << Spacer.new.as(View)

        # Center focal vertically with spacers
        v_centered = VStack.new(spacing: 0.0)
        v_centered.minimum_width = 1090.0
        v_centered.maximum_width = 1090.0
        v_centered.minimum_height = 746.0
        v_centered << Spacer.new.as(View)
        v_centered << h_centered.as(View)
        v_centered << Spacer.new.as(View)

        # 55pt padding from all window edges (xxl Fibonacci-golden token)
        wrapper = VStack.new(spacing: 0.0)
        wrapper.alignment = Alignment::Center
        wrapper.minimum_width = 1200.0
        wrapper.maximum_width = 1200.0
        wrapper.minimum_height = 856.0
        wrapper << v_centered.as(View)
        wrapper.padding = EdgeInsets.new(top: 55.0, trailing: 55.0, bottom: 55.0, leading: 55.0)
        wrapper.accessibility_label = "Ambient scene content area"

        wrapper.as(View)
      end
    end
  end
end
