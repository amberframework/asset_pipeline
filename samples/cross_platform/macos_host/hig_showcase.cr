# HIG showcase host for macOS visual validation.
#
# Builds exactly ONE UI::View (selected by slug) and displays it on a native
# AppKit window. The window title is "HIG: <slug>" so the AXTest harness
# can find it by title and screenshot it.
#
# Slug source (in priority order):
#   1. ENV["HIG_SLUG"]
#   2. ARGV[0]
#   3. default "buttons"
#
# Usage:
#   HIG_SLUG=toggles ./bin/hig_showcase
#   ./bin/hig_showcase buttons
#
# Build: see samples/cross_platform/macos_host/Makefile.

require "json"
require "../../../src/ui"
require "../../../src/ui/validation_scenes"
require "../../../src/ui/probes"

{% if flag?(:macos) %}
  SLUG          = ENV["HIG_SLUG"]? || ARGV[0]? || "buttons"
  WORKLIST_PATH = File.expand_path("../../../.claude/skills/apple-platform-guide/validation/worklist.json", __DIR__)
  BACKDROPS_DIR = File.expand_path("../../../.claude/skills/apple-platform-guide/validation/backdrops", __DIR__)

  def resolved_backdrop_path(slug : String, appearance : String) : String?
    return nil unless File.exists?(WORKLIST_PATH)

    pages = JSON.parse(File.read(WORKLIST_PATH))["pages"].as_a?
    return nil unless pages

    page = pages.find do |page_json|
      page_json["slug"]?.try(&.as_s?) == slug
    end
    return nil unless page

    stem = page["backdrop"]?.try(&.as_s?)
    return nil unless stem

    macos_candidate = File.join(BACKDROPS_DIR, "#{stem}-macos-#{appearance}.png")
    return macos_candidate if File.exists?(macos_candidate)

    shared_candidate = File.join(BACKDROPS_DIR, "#{stem}-#{appearance}.png")
    return shared_candidate if File.exists?(shared_candidate)

    nil
  end

  # ---------------------------------------------------------------------------
  # Scene dispatch
  # ---------------------------------------------------------------------------
  #
  # Scene composers provide only the context required to judge the HIG component.
  # Default preview guidance lives in:
  # .claude/skills/apple-platform-guide/foundations/preview-composition.md
  #
  # Prefer an isolation-style component study. Use app chrome only when the slug's
  # HIG behavior depends on structure such as sidebars, toolbars, or split views.
  #
  # scene_for_slug returns the scene name for a given slug, or nil if the slug
  # renders without a scene (raw component fill).
  #
  # Scene wrapping is triggered automatically by the capture path when the
  # returned scene is non-nil.

  SLUG_SCENES = {
    # Iter A -- pilot scenes
    "sheets"        => "dashboard",
    "alerts"        => "dashboard",
    "popovers"      => "dashboard",
    "action-sheets" => "dashboard",
    "edit-menus"    => "ambient",
    "context-menus" => "ambient",
    "dock-menus"    => "dock",
    # Iter B -- inbox scene
    "sidebars"         => "inbox",
    "split-views"      => "inbox",
    "lists-and-tables" => "inbox",
    # Iter B -- gallery scene
    "collections"       => "ambient",
    "image-views"       => "gallery",
    "rating-indicators" => "ambient",
    "page-controls"     => "gallery",
    # Iter B -- chart scene
    "charts"              => "ambient",
    "progress-indicators" => "ambient",
    # Iter B -- settings scene
    "buttons"             => "settings",
    "toggles"             => "ambient",
    "sliders"             => "ambient",
    "steppers"            => "ambient",
    "pickers"             => "ambient",
    "segmented-controls"  => "ambient",
    "pop-up-buttons"      => "ambient",
    "pull-down-buttons"   => "ambient",
    "disclosure-controls" => "settings",
    "color-wells"         => "settings",
    "combo-boxes"         => "settings",
    # Iter B -- ambient scene additions
    "menus" => "ambient",
    # Iter B -- dashboard scene additions
    "activity-views" => "dashboard",
    # Iter B -- ambient scene
    "text-fields"   => "ambient",
    "text-views"    => "ambient",
    "search-fields" => "ambient",
    "labels"        => "ambient",
    "column-views"  => "ambient",
    "token-fields"  => "ambient",
    "image-wells"   => "ambient",
    "gauges"        => "ambient",
    "activity-rings" => "ambient",
    "boxes"         => "ambient",
    "outline-views" => "ambient",
    "panels"        => "ambient",
    "path-controls" => "ambient",
    "maps"          => "ambient",
    "playing-video" => "ambient",
    "scroll-views"  => "ambient",
    "toolbars"      => "ambient",
    "tab-bars"      => "ambient",
    "tab-views"     => "ambient",
  } of String => String

  def scene_for_slug(slug : String) : String?
    SLUG_SCENES[slug]?
  end

  # Wrap a focal component in the appropriate scene composer.
  # focal_position is per-scene (see each scene class for valid values).
  def wrap_in_scene(slug : String, focal : UI::View) : UI::View
    case SLUG_SCENES[slug]?
    when "dashboard"
      fp = case slug
           when "toolbars", "tab-bars", "tab-views" then :toolbar_trailing
           when "activity-views"                    then :center_modal
           else                                          :center_modal
           end
      scene = UI::ValidationScenes::DashboardScene.new(focal: focal, focal_position: fp)
      scene.build
    when "document"
      scene = UI::ValidationScenes::DocumentScene.new(focal: focal, focal_position: :adjacent_to_selection)
      scene.build
    when "dock"
      scene = UI::ValidationScenes::DockScene.new(focal: focal, focal_position: :above_dock_icon)
      scene.build
    when "inbox"
      fp = case slug
           when "sidebars"         then :full_2pane
           when "split-views"      then :full_2pane
           when "lists-and-tables" then :right_pane
           else                         :right_pane
           end
      scene = UI::ValidationScenes::InboxScene.new(focal: focal, focal_position: fp)
      scene.build
    when "gallery"
      fp = case slug
           when "image-views"       then :grid_full
           when "rating-indicators" then :inline_rows
           when "page-controls"     then :carousel
           else                          :grid_full
           end
      scene = UI::ValidationScenes::GalleryScene.new(focal: focal, focal_position: fp)
      scene.build
    when "chart"
      fp = case slug
           when "progress-indicators" then :inline_rows
           else                            :card_focal
           end
      scene = UI::ValidationScenes::ChartScene.new(focal: focal, focal_position: fp)
      scene.build
    when "settings"
      row_lbl, fp = case slug
                    when "buttons"             then {"Buttons:", :multi_row}
                    when "toggles"             then {"Toggles:", :multi_row}
                    when "sliders"             then {"Sliders:", :multi_row}
                    when "disclosure-controls" then {"Disclosure:", :multi_row}
                    when "color-wells"         then {"Color wells:", :multi_row}
                    when "steppers"            then {"Quantity:", :single_row}
                    when "pickers"             then {"Select vault:", :single_row}
                    when "segmented-controls"  then {"View:", :single_row}
                    when "pop-up-buttons"      then {"Sort by:", :single_row}
                    when "pull-down-buttons"   then {"Share via:", :single_row}
                    when "combo-boxes"         then {"Ritual type:", :single_row}
                    else                            {"Setting:", :single_row}
                    end
      scene = UI::ValidationScenes::SettingsScene.new(focal: focal, focal_position: fp, row_label: row_lbl)
      scene.build
    when "ambient"
      scene = UI::ValidationScenes::AmbientScene.new(focal: focal, focal_position: :centered)
      scene.build
    else
      focal
    end
  end

  # ---------------------------------------------------------------------------
  # Component dispatch
  # ---------------------------------------------------------------------------
  #
  # Each case arm constructs a single UI::View instance. Constructor
  # signatures mirror src/ui/views/<name>.cr exactly -- unknown slugs fall
  # through to a Label placeholder so the host still opens a window (agents
  # rely on the "HIG: <slug>" window existing to know the binary launched).

  def build_component(slug : String) : UI::View
    case slug
    when "alerts"
      # Amber alert: "Reshape today's timeline?" — destructive action erases 3h of
      # context. HIG: "Use the destructive style to identify a button that performs
      # a destructive action people didn't deliberately choose." — Alerts / Best practices.
      # Cancel on leading side; Reshape (Amber plum destructive) on trailing side.
      # NSVisualEffectView hudWindow material (7) — HIG surface component.
      alert = UI::Alert.new("Reshape today's timeline?", "This will erase 3 hours of context. Amber cannot restore them.")
      alert.add_button("Cancel", :cancel)
      alert.add_button("Reshape", :destructive)
      alert.as(UI::View)
    when "action-sheets"
      # Amber action sheet gallery — three variants in a VStack.
      # HIG: "Make destructive choices visually prominent... place these buttons
      # at the top of the action sheet where they tend to be most noticeable."
      # HIG: "Place the Cancel button at the bottom of the action sheet."
      # Four buttons per brand/amber.md Action sheet content library.
      # Rendered inline (NOT via is_presented) so the host window shows content.
      # NSVisualEffectView grouped_card material (setMaterial: 11) tracks appearance.
      # Corner radius 16pt (Amber phi-scale "sheet" token). June R5 fix.

      # --- Variant A: Primary (4-action) -- full Amber draft management flow ---
      main_content = UI::VStack.new(spacing: 8.0)
      main_label = UI::Label.new("What should Amber do with this draft?")
      main_label.font = UI::Font.new(size: 15.0, weight: :semibold)
      main_label.accessibility_label = "Action sheet prompt"
      main_content << main_label.as(UI::View)
      main_content << UI::Button.new("Banish draft forever", role: :destructive)
      main_content << UI::Button.new("Archive to vault")
      main_content << UI::Button.new("Conjure copy")
      main_content << UI::Button.new("Never mind", role: :cancel)
      main_sheet = UI::Sheet.new(main_content.as(UI::View), surface_style: :grouped_card)
      main_sheet.accessibility_label = "Action sheet: draft management"

      # --- Variant B: 2-action confirm (destructive + cancel only, R10) ---
      confirm_content = UI::VStack.new(spacing: 8.0)
      confirm_title = UI::Label.new("Banish this memory permanently?")
      confirm_title.font = UI::Font.new(size: 15.0, weight: :semibold)
      confirm_title.accessibility_label = "Confirmation prompt"
      confirm_detail = UI::Label.new("Amber cannot retrieve a banished memory.")
      confirm_detail.font = UI::Font.new(size: 13.0, weight: :regular)
      confirm_content << confirm_title.as(UI::View)
      confirm_content << confirm_detail.as(UI::View)
      confirm_content << UI::Button.new("Banish forever", role: :destructive)
      confirm_content << UI::Button.new("Keep it", role: :cancel)
      confirm_sheet = UI::Sheet.new(confirm_content.as(UI::View), surface_style: :grouped_card)
      confirm_sheet.accessibility_label = "Action sheet: 2-action confirm"

      # --- Variant C: title+message with no cancel (edge-case, R10) ---
      # HIG: "Avoid using a cancel button with a destructive action sheet
      # ... to avoid ambiguity." Demonstrates no-cancel edge case.
      edge_content = UI::VStack.new(spacing: 8.0)
      edge_title = UI::Label.new("Delete all synced memories?")
      edge_title.font = UI::Font.new(size: 15.0, weight: :semibold)
      edge_title.accessibility_label = "Edge-case prompt"
      edge_msg = UI::Label.new("All 142 memories will be removed from this device. Amber Cloud copies remain intact.")
      edge_msg.font = UI::Font.new(size: 13.0, weight: :regular)
      edge_content << edge_title.as(UI::View)
      edge_content << edge_msg.as(UI::View)
      edge_content << UI::Button.new("Delete from device", role: :destructive)
      edge_sheet = UI::Sheet.new(edge_content.as(UI::View), surface_style: :grouped_card)
      edge_sheet.accessibility_label = "Action sheet: destructive-only edge case"

      # Stack the three variants vertically for the gallery capture.
      gallery = UI::VStack.new(spacing: 21.0)
      gallery.accessibility_label = "Action sheet gallery"
      gallery << main_sheet.as(UI::View)
      gallery << confirm_sheet.as(UI::View)
      gallery << edge_sheet.as(UI::View)
      gallery.as(UI::View)
    when "activity-views"
      # UI::ActivityView — four-zone share sheet component.
      # HIG: "An activity view — often called a share sheet — presents a range
      # of tasks that people can perform in the current context."
      # HIG Platform considerations: "Not supported in macOS, tvOS, or watchOS."
      # The macOS renderer emits an NSVisualEffectView (popover material)
      # approximation with all four HIG layout zones inline.
      # Amber content per brand/amber.md: five destinations including Vault;
      # actions updated to Save to Files / Conjure copy / Copy / Print.
      # accessibility_label required per HIG interactive-element rule.
      act_macos = UI::ActivityView.new(
        title: "Nature Walks",
        subtitle: "12 photos · 3.4 MB",
        thumbnail: UI::Image.new("photo"),
        destinations: [
          UI::ActivityDestination.new(icon_symbol: "envelope", label: "Mail"),
          UI::ActivityDestination.new(icon_symbol: "message", label: "Messages"),
          UI::ActivityDestination.new(icon_symbol: "wifi", label: "AirDrop"),
          UI::ActivityDestination.new(icon_symbol: "note.text", label: "Notes"),
          UI::ActivityDestination.new(icon_symbol: "archivebox", label: "Vault"),
        ],
        actions: [
          UI::ActivityAction.new(icon_symbol: "folder", label: "Save to Files"),
          UI::ActivityAction.new(icon_symbol: "wand.and.stars", label: "Conjure copy"),
          UI::ActivityAction.new(icon_symbol: "doc.on.doc", label: "Copy"),
          UI::ActivityAction.new(icon_symbol: "printer", label: "Print"),
        ],
        on_cancel: -> { }
      )
      act_macos.accessibility_label = "Activity view: Nature Walks share sheet"
      act_macos.as(UI::View)
    when "boxes"
      # HIG Box (UI::Card -> NSBox on macOS, UIView on iOS): a visually distinct
      # grouped surface. HIG abstract: "A box creates a visually distinct group
      # of logically related information and components." HIG content guidance:
      # "Provide a succinct introductory title if it helps clarify the box's
      # contents" -- we render title + body text + a couple of label/value rows
      # to exercise the grouped surface chrome. Pure surface demo: no role-colored
      # buttons (that would trigger the known UI::Button#role gap from gaps.md).
      box_body = UI::VStack.new(spacing: 10.0)
      box_body.alignment = UI::Alignment::Leading
      box_body.padding = UI::EdgeInsets.new(top: 16.0, trailing: 18.0, bottom: 16.0, leading: 18.0)
      box_intro = UI::Label.new("Your order ships in a reusable padded mailer.")
      box_intro.font = UI::Font.new(size: 13.0, weight: :regular)
      box_body << box_intro.as(UI::View)
      row1 = UI::HStack.new(spacing: 12.0)
      row1.alignment = UI::Alignment::Center
      carrier_label = UI::Label.new("Carrier")
      carrier_label.font = UI::Font.new(size: 12.0, weight: :semibold)
      carrier_label.text_color = UI::Color.new(r: 0.45, g: 0.45, b: 0.45)
      carrier_value = UI::Label.new("USPS Ground")
      carrier_value.font = UI::Font.new(size: 13.0, weight: :regular)
      row1 << carrier_label.as(UI::View)
      row1 << UI::Spacer.new.as(UI::View)
      row1 << carrier_value.as(UI::View)
      row2 = UI::HStack.new(spacing: 12.0)
      row2.alignment = UI::Alignment::Center
      arrival_label = UI::Label.new("Estimated arrival")
      arrival_label.font = UI::Font.new(size: 12.0, weight: :semibold)
      arrival_label.text_color = UI::Color.new(r: 0.45, g: 0.45, b: 0.45)
      arrival_value = UI::Label.new("Apr 17 - Apr 19")
      arrival_value.font = UI::Font.new(size: 13.0, weight: :regular)
      row2 << arrival_label.as(UI::View)
      row2 << UI::Spacer.new.as(UI::View)
      row2 << arrival_value.as(UI::View)
      box_body << row1
      box_body << row2
      card = UI::Card.new(box_body.as(UI::View))
      card.title = "Shipping details"
      card.is_outlined = true
      card.minimum_width = 420.0
      card.maximum_width = 420.0
      card.as(UI::View)
    when "collections"
      # HIG Collections: "A collection manages an ordered set of content and
      # presents it in a customizable and highly visual layout."
      # We render a compact 3-column photo-tile grid using UI::ListView in grid
      # mode (layout: :grid, columns: 3). Each tile is a VStack with a placeholder
      # image label and a caption label below it.
      make_tile = ->(symbol : String, caption : String) do
        tile = UI::VStack.new(spacing: 4.0)
        tile.alignment = UI::Alignment::Center
        tile.minimum_width = 114.0
        tile.maximum_width = 114.0
        tile.minimum_height = 110.0
        tile.padding = UI::EdgeInsets.new(top: 10.0, trailing: 8.0, bottom: 10.0, leading: 8.0)
        tile.corner_radius = 10.0
        tile.background = UI::Color.new(r: 0.96, g: 0.92, b: 0.86, a: 0.78)
        thumb = UI::Image.new(symbol)
        thumb.minimum_width = 40.0
        thumb.minimum_height = 40.0
        thumb.content_mode = UI::ContentMode::Fit
        thumb.tint_color = UI::Color.new(r: 0.36, g: 0.23, b: 0.58)
        cap = UI::Label.new(caption)
        cap.font = UI::Font.new(size: 11.0, weight: :regular)
        cap.text_color = UI::Color.new(r: 0.45, g: 0.45, b: 0.45)
        tile << thumb.as(UI::View)
        tile << cap.as(UI::View)
        tile.as(UI::View)
      end
      tiles = [
        make_tile.call("mountain.2", "Big Sur"),
        make_tile.call("sunrise", "Morning"),
        make_tile.call("figure.walk", "Trail"),
        make_tile.call("cup.and.saucer", "Coffee"),
        make_tile.call("sunset", "Sunset"),
        make_tile.call("water.waves", "Coast"),
        make_tile.call("leaf", "Forest"),
        make_tile.call("drop", "Lake"),
        make_tile.call("building.2", "City"),
      ]
      section = UI::ListView::Section.new(header: "Photos", items: tiles)
      list = UI::ListView.new(sections: [section], style: UI::ListStyle::Plain, layout: UI::ListLayout::Grid, columns: 3)
      list.item_spacing = 12.0
      list.minimum_width = 400.0
      list.maximum_width = 400.0
      list.minimum_height = 372.0
      list.background = UI::Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.0)
      list.shows_separators = false
      collections_card = UI::Card.new(list.as(UI::View))
      collections_card.minimum_width = 448.0
      collections_card.maximum_width = 448.0
      collections_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      collections_card.is_outlined = true
      collections_card.material = :secondary
      collections_card.accessibility_label = "Collections study card"
      collections_card.as(UI::View)
    when "lists-and-tables"
      # HIG "Lists and tables" gallery -- iter-31.
      # Three sections showcasing the three most important HIG list shapes:
      #   1. Plain list (hairline dividers, no card wrapper)
      #   2. Inset-grouped list (rounded 10pt card, grouped rows)
      #   3. Accessory rows (trailing chevron + trailing value text)
      # HIG Best practices: "Prefer displaying text in a list or table.
      # A table can include any type of content, but the row-based format
      # is especially well suited to making text easy to scan and read."
      # HIG iOS Platform considerations: "If you need to let people drill
      # into a list or table row's subviews, use a disclosure indicator
      # accessory control."
      #
      # Row factory: primary label + spacer + trailing accessory label.
      lt_row = ->(title : String, trailing : String) do
        r = UI::HStack.new(spacing: 12.0)
        r << UI::Label.new(title)
        r << UI::Spacer.new
        tl = UI::Label.new(trailing)
        tl.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
        r << tl.as(UI::View)
        r.as(UI::View)
      end

      gallery = UI::VStack.new(spacing: 16.0)

      # -- Section 1: Plain list --
      plain_heading = UI::Label.new("Plain List")
      gallery << plain_heading.as(UI::View)
      plain_items = [
        lt_row.call("Mail", ""),
        lt_row.call("Messages", ""),
        lt_row.call("Notes", ""),
        lt_row.call("Reminders", ""),
      ] of UI::View
      plain_section = UI::ListView::Section.new(items: plain_items)
      plain_list = UI::ListView.new(sections: [plain_section], style: UI::ListStyle::Plain)
      plain_list.shows_separators = true
      gallery << plain_list.as(UI::View)

      gallery << UI::Divider.new(:horizontal).as(UI::View)

      # -- Section 2: Inset-grouped (rounded card) --
      grouped_heading = UI::Label.new("Inset-Grouped List")
      gallery << grouped_heading.as(UI::View)
      grouped_items = [
        lt_row.call("General", "\u276F"),
        lt_row.call("Appearance", "\u276F"),
        lt_row.call("Sounds & Haptics", "\u276F"),
      ] of UI::View
      grouped_section = UI::ListView::Section.new(header: "Settings", items: grouped_items)
      grouped_list = UI::ListView.new(sections: [grouped_section], style: UI::ListStyle::InsetGrouped)
      grouped_list.shows_separators = true
      gallery << grouped_list.as(UI::View)

      gallery << UI::Divider.new(:horizontal).as(UI::View)

      # -- Section 3: Accessory rows (chevron + value) --
      acc_heading = UI::Label.new("Row Accessories")
      gallery << acc_heading.as(UI::View)
      acc_items = [
        lt_row.call("Wi-Fi", "HomeNet \u276F"),
        lt_row.call("Bluetooth", "On"),
        lt_row.call("Cellular", "\u276F"),
      ] of UI::View
      acc_section = UI::ListView::Section.new(items: acc_items)
      acc_list = UI::ListView.new(sections: [acc_section], style: UI::ListStyle::Grouped)
      acc_list.shows_separators = true
      gallery << acc_list.as(UI::View)

      gallery.as(UI::View)
    when "context-menus"
      # HIG context menu content surface: a short list of task-specific commands
      # revealed by secondary-click. The showcase uses the dedicated
      # UI::ContextMenu surface so the screenshot exercises the menu rows
      # without any extra host chrome competing for attention.
      menu = UI::ContextMenu.new
      menu.minimum_width = 240.0
      menu.maximum_width = 240.0
      menu.accessibility_label = "Selection context menu"
      menu.add_item("Cut", icon: "scissors")
      menu.add_item("Copy", icon: "doc.on.doc")
      menu.add_item("Paste", icon: "clipboard")
      menu.add_separator
      menu.add_item("Share...", icon: "square.and.arrow.up")
      menu.add_item("Duplicate", icon: "square.on.square")
      menu.add_separator
      menu.add_item("Delete", icon: "trash", is_destructive: true)
      menu.as(UI::View)
    when "digit-entry-views"
      # HIG digit entry view: a full-screen PIN / passcode entry surface.
      # HIG abstract: "A digit entry view fills the entire screen and prompts
      # people to enter a series of digits, like a PIN, using a digit-specific
      # keyboard." HIG Platform considerations explicitly say: "Not supported
      # in iOS, iPadOS, macOS, visionOS, or watchOS" -- this component is
      # tvOS-only (TVDigitEntryViewController). Since our validation host
      # targets iOS + macOS, we render a HIG-faithful *visual mock* using
      # UI::TextField primitives: a title, prompt, and a horizontal row of
      # 6 secure-entry TextField cells. This exercises the HIG "line of
      # digits" visual and the secure-entry recommendation ("Use secure
      # digit fields. Secure digit fields display asterisks instead of the
      # entered digit onscreen"). Deviations (no per-digit boxed chrome on
      # UI::TextField, no numeric-only keyboard constraint on macOS) are
      # the expected systemic gap and are documented in the report.
      content = UI::VStack.new(spacing: 12.0)
      content << UI::Label.new("Enter Passcode")
      content << UI::Label.new("Enter the 6-digit code sent to your device.")
      digit_row = UI::HStack.new(spacing: 8.0)
      6.times do
        cell = UI::TextField.new("·")
        cell.secure_entry = true
        cell.keyboard_type = UI::KeyboardType::NumberPad
        digit_row << cell
      end
      content << digit_row.as(UI::View)
      content.as(UI::View)
    when "disclosure-controls"
      # HIG "Disclosure controls" -- both shapes documented in HIG:
      #   (1) Disclosure triangle: "points inward from the leading edge
      #       when its content is hidden and down when its content is
      #       visible." NSButton.BezelStyle.disclosure (5). Used inline in
      #       lists/outlines (e.g. Finder list view, Keynote export).
      #   (2) Disclosure button (push-disclosure): "points down when its
      #       content is hidden and up when its content is visible." Used
      #       in dialogs to reveal advanced options (e.g. Save sheet).
      # UI::DisclosureGroup maps to NSButton bezelStyle=disclosure (5) on
      # macOS with state=1 (expanded, pointing down) or state=0 (collapsed).
      # HIG: "Use a disclosure control to hide details until they're
      # relevant. Place controls that people are most likely to use at the
      # top of the disclosure hierarchy so they're always visible."
      content = UI::VStack.new(spacing: 12.0)

      # --- Shape 1: Disclosure triangles (list/outline context) ---
      section_label = UI::Label.new("Disclosure Triangles")
      content << section_label.as(UI::View)

      # Expanded group: General -- triangle pointing down (state=1)
      expanded_group = UI::DisclosureGroup.new("General", expanded: true)
      expanded_group.content << UI::Label.new("Appearance: Auto")
      expanded_group.content << UI::Label.new("Language & Region: English (US)")
      expanded_group.content << UI::Label.new("Date & Time: Automatic")
      content << expanded_group.as(UI::View)

      # Collapsed group: Privacy & Security -- triangle pointing inward (state=0)
      collapsed_group = UI::DisclosureGroup.new("Privacy & Security", expanded: false)
      collapsed_group.content << UI::Label.new("Location Services: On")
      content << collapsed_group.as(UI::View)

      # Collapsed group: Notifications
      notif_group = UI::DisclosureGroup.new("Notifications", expanded: false)
      notif_group.content << UI::Label.new("Allow Notifications: On")
      content << notif_group.as(UI::View)

      content << UI::Divider.new(:horizontal)

      # --- Shape 2: Disclosure button (dialog "Show More" context) ---
      # HIG: "A disclosure button shows and hides functionality associated
      # with a specific control. For example, the macOS Save sheet shows a
      # disclosure button next to the Save As text field."
      shape2_label = UI::Label.new("Disclosure Button (Show More / Show Less)")
      content << shape2_label.as(UI::View)

      # Hidden state: "Show More" (points down = content hidden per HIG)
      hidden_options = UI::DisclosureGroup.new("Show More", expanded: false)
      hidden_options.content << UI::Label.new("Output location: /Users/user/Documents")
      content << hidden_options.as(UI::View)

      # Revealed state: options visible (points up = content visible per HIG)
      revealed_options = UI::DisclosureGroup.new("Show Less", expanded: true)
      revealed_options.content << UI::Label.new("Output location: /Users/user/Documents")
      revealed_options.content << UI::Label.new("Format: PDF")
      revealed_options.content << UI::Label.new("Color profile: sRGB")
      content << revealed_options.as(UI::View)

      content.as(UI::View)
    when "dock-menus"
      # HIG dock menu content surface: the secondary-click menu that extends
      # from a Dock tile on macOS. HIG abstract: "On a Mac, people can
      # secondary click an app's or game's icon in the Dock to reveal a Dock
      # menu, which presents both system-provided and custom items." Platform
      # considerations: "Not supported in iOS, iPadOS, tvOS, visionOS, or
      # watchOS." -- macOS-only; iOS host renders an N/A placeholder. We
      # render the item list inline as a VStack (same convention as
      # action-sheets / context-menus) so the screenshot captures the menu
      # surface itself. Canonical structure per HIG "Best practices":
      #   "Prefer high-value custom items for your Dock menu. For example,
      #    a Dock menu can list all currently or recently open windows,
      #    making it a convenient way to jump to the window people want."
      # Shape: app-specific items at top, separator, recent documents,
      # separator, system items (Options subhead / Show in Finder / Hide /
      # Quit). Surface: NSVisualEffectMaterial.menu (10) via UI::Sheet
      # grouped_card, which calls setMaterial:10 in appkit_renderer.cr.
      content = UI::VStack.new(spacing: 6.0)

      # --- Group 1: App-specific custom items ---
      content << UI::Button.new("New Window", symbol: "plus.rectangle")
      content << UI::Button.new("Open Recent \u25B8", symbol: "clock.arrow.circlepath")

      content << UI::Divider.new(:horizontal)

      # --- Group 2: Recent documents (high-value per HIG best practices) ---
      recent_header = UI::Label.new("Recent")
      recent_header.font = UI::Font.new(size: 11.0, weight: :semibold)
      recent_header.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      content << recent_header.as(UI::View)
      content << UI::Button.new("report-q1.pdf", symbol: "doc.fill")
      content << UI::Button.new("notes.md", symbol: "doc.text")
      content << UI::Button.new("drafts.md", symbol: "doc.text")

      content << UI::Divider.new(:horizontal)

      # --- Group 3: System items ---
      options_header = UI::Label.new("Options")
      options_header.font = UI::Font.new(size: 11.0, weight: :semibold)
      options_header.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      content << options_header.as(UI::View)
      content << UI::Button.new("Keep in Dock", symbol: "pin")
      content << UI::Button.new("Open at Login", symbol: "power")
      content << UI::Button.new("Show in Finder", symbol: "folder")
      content << UI::Button.new("Hide", symbol: "eye.slash")
      content << UI::Button.new("Quit", symbol: "xmark.circle")

      UI::Sheet.new(content.as(UI::View), surface_style: :grouped_card).as(UI::View)
    when "edit-menus"
      # HIG edit menu content surface: a compact macOS Edit menu presented as
      # a deliberate showcase plate. The title stays short, the menu groups stay
      # tight, and the sheet remains centered with generous amber gutters.
      outer = UI::VStack.new(spacing: 12.0)
      outer.alignment = UI::Alignment::Center

      edit_title = UI::Label.new("Edit")
      edit_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      edit_title.accessibility_label = "Edit menu study title"
      outer << edit_title.as(UI::View)

      edit_subtitle = UI::Label.new("Clipboard, selection, find.")
      edit_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      edit_subtitle.text_color_role = UI::LabelRole::Secondary
      edit_subtitle.accessibility_label = "Edit menu study subtitle"
      outer << edit_subtitle.as(UI::View)

      content = UI::VStack.new(spacing: 6.0)

      # --- Group 1: Clipboard ---
      cut_row = UI::HStack.new(spacing: 8.0)
      cut_row << UI::Button.new("Cut", symbol: "scissors")
      cut_row << UI::Spacer.new
      cut_key = UI::Label.new("\u2318X")
      cut_key.font = UI::Font.new(size: 13.0, weight: :regular)
      cut_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      cut_row << cut_key.as(UI::View)
      content << cut_row.as(UI::View)

      copy_row = UI::HStack.new(spacing: 8.0)
      copy_row << UI::Button.new("Copy", symbol: "doc.on.doc")
      copy_row << UI::Spacer.new
      copy_key = UI::Label.new("\u2318C")
      copy_key.font = UI::Font.new(size: 13.0, weight: :regular)
      copy_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      copy_row << copy_key.as(UI::View)
      content << copy_row.as(UI::View)

      paste_row = UI::HStack.new(spacing: 8.0)
      paste_row << UI::Button.new("Paste", symbol: "doc.on.clipboard")
      paste_row << UI::Spacer.new
      paste_key = UI::Label.new("\u2318V")
      paste_key.font = UI::Font.new(size: 13.0, weight: :regular)
      paste_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      paste_row << paste_key.as(UI::View)
      content << paste_row.as(UI::View)

      content << UI::Divider.new(:horizontal)

      # --- Group 2: Selection ---
      sall_row = UI::HStack.new(spacing: 8.0)
      sall_row << UI::Button.new("Select All", symbol: "selection.pin.in.out")
      sall_row << UI::Spacer.new
      sall_key = UI::Label.new("\u2318A")
      sall_key.font = UI::Font.new(size: 13.0, weight: :regular)
      sall_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      sall_row << sall_key.as(UI::View)
      content << sall_row.as(UI::View)

      content << UI::Divider.new(:horizontal)

      # --- Group 3: Find / utilities ---
      find_row = UI::HStack.new(spacing: 8.0)
      find_row << UI::Button.new("Find\u2026", symbol: "magnifyingglass")
      find_row << UI::Spacer.new
      find_key = UI::Label.new("\u2318F")
      find_key.font = UI::Font.new(size: 13.0, weight: :regular)
      find_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      find_row << find_key.as(UI::View)
      content << find_row.as(UI::View)

      content << UI::Button.new("Look Up", symbol: "book")
      content << UI::Button.new("Translate", symbol: "character.bubble")

      menu_sheet = UI::Sheet.new(content.as(UI::View), surface_style: :grouped_card)
      menu_sheet.accessibility_label = "Edit menu study"
      outer << menu_sheet.as(UI::View)
      outer.as(UI::View)
    when "menus"
      # HIG menus content surface: the general menu surface shape covering
      # menu-bar pull-down menus (macOS File / Edit / View / ...) and
      # pull-down / pop-up menus on both platforms. HIG abstract: "A menu
      # reveals its options when people interact with it, making it a
      # space-efficient way to present commands in your app or game."
      # This slug is the generic Menus page (distinct from context-menus /
      # edit-menus / dock-menus which cover specific use cases).
      #
      # We render TWO inline menu surfaces stacked in a VStack. Routing this
      # slug through the ambient scene keeps the study centered and lets the
      # menu surfaces read as deliberate product samples instead of a raw demo
      # page.
      #
      # Surface A: "File" pull-down menu (macOS menu-bar style).
      #   Canonical macOS File menu item set (NSMenu "File" convention):
      #     Group 1 (new / open): New (doc / Cmd-N) / Open... (folder.open / Cmd-O)
      #                           / Close (xmark / Cmd-W)
      #     Separator
      #     Group 2 (save): Save (arrow.down.doc / Cmd-S) / Revert (arrow.counterclockwise)
      #     Separator
      #     Group 3 (print): Print... (printer / Cmd-P)
      #     Additionally: "Export >" row with chevron to signal submenu.
      #   Keyboard shortcuts shown as right-aligned secondary labels (macOS only).
      #   HIG "Submenus": "A menu item indicates the presence of a submenu by
      #   displaying a symbol -- like a chevron -- after its label."
      #
      # Surface B: "Sort By" pop-up menu with checkmark selected state.
      #   Items: Name / Date (checkmarked -- currently selected) / Size
      #   HIG "Toggled items": "Consider using a checkmark to show that an
      #   attribute is currently in effect."
      #
      # No destructive items in File or Sort menus (correct -- data operations
      # require confirmation dialogs, not plain menu items per HIG Alerts).
      outer = UI::VStack.new(spacing: 14.0)
      outer.alignment = UI::Alignment::Center

      menus_title = UI::Label.new("Menus")
      menus_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      menus_title.accessibility_label = "Menus study title"
      outer << menus_title.as(UI::View)

      menus_subtitle = UI::Label.new("Flat menu surfaces with quieter spacing.")
      menus_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      menus_subtitle.text_color_role = UI::LabelRole::Secondary
      menus_subtitle.accessibility_label = "Menus study subtitle"
      outer << menus_subtitle.as(UI::View)

      # --- Surface A: File pull-down ---
      file_content = UI::VStack.new(spacing: 4.0)

      # Section header label
      file_header = UI::Label.new("File")
      file_header.font = UI::Font.new(size: 11.0, weight: :semibold)
      file_header.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      file_content << file_header.as(UI::View)

      # Group 1: New / Open / Close
      new_row = UI::HStack.new(spacing: 8.0)
      new_row << UI::Button.new("New", symbol: "doc")
      new_row << UI::Spacer.new
      new_key = UI::Label.new("\u2318N")
      new_key.font = UI::Font.new(size: 13.0, weight: :regular)
      new_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      new_row << new_key.as(UI::View)
      file_content << new_row.as(UI::View)

      open_row = UI::HStack.new(spacing: 8.0)
      open_row << UI::Button.new("Open\u2026", symbol: "folder.open")
      open_row << UI::Spacer.new
      open_key = UI::Label.new("\u2318O")
      open_key.font = UI::Font.new(size: 13.0, weight: :regular)
      open_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      open_row << open_key.as(UI::View)
      file_content << open_row.as(UI::View)

      close_row = UI::HStack.new(spacing: 8.0)
      close_row << UI::Button.new("Close", symbol: "xmark")
      close_row << UI::Spacer.new
      close_key = UI::Label.new("\u2318W")
      close_key.font = UI::Font.new(size: 13.0, weight: :regular)
      close_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      close_row << close_key.as(UI::View)
      file_content << close_row.as(UI::View)

      file_content << UI::Divider.new(:horizontal)

      # Group 2: Save / Revert
      save_row = UI::HStack.new(spacing: 8.0)
      save_row << UI::Button.new("Save", symbol: "arrow.down.doc")
      save_row << UI::Spacer.new
      save_key = UI::Label.new("\u2318S")
      save_key.font = UI::Font.new(size: 13.0, weight: :regular)
      save_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      save_row << save_key.as(UI::View)
      file_content << save_row.as(UI::View)

      file_content << UI::Button.new("Revert", symbol: "arrow.counterclockwise")

      file_content << UI::Divider.new(:horizontal)

      # Group 3: Export (submenu indicator) / Print
      # HIG "Submenus": chevron after label signals nested items.
      export_row = UI::HStack.new(spacing: 8.0)
      export_row << UI::Button.new("Export", symbol: "square.and.arrow.up")
      export_row << UI::Spacer.new
      chevron = UI::Label.new("\u203a") # single right-pointing angle quotation mark as chevron
      chevron.font = UI::Font.new(size: 15.0, weight: :regular)
      chevron.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      export_row << chevron.as(UI::View)
      file_content << export_row.as(UI::View)

      print_row = UI::HStack.new(spacing: 8.0)
      print_row << UI::Button.new("Print\u2026", symbol: "printer")
      print_row << UI::Spacer.new
      print_key = UI::Label.new("\u2318P")
      print_key.font = UI::Font.new(size: 13.0, weight: :regular)
      print_key.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      print_row << print_key.as(UI::View)
      file_content << print_row.as(UI::View)

      file_surface = UI::Sheet.new(file_content.as(UI::View), surface_style: :grouped_card)
      outer << file_surface.as(UI::View)

      # --- Surface B: Sort By pop-up with checkmark ---
      sort_content = UI::VStack.new(spacing: 4.0)

      sort_header = UI::Label.new("Sort by")
      sort_header.font = UI::Font.new(size: 11.0, weight: :semibold)
      sort_header.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      sort_content << sort_header.as(UI::View)

      # Name (unselected)
      name_row = UI::HStack.new(spacing: 8.0)
      name_spacer = UI::Label.new("  ") # placeholder for alignment where checkmark would be
      name_spacer.font = UI::Font.new(size: 13.0, weight: :regular)
      name_row << name_spacer.as(UI::View)
      name_row << UI::Button.new("Name", symbol: "character")
      sort_content << name_row.as(UI::View)

      # Date (selected -- checkmark shown)
      # HIG "Toggled items": "Consider using a checkmark to show that an
      # attribute is currently in effect."
      date_row = UI::HStack.new(spacing: 8.0)
      checkmark = UI::Label.new("\u2713") # checkmark character
      checkmark.font = UI::Font.new(size: 13.0, weight: :semibold)
      date_row << checkmark.as(UI::View)
      date_row << UI::Button.new("Date", symbol: "calendar")
      sort_content << date_row.as(UI::View)

      # Size (unselected)
      size_row = UI::HStack.new(spacing: 8.0)
      size_spacer = UI::Label.new("  ") # placeholder for alignment
      size_spacer.font = UI::Font.new(size: 13.0, weight: :regular)
      size_row << size_spacer.as(UI::View)
      size_row << UI::Button.new("Size", symbol: "arrow.up.arrow.down")
      sort_content << size_row.as(UI::View)

      sort_surface = UI::Sheet.new(sort_content.as(UI::View), surface_style: :grouped_card)
      outer << sort_surface.as(UI::View)

      outer.as(UI::View)
    when "buttons"
      # HIG button gallery: representative variants covering style, role, and
      # state. HIG abstract: "A button initiates an instantaneous action."
      # HIG Best practices: "a button needs a hit region of at least 44x44 pt."
      # Variants:
      #   Row 1:  Default       — NSBezelStyleRounded, system blue label
      #   Row 2:  Prominent     — filled blue bezel (NSButton bezelColor = controlAccentColor)
      #   Row 3:  Tinted        — NSBezelStyleFlexiblePush, translucent accent fill
      #   Row 4:  Bordered      — same as Default, explicit style knob
      #   Row 5:  Borderless    — no bezel, text-link style (isBordered = false)
      #   Row 6:  Destructive   — system red label per HIG
      #   Row 7:  Cancel        — semibold label per HIG
      #   Row 8:  Prom+Dest     — Prominent style + destructive role (red fill)
      #   Row 9:  Disabled      — setEnabled:NO
      #   Row 10: SF Symbol     — share icon + "Share" label
      #   Row 11: Dest + Symbol — trash icon + destructive role
      # Each row is an HStack: a label describing the variant, then the button.
      # HIG macOS: default button minimum 28pt tall; prominent minimum 32pt tall.
      # HIG Buttons — Best practices: "a button needs a hit region of at least
      # 44x44 pt" on iOS; macOS standard is 28pt minimum for default, 32pt for
      # prominent. Label/button column gap: 8pt (sm token on Apple 8pt grid).
      btn_gallery = UI::VStack.new(spacing: 10.0)

      btn_gallery << UI::Label.new("Button Style / Role Gallery").tap { |l|
        l.font = UI::Font.new(size: 13.0, weight: :semibold)
      }

      # Row 1 -- Default (system bordered, Amber gold label), 28pt min height
      r1 = UI::HStack.new(spacing: 8.0)
      r1 << UI::Label.new("Default")
      btn1 = UI::Button.new("Continue", style: UI::ButtonStyle::Default)
      btn1.minimum_height = 28.0
      r1 << btn1.as(UI::View)
      btn_gallery << r1.as(UI::View)

      # Row 2 -- Prominent (filled Amber gold CTA), 32pt min height
      r2 = UI::HStack.new(spacing: 8.0)
      r2 << UI::Label.new("Prominent")
      btn2 = UI::Button.new("Save", style: UI::ButtonStyle::Prominent)
      btn2.minimum_height = 32.0
      r2 << btn2.as(UI::View)
      btn_gallery << r2.as(UI::View)

      # Row 3 -- Tinted (translucent Amber gold fill, secondary CTA), 28pt
      r3 = UI::HStack.new(spacing: 8.0)
      r3 << UI::Label.new("Tinted")
      btn3 = UI::Button.new("Add to List", style: UI::ButtonStyle::Tinted)
      btn3.minimum_height = 28.0
      r3 << btn3.as(UI::View)
      btn_gallery << r3.as(UI::View)

      # Row 4 -- Bordered (explicit, same as Default), 28pt
      r4 = UI::HStack.new(spacing: 8.0)
      r4 << UI::Label.new("Bordered")
      btn4 = UI::Button.new("Options", style: UI::ButtonStyle::Bordered)
      btn4.minimum_height = 28.0
      r4 << btn4.as(UI::View)
      btn_gallery << r4.as(UI::View)

      # Row 5 -- Borderless (text-link, low prominence), 28pt
      r5 = UI::HStack.new(spacing: 8.0)
      r5 << UI::Label.new("Borderless")
      btn5 = UI::Button.new("Learn more", style: UI::ButtonStyle::Borderless)
      btn5.minimum_height = 28.0
      r5 << btn5.as(UI::View)
      btn_gallery << r5.as(UI::View)

      # Row 6 -- Destructive role (system red label), 28pt
      r6 = UI::HStack.new(spacing: 8.0)
      r6 << UI::Label.new("Destructive")
      btn6 = UI::Button.new("Delete", role: :destructive)
      btn6.minimum_height = 28.0
      r6 << btn6.as(UI::View)
      btn_gallery << r6.as(UI::View)

      # Row 7 -- Cancel role (semibold label per HIG), 28pt
      r7 = UI::HStack.new(spacing: 8.0)
      r7 << UI::Label.new("Cancel")
      btn7 = UI::Button.new("Cancel", role: :cancel)
      btn7.minimum_height = 28.0
      r7 << btn7.as(UI::View)
      btn_gallery << r7.as(UI::View)

      # Row 8 -- Prominent + Destructive (red filled bezel), 32pt
      r8 = UI::HStack.new(spacing: 8.0)
      r8 << UI::Label.new("Prom + Dest")
      btn8 = UI::Button.new("Delete Account", role: :destructive, style: UI::ButtonStyle::Prominent)
      btn8.minimum_height = 32.0
      r8 << btn8.as(UI::View)
      btn_gallery << r8.as(UI::View)

      # Row 9 -- Disabled state, 28pt
      r9 = UI::HStack.new(spacing: 8.0)
      r9 << UI::Label.new("Disabled")
      disabled_btn = UI::Button.new("Unavailable")
      disabled_btn.disabled = true
      disabled_btn.minimum_height = 28.0
      r9 << disabled_btn.as(UI::View)
      btn_gallery << r9.as(UI::View)

      # Row 10 -- With SF Symbol (share icon), 28pt
      r10 = UI::HStack.new(spacing: 8.0)
      r10 << UI::Label.new("SF Symbol")
      btn10 = UI::Button.new("Share", symbol: "square.and.arrow.up")
      btn10.minimum_height = 28.0
      r10 << btn10.as(UI::View)
      btn_gallery << r10.as(UI::View)

      # Row 11 -- Destructive with symbol (trash icon), 28pt
      r11 = UI::HStack.new(spacing: 8.0)
      r11 << UI::Label.new("Dest + Symbol")
      btn11 = UI::Button.new("Remove", role: :destructive, symbol: "trash")
      btn11.minimum_height = 28.0
      r11 << btn11.as(UI::View)
      btn_gallery << r11.as(UI::View)

      btn_gallery.as(UI::View)
    when "toggles"
      # HIG toggles: six HIG-canonical scenarios covering ON, OFF, Disabled-ON,
      # Disabled-OFF states per Best practices.
      # HIG Best practices: "Make sure the visual differences in a toggle's state
      # are obvious." -- on (Amber gold) vs gray (off) vs dimmed (disabled).
      # macOS: NSSwitch (macOS 10.15+) is the preferred control per HIG macOS
      # guidance: "Prefer a switch for settings that you want to emphasize."
      # All ON-state switches use the Amber gold brand accent (consistent accent
      # per group -- HIG: "Change the default color only if necessary, and use the
      # same color for all switches in your app.").
      #
      # Dark appearance note: NSSwitch setContentTintColor: applies the Amber gold
      # to the ON track via the window's effective appearance. The tint call is
      # made through nsswitch_set_tint which guards on respondsToSelector: (macOS 12+).
      # On macOS 26 (Darwin 25.x) this is always available.
      amber_gold_tgl = UI::Color.new(r: 1.0, g: 0.678, b: 0.2)
      tgl_stack = UI::VStack.new(spacing: 16.0)
      tgl_stack.alignment = UI::Alignment::Leading
      tgl_stack.minimum_width = 484.0
      tgl_stack.maximum_width = 484.0

      title_lbl = UI::Label.new("Switch states")
      title_lbl.font = UI::Font.new(size: 15.0, weight: :semibold)
      title_lbl.accessibility_label = "Toggle study title"
      tgl_stack << title_lbl.as(UI::View)

      # Row 1: ON state -- Amber gold track, thumb right
      row1 = UI::HStack.new(spacing: 12.0)
      label1 = UI::Label.new("Notifications")
      label1.accessibility_label = "Notifications label"
      row1 << label1.as(UI::View)
      row1 << UI::Spacer.new.as(UI::View)
      tgl_on = UI::Toggle.new("", true)
      tgl_on.tint_color = amber_gold_tgl
      tgl_on.accessibility_label = "Notifications toggle, on"
      row1 << tgl_on.as(UI::View)
      tgl_stack << row1.as(UI::View)

      # Row 2: OFF state -- system gray track, thumb left
      row2 = UI::HStack.new(spacing: 12.0)
      label2 = UI::Label.new("Dark Mode")
      label2.accessibility_label = "Dark Mode label"
      row2 << label2.as(UI::View)
      row2 << UI::Spacer.new.as(UI::View)
      tgl_off = UI::Toggle.new("", false)
      tgl_off.accessibility_label = "Dark Mode toggle, off"
      row2 << tgl_off.as(UI::View)
      tgl_stack << row2.as(UI::View)

      # Row 3: Disabled (OFF) -- dimmed, non-interactive
      # HIG: "Clearly identify the setting, view, or content the toggle affects."
      row3 = UI::HStack.new(spacing: 12.0)
      label3 = UI::Label.new("Location")
      label3.accessibility_label = "Location label"
      row3 << label3.as(UI::View)
      row3 << UI::Spacer.new.as(UI::View)
      tgl_disabled_off = UI::Toggle.new("", false)
      tgl_disabled_off.disabled = true
      tgl_disabled_off.accessibility_label = "Location toggle, disabled off"
      row3 << tgl_disabled_off.as(UI::View)
      tgl_stack << row3.as(UI::View)

      # Row 4: ON with brand accent -- same Amber gold (consistent accent per group)
      # HIG: "Use the same color for all switches in your app." Focus Mode is on,
      # demonstrating the ON state with the brand accent color.
      row4 = UI::HStack.new(spacing: 12.0)
      label4 = UI::Label.new("Focus Mode")
      label4.accessibility_label = "Focus Mode label"
      row4 << label4.as(UI::View)
      row4 << UI::Spacer.new.as(UI::View)
      tgl_focus = UI::Toggle.new("", true)
      tgl_focus.tint_color = amber_gold_tgl
      tgl_focus.accessibility_label = "Focus Mode toggle, on"
      row4 << tgl_focus.as(UI::View)
      tgl_stack << row4.as(UI::View)

      # Row 5: Disabled ON -- gold track dimmed, non-interactive.
      # Stresses dark rendering: gold fill should be visible even at reduced alpha.
      row5 = UI::HStack.new(spacing: 12.0)
      label5 = UI::Label.new("Night Shift")
      label5.accessibility_label = "Night Shift label"
      row5 << label5.as(UI::View)
      row5 << UI::Spacer.new.as(UI::View)
      tgl_disabled_on = UI::Toggle.new("", true)
      tgl_disabled_on.tint_color = amber_gold_tgl
      tgl_disabled_on.disabled = true
      tgl_disabled_on.accessibility_label = "Night Shift toggle, disabled on"
      row5 << tgl_disabled_on.as(UI::View)
      tgl_stack << row5.as(UI::View)

      # Row 6: Disabled OFF -- system gray track dimmed.
      row6 = UI::HStack.new(spacing: 12.0)
      label6 = UI::Label.new("Auto Lock")
      label6.accessibility_label = "Auto Lock label"
      row6 << label6.as(UI::View)
      row6 << UI::Spacer.new.as(UI::View)
      tgl_disabled_off2 = UI::Toggle.new("", false)
      tgl_disabled_off2.disabled = true
      tgl_disabled_off2.accessibility_label = "Auto Lock toggle, disabled off"
      row6 << tgl_disabled_off2.as(UI::View)
      tgl_stack << row6.as(UI::View)

      tgl_card = UI::Card.new(tgl_stack.as(UI::View))
      tgl_card.minimum_width = 520.0
      tgl_card.maximum_width = 520.0
      tgl_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      tgl_card.is_outlined = true
      tgl_card.material = :secondary
      tgl_card.accessibility_label = "Switch states study card"
      tgl_card.as(UI::View)
    when "text-fields"
      # HIG text-fields: four labelled variants covering the canonical states.
      # HIG Best practices: "Show a hint in a text field to help communicate its
      # purpose" — every field here has a placeholder or filled value.
      # macOS: NSTextField (rounded bezel) or NSSecureTextField.

      tf_stack = UI::VStack.new(spacing: 14.0)
      tf_stack.alignment = UI::Alignment::Leading
      tf_stack.minimum_width = 360.0
      tf_stack.maximum_width = 360.0
      tf_stack << UI::Label.new("Account details").tap { |l| l.font = UI::Font.new(size: 15.0, weight: :semibold) }

      # Row 1: Name (empty, placeholder visible)
      row1 = UI::VStack.new(spacing: 4.0)
      row1.alignment = UI::Alignment::Leading
      lbl1 = UI::Label.new("Name:")
      lbl1.font = UI::Font.new(size: 13.0, weight: :regular)
      lbl1.accessibility_label = "Name label"
      tf1 = UI::TextField.new("Your name")
      tf1.minimum_width = 280.0
      tf1.maximum_width = 280.0
      tf1.accessibility_label = "Name field"
      row1 << lbl1.as(UI::View)
      row1 << tf1.as(UI::View)
      tf_stack << row1.as(UI::View)

      # Row 2: Email (filled value — primary text visible)
      row2 = UI::VStack.new(spacing: 4.0)
      row2.alignment = UI::Alignment::Leading
      lbl2 = UI::Label.new("Email:")
      lbl2.font = UI::Font.new(size: 13.0, weight: :regular)
      lbl2.accessibility_label = "Email label"
      tf2 = UI::TextField.new("Email address")
      tf2.text = "alice@example.com"
      tf2.minimum_width = 280.0
      tf2.maximum_width = 280.0
      tf2.keyboard_type = UI::KeyboardType::EmailAddress
      tf2.accessibility_label = "Email field"
      row2 << lbl2.as(UI::View)
      row2 << tf2.as(UI::View)
      tf_stack << row2.as(UI::View)

      # Row 3: Password (secure entry — dots)
      row3 = UI::VStack.new(spacing: 4.0)
      row3.alignment = UI::Alignment::Leading
      lbl3 = UI::Label.new("Password:")
      lbl3.font = UI::Font.new(size: 13.0, weight: :regular)
      lbl3.accessibility_label = "Password label"
      tf3 = UI::TextField.new("Password")
      tf3.secure_entry = true
      tf3.text = "secretpassword"
      tf3.minimum_width = 280.0
      tf3.maximum_width = 280.0
      tf3.accessibility_label = "Password field"
      row3 << lbl3.as(UI::View)
      row3 << tf3.as(UI::View)
      tf_stack << row3.as(UI::View)

      # Row 4: Numeric / formatted (number pad keyboard on iOS)
      row4 = UI::VStack.new(spacing: 4.0)
      row4.alignment = UI::Alignment::Leading
      lbl4 = UI::Label.new("Amount:")
      lbl4.font = UI::Font.new(size: 13.0, weight: :regular)
      lbl4.accessibility_label = "Amount label"
      tf4 = UI::TextField.new("0.00")
      tf4.minimum_width = 160.0
      tf4.maximum_width = 160.0
      tf4.keyboard_type = UI::KeyboardType::NumberPad
      tf4.accessibility_label = "Amount field"
      row4 << lbl4.as(UI::View)
      row4 << tf4.as(UI::View)
      tf_stack << row4.as(UI::View)

      tf_card = UI::Card.new(tf_stack.as(UI::View))
      tf_card.minimum_width = 420.0
      tf_card.maximum_width = 420.0
      tf_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      tf_card.is_outlined = true
      tf_card.material = :secondary
      tf_card.accessibility_label = "Text field study card"
      tf_card.as(UI::View)
    when "token-fields"
      # Mail-like token entry study: compact, centered, and calm. The fallback
      # token field already gives us the chip tray and input boundary, so the
      # job here is to stage it with concise copy and restrained content.
      token_field = UI::TokenField.new(
        [
          UI::TokenField::Token.new("Amber", "person.fill"),
          UI::TokenField::Token.new("Design", "pencil.and.outline"),
          UI::TokenField::Token.new("QA", "checkmark.seal.fill"),
        ],
        "Add recipient",
        "Recipients",
        "Mail-style entry for people or groups."
      )
      token_field.selected_indexes = [0]
      token_field.input_min_width = 132.0
      token_field.input_max_width = 180.0
      token_field.viewport_width = 456.0
      token_field.viewport_height = 0.0
      token_field.accessibility_label = "Token field study"
      token_field.as(UI::View)
    when "image-wells"
      # Finder-adjacent image well study: compact, restrained, and centered.
      # The fallback image well already renders the framed drop target, so this
      # case focuses on the label/prompt rhythm and a believable empty state.
      image_well = UI::ImageWell.new(
        nil,
        "Poster image",
        "Drop a photo or screenshot",
        "Single image replacement.",
        "The framed field should stay calm and readable."
      )
      image_well.placeholder_icon = "photo"
      image_well.well_width = 230.0
      image_well.well_height = 168.0
      image_well.preview_padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
      image_well.viewport_width = 452.0
      image_well.viewport_height = 0.0
      image_well.accessibility_label = "Image well study"
      image_well.as(UI::View)
    when "gauges"
      # Instrument-like gauge study: compact, centered, and quietly technical.
      # The fallback gauge already provides the circular stage, so this case
      # keeps the framing restrained and lets the ring read like a real tool.
      gauge = UI::Gauge.new(
        68.0,
        0.0,
        100.0,
        "System load",
        "Current thermal headroom",
        "Amber monitoring dial",
        "A single, readable meter with enough gutter to feel intentional."
      )
      gauge.units = "%"
      gauge.value_precision = 0
      gauge.diameter = 176.0
      gauge.ring_thickness = 12.0
      gauge.track_color = UI::Color.new(r: 0.82, g: 0.78, b: 0.72)
      gauge.progress_color = UI::Color.new(r: 1.0, g: 0.58, b: 0.0)
      gauge.viewport_width = 452.0
      gauge.viewport_height = 0.0
      gauge.accessibility_label = "Gauge study"
      gauge.as(UI::View)
    when "activity-rings"
      # Apple Activity Rings are unsupported on macOS, so this study uses the
      # shared fallback primitive in an honest, centered composition. The goal
      # is to read like a tool panel, not a novelty dashboard.
      rings = UI::ActivityRings.new(0.82, 0.66, 0.58)
      rings.size = 176.0
      rings.thickness = 14.0
      rings.gap = 10.0
      rings.accessibility_label = "Activity rings"

      rings_title = UI::Label.new("Activity rings")
      rings_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      rings_title.accessibility_label = "Activity rings study title"

      rings_subtitle = UI::Label.new("A centered fallback that keeps the focus on the rings.")
      rings_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      rings_subtitle.text_color_role = UI::LabelRole::Secondary
      rings_subtitle.accessibility_label = "Activity rings study subtitle"

      rings_body = UI::VStack.new(spacing: 12.0)
      rings_body.alignment = UI::Alignment::Center
      rings_body << rings_title
      rings_body << rings_subtitle
      rings_body << rings.as(UI::View)

      rings_card = UI::Card.new(rings_body.as(UI::View))
      rings_card.minimum_width = 492.0
      rings_card.maximum_width = 492.0
      rings_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 20.0, bottom: 18.0, leading: 20.0)
      rings_card.is_outlined = true
      rings_card.material = :secondary
      rings_card.accessibility_label = "Activity rings study card"
      rings_card.as(UI::View)
    when "text-views"
      # HIG text-views: multi-line, scrollable text editing area.
      # HIG abstract: "A text view displays multiline, styled text content,
      # which can optionally be editable."
      # HIG Best practices: "Use a text view when you need to display text
      # that's long, editable, or in a special format."
      # macOS: NSTextView inside NSScrollView.
      # Three representative instances:
      #   1. Read-only paragraph -- demonstrates line wrapping.
      #   2. Editable (empty placeholder via label) -- demonstrates bordered editable area.
      #   3. Attributed-style multi-span -- demonstrates bold + italic co-present.

      tv_outer = UI::VStack.new(spacing: 12.0)
      tv_outer.alignment = UI::Alignment::Leading
      tv_outer.minimum_width = 488.0
      tv_outer.maximum_width = 488.0

      tv_title = UI::Label.new("Text view")
      tv_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      tv_title.accessibility_label = "Text views study title"
      tv_outer << tv_title

      tv_subtitle = UI::Label.new("A polished editing surface with calm gutters.")
      tv_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      tv_subtitle.text_color_role = UI::LabelRole::Secondary
      tv_subtitle.accessibility_label = "Text views study subtitle"
      tv_outer << tv_subtitle

      tv_stack = UI::VStack.new(spacing: 14.0)

      # Row 1: Read-only paragraph (3-4 lines at typical window width)
      row1_lbl = UI::Label.new("Read only")
      row1_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
      row1_lbl.accessibility_label = "Read-only paragraph label"
      tv_stack << row1_lbl.as(UI::View)

      tv1 = UI::TextArea.new
      tv1.text = "Morning pages begin with a few quiet lines. The surface should feel ready, legible, and unhurried."
      tv1.is_editable = false
      tv1.is_scrollable = false
      tv1.minimum_width = 488.0
      tv1.maximum_width = 488.0
      tv1.minimum_height = 92.0
      tv1.maximum_height = 92.0
      tv1.accessibility_label = "Read-only text view"
      tv_stack << tv1.as(UI::View)

      # Row 2: Label indicating editable text area (UI::TextArea for editable; RichText for validation)
      row2_lbl = UI::Label.new("Attributed text")
      row2_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
      row2_lbl.accessibility_label = "Attributed text label"
      tv_stack << row2_lbl.as(UI::View)

      tv2 = UI::TextArea.new
      tv2.text = "Primary text holds the room while secondary emphasis stays restrained."
      tv2.is_editable = true
      tv2.is_scrollable = false
      tv2.minimum_width = 488.0
      tv2.maximum_width = 488.0
      tv2.minimum_height = 88.0
      tv2.maximum_height = 88.0
      tv2.accessibility_label = "Attributed text view"
      tv_stack << tv2.as(UI::View)

      tv_outer << tv_stack.as(UI::View)

      tv_card = UI::Card.new(tv_outer.as(UI::View))
      tv_card.minimum_width = 540.0
      tv_card.maximum_width = 540.0
      tv_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      tv_card.is_outlined = true
      tv_card.material = :secondary
      tv_card.accessibility_label = "Text view study card"
      tv_card.as(UI::View)
    when "labels"
      # HIG Labels: 8-row typographic gallery exercising all four LabelRole
      # semantic color tokens (iteration-18 contract) plus the full HIG
      # text-size ladder approximated via UI::Label#font size+weight.
      #
      # HIG abstract: "A label is a static piece of text that people can read
      # and often copy, but not edit."
      # HIG Best practices:
      #   "Prefer system fonts."
      #   "Use system-provided label colors to communicate relative importance."
      #
      # LabelRole tokens resolve to NSColor.labelColor / secondaryLabelColor /
      # tertiaryLabelColor / quaternaryLabelColor at render time, tracking
      # appearance (light/dark) and Increase Contrast automatically.
      # `UI::Label` has no symbolic :style knob for HIG text styles (no Dynamic
      # Type mapping -- see gaps.md). Sizes approximate the HIG ladder:
      # Large Title=34, Headline=17 semibold, Body=17, Callout=16,
      # Subheadline=15 semibold, Footnote=13, Caption=12.
      content = UI::VStack.new(spacing: 9.0)
      content.alignment = UI::Alignment::Leading

      title = UI::Label.new("Label styles")
      title.font = UI::Font.new(size: 17.0, weight: :semibold)
      title.accessibility_label = "Labels study title"
      content << title

      subtitle = UI::Label.new("Typography and semantic color in one quiet set.")
      subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      subtitle.text_color_role = UI::LabelRole::Secondary
      subtitle.accessibility_label = "Labels study subtitle"
      content << subtitle

      # Row 1: Large Title -- Primary, 34pt Bold
      row1_label = UI::Label.new("Row 1 (Large Title)")
      row1_label.font = UI::Font.new(size: 12.0, weight: :regular)
      row1_label.text_color_role = UI::LabelRole::Secondary
      content << row1_label
      large_title = UI::Label.new("The quick brown fox")
      large_title.font = UI::Font.new(size: 34.0, weight: :bold)
      large_title.text_color_role = UI::LabelRole::Primary
      content << large_title

      # Row 2: Headline -- Primary, 17pt Semibold
      row2_label = UI::Label.new("Row 2 (Headline)")
      row2_label.font = UI::Font.new(size: 12.0, weight: :regular)
      row2_label.text_color_role = UI::LabelRole::Secondary
      content << row2_label
      headline = UI::Label.new("The quick brown fox")
      headline.font = UI::Font.new(size: 17.0, weight: :semibold)
      headline.text_color_role = UI::LabelRole::Primary
      content << headline

      # Row 3: Body -- Primary, 17pt Regular
      row3_label = UI::Label.new("Row 3 (Body)")
      row3_label.font = UI::Font.new(size: 12.0, weight: :regular)
      row3_label.text_color_role = UI::LabelRole::Secondary
      content << row3_label
      body = UI::Label.new("The quick brown fox")
      body.font = UI::Font.new(size: 17.0, weight: :regular)
      body.text_color_role = UI::LabelRole::Primary
      content << body

      # Row 4: Callout -- Primary, 16pt Regular
      row4_label = UI::Label.new("Row 4 (Callout)")
      row4_label.font = UI::Font.new(size: 12.0, weight: :regular)
      row4_label.text_color_role = UI::LabelRole::Secondary
      content << row4_label
      callout = UI::Label.new("The quick brown fox")
      callout.font = UI::Font.new(size: 16.0, weight: :regular)
      callout.text_color_role = UI::LabelRole::Primary
      content << callout

      # Row 5: Subheadline -- Secondary, 15pt Semibold
      row5_label = UI::Label.new("Row 5 (Subheadline, Secondary color)")
      row5_label.font = UI::Font.new(size: 12.0, weight: :regular)
      row5_label.text_color_role = UI::LabelRole::Secondary
      content << row5_label
      subhead = UI::Label.new("The quick brown fox")
      subhead.font = UI::Font.new(size: 15.0, weight: :semibold)
      subhead.text_color_role = UI::LabelRole::Secondary
      content << subhead

      # Row 6: Footnote -- Tertiary, 13pt Regular
      row6_label = UI::Label.new("Row 6 (Footnote, Tertiary color)")
      row6_label.font = UI::Font.new(size: 12.0, weight: :regular)
      row6_label.text_color_role = UI::LabelRole::Secondary
      content << row6_label
      footnote = UI::Label.new("The quick brown fox")
      footnote.font = UI::Font.new(size: 13.0, weight: :regular)
      footnote.text_color_role = UI::LabelRole::Tertiary
      content << footnote

      # Row 7: Caption -- Quaternary, 12pt Regular
      row7_label = UI::Label.new("Row 7 (Caption, Quaternary color)")
      row7_label.font = UI::Font.new(size: 12.0, weight: :regular)
      row7_label.text_color_role = UI::LabelRole::Secondary
      content << row7_label
      caption = UI::Label.new("THE QUICK BROWN FOX")
      caption.font = UI::Font.new(size: 12.0, weight: :regular)
      caption.text_color_role = UI::LabelRole::Quaternary
      content << caption

      # Row 8: Multi-line wrapping Body -- Primary, 17pt Regular, 4 lines
      row8_label = UI::Label.new("Row 8 (Multi-line Body, Primary color)")
      row8_label.font = UI::Font.new(size: 12.0, weight: :regular)
      row8_label.text_color_role = UI::LabelRole::Secondary
      content << row8_label
      multiline = UI::Label.new("The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump!")
      multiline.font = UI::Font.new(size: 17.0, weight: :regular)
      multiline.text_color_role = UI::LabelRole::Primary
      multiline.number_of_lines = 0
      content << multiline

      label_card = UI::Card.new(content.as(UI::View))
      label_card.minimum_width = 460.0
      label_card.maximum_width = 460.0
      label_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      label_card.is_outlined = true
      label_card.material = :secondary
      label_card.accessibility_label = "Labels study card"
      label_card.as(UI::View)
    when "sliders"
      # HIG Sliders: horizontal track with thumb; leading portion filled in tint color.
      # Best practices: "Customize a slider's appearance if it adds value."
      # Best practices: "Use familiar slider directions" — min on leading, max on trailing.
      # Showcase: four variants exercising the canonical HIG patterns:
      #   1. Plain slider at ~40% value (default tint, NSSlider linear style)
      #   2. Slider with leading "0" and trailing "100" text labels + current-value label
      #   3. Volume-style with speaker.slash / speaker.wave.3 SF Symbol icons as labels
      #   4. Tinted variant using system orange accent to show brand-override knob

      sliders_stack = UI::VStack.new(spacing: 18.0)
      sliders_stack.alignment = UI::Alignment::Leading
      sliders_stack.minimum_width = 484.0
      sliders_stack.maximum_width = 484.0

      # --- Section title ---
      title_lbl = UI::Label.new("Amber sound mix")
      title_lbl.font = UI::Font.new(size: 15.0, weight: :semibold)
      title_lbl.text_color_role = UI::LabelRole::Primary
      title_lbl.accessibility_label = "Sliders showcase title"
      sliders_stack << title_lbl

      # --- Variant 1: Plain slider at 40% ---
      v1_caption = UI::Label.new("Ambient volume")
      v1_caption.font = UI::Font.new(size: 11.0, weight: :regular)
      v1_caption.text_color_role = UI::LabelRole::Secondary
      v1_caption.accessibility_label = "Plain slider caption"
      sliders_stack << v1_caption

      plain_slider = UI::Slider.new(0.0, 100.0, 40.0)
      plain_slider.minimum_width = 360.0
      plain_slider.maximum_width = 360.0
      plain_slider.accessibility_label = "Plain slider at 40 percent"
      sliders_stack << plain_slider

      # --- Variant 2: Slider with text min/max labels and current-value display ---
      v2_caption = UI::Label.new("Slider with min / max text labels")
      v2_caption.font = UI::Font.new(size: 11.0, weight: :regular)
      v2_caption.text_color_role = UI::LabelRole::Secondary
      v2_caption.accessibility_label = "Labeled slider caption"
      sliders_stack << v2_caption

      labeled_row = UI::HStack.new(spacing: 8.0)
      min_lbl = UI::Label.new("0")
      min_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
      min_lbl.text_color_role = UI::LabelRole::Secondary
      labeled_row << min_lbl

      labeled_slider = UI::Slider.new(0.0, 100.0, 65.0)
      labeled_slider.minimum_width = 360.0
      labeled_slider.maximum_width = 360.0
      labeled_slider.accessibility_label = "Brightness slider at 65 percent"
      labeled_row << labeled_slider

      max_lbl = UI::Label.new("100")
      max_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
      max_lbl.text_color_role = UI::LabelRole::Secondary
      labeled_row << max_lbl
      sliders_stack << labeled_row

      val_lbl = UI::Label.new("Current value: 65")
      val_lbl.font = UI::Font.new(size: 11.0, weight: :regular)
      val_lbl.text_color_role = UI::LabelRole::Tertiary
      val_lbl.accessibility_label = "Current slider value label"
      sliders_stack << val_lbl

      # --- Variant 3: Volume-style slider with SF Symbol icons ---
      v3_caption = UI::Label.new("Playback volume")
      v3_caption.font = UI::Font.new(size: 11.0, weight: :regular)
      v3_caption.text_color_role = UI::LabelRole::Secondary
      v3_caption.accessibility_label = "Volume slider caption"
      sliders_stack << v3_caption

      vol_row = UI::HStack.new(spacing: 8.0)
      vol_min_icon = UI::Image.new("speaker.slash")
      vol_min_icon.accessibility_label = "Speaker off"
      vol_row << vol_min_icon

      vol_slider = UI::Slider.new(0.0, 1.0, 0.55)
      vol_slider.minimum_width = 360.0
      vol_slider.maximum_width = 360.0
      vol_slider.accessibility_label = "Volume slider at 55 percent"
      vol_row << vol_slider

      vol_max_icon = UI::Image.new("speaker.wave.3")
      vol_max_icon.accessibility_label = "Speaker full volume"
      vol_row << vol_max_icon
      sliders_stack << vol_row

      # --- Variant 4: Tinted slider (brand orange accent) ---
      v4_caption = UI::Label.new("Ritual intensity")
      v4_caption.font = UI::Font.new(size: 11.0, weight: :regular)
      v4_caption.text_color_role = UI::LabelRole::Secondary
      v4_caption.accessibility_label = "Tinted slider caption"
      sliders_stack << v4_caption

      tinted_slider = UI::Slider.new(0.0, 100.0, 75.0)
      tinted_slider.minimum_width = 360.0
      tinted_slider.maximum_width = 360.0
      tinted_slider.tint_color = UI::Color.new(r: 1.0, g: 0.584, b: 0.0)
      tinted_slider.accessibility_label = "Tinted slider at 75 percent"
      sliders_stack << tinted_slider

      sliders_card = UI::Card.new(sliders_stack.as(UI::View))
      sliders_card.minimum_width = 520.0
      sliders_card.maximum_width = 520.0
      sliders_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      sliders_card.is_outlined = true
      sliders_card.material = :secondary
      sliders_card.accessibility_label = "Sliders study card"
      sliders_card.as(UI::View)
    when "steppers"
      # HIG: "A stepper is a two-segment control that people use to increase or decrease an
      # incremental value." NSStepper renders as a pill-shaped +/- control. The stepper
      # itself does NOT display its value -- always pair it with a Label.
      # HIG: "Make the value that a stepper affects obvious."
      # Showcase: three stepper rows demonstrating normal, at-minimum, and at-maximum states.
      # NSStepper automatically dims the minus segment when value == minimum,
      # and dims the plus segment when value == maximum -- this is native platform behaviour.

      steppers_title = UI::Label.new("Steppers")
      steppers_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      steppers_title.accessibility_label = "Steppers study title"
      steppers_subtitle = UI::Label.new("Small increments should read at a glance.")
      steppers_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      steppers_subtitle.text_color_role = UI::LabelRole::Secondary
      steppers_subtitle.accessibility_label = "Steppers study subtitle"

      # Row 1: normal state, value 3, range 0-10
      row1_label = UI::Label.new("Quantity: 3")
      row1_label.font = UI::Font.new(size: 13.0, weight: :regular)
      row1_label.text_color_role = UI::LabelRole::Secondary
      row1_label.minimum_width = 148.0
      row1_label.accessibility_label = "Quantity label, value 3"

      row1_stepper = UI::Stepper.new(0.0, 10.0, 3.0)
      row1_stepper.step_value = 1.0
      row1_stepper.accessibility_label = "Quantity stepper, value 3, minimum 0, maximum 10"

      row1 = UI::HStack.new(spacing: 8.0)
      row1.alignment = UI::Alignment::Center
      row1 << row1_label
      row1 << row1_stepper

      # Row 2: at minimum -- minus segment auto-dimmed by NSStepper
      row2_label = UI::Label.new("At minimum: 0")
      row2_label.font = UI::Font.new(size: 13.0, weight: :regular)
      row2_label.text_color_role = UI::LabelRole::Secondary
      row2_label.minimum_width = 148.0
      row2_label.accessibility_label = "At minimum label, value 0"

      row2_stepper = UI::Stepper.new(0.0, 10.0, 0.0)
      row2_stepper.step_value = 1.0
      row2_stepper.accessibility_label = "Stepper at minimum, value 0, minus disabled"

      row2 = UI::HStack.new(spacing: 8.0)
      row2.alignment = UI::Alignment::Center
      row2 << row2_label
      row2 << row2_stepper

      # Row 3: at maximum -- plus segment auto-dimmed by NSStepper
      row3_label = UI::Label.new("At maximum: 10")
      row3_label.font = UI::Font.new(size: 13.0, weight: :regular)
      row3_label.text_color_role = UI::LabelRole::Secondary
      row3_label.minimum_width = 148.0
      row3_label.accessibility_label = "At maximum label, value 10"

      row3_stepper = UI::Stepper.new(0.0, 10.0, 10.0)
      row3_stepper.step_value = 1.0
      row3_stepper.accessibility_label = "Stepper at maximum, value 10, plus disabled"

      row3 = UI::HStack.new(spacing: 8.0)
      row3.alignment = UI::Alignment::Center
      row3 << row3_label
      row3 << row3_stepper

      steppers_stack = UI::VStack.new(spacing: 12.0)
      steppers_stack.alignment = UI::Alignment::Center
      steppers_stack << steppers_title
      steppers_stack << steppers_subtitle
      steppers_stack << row1
      steppers_stack << row2
      steppers_stack << row3

      steppers_card = UI::Card.new(steppers_stack.as(UI::View))
      steppers_card.minimum_width = 396.0
      steppers_card.maximum_width = 396.0
      steppers_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 20.0, bottom: 18.0, leading: 20.0)
      steppers_card.is_outlined = true
      steppers_card.material = :secondary
      steppers_card.accessibility_label = "Steppers study card"
      steppers_card.as(UI::View)
    when "segmented-controls"
      # HIG: "A segmented control is a linear set of two or more segments, each of
      # which functions as a button." NSSegmentedControl renders as a pill-shaped
      # grouped control; the selected segment has a filled backing in both light
      # and dark appearances.
      # Showcase: text-only (Day/Week/Month, Week selected at index 1) plus an
      # icon-label variant using SF Symbol names as text labels (4 segments, index 1 selected).
      # HIG: "Limit the number of segments in a control." -- 3 and 4 segments.
      # HIG: "Use nouns or noun phrases for segment labels."
      # HIG: "Prefer using either text or images -- not a mix -- in a single control."

      # Range: 3 segments, index 1 (Week) selected — HIG "Limit the number of
      # segments" + "Use nouns for segment labels".
      sc_title = UI::Label.new("Segmented controls")
      sc_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      sc_title.accessibility_label = "Segmented controls study title"

      sc_subtitle = UI::Label.new("Balanced defaults for view switching.")
      sc_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      sc_subtitle.text_color_role = UI::LabelRole::Secondary
      sc_subtitle.accessibility_label = "Segmented controls study subtitle"

      sc_text = UI::SegmentedControl.new(["Day", "Week", "Month"], 1)
      sc_text.accessibility_label = "Day Week Month segmented control"

      # Density: 4 segments with short noun labels. The underlying
      # UI::SegmentedControl only accepts text labels; SF Symbol-only segment
      # variants are exposed via a different control in future work.
      sc_icon = UI::SegmentedControl.new(["List", "Grid", "Dense", "Stack"], 1)
      sc_icon.accessibility_label = "Density segmented control"

      sc_outer = UI::VStack.new(spacing: 14.0)
      sc_outer.alignment = UI::Alignment::Center
      sc_outer << sc_title
      sc_outer << sc_subtitle
      sc_outer << sc_text
      sc_outer << sc_icon

      sc_card = UI::Card.new(sc_outer.as(UI::View))
      sc_card.minimum_width = 468.0
      sc_card.maximum_width = 468.0
      sc_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 20.0, bottom: 18.0, leading: 20.0)
      sc_card.is_outlined = true
      sc_card.material = :secondary
      sc_card.accessibility_label = "Segmented controls study card"
      sc_card.as(UI::View)
    when "column-views"
      # Finder-like column browser rendered through the shared UI::ColumnView
      # fallback. The composition stays compact so the selected path and column
      # rhythm read clearly against the amber backdrop.
      projects = UI::ColumnView::Item.new("Projects", "folder.fill", "12")
      amber_branch = UI::ColumnView::Item.new("Amber", "folder.fill", "Brand")
      amber_branch.add_child(UI::ColumnView::Item.new("Brand", "doc.text.fill", "Notes"))
      amber_branch.add_child(UI::ColumnView::Item.new("Scenes", "square.grid.2x2.fill", "Layouts"))
      amber_branch.add_child(UI::ColumnView::Item.new("Validation", "checkmark.seal.fill", "Captures"))
      projects.add_child(amber_branch)

      libraries = UI::ColumnView::Item.new("Library", "books.vertical.fill", "6")
      libraries.add_child(UI::ColumnView::Item.new("Writing", "doc.text.fill", "Pages"))
      libraries.add_child(UI::ColumnView::Item.new("Sketches", "scribble.variable", "UI"))
      libraries.add_child(UI::ColumnView::Item.new("Archive", "tray.full.fill", "Older"))

      inbox = UI::ColumnView::Item.new("Inbox", "tray.full.fill", "24")
      inbox.add_child(UI::ColumnView::Item.new("Today", "clock.fill", "4"))
      inbox.add_child(UI::ColumnView::Item.new("This Week", "calendar", "8"))
      inbox.add_child(UI::ColumnView::Item.new("All Notes", "tray.full", "Full"))

      column_view = UI::ColumnView.new([libraries, projects, inbox])
      column_view.selected_indexes = [1, 0, 1]
      column_view.column_widths = [196.0, 200.0, 196.0]
      column_view.default_column_width = 196.0
      column_view.viewport_width = 640.0
      column_view.viewport_height = 320.0
      column_view.shows_disclosure_glyphs = true
      column_view.accessibility_label = "Finder style column browser"

      cv_title = UI::Label.new("Column view")
      cv_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      cv_title.accessibility_label = "Column views study title"

      cv_subtitle = UI::Label.new("A compact Finder-style browser with visible depth.")
      cv_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      cv_subtitle.text_color_role = UI::LabelRole::Secondary
      cv_subtitle.accessibility_label = "Column views study subtitle"

      cv_stack = UI::VStack.new(spacing: 12.0)
      cv_stack.alignment = UI::Alignment::Center
      cv_stack << cv_title
      cv_stack << cv_subtitle
      cv_stack << column_view.as(UI::View)

      cv_card = UI::Card.new(cv_stack.as(UI::View))
      cv_card.minimum_width = 700.0
      cv_card.maximum_width = 700.0
      cv_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      cv_card.is_outlined = true
      cv_card.material = :secondary
      cv_card.accessibility_label = "Column views study card"
      cv_card.as(UI::View)
    when "progress-indicators"
      # HIG: "Progress indicators let people know that your app isn't stalled
      # while it loads content or performs lengthy operations."
      # Gallery covers: spinner (medium), spinner (large, tinted), linear
      # determinate at 60%, linear indeterminate, labeled upload row with cancel.
      # HIG: "When possible, use a determinate progress indicator."
      # HIG: "If it's helpful, display a description that provides additional
      # context for the task."
      # HIG macOS: "Prefer an activity indicator (spinner) to communicate the
      # status of a background operation or when space is constrained."
      gallery = UI::VStack.new(spacing: 14.0)
      gallery.alignment = UI::Alignment::Leading
      gallery.minimum_width = 384.0
      gallery.maximum_width = 384.0

      # --- Section: Spinners ---
      spinner_hdr = UI::Label.new("Spinners")
      spinner_hdr.font = UI::Font.new(size: 13.0, weight: :semibold)
      spinner_hdr.accessibility_label = "Spinners section header"
      gallery << spinner_hdr

      spinner_row = UI::HStack.new(spacing: 20.0)

      # Medium spinner (HIG default — NSProgressIndicator spinning style)
      med_spinner = UI::ActivityIndicator.new(true, :medium)
      med_spinner.accessibility_label = "Loading indicator medium"
      spinner_row << med_spinner

      # Large spinner, tinted with the Amber role color.
      lg_spinner = UI::ActivityIndicator.new(true, :large)
      lg_spinner.color = UI::Color.new(r: 1.0, g: 0.678, b: 0.2, a: 1.0)
      lg_spinner.accessibility_label = "Loading indicator large"
      spinner_row << lg_spinner

      gallery << spinner_row

      # --- Section: Linear determinate at 60% ---
      bar_hdr = UI::Label.new("Linear progress")
      bar_hdr.font = UI::Font.new(size: 13.0, weight: :semibold)
      bar_hdr.accessibility_label = "Linear progress section header"
      gallery << bar_hdr

      det_bar = UI::ProgressView.new(0.6, UI::ProgressStyle::Linear)
      det_bar.label = "Uploading"
      det_bar.minimum_width = 296.0
      det_bar.maximum_width = 296.0
      det_bar.accessibility_label = "Upload progress 60 percent"
      gallery << det_bar

      det_lbl = UI::Label.new("Uploading 60%")
      det_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
      det_lbl.accessibility_label = "Upload progress label"
      gallery << det_lbl

      # --- Section: Linear indeterminate ---
      indet_hdr = UI::Label.new("Linear progress")
      indet_hdr.font = UI::Font.new(size: 13.0, weight: :semibold)
      indet_hdr.accessibility_label = "Indeterminate progress section header"
      gallery << indet_hdr

      indet_bar = UI::ProgressView.new(nil, UI::ProgressStyle::Linear)
      indet_bar.label = "Syncing"
      indet_bar.minimum_width = 296.0
      indet_bar.maximum_width = 296.0
      indet_bar.accessibility_label = "Syncing progress indeterminate"
      gallery << indet_bar

      indet_lbl = UI::Label.new("Syncing...")
      indet_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
      indet_lbl.accessibility_label = "Syncing status label"
      gallery << indet_lbl

      # --- Section: Labeled upload row with cancel (HIG cancel guidance) ---
      upload_hdr = UI::Label.new("Upload with cancel")
      upload_hdr.font = UI::Font.new(size: 13.0, weight: :semibold)
      upload_hdr.accessibility_label = "Upload with cancel section header"
      gallery << upload_hdr

      upload_row = UI::HStack.new(spacing: 10.0)
      upload_row.alignment = UI::Alignment::Center
      upload_lbl = UI::Label.new("Uploading file.zip")
      upload_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
      upload_lbl.accessibility_label = "Upload filename"
      upload_row << upload_lbl
      upload_bar = UI::ProgressView.new(0.6, UI::ProgressStyle::Linear)
      upload_bar.minimum_width = 148.0
      upload_bar.maximum_width = 148.0
      upload_row << upload_bar.as(UI::View)
      cancel_btn = UI::Button.new("Cancel")
      cancel_btn.role = :cancel
      cancel_btn.accessibility_label = "Cancel upload"
      upload_row << cancel_btn
      gallery << upload_row

      progress_card = UI::Card.new(gallery.as(UI::View))
      progress_card.minimum_width = 428.0
      progress_card.maximum_width = 428.0
      progress_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      progress_card.is_outlined = true
      progress_card.material = :secondary
      progress_card.accessibility_label = "Progress indicators study card"
      progress_card.as(UI::View)
    when "activity-indicators" then UI::ActivityIndicator.new(true, :medium)
    when "popovers"
      # HIG: "A popover is a transient view that appears above other content when
      # people click or tap a control or interactive area."
      # HIG Best practices: "Use a popover to expose a small amount of information
      # or functionality." -- Popovers / Best practices.
      #
      # Rendered inline (not via is_presented) so the validation host can screenshot
      # the glass surface in isolation. The popover content models a filter panel:
      # title + two radio-style picker options + "Clear filters" button at bottom.
      # HIG Best practices: "Use a popover to expose a small amount of information
      # or functionality." — Popovers / Best practices.
      # The filter panel is the canonical HIG-recommended popover use case
      # (contextual editing panel anchored to a toolbar button).
      #
      # macOS: NSVisualEffectView (popover material = 6) wrapping an NSStackView.
      # Corner radius ~10pt, BehindWindow blending, StateActive.
      popover_content = UI::VStack.new(spacing: 12.0)

      filter_title = UI::Label.new("Filter")
      filter_title.font = UI::Font.new(size: 13.0, weight: :semibold)
      filter_title.accessibility_label = "Filter panel title"
      popover_content << filter_title

      pop_divider = UI::Divider.new(:horizontal)
      popover_content << pop_divider

      # Sort order — radio-style segmented picker (two mutually exclusive options).
      sort_label = UI::Label.new("Sort by")
      sort_label.font = UI::Font.new(size: 11.0, weight: :semibold)
      sort_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      sort_label.accessibility_label = "Sort by label"
      popover_content << sort_label

      sort_picker = UI::Picker.new(["Newest first", "Oldest first"], 0)
      sort_picker.style = UI::PickerStyle::Segmented
      sort_picker.accessibility_label = "Sort order picker"
      popover_content << sort_picker

      # Vault filter -- radio-style segmented picker.
      vault_label = UI::Label.new("Vault")
      vault_label.font = UI::Font.new(size: 11.0, weight: :semibold)
      vault_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      vault_label.accessibility_label = "Vault filter label"
      popover_content << vault_label

      vault_picker = UI::Picker.new(["Morning Pages", "All vaults"], 1)
      vault_picker.style = UI::PickerStyle::Segmented
      vault_picker.accessibility_label = "Vault filter picker"
      popover_content << vault_picker

      pop_divider2 = UI::Divider.new(:horizontal)
      popover_content << pop_divider2

      clear_btn = UI::Button.new("Clear filters", role: :default)
      clear_btn.accessibility_label = "Clear filters"
      popover_content << clear_btn

      UI::Popover.new(popover_content.as(UI::View), :bottom).as(UI::View)
    when "pickers"
      # HIG: "A picker displays one or more scrollable lists of distinct values
      # that people can choose from." macOS: NSPopUpButton (pop-up style picker)
      # showing current selection + chevron.  A pop-up picker is the idiomatic
      # macOS equivalent; the wheel style is iOS-specific.
      picker_options = ["United States", "Canada", "Mexico", "United Kingdom", "Australia",
                        "Germany", "France", "Japan", "Brazil", "India"]
      pop_up = UI::Picker.new(picker_options, 0)
      pop_up.label = "Country"
      pop_up.accessibility_label = "Country picker"
      pop_up.style = UI::PickerStyle::Menu

      container = UI::VStack.new(spacing: 12.0)
      container.alignment = UI::Alignment::Leading
      container.minimum_width = 420.0
      container.maximum_width = 420.0

      picker_title = UI::Label.new("Select country")
      picker_title.font = UI::Font.new(size: 15.0, weight: :semibold)
      picker_title.accessibility_label = "Country picker title"
      container << picker_title.as(UI::View)
      container << pop_up.as(UI::View)

      picker_card = UI::Card.new(container.as(UI::View))
      picker_card.minimum_width = 456.0
      picker_card.maximum_width = 456.0
      picker_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      picker_card.is_outlined = true
      picker_card.material = :secondary
      picker_card.accessibility_label = "Country picker study card"
      picker_card.as(UI::View)
    when "pop-up-buttons"
      # HIG: "Use a pop-up button to present a flat list of mutually exclusive
      # options or states."  NSPopUpButton on macOS shows the current selection
      # on the button face with a trailing up/down chevron indicator.  Three
      # examples demonstrate the HIG-recommended pattern: a labelled context
      # label + button pair, multiple buttons showing different selections, and
      # a third showing a longer option list.
      container = UI::VStack.new(spacing: 14.0)
      container.alignment = UI::Alignment::Center

      popup_title = UI::Label.new("Pop-up buttons")
      popup_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      popup_title.accessibility_label = "Pop-up buttons study title"
      container << popup_title.as(UI::View)

      popup_subtitle = UI::Label.new("One current choice, shown compactly.")
      popup_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      popup_subtitle.text_color_role = UI::LabelRole::Secondary
      popup_subtitle.accessibility_label = "Pop-up buttons study subtitle"
      container << popup_subtitle.as(UI::View)

      popup_rows = UI::VStack.new(spacing: 12.0)
      popup_rows.alignment = UI::Alignment::Leading

      # Row 1: Alignment pop-up
      row1_label = UI::Label.new("Alignment")
      row1_label.font = UI::Font.new(size: 13.0, weight: :regular)
      row1_label.text_color_role = UI::LabelRole::Secondary
      row1_label.minimum_width = 126.0
      row1_btn = UI::MenuButton.new("Alignment")
      row1_btn.add_item("Left")
      row1_btn.add_item("Center")
      row1_btn.add_item("Right")
      row1_btn.add_item("Justified")
      row1_btn.selected_index = 0
      row1_btn.accessibility_label = "Alignment, pop-up button"
      row1 = UI::HStack.new(spacing: 8.0)
      row1 << row1_label
      row1 << row1_btn
      popup_rows << row1

      # Row 2: Font size pop-up (showing a mid-list selection)
      row2_label = UI::Label.new("Size")
      row2_label.font = UI::Font.new(size: 13.0, weight: :regular)
      row2_label.text_color_role = UI::LabelRole::Secondary
      row2_label.minimum_width = 126.0
      row2_btn = UI::MenuButton.new("Font size")
      row2_btn.add_item("9pt")
      row2_btn.add_item("10pt")
      row2_btn.add_item("11pt")
      row2_btn.add_item("12pt")
      row2_btn.add_item("14pt")
      row2_btn.add_item("18pt")
      row2_btn.add_item("24pt")
      row2_btn.selected_index = 3 # "12pt" selected
      row2_btn.accessibility_label = "Font size, pop-up button"
      row2 = UI::HStack.new(spacing: 8.0)
      row2 << row2_label
      row2 << row2_btn
      popup_rows << row2

      # Row 3: Theme pop-up (showing "Auto" with system follow)
      row3_label = UI::Label.new("Theme")
      row3_label.font = UI::Font.new(size: 13.0, weight: :regular)
      row3_label.text_color_role = UI::LabelRole::Secondary
      row3_label.minimum_width = 126.0
      row3_btn = UI::MenuButton.new("Theme")
      row3_btn.add_item("Auto")
      row3_btn.add_item("Light")
      row3_btn.add_item("Dark")
      row3_btn.selected_index = 0 # "Auto" selected
      row3_btn.accessibility_label = "Theme, pop-up button"
      row3 = UI::HStack.new(spacing: 8.0)
      row3 << row3_label
      row3 << row3_btn
      popup_rows << row3

      container << popup_rows

      popup_card = UI::Card.new(container.as(UI::View))
      popup_card.minimum_width = 436.0
      popup_card.maximum_width = 436.0
      popup_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 20.0, bottom: 18.0, leading: 20.0)
      popup_card.is_outlined = true
      popup_card.material = :secondary
      popup_card.accessibility_label = "Pop-up buttons study card"
      popup_card.as(UI::View)
    when "pull-down-buttons"
      # HIG: "A pull-down button displays a menu of items or actions that
      # directly relate to the button's purpose."  NSPopUpButton with
      # setIsPullDown: YES shows a verb label + single chevron.down; no item
      # is pre-selected and no checkmarks appear in the open menu.
      # Three HIG-recommended patterns:
      #   1. "Add" -- presents a set of 'what to add' choices (Add Folder /
      #      Add Document / Add Template / Import...).
      #   2. Ellipsis "..." -- more-actions pull-down (Duplicate / Rename /
      #      Move / Delete -- destructive).
      #   3. "Export" (prominent style) -- toolbar-style pull-down showing
      #      export format choices (PDF / CSV / HTML / Markdown).
      pd_container = UI::VStack.new(spacing: 14.0)
      pd_container.alignment = UI::Alignment::Center

      pd_title = UI::Label.new("Pull-down buttons")
      pd_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      pd_title.accessibility_label = "Pull-down buttons study title"
      pd_container << pd_title.as(UI::View)

      pd_subtitle = UI::Label.new("Verb-led menus for closely related actions.")
      pd_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      pd_subtitle.text_color_role = UI::LabelRole::Secondary
      pd_subtitle.accessibility_label = "Pull-down buttons study subtitle"
      pd_container << pd_subtitle.as(UI::View)

      pd_rows = UI::VStack.new(spacing: 12.0)
      pd_rows.alignment = UI::Alignment::Leading

      # --- 1. Add pull-down ---
      pd_ctx1 = UI::Label.new("Create")
      pd_ctx1.font = UI::Font.new(size: 13.0, weight: :regular)
      pd_ctx1.text_color_role = UI::LabelRole::Secondary
      pd_ctx1.minimum_width = 126.0
      add_btn = UI::MenuButton.new("Add")
      add_btn.is_pull_down = true
      add_btn.add_item("New Folder")
      add_btn.add_item("New Document")
      add_btn.add_item("New Template")
      add_btn.add_item("Import\u2026")
      add_btn.accessibility_label = "Add, pull-down button"
      pd_row1 = UI::HStack.new(spacing: 8.0)
      pd_row1 << pd_ctx1
      pd_row1 << add_btn
      pd_rows << pd_row1

      # --- 2. Ellipsis more-actions pull-down ---
      pd_ctx2 = UI::Label.new("More actions")
      pd_ctx2.font = UI::Font.new(size: 13.0, weight: :regular)
      pd_ctx2.text_color_role = UI::LabelRole::Secondary
      pd_ctx2.minimum_width = 126.0
      more_btn = UI::MenuButton.new("\u2026")
      more_btn.is_pull_down = true
      more_btn.add_item("Duplicate")
      more_btn.add_item("Rename")
      more_btn.add_item("Move\u2026")
      more_btn.add_item("Delete", is_destructive: true)
      more_btn.accessibility_label = "More actions, pull-down button"
      pd_row2 = UI::HStack.new(spacing: 8.0)
      pd_row2 << pd_ctx2
      pd_row2 << more_btn
      pd_rows << pd_row2

      # --- 3. Export pull-down (prominent toolbar style) ---
      pd_ctx3 = UI::Label.new("Export format")
      pd_ctx3.font = UI::Font.new(size: 13.0, weight: :regular)
      pd_ctx3.text_color_role = UI::LabelRole::Secondary
      pd_ctx3.minimum_width = 126.0
      export_btn = UI::MenuButton.new("Export")
      export_btn.is_pull_down = true
      export_btn.button_style = :prominent
      export_btn.add_item("PDF")
      export_btn.add_item("CSV")
      export_btn.add_item("HTML")
      export_btn.add_item("Markdown")
      export_btn.accessibility_label = "Export, pull-down button"
      pd_row3 = UI::HStack.new(spacing: 8.0)
      pd_row3 << pd_ctx3
      pd_row3 << export_btn
      pd_rows << pd_row3

      pd_container << pd_rows

      pd_card = UI::Card.new(pd_container.as(UI::View))
      pd_card.minimum_width = 436.0
      pd_card.maximum_width = 436.0
      pd_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 20.0, bottom: 18.0, leading: 20.0)
      pd_card.is_outlined = true
      pd_card.material = :secondary
      pd_card.accessibility_label = "Pull-down buttons study card"
      pd_card.as(UI::View)
    when "scroll-views"
      # HIG scroll views: a centered archive plate with a short header and a
      # bounded vertical scroll area. The rows stay plain so the scroll boundary
      # and the amber gutters are the interesting parts of the capture.
      sv_title = UI::Label.new("Archive")
      sv_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      sv_title.accessibility_label = "Scroll view study title"

      sv_subtitle = UI::Label.new("Scrollable rows")
      sv_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      sv_subtitle.text_color_role = UI::LabelRole::Secondary
      sv_subtitle.accessibility_label = "Scroll view study subtitle"

      # Build a VStack of 15 labeled rows as the scrollable content.
      sv_content = UI::VStack.new(spacing: 0.0)
      (1..15).each do |i|
        row_label = UI::Label.new("Entry #{i}")
        row_label.font = UI::Font.new(size: 14.0, weight: :regular)
        row_label.accessibility_label = "Scroll row #{i}"
        sv_content << row_label
        if i < 15
          sv_content << UI::Divider.new
        end
      end

      # Wrap in a ScrollView with vertical scrolling enabled.
      scroll = UI::ScrollView.new(sv_content)
      scroll.scroll_vertical = true
      scroll.scroll_horizontal = false
      scroll.shows_indicators = true
      scroll.frame_height = 192.0
      scroll.minimum_width = 384.0
      scroll.maximum_width = 384.0
      scroll.accessibility_label = "Vertical scroll view with 15 rows"

      scroll_body = UI::VStack.new(spacing: 12.0)
      scroll_body.alignment = UI::Alignment::Leading
      scroll_body << sv_title.as(UI::View)
      scroll_body << sv_subtitle.as(UI::View)
      scroll_body << scroll.as(UI::View)

      scroll_card = UI::Card.new(scroll_body.as(UI::View))
      scroll_card.minimum_width = 432.0
      scroll_card.maximum_width = 432.0
      scroll_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      scroll_card.is_outlined = true
      scroll_card.material = :secondary
      scroll_card.accessibility_label = "Scroll view study card"
      scroll_card.as(UI::View)
    when "toolbars"
      # HIG: "A toolbar provides convenient access to frequently used commands,
      # controls, navigation, and search." On macOS 26 the toolbar background
      # is a Liquid Glass NSVisualEffectView (material: menu/toolbar, tracks
      # appearance). Items are icon-only NSButtons without bezels; dividers
      # are NSBox separators.
      #
      # Showcase: document-app-style top toolbar with five action buttons +
      # two dividers + a search field placeholder. Mirrors the Mail/Finder
      # pattern: sidebar-toggle | back, forward | share | search.
      #
      # HIG Best practices:
      #   "Choose items deliberately to avoid overcrowding."
      #   "Prefer system-provided symbols without borders."
      #   "Group toolbar items logically by function and frequency of use."

      tb = UI::Toolbar.new("Document")
      tb.shows_title = true
      tb.accessibility_label = "Document toolbar"

      # Group 1: Sidebar toggle
      tb.add_item("sidebar-toggle", "Toggle Sidebar", "sidebar.leading")
      tb.add_item("sep1", "---", nil)

      # Group 2: Navigation
      tb.add_item("back", "Back", "chevron.backward")
      tb.add_item("forward", "Forward", "chevron.forward")
      tb.add_item("sep2", "---", nil)

      # Group 3: Share + Search placeholder
      tb.add_item("share", "Share", "square.and.arrow.up")
      tb.add_item("search", "Search", "magnifyingglass")
      tb.add_item("more", "More", "ellipsis.circle")
      tb.minimum_width = 520.0
      tb.maximum_width = 520.0

      tb_heading = UI::Label.new("Document actions")
      tb_heading.font = UI::Font.new(size: 17.0, weight: :semibold)
      tb_heading.accessibility_label = "Document actions heading"

      tb_desc = UI::Label.new("Keep the toolbar compact, with only the commands that earn top-level reach.")
      tb_desc.font = UI::Font.new(size: 13.0)
      tb_desc.accessibility_label = "Document actions description"

      tb_outer = UI::VStack.new(spacing: 12.0)
      tb_outer.minimum_width = 520.0
      tb_outer.maximum_width = 520.0
      tb_outer << tb_heading
      tb_outer << tb_desc
      tb_outer << tb

      tb_card = UI::Card.new(tb_outer.as(UI::View))
      tb_card.minimum_width = 556.0
      tb_card.maximum_width = 556.0
      tb_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      tb_card.is_outlined = true
      tb_card.material = :secondary
      tb_card.accessibility_label = "Toolbar study card"
      tb_card.as(UI::View)
    when "search-fields"
      # HIG: "A search field lets people search a collection of content for
      # specific terms they enter." NSSearchField provides the magnifying-glass
      # leading icon, rounded-rect bezel, and clear button automatically.
      # Showcase: two states side-by-side — empty (placeholder visible) and
      # filled (text + trailing clear button).

      sf_title = UI::Label.new("Find memories")
      sf_title.font = UI::Font.new(size: 15.0, weight: :medium)
      sf_title.accessibility_label = "Find memories title"

      # State 1: empty field — shows leading magnifying-glass + placeholder
      sf_empty_label = UI::Label.new("New query")
      sf_empty_label.font = UI::Font.new(size: 11.0, weight: :regular)
      sf_empty_label.accessibility_label = "Empty search field label"

      sf_empty = UI::SearchField.new("Shows, Movies, and More")
      sf_empty.text = ""
      sf_empty.minimum_width = 420.0
      sf_empty.maximum_width = 420.0
      sf_empty.accessibility_label = "Empty search field"

      # State 2: filled — shows text in primary color + trailing clear button
      sf_filled_label = UI::Label.new("Recent query")
      sf_filled_label.font = UI::Font.new(size: 11.0, weight: :regular)
      sf_filled_label.accessibility_label = "Filled search field label"

      sf_filled = UI::SearchField.new("Shows, Movies, and More")
      sf_filled.text = "Apple HIG"
      sf_filled.minimum_width = 420.0
      sf_filled.maximum_width = 420.0
      sf_filled.accessibility_label = "Filled search field with Apple HIG query"

      sf_outer = UI::VStack.new(spacing: 10.0)
      sf_outer.minimum_width = 420.0
      sf_outer.maximum_width = 420.0
      sf_outer << sf_title
      sf_outer << sf_empty_label
      sf_outer << sf_empty
      sf_outer << sf_filled_label
      sf_outer << sf_filled
      sf_card = UI::Card.new(sf_outer.as(UI::View))
      sf_card.minimum_width = 456.0
      sf_card.maximum_width = 456.0
      sf_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      sf_card.is_outlined = true
      sf_card.material = :secondary
      sf_card.accessibility_label = "Search field study card"
      sf_card.as(UI::View)
    when "sidebars"
      # Amber sidebar: MEMORIES section (Inbox 12 · Dreamed · Noted · Archived)
      # + VAULTS section (Morning Pages · Sketches · Rituals · Code Spells).
      # HIG: "A sidebar appears on the leading side of a view and lets people
      # navigate between sections in your app or game." Sidebars float above
      # content in the Liquid Glass layer.
      #
      # Architecture: Option A (explicit 3-column HStack).
      # We do NOT wrap in NavigationSplitView. That type renders its own
      # 3-column structure internally; adding our custom message list adjacent
      # to it doubles the column count (4 columns visible). Instead we compose
      # three explicit columns: sidebar + message list + detail pane.
      # The sidebar column is wrapped in UI::GlassBackground with sidebar
      # material so it gets NSVisualEffectView(material: .sidebar) exactly as HIG
      # requires. The overall container is an HStack that the InboxScene wraps
      # in app chrome via :full_2pane focal_position.
      #
      # HIG Best practices: "Consider using familiar symbols to represent items in
      # the sidebar." All rows use SF Symbols as leading icons.
      # HIG macOS: "sidebar icons use the current accent color."
      # Amber accent (Amber gold #FFAD33 -> r:1.0, g:0.678, b:0.2) used in place
      # of systemBlue for icon tints.

      # Amber gold color (r:1.0 g:0.678 b:0.2)
      amber_gold = UI::Color.new(r: 1.0, g: 0.678, b: 0.2)
      # Amber plum for secondary accent (r:0.357 g:0.227 b:0.58)
      amber_plum = UI::Color.new(r: 0.357, g: 0.227, b: 0.58)

      sidebar_stack = UI::VStack.new(spacing: 6.0)
      sidebar_stack.alignment = UI::Alignment::Leading
      sidebar_stack.minimum_width = 188.0
      sidebar_stack.maximum_width = 188.0
      sidebar_stack.minimum_height = 856.0
      sidebar_stack.maximum_height = 856.0
      sidebar_stack.padding = UI::EdgeInsets.new(top: 13.0, trailing: 13.0, bottom: 13.0, leading: 13.0)

      # MEMORIES section header
      memories_hdr = UI::Label.new("MEMORIES")
      memories_hdr.font = UI::Font.new(size: 11.0, weight: :semibold)
      memories_hdr.text_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.6)
      memories_hdr.accessibility_label = "Memories section header"
      sidebar_stack << memories_hdr

      # Inbox row (badge 12)
      inbox_row = UI::HStack.new(spacing: 8.0)
      inbox_icon = UI::Image.new("tray.fill")
      inbox_icon.tint_color = amber_gold
      inbox_icon.accessibility_label = "Inbox icon"
      inbox_label = UI::Label.new("Inbox")
      inbox_label.font = UI::Font.new(size: 14.0, weight: :regular)
      inbox_label.accessibility_label = "Inbox"
      inbox_badge = UI::Label.new("12")
      inbox_badge.font = UI::Font.new(size: 12.0, weight: :semibold)
      inbox_badge.text_color = amber_gold
      inbox_badge.accessibility_label = "12 unread memories"
      inbox_spacer = UI::Spacer.new
      inbox_row << inbox_icon
      inbox_row << inbox_label
      inbox_row << inbox_spacer
      inbox_row << inbox_badge
      inbox_row.accessibility_label = "Inbox navigation row"
      sidebar_stack << inbox_row

      # Dreamed row
      dreamed_row = UI::HStack.new(spacing: 8.0)
      dreamed_icon = UI::Image.new("moon.stars.fill")
      dreamed_icon.tint_color = amber_plum
      dreamed_icon.accessibility_label = "Dreamed icon"
      dreamed_label = UI::Label.new("Dreamed")
      dreamed_label.font = UI::Font.new(size: 14.0, weight: :regular)
      dreamed_label.accessibility_label = "Dreamed"
      dreamed_row << dreamed_icon
      dreamed_row << dreamed_label
      dreamed_row.accessibility_label = "Dreamed navigation row"
      sidebar_stack << dreamed_row

      # Noted row
      noted_row = UI::HStack.new(spacing: 8.0)
      noted_icon = UI::Image.new("note.text")
      noted_icon.tint_color = amber_gold
      noted_icon.accessibility_label = "Noted icon"
      noted_label = UI::Label.new("Noted")
      noted_label.font = UI::Font.new(size: 14.0, weight: :regular)
      noted_label.accessibility_label = "Noted"
      noted_row << noted_icon
      noted_row << noted_label
      noted_row.accessibility_label = "Noted navigation row"
      sidebar_stack << noted_row

      # Archived row
      archived_row = UI::HStack.new(spacing: 8.0)
      archived_icon = UI::Image.new("archivebox.fill")
      archived_icon.tint_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      archived_icon.accessibility_label = "Archived icon"
      archived_label = UI::Label.new("Archived")
      archived_label.font = UI::Font.new(size: 14.0, weight: :regular)
      archived_label.accessibility_label = "Archived"
      archived_row << archived_icon
      archived_row << archived_label
      archived_row.accessibility_label = "Archived navigation row"
      sidebar_stack << archived_row

      # Separator
      mem_sep = UI::Divider.new
      mem_sep.accessibility_label = "Section separator"
      sidebar_stack << mem_sep

      # VAULTS section header
      vaults_hdr = UI::Label.new("VAULTS")
      vaults_hdr.font = UI::Font.new(size: 11.0, weight: :semibold)
      vaults_hdr.text_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.6)
      vaults_hdr.accessibility_label = "Vaults section header"
      sidebar_stack << vaults_hdr

      # Morning Pages vault
      mp_row = UI::HStack.new(spacing: 8.0)
      mp_icon = UI::Image.new("sun.max.fill")
      mp_icon.tint_color = amber_gold
      mp_icon.accessibility_label = "Morning pages icon"
      mp_label = UI::Label.new("Morning Pages")
      mp_label.font = UI::Font.new(size: 14.0, weight: :regular)
      mp_label.accessibility_label = "Morning Pages vault"
      mp_row << mp_icon
      mp_row << mp_label
      mp_row.accessibility_label = "Morning Pages navigation row"
      sidebar_stack << mp_row

      # Sketches vault
      sk_row = UI::HStack.new(spacing: 8.0)
      sk_icon = UI::Image.new("pencil.and.scribble")
      sk_icon.tint_color = amber_plum
      sk_icon.accessibility_label = "Sketches icon"
      sk_label = UI::Label.new("Sketches")
      sk_label.font = UI::Font.new(size: 14.0, weight: :regular)
      sk_label.accessibility_label = "Sketches vault"
      sk_row << sk_icon
      sk_row << sk_label
      sk_row.accessibility_label = "Sketches navigation row"
      sidebar_stack << sk_row

      # Rituals vault
      ri_row = UI::HStack.new(spacing: 8.0)
      ri_icon = UI::Image.new("wand.and.stars")
      ri_icon.tint_color = amber_plum
      ri_icon.accessibility_label = "Rituals icon"
      ri_label = UI::Label.new("Rituals")
      ri_label.font = UI::Font.new(size: 14.0, weight: :regular)
      ri_label.accessibility_label = "Rituals vault"
      ri_row << ri_icon
      ri_row << ri_label
      ri_row.accessibility_label = "Rituals navigation row"
      sidebar_stack << ri_row

      # Code Spells vault
      cs_row = UI::HStack.new(spacing: 8.0)
      cs_icon = UI::Image.new("chevron.left.forwardslash.chevron.right")
      cs_icon.tint_color = amber_gold
      cs_icon.accessibility_label = "Code Spells icon"
      cs_label = UI::Label.new("Code Spells")
      cs_label.font = UI::Font.new(size: 14.0, weight: :regular)
      cs_label.accessibility_label = "Code Spells vault"
      cs_row << cs_icon
      cs_row << cs_label
      cs_row.accessibility_label = "Code Spells navigation row"
      sidebar_stack << cs_row

      # --- Message list column (content pane) ---
      # Amber-voice message rows: avatar circle + text VStack + timestamp.
      # Row height 68pt (HIG inset-grouped cell standard for 3-line rows).
      # Section header "INBOX" at 11pt SemiBold Caps.
      # Each row separated by a 1pt horizontal Divider.
      #
      # Row anatomy (left-to-right):
      #   [unread dot 10pt] [avatar circle 32pt SF symbol] [VStack: sender/subject/preview] [Spacer] [timestamp + unread badge]
      msg_list = UI::VStack.new(spacing: 0.0)
      msg_list.alignment = UI::Alignment::Leading
      msg_list.minimum_width = 252.0
      msg_list.maximum_width = 252.0
      msg_list.minimum_height = 856.0
      msg_list.maximum_height = 856.0

      inbox_hdr = UI::Label.new("INBOX")
      inbox_hdr.font = UI::Font.new(size: 11.0, weight: :semibold)
      inbox_hdr.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      inbox_hdr.accessibility_label = "Inbox section header"
      inbox_hdr.padding = UI::EdgeInsets.new(top: 8.0, trailing: 8.0, bottom: 4.0, leading: 8.0)
      msg_list << inbox_hdr

      [
        {true, "Amber", "Morning pages unlocked", "Your 3-page ritual is complete. Amber noticed the shift.", "9:14"},
        {true, "Rituals", "5 rituals due tomorrow", "Morning pages, breathwork, evening review, and 2 more.", "Tue"},
        {false, "Vault", "248 artifacts archived", "Your vault is thriving. The rift is stable.", "Sun"},
        {false, "Deep Work", "2h 14m today \u00B7 new record", "You outran yesterday's session. Amber is holding the streak.", "Apr 13"},
        {false, "Amber", "Memory synced across rift", "Your vault is up to date. Nothing was lost.", "Apr 12"},
      ].each_with_index do |(unread, sender, subject, preview, timestamp), idx|
        if idx > 0
          sep = UI::Divider.new(:horizontal)
          sep.accessibility_label = "Message separator"
          msg_list << sep
        end

        # Unread indicator dot (8pt, amber gold, leading-most element)
        dot_lbl = UI::Label.new(unread ? "\u25CF" : " ")
        dot_lbl.font = UI::Font.new(size: 8.0, weight: :regular)
        dot_lbl.text_color = amber_gold
        dot_lbl.minimum_width = 10.0
        dot_lbl.accessibility_label = unread ? "Unread" : ""

        # Avatar: 32pt circle with person.circle.fill SF Symbol, amber gold tint
        avatar_img = UI::Image.new("person.circle.fill")
        avatar_img.tint_color = amber_gold
        avatar_img.minimum_width = 32.0
        avatar_img.minimum_height = 32.0
        avatar_img.content_mode = UI::ContentMode::Fit
        avatar_img.accessibility_label = "#{sender} avatar"

        # Text column: sender (15pt semibold if unread else regular),
        # subject (13pt), preview (12pt secondary)
        sender_lbl = UI::Label.new(sender)
        sender_lbl.font = UI::Font.new(size: 15.0, weight: unread ? :semibold : :regular)
        sender_lbl.accessibility_label = "From #{sender}"

        subject_lbl = UI::Label.new(subject)
        subject_lbl.font = UI::Font.new(size: 13.0, weight: unread ? :semibold : :regular)
        subject_lbl.accessibility_label = "Subject: #{subject}"

        preview_lbl = UI::Label.new(preview)
        preview_lbl.font = UI::Font.new(size: 12.0, weight: :regular)
        preview_lbl.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
        preview_lbl.accessibility_label = "Preview"

        text_col = UI::VStack.new(spacing: 1.0)
        text_col << sender_lbl.as(UI::View)
        text_col << subject_lbl.as(UI::View)
        text_col << preview_lbl.as(UI::View)

        # Trailing: timestamp (11pt tertiary) + optional unread badge dot
        ts_lbl = UI::Label.new(timestamp)
        ts_lbl.font = UI::Font.new(size: 11.0, weight: :regular)
        ts_lbl.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
        ts_lbl.accessibility_label = "Received #{timestamp}"

        trailing_col = UI::VStack.new(spacing: 2.0)
        trailing_col << ts_lbl.as(UI::View)
        if unread
          badge_dot = UI::Label.new("\u25CF")
          badge_dot.font = UI::Font.new(size: 10.0, weight: :regular)
          badge_dot.text_color = amber_gold
          badge_dot.accessibility_label = "Unread badge"
          trailing_col << badge_dot.as(UI::View)
        end

        msg_row = UI::HStack.new(spacing: 6.0)
        msg_row << dot_lbl.as(UI::View)
        msg_row << avatar_img.as(UI::View)
        msg_row << text_col.as(UI::View)
        msg_row << UI::Spacer.new.as(UI::View)
        msg_row << trailing_col.as(UI::View)
        msg_row.minimum_height = 68.0
        msg_row.padding = UI::EdgeInsets.new(top: 10.0, trailing: 8.0, bottom: 10.0, leading: 8.0)
        msg_row.accessibility_label = "Message from #{sender}: #{subject}"
        msg_list << msg_row
      end

      # --- Detail pane: empty state (centered in right 60% of window) ---
      # HIG Best practices: "Provide meaningful content in the detail pane."
      # Empty state: envelope.open SF Symbol + "Select a memory to read" hint,
      # centered in the detail column (not bottom-left).
      detail_icon = UI::Image.new("envelope.open")
      detail_icon.minimum_width = 48.0
      detail_icon.minimum_height = 48.0
      detail_icon.content_mode = UI::ContentMode::Fit
      detail_icon.tint_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      detail_icon.accessibility_label = "Empty state envelope icon"

      detail_hint = UI::Label.new("Select a memory to read")
      detail_hint.font = UI::Font.new(size: 15.0, weight: :regular)
      detail_hint.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      detail_hint.accessibility_label = "Select a memory to read"

      # Vertical centering: Spacer + icon + hint + Spacer fills the detail column.
      # Horizontal centering: leading Spacer + content + trailing Spacer,
      # pinned to 697pt so the Spacers have definite space to distribute.
      detail_center_h = UI::HStack.new(spacing: 0.0)
      detail_center_h.alignment = UI::Alignment::Fill
      detail_center_h.minimum_width = 518.0
      detail_center_h.maximum_width = 518.0
      detail_icon_hint = UI::VStack.new(spacing: 8.0)
      detail_icon_hint.alignment = UI::Alignment::Center
      detail_icon_hint << detail_icon.as(UI::View)
      detail_icon_hint << detail_hint.as(UI::View)
      detail_center_h << UI::Spacer.new.as(UI::View)
      detail_center_h << detail_icon_hint.as(UI::View)
      detail_center_h << UI::Spacer.new.as(UI::View)

      detail_empty = UI::VStack.new(spacing: 0.0)
      detail_empty << UI::Spacer.new.as(UI::View)
      detail_empty << detail_center_h.as(UI::View)
      detail_empty << UI::Spacer.new.as(UI::View)
      detail_empty.alignment = UI::Alignment::Fill
      detail_empty.minimum_width = 518.0
      detail_empty.maximum_width = 518.0
      detail_empty.minimum_height = 856.0
      detail_empty.maximum_height = 856.0
      detail_empty.accessibility_label = "Detail empty state"

      # --- Sidebar glass wrapper ---
      # Wrap sidebar_stack in GlassBackground with sidebar material so the column
      # renders NSVisualEffectView(material: .sidebar) per HIG. The glass view is
      # given exact width (188pt) and the same minimum_height as the body_row.
      # GlassBackground maps to NSVisualEffectView on macOS with the sidebar
      # material (NSVisualEffectMaterialSidebar = 7), tracking appearance.
      sidebar_glass = UI::GlassBackground.new(sidebar_stack.as(UI::View))
      sidebar_glass.material = :sidebar
      sidebar_glass.minimum_width = 188.0
      sidebar_glass.maximum_width = 188.0
      sidebar_glass.minimum_height = 856.0
      sidebar_glass.maximum_height = 856.0
      sidebar_glass.accessibility_label = "Amber sidebar glass column"

      # --- Option A: explicit 3-column HStack ---
      # Column 1: sidebar glass (188pt, NSVisualEffectView sidebar material)
      # Separator 1: 1pt vertical Divider
      # Column 2: message list (252pt, fixed)
      # Separator 2: 1pt vertical Divider
      # Column 3: detail pane (fills the remainder of the study width)
      sep_a = UI::Divider.new(:vertical)
      sep_a.accessibility_label = "Sidebar / message-list separator"
      sep_b = UI::Divider.new(:vertical)
      sep_b.accessibility_label = "Message-list / detail separator"

      three_col = UI::HStack.new(spacing: 0.0)
      three_col.alignment = UI::Alignment::Fill
      three_col.minimum_width = 960.0
      three_col.maximum_width = 960.0
      three_col.minimum_height = 856.0
      three_col.maximum_height = 856.0
      three_col << sidebar_glass.as(UI::View)
      three_col << sep_a.as(UI::View)
      three_col << msg_list.as(UI::View)
      three_col << sep_b.as(UI::View)
      three_col << detail_empty.as(UI::View)
      three_col.accessibility_label = "Amber 3-column inbox layout"
      three_col.as(UI::View)
    when "split-views"
      # HIG: "A split view manages the presentation of multiple adjacent panes of
      # content, each of which can contain a variety of components, including
      # tables, collections, images, and custom views."
      #
      # Distinct from sidebars (iter 41) which only validated the navigation
      # column. Split-views validates the FULL divided canvas: sidebar pane |
      # list pane | detail pane, with 1pt thin dividers between columns.
      #
      # Showcase: 3-pane Mail-style layout.
      #   Left (~160pt): Mailboxes navigation sidebar.
      #   Middle (~220pt): "Inbox" message list — 4 rows (sender / subject /
      #     preview) with thin dividers between rows.
      #   Right (remainder): Message detail — From/Subject header + body text.
      #
      # HIG Best practices: "To support navigation, persistently highlight the
      # current selection in each pane that leads to the detail view."
      # HIG macOS: "Prefer the thin divider style. The thin divider measures one
      # point in width, giving you maximum space for content."
      #
      # The outer container is an HStack so AppKit places panes left-to-right.
      # Explicit UI::Divider views between columns produce the 1pt separators
      # that make the split visually distinguishable from the sidebars render.

      # --- Pane 1: Sidebar (left ~186pt) ---
      sv_mailboxes_hdr = UI::Label.new("MAILBOXES")
      sv_mailboxes_hdr.font = UI::Font.new(size: 11.0, weight: :semibold)
      sv_mailboxes_hdr.text_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.6)
      sv_mailboxes_hdr.accessibility_label = "Mailboxes section header"

      sv_inbox_row = UI::HStack.new(spacing: 6.0)
      sv_inbox_icon = UI::Image.new("envelope")
      sv_inbox_icon.tint_color = UI::Color.new(r: 0.0, g: 0.478, b: 1.0)
      sv_inbox_icon.accessibility_label = "Envelope icon"
      sv_inbox_lbl = UI::Label.new("Inbox")
      sv_inbox_lbl.font = UI::Font.new(size: 13.0, weight: :semibold)
      sv_inbox_lbl.accessibility_label = "Inbox, selected"
      sv_inbox_badge = UI::Label.new("12")
      sv_inbox_badge.font = UI::Font.new(size: 11.0, weight: :semibold)
      sv_inbox_badge.text_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.6)
      sv_inbox_badge.accessibility_label = "12 unread"
      sv_inbox_spacer = UI::Spacer.new
      sv_inbox_row << sv_inbox_icon
      sv_inbox_row << sv_inbox_lbl
      sv_inbox_row << sv_inbox_spacer
      sv_inbox_row << sv_inbox_badge
      sv_inbox_row.accessibility_label = "Inbox row, selected"

      sv_flagged_row = UI::HStack.new(spacing: 6.0)
      sv_flag_icon = UI::Image.new("flag")
      sv_flag_icon.tint_color = UI::Color.new(r: 1.0, g: 0.584, b: 0.0)
      sv_flag_icon.accessibility_label = "Flag icon"
      sv_flagged_lbl = UI::Label.new("Flagged")
      sv_flagged_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
      sv_flagged_lbl.accessibility_label = "Flagged"
      sv_flagged_row << sv_flag_icon
      sv_flagged_row << sv_flagged_lbl
      sv_flagged_row.accessibility_label = "Flagged navigation row"

      sv_sep1 = UI::Divider.new
      sv_sep1.accessibility_label = "Sidebar section separator"

      sv_folders_hdr = UI::Label.new("FOLDERS")
      sv_folders_hdr.font = UI::Font.new(size: 11.0, weight: :semibold)
      sv_folders_hdr.text_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.6)
      sv_folders_hdr.accessibility_label = "Folders section header"

      sv_work_row = UI::HStack.new(spacing: 6.0)
      sv_work_icon = UI::Image.new("folder")
      sv_work_icon.tint_color = UI::Color.new(r: 0.0, g: 0.478, b: 1.0)
      sv_work_icon.accessibility_label = "Folder icon"
      sv_work_lbl = UI::Label.new("Work")
      sv_work_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
      sv_work_lbl.accessibility_label = "Work folder"
      sv_work_row << sv_work_icon
      sv_work_row << sv_work_lbl
      sv_work_row.accessibility_label = "Work folder navigation row"

      sv_sidebar_stack = UI::VStack.new(spacing: 6.0)
      sv_sidebar_stack.alignment = UI::Alignment::Leading
      sv_sidebar_stack.minimum_width = 186.0
      sv_sidebar_stack.maximum_width = 186.0
      sv_sidebar_stack.minimum_height = 856.0
      sv_sidebar_stack.maximum_height = 856.0
      sv_sidebar_stack.padding = UI::EdgeInsets.new(top: 13.0, trailing: 13.0, bottom: 13.0, leading: 13.0)
      sv_sidebar_stack << sv_mailboxes_hdr
      sv_sidebar_stack << sv_inbox_row
      sv_sidebar_stack << sv_flagged_row
      sv_sidebar_stack << sv_sep1
      sv_sidebar_stack << sv_folders_hdr
      sv_sidebar_stack << sv_work_row
      sv_sidebar_stack << UI::Spacer.new

      # --- Pane 2: Message list (middle ~240pt) ---
      sv_list_hdr = UI::Label.new("Inbox")
      sv_list_hdr.font = UI::Font.new(size: 15.0, weight: :semibold)
      sv_list_hdr.accessibility_label = "Inbox list header"

      sv_list_content = UI::VStack.new(spacing: 6.0)
      sv_list_content.alignment = UI::Alignment::Leading
      sv_list_content.minimum_width = 240.0
      sv_list_content.maximum_width = 240.0
      sv_list_content.minimum_height = 856.0
      sv_list_content.maximum_height = 856.0
      sv_list_content.padding = UI::EdgeInsets.new(top: 13.0, trailing: 13.0, bottom: 13.0, leading: 13.0)
      sv_list_content << sv_list_hdr
      [
        {"Alice Martin", "Quarterly report", "Q1 numbers attached."},
        {"Bob Chen", "Re: Meeting notes", "Reviewed; all clear."},
        {"Carol Davis", "Weekend plans", "Saturday works?"},
        {"Dave Kim", "Invoice #4821", "March invoice attached."},
      ].each_with_index do |(sender, subject, preview), idx|
        if idx > 0
          sv_list_content << UI::Divider.new
        end
        row_v = UI::VStack.new(spacing: 2.0)
        s_lbl = UI::Label.new(sender)
        s_lbl.font = UI::Font.new(size: 13.0, weight: :semibold)
        s_lbl.accessibility_label = "Sender #{sender}"
        sub_lbl = UI::Label.new(subject)
        sub_lbl.font = UI::Font.new(size: 12.0, weight: :regular)
        sub_lbl.accessibility_label = "Subject #{subject}"
        prev_lbl = UI::Label.new(preview)
        prev_lbl.font = UI::Font.new(size: 11.0, weight: :regular)
        prev_lbl.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
        prev_lbl.accessibility_label = "Preview"
        row_v << s_lbl
        row_v << sub_lbl
        row_v << prev_lbl
        row_v.accessibility_label = "Message from #{sender}"
        sv_list_content << row_v
      end

      # --- Pane 3: Message detail (right, remainder) ---
      sv_detail_from = UI::Label.new("From: Alice Martin <alice@example.com>")
      sv_detail_from.font = UI::Font.new(size: 12.0, weight: :regular)
      sv_detail_from.accessibility_label = "From Alice Martin"

      sv_detail_subject = UI::Label.new("Subject: Quarterly report")
      sv_detail_subject.font = UI::Font.new(size: 12.0, weight: :semibold)
      sv_detail_subject.accessibility_label = "Subject Quarterly report"

      sv_detail_sep = UI::Divider.new
      sv_detail_sep.accessibility_label = "Message header separator"

      sv_detail_body = UI::Label.new("Hi,\n\nPlease find the Q1 numbers attached. Revenue was up 12% year-over-year and margin improved by 2.4 points.\n\nLet me know if you want the backup file.\n\n— Alice")
      sv_detail_body.font = UI::Font.new(size: 13.0, weight: :regular)
      sv_detail_body.accessibility_label = "Message body"

      sv_detail_pane = UI::VStack.new(spacing: 8.0)
      sv_detail_pane.alignment = UI::Alignment::Leading
      sv_detail_pane.minimum_width = 540.0
      sv_detail_pane.maximum_width = 540.0
      sv_detail_pane.minimum_height = 856.0
      sv_detail_pane.maximum_height = 856.0
      sv_detail_pane.padding = UI::EdgeInsets.new(top: 19.0, trailing: 24.0, bottom: 19.0, leading: 24.0)
      sv_detail_pane << sv_detail_from
      sv_detail_pane << sv_detail_subject
      sv_detail_pane << sv_detail_sep
      sv_detail_pane << sv_detail_body
      sv_detail_pane << UI::Spacer.new

      # --- Assemble: sidebar | divider | list | divider | detail ---
      # Using NavigationSplitView with content + detail populated so all three
      # columns render. An enclosing HStack with UI::Divider elements provides
      # the visible 1pt column separators HIG requires.
      #
      # The outer HStack ensures macOS renders all three columns side-by-side
      # (AppKit places HStack children in a horizontal NSStackView) with the
      # Divider views providing the 1pt separator lines between columns.
      sv_col_sep_a = UI::Divider.new
      sv_col_sep_a.accessibility_label = "Column divider between sidebar and list"
      sv_col_sep_b = UI::Divider.new
      sv_col_sep_b.accessibility_label = "Column divider between list and detail"

      sv_outer = UI::HStack.new(spacing: 0.0)
      sv_outer.alignment = UI::Alignment::Fill
      sv_outer.minimum_width = 968.0
      sv_outer.maximum_width = 968.0
      sv_outer.minimum_height = 856.0
      sv_outer.maximum_height = 856.0
      sv_outer << sv_sidebar_stack
      sv_outer << sv_col_sep_a
      sv_outer << sv_list_content
      sv_outer << sv_col_sep_b
      sv_outer << sv_detail_pane
      sv_outer.accessibility_label = "3-pane split view: sidebar, message list, detail"
      sv_outer.as(UI::View)
    when "sheets"
      # Amber sheet: "Conjure Reminder" — scoped task sheet with Amber-voice copy.
      # HIG: "A sheet helps people perform a scoped task that's closely related
      # to their current context." Rendered inline (surface_style: :grouped_card)
      # via NSVisualEffectView (NSVisualEffectMaterialMenu, material 10, tracks
      # appearance). NOT via is_presented which triggers NSWindow modal lifecycle.
      # Title: "Conjure Reminder" (17pt Headline). Fields: "Morning pages title",
      # "e.g. Apr 15 · 7:00", "None / Low / Medium / High" per Amber copy.
      # Action wiring: Conjure is the primary CTA (Prominent Amber gold fill);
      # Cancel is the secondary action (semibold label, bordered/default style).
      # HIG: "Always include a button that dismisses the sheet" — Cancel role.
      # HIG: "Use the Prominent (filled) style for the most likely action" — Conjure.

      # Grabber handle — 5pt tall, 36pt wide, secondary fill, centered at top.
      # HIG sheet: "Include a grabber if the sheet can be resized."
      sh_grabber_row = UI::HStack.new(spacing: 0.0)
      sh_grabber_row << UI::Spacer.new.as(UI::View)
      sh_grabber_dot = UI::Label.new("          ")
      sh_grabber_dot.background = UI::Color.new(r: 0.55, g: 0.55, b: 0.55, a: 0.5)
      sh_grabber_dot.corner_radius = 2.5
      sh_grabber_dot.minimum_height = 5.0
      sh_grabber_dot.maximum_height = 5.0
      sh_grabber_dot.minimum_width = 36.0
      sh_grabber_dot.maximum_width = 36.0
      sh_grabber_dot.accessibility_label = "Sheet grabber"
      sh_grabber_row << sh_grabber_dot.as(UI::View)
      sh_grabber_row << UI::Spacer.new.as(UI::View)
      sh_grabber_row.minimum_height = 13.0

      # Title: 17pt Headline per HIG sheet typography.
      sh_title = UI::Label.new("Conjure Reminder")
      sh_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      sh_title.accessibility_label = "Sheet title: Conjure Reminder"

      sh_divider = UI::Divider.new

      # Form rows — Amber-voice copy.  Each row is an HStack: 80pt right-aligned
      # label (13pt regular) + TextField that fills remaining card width.
      # sheet card width: 540pt; inner insets 16pt x 2 = 508pt usable.
      # TextField minimum_width = 360pt so it fills the right portion of the row.
      # Row gap: 13pt per HIG form spacing.
      make_sh_row = ->(label_text : String, placeholder : String, a11y : String) do
        sh_lbl = UI::Label.new(label_text)
        sh_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
        sh_lbl.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
        sh_lbl.minimum_width = 80.0
        sh_lbl.maximum_width = 80.0
        sh_lbl.accessibility_label = "#{label_text} label"

        sh_fld = UI::TextField.new(placeholder)
        sh_fld.minimum_width = 360.0
        sh_fld.accessibility_label = a11y

        sh_row_h = UI::HStack.new(spacing: 8.0)
        sh_row_h << sh_lbl.as(UI::View)
        sh_row_h << sh_fld.as(UI::View)
        sh_row_h.minimum_height = 28.0
        sh_row_h.accessibility_label = "Form row: #{label_text}"
        sh_row_h.as(UI::View)
      end

      sh_form = UI::VStack.new(spacing: 13.0)
      sh_form.alignment = UI::Alignment::Leading
      sh_form << make_sh_row.call("Title:", "Morning pages title", "Reminder title field")
      sh_form << make_sh_row.call("When:", "e.g. Apr 15 \u00B7 7:00", "Reminder date and time field")
      sh_form << make_sh_row.call("Weight:", "None / Low / Medium / High", "Reminder priority field")

      sh_divider2 = UI::Divider.new

      # Bottom action bar:
      #   Cancel — role: :cancel (semibold, bordered/default style, Amber gold label)
      #   Conjure — role: :default, style: Prominent (Amber gold fill, ember-dark label)
      # HIG: primary action (Conjure) uses filled/prominent; cancel is secondary.
      sh_cancel = UI::Button.new("Cancel", role: :cancel)
      sh_cancel.accessibility_label = "Cancel sheet"
      sh_save = UI::Button.new("Conjure", role: :default, style: UI::ButtonStyle::Prominent)
      sh_save.accessibility_label = "Conjure reminder"

      sh_actions = UI::HStack.new(spacing: 12.0)
      sh_actions << sh_cancel
      sh_actions << UI::Spacer.new
      sh_actions << sh_save

      sh_body = UI::VStack.new(spacing: 12.0)
      sh_body << sh_grabber_row
      sh_body << sh_title
      sh_body << sh_divider
      sh_body << sh_form
      sh_body << sh_divider2
      sh_body << sh_actions

      UI::Sheet.new(sh_body.as(UI::View), surface_style: :grouped_card).as(UI::View)
    when "image-views"
      # HIG: "An image view displays a single image on a transparent or opaque
      # background." Six-variant gallery exercising the HIG-described shapes:
      # 1. SF Symbol image (large tinted) via UI::Image + tint_color
      # 2. Square photo thumbnail (bordered rectangle placeholder)
      # 3. Circular avatar (UI::Circle, clipped)
      # 4. Rounded-corner card thumbnail (UI::RoundedRectangle, 12pt radius)
      # 5. Loading state (UI::ActivityIndicator + label)
      # 6. Error/placeholder state (gray rectangle + broken-image label)
      #
      # clip_shape is not yet a property on UI::AsyncImage; circular avatar uses
      # UI::Circle directly. See validation/gaps.md (iteration 29 entry).
      gallery = UI::VStack.new(spacing: 14.0)
      gallery.alignment = UI::Alignment::Center

      image_title = UI::Label.new("Image view")
      image_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      image_title.accessibility_label = "Image views study title"
      gallery << image_title

      image_subtitle = UI::Label.new("One visual at a time, with room around it.")
      image_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      image_subtitle.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      image_subtitle.accessibility_label = "Image views study subtitle"
      gallery << image_subtitle

      hero_label = UI::Label.new("Symbol image")
      hero_label.font = UI::Font.new(size: 12.0, weight: :regular)
      hero_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      gallery << hero_label
      sym_img = UI::Image.new("star.fill")
      sym_img.tint_color = UI::Color.new(r: 1.0, g: 0.58, b: 0.0)
      gallery << sym_img

      thumb_label = UI::Label.new("Thumbnail and avatar")
      thumb_label.font = UI::Font.new(size: 12.0, weight: :regular)
      thumb_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      gallery << thumb_label

      thumb_row = UI::HStack.new(spacing: 18.0)
      thumb_row.alignment = UI::Alignment::Center
      thumb = UI::Rectangle.new(width: 124.0, height: 124.0)
      thumb.fill_color = UI::Color.new(r: 0.84, g: 0.81, b: 0.77)
      thumb.stroke_color = UI::Color.new(r: 0.65, g: 0.58, b: 0.52)
      thumb.stroke_width = 1.0
      thumb_row << thumb
      avatar = UI::Circle.new(72.0)
      avatar.fill_color = UI::Color.new(r: 0.69, g: 0.56, b: 0.49)
      avatar.stroke_color = UI::Color.new(r: 1.0, g: 0.95, b: 0.88)
      avatar.stroke_width = 2.0
      thumb_row << avatar
      gallery << thumb_row

      placeholder_label = UI::Label.new("Placeholder state")
      placeholder_label.font = UI::Font.new(size: 12.0, weight: :regular)
      placeholder_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      gallery << placeholder_label

      placeholder_row = UI::HStack.new(spacing: 10.0)
      placeholder_row.alignment = UI::Alignment::Center
      err_bg = UI::Rectangle.new(width: 160.0, height: 96.0)
      err_bg.fill_color = UI::Color.new(r: 0.90, g: 0.90, b: 0.92)
      err_bg.stroke_color = UI::Color.new(r: 0.75, g: 0.75, b: 0.77)
      err_bg.stroke_width = 1.0
      placeholder_row << err_bg
      placeholder_msg = UI::VStack.new(spacing: 2.0)
      placeholder_msg.alignment = UI::Alignment::Leading
      err_sym = UI::Image.new("photo")
      err_sym.tint_color = UI::Color.new(r: 0.70, g: 0.70, b: 0.72)
      placeholder_msg << err_sym
      err_msg = UI::Label.new("Failed to load image")
      err_msg.font = UI::Font.new(size: 12.0, weight: :regular)
      err_msg.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      placeholder_msg << err_msg
      placeholder_row << placeholder_msg
      gallery << placeholder_row

      image_card = UI::Card.new(gallery.as(UI::View))
      image_card.minimum_width = 520.0
      image_card.maximum_width = 520.0
      image_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      image_card.is_outlined = true
      image_card.material = :secondary
      image_card.accessibility_label = "Image views study card"
      image_card.as(UI::View)
    when "tab-bars"
      # HIG: "A tab bar lets people navigate between top-level sections of your app."
      # HIG tab-bars (iOS): "A tab bar floats above content at the bottom of the screen.
      # Its items rest on a Liquid Glass background that allows content beneath to peek through."
      # Showcase: 5-tab bar -- house/Home, magnifyingglass/Search (selected, blue), heart/Favorites,
      # bell/Activity, person/Profile. Demonstrates SF Symbol icons + labels + selected-tab tint.
      # On macOS: rendered using NSVisualEffectMaterialMenu (10) glass surface to approximate
      # the iOS Liquid Glass bar. The selected tab (Search, index 1) is tinted system blue.
      # HIG: "Consider using SF Symbols to provide familiar, scalable tab bar icons."
      # HIG: "Include tab labels to help with navigation."

      home_content = UI::VStack.new(spacing: 8.0)
      home_lbl = UI::Label.new("Home")
      home_lbl.font = UI::Font.new(size: 15.0, weight: :semibold)
      home_lbl.accessibility_label = "Home section content"
      home_content << home_lbl

      search_content = UI::VStack.new(spacing: 8.0)
      search_lbl = UI::Label.new("Search")
      search_lbl.font = UI::Font.new(size: 15.0, weight: :semibold)
      search_lbl.accessibility_label = "Search section content"
      search_hint = UI::Label.new("Find memories, rituals, and vaults")
      search_hint.font = UI::Font.new(size: 13.0, weight: :regular)
      search_hint.text_color_role = UI::LabelRole::Secondary
      search_hint.accessibility_label = "Search section hint"
      search_content << search_lbl
      search_content << search_hint

      tabs = [
        UI::TabView::Tab.new(label: "Home", icon: "house", content: home_content.as(UI::View)),
        UI::TabView::Tab.new(label: "Search", icon: "magnifyingglass", content: search_content.as(UI::View)),
        UI::TabView::Tab.new(label: "Favorites", icon: "heart", content: UI::Label.new("Favorites").as(UI::View)),
        UI::TabView::Tab.new(label: "Activity", icon: "bell", content: UI::Label.new("Activity").as(UI::View)),
        UI::TabView::Tab.new(label: "Profile", icon: "person", content: UI::Label.new("Profile").as(UI::View)),
      ]

      tab_view = UI::TabView.new(tabs, 1)
      tab_view.glass_bar = true
      tab_view.minimum_width = 520.0
      tab_view.maximum_width = 520.0
      tab_view.minimum_height = 196.0
      tab_view.maximum_height = 196.0
      tab_view.accessibility_label = "Tab bar navigation"

      tab_bar_heading = UI::Label.new("Top-level navigation")
      tab_bar_heading.font = UI::Font.new(size: 17.0, weight: :semibold)
      tab_bar_heading.accessibility_label = "Top-level navigation heading"

      tab_bar_desc = UI::Label.new("Let the bar stay visually light so the selected destination is obvious without overwhelming the scene.")
      tab_bar_desc.font = UI::Font.new(size: 13.0)
      tab_bar_desc.accessibility_label = "Top-level navigation description"

      tab_bar_outer = UI::VStack.new(spacing: 12.0)
      tab_bar_outer.minimum_width = 520.0
      tab_bar_outer.maximum_width = 520.0
      tab_bar_outer << tab_bar_heading
      tab_bar_outer << tab_bar_desc
      tab_bar_outer << tab_view.as(UI::View)

      tab_bar_card = UI::Card.new(tab_bar_outer.as(UI::View))
      tab_bar_card.minimum_width = 556.0
      tab_bar_card.maximum_width = 556.0
      tab_bar_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      tab_bar_card.is_outlined = true
      tab_bar_card.material = :secondary
      tab_bar_card.accessibility_label = "Tab bar study card"
      tab_bar_card.as(UI::View)
    when "tab-views"
      # HIG tab-views: "A tab view presents multiple mutually exclusive panes of
      # content in the same area, which people can switch between using a tabbed control."
      # Platform: macOS only (NSTabView). Not supported on iOS -- use segmented control.
      # Pattern: top tab strip (text-only labels) above content pane. HIG: "The tabbed
      # control appears on the top edge of the content area." NSVisualEffectMaterialMenu
      # glass wraps the whole component for consistent appearance tracking.
      # HIG: "Provide a label for each tab that describes the contents of its pane."
      # HIG: "Avoid providing more than six tabs in a tab view."
      # Selected tab (General, index 0) tinted system blue; others secondary gray.

      general_content = UI::VStack.new(spacing: 12.0)
      general_heading = UI::Label.new("General")
      general_heading.font = UI::Font.new(size: 15.0, weight: :semibold)
      general_heading.accessibility_label = "General settings heading"
      general_row1 = UI::Label.new("Language & Region: English (US)")
      general_row1.font = UI::Font.new(size: 13.0, weight: :regular)
      general_row1.text_color_role = UI::LabelRole::Secondary
      general_row1.accessibility_label = "Language and region setting"
      general_row2 = UI::Label.new("Date & Time format: automatic")
      general_row2.font = UI::Font.new(size: 13.0, weight: :regular)
      general_row2.text_color_role = UI::LabelRole::Secondary
      general_row2.accessibility_label = "Date and time format setting"
      general_content << general_heading
      general_content << general_row1
      general_content << general_row2

      tv_tabs = [
        UI::TabView::Tab.new(label: "General", content: general_content.as(UI::View)),
        UI::TabView::Tab.new(label: "Advanced", content: UI::Label.new("Advanced settings").as(UI::View)),
        UI::TabView::Tab.new(label: "Accessibility", content: UI::Label.new("Accessibility options").as(UI::View)),
        UI::TabView::Tab.new(label: "Updates", content: UI::Label.new("Software updates").as(UI::View)),
      ]

      tv = UI::TabView.new(tv_tabs, 0)
      tv.bar_position = :top
      tv.glass_bar = true
      tv.minimum_width = 520.0
      tv.maximum_width = 520.0
      tv.minimum_height = 220.0
      tv.maximum_height = 220.0
      tv.accessibility_label = "Tab view navigation"

      tab_view_heading = UI::Label.new("Tabbed preferences")
      tab_view_heading.font = UI::Font.new(size: 17.0, weight: :semibold)
      tab_view_heading.accessibility_label = "Tabbed preferences heading"

      tab_view_desc = UI::Label.new("Keep tab labels terse and let the pane content carry the detail.")
      tab_view_desc.font = UI::Font.new(size: 13.0)
      tab_view_desc.accessibility_label = "Tabbed preferences description"

      tab_view_outer = UI::VStack.new(spacing: 12.0)
      tab_view_outer.minimum_width = 520.0
      tab_view_outer.maximum_width = 520.0
      tab_view_outer << tab_view_heading
      tab_view_outer << tab_view_desc
      tab_view_outer << tv.as(UI::View)

      tab_view_card = UI::Card.new(tab_view_outer.as(UI::View))
      tab_view_card.minimum_width = 556.0
      tab_view_card.maximum_width = 556.0
      tab_view_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      tab_view_card.is_outlined = true
      tab_view_card.material = :secondary
      tab_view_card.accessibility_label = "Tab view study card"
      tab_view_card.as(UI::View)
    when "charts"
      # Amber charts: "Focus minutes this week" bar chart, 7 days Mon-Sun.
      # Bar fill uses Amber plum (#5B3A94 -> r:0.357 g:0.227 b:0.58) per Amber
      # palette (NOT systemBlue). Realistic focus-session values (minutes).
      # HIG Best practices: "Establish a consistent visual hierarchy that helps
      # communicate the relative importance of various chart elements."
      # HIG: "In a compact environment, maximize the width of the plot area."
      # Amber plum per-bar color (#5B3A94 -> r:0.357 g:0.227 b:0.58).
      amber_plum_chart = UI::Color.new(r: 0.357, g: 0.227, b: 0.58)
      chart = UI::ChartView.new
      chart.chart_type = :bar
      chart.title = "Focus minutes this week"
      chart.data_points = [
        UI::ChartDataPoint.new(label: "Mon", value: 94.0, color: amber_plum_chart),
        UI::ChartDataPoint.new(label: "Tue", value: 120.0, color: amber_plum_chart),
        UI::ChartDataPoint.new(label: "Wed", value: 45.0, color: amber_plum_chart),
        UI::ChartDataPoint.new(label: "Thu", value: 138.0, color: amber_plum_chart),
        UI::ChartDataPoint.new(label: "Fri", value: 82.0, color: amber_plum_chart),
        UI::ChartDataPoint.new(label: "Sat", value: 157.0, color: amber_plum_chart),
        UI::ChartDataPoint.new(label: "Sun", value: 63.0, color: amber_plum_chart),
      ]
      chart.show_grid = true
      chart.show_legend = false
      chart.minimum_width = 360.0
      chart.maximum_width = 360.0
      chart.minimum_height = 220.0
      chart.maximum_height = 220.0
      chart.accessibility_label = "Focus minutes this week bar chart, Mon through Sun"
      chart_card = UI::Card.new(chart.as(UI::View))
      chart_card.minimum_width = 420.0
      chart_card.maximum_width = 420.0
      chart_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      chart_card.is_outlined = true
      chart_card.material = :secondary
      chart_card.accessibility_label = "Focus minutes study card"
      chart_card.as(UI::View)
    when "color-wells"
      # HIG Color wells: a small swatch button showing the current color.
      # HIG Best practices: "Consider the system-provided color picker for a
      # familiar experience."
      # macOS renders as NSColorWell -- a rounded rect filled with the chosen color.
      outer = UI::VStack.new(spacing: 16.0)

      # Row 1: labeled red color well.
      row1 = UI::HStack.new(spacing: 12.0)
      lbl1 = UI::Label.new("Stroke color")
      lbl1.accessibility_label = "Stroke color label"
      well1 = UI::ColorPicker.new
      well1.selected_color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
      well1.label = "Stroke color"
      well1.accessibility_label = "Stroke color well, red"
      row1 << lbl1
      row1 << well1

      # Row 2: labeled custom color well (teal #00897B -> r:0/g:137/b:123 -> 0.0/0.537/0.482).
      row2 = UI::HStack.new(spacing: 12.0)
      lbl2 = UI::Label.new("Fill color")
      lbl2.accessibility_label = "Fill color label"
      well2 = UI::ColorPicker.new
      well2.selected_color = UI::Color.new(r: 0.0, g: 0.537, b: 0.482)
      well2.label = "Fill color"
      well2.accessibility_label = "Fill color well, teal"
      row2 << lbl2
      row2 << well2

      # Row 3: "Pick a color..." label + color well (orange).
      row3 = UI::HStack.new(spacing: 12.0)
      lbl3 = UI::Label.new("Pick a color...")
      lbl3.accessibility_label = "Pick a color prompt"
      well3 = UI::ColorPicker.new
      well3.selected_color = UI::Color.new(r: 1.0, g: 0.584, b: 0.0)
      well3.label = "Pick a color"
      well3.accessibility_label = "Pick a color well, orange"
      row3 << lbl3
      row3 << well3

      outer << row1
      outer << row2
      outer << row3
      outer.as(UI::View)
    when "web-views"
      # HIG Web views: embeds rich web content (HTML or URL) inside an app.
      # HIG Best practices: "Support forward and back navigation when appropriate."
      # Use a deterministic local HTML preview so capture quality reflects the
      # default taste of the component rather than a random external site.
      preview_html = <<-HTML
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      html, body { margin: 0; padding: 0; background: #f4efe8; color: #171311; font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif; }
      body { padding: 22px; }
      .shell { background: rgba(255,255,255,0.76); border: 1px solid rgba(127,102,77,0.12); border-radius: 22px; padding: 18px; box-shadow: 0 18px 42px rgba(56,35,20,0.12); }
      .eyebrow { font-size: 11px; letter-spacing: 0.08em; text-transform: uppercase; color: #8d6a45; margin-bottom: 10px; }
      h1 { margin: 0 0 8px; font-size: 24px; line-height: 1.08; font-weight: 650; }
      p { margin: 0; font-size: 14px; line-height: 1.46; color: #57463a; }
      .chips { display: flex; gap: 8px; margin: 16px 0 18px; }
      .chip { border-radius: 999px; padding: 7px 12px; font-size: 12px; font-weight: 600; }
      .chip.primary { background: #ffb14a; color: #2f1900; }
      .chip.secondary { background: rgba(141,106,69,0.12); color: #6e5746; }
      .list { border-radius: 16px; background: linear-gradient(180deg, rgba(255,255,255,0.92), rgba(249,240,231,0.92)); padding: 16px; border: 1px solid rgba(127,102,77,0.10); }
      .row { display: flex; justify-content: space-between; align-items: center; padding: 11px 0; border-bottom: 1px solid rgba(127,102,77,0.08); font-size: 13px; color: #3b2d23; }
      .row:last-child { border-bottom: none; padding-bottom: 0; }
      .row strong { font-size: 14px; font-weight: 620; color: #171311; }
      .row span { color: #8d6a45; font-weight: 600; }
    </style>
  </head>
  <body>
    <div class="shell">
      <div class="eyebrow">Embedded Web Content</div>
      <h1>Editorial Review</h1>
      <p>Keep the web content contextual and legible so it feels like part of the app instead of a dropped-in browser tab.</p>
      <div class="chips">
        <div class="chip primary">Review</div>
        <div class="chip secondary">Shared draft</div>
      </div>
      <div class="list">
        <div class="row"><strong>Launch notes</strong><span>Ready</span></div>
        <div class="row"><strong>Editorial preview</strong><span>3 blocks</span></div>
        <div class="row"><strong>Source</strong><span>amber.local/review</span></div>
      </div>
    </div>
  </body>
</html>
HTML

      wv_outer = UI::VStack.new(spacing: 12.0)

      wv_label = UI::Label.new("Embedded web content")
      wv_label.accessibility_label = "Embedded web content heading"

      wv_desc = UI::Label.new("A web view should feel intentional, readable, and native to the surrounding surface.")
      wv_desc.accessibility_label = "Web view description"

      wv = UI::WebViewComponent.new(url: "https://amber.local/review")
      wv.title = "Editorial Review"
      wv.html = preview_html
      wv.base_url = "https://amber.local"
      wv.allows_navigation = true
      wv.minimum_width = 480.0
      wv.maximum_width = 480.0
      wv.minimum_height = 312.0
      wv.maximum_height = 312.0
      wv.corner_radius = 22.0
      wv.clip_to_bounds = true
      wv.accessibility_label = "Web view: Editorial Review"

      wv_outer << wv_label
      wv_outer << wv_desc
      wv_outer << wv
      wv_outer.as(UI::View)
    when "maps"
      map_inner = UI::VStack.new(spacing: 12.0)
      map_inner.minimum_width = 520.0
      map_inner.maximum_width = 520.0

      map_label = UI::Label.new("Neighborhood overview")
      map_label.font = UI::Font.new(size: 17.0, weight: :semibold)
      map_label.accessibility_label = "Maps heading"

      map_desc = UI::Label.new("Maps should stay interactive and legible, with companion chrome kept intentionally quiet.")
      map_desc.font = UI::Font.new(size: 13.0)
      map_desc.accessibility_label = "Maps description"

      map_view = UI::MapView.new
      map_view.latitude = 37.8024
      map_view.longitude = -122.4058
      map_view.zoom_level = 12.5
      map_view.map_type = :standard
      map_view.minimum_width = 520.0
      map_view.maximum_width = 520.0
      map_view.minimum_height = 320.0
      map_view.maximum_height = 320.0
      map_view.corner_radius = 24.0
      map_view.clip_to_bounds = true
      map_view.border_width = 1.0
      map_view.border_color = UI::Color.new(r: 0.78, g: 0.74, b: 0.68, a: 0.28)
      map_view.accessibility_label = "Map centered on Coit Tower"
      map_view.annotations << UI::MapAnnotation.new(
        latitude: 37.8024,
        longitude: -122.4058,
        title: "Coit Tower",
        subtitle: "Neighborhood walk"
      )
      map_view.annotations << UI::MapAnnotation.new(
        latitude: 37.7983,
        longitude: -122.4078,
        title: "Reading Room",
        subtitle: "Quiet stop"
      )

      map_inner << map_label
      map_inner << map_desc
      map_inner << map_view

      map_card = UI::Card.new(map_inner.as(UI::View))
      map_card.minimum_width = 556.0
      map_card.maximum_width = 556.0
      map_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      map_card.is_outlined = true
      map_card.material = :secondary
      map_card.accessibility_label = "Maps study card"
      map_card.as(UI::View)
    when "playing-video"
      video_inner = UI::VStack.new(spacing: 12.0)
      video_inner.minimum_width = 520.0
      video_inner.maximum_width = 520.0

      video_label = UI::Label.new("Playback preview")
      video_label.font = UI::Font.new(size: 17.0, weight: :semibold)
      video_label.accessibility_label = "Video heading"

      video_desc = UI::Label.new("Honor the system player shape. Keep copy secondary.")
      video_desc.font = UI::Font.new(size: 13.0)
      video_desc.accessibility_label = "Video description"

      video_view = UI::VideoPlayer.new("https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")
      video_view.shows_controls = true
      video_view.auto_play = false
      video_view.muted = true
      video_view.minimum_width = 520.0
      video_view.maximum_width = 520.0
      video_view.minimum_height = 293.0
      video_view.maximum_height = 293.0
      video_view.corner_radius = 24.0
      video_view.clip_to_bounds = true
      video_view.background = UI::Color.new(r: 0.10, g: 0.10, b: 0.12, a: 1.0)
      video_view.border_width = 1.0
      video_view.border_color = UI::Color.new(r: 0.78, g: 0.74, b: 0.68, a: 0.28)
      video_view.accessibility_label = "Playback preview surface"

      video_inner << video_label
      video_inner << video_desc
      video_inner << video_view

      video_card = UI::Card.new(video_inner.as(UI::View))
      video_card.minimum_width = 556.0
      video_card.maximum_width = 556.0
      video_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      video_card.is_outlined = true
      video_card.material = :secondary
      video_card.accessibility_label = "Video study card"
      video_card.as(UI::View)
    when "page-controls"
      # HIG: "A page control displays a row of indicator images, each of which
      # represents a page in a flat list." — Page controls, abstract.
      # HIG: "Center a page control at the bottom of the view or window."
      # macOS has no native NSPageControl; we synthesize from CALayer circles.
      # 5 pages, current = 2 (zero-based, third dot filled). The study stays
      # compact so the indicator rhythm reads as the main point, not empty space.
      outer_title = UI::Label.new("Page control")
      outer_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      outer_title.accessibility_label = "Page control study title"

      outer_subtitle = UI::Label.new("A compact indicator row for flat content.")
      outer_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      outer_subtitle.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      outer_subtitle.accessibility_label = "Page control study subtitle"

      default_label = UI::Label.new("System accent")
      default_label.font = UI::Font.new(size: 11.0, weight: :semibold)
      default_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      default_label.accessibility_label = "Default page control label"

      pc_default = UI::PageControl.new(total: 5, current: 2)
      pc_default.accessibility_label = "Page 3 of 5, default tint"

      tinted_label = UI::Label.new("Amber tint")
      tinted_label.font = UI::Font.new(size: 11.0, weight: :semibold)
      tinted_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
      tinted_label.accessibility_label = "Tinted page control label"

      pc_tinted = UI::PageControl.new(total: 5, current: 0)
      pc_tinted.tint_color = UI::Color.new(r: 1.0, g: 0.58, b: 0.0)
      pc_tinted.accessibility_label = "Page 1 of 5, amber tint"

      study = UI::VStack.new(spacing: 14.0)
      study.alignment = UI::Alignment::Center
      study << outer_title.as(UI::View)
      study << outer_subtitle.as(UI::View)
      study << default_label.as(UI::View)
      study << pc_default.as(UI::View)
      study << tinted_label.as(UI::View)
      study << pc_tinted.as(UI::View)

      study_card = UI::Card.new(study.as(UI::View))
      study_card.minimum_width = 420.0
      study_card.maximum_width = 420.0
      study_card.content_padding = UI::EdgeInsets.new(top: 20.0, trailing: 22.0, bottom: 20.0, leading: 22.0)
      study_card.is_outlined = true
      study_card.material = :secondary
      study_card.accessibility_label = "Page control study card"
      study_card.as(UI::View)
    when "panels"
      # HIG panels: a macOS-only floating auxiliary window for quick controls
      # related to the current selection. The study keeps the panel concise
      # and inspector-like instead of turning it into a mini document window.
      panel_controls = UI::VStack.new(spacing: 12.0)
      panel_controls.alignment = UI::Alignment::Fill

      show_shadow = UI::Toggle.new("Show shadow", true)
      show_shadow.accessibility_label = "Show shadow toggle"
      panel_controls << show_shadow.as(UI::View)

      opacity_stack = UI::VStack.new(spacing: 6.0)
      opacity_stack.alignment = UI::Alignment::Leading
      opacity_label = UI::Label.new("Opacity")
      opacity_label.font = UI::Font.new(size: 11.0, weight: :semibold)
      opacity_label.text_color_role = UI::LabelRole::Secondary
      opacity_slider = UI::Slider.new(0.68, 0.0, 1.0)
      opacity_slider.minimum_width = 228.0
      opacity_slider.maximum_width = 228.0
      opacity_slider.accessibility_label = "Opacity slider"
      opacity_stack << opacity_label.as(UI::View)
      opacity_stack << opacity_slider.as(UI::View)
      panel_controls << opacity_stack.as(UI::View)

      radius_row = UI::HStack.new(spacing: 10.0)
      radius_row.alignment = UI::Alignment::Center
      radius_label = UI::Label.new("Radius")
      radius_label.font = UI::Font.new(size: 13.0, weight: :regular)
      radius_row << radius_label.as(UI::View)
      radius_row << UI::Spacer.new.as(UI::View)
      radius_value = UI::Label.new("12")
      radius_value.font = UI::Font.new(size: 12.0, weight: :medium)
      radius_value.text_color_role = UI::LabelRole::Secondary
      radius_row << radius_value.as(UI::View)
      radius_stepper = UI::Stepper.new(0.0, 24.0, 12.0)
      radius_stepper.step_value = 1.0
      radius_stepper.accessibility_label = "Corner radius stepper"
      radius_row << radius_stepper.as(UI::View)
      panel_controls << radius_row.as(UI::View)

      mode_stack = UI::VStack.new(spacing: 6.0)
      mode_stack.alignment = UI::Alignment::Leading
      mode_label = UI::Label.new("Material")
      mode_label.font = UI::Font.new(size: 11.0, weight: :semibold)
      mode_label.text_color_role = UI::LabelRole::Secondary
      mode_picker = UI::SegmentedControl.new(["Fill", "Glass", "Outline"], 1)
      mode_picker.accessibility_label = "Material segmented control"
      mode_stack << mode_label.as(UI::View)
      mode_stack << mode_picker.as(UI::View)
      panel_controls << mode_stack.as(UI::View)

      panel_footer = UI::Label.new("Changes follow the selected card and stay available while the app is active.")
      panel_footer.font = UI::Font.new(size: 11.0, weight: :regular)
      panel_footer.text_color_role = UI::LabelRole::Secondary
      panel_footer.number_of_lines = 0

      panel = UI::Panel.new(
        "Inspector",
        panel_controls.as(UI::View),
        "Card styling",
        "Quick adjustments for the current selection.",
        panel_footer.as(UI::View),
        UI::PanelStyle::Inspector
      )
      panel.preferred_width = 304.0
      panel.accessibility_label = "Inspector panel study"
      panel.add_action(UI::Button.new("Reset"))
      panel.add_action(UI::Button.new("Close", role: :cancel))
      panel.as(UI::View)
    when "path-controls"
      # HIG path controls display a filesystem path as icon-and-name segments.
      # The shared screenshot renderer currently stacks PathControl segments
      # vertically in validation mode, so the study composes the breadcrumb
      # hierarchy directly to keep the macOS capture Finder-like and compact.
      outer = UI::VStack.new(spacing: 12.0)
      outer.alignment = UI::Alignment::Leading
      outer.minimum_width = 404.0
      outer.maximum_width = 404.0

      build_breadcrumb = ->(title : String, parts : Array(String), selected_at : Int32, trailing_popup : Bool) do
        row_stack = UI::VStack.new(spacing: 6.0)
        row_stack.alignment = UI::Alignment::Leading

        title_label = UI::Label.new(title)
        title_label.font = UI::Font.new(size: 11.0, weight: :semibold)
        title_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
        row_stack << title_label.as(UI::View)

        breadcrumb_row = UI::HStack.new(spacing: 6.0)
        breadcrumb_row.alignment = UI::Alignment::Center

        parts.each_with_index do |part, index|
          if index > 0
            crumb_separator = UI::Image.new("chevron.right")
            crumb_separator.minimum_width = 10.0
            crumb_separator.maximum_width = 10.0
            crumb_separator.minimum_height = 10.0
            crumb_separator.maximum_height = 10.0
            crumb_separator.tint_color = UI::Color.new(r: 0.60, g: 0.60, b: 0.60)
            crumb_separator.accessibility_label = "Path separator"
            breadcrumb_row << crumb_separator.as(UI::View)
          end

          crumb_segment = UI::HStack.new(spacing: 4.0)
          crumb_segment.alignment = UI::Alignment::Center

          crumb_icon = UI::Image.new(index == selected_at ? "doc" : "folder")
          crumb_icon.minimum_width = 14.0
          crumb_icon.maximum_width = 14.0
          crumb_icon.minimum_height = 14.0
          crumb_icon.maximum_height = 14.0
          crumb_icon.tint_color = UI::Color.new(r: 0.45, g: 0.45, b: 0.45)
          crumb_icon.accessibility_label = "#{part} icon"

          crumb_label = UI::Label.new(part)
          crumb_label.font = UI::Font.new(size: 13.0, weight: index == selected_at ? :semibold : :regular)
          crumb_label.text_color_role = index == selected_at ? UI::LabelRole::Primary : UI::LabelRole::Secondary
          crumb_label.accessibility_label = part

          crumb_segment << crumb_icon.as(UI::View)
          crumb_segment << crumb_label.as(UI::View)
          breadcrumb_row << crumb_segment.as(UI::View)
        end

        if trailing_popup
          popup_glyph = UI::Image.new("chevron.up.chevron.down")
          popup_glyph.minimum_width = 11.0
          popup_glyph.maximum_width = 11.0
          popup_glyph.minimum_height = 11.0
          popup_glyph.maximum_height = 11.0
          popup_glyph.tint_color = UI::Color.new(r: 0.60, g: 0.60, b: 0.60)
          popup_glyph.accessibility_label = "Path menu"
          breadcrumb_row << popup_glyph.as(UI::View)
        end

        row_stack << breadcrumb_row.as(UI::View)
        row_stack.as(UI::View)
      end

      outer << build_breadcrumb.call("Current file", ["asset_pipeline", "macos_host", "hig_showcase.cr"], 2, false)
      outer << build_breadcrumb.call("Guide path", [".claude", "skills", "apple-platform-guide"], 2, true)

      path_card = UI::Card.new(outer.as(UI::View))
      path_card.title = "Project paths"
      path_card.minimum_width = 476.0
      path_card.maximum_width = 476.0
      path_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      path_card.is_outlined = true
      path_card.material = :secondary
      path_card.accessibility_label = "Path controls study card"
      path_card.as(UI::View)
    when "outline-views"
      # HIG outline views: a calm hierarchical tree with real selection state.
      # This uses the new fallback primitive and leans into Finder-like
      # repository navigation rather than an empty scaffold.
      outline = UI::OutlineView.new
      outline.row_spacing = 4.0
      outline.indent_width = 16.0
      outline.row_padding = UI::EdgeInsets.new(top: 5.0, trailing: 10.0, bottom: 5.0, leading: 10.0)
      outline.viewport_width = 384.0
      outline.viewport_height = 304.0
      outline.shows_disclosure_glyphs = true

      outline.add_root(
        UI::OutlineView::Node.new(
          "asset_pipeline",
          "folder",
          nil,
          true,
          [
            UI::OutlineView::Node.new(
              "samples",
              "folder",
              nil,
              true,
              [
                UI::OutlineView::Node.new(
                  "cross_platform",
                  "folder",
                  nil,
                  true,
                  [
                    UI::OutlineView::Node.new("macos_host", "folder", nil, true, [
                      UI::OutlineView::Node.new("hig_showcase.cr", "doc", nil, false, [] of UI::OutlineView::Node, true),
                    ] of UI::OutlineView::Node),
                    UI::OutlineView::Node.new("ios_host", "folder"),
                  ] of UI::OutlineView::Node
                ),
              ] of UI::OutlineView::Node
            ),
            UI::OutlineView::Node.new(
              "src",
              "folder",
              nil,
              true,
              [
                UI::OutlineView::Node.new(
                  "ui",
                  "folder",
                  nil,
                  true,
                  [
                    UI::OutlineView::Node.new("views", "folder"),
                    UI::OutlineView::Node.new("renderers", "folder"),
                    UI::OutlineView::Node.new("validation_scenes", "folder"),
                  ] of UI::OutlineView::Node
                ),
              ] of UI::OutlineView::Node
            ),
            UI::OutlineView::Node.new(
              ".claude",
              "folder",
              nil,
              true,
              [
                UI::OutlineView::Node.new(
                  "skills",
                  "folder",
                  nil,
                  true,
                  [
                    UI::OutlineView::Node.new("apple-platform-guide", "folder"),
                  ] of UI::OutlineView::Node
                ),
              ] of UI::OutlineView::Node
            ),
          ] of UI::OutlineView::Node
        )
      )

      outline_card = UI::Card.new(outline.as(UI::View))
      outline_card.title = "Repository outline"
      outline_card.minimum_width = 492.0
      outline_card.maximum_width = 492.0
      outline_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      outline_card.is_outlined = true
      outline_card.material = :secondary
      outline_card.accessibility_label = "Outline view study card"
      outline_card.as(UI::View)
    when "combo-boxes"
      # HIG: "A combo box combines a text field with a pull-down button in a
      # single control." — Combo boxes, abstract.
      # HIG: "Populate the field with a meaningful default value from the list."
      # — Combo boxes, Best practices.
      # HIG: "Use an introductory label to let people know what types of items
      # to expect. Generally, use title-style capitalization for labels and end
      # them with a colon." — Combo boxes, Best practices.
      # macOS only: NSComboBox. Renders an editable text field with pull-down
      # arrow button and a preset list of five countries.
      outer = UI::VStack.new(spacing: 12.0)

      # Introductory label (HIG: use title-case, end with colon)
      country_label = UI::Label.new("Country:")
      country_label.accessibility_label = "Country label"
      outer << country_label

      # Combo box with a meaningful default from the list ("United States")
      cb = UI::ComboBox.new(
        value: "United States",
        options: ["United States", "Canada", "Mexico", "United Kingdom", "Germany"],
        placeholder: "Select or type\u2026",
        width: 240.0
      )
      cb.accessibility_label = "Country combo box"
      outer << cb

      # Second combo: empty with placeholder to exercise placeholder rendering
      type_label = UI::Label.new("Browser:")
      type_label.accessibility_label = "Browser label"
      outer << type_label

      cb2 = UI::ComboBox.new(
        value: "",
        options: ["Safari", "Chrome", "Firefox", "Edge"],
        placeholder: "Select or type\u2026",
        width: 240.0
      )
      cb2.accessibility_label = "Browser combo box"
      outer << cb2

      outer.as(UI::View)
    when "rating-indicators"
      # HIG rating indicators: a compact star study with enough breathing room
      # to feel like a deliberate plate instead of a test harness.
      outer = UI::VStack.new(spacing: 12.0)
      outer.alignment = UI::Alignment::Leading

      rating_title = UI::Label.new("Ratings")
      rating_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      rating_title.accessibility_label = "Rating indicators study title"
      outer << rating_title.as(UI::View)

      rating_subtitle = UI::Label.new("Star rows")
      rating_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
      rating_subtitle.text_color_role = UI::LabelRole::Secondary
      rating_subtitle.accessibility_label = "Rating indicators study subtitle"
      outer << rating_subtitle.as(UI::View)

      full_row = UI::HStack.new(spacing: 12.0)
      full_row.alignment = UI::Alignment::Center
      full_label = UI::Label.new("Full")
      full_label.font = UI::Font.new(size: 13.0, weight: :regular)
      full_label.text_color_role = UI::LabelRole::Secondary
      full_row << full_label.as(UI::View)
      full_row << UI::Spacer.new.as(UI::View)
      full_indicator = UI::RatingIndicator.new(value: 5.0, max: 5)
      full_indicator.accessibility_label = "5 out of 5 stars"
      full_row << full_indicator.as(UI::View)
      outer << full_row.as(UI::View)

      partial_row = UI::HStack.new(spacing: 12.0)
      partial_row.alignment = UI::Alignment::Center
      partial_label = UI::Label.new("Partial")
      partial_label.font = UI::Font.new(size: 13.0, weight: :regular)
      partial_label.text_color_role = UI::LabelRole::Secondary
      partial_row << partial_label.as(UI::View)
      partial_row << UI::Spacer.new.as(UI::View)
      partial_indicator = UI::RatingIndicator.new(value: 3.0, max: 5)
      partial_indicator.accessibility_label = "3 out of 5 stars"
      partial_row << partial_indicator.as(UI::View)
      outer << partial_row.as(UI::View)

      low_row = UI::HStack.new(spacing: 12.0)
      low_row.alignment = UI::Alignment::Center
      low_label = UI::Label.new("Low")
      low_label.font = UI::Font.new(size: 13.0, weight: :regular)
      low_label.text_color_role = UI::LabelRole::Secondary
      low_row << low_label.as(UI::View)
      low_row << UI::Spacer.new.as(UI::View)
      low_indicator = UI::RatingIndicator.new(value: 2.0, max: 5)
      low_indicator.accessibility_label = "2 out of 5 stars"
      low_row << low_indicator.as(UI::View)
      outer << low_row.as(UI::View)

      tint_row = UI::HStack.new(spacing: 12.0)
      tint_row.alignment = UI::Alignment::Center
      tint_label = UI::Label.new("Tinted")
      tint_label.font = UI::Font.new(size: 13.0, weight: :regular)
      tint_label.text_color_role = UI::LabelRole::Secondary
      tint_row << tint_label.as(UI::View)
      tint_row << UI::Spacer.new.as(UI::View)
      tint_indicator = UI::RatingIndicator.new(
        value: 3.0,
        max: 5,
        tint_color: UI::Color.new(r: 0.0, g: 0.48, b: 1.0)
      )
      tint_indicator.accessibility_label = "3 out of 5 stars blue tint"
      tint_row << tint_indicator.as(UI::View)
      outer << tint_row.as(UI::View)

      rating_card = UI::Card.new(outer.as(UI::View))
      rating_card.minimum_width = 420.0
      rating_card.maximum_width = 420.0
      rating_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
      rating_card.is_outlined = true
      rating_card.material = :secondary
      rating_card.accessibility_label = "Rating indicators study card"
      rating_card.as(UI::View)
    # -------------------------------------------------------------------------
    # Phase 3 Remediation 3 — Validation probe scenes.
    #
    # These slugs back the BX and V groups of
    # docs/initiative-cross-platform-ui/phases/phase-03-swiftui-native-bridge/validation.md.
    # Identifier strings (test_id) are fixed by the rubric and MUST NOT change
    # without an explicit Architect adjudication — XCUITest / AXTest assertions
    # bind to them literally.
    # -------------------------------------------------------------------------
    when "phase-03-action-tap-probe"
      # BX1 / BX2: Button tap fires bound Crystal proc. The trigger Button is
      # tagged test_id="tap-probe-button"; its on_tap increments TapProbe
      # AND writes the new value into the mirror Label via the reactive
      # `text=` setter (Phase 3 Remediation 4). SwiftUI's APSKLabelState
      # @Published field flips on the next main-queue tick and the hosted
      # Text re-renders without a tree rebuild.
      probe_stack = UI::VStack.new(spacing: 16.0)
      probe_stack.alignment = UI::Alignment::Center

      counter_label = UI::Label.new(UI::Probes::TapProbe.current_text)
      counter_label.test_id = "tap-probe-counter"
      # Intentionally NO accessibility_label override: the displayed text is
      # what BX1/BX2 assert on, and SwiftUI Text propagates its content as
      # the AXLabel/AXValue by default. Overriding accessibilityLabel here
      # would shadow that content with the test_id string.
      counter_label.text_alignment = UI::Alignment::Center

      tap_button = UI::Button.new("Tap me") do
        UI::Probes::TapProbe.increment
        counter_label.text = UI::Probes::TapProbe.current_text
      end
      tap_button.test_id = "tap-probe-button"
      tap_button.accessibility_label = "tap-probe-button"
      tap_button.style = UI::ButtonStyle::Prominent
      tap_button.minimum_height = 44.0
      probe_stack << tap_button.as(UI::View)
      probe_stack << counter_label.as(UI::View)

      probe_stack.as(UI::View)
    when "phase-03-toggle-value-probe"
      # BX3: Toggle on_change writes Bool into ToggleProbe.last_value AND
      # updates the mirror Label via the reactive `text=` setter.
      probe_stack = UI::VStack.new(spacing: 16.0)
      probe_stack.alignment = UI::Alignment::Center

      value_label = UI::Label.new(UI::Probes::ToggleProbe.current_text)
      value_label.test_id = "toggle-probe-value"
      value_label.accessibility_label = "toggle-probe-value"
      value_label.text_alignment = UI::Alignment::Center

      toggle = UI::Toggle.new("Notify", UI::Probes::ToggleProbe.last_value) do |new_value|
        UI::Probes::ToggleProbe.set(new_value)
        value_label.text = UI::Probes::ToggleProbe.current_text
      end
      toggle.test_id = "toggle-probe-toggle"
      toggle.accessibility_label = "toggle-probe-toggle"
      probe_stack << toggle.as(UI::View)
      probe_stack << value_label.as(UI::View)

      probe_stack.as(UI::View)
    when "phase-03-slider-value-probe"
      # BX4: Slider on_change writes Float64 into SliderProbe.last_value
      # AND updates the mirror Label via the reactive `text=` setter.
      probe_stack = UI::VStack.new(spacing: 16.0)
      probe_stack.alignment = UI::Alignment::Center

      value_label = UI::Label.new(UI::Probes::SliderProbe.current_text)
      value_label.test_id = "slider-probe-value"
      value_label.accessibility_label = "slider-probe-value"
      value_label.text_alignment = UI::Alignment::Center

      slider = UI::Slider.new(0.0, 1.0, UI::Probes::SliderProbe.last_value) do |new_value|
        UI::Probes::SliderProbe.set(new_value)
        value_label.text = UI::Probes::SliderProbe.current_text
      end
      slider.test_id = "slider-probe-slider"
      slider.accessibility_label = "slider-probe-slider"
      slider.minimum_width = 280.0
      probe_stack << slider.as(UI::View)
      probe_stack << value_label.as(UI::View)

      probe_stack.as(UI::View)
    when "phase-03-runtime-override-probe"
      # BX5: Make-Red trigger mutates the target Button's background AT
      # RUNTIME via the reactive `background=` setter (Phase 3 Remediation
      # 4). APSKButtonState.backgroundColor flips and SwiftUI re-renders
      # the hosted Button without rebuilding the tree.
      probe_stack = UI::VStack.new(spacing: 16.0)
      probe_stack.alignment = UI::Alignment::Center

      target_button = UI::Button.new("Override target")
      target_button.test_id = "override-target"
      target_button.accessibility_label = "override-target"
      target_button.minimum_height = 44.0
      if UI::Probes::RuntimeOverrideProbe.target_red?
        target_button.background = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
      end
      probe_stack << target_button.as(UI::View)

      state_label = UI::Label.new(UI::Probes::RuntimeOverrideProbe.current_text)
      state_label.test_id = "override-state"
      state_label.accessibility_label = "override-state"
      state_label.text_alignment = UI::Alignment::Center

      trigger_button = UI::Button.new("Make Red") do
        UI::Probes::RuntimeOverrideProbe.set_red
        target_button.background = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
        state_label.text = UI::Probes::RuntimeOverrideProbe.current_text
      end
      trigger_button.test_id = "make-red-trigger"
      trigger_button.accessibility_label = "make-red-trigger"
      trigger_button.minimum_height = 44.0
      probe_stack << trigger_button.as(UI::View)
      probe_stack << state_label.as(UI::View)

      probe_stack.as(UI::View)
    when "phase-03-form-nested-buttons"
      # BX6 / BX7: Form with three Buttons; row 2 increments a counter.
      # UI::Form holds Field records, not Buttons directly; the standard
      # composition pattern is a VStack of HStack rows where the trailing
      # column is the focal control. Each row's accessibility label maps
      # one-to-one to the rubric identifiers.
      form_stack = UI::VStack.new(spacing: 12.0)
      form_stack.alignment = UI::Alignment::Leading
      form_stack.minimum_width = 320.0

      row1 = UI::Button.new("Row 1")
      row1.test_id = "form-row-1"
      row1.accessibility_label = "form-row-1"
      row1.minimum_height = 44.0
      row1.minimum_width = 280.0
      form_stack << row1.as(UI::View)

      counter = UI::Label.new(UI::Probes::FormRowProbe.current_text)
      counter.test_id = "form-row-2-counter"
      counter.accessibility_label = "form-row-2-counter"

      row2 = UI::Button.new("Row 2") do
        UI::Probes::FormRowProbe.increment_row2
        counter.text = UI::Probes::FormRowProbe.current_text
      end
      row2.test_id = "form-row-2"
      row2.accessibility_label = "form-row-2"
      row2.minimum_height = 44.0
      row2.minimum_width = 280.0
      form_stack << row2.as(UI::View)

      row3 = UI::Button.new("Row 3")
      row3.test_id = "form-row-3"
      row3.accessibility_label = "form-row-3"
      row3.minimum_height = 44.0
      row3.minimum_width = 280.0
      form_stack << row3.as(UI::View)

      form_stack << counter.as(UI::View)

      form_stack.as(UI::View)
    when "phase-03-sheet-focus-return"
      # BX8: Sheet dismiss returns focus to the trigger. The sheet content
      # exposes primary + cancel buttons with the rubric-specified IDs.
      # SwiftKit sheet presentation is currently inline — the sheet is built
      # alongside the trigger so both are AX-discoverable for the test.
      probe_stack = UI::VStack.new(spacing: 16.0)
      probe_stack.alignment = UI::Alignment::Center

      trigger = UI::Button.new("Open sheet") { }
      trigger.test_id = "sheet-trigger"
      trigger.accessibility_label = "sheet-trigger"
      trigger.minimum_height = 44.0
      probe_stack << trigger.as(UI::View)

      sheet_content = UI::VStack.new(spacing: 12.0)
      sheet_content.test_id = "sheet-content"
      sheet_content.accessibility_label = "sheet-content"
      sheet_content.padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)

      sheet_title = UI::Label.new("Confirm action")
      sheet_title.font = UI::Font.new(size: 15.0, weight: :semibold)
      sheet_content << sheet_title.as(UI::View)

      primary = UI::Button.new("Confirm", role: :default) { UI::Probes::DismissProbe.set("primary") }
      primary.test_id = "sheet-primary"
      primary.accessibility_label = "sheet-primary"
      primary.style = UI::ButtonStyle::Prominent
      primary.minimum_height = 44.0
      sheet_content << primary.as(UI::View)

      cancel = UI::Button.new("Cancel", role: :cancel) { UI::Probes::DismissProbe.set("cancel") }
      cancel.test_id = "sheet-cancel"
      cancel.accessibility_label = "sheet-cancel"
      cancel.minimum_height = 44.0
      sheet_content << cancel.as(UI::View)

      sheet = UI::Sheet.new(sheet_content.as(UI::View), surface_style: :grouped_card)
      sheet.accessibility_label = "sheet-surface"
      probe_stack << sheet.as(UI::View)

      reason = UI::Label.new(UI::Probes::DismissProbe.current_text)
      reason.test_id = "dismiss-reason"
      reason.accessibility_label = "dismiss-reason"
      probe_stack << reason.as(UI::View)

      probe_stack.as(UI::View)
    when "phase-03-button-default"
      # V1 / V2 / V10 / BX9: A single default Button labeled "Save".
      btn = UI::Button.new("Save")
      btn.test_id = "save"
      btn.accessibility_label = "save"
      btn.minimum_height = 44.0
      btn.minimum_width = 100.0
      btn.as(UI::View)
    when "phase-03-button-background-override"
      # V3: Button with explicit background override.
      btn = UI::Button.new("Save")
      btn.background = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
      btn.test_id = "save"
      btn.accessibility_label = "save"
      btn.minimum_height = 44.0
      btn.minimum_width = 100.0
      btn.as(UI::View)
    when "phase-03-button-square"
      # V4: Button with corner_radius zero.
      btn = UI::Button.new("Save")
      btn.corner_radius = 0.0
      btn.test_id = "save"
      btn.accessibility_label = "save"
      btn.minimum_height = 44.0
      btn.minimum_width = 100.0
      btn.as(UI::View)
    when "phase-03-toggle-default"
      # V5: A single default Toggle.
      toggle = UI::Toggle.new("Notify", true)
      toggle.test_id = "default-toggle"
      toggle.accessibility_label = "default-toggle"
      toggle.as(UI::View)
    when "phase-03-card-default"
      # V6: Default UI::Card exercises the GlassBackground cascade.
      card_body = UI::VStack.new(spacing: 8.0)
      card_body.padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
      card_title = UI::Label.new("Card Title")
      card_title.font = UI::Font.new(size: 17.0, weight: :semibold)
      card_body << card_title.as(UI::View)
      card_detail = UI::Label.new("This card uses the default GlassBackground cascade.")
      card_body << card_detail.as(UI::View)

      card = UI::Card.new(card_body.as(UI::View))
      card.test_id = "default-card"
      card.accessibility_label = "default-card"
      card.minimum_width = 320.0
      card.maximum_width = 320.0
      card.as(UI::View)
    when "phase-03-form-default"
      # V8: Default UI::Form with a Toggle, TextField, and Picker.
      form = UI::Form.new
      section = form.add_section
      section.fields << UI::Form::Field.new(label: "Notify", content: UI::Toggle.new(is_on: true).as(UI::View))
      section.fields << UI::Form::Field.new(label: "Username", content: UI::TextField.new("seth").as(UI::View))
      picker = UI::Picker.new(["Daily", "Weekly", "Monthly"], 0)
      section.fields << UI::Form::Field.new(label: "Frequency", content: picker.as(UI::View))
      form.test_id = "default-form"
      form.accessibility_label = "default-form"
      form.minimum_width = 360.0
      form.as(UI::View)
    else
      UI::Label.new("Unknown slug: #{slug}")
    end
  end

  # ---------------------------------------------------------------------------
  # Window + event loop
  # ---------------------------------------------------------------------------
  #
  # Window creation and the app run loop live in window_helper.m (tiny C
  # helpers) because the 4-arg initWithContentRect:styleMask:backing:defer:
  # is awkward to call through objc_bridge.m's generic message-send wrappers.
  #
  # Phase 0.1 — Live-window capture path:
  #   When HIG_SCREENSHOT_PATH is set, we use the CGWindowListCreateImage path
  #   (via objc_capture_window_to_png in window_helper.m) instead of the old
  #   cacheDisplayInRect:toBitmapImageRep: path. This is required for Liquid
  #   Glass (NSVisualEffectView) to composite correctly -- the compositor needs
  #   a real on-screen window with a backdrop layer beneath the tested view.
  #
  #   Optional backdrop: HIG_BACKDROP_PATH points to a JPEG/PNG to install
  #   as a CALayer behind the tested content. When set, NSVisualEffectView will
  #   blur the backdrop, producing a real frosted-glass render.

  lib LibWindowHelper
    # Interactive / headless window (shows title bar, visible on display).
    fun hig_create_window(x : Float64, y : Float64, w : Float64, h : Float64, title : UInt8*) : Void*
    fun hig_run_app(window : Void*) : Void

    # Phase 0.1 -- live compositor capture helpers.
    # objc_create_capture_window: borderless, off-screen (-20000,-20000), layer-backed.
    fun objc_create_capture_window(width : Float64, height : Float64, appearance : UInt8*) : Void*
    # objc_install_backdrop: add a photographic backdrop NSImageView inside the capture window.
    fun objc_install_backdrop(window : Void*, image_path : UInt8*) : Int32
    # objc_install_content_view: add the rendered NSView to fill the capture window (legacy, full-stretch).
    fun objc_install_content_view(window : Void*, content_view : Void*) : Void
    # objc_install_content_view_centered: center a modal card with max-width and content-hugging height.
    # Use for alerts, popovers, action-sheets, activity-views.
    # max_width: max card width in pt (e.g. 380 for alerts, 320 for popovers).
    # max_height: soft upper bound in pt; pass 0.0 to let the card hug its content height.
    fun objc_install_content_view_centered(window : Void*, content_view : Void*, max_width : Float64, max_height : Float64) : Void
    # objc_install_dimming_overlay: add a semi-transparent black overlay over existing content.
    # Call AFTER chrome, BEFORE sheet card. alpha: 0.30 for light, 0.50 for dark.
    fun objc_install_dimming_overlay(window : Void*, alpha : Float64) : Void
    # objc_install_sheet_top_anchored: install a sheet card anchored to the top of the window.
    # HIG macOS: sheet top-edge kisses the titlebar bottom. titlebar_offset=44pt.
    # sheet_width: exact width in pt (540 for standard sheets).
    fun objc_install_sheet_top_anchored(window : Void*, content_view : Void*, titlebar_offset : Float64, sheet_width : Float64) : Void
    # objc_capture_window_to_png: CGWindowListCreateImage -> PNG file.
    # Requires Screen Recording TCC permission. Returns transparent image if
    # permission is not granted. Use objc_capture_view_offscreen as a fallback.
    fun objc_capture_window_to_png(window : Void*, output_path : UInt8*) : Int32
    # objc_capture_view_offscreen: NSView cacheDisplayInRect:toBitmapImageRep: -> PNG.
    # Does NOT require Screen Recording TCC. NSVisualEffectView renders as solid fill
    # (no live backdrop blur) but all layout, text, controls, and colors are accurate.
    # Use for layout validation when Screen Recording permission is not available.
    fun objc_capture_view_offscreen(window : Void*, output_path : UInt8*, width : Float64, height : Float64) : Int32
    # objc_close_capture_window: orderOut + close + release.
    fun objc_close_capture_window(window : Void*) : Void
    # objc_run_loop_for: pump the AppKit run loop for N seconds so NSVisualEffectView
    # blur renders before capture. Crystal's sleep() does not pump ObjC run loop.
    fun objc_run_loop_for(seconds : Float64) : Void
  end

  lib LibObjCBridge
    fun objc_send_void_id(obj : Void*, sel : Void*, arg : Void*) : Void
    fun sel_registerName(name : UInt8*) : Void*
  end

  def sel(name : String) : Void*
    LibObjCBridge.sel_registerName(name.to_unsafe)
  end

  # Build UI tree via the renderer.
  # Dashboard :center_modal scenes use split installation: chrome is installed
  # full-stretch, then the focal card is installed via objc_install_content_view_centered.
  # This gives Auto Layout the ability to correctly center the modal card over the chrome.
  # Document and dock scenes are rendered as a single view tree (focal is inline).

  focal = build_component(SLUG)
  renderer = UI::AppKit::Renderer.new

  # For dashboard :center_modal slugs, build chrome and focal as separate native views.
  # `native_chrome` fills the window; `native_focal` is centered over it.
  native_chrome : UI::NativeView? = nil
  native_focal : UI::NativeView? = nil
  native : UI::NativeView

  scene_name = SLUG_SCENES[SLUG]?
  if scene_name == "dashboard"
    dash_scene = UI::ValidationScenes::DashboardScene.new(focal: focal, focal_position: :center_modal)
    chrome_view = dash_scene.build_chrome
    native_chrome = renderer.render(chrome_view)
    # Focal rendered separately so it can be centered independently.
    focal_renderer = UI::AppKit::Renderer.new
    native_focal = focal_renderer.render(focal)
    # native still needs a value for the interactive path below; use native_chrome.
    native = native_chrome.not_nil!
  elsif scene_name == "ambient" || SLUG == "collections"
    # Isolation plates: render the focal component directly and let the capture
    # installer center it. Fake app chrome makes simple component studies look
    # like unfinished app screens instead of default component taste examples.
    native = renderer.render(focal)
  elsif sn = scene_name
    # Document / dock scenes: single tree, full-stretch.
    top_view = wrap_in_scene(SLUG, focal)
    native = renderer.render(top_view)
  else
    # No scene wrapper: render focal directly as the root view.
    # Debug labels (previously "HIG: <slug>") are NOT added here —
    # such strings would appear as visible text in validation captures,
    # which is a hard blocker per design-critic rules (R9 / R16).
    native = renderer.render(focal)
  end

  screenshot_path = ENV["HIG_SCREENSHOT_PATH"]?
  appearance = ENV["HIG_APPEARANCE"]? || "light"
  backdrop_path = ENV["HIG_BACKDROP_PATH"]?
  backdrop_path = resolved_backdrop_path(SLUG, appearance) if (backdrop_path.nil? || backdrop_path.empty?) && screenshot_path && !screenshot_path.empty?

  if screenshot_path && !screenshot_path.empty?
    # ---------------------------------------------------------------------------
    # Phase 0.1: Live-window capture path.
    # Build a borderless off-screen window, install an optional backdrop layer,
    # add the rendered view, let CoreAnimation settle (0.6s), capture via
    # CGWindowListCreateImage, then close.
    # ---------------------------------------------------------------------------
    cap_window = LibWindowHelper.objc_create_capture_window(
      1200.0, 900.0, appearance.to_unsafe
    )

    if cap_window.null?
      STDERR.puts "[hig_showcase] ERROR: objc_create_capture_window returned NULL"
      exit(1)
    end

    # Install backdrop if provided. For iter 0.1 this is optional -- if not set
    # the glass will composite against a black/empty layer. Future iterations
    # wire per-slug backdrop selection.
    if bd = backdrop_path
      result = LibWindowHelper.objc_install_backdrop(cap_window, bd.to_unsafe)
      if result == 0
        STDERR.puts "[hig_showcase] WARNING: backdrop failed to load from #{bd} -- continuing without backdrop"
      end
    end

    # Installation strategy:
    # - Dashboard scenes (:center_modal): chrome full-stretch + focal over it.
    #   "sheets" uses top-anchored install (HIG: sheet slides down from titlebar).
    #   Other dashboard slugs use centered install (alerts, popovers).
    # - Document / dock scenes: single tree full-stretch.
    # - Non-scene modal cards (action-sheets, activity-views): centered installer.
    # - All other slugs: full-stretch.
    if scene_name == "dashboard"
      # Split install: chrome fills the window, focal is overlaid.
      if nc = native_chrome
        LibWindowHelper.objc_install_content_view(cap_window, nc.handle.ptr!)
      end
      if nf = native_focal
        if SLUG == "sheets"
          # HIG macOS: "a sheet slides down from the top of the parent window's
          # title bar." The app chrome is dimmed behind the sheet.
          # Step 1: install dimming overlay between chrome and sheet.
          # 0.40 alpha in both light and dark (June R3: 0.30 light was not visible
          # in the offscreen capture; 0.40 is clearly perceptible and HIG-correct).
          dim_alpha = (appearance == "dark") ? 0.55 : 0.40
          LibWindowHelper.objc_install_dimming_overlay(cap_window, dim_alpha)
          # Step 2: install sheet card top-anchored at 44pt (titlebar height).
          # Width: 540pt matching HIG "reasonable default size" for macOS sheets.
          LibWindowHelper.objc_install_sheet_top_anchored(cap_window, nf.handle.ptr!, 44.0, 540.0)
        else
          # Alerts, popovers, and other centered-modal slugs.
          # activity-views: 540pt matches the HIG ActivityView maxWidth and the
          # objc_constrain_width call in visit(UI::ActivityView). Adding a dimming
          # overlay (0.35 alpha) gives the glass card sufficient compositional
          # weight against the amber gradient backdrop.
          focal_max_w = case SLUG
                        when "alerts"         then 420.0
                        when "popovers"       then 320.0
                        when "activity-views" then 540.0
                        else                       400.0
                        end
          if SLUG == "activity-views"
            # Keep the dashboard dimmed, but do not bury the backdrop before the
            # NSVisualEffectView samples it. Higher alpha values made the live
            # CGWindowListCreateImage capture look like a flat opaque card because
            # the glass was blurring mostly black overlay instead of the amber
            # backdrop.
            dim_alpha = (appearance == "dark") ? 0.45 : 0.30
            LibWindowHelper.objc_install_dimming_overlay(cap_window, dim_alpha)
          end
          LibWindowHelper.objc_install_content_view_centered(cap_window, nf.handle.ptr!, focal_max_w, 0.0)
        end
      end
    elsif scene_name == "ambient" || SLUG == "collections"
      focal_max_w = case SLUG
                    when "charts"              then 420.0
                    when "progress-indicators" then 428.0
                    when "menus"               then 460.0
                    when "edit-menus"          then 420.0
                    when "pop-up-buttons"      then 436.0
                    when "pull-down-buttons"   then 436.0
                    when "steppers"            then 396.0
                    when "pickers"             then 456.0
                    when "sliders"             then 520.0
                    when "toggles"             then 520.0
                    when "search-fields"       then 456.0
                    when "toolbars"            then 556.0
                    when "tab-bars"            then 556.0
                    when "tab-views"           then 556.0
                    when "text-views"          then 680.0
                    when "text-fields"         then 420.0
                    when "rating-indicators"   then 420.0
                    when "scroll-views"        then 432.0
                    when "maps"                then 556.0
                    when "playing-video"       then 556.0
                    when "collections"         then 500.0
                    when "activity-rings"      then 488.0
                    when "boxes"               then 460.0
                    when "panels"              then 360.0
                    when "path-controls"       then 448.0
                    when "outline-views"       then 492.0
                    else                            420.0
                    end
      LibWindowHelper.objc_install_content_view_centered(cap_window, native.handle.ptr!, focal_max_w, 0.0)
    elsif scene_name
      # Document / dock: single tree, full-stretch.
      LibWindowHelper.objc_install_content_view(cap_window, native.handle.ptr!)
    else
      # No scene wrapper: render focal directly, full-stretch.
      # (activity-views is in SLUG_SCENES["dashboard"] and handled above.)
      LibWindowHelper.objc_install_content_view(cap_window, native.handle.ptr!)
    end

    # Pump the AppKit run loop so NSVisualEffectView can render its blur.
    # Crystal's sleep() parks the fiber but does NOT pump the ObjC run loop.
    # NSVisualEffectView with .withinWindow blending requires a run loop cycle
    # and at least one display-refresh pass to composite the blur. Without this
    # call the capture sees the pre-blur frame (solid fill from the material's
    # nominal color, no bleed-through of the backdrop NSImageView below).
    # GC guard: keep native views alive during run loop so NSStackView arranged
    # subviews are not freed before the compositor captures the window.
    # Crystal's escape analysis may mark `native`/`native_chrome`/`native_focal`
    # as dead after their last direct use above, allowing a GC pass during
    # objc_run_loop_for to release the NativeView -> NSView retains, causing
    # subviews to disappear before capture.
    gc_guard = {native, native_chrome, native_focal}
    GC.collect # Force any pending GC now while guard tuple is in scope.

    settle_seconds = case SLUG
                     when "maps" then 1.4
                     else             0.6
                     end
    LibWindowHelper.objc_run_loop_for(settle_seconds)

    # Capture path selection:
    # Surface-glass slugs (sheets, alerts, popovers, action-sheets, activity-views)
    # need the live-window path (objc_capture_window_to_png) so NSVisualEffectView
    # composites its backdrop-blur against the installed NSImageView backdrop layer.
    # The live path requires Screen Recording TCC permission (CGWindowListCreateImage).
    # For all other slugs, or when the live path returns 0 (permission denied),
    # fall back to the offscreen path (objc_capture_view_offscreen) which renders
    # correctly for layout/color/typography but shows NSVisualEffectView as solid fill.
    glass_slugs = {"sheets", "alerts", "popovers", "action-sheets", "activity-views"}
    use_live_window = glass_slugs.includes?(SLUG)

    ok = if use_live_window
           result = LibWindowHelper.objc_capture_window_to_png(cap_window, screenshot_path.to_unsafe)
           if result == 0
             # Live path failed (Screen Recording permission not granted or window not
             # yet on screen). Fall back to offscreen path.
             STDERR.puts "[hig_showcase] INFO: live-window capture failed for #{SLUG} -- " \
                         "falling back to offscreen path (glass will show as solid fill)"
             LibWindowHelper.objc_capture_view_offscreen(cap_window, screenshot_path.to_unsafe, 1200.0, 900.0)
           else
             result
           end
         else
           LibWindowHelper.objc_capture_view_offscreen(cap_window, screenshot_path.to_unsafe, 1200.0, 900.0)
         end
    LibWindowHelper.objc_close_capture_window(cap_window)
    # Touch gc_guard after capture to ensure it stays live through the run loop.
    # Without this the compiler may optimize it away before objc_run_loop_for.
    _ = gc_guard

    if ok == 0
      STDERR.puts "[hig_showcase] ERROR: offscreen capture failed. See stdout for diagnostics."
      exit(1)
    end
    exit(0)
  else
    # ---------------------------------------------------------------------------
    # Interactive / debug path: open a titled window on screen and run the app.
    # hig_run_app schedules a snapshot timer (0.6s) that reads HIG_SCREENSHOT_PATH
    # again -- since it is unset here, it will either keep the window open
    # (if HIG_INTERACTIVE=1) or exit (default).
    # ---------------------------------------------------------------------------
    title = "HIG: #{SLUG}"
    window = LibWindowHelper.hig_create_window(0.0, 0.0, 1200.0, 900.0, title.to_unsafe)
    LibObjCBridge.objc_send_void_id(window, sel("setContentView:"), native.handle.ptr!)
    LibWindowHelper.hig_run_app(window)
  end
{% else %}
  puts "[hig_showcase] Built without -Dmacos; no native renderer available."
{% end %}
