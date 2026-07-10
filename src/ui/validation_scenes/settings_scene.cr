# SettingsScene — Phase 6 validation builder. Produces a UI::View tree of a
# settings form composition (rows, toggles, pickers) for renderer captures.

require "../view"
require "../views/label"
require "../views/button"
require "../views/text_field"
require "../views/divider"
require "../views/card"
require "../views/image"
require "../views/hstack"
require "../views/vstack"
require "../views/spacer"

module UI
  module ValidationScenes
    # SettingsScene -- Amber preferences window.
    #
    # Plain Crystal class (NOT a UI::View subclass). Call `.build` to get a
    # UI::View tree the renderer can walk.
    #
    # Layout:
    #   - Title bar: gear SF Symbol + "Amber \u00B7 Preferences" wordmark.
    #   - Left sidebar column (~160pt): General (selected) / Appearance /
    #     Rituals / Vaults / Sounds -- each row has an SF Symbol glyph.
    #   - Right content area: a form grouping with the focal component as
    #     one (or multiple) rows. HIG form row layout: labels on the left
    #     in a ~120pt right-aligned column, controls on the right, 34pt
    #     row height, 8pt row gap.
    #
    # focal_position values:
    #   :single_row  -- focal placed as one form row with a leading label
    #                   (used for Steppers, Pickers, SegmentedControls, etc.)
    #   :multi_row   -- focal placed as a group of rows (used for Buttons,
    #                   Toggles, Sliders, ColorWells, DisclosureControls, etc.)
    #
    # HIG form row dimensions:
    #   label column: ~120pt, right-aligned text
    #   control column: flexible (fills remaining width)
    #   row height: 34pt (HIG minimum for macOS form rows)
    #   inter-row gap: 8pt (sm token)
    #
    # Example:
    #   scene = SettingsScene.new(focal: toggle_view, focal_position: :single_row,
    #                             row_label: "Enable notifications:")
    #   view_tree = scene.build
    #   renderer.render(view_tree)

    class SettingsScene
      property focal : View
      property focal_position : Symbol # :single_row | :multi_row
      property row_label : String      # label text for :single_row position

      def initialize(
        @focal : View,
        @focal_position : Symbol = :single_row,
        @row_label : String = "Setting:",
      )
      end

      # Build the full scene tree. Returns a UI::View tree ready for rendering.
      def build : View
        # ----------------------------------------------------------------
        # TITLE BAR
        # ----------------------------------------------------------------
        gear_icon = Image.new("gearshape")
        gear_icon.minimum_width = 18.0
        gear_icon.minimum_height = 18.0
        gear_icon.content_mode = ContentMode::Fit
        gear_icon.accessibility_label = "Preferences icon"

        title_lbl = Label.new("Amber \u00B7 Preferences")
        title_lbl.font = Font.new(size: 15.0, weight: :semibold)
        title_lbl.accessibility_label = "Preferences window title"

        top_bar = HStack.new(spacing: 8.0)
        top_bar << gear_icon.as(View)
        top_bar << title_lbl.as(View)
        top_bar << Spacer.new.as(View)
        top_bar.padding = EdgeInsets.new(top: 13.0, trailing: 21.0, bottom: 13.0, leading: 21.0)

        top_bar_divider = Divider.new(:horizontal)

        # ----------------------------------------------------------------
        # LEFT NAV SIDEBAR -- settings categories
        # ----------------------------------------------------------------
        sidebar = build_sidebar

        sidebar_divider = Divider.new(:vertical)

        # ----------------------------------------------------------------
        # RIGHT CONTENT -- form panel with focal
        # ----------------------------------------------------------------
        right_panel = build_right_panel

        # body_row: HStack spanning exactly the 1200pt window width.
        # Exact pin (minimum_width == maximum_width) at priority 999 overrides
        # NSStackView GravityAreas' intrinsic-size preference, giving body_row
        # a definite 1200pt frame. Alignment::Fill triggers setDistribution:0
        # on the HStack NSStackView so the last child (right_panel) expands to
        # fill 1200 - 160(sidebar) - 1(divider) = 1039pt.
        # Vertical pin (minimum_height == maximum_height = 856) fills the
        # remaining 856pt below the 44pt title bar to reach 900pt window height.
        body_row = HStack.new(spacing: 0.0)
        body_row.alignment = Alignment::Fill
        body_row.minimum_width = 1200.0
        body_row.maximum_width = 1200.0
        body_row.minimum_height = 856.0
        body_row.maximum_height = 856.0
        body_row << sidebar.as(View)
        body_row << sidebar_divider.as(View)
        body_row << right_panel.as(View)

        # top_bar spans full window width too (exact pin); 44pt tall.
        top_bar.minimum_width = 1200.0
        top_bar.maximum_width = 1200.0
        top_bar.minimum_height = 44.0
        top_bar.maximum_height = 44.0

        # The page VStack is the single continuous Preferences window surface.
        # Set an explicit background so the peach backdrop gradient does NOT
        # bleed through between the nav sidebar and form panel subviews.
        # Cream (#FAF6F0) in light; deep ember (#2A1A08) in dark — these match
        # the Amber surface tokens from brand/amber.md.
        # objc_install_content_view clears only the root NSWindow content view's
        # layer; this background is on the page NSStackView's own layer and is
        # NOT cleared. Corner radius 10pt gives the card shape per brand/amber.md
        # `card` radius token.
        is_dark = ENV["HIG_APPEARANCE"]? == "dark"
        page_bg = is_dark ? Color.new(r: 0.165, g: 0.102, b: 0.031) :
                            Color.new(r: 0.980, g: 0.965, b: 0.941)

        page = VStack.new(spacing: 0.0)
        page.alignment = Alignment::Fill
        page.minimum_width = 1200.0
        page.maximum_width = 1200.0
        page.minimum_height = 900.0
        page.maximum_height = 900.0
        page.background = page_bg
        page << top_bar.as(View)
        page << top_bar_divider.as(View)
        page << body_row.as(View)

        page.as(View)
      end

      private def build_sidebar : View
        # Match the page_bg so the nav sidebar column has NO gap at its right
        # edge. Without this, the NSWindow content view's peach backdrop bleeds
        # between the sidebar column and the body_row HStack.
        is_dark = ENV["HIG_APPEARANCE"]? == "dark"
        col_bg = is_dark ? Color.new(r: 0.165, g: 0.102, b: 0.031) :
                           Color.new(r: 0.980, g: 0.965, b: 0.941)
        sidebar = VStack.new(spacing: 2.0)
        sidebar.minimum_width = 160.0
        sidebar.maximum_width = 160.0
        sidebar.minimum_height = 856.0
        sidebar.maximum_height = 856.0
        sidebar.background = col_bg
        sidebar.padding = EdgeInsets.new(top: 13.0, trailing: 8.0, bottom: 13.0, leading: 13.0)

        [
          {"gearshape", "General", true},
          {"paintbrush", "Appearance", false},
          {"sparkles", "Rituals", false},
          {"shippingbox", "Vaults", false},
          {"speaker.wave.2", "Sounds", false},
        ].each do |symbol, title, selected|
          row = HStack.new(spacing: 8.0)
          icon = Image.new(symbol)
          icon.minimum_width = 16.0
          icon.minimum_height = 16.0
          icon.content_mode = ContentMode::Fit
          icon.accessibility_label = "#{title} settings icon"

          lbl = Label.new(title)
          lbl.font = Font.new(size: 13.0, weight: selected ? :semibold : :regular)
          lbl.accessibility_label = title
          if selected
            lbl.text_color = Color.new(r: 1.0, g: 0.678, b: 0.2) # Amber gold -- active
          end

          row << icon.as(View)
          row << lbl.as(View)
          row.padding = EdgeInsets.new(top: 5.0, trailing: 4.0, bottom: 5.0, leading: 4.0)
          if selected
            row.corner_radius = 6.0
            row.background = Color.new(r: 1.0, g: 0.678, b: 0.2, a: 0.12) # subtle gold tint
          end
          row.accessibility_label = "#{title} settings category#{selected ? " (selected)" : ""}"

          sidebar << row.as(View)
        end

        sidebar.as(View)
      end

      private def build_right_panel : View
        # Match the page_bg so the right form panel has NO gap at its left edge.
        # Without this, the peach backdrop bleeds between the vertical divider
        # and the form panel's leading inset.
        is_dark = ENV["HIG_APPEARANCE"]? == "dark"
        panel_bg = is_dark ? Color.new(r: 0.165, g: 0.102, b: 0.031) :
                             Color.new(r: 0.980, g: 0.965, b: 0.941)
        panel = VStack.new(spacing: 0.0)
        panel.alignment = Alignment::Leading
        # minimum_width without maximum_width creates a >= constraint at priority 500.
        # NSStackView GravityAreas expands the right panel to at least 900pt,
        # filling the remainder of the 1200pt window after the 160pt sidebar.
        # minimum_height == maximum_height pins vertical fill to 856pt.
        panel.minimum_width = 900.0
        panel.minimum_height = 856.0
        panel.maximum_height = 856.0
        panel.background = panel_bg
        panel.padding = EdgeInsets.new(top: 21.0, trailing: 34.0, bottom: 21.0, leading: 34.0)

        # Section heading: General
        section_heading = Label.new("General")
        section_heading.font = Font.new(size: 17.0, weight: :semibold)
        section_heading.accessibility_label = "General settings section"
        panel << section_heading.as(View)

        gap = Spacer.new
        gap.minimum_height = 13.0
        panel << gap.as(View)

        case @focal_position
        when :single_row
          # Stub rows above the focal -- give context.
          panel << form_row("Wandering name:", Label.new("Your wandering name")).as(View)
          panel << form_row("Email:", Label.new("dispatches@amber.rift")).as(View)
          panel << Divider.new(:horizontal).as(View)

          gap2 = Spacer.new
          gap2.minimum_height = 8.0
          panel << gap2.as(View)

          # Focal row
          panel << form_row(@row_label, @focal).as(View)

          gap3 = Spacer.new
          gap3.minimum_height = 8.0
          panel << gap3.as(View)
          panel << Divider.new(:horizontal).as(View)

          # Stub rows below
          panel << form_row("Language:", Label.new("English (US)")).as(View)
          panel << form_row("Time zone:", Label.new("America/Chicago")).as(View)
        when :multi_row
          # Stub row above
          panel << form_row("Wandering name:", Label.new("Your wandering name")).as(View)
          panel << Divider.new(:horizontal).as(View)

          gap2 = Spacer.new
          gap2.minimum_height = 8.0
          panel << gap2.as(View)

          # Focal placed as a group block (spans full width of right panel).
          # Multi-row focals (toggles, buttons, sliders) benefit from full width.
          focal_container = VStack.new(spacing: 8.0)
          focal_container << @focal
          panel << focal_container.as(View)

          gap3 = Spacer.new
          gap3.minimum_height = 8.0
          panel << gap3.as(View)
          panel << Divider.new(:horizontal).as(View)

          # Stub row below
          panel << form_row("Language:", Label.new("English (US)")).as(View)
        else
          panel << @focal
        end

        panel << Spacer.new.as(View)

        panel.as(View)
      end

      # Build a single HIG form row: right-aligned label column + control column.
      # HIG: label ~120pt right-aligned, control fills remaining width, 34pt row height.
      private def form_row(label_text : String, control : View) : View
        lbl = Label.new(label_text)
        lbl.font = Font.new(size: 13.0, weight: :regular)
        lbl.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        lbl.minimum_width = 120.0
        lbl.maximum_width = 120.0
        lbl.accessibility_label = label_text

        row = HStack.new(spacing: 8.0)
        row << lbl.as(View)
        row << control
        row.minimum_height = 34.0
        row.padding = EdgeInsets.new(top: 4.0, trailing: 0.0, bottom: 4.0, leading: 0.0)
        row.accessibility_label = "Form row: #{label_text}"

        row.as(View)
      end
    end
  end
end
