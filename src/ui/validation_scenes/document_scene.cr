# DocumentScene — Phase 6 validation builder. Produces a UI::View tree of a
# document-style text + toolbar layout for renderer captures.

require "../view"
require "../views/label"
require "../views/button"
require "../views/divider"
require "../views/hstack"
require "../views/vstack"
require "../views/spacer"

module UI
  module ValidationScenes
    # DocumentScene -- Amber journal editor.
    #
    # Plain Crystal class (NOT a UI::View subclass). Call `.build` to get a
    # UI::View tree that the renderer can walk.
    #
    # Renders an Amber journal document view around a focal component
    # (typically a context-menu or edit-menu) so validation captures show
    # the menu surface in its correct spatial relationship to selected text.
    #
    # Layout:
    #   - Title bar: back chevron + "Morning Pages · April 14" title.
    #   - Document body: fake journal entry paragraphs with ~3 lines of
    #     highlighted selected text (Amber gold background behind those
    #     lines to indicate selection state).
    #   - Text cursor / selection indicator row.
    #   - Focal component placed adjacent to the selection:
    #       - :adjacent_to_selection  -- macOS: to the right; iOS: below.
    #
    # focal_position values:
    #   :adjacent_to_selection  -- positions focal floating next to selected text
    #
    # Example:
    #   scene = DocumentScene.new(focal: context_menu, focal_position: :adjacent_to_selection)
    #   view_tree = scene.build
    #   renderer.render(view_tree)

    class DocumentScene
      property focal : View
      property focal_position : Symbol  # :adjacent_to_selection

      def initialize(@focal : View, @focal_position : Symbol = :adjacent_to_selection)
      end

      # Build the full scene tree. Returns a UI::View tree ready for rendering.
      def build : View
        # ----------------------------------------------------------------
        # TITLE BAR
        # ----------------------------------------------------------------
        back_btn = Button.new("Back", symbol: "chevron.left")
        back_btn.accessibility_label = "Back button"

        doc_title = Label.new("Morning Pages \u00B7 April 14")
        doc_title.font = Font.new(size: 17.0, weight: :semibold)
        doc_title.accessibility_label = "Document title"

        title_bar = HStack.new(spacing: 13.0)
        title_bar << back_btn.as(View)
        title_bar << Spacer.new.as(View)
        title_bar << doc_title.as(View)
        title_bar << Spacer.new.as(View)
        title_bar.padding = EdgeInsets.new(top: 13.0, trailing: 21.0, bottom: 13.0, leading: 21.0)

        title_divider = Divider.new(:horizontal)

        # ----------------------------------------------------------------
        # DOCUMENT BODY -- journal entry text
        # ----------------------------------------------------------------
        body_padding = EdgeInsets.new(top: 21.0, trailing: 55.0, bottom: 21.0, leading: 55.0)

        para1 = Label.new("There is something about the early morning that makes thought come easier. Before the notifications arrive, before the day claims its portion of me, there is this narrow window.")
        para1.font = Font.new(size: 15.0, weight: :regular)
        para1.accessibility_label = "Journal paragraph 1"

        gap1 = Spacer.new
        gap1.minimum_height = 13.0

        # Three selected lines -- Amber gold background approximates text selection.
        # HIG edit-menu and context-menu validation: selection is the trigger for
        # these menus, so showing the selected region is load-bearing for the capture.
        sel_line1 = Label.new("I have been writing morning pages for six months now, and")
        sel_line1.font = Font.new(size: 15.0, weight: :regular)
        sel_line1.background = Color.new(r: 1.0, g: 0.678, b: 0.2, a: 0.45)  # Amber gold 45% -- selection tint
        sel_line1.accessibility_label = "Selected text line 1"

        sel_line2 = Label.new("something has shifted. The inner critic still arrives, but it")
        sel_line2.font = Font.new(size: 15.0, weight: :regular)
        sel_line2.background = Color.new(r: 1.0, g: 0.678, b: 0.2, a: 0.45)
        sel_line2.accessibility_label = "Selected text line 2"

        sel_line3 = Label.new("no longer runs the show. Amber noticed first.")
        sel_line3.font = Font.new(size: 15.0, weight: :regular)
        sel_line3.background = Color.new(r: 1.0, g: 0.678, b: 0.2, a: 0.45)
        sel_line3.accessibility_label = "Selected text line 3"

        selected_block = VStack.new(spacing: 0.0)
        selected_block << sel_line1.as(View)
        selected_block << sel_line2.as(View)
        selected_block << sel_line3.as(View)
        selected_block.accessibility_label = "Selected text block"

        # Cursor indicator -- thin divider after selection
        cursor_bar = Divider.new(:horizontal)

        gap2 = Spacer.new
        gap2.minimum_height = 13.0

        para2 = Label.new("Today the thread is this: what does it mean to make something? Not publish, not share -- just make. The artifact exists whether or not it finds an audience.")
        para2.font = Font.new(size: 15.0, weight: :regular)
        para2.accessibility_label = "Journal paragraph 2"

        gap3 = Spacer.new
        gap3.minimum_height = 13.0

        para3 = Label.new("Three pages. That is the practice. Three pages, no editing, no second-guessing the thread. Let it be tangled. Amber can help sort it later.")
        para3.font = Font.new(size: 15.0, weight: :regular)
        para3.accessibility_label = "Journal paragraph 3"

        doc_body = VStack.new(spacing: 0.0)
        doc_body << para1.as(View)
        doc_body << gap1.as(View)
        doc_body << selected_block.as(View)
        doc_body << cursor_bar.as(View)
        doc_body << gap2.as(View)
        doc_body << para2.as(View)
        doc_body << gap3.as(View)
        doc_body << para3.as(View)
        doc_body.padding = body_padding

        # ----------------------------------------------------------------
        # FOCAL PLACEMENT
        # ----------------------------------------------------------------
        title_bar.minimum_width = 1200.0
        title_bar.maximum_width = 1200.0
        title_bar.minimum_height = 44.0
        title_bar.maximum_height = 44.0

        case @focal_position
        when :adjacent_to_selection
          # On macOS: menu floats to the right of the selected block.
          # On iOS: menu floats below the selected block.
          # Approximate with a row that pushes the focal to the right side.
          focal_row = HStack.new(spacing: 21.0)
          focal_row << Spacer.new.as(View)
          focal_row << @focal
          focal_row.padding = EdgeInsets.new(top: 0.0, trailing: 55.0, bottom: 0.0, leading: 0.0)

          content_with_focal = VStack.new(spacing: 0.0)
          content_with_focal.alignment = Alignment::Fill
          content_with_focal.minimum_width = 1200.0
          content_with_focal.maximum_width = 1200.0
          content_with_focal.minimum_height = 900.0
          content_with_focal.maximum_height = 900.0
          content_with_focal << title_bar.as(View)
          content_with_focal << title_divider.as(View)
          content_with_focal << doc_body.as(View)
          content_with_focal << focal_row.as(View)
          content_with_focal << Spacer.new.as(View)
          content_with_focal.as(View)
        else
          content_plain = VStack.new(spacing: 0.0)
          content_plain.alignment = Alignment::Fill
          content_plain.minimum_width = 1200.0
          content_plain.maximum_width = 1200.0
          content_plain.minimum_height = 900.0
          content_plain.maximum_height = 900.0
          content_plain << title_bar.as(View)
          content_plain << title_divider.as(View)
          content_plain << doc_body.as(View)
          content_plain << @focal
          content_plain << Spacer.new.as(View)
          content_plain.as(View)
        end
      end
    end
  end
end
