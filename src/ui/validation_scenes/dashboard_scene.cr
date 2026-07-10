# DashboardScene — Phase 6 validation builder. Produces a UI::View tree of a
# dashboard with stat cards, charts, and a sheet for renderer captures.

require "../view"
require "../views/label"
require "../views/button"
require "../views/text_field"
require "../views/divider"
require "../views/card"
require "../views/sheet"
require "../views/image"
require "../views/hstack"
require "../views/vstack"
require "../views/zstack"
require "../views/spacer"
require "../views/glass_background"

module UI
  module ValidationScenes
    # DashboardScene -- legacy Amber app-context validation scene.
    #
    # Plain Crystal class (NOT a UI::View subclass). Call `.build` to get a
    # UI::View tree that the renderer can walk.
    #
    # Use this only when the selected preview stage needs app structure. Most
    # component validation should prefer the isolation/relationship contract in
    # .claude/skills/apple-platform-guide/foundations/preview-composition.md so
    # the focal component stays visually dominant.
    #
    # Layout (macOS: 3-column; iOS: single-column main area only):
    #   - Top bar: Amber wordmark (left), search field stub (center),
    #              profile avatar circle (right).
    #   - Left sidebar (~200pt): MEMORIES section + VAULTS section per amber.md.
    #   - Main area: two content cards (focus stats + recent memories).
    #   - Focal component overlaid at center with a dimmed scrim (modal
    #     presentation) for sheets/alerts/popovers/activity-views/action-sheets.
    #
    # focal_position values:
    #   :center_modal      -- focal sits centered over main area with scrim
    #   :toolbar_trailing  -- focal placed inline in top-bar trailing area
    #
    # Example:
    #   scene = DashboardScene.new(focal: my_sheet, focal_position: :center_modal)
    #   view_tree = scene.build
    #   renderer.render(view_tree)

    class DashboardScene
      property focal : View
      property focal_position : Symbol  # :center_modal or :toolbar_trailing

      def initialize(@focal : View, @focal_position : Symbol = :center_modal)
      end

      # Build only the background chrome tree (no focal overlay).
      # Used by macOS hosts that install chrome and focal as separate native views
      # so Auto Layout can center the modal card independently of the chrome.
      def build_chrome : View
        build_internal(with_focal: false)
      end

      # Build the full scene tree. Returns a UI::View tree ready for rendering.
      def build : View
        build_internal(with_focal: true)
      end

      private def build_internal(with_focal : Bool) : View
        # ----------------------------------------------------------------
        # TOP BAR
        # ----------------------------------------------------------------
        wordmark = Label.new("Amber")
        wordmark.font = Font.new(size: 15.0, weight: :semibold)
        wordmark.accessibility_label = "Amber app wordmark"

        search_stub = TextField.new("Search memories...")
        search_stub.accessibility_label = "Search field"
        search_stub.maximum_width = 280.0

        avatar_label = Label.new("A")
        avatar_label.font = Font.new(size: 13.0, weight: :semibold)
        avatar_label.accessibility_label = "Profile avatar"
        avatar_label.corner_radius = 16.0
        avatar_label.background = Color.new(r: 1.0, g: 0.678, b: 0.2)  # Amber gold
        avatar_label.padding = EdgeInsets.new(top: 4.0, trailing: 8.0, bottom: 4.0, leading: 8.0)

        top_bar = HStack.new(spacing: 13.0)
        top_bar << wordmark.as(View)
        top_bar << Spacer.new.as(View)
        top_bar << search_stub.as(View)
        top_bar << Spacer.new.as(View)
        top_bar << avatar_label.as(View)
        top_bar.padding = EdgeInsets.new(top: 13.0, trailing: 21.0, bottom: 13.0, leading: 21.0)

        top_bar_divider = Divider.new(:horizontal)

        # ----------------------------------------------------------------
        # LEFT SIDEBAR -- MEMORIES + VAULTS sections (amber.md)
        # ----------------------------------------------------------------
        sidebar = VStack.new(spacing: 4.0)
        sidebar.alignment = Alignment::Leading
        sidebar.minimum_width = 200.0
        sidebar.maximum_width = 200.0
        sidebar.padding = EdgeInsets.new(top: 13.0, trailing: 8.0, bottom: 13.0, leading: 13.0)

        memories_header = Label.new("MEMORIES")
        memories_header.font = Font.new(size: 11.0, weight: :semibold)
        memories_header.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        memories_header.accessibility_label = "Memories section header"
        sidebar << memories_header.as(View)

        [
          {"Inbox", "tray", 12},
          {"Dreamed", "moon.stars", 0},
          {"Noted", "pencil", 0},
          {"Archived", "archivebox", 0},
        ].each do |title, symbol, badge|
          row = HStack.new(spacing: 8.0)
          # Use Image so AppKit calls imageWithSystemSymbolName: and UIKit calls
          # systemImageNamed: -- both resolve the SF Symbol glyph rather than text.
          icon = Image.new(symbol)
          icon.minimum_width = 16.0
          icon.minimum_height = 16.0
          icon.content_mode = ContentMode::Fit
          icon.accessibility_label = "#{title} icon"
          lbl = Label.new(badge > 0 ? "#{title} #{badge}" : title)
          lbl.font = Font.new(size: 13.0, weight: :regular)
          lbl.accessibility_label = title
          row << icon.as(View)
          row << lbl.as(View)
          sidebar << row.as(View)
        end

        sidebar << Spacer.new.as(View)

        vaults_header = Label.new("VAULTS")
        vaults_header.font = Font.new(size: 11.0, weight: :semibold)
        vaults_header.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        vaults_header.accessibility_label = "Vaults section header"
        sidebar << vaults_header.as(View)

        [
          "Morning Pages",
          "Sketches",
          "Rituals",
          "Code Spells",
        ].each do |vault|
          vault_lbl = Label.new(vault)
          vault_lbl.font = Font.new(size: 13.0, weight: :regular)
          vault_lbl.accessibility_label = vault
          sidebar << vault_lbl.as(View)
        end

        sidebar_divider = Divider.new(:vertical)

        # ----------------------------------------------------------------
        # MAIN AREA -- two content cards
        # ----------------------------------------------------------------

        # Card 1: Today's focus
        focus_header = Label.new("Today's focus")
        focus_header.font = Font.new(size: 15.0, weight: :semibold)
        focus_header.accessibility_label = "Today's focus card heading"

        focus_stat = Label.new("2h 14m of deep work")
        focus_stat.font = Font.new(size: 22.0, weight: :bold)
        focus_stat.accessibility_label = "Deep work duration"
        focus_stat.text_color = Color.new(r: 1.0, g: 0.678, b: 0.2)  # Amber gold

        focus_ritual = Label.new("Current ritual: Morning pages")
        focus_ritual.font = Font.new(size: 13.0, weight: :regular)
        focus_ritual.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        focus_ritual.accessibility_label = "Current ritual label"

        focus_body = VStack.new(spacing: 8.0)
        focus_body << focus_header.as(View)
        focus_body << focus_stat.as(View)
        focus_body << focus_ritual.as(View)
        focus_body.padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)

        focus_card = Card.new(focus_body.as(View))
        focus_card.corner_radius = 10.0
        focus_card.accessibility_label = "Today's focus card"

        # Card 2: Recent memories (3 rows)
        mem_header = Label.new("Recent memories")
        mem_header.font = Font.new(size: 15.0, weight: :semibold)
        mem_header.accessibility_label = "Recent memories card heading"

        memory_rows = VStack.new(spacing: 8.0)
        memory_rows << mem_header.as(View)

        [
          {"sun.max",        "Morning pages", "3 entries"},
          {"hourglass",      "Deep work",     "2h 14m today"},
          {"wand.and.stars", "Rituals",       "5 tomorrow"},
        ].each do |sym, title, detail|
          mem_row = HStack.new(spacing: 13.0)
          # Use Image so the renderer calls imageWithSystemSymbolName: / systemImageNamed:
          # and the SF Symbol glyph renders rather than the symbol name as plain text.
          mem_icon = Image.new(sym)
          mem_icon.minimum_width = 20.0
          mem_icon.minimum_height = 20.0
          mem_icon.content_mode = ContentMode::Fit
          mem_icon.accessibility_label = "#{title} icon"
          mem_title_lbl = Label.new(title)
          mem_title_lbl.font = Font.new(size: 13.0, weight: :regular)
          mem_title_lbl.accessibility_label = title
          mem_detail_lbl = Label.new(detail)
          mem_detail_lbl.font = Font.new(size: 12.0, weight: :regular)
          mem_detail_lbl.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
          mem_detail_lbl.accessibility_label = "#{title} detail"
          mem_col = VStack.new(spacing: 2.0)
          mem_col << mem_title_lbl.as(View)
          mem_col << mem_detail_lbl.as(View)
          mem_row << mem_icon.as(View)
          mem_row << mem_col.as(View)
          memory_rows << mem_row.as(View)
        end

        memory_body = VStack.new(spacing: 0.0)
        memory_body << memory_rows.as(View)
        memory_body.padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)

        memory_card = Card.new(memory_body.as(View))
        memory_card.corner_radius = 10.0
        memory_card.accessibility_label = "Recent memories card"

        main_cards = VStack.new(spacing: 21.0)
        main_cards << focus_card.as(View)
        main_cards << memory_card.as(View)
        main_cards.padding = EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)

        # body_row: HStack pinned to exactly 1200pt (min==max) so NSStackView
        # GravityAreas gives it a definite frame. Fill distribution then expands
        # main_cards to fill 1200 - 200(sidebar) - 1(divider) = 999pt.
        body_row = HStack.new(spacing: 0.0)
        body_row.alignment = Alignment::Fill
        body_row.minimum_width = 1200.0
        body_row.maximum_width = 1200.0
        body_row << sidebar.as(View)
        body_row << sidebar_divider.as(View)
        body_row << main_cards.as(View)

        top_bar.minimum_width = 1200.0
        top_bar.maximum_width = 1200.0

        chrome = VStack.new(spacing: 0.0)
        chrome.alignment = Alignment::Leading
        chrome << top_bar.as(View)
        chrome << top_bar_divider.as(View)
        chrome << body_row.as(View)

        # ----------------------------------------------------------------
        # FOCAL OVERLAY
        # ----------------------------------------------------------------
        # When with_focal is false (chrome-only build), return chrome without
        # the focal. The macOS capture driver installs the focal separately via
        # objc_install_content_view_centered so Auto Layout can center the modal.
        return chrome.as(View) unless with_focal

        case @focal_position
        when :center_modal
          # Return the chrome only -- the capture driver installs the focal
          # separately via objc_install_content_view_centered. This gives
          # Auto Layout the ability to center the modal card correctly.
          # For renderers that don't support split installation (e.g. iOS
          # UIKit inline renderer), embed the focal in a centered row.
          focal_row = HStack.new(spacing: 0.0)
          focal_row << Spacer.new.as(View)
          focal_row << @focal
          focal_row << Spacer.new.as(View)

          chrome_with_focal = VStack.new(spacing: 0.0)
          chrome_with_focal << chrome.as(View)
          chrome_with_focal << focal_row.as(View)
          chrome_with_focal.as(View)
        when :bottom_sheet
          # Bottom-anchored sheet overlay for iOS.
          # HIG iOS: "a sheet slides up from the bottom of the screen."
          # The sheet renders at .medium detent equivalent (~520pt tall).
          #
          # Architecture: on iOS the 3-column desktop DashboardScene chrome
          # is too tall and wide for iPhone (1200pt minimum_width overflows).
          # For :bottom_sheet we build a compact single-column iOS backdrop:
          #   - A top bar with wordmark + search stub (no sidebar, no 3-col body).
          #   - A Spacer that fills the remaining backdrop area (dimmed via
          #     background color to simulate the HIG "app appears dimmed" effect).
          #   - The focal sheet below, flush with the bottom of the scene.
          # This keeps the total content height well under 844pt on iPhone 15.
          # HIG: "the app appears dimmed behind the sheet."

          ios_top_bar = HStack.new(spacing: 13.0)
          ios_top_bar << wordmark.as(View)
          ios_top_bar << Spacer.new.as(View)
          ios_top_bar << search_stub.as(View)
          ios_top_bar.padding = EdgeInsets.new(top: 13.0, trailing: 16.0, bottom: 13.0, leading: 16.0)
          # Pin top bar height to 60pt (13pt top+bottom padding + 34pt label).
          # Without this, UIStackViewDistributionFill expands the top bar to fill
          # the remaining safe area height, displacing the sheet glass downward.
          ios_top_bar.minimum_height = 60.0
          ios_top_bar.maximum_height = 60.0

          # Dimmed backdrop: a fixed-height band between the top bar and the sheet.
          # HIG: "the app appears dimmed behind the sheet."
          # Use UIBlurEffectStyleSystemUltraThinMaterial (GlassBackground :ultra_thin)
          # instead of a flat UIColor.black.withAlphaComponent(0.3) fill so the scrim
          # has the soft HIG-standard blur-dim rather than a hard rectangular gray band.
          # Fixed height of 80pt — enough vertical breathing room to show the blur
          # compositing against the top-bar gradient backdrop.
          # Total scene height: top_bar 60 + divider 1 + backdrop 80 + focal = well
          # within the safe content area of iPhone 15 (~796pt below status bar).
          backdrop_area = GlassBackground.new(material: :ultra_thin)
          backdrop_area.minimum_height = 80.0
          backdrop_area.maximum_height = 80.0
          backdrop_area.accessibility_label = "Dimmed backdrop"

          ios_scene = VStack.new(spacing: 0.0)
          ios_scene.alignment = Alignment::Fill
          ios_scene << ios_top_bar.as(View)
          ios_scene << Divider.new(:horizontal).as(View)
          ios_scene << backdrop_area.as(View)
          ios_scene << @focal
          ios_scene.as(View)
        when :toolbar_trailing
          # Focal placed inline in the toolbar trailing area (for menus
          # that pop from toolbar buttons, e.g. pull-down buttons).
          toolbar_with_focal = HStack.new(spacing: 13.0)
          toolbar_with_focal << wordmark.as(View)
          toolbar_with_focal << Spacer.new.as(View)
          toolbar_with_focal << search_stub.as(View)
          toolbar_with_focal << Spacer.new.as(View)
          toolbar_with_focal << @focal

          body_with_focal = VStack.new(spacing: 0.0)
          body_with_focal << toolbar_with_focal.as(View)
          body_with_focal << top_bar_divider.as(View)
          body_with_focal << body_row.as(View)
          body_with_focal.as(View)
        else
          chrome.as(View)
        end
      end
    end
  end
end
