# ChartScene — Phase 6 validation builder. Produces a UI::View tree representing
# a chart-and-card composition for renderer visual-regression captures.

require "../view"
require "../views/label"
require "../views/button"
require "../views/divider"
require "../views/card"
require "../views/image"
require "../views/hstack"
require "../views/vstack"
require "../views/spacer"

module UI
  module ValidationScenes
    # ChartScene -- Amber focus dashboard chart card.
    #
    # Plain Crystal class (NOT a UI::View subclass). Call `.build` to get a
    # UI::View tree the renderer can walk.
    #
    # Layout:
    #   - Title bar: "Amber \u00B7 Focus".
    #   - Two-column content:
    #       Left (narrow, ~140pt): three stat rows:
    #           "2h 14m" / Today
    #           "7" / Streak
    #           "12" / Distortions
    #       Right (wide, fills rest): chart card with:
    #           - Card title: "Focus minutes this week"
    #           - Focal component centered inside the card with 21pt padding.
    #           - Amber plum (#5B3A94 light / #7D59B8 dark) accent on chart.
    #
    # focal_position values:
    #   :card_focal   -- focal sits inside the chart card (charts, gauges, etc.)
    #   :inline_rows  -- focal placed as rows in the left stat column
    #                    (progress bars, activity rings alongside stat text)
    #
    # Chart card padding: 21pt all sides (Fibonacci-golden Lg token) so the
    # focal chart does not touch the card edges. This is mandatory per the
    # Iter B nitpick specification.
    #
    # Example:
    #   scene = ChartScene.new(focal: chart_view, focal_position: :card_focal)
    #   view_tree = scene.build
    #   renderer.render(view_tree)

    class ChartScene
      property focal : View
      property focal_position : Symbol # :card_focal | :inline_rows

      def initialize(@focal : View, @focal_position : Symbol = :card_focal)
      end

      # Build the full scene tree. Returns a UI::View tree ready for rendering.
      def build : View
        # ----------------------------------------------------------------
        # TITLE BAR
        # ----------------------------------------------------------------
        focus_icon = Image.new("brain.head.profile")
        focus_icon.minimum_width = 18.0
        focus_icon.minimum_height = 18.0
        focus_icon.content_mode = ContentMode::Fit
        focus_icon.accessibility_label = "Focus icon"

        title_lbl = Label.new("Amber \u00B7 Focus")
        title_lbl.font = Font.new(size: 15.0, weight: :semibold)
        title_lbl.accessibility_label = "Amber Focus title"

        range_lbl = Label.new("This week")
        range_lbl.font = Font.new(size: 13.0, weight: :regular)
        range_lbl.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        range_lbl.accessibility_label = "Chart time range: This week"

        top_bar = HStack.new(spacing: 8.0)
        top_bar << focus_icon.as(View)
        top_bar << title_lbl.as(View)
        top_bar << Spacer.new.as(View)
        top_bar << range_lbl.as(View)
        top_bar.padding = EdgeInsets.new(top: 13.0, trailing: 21.0, bottom: 13.0, leading: 21.0)
        top_bar.minimum_width = 1200.0
        top_bar.maximum_width = 1200.0

        top_bar_divider = Divider.new(:horizontal)

        # ----------------------------------------------------------------
        # BODY -- left stat column + right chart card
        # ----------------------------------------------------------------
        body = build_body

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
        page << body

        page.as(View)
      end

      private def build_body : View
        left_col = build_stat_column
        right_col = build_chart_card

        # body_row is pinned to exactly 1200pt (min==max) so NSStackView
        # GravityAreas gives it a definite frame. Fill distribution expands
        # right_col to fill remaining space after the 140pt left_col.
        # Vertical pin (min==max=856) fills below the 44pt title bar.
        body_row = HStack.new(spacing: 21.0)
        body_row.alignment = Alignment::Fill
        body_row.minimum_width = 1200.0
        body_row.maximum_width = 1200.0
        body_row.minimum_height = 856.0
        body_row.maximum_height = 856.0
        body_row << left_col.as(View)
        body_row << right_col.as(View)
        body_row.padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)

        body_row.as(View)
      end

      private def build_stat_column : View
        col = VStack.new(spacing: 21.0)
        col.minimum_width = 140.0
        col.maximum_width = 140.0

        stats = [
          {"2h 14m", "Today", "hourglass"},
          {"7", "Streak", "flame"},
          {"12", "Distortions", "wand.and.stars"},
        ]

        stats.each do |value, label_text, symbol|
          stat_icon = Image.new(symbol)
          stat_icon.minimum_width = 18.0
          stat_icon.minimum_height = 18.0
          stat_icon.content_mode = ContentMode::Fit
          stat_icon.accessibility_label = "#{label_text} icon"
          stat_icon.tint_color = Color.new(r: 0.357, g: 0.227, b: 0.58) # Amber plum light

          val_lbl = Label.new(value)
          val_lbl.font = Font.new(size: 22.0, weight: :bold)
          val_lbl.text_color = Color.new(r: 0.357, g: 0.227, b: 0.58) # Amber plum light
          val_lbl.accessibility_label = "#{label_text}: #{value}"

          lbl = Label.new(label_text)
          lbl.font = Font.new(size: 11.0, weight: :regular)
          lbl.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
          lbl.accessibility_label = label_text

          stat_block = VStack.new(spacing: 2.0)
          stat_block << stat_icon.as(View)
          stat_block << val_lbl.as(View)
          stat_block << lbl.as(View)

          if @focal_position == :inline_rows
            # Progress bar or activity indicator embedded beside each stat.
            stat_row = HStack.new(spacing: 8.0)
            stat_row << stat_block.as(View)
            stat_row << @focal
            col << stat_row.as(View)
          else
            col << stat_block.as(View)
          end
        end

        col << Spacer.new.as(View)

        col.as(View)
      end

      private def build_chart_card : View
        # Card title
        card_title = Label.new("Focus minutes this week")
        card_title.font = Font.new(size: 15.0, weight: :semibold)
        card_title.accessibility_label = "Chart title: Focus minutes this week"

        card_subtitle = Label.new("Mon \u2013 Sun")
        card_subtitle.font = Font.new(size: 11.0, weight: :regular)
        card_subtitle.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        card_subtitle.accessibility_label = "Chart date range: Mon to Sun"

        title_row = HStack.new(spacing: 8.0)
        title_row << card_title.as(View)
        title_row << Spacer.new.as(View)
        title_row << card_subtitle.as(View)

        # Focal chart centered inside the card with mandatory 21pt padding.
        # The 21pt card content_padding (set below on the Card object) handles
        # the perimeter; this gap provides vertical breathing room between
        # the title and the chart surface.
        title_gap = Spacer.new
        title_gap.minimum_height = 13.0

        card_body = VStack.new(spacing: 0.0)
        card_body << title_row.as(View)
        card_body << title_gap.as(View)
        card_body << @focal if @focal_position == :card_focal
        card_body << Spacer.new.as(View)

        chart_card = Card.new(card_body.as(View))
        chart_card.corner_radius = 10.0
        # 21pt card padding so the chart does not touch the card edges (Iter B nitpick)
        chart_card.content_padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)
        # Expand card to fill the full width of the right column (1200 - 21 - 140 - 21 - 21 = ~997pt).
        # Without this, the card renders at intrinsic width (~270pt), leaving >70% of the
        # right column empty -- a composition failure under R15.
        chart_card.minimum_width = 900.0
        # Fill the body height (856 - 44 topbar - 21 top_padding - 21 bottom_padding = ~770pt).
        chart_card.minimum_height = 770.0
        chart_card.accessibility_label = "Focus chart card"

        chart_card.as(View)
      end
    end
  end
end
