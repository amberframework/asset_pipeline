# InboxScene — Phase 6 validation builder. Produces a UI::View tree of an email /
# messaging inbox list-and-detail composition for renderer captures.

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
require "../views/list_view"

module UI
  module ValidationScenes
    # InboxScene -- Amber 2-pane inbox (sidebar + message list / detail).
    #
    # Plain Crystal class (NOT a UI::View subclass). Call `.build` to get a
    # UI::View tree the renderer can walk.
    #
    # Layout:
    #   - Left sidebar column (~200pt): MEMORIES section (Inbox 12 / Dreamed /
    #     Noted / Archived) + VAULTS section (Morning Pages / Sketches /
    #     Rituals / Code Spells). Real SF Symbol glyphs via UI::Image.
    #   - Right content area: message list with 4-5 Amber-voice messages
    #     (sender / subject / preview) OR a message detail pane (for
    #     sidebars re-capture). Focal component replaces or augments
    #     the right pane depending on focal_position.
    #
    # focal_position values:
    #   :left_pane    -- focal replaces the left sidebar column
    #   :right_pane   -- focal replaces the right message list content area
    #   :full_2pane   -- focal spans full width (sidebar + right), used for
    #                    split-views where the focal IS the 2-pane container
    #
    # Example:
    #   scene = InboxScene.new(focal: sidebar_view, focal_position: :left_pane)
    #   view_tree = scene.build
    #   renderer.render(view_tree)

    class InboxScene
      property focal : View
      property focal_position : Symbol # :left_pane | :right_pane | :full_2pane

      def initialize(@focal : View, @focal_position : Symbol = :right_pane)
      end

      # Build the full scene tree. Returns a UI::View tree ready for rendering.
      def build : View
        # ----------------------------------------------------------------
        # TITLE BAR
        # ----------------------------------------------------------------
        wordmark = Label.new("Amber")
        wordmark.font = Font.new(size: 15.0, weight: :semibold)
        wordmark.accessibility_label = "Amber app wordmark"

        inbox_title = Label.new("Inbox")
        inbox_title.font = Font.new(size: 17.0, weight: :semibold)
        inbox_title.accessibility_label = "Inbox title"

        compose_btn = Button.new("Compose", symbol: "square.and.pencil")
        compose_btn.accessibility_label = "Compose new message"

        top_bar = HStack.new(spacing: 13.0)
        top_bar << wordmark.as(View)
        top_bar << Spacer.new.as(View)
        top_bar << inbox_title.as(View)
        top_bar << Spacer.new.as(View)
        top_bar << compose_btn.as(View)
        top_bar.padding = EdgeInsets.new(top: 13.0, trailing: 21.0, bottom: 13.0, leading: 21.0)

        top_bar_divider = Divider.new(:horizontal)

        # ----------------------------------------------------------------
        # LEFT SIDEBAR -- MEMORIES + VAULTS sections
        # ----------------------------------------------------------------
        sidebar = build_sidebar

        sidebar_divider = Divider.new(:vertical)

        # ----------------------------------------------------------------
        # RIGHT CONTENT -- message list
        # ----------------------------------------------------------------
        message_list = build_message_list

        # ----------------------------------------------------------------
        # ASSEMBLE BASED ON focal_position
        # ----------------------------------------------------------------
        case @focal_position
        when :left_pane
          # Focal replaces the left sidebar. body_row is pinned to exactly
          # 1200pt (min==max) so NSStackView GravityAreas gives it a definite
          # frame; Fill distribution then expands the message_list to fill
          # remaining space after the focal pane and the 1pt divider.
          # Vertical pin (min==max=856) fills below the 44pt title bar.
          is_dark = ENV["HIG_APPEARANCE"]? == "dark"
          page_bg = is_dark ? Color.new(r: 0.165, g: 0.102, b: 0.031) :
                              Color.new(r: 0.980, g: 0.965, b: 0.941)

          body_row = HStack.new(spacing: 0.0)
          body_row.alignment = Alignment::Fill
          body_row.minimum_width = 1200.0
          body_row.maximum_width = 1200.0
          body_row.minimum_height = 856.0
          body_row.maximum_height = 856.0
          body_row << @focal
          body_row << sidebar_divider.as(View)
          body_row << message_list.as(View)

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
          page.background = page_bg
          page << top_bar.as(View)
          page << top_bar_divider.as(View)
          page << body_row.as(View)
          page.as(View)
        when :right_pane
          # Sidebar is 200pt (min==max). body_row is pinned to 1200pt;
          # Fill distribution expands focal to fill 1200-200-1=999pt.
          # Vertical pin (min==max=856) fills below the 44pt title bar.
          body_row = HStack.new(spacing: 0.0)
          body_row.alignment = Alignment::Fill
          body_row.minimum_width = 1200.0
          body_row.maximum_width = 1200.0
          body_row.minimum_height = 856.0
          body_row.maximum_height = 856.0
          body_row << sidebar.as(View)
          body_row << sidebar_divider.as(View)
          body_row << @focal

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
          page << body_row.as(View)
          page.as(View)
        when :full_2pane
          # Focal is the split-view itself; wrap in app chrome only.
          # The page VStack gets a solid background so the peach backdrop
          # gradient does NOT leak between the title bar and the focal pane.
          # Uses the same Amber surface tokens as SettingsScene.
          is_dark = ENV["HIG_APPEARANCE"]? == "dark"
          page_bg = is_dark ? Color.new(r: 0.165, g: 0.102, b: 0.031) :
                              Color.new(r: 0.980, g: 0.965, b: 0.941)

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
          page.background = page_bg
          page << top_bar.as(View)
          page << top_bar_divider.as(View)
          page << @focal
          page.as(View)
        else
          # Fallback: focal appended below the 2-pane body.
          body_row = HStack.new(spacing: 0.0)
          body_row.alignment = Alignment::Fill
          body_row.minimum_width = 1200.0
          body_row.maximum_width = 1200.0
          body_row.minimum_height = 856.0
          body_row.maximum_height = 856.0
          body_row << sidebar.as(View)
          body_row << sidebar_divider.as(View)
          body_row << message_list.as(View)

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
          page << body_row.as(View)
          page << @focal
          page.as(View)
        end
      end

      private def build_sidebar : View
        sidebar = VStack.new(spacing: 4.0)
        sidebar.alignment = Alignment::Leading
        sidebar.minimum_width = 200.0
        sidebar.maximum_width = 200.0
        sidebar.minimum_height = 856.0
        sidebar.maximum_height = 856.0
        sidebar.padding = EdgeInsets.new(top: 13.0, trailing: 8.0, bottom: 13.0, leading: 13.0)

        # MEMORIES section header
        mem_header = Label.new("MEMORIES")
        mem_header.font = Font.new(size: 11.0, weight: :semibold)
        mem_header.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        mem_header.accessibility_label = "Memories section header"
        sidebar << mem_header.as(View)

        [
          {"tray", "Inbox", 12},
          {"moon.stars", "Dreamed", 0},
          {"pencil", "Noted", 0},
          {"archivebox", "Archived", 0},
        ].each_with_index do |(symbol, title, badge), idx|
          row = HStack.new(spacing: 8.0)
          icon = Image.new(symbol)
          icon.minimum_width = 16.0
          icon.minimum_height = 16.0
          icon.content_mode = ContentMode::Fit
          icon.accessibility_label = "#{title} icon"

          lbl = Label.new(badge > 0 ? "#{title} #{badge}" : title)
          lbl.font = Font.new(size: 13.0, weight: idx == 0 ? :semibold : :regular)
          lbl.accessibility_label = title
          # Inbox row highlighted as selected (Amber gold tint)
          if idx == 0
            lbl.text_color = Color.new(r: 1.0, g: 0.678, b: 0.2)
          end

          row << icon.as(View)
          row << lbl.as(View)
          sidebar << row.as(View)
        end

        sidebar << Spacer.new.as(View)

        # VAULTS section header
        vaults_header = Label.new("VAULTS")
        vaults_header.font = Font.new(size: 11.0, weight: :semibold)
        vaults_header.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        vaults_header.accessibility_label = "Vaults section header"
        sidebar << vaults_header.as(View)

        [
          {"book", "Morning Pages"},
          {"scribble", "Sketches"},
          {"sparkles", "Rituals"},
          {"terminal", "Code Spells"},
        ].each do |symbol, vault_name|
          row = HStack.new(spacing: 8.0)
          icon = Image.new(symbol)
          icon.minimum_width = 16.0
          icon.minimum_height = 16.0
          icon.content_mode = ContentMode::Fit
          icon.accessibility_label = "#{vault_name} vault icon"

          lbl = Label.new(vault_name)
          lbl.font = Font.new(size: 13.0, weight: :regular)
          lbl.accessibility_label = vault_name

          row << icon.as(View)
          row << lbl.as(View)
          sidebar << row.as(View)
        end

        sidebar.as(View)
      end

      private def build_message_list : View
        messages_area = VStack.new(spacing: 0.0)
        messages_area.alignment = Alignment::Leading
        messages_area.padding = EdgeInsets.new(top: 13.0, trailing: 21.0, bottom: 13.0, leading: 21.0)

        list_header = Label.new("12 messages")
        list_header.font = Font.new(size: 11.0, weight: :regular)
        list_header.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        list_header.accessibility_label = "Message count"
        messages_area << list_header.as(View)

        messages = [
          {"Amber", "Morning pages unlocked", "Your 3-page ritual is complete. Amber noticed the shift."},
          {"Rituals", "5 rituals due tomorrow", "Morning pages, breathwork, evening review, and 2 more."},
          {"Vault", "248 artifacts archived", "Your vault is thriving. The rift is stable."},
          {"Deep Work", "2h 14m today \u00B7 new record", "You outran yesterday's session. Amber is holding the streak."},
          {"Amber", "Memory synced across rift", "Your vault is up to date. Nothing was lost."},
        ]

        messages.each_with_index do |(sender, subject, preview), idx|
          row = build_message_row(sender, subject, preview, unread: idx < 2)
          messages_area << row.as(View)
          if idx < messages.size - 1
            messages_area << Divider.new(:horizontal).as(View)
          end
        end

        messages_area.as(View)
      end

      private def build_message_row(sender : String, subject : String, preview : String, unread : Bool) : View
        # Unread indicator dot (Amber gold circle approximated as a short label)
        indicator = Label.new(unread ? "\u25CF" : " ")
        indicator.font = Font.new(size: 9.0, weight: :regular)
        indicator.text_color = Color.new(r: 1.0, g: 0.678, b: 0.2)
        indicator.minimum_width = 12.0
        indicator.accessibility_label = unread ? "Unread" : ""

        # HIG inset-grouped cell: sender 15pt Semibold, subject 13pt Regular,
        # preview 12pt Regular Secondary. Row height 72pt (HIG standard cell).
        sender_lbl = Label.new(sender)
        sender_lbl.font = Font.new(size: 15.0, weight: unread ? :semibold : :regular)
        sender_lbl.accessibility_label = "From: #{sender}"

        subject_lbl = Label.new(subject)
        subject_lbl.font = Font.new(size: 13.0, weight: unread ? :semibold : :regular)
        subject_lbl.accessibility_label = "Subject: #{subject}"

        preview_lbl = Label.new(preview)
        preview_lbl.font = Font.new(size: 12.0, weight: :regular)
        preview_lbl.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        preview_lbl.accessibility_label = "Preview: #{preview}"

        text_col = VStack.new(spacing: 2.0)
        text_col << sender_lbl.as(View)
        text_col << subject_lbl.as(View)
        text_col << preview_lbl.as(View)

        # 72pt row height is HIG standard for inset-grouped message cells.
        # Top/bottom padding = (72 - ~36pt of 3-line text stack) / 2 = ~18pt each.
        row = HStack.new(spacing: 8.0)
        row << indicator.as(View)
        row << text_col.as(View)
        row << Spacer.new.as(View)
        row.minimum_height = 72.0
        row.maximum_height = 72.0
        row.padding = EdgeInsets.new(top: 18.0, trailing: 0.0, bottom: 18.0, leading: 0.0)
        row.accessibility_label = "Message from #{sender}: #{subject}"

        row.as(View)
      end
    end
  end
end
