# GalleryScene — Phase 6 validation builder. Produces a UI::View tree of an image
# gallery grid composition for renderer captures.

require "../view"
require "../views/label"
require "../views/button"
require "../views/divider"
require "../views/card"
require "../views/image"
require "../views/hstack"
require "../views/vstack"
require "../views/spacer"
require "../views/segmented_control"
require "../views/grid"

module UI
  module ValidationScenes
    # GalleryScene -- Amber memories gallery.
    #
    # Plain Crystal class (NOT a UI::View subclass). Call `.build` to get a
    # UI::View tree the renderer can walk.
    #
    # Layout:
    #   - Title bar: "Amber \u00B7 Memories" + segmented grid/list toggle
    #     in top-right corner.
    #   - Grid/list of Amber memories: tiles with SF Symbol placeholder
    #     images (leaf / sparkles / sun.max etc.) + memory title + timestamp.
    #   - Focal placement depends on focal_position.
    #
    # focal_position values:
    #   :grid_full    -- focal replaces the entire grid content area
    #                    (used for image-views, collections)
    #   :inline_rows  -- focal embedded as a column alongside each tile row
    #                    (used for rating-indicators: each row shows a memory
    #                    title + a rating control beside it)
    #   :carousel     -- focal placed below a horizontal scroll of memory cards
    #                    (used for page-controls: 3 cards + page dots beneath)
    #
    # Tile spacing: 21pt gap between tiles (Fibonacci-golden Lg token).
    # Tile aspect ratio: square (1:1). Consistent tile widths within each row.
    #
    # Example:
    #   scene = GalleryScene.new(focal: image_gallery_view, focal_position: :grid_full)
    #   view_tree = scene.build
    #   renderer.render(view_tree)

    class GalleryScene
      property focal : View
      property focal_position : Symbol # :grid_full | :inline_rows | :carousel

      def initialize(@focal : View, @focal_position : Symbol = :grid_full)
      end

      # Build the full scene tree. Returns a UI::View tree ready for rendering.
      def build : View
        # ----------------------------------------------------------------
        # TITLE BAR
        # ----------------------------------------------------------------
        wordmark = Label.new("Amber \u00B7 Memories")
        wordmark.font = Font.new(size: 15.0, weight: :semibold)
        wordmark.accessibility_label = "Amber Memories title"

        # Grid/list toggle -- segmented control in top-right
        view_toggle = SegmentedControl.new(segments: ["Grid", "List"], selected_index: 0)
        view_toggle.accessibility_label = "Grid or list view toggle"

        top_bar = HStack.new(spacing: 13.0)
        top_bar << wordmark.as(View)
        top_bar << Spacer.new.as(View)
        top_bar << view_toggle.as(View)
        top_bar.padding = EdgeInsets.new(top: 13.0, trailing: 21.0, bottom: 13.0, leading: 21.0)

        top_bar_divider = Divider.new(:horizontal)

        # ----------------------------------------------------------------
        # CONTENT AREA
        # ----------------------------------------------------------------
        content = build_content_for(@focal_position)

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

      private def build_content_for(position : Symbol) : View
        case position
        when :grid_full
          # Focal IS the gallery content.
          container = VStack.new(spacing: 0.0)
          container.alignment = Alignment::Center
          container.minimum_width = 1200.0
          container.maximum_width = 1200.0
          container.minimum_height = 856.0
          container.padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)
          container << @focal
          container.as(View)
        when :inline_rows
          # Row list: each memory row carries the focal inline.
          # Used for rating-indicators where every memory has a star rating.
          memories = [
            {"leaf", "Garden thoughts", "12 sprouts", "April 12"},
            {"sun.max", "Morning pages", "3 entries", "April 13"},
            {"moon.stars", "Dream journal", "2 entries", "April 11"},
            {"wand.and.stars", "Rituals", "5 tomorrow", "April 13"},
            {"hourglass", "Deep work", "2h 14m today", "April 13"},
          ]

          list = VStack.new(spacing: 0.0)
          list.padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)

          memories.each_with_index do |(symbol, title, detail, date), idx|
            icon = Image.new(symbol)
            icon.minimum_width = 32.0
            icon.minimum_height = 32.0
            icon.content_mode = ContentMode::Fit
            icon.accessibility_label = "#{title} icon"
            icon.tint_color = Color.new(r: 1.0, g: 0.678, b: 0.2) # Amber gold tint

            title_lbl = Label.new(title)
            title_lbl.font = Font.new(size: 13.0, weight: :semibold)
            title_lbl.accessibility_label = title

            detail_lbl = Label.new(detail)
            detail_lbl.font = Font.new(size: 11.0, weight: :regular)
            detail_lbl.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
            detail_lbl.accessibility_label = "#{title} detail: #{detail}"

            date_lbl = Label.new(date)
            date_lbl.font = Font.new(size: 11.0, weight: :regular)
            date_lbl.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
            date_lbl.accessibility_label = "#{title} date: #{date}"

            text_col = VStack.new(spacing: 2.0)
            text_col << title_lbl.as(View)
            text_col << detail_lbl.as(View)

            mem_row = HStack.new(spacing: 13.0)
            mem_row << icon.as(View)
            mem_row << text_col.as(View)
            mem_row << Spacer.new.as(View)
            mem_row << date_lbl.as(View)
            # Focal (e.g. rating indicator) on the trailing edge
            mem_row << @focal
            mem_row.padding = EdgeInsets.new(top: 8.0, trailing: 0.0, bottom: 8.0, leading: 0.0)
            mem_row.minimum_height = 44.0
            mem_row.accessibility_label = "Memory row: #{title}"

            list << mem_row.as(View)
            if idx < memories.size - 1
              list << Divider.new(:horizontal).as(View)
            end
          end

          list.as(View)
        when :carousel
          # Horizontal scroll of 3 memory cards + page indicator beneath.
          # Used for page-controls.
          cards_row = HStack.new(spacing: 21.0)
          cards_row.padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 0.0, leading: 21.0)

          [
            {"leaf", "Garden thoughts", "12 sprouts", "April 12"},
            {"sun.max", "Morning pages", "3 entries", "April 13"},
            {"moon.stars", "Dream journal", "2 entries", "April 11"},
          ].each do |symbol, title, detail, date|
            card_icon = Image.new(symbol)
            card_icon.minimum_width = 40.0
            card_icon.minimum_height = 40.0
            card_icon.content_mode = ContentMode::Fit
            card_icon.accessibility_label = "#{title} card icon"
            card_icon.tint_color = Color.new(r: 1.0, g: 0.678, b: 0.2)

            card_title = Label.new(title)
            card_title.font = Font.new(size: 15.0, weight: :semibold)
            card_title.accessibility_label = title

            card_detail = Label.new(detail)
            card_detail.font = Font.new(size: 13.0, weight: :regular)
            card_detail.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
            card_detail.accessibility_label = "#{title}: #{detail}"

            card_date = Label.new(date)
            card_date.font = Font.new(size: 11.0, weight: :regular)
            card_date.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
            card_date.accessibility_label = "Date: #{date}"

            card_body = VStack.new(spacing: 8.0)
            card_body << card_icon.as(View)
            card_body << card_title.as(View)
            card_body << card_detail.as(View)
            card_body << card_date.as(View)
            card_body.padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)

            mem_card = Card.new(card_body.as(View))
            mem_card.corner_radius = 10.0
            mem_card.minimum_width = 180.0
            mem_card.minimum_height = 160.0
            mem_card.accessibility_label = "#{title} memory card"

            cards_row << mem_card.as(View)
          end

          # Focal (page control dots) below the card row
          focal_row = HStack.new(spacing: 0.0)
          focal_row << Spacer.new.as(View)
          focal_row << @focal
          focal_row << Spacer.new.as(View)
          focal_row.padding = EdgeInsets.new(top: 13.0, trailing: 0.0, bottom: 21.0, leading: 0.0)

          carousel = VStack.new(spacing: 0.0)
          carousel << cards_row.as(View)
          carousel << focal_row.as(View)
          carousel << Spacer.new.as(View)
          carousel.as(View)
        else
          container = VStack.new(spacing: 21.0)
          container.padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)
          container << @focal
          container.as(View)
        end
      end

      # Build an Amber-branded memory tile for the grid.
      # symbol: SF Symbol name. caption: tile label.
      def self.memory_tile(symbol : String, caption : String, timestamp : String) : View
        icon = Image.new(symbol)
        icon.minimum_width = 64.0
        icon.minimum_height = 64.0
        icon.content_mode = ContentMode::Fit
        icon.accessibility_label = "#{caption} memory icon"
        icon.tint_color = Color.new(r: 1.0, g: 0.678, b: 0.2) # Amber gold

        cap_lbl = Label.new(caption)
        cap_lbl.font = Font.new(size: 11.0, weight: :semibold)
        cap_lbl.accessibility_label = caption

        ts_lbl = Label.new(timestamp)
        ts_lbl.font = Font.new(size: 10.0, weight: :regular)
        ts_lbl.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        ts_lbl.accessibility_label = "Timestamp: #{timestamp}"

        tile = VStack.new(spacing: 4.0)
        tile << icon.as(View)
        tile << cap_lbl.as(View)
        tile << ts_lbl.as(View)
        tile.padding = EdgeInsets.new(top: 8.0, trailing: 8.0, bottom: 8.0, leading: 8.0)
        tile.corner_radius = 10.0
        tile.minimum_width = 100.0
        tile.minimum_height = 100.0
        tile.accessibility_label = "#{caption} memory tile"

        tile.as(View)
      end
    end
  end
end
