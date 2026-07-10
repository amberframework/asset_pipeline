# CrystalHIGHost iOS bridge.
#
# Cross-compiled via samples/cross_platform/ios_host/build_crystal_lib.sh into
# libhighost.a, linked into the Swift host app (CrystalHIGHost target).
#
# Exposes C-ABI functions callable from Swift through the bridging header.
#
# Pattern mirrors happy_coach/mobile/shared/bridge.cr -- guarded by
# {% if flag?(:ios) %} so the file also compiles for host tooling without
# pulling in UIKit renderer code.

{% if flag?(:ios) %}

require "../../../src/ui"
require "../../../src/ui/validation_scenes"
require "../../../src/ui/probes"

module CrystalHIGHost::Bridge
  @@initialized = false
  # Keep the NativeView tree alive so the NSObject retain counts don't
  # drop to zero after Swift takes the pointer. One slot per render is
  # enough for this validation host.
  @@last_native : UI::NativeView? = nil

  def self.initialize_runtime
    return if @@initialized
    GC.init
    # iOS-specific: explicitly seed every probe singleton's class
    # variables. Crystal's normal class-variable initialisation runs
    # from `__crystal_main`, but the iOS embedding hides `_main` (via
    # `ld -r -unexported_symbol _main` in build_crystal_lib.sh) and
    # SwiftUI enters Crystal through `crystal_render_slug`, not through
    # `__crystal_main`. Without this seeding,
    # `UI::Probes::DismissProbe.@@last_reason : String = "none"`
    # (and the other probe class variables) returns the zero-init
    # value (nil) instead of "none", and `UI::Label.new(nil).text`
    # later crashes at field load (KERN_INVALID_ADDRESS at 0x4).
    # Root cause is documented in
    # docs/initiative-cross-platform-ui/handoff/phase-03-remediation-9-bx3-bx8-rootcause.md;
    # this is the smallest fix Codex approved at Pre-fix Checkpoint 3.
    # The broader Crystal-iOS class-variable / class-constant init
    # gap (STDERR, Float::Printer::Dragonbox, arbitrary user class
    # vars) is acknowledged as out-of-scope here — see same doc.
    UI::Probes::DismissProbe.reset
    UI::Probes::ToggleProbe.reset
    UI::Probes::SliderProbe.reset
    UI::Probes::TapProbe.reset
    UI::Probes::FormRowProbe.reset
    UI::Probes::RuntimeOverrideProbe.reset
    @@initialized = true
  end

  def self.last_native=(nv : UI::NativeView)
    @@last_native = nv
  end

  # Map a slug to its scene name without using a Hash constant.
  # A Hash constant initialized at module level requires the Crystal runtime
  # (fiber/thread subsystem) to be running when first accessed. On iOS, the
  # first call to crystal_render_slug arrives from SwiftUI's layout pass
  # (UIViewRepresentable.makeUIView), which runs on the main UIKit thread
  # BEFORE Crystal's lazy-initialized Thread::current / once mechanism is
  # set up. Accessing a Hash constant in that context crashes with SIGSEGV
  # at 0x21 (null + 33). A case expression generates plain conditional
  # branches and is safe to call from any thread at any time.
  private def self.scene_for_slug(slug : String) : String?
    case slug
    when "sheets"        then "dashboard"
    when "action-sheets"   then "dashboard"
    when "activity-views"  then "dashboard"
    when "dock-menus"    then "dock"
    else                      nil
    end
  end

  # Wrap a focal component in the appropriate scene composer.
  # Returns the focal unwrapped if no scene is mapped for the slug.
  # The returned view has test_id "hig-component-root" so the iOS XCUITest
  # harness can confirm the app launched and rendered content.
  def self.wrap_in_scene(slug : String, focal : UI::View) : UI::View
    scene_view = case scene_for_slug(slug)
    when "dashboard"
      if slug == "sheets"
        # iOS sheet: return the glass directly so SwiftUI's UIViewRepresentable
        # proposes the full safe area to it. The HIGBackdropController gradient
        # (installed in the window at index 0) provides the dimmed backdrop.
        # Bypassing the DashboardScene avoids UIStackView distribution ambiguity
        # that was clipping the sheet at the Weight field (ios_sh_actions invisible).
        # The glass has minimum_height == maximum_height == 400pt so SwiftUI sizes
        # it correctly via systemLayoutSizeFitting.
        focal
      elsif slug == "action-sheets"
        # iOS action sheet: bottom-anchored layout per HIG.
        # HIG iOS: "On iPhone, action sheets always appear at the bottom of the screen."
        # Use :bottom_sheet focal position to place the glass at the bottom of a
        # compact single-column iOS backdrop (no sidebar, no 3-col chrome).
        UI::ValidationScenes::DashboardScene.new(focal: focal, focal_position: :bottom_sheet).build
      elsif slug == "activity-views"
        # iOS activity view (share sheet): appears as a bottom-anchored modal per HIG.
        # HIG: "An activity view can appear as a sheet or a popover, depending on the
        # device and orientation." On iPhone it is always a sheet from the bottom.
        # Use :bottom_sheet focal position — same compact single-column iOS backdrop
        # as action-sheets — so the glass card is visible in the capture viewport.
        # The 1200pt minimum_width of the 3-column :center_modal chrome overflows the
        # iPhone display and pushes the focal off-screen.
        UI::ValidationScenes::DashboardScene.new(focal: focal, focal_position: :bottom_sheet).build
      else
        # Remaining dashboard-backed surfaces use :center_modal.
        UI::ValidationScenes::DashboardScene.new(focal: focal, focal_position: :center_modal).build
      end
    when "document"
      UI::ValidationScenes::DocumentScene.new(focal: focal, focal_position: :adjacent_to_selection).build
    when "dock"
      UI::ValidationScenes::DockScene.new(focal: focal, focal_position: :above_dock_icon).build
    else
      focal
    end
    # Tag the root view so the iOS XCUITest accessibility probe can find it.
    scene_view.accessibility_label = "hig-component-root"
    scene_view.test_id = "hig-component-root"
    scene_view
  end

  # Dispatch slug -> UI::View. Keep constructor arguments aligned with
  # src/ui/views/<name>.cr; unknown slugs render a Label placeholder so
  # the UITest still finds the accessibility root.
  def self.build_component(slug : String) : UI::View
    # Build the focal component first.
    focal = build_focal(slug)
    # Keep the newer centered study treatment on the iOS slugs that need it,
    # while leaving the scene-backed presentation surfaces alone.
    case slug
    when "alerts"
      centered_study_card(focal, card_width: 320.0, content_padding: UI::EdgeInsets.new(top: 10.0, trailing: 10.0, bottom: 10.0, leading: 10.0))
    when "popovers"
      centered_study_card(focal, card_width: 304.0, content_padding: UI::EdgeInsets.new(top: 10.0, trailing: 10.0, bottom: 10.0, leading: 10.0))
    when "charts"
      centered_study_card(focal, card_width: 356.0, content_padding: UI::EdgeInsets.new(top: 8.0, trailing: 8.0, bottom: 8.0, leading: 8.0))
    when "page-controls"
      centered_study_card(focal, card_width: 300.0, content_padding: UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0))
    when "sidebars"
      centered_study_card(focal, card_width: 344.0, content_padding: UI::EdgeInsets.new(top: 12.0, trailing: 12.0, bottom: 12.0, leading: 12.0))
    when "split-views"
      centered_study_card(focal, card_width: 348.0, content_padding: UI::EdgeInsets.new(top: 12.0, trailing: 12.0, bottom: 12.0, leading: 12.0))
    when "pickers", "toggles"
      centered_study_card(focal, card_width: 360.0, content_padding: UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0))
    when "sliders"
      centered_study_card(focal, card_width: 348.0, content_padding: UI::EdgeInsets.new(top: 12.0, trailing: 12.0, bottom: 12.0, leading: 12.0))
    when "collections"
      centered_study_card(focal, card_width: 304.0, content_padding: UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0))
    when "context-menus"
      centered_study_card(focal, card_width: 284.0, content_padding: UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0))
    when "progress-indicators"
      centered_study_card(focal, card_width: 364.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
    when "segmented-controls"
      centered_study_card(focal, card_width: 332.0, content_padding: UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0))
    when "text-fields"
      centered_study_card(focal, card_width: 364.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
    when "labels"
      centered_study_card(focal, card_width: 320.0, content_padding: UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0))
    when "text-views"
      centered_study_card(focal, card_width: 336.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
    when "image-views"
      centered_study_card(focal, card_width: 324.0, content_padding: UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0))
    when "column-views"
      centered_study_card(focal, card_width: 360.0, content_padding: UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0))
    when "token-fields"
      centered_isolation_plate(focal)
    when "image-wells"
      centered_isolation_plate(focal)
    when "gauges"
      centered_isolation_plate(focal)
    when "activity-rings"
      centered_study_card(focal, card_width: 320.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 18.0, bottom: 16.0, leading: 18.0))
    when "panels"
      centered_study_card(focal, card_width: 336.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
    when "path-controls"
      centered_study_card(focal, card_width: 320.0, content_padding: UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0))
    when "outline-views"
      centered_study_card(focal, card_width: 344.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
    else
      # If a scene is mapped for this slug, wrap it; otherwise return the plain focal.
      # Use scene_for_slug (a case expression) rather than a Hash constant lookup
      # to avoid the Crystal runtime crash documented in scene_for_slug above.
      if scene_for_slug(slug)
        wrap_in_scene(slug, focal)
      elsif isolation_plate_slug?(slug)
        centered_isolation_plate(focal)
      else
        focal
      end
    end
  end

  private def self.isolation_plate_slug?(slug : String) : Bool
    case slug
    when "boxes", "collections", "context-menus", "maps", "playing-video",
         "progress-indicators", "text-fields", "path-controls", "outline-views"
      true
    else
      false
    end
  end

  private def self.centered_isolation_plate(focal : UI::View) : UI::View
    # Centering contract (measured iteration, root-cause recorded in
    # feedback_reflection_over_shotgun.md):
    #
    # SwiftUI's ContentView uses `.frame(maxWidth: .infinity, alignment: .center)`
    # on the UIViewRepresentable. UIStackView with alignment=Center does not
    # reliably center a pinned-width child when the parent's own width is
    # proposed by SwiftUI — the child either flush-lefts or stretches past
    # its required-priority width pin.
    #
    # Robust centering pattern: surround the focal with a pair of unpinned
    # Spacers inside an HStack (default Fill distribution). Two unpinned
    # Spacers in a horizontal UIStackView split the remaining space evenly.
    # The focal's own width pin survives because the Spacers absorb the
    # difference. Works on both macOS and iOS.
    h_center = UI::HStack.new(spacing: 0.0)
    h_center << UI::Spacer.new.as(UI::View)
    h_center << focal
    h_center << UI::Spacer.new.as(UI::View)

    plate = UI::VStack.new(spacing: 0.0)
    plate.minimum_height = 760.0
    plate << UI::Spacer.new.as(UI::View)
    plate << h_center.as(UI::View)
    plate << UI::Spacer.new.as(UI::View)
    plate.accessibility_label = "hig-component-root"
    plate.test_id = "hig-component-root"
    plate.as(UI::View)
  end

  private def self.centered_study_card(focal : UI::View, card_width : Float64, content_padding : UI::EdgeInsets) : UI::View
    card = UI::Card.new(focal)
    card.corner_radius = 10.0
    card.minimum_width = card_width
    card.maximum_width = card_width
    card.content_padding = content_padding
    card.is_outlined = true
    card.material = :secondary
    centered_isolation_plate(card.as(UI::View))
  end

  private def self.popover_option_row(label_text : String, selected : Bool) : UI::View
    row = UI::HStack.new(spacing: 12.0)
    row.minimum_width = 220.0
    row.maximum_width = 220.0
    row.padding = UI::EdgeInsets.new(top: 8.0, trailing: 0.0, bottom: 8.0, leading: 0.0)

    label = UI::Label.new(label_text)
    label.font = UI::Font.new(size: 15.0, weight: :regular)
    row << label.as(UI::View)
    row << UI::Spacer.new.as(UI::View)

    if selected
      check = UI::Image.new("checkmark")
      check.tint_color = UI::Color.new(r: 0.0, g: 0.478, b: 1.0)
      check.accessibility_label = "#{label_text} selected"
      row << check.as(UI::View)
    end

    row.as(UI::View)
  end

  private def self.popover_option_group(title : String, options : Array(Tuple(String, Bool))) : UI::View
    group = UI::VStack.new(spacing: 8.0)

    section_label = UI::Label.new(title)
    section_label.font = UI::Font.new(size: 12.0, weight: :semibold)
    section_label.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
    group << section_label.as(UI::View)

    list = UI::VStack.new(spacing: 0.0)
    list.minimum_width = 220.0
    list.maximum_width = 220.0

    options.each_with_index do |(label_text, selected), index|
      list << popover_option_row(label_text, selected)
      list << UI::Divider.new(:horizontal).as(UI::View) unless index == options.size - 1
    end

    group << list.as(UI::View)
    group.as(UI::View)
  end

  # Build just the focal component (the raw view without scene chrome).
  # Split from build_component so tests can exercise the focal in isolation.
  # NOTE: The "HIG: <slug>" debug label was removed. Scene-label debug strings
  # must not appear in user-facing validation captures (Issue B). Slugs without
  # a scene wrapper (e.g. buttons, toggles, sidebars) were showing this label
  # as visible text in the rendered output.
  def self.build_focal(slug : String) : UI::View
    vstack = UI::VStack.new(spacing: 16.0)

    child = case slug
            when "alerts"
              # Amber alert: "Reshape today's timeline?" — destructive action
              # erases 3h of context. Amber copy per brand/amber.md.
              # HIG: "Use the destructive style to identify a button that performs
              # a destructive action people didn't deliberately choose." — Alerts.
              # Inline glass-card via UIVisualEffectView (UIGlassEffect iOS 26 /
              # UIBlurEffectStyleSystemMaterial fallback). Not via is_presented.
              ios_alert = UI::Alert.new("Reshape today's timeline?", "This erases 3 hours of context. Amber cannot restore it.")
              ios_alert.add_button("Cancel", :cancel)
              ios_alert.add_button("Reshape", :destructive)
              ios_alert.minimum_width = 284.0
              ios_alert.maximum_width = 284.0
              ios_alert.as(UI::View)
            when "action-sheets"
              # HIG canonical action sheet layout (Mail cancel-draft pattern).
              # HIG iOS: "On iPhone, action sheets always appear at the bottom."
              # HIG: "Make destructive choices visually prominent; place them at
              # the top of the action sheet." HIG: "Place the Cancel button at
              # the bottom, separated from the other actions."
              # The Cancel button renders as a VISUALLY SEPARATE capsule with an
              # 8pt gap below the main action group — matching HIG canonical
              # Mail action-sheet illustration. Bottom-anchored via :bottom_sheet.
              # Corner radius 16pt (Amber phi-scale "sheet" token).

              # Main action card: prompt + 3 actions (destructive first, per HIG).
              main_content = UI::VStack.new(spacing: 8.0)
              main_prompt = UI::Label.new("What should Amber do with this draft?")
              main_prompt.font = UI::Font.new(size: 15.0, weight: :semibold)
              main_prompt.accessibility_label = "Action sheet prompt"
              main_content << main_prompt.as(UI::View)
              main_content << UI::Button.new("Banish draft forever", role: :destructive)
              main_content << UI::Button.new("Archive to vault")
              main_content << UI::Button.new("Conjure copy")
              main_sheet = UI::Sheet.new(main_content.as(UI::View), surface_style: :grouped_card)
              main_sheet.minimum_height = 220.0
              main_sheet.maximum_height = 220.0
              main_sheet.accessibility_label = "Action sheet: draft management"

              # Detached Cancel capsule — 8pt gap below main card per HIG.
              # HIG: "Provide a Cancel button. On iPhone, always add a Cancel
              # button so people can abandon the action."
              cancel_content = UI::VStack.new(spacing: 0.0)
              cancel_btn = UI::Button.new("Never mind", role: :cancel)
              cancel_content << cancel_btn.as(UI::View)
              cancel_sheet = UI::Sheet.new(cancel_content.as(UI::View), surface_style: :grouped_card)
              cancel_sheet.minimum_height = 60.0
              cancel_sheet.maximum_height = 60.0
              cancel_sheet.accessibility_label = "Cancel action sheet"

              # Gallery: main card + 8pt spacer + cancel capsule.
              # Total focal height: 220 + 8 + 60 = 288pt.
              gallery = UI::VStack.new(spacing: 8.0)
              gallery.alignment = UI::Alignment::Fill
              gallery << main_sheet.as(UI::View)
              gallery << cancel_sheet.as(UI::View)
              gallery.as(UI::View)
            when "activity-views"
              # UI::ActivityView — four-zone share sheet.
              # HIG: "An activity view presents sharing activities like messaging
              # and actions like Copy and Print, in addition to quick access to
              # frequently used apps." Rendered inline for capture path.
              # Production: dispatch UIActivityViewController instead.
              # minimum_height=320pt: header ~50pt + dest row ~80pt + action
              # grid ~110pt + cancel ~44pt + insets 36pt = ~320pt. Fixed height
              # so UIStackView distribution does not collapse the glass card in
              # the :bottom_sheet compact iOS scene. Amber content per brand/amber.md.
              act = UI::ActivityView.new(
                title: "Nature Walks",
                subtitle: "12 photos · 3.4 MB",
                thumbnail: UI::Image.new("photo"),
                destinations: [
                  UI::ActivityDestination.new(icon_symbol: "envelope",  label: "Mail"),
                  UI::ActivityDestination.new(icon_symbol: "message",   label: "Messages"),
                  UI::ActivityDestination.new(icon_symbol: "wifi",      label: "AirDrop"),
                  UI::ActivityDestination.new(icon_symbol: "note.text", label: "Notes"),
                  UI::ActivityDestination.new(icon_symbol: "archivebox", label: "Vault"),
                ],
                actions: [
                  UI::ActivityAction.new(icon_symbol: "folder",     label: "Save to Files"),
                  UI::ActivityAction.new(icon_symbol: "wand.and.stars", label: "Conjure copy"),
                  UI::ActivityAction.new(icon_symbol: "doc.on.doc", label: "Copy"),
                  UI::ActivityAction.new(icon_symbol: "printer",    label: "Print"),
                ],
                on_cancel: -> { }
              )
              # minimum_height=300pt prevents UIStackView from collapsing the
              # glass card. No maximum_height — the card auto-sizes to content
              # (all four HIG zones: header + dest row + action grid + cancel).
              act.minimum_height = 300.0
              act.accessibility_label = "Activity view: Nature Walks share sheet"
              act.as(UI::View)
            when "boxes"
              # HIG Box -> UI::Card -> UIView grouped container. iOS/iPadOS
              # HIG platform note: "iOS and iPadOS use the secondary and
              # tertiary background colors in boxes." Render title + body +
              # two label/value rows; keep buttons out so the verdict can
              # evaluate the card chrome itself (avoiding the UI::Button#role
              # gap documented in gaps.md).
              box_body = UI::VStack.new(spacing: 10.0)
              box_body.alignment = UI::Alignment::Leading
              box_intro = UI::Label.new("Your order ships in a reusable padded mailer.")
              box_intro.font = UI::Font.new(size: 15.0, weight: :regular)
              box_body << box_intro.as(UI::View)
              box_row1 = UI::HStack.new(spacing: 12.0)
              box_row1.alignment = UI::Alignment::Center
              box_carrier_label = UI::Label.new("Carrier")
              box_carrier_label.font = UI::Font.new(size: 13.0, weight: :semibold)
              box_carrier_label.text_color_role = UI::LabelRole::Secondary
              box_carrier_value = UI::Label.new("USPS Ground")
              box_carrier_value.font = UI::Font.new(size: 15.0, weight: :regular)
              box_row1 << box_carrier_label.as(UI::View)
              box_row1 << UI::Spacer.new.as(UI::View)
              box_row1 << box_carrier_value.as(UI::View)
              box_row2 = UI::HStack.new(spacing: 12.0)
              box_row2.alignment = UI::Alignment::Center
              box_arrival_label = UI::Label.new("Estimated arrival")
              box_arrival_label.font = UI::Font.new(size: 13.0, weight: :semibold)
              box_arrival_label.text_color_role = UI::LabelRole::Secondary
              box_arrival_value = UI::Label.new("Apr 17 - Apr 19")
              box_arrival_value.font = UI::Font.new(size: 15.0, weight: :regular)
              box_row2 << box_arrival_label.as(UI::View)
              box_row2 << UI::Spacer.new.as(UI::View)
              box_row2 << box_arrival_value.as(UI::View)
              box_body << box_row1
              box_body << box_row2
              box_card = UI::Card.new(box_body.as(UI::View))
              box_card.title = "Shipping details"
              box_card.content_padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
              box_card.is_outlined = true
              box_card.minimum_width = 284.0
              box_card.maximum_width = 284.0
              box_card.as(UI::View)
            when "collections"
              # HIG Collections: "A collection manages an ordered set of
              # content and presents it in a customizable and highly visual
              # layout." HIG illustration shows a 4-column image grid.
              # We render a 3-column photo-tile grid using UI::ListView in
              # grid mode (layout: :grid, columns: 3) matching HIG best
              # practice: "Use the standard row or grid layout whenever
              # possible." Each tile is a VStack with a placeholder label
              # and a caption.
              make_tile = ->(symbol : String, caption : String) do
                tile = UI::VStack.new(spacing: 4.0)
                tile.alignment = UI::Alignment::Center
                tile.minimum_width = 96.0
                tile.maximum_width = 96.0
                tile.minimum_height = 96.0
                tile.padding = UI::EdgeInsets.new(top: 10.0, trailing: 8.0, bottom: 8.0, leading: 8.0)
                tile.corner_radius = 12.0
                tile.background = UI::Color.new(r: 0.96, g: 0.92, b: 0.86, a: 0.70)
                thumb = UI::Image.new(symbol)
                thumb.minimum_width = 34.0
                thumb.minimum_height = 34.0
                thumb.content_mode = UI::ContentMode::Fit
                thumb.tint_color = UI::Color.new(r: 0.36, g: 0.23, b: 0.58)
                cap = UI::Label.new(caption)
                cap.font = UI::Font.new(size: 12.0, weight: :regular)
                cap.text_color_role = nil
                cap.text_color = UI::Color.new(r: 0.45, g: 0.45, b: 0.45)
                tile << thumb.as(UI::View)
                tile << cap.as(UI::View)
                tile.as(UI::View)
              end
              coll_tiles = [
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
              coll_stack = UI::VStack.new(spacing: 14.0)
              coll_stack.alignment = UI::Alignment::Center
              coll_stack.minimum_width = 240.0
              coll_stack.maximum_width = 240.0
              coll_stack << UI::Label.new("Photos").tap { |l| l.font = UI::Font.new(size: 17.0, weight: :semibold) }.as(UI::View)
              coll_tiles.first(6).each_slice(2) do |pair|
                row = UI::HStack.new(spacing: 12.0)
                row.alignment = UI::Alignment::Center
                pair.each { |tile| row << tile }
                coll_stack << row.as(UI::View)
              end
              coll_stack.as(UI::View)
            when "lists-and-tables"
              # HIG "Lists and tables" gallery -- iter-31.
              # Three sections: plain list, inset-grouped card, accessory rows.
              # HIG Best practices: "Prefer displaying text in a list or table.
              # A table can include any type of content, but the row-based
              # format is especially well suited to making text easy to scan
              # and read." HIG iOS: "If you need to let people drill into a
              # list or table row's subviews, use a disclosure indicator
              # accessory control." We use U+276F as a disclosure-indicator
              # stand-in (UITableViewCell.AccessoryType.disclosureIndicator
              # requires a real UITableView, not a UIStackView row).
              ios_lt_row = ->(title : String, trailing : String) do
                r = UI::HStack.new(spacing: 12.0)
                r << UI::Label.new(title)
                r << UI::Spacer.new
                tl = UI::Label.new(trailing)
                tl.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
                r << tl.as(UI::View)
                r.as(UI::View)
              end

              ios_gallery = UI::VStack.new(spacing: 16.0)

              # Section 1: Plain list with hairline separators.
              ios_gallery << UI::Label.new("Plain List").as(UI::View)
              plain_items = [
                ios_lt_row.call("Mail", ""),
                ios_lt_row.call("Messages", ""),
                ios_lt_row.call("Notes", ""),
                ios_lt_row.call("Reminders", ""),
              ] of UI::View
              plain_sec = UI::ListView::Section.new(items: plain_items)
              plain_lst = UI::ListView.new(sections: [plain_sec], style: UI::ListStyle::Plain)
              plain_lst.shows_separators = true
              ios_gallery << plain_lst.as(UI::View)

              ios_gallery << UI::Divider.new(:horizontal).as(UI::View)

              # Section 2: Inset-grouped (rounded card).
              ios_gallery << UI::Label.new("Inset-Grouped List").as(UI::View)
              grouped_items = [
                ios_lt_row.call("General", "\u276F"),
                ios_lt_row.call("Appearance", "\u276F"),
                ios_lt_row.call("Sounds & Haptics", "\u276F"),
              ] of UI::View
              grouped_sec = UI::ListView::Section.new(header: "Settings", items: grouped_items)
              grouped_lst = UI::ListView.new(sections: [grouped_sec], style: UI::ListStyle::InsetGrouped)
              grouped_lst.shows_separators = true
              ios_gallery << grouped_lst.as(UI::View)

              ios_gallery << UI::Divider.new(:horizontal).as(UI::View)

              # Section 3: Accessory rows (chevron + value text).
              ios_gallery << UI::Label.new("Row Accessories").as(UI::View)
              acc_items = [
                ios_lt_row.call("Wi-Fi", "HomeNet \u276F"),
                ios_lt_row.call("Bluetooth", "On"),
                ios_lt_row.call("Cellular", "\u276F"),
              ] of UI::View
              acc_sec = UI::ListView::Section.new(items: acc_items)
              acc_lst = UI::ListView.new(sections: [acc_sec], style: UI::ListStyle::Grouped)
              acc_lst.shows_separators = true
              ios_gallery << acc_lst.as(UI::View)

              ios_gallery.as(UI::View)
            when "context-menus"
              # HIG context menu content: task-specific commands revealed by
              # long-press on iOS / iPadOS. Use the dedicated UI::ContextMenu
              # surface so the capture reflects full-width menu rows rather
              # than a stack of separate buttons.
              menu = UI::ContextMenu.new
              menu.minimum_width = 240.0
              menu.maximum_width = 240.0
              menu.accessibility_label = "Selection commands"
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
              # HIG digit entry view: full-screen PIN / passcode entry.
              # HIG abstract: "A digit entry view fills the entire screen
              # and prompts people to enter a series of digits, like a PIN,
              # using a digit-specific keyboard." HIG Platform considerations:
              # "Not supported in iOS, iPadOS, macOS, visionOS, or watchOS"
              # -- this component is tvOS-only (TVDigitEntryViewController).
              # We render a HIG-faithful *visual mock* using UI::TextField
              # primitives: title, prompt, and a horizontal row of 6 secure
              # TextField cells with NumberPad keyboard hints. Exercises the
              # HIG "line of digits" visual and secure-entry recommendation.
              digit_content = UI::VStack.new(spacing: 12.0)
              digit_content << UI::Label.new("Enter Passcode")
              digit_content << UI::Label.new("Enter the 6-digit code sent to your device.")
              digit_row = UI::HStack.new(spacing: 8.0)
              6.times do
                cell = UI::TextField.new("·")
                cell.secure_entry = true
                cell.keyboard_type = UI::KeyboardType::NumberPad
                digit_row << cell
              end
              digit_content << digit_row.as(UI::View)
              digit_content.as(UI::View)
            when "disclosure-controls"
              # HIG "Disclosure controls" (iOS/iPadOS): SwiftUI
              # DisclosureGroup view, rendered as a chevron-prefixed
              # UIButton row (chevron.right collapsed, chevron.down
              # expanded) + optional child UIStackView content.
              # HIG: "Disclosure controls are available in iOS, iPadOS,
              # and visionOS with the SwiftUI DisclosureGroup view."
              # Both expanded and collapsed states shown inline.
              disc_content = UI::VStack.new(spacing: 12.0)

              # Expanded group: General (chevron.down)
              ios_expanded = UI::DisclosureGroup.new("General", expanded: true)
              ios_expanded.content << UI::Label.new("Appearance: Auto")
              ios_expanded.content << UI::Label.new("Language & Region: English (US)")
              ios_expanded.content << UI::Label.new("Date & Time: Automatic")
              disc_content << ios_expanded.as(UI::View)

              # Collapsed group: Privacy & Security (chevron.right)
              ios_collapsed = UI::DisclosureGroup.new("Privacy & Security", expanded: false)
              ios_collapsed.content << UI::Label.new("Location Services: On")
              disc_content << ios_collapsed.as(UI::View)

              # Collapsed group: Notifications
              ios_notif = UI::DisclosureGroup.new("Notifications", expanded: false)
              ios_notif.content << UI::Label.new("Allow Notifications: On")
              disc_content << ios_notif.as(UI::View)

              disc_content << UI::Divider.new(:horizontal)

              # "Show More" disclosure button pattern (collapsed)
              ios_more = UI::DisclosureGroup.new("Show More", expanded: false)
              ios_more.content << UI::Label.new("Output: /Documents")
              disc_content << ios_more.as(UI::View)

              # "Show Less" disclosure button pattern (expanded)
              ios_less = UI::DisclosureGroup.new("Show Less", expanded: true)
              ios_less.content << UI::Label.new("Output: /Documents")
              ios_less.content << UI::Label.new("Format: PDF")
              ios_less.content << UI::Label.new("Color: sRGB")
              disc_content << ios_less.as(UI::View)

              disc_content.as(UI::View)
            when "dock-menus"
              # HIG Dock menus are macOS-only. Platform considerations:
              # "Not supported in iOS, iPadOS, tvOS, visionOS, or watchOS."
              # HIG note: "Although iOS and iPadOS don't support a Dock
              # menu, people can reveal a similar menu of system-provided
              # and custom items -- called Home Screen quick actions --
              # when they long press an app icon on the Home Screen or in
              # the Dock." That's tracked as the `home-screen-quick-actions`
              # slug (P2). For this validation we render a clearly-intentional
              # "macOS-only feature" placeholder card so the screenshot is
              # non-black and the platform exclusion is documented in-frame.
              # The surface uses UI::Sheet grouped_card so it reads as a
              # deliberate HIG-styled card rather than a blank fallback.
              dock_na_content = UI::VStack.new(spacing: 12.0)

              na_title = UI::Label.new("Dock Menus — macOS Only")
              na_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              dock_na_content << na_title.as(UI::View)

              na_body = UI::Label.new("Dock menus are a macOS-exclusive feature. People secondary-click an app icon in the Dock to reveal custom and system items.")
              na_body.font = UI::Font.new(size: 15.0, weight: :regular)
              na_body.number_of_lines = 0
              dock_na_content << na_body.as(UI::View)

              dock_na_content << UI::Divider.new(:horizontal)

              na_alt_title = UI::Label.new("iOS equivalent")
              na_alt_title.font = UI::Font.new(size: 13.0, weight: :semibold)
              na_alt_title.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
              dock_na_content << na_alt_title.as(UI::View)

              na_alt_body = UI::Label.new("Home Screen quick actions (long-press on app icon) provide a similar contextual-command surface on iOS. See HIG: Home Screen quick actions.")
              na_alt_body.font = UI::Font.new(size: 13.0, weight: :regular)
              na_alt_body.number_of_lines = 0
              na_alt_body.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
              dock_na_content << na_alt_body.as(UI::View)

              UI::Sheet.new(dock_na_content.as(UI::View), surface_style: :grouped_card).as(UI::View)
            when "panels"
              # HIG panels are macOS-only auxiliary windows. Keep the iOS
              # preview explicit and useful rather than faking floating window
              # chrome on a platform that does not support it.
              panel_na_content = UI::VStack.new(spacing: 12.0)
              panel_na_content.alignment = UI::Alignment::Leading
              panel_na_content.minimum_width = 272.0
              panel_na_content.maximum_width = 272.0

              panel_na_title = UI::Label.new("Panels are macOS only")
              panel_na_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              panel_na_content << panel_na_title.as(UI::View)

              panel_na_body = UI::Label.new("Use sheets or split views on iPhone and iPad for supplementary controls tied to the current task.")
              panel_na_body.font = UI::Font.new(size: 15.0, weight: :regular)
              panel_na_body.number_of_lines = 0
              panel_na_content << panel_na_body.as(UI::View)

              panel_na_content << UI::Divider.new(:horizontal)

              panel_na_alt_title = UI::Label.new("Closest iOS fit")
              panel_na_alt_title.font = UI::Font.new(size: 13.0, weight: :semibold)
              panel_na_alt_title.text_color_role = UI::LabelRole::Secondary
              panel_na_content << panel_na_alt_title.as(UI::View)

              panel_na_alt_body = UI::Label.new("A sheet, popover, or inspector pane can present the same controls without floating window chrome.")
              panel_na_alt_body.font = UI::Font.new(size: 13.0, weight: :regular)
              panel_na_alt_body.number_of_lines = 0
              panel_na_alt_body.text_color_role = UI::LabelRole::Secondary
              panel_na_content << panel_na_alt_body.as(UI::View)

              panel_na_content.as(UI::View)
            when "edit-menus"
              # HIG edit menu: the contextual text-editing surface revealed by
              # touch-and-hold / double-tap on a text selection (iOS / iPadOS).
              # HIG abstract: "An edit menu lets people make changes to
              # selected content in the current view, in addition to offering
              # related commands like Copy, Select, Translate, and Look Up."
              # HIG iOS behavior: "the edit menu displays commands in a
              # compact, horizontal list ... People can tap a chevron on the
              # trailing edge to expand it into a context menu." We mirror the
              # inline-VStack-in-Sheet pattern (not the compact horizontal bar)
              # so the screenshot captures the full vertical command set.
              # Canonical iOS UIResponderStandardEditActions item set:
              #   Group 1 (clipboard): Cut (scissors) / Copy (doc.on.doc)
              #                        / Paste (doc.on.clipboard)
              #   Separator
              #   Group 2 (selection): Select All (selection.pin.in.out)
              #   Separator
              #   Group 3 (find / utilities): Find... (magnifyingglass)
              #                               / Look Up (book)
              #                               / Translate (character.bubble)
              #   Separator
              #   Group 4 (share): Share (square.and.arrow.up)
              # No keyboard shortcut labels on iOS (touch platform). No
              # destructive items -- standard edit menu actions are clipboard
              # operations, not data-destroying. HIG "Best practices":
              # "Prefer the system-provided edit menu... For a list of
              # standard edit menu commands, see UIResponderStandardEditActions."
              edit_content = UI::VStack.new(spacing: 4.0)

              # --- Group 1: Clipboard ---
              edit_content << UI::Button.new("Cut", symbol: "scissors")
              edit_content << UI::Button.new("Copy", symbol: "doc.on.doc")
              edit_content << UI::Button.new("Paste", symbol: "doc.on.clipboard")

              edit_content << UI::Divider.new(:horizontal)

              # --- Group 2: Selection ---
              edit_content << UI::Button.new("Select All", symbol: "selection.pin.in.out")

              edit_content << UI::Divider.new(:horizontal)

              # --- Group 3: Find / utilities ---
              edit_content << UI::Button.new("Find\u2026", symbol: "magnifyingglass")
              edit_content << UI::Button.new("Look Up", symbol: "book")
              edit_content << UI::Button.new("Translate", symbol: "character.bubble")

              edit_content << UI::Divider.new(:horizontal)

              # --- Group 4: Share ---
              edit_content << UI::Button.new("Share", symbol: "square.and.arrow.up")

              edit_plate = UI::VStack.new(spacing: 12.0)
              edit_plate.alignment = UI::Alignment::Leading

              edit_title = UI::Label.new("Edit menus")
              edit_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              edit_plate << edit_title.as(UI::View)

              edit_subtitle = UI::Label.new("Clipboard and lookup actions in a compact study.")
              edit_subtitle.font = UI::Font.new(size: 13.0, weight: :regular)
              edit_subtitle.text_color_role = UI::LabelRole::Secondary
              edit_subtitle.number_of_lines = 0
              edit_plate << edit_subtitle.as(UI::View)

              edit_plate << edit_content.as(UI::View)
              centered_study_card(edit_plate.as(UI::View), card_width: 320.0, content_padding: UI::EdgeInsets.new(top: 14.0, trailing: 14.0, bottom: 14.0, leading: 14.0))
            when "menus"
              # Keep the menu study compact and centered so the two menu types
              # read as one calm card instead of separate demo dumps.
              ios_menus_body = UI::VStack.new(spacing: 12.0)
              ios_menus_body.alignment = UI::Alignment::Leading
              ios_menus_body.minimum_width = 292.0
              ios_menus_body.maximum_width = 292.0

              ios_menus_title = UI::Label.new("Menus")
              ios_menus_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_menus_title.accessibility_label = "Menus showcase title"
              ios_menus_body << ios_menus_title

              ios_menus_desc = UI::Label.new("Pull-down and pop-up menus in a compact study.")
              ios_menus_desc.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_menus_desc.text_color_role = UI::LabelRole::Secondary
              ios_menus_desc.number_of_lines = 0
              ios_menus_desc.accessibility_label = "Menus showcase description"
              ios_menus_body << ios_menus_desc

              ios_file_hdr = UI::Label.new("File")
              ios_file_hdr.font = UI::Font.new(size: 12.0, weight: :semibold)
              ios_file_hdr.text_color_role = UI::LabelRole::Secondary
              ios_file_hdr.accessibility_label = "File menu section header"
              ios_menus_body << ios_file_hdr

              ios_file_content = UI::VStack.new(spacing: 0.0)
              ios_file_content << UI::Button.new("New", symbol: "doc")
              ios_file_content << UI::Button.new("Open\u2026", symbol: "folder.open")
              ios_file_content << UI::Button.new("Close", symbol: "xmark")
              ios_file_content << UI::Divider.new(:horizontal)

              ios_export_row = UI::HStack.new(spacing: 8.0)
              ios_export_row << UI::Button.new("Export", symbol: "square.and.arrow.up")
              ios_export_row << UI::Spacer.new.as(UI::View)
              ios_chevron = UI::Label.new("\u203a")
              ios_chevron.font = UI::Font.new(size: 15.0, weight: :regular)
              ios_chevron.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
              ios_export_row << ios_chevron.as(UI::View)
              ios_file_content << ios_export_row.as(UI::View)
              ios_menus_body << ios_file_content.as(UI::View)
              ios_menus_body << UI::Divider.new(:horizontal)

              ios_sort_hdr = UI::Label.new("Sort")
              ios_sort_hdr.font = UI::Font.new(size: 12.0, weight: :semibold)
              ios_sort_hdr.text_color_role = UI::LabelRole::Secondary
              ios_sort_hdr.accessibility_label = "Sort pop-up section header"
              ios_menus_body << ios_sort_hdr

              ios_sort_content = UI::VStack.new(spacing: 0.0)

              ios_name_row = UI::HStack.new(spacing: 8.0)
              ios_name_row << UI::Label.new("Sort by name").as(UI::View)
              ios_name_row << UI::Spacer.new.as(UI::View)
              ios_name_row << UI::Button.new("Name", symbol: "character")
              ios_sort_content << ios_name_row.as(UI::View)

              ios_date_row = UI::HStack.new(spacing: 8.0)
              ios_date_row << UI::Label.new("Sort by date").as(UI::View)
              ios_date_row << UI::Spacer.new.as(UI::View)
              ios_checkmark = UI::Label.new("\u2713")
              ios_checkmark.font = UI::Font.new(size: 13.0, weight: :semibold)
              ios_date_row << ios_checkmark.as(UI::View)
              ios_date_row << UI::Button.new("Date", symbol: "calendar")
              ios_sort_content << ios_date_row.as(UI::View)

              ios_size_row = UI::HStack.new(spacing: 8.0)
              ios_size_row << UI::Label.new("Sort by size").as(UI::View)
              ios_size_row << UI::Spacer.new.as(UI::View)
              ios_size_row << UI::Button.new("Size", symbol: "arrow.up.arrow.down")
              ios_sort_content << ios_size_row.as(UI::View)
              ios_menus_body << ios_sort_content.as(UI::View)

              centered_study_card(ios_menus_body.as(UI::View), card_width: 340.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
            when "buttons"
              # HIG button gallery matching the macOS hig_showcase arm.
              # Eleven-row set covering all ButtonStyle variants, roles, and states.
              # UIButton.Configuration variants (iOS 15+):
              #   Default / Bordered -> .gray()    — bordered, gray fill
              #   Prominent          -> .filled()   — filled blue (or red for dest)
              #   Tinted             -> .tinted()   — translucent accent fill
              #   Borderless         -> .plain()    — text-link, no bezel
              ios_btn_gallery = UI::VStack.new(spacing: 10.0)
              ios_btn_gallery << UI::Label.new("Button Style / Role Gallery").tap { |l|
                l.font = UI::Font.new(size: 13.0, weight: :semibold)
              }
              # Row 1 -- Default (gray configuration, system bordered)
              ios_r1 = UI::HStack.new(spacing: 12.0)
              ios_r1 << UI::Label.new("Default")
              ios_r1 << UI::Button.new("Continue", style: UI::ButtonStyle::Default)
              ios_btn_gallery << ios_r1.as(UI::View)
              # Row 2 -- Prominent (filled blue CTA)
              ios_r2 = UI::HStack.new(spacing: 12.0)
              ios_r2 << UI::Label.new("Prominent")
              ios_r2 << UI::Button.new("Save", style: UI::ButtonStyle::Prominent)
              ios_btn_gallery << ios_r2.as(UI::View)
              # Row 3 -- Tinted (translucent accent fill)
              ios_r3 = UI::HStack.new(spacing: 12.0)
              ios_r3 << UI::Label.new("Tinted")
              ios_r3 << UI::Button.new("Add to List", style: UI::ButtonStyle::Tinted)
              ios_btn_gallery << ios_r3.as(UI::View)
              # Row 4 -- Bordered (same as Default, explicit knob)
              ios_r4 = UI::HStack.new(spacing: 12.0)
              ios_r4 << UI::Label.new("Bordered")
              ios_r4 << UI::Button.new("Options", style: UI::ButtonStyle::Bordered)
              ios_btn_gallery << ios_r4.as(UI::View)
              # Row 5 -- Borderless (plain configuration, text-link)
              ios_r5 = UI::HStack.new(spacing: 12.0)
              ios_r5 << UI::Label.new("Borderless")
              ios_r5 << UI::Button.new("Learn more", style: UI::ButtonStyle::Borderless)
              ios_btn_gallery << ios_r5.as(UI::View)
              # Row 6 -- Destructive role (red label on gray bezel)
              ios_r6 = UI::HStack.new(spacing: 12.0)
              ios_r6 << UI::Label.new("Destructive")
              ios_r6 << UI::Button.new("Delete", role: :destructive)
              ios_btn_gallery << ios_r6.as(UI::View)
              # Row 7 -- Cancel role (semibold per HIG)
              ios_r7 = UI::HStack.new(spacing: 12.0)
              ios_r7 << UI::Label.new("Cancel")
              ios_r7 << UI::Button.new("Cancel", role: :cancel)
              ios_btn_gallery << ios_r7.as(UI::View)
              # Row 8 -- Prominent + Destructive (red filled bezel)
              ios_r8 = UI::HStack.new(spacing: 12.0)
              ios_r8 << UI::Label.new("Prom + Dest")
              ios_r8 << UI::Button.new("Delete Account", role: :destructive, style: UI::ButtonStyle::Prominent)
              ios_btn_gallery << ios_r8.as(UI::View)
              # Row 9 -- Disabled
              ios_r9 = UI::HStack.new(spacing: 12.0)
              ios_r9 << UI::Label.new("Disabled")
              ios_dis = UI::Button.new("Unavailable")
              ios_dis.disabled = true
              ios_r9 << ios_dis.as(UI::View)
              ios_btn_gallery << ios_r9.as(UI::View)
              # Row 10 -- SF Symbol (share icon)
              ios_r10 = UI::HStack.new(spacing: 12.0)
              ios_r10 << UI::Label.new("SF Symbol")
              ios_r10 << UI::Button.new("Share", symbol: "square.and.arrow.up")
              ios_btn_gallery << ios_r10.as(UI::View)
              # Row 11 -- Destructive with symbol
              ios_r11 = UI::HStack.new(spacing: 12.0)
              ios_r11 << UI::Label.new("Dest + Symbol")
              ios_r11 << UI::Button.new("Remove", role: :destructive, symbol: "trash")
              ios_btn_gallery << ios_r11.as(UI::View)
              ios_btn_gallery.as(UI::View)
            when "toggles"
              # HIG toggles: six HIG-canonical scenarios covering ON, OFF,
              # Disabled-ON, Disabled-OFF states per Best practices.
              # HIG Best practices: "Make sure the visual differences in a
              # toggle's state are obvious." -- on (Amber gold), gray (off),
              # dimmed (disabled).
              # iOS: UISwitch -- setOn:animated: / setOnTintColor: / setEnabled:.
              # HIG iOS: "Use the switch toggle style only in a list row."
              # HIG iOS: "Use the same color for all switches in your app" --
              # all ON-state switches use Amber gold.
              # Dark mode fix (June R3): UISwitch.overrideUserInterfaceStyle is
              # set directly in the renderer from TEST_RUNNER_HIG_APPEARANCE so
              # the OFF-state track resolves as dark gray (#3A2A10 equivalent),
              # not cream (light mode fallback).
              ios_amber_gold_tgl = UI::Color.new(r: 1.0, g: 0.678, b: 0.2)
              ios_tgl_stack = UI::VStack.new(spacing: 16.0)

              # Row 1: ON state -- Amber gold track, thumb right
              ios_row1 = UI::HStack.new(spacing: 12.0)
              ios_lbl1 = UI::Label.new("Notifications")
              ios_lbl1.accessibility_label = "Notifications label"
              ios_row1 << ios_lbl1.as(UI::View)
              ios_row1 << UI::Spacer.new.as(UI::View)
              ios_tgl_on = UI::Toggle.new("", true)
              ios_tgl_on.tint_color = ios_amber_gold_tgl
              ios_tgl_on.accessibility_label = "Notifications toggle, on"
              ios_row1 << ios_tgl_on.as(UI::View)
              ios_tgl_stack << ios_row1.as(UI::View)

              # Row 2: OFF state -- system gray track (dark: dark gray pill),
              # thumb left. overrideUserInterfaceStyle is set per-switch in renderer.
              ios_row2 = UI::HStack.new(spacing: 12.0)
              ios_lbl2 = UI::Label.new("Dark Mode")
              ios_lbl2.accessibility_label = "Dark Mode label"
              ios_row2 << ios_lbl2.as(UI::View)
              ios_row2 << UI::Spacer.new.as(UI::View)
              ios_tgl_off = UI::Toggle.new("", false)
              ios_tgl_off.accessibility_label = "Dark Mode toggle, off"
              ios_row2 << ios_tgl_off.as(UI::View)
              ios_tgl_stack << ios_row2.as(UI::View)

              # Row 3: Disabled (OFF) -- dimmed, non-interactive.
              # HIG: "Clearly identify the setting, view, or content the toggle affects."
              ios_row3 = UI::HStack.new(spacing: 12.0)
              ios_lbl3 = UI::Label.new("Location")
              ios_lbl3.accessibility_label = "Location label"
              ios_row3 << ios_lbl3.as(UI::View)
              ios_row3 << UI::Spacer.new.as(UI::View)
              ios_tgl_disabled_off = UI::Toggle.new("", false)
              ios_tgl_disabled_off.disabled = true
              ios_tgl_disabled_off.accessibility_label = "Location toggle, disabled off"
              ios_row3 << ios_tgl_disabled_off.as(UI::View)
              ios_tgl_stack << ios_row3.as(UI::View)

              # Row 4: ON with Amber gold -- consistent brand accent per HIG.
              # "Use the same color for all switches in your app." Focus Mode
              # demonstrates ON state with the brand accent (Amber gold).
              ios_row4 = UI::HStack.new(spacing: 12.0)
              ios_lbl4 = UI::Label.new("Focus Mode")
              ios_lbl4.accessibility_label = "Focus Mode label"
              ios_row4 << ios_lbl4.as(UI::View)
              ios_row4 << UI::Spacer.new.as(UI::View)
              ios_tgl_focus = UI::Toggle.new("", true)
              ios_tgl_focus.tint_color = ios_amber_gold_tgl
              ios_tgl_focus.accessibility_label = "Focus Mode toggle, on"
              ios_row4 << ios_tgl_focus.as(UI::View)
              ios_tgl_stack << ios_row4.as(UI::View)

              # Row 5: Disabled ON -- gold track dimmed, non-interactive.
              # Stresses dark rendering: gold fill should remain visible at reduced alpha.
              ios_row5 = UI::HStack.new(spacing: 12.0)
              ios_lbl5 = UI::Label.new("Night Shift")
              ios_lbl5.accessibility_label = "Night Shift label"
              ios_row5 << ios_lbl5.as(UI::View)
              ios_row5 << UI::Spacer.new.as(UI::View)
              ios_tgl_disabled_on = UI::Toggle.new("", true)
              ios_tgl_disabled_on.tint_color = ios_amber_gold_tgl
              ios_tgl_disabled_on.disabled = true
              ios_tgl_disabled_on.accessibility_label = "Night Shift toggle, disabled on"
              ios_row5 << ios_tgl_disabled_on.as(UI::View)
              ios_tgl_stack << ios_row5.as(UI::View)

              # Row 6: Disabled OFF -- dark gray track dimmed.
              ios_row6 = UI::HStack.new(spacing: 12.0)
              ios_lbl6 = UI::Label.new("Auto Lock")
              ios_lbl6.accessibility_label = "Auto Lock label"
              ios_row6 << ios_lbl6.as(UI::View)
              ios_row6 << UI::Spacer.new.as(UI::View)
              ios_tgl_disabled_off2 = UI::Toggle.new("", false)
              ios_tgl_disabled_off2.disabled = true
              ios_tgl_disabled_off2.accessibility_label = "Auto Lock toggle, disabled off"
              ios_row6 << ios_tgl_disabled_off2.as(UI::View)
              ios_tgl_stack << ios_row6.as(UI::View)

              ios_tgl_stack.as(UI::View)
            when "text-fields"
              # HIG text-fields: four labelled variants on iOS UITextField.
              # UITextField with UITextBorderStyleRoundedRect for bordered chrome.
              # HIG Best practices: "Show a hint in a text field to help communicate
              # its purpose." -- placeholder for empty, filled value where appropriate.
              # iOS: "Display a Clear button in the trailing end."

              ios_tf_stack = UI::VStack.new(spacing: 12.0)
              ios_tf_stack.alignment = UI::Alignment::Leading
              ios_tf_stack.minimum_width = 312.0
              ios_tf_stack.maximum_width = 312.0
              ios_tf_stack.padding = UI::EdgeInsets.new(top: 14.0, trailing: 16.0, bottom: 14.0, leading: 16.0)
              ios_tf_stack << UI::Label.new("Profile details").tap { |l| l.font = UI::Font.new(size: 17.0, weight: :semibold) }

              # Row 1: Name (empty, placeholder)
              ios_row1 = UI::VStack.new(spacing: 3.0)
              ios_row1.alignment = UI::Alignment::Leading
              ios_lbl1 = UI::Label.new("Name:")
              ios_lbl1.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_lbl1.accessibility_label = "Name label"
              ios_tf1 = UI::TextField.new("Your name")
              ios_tf1.minimum_width = 260.0
              ios_tf1.accessibility_label = "Name field"
              ios_row1 << ios_lbl1.as(UI::View)
              ios_row1 << ios_tf1.as(UI::View)
              ios_tf_stack << ios_row1.as(UI::View)

              # Row 2: Email (filled)
              ios_row2 = UI::VStack.new(spacing: 3.0)
              ios_row2.alignment = UI::Alignment::Leading
              ios_lbl2 = UI::Label.new("Email:")
              ios_lbl2.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_lbl2.accessibility_label = "Email label"
              ios_tf2 = UI::TextField.new("Email address")
              ios_tf2.text = "alice@example.com"
              ios_tf2.minimum_width = 260.0
              ios_tf2.keyboard_type = UI::KeyboardType::EmailAddress
              ios_tf2.accessibility_label = "Email field"
              ios_row2 << ios_lbl2.as(UI::View)
              ios_row2 << ios_tf2.as(UI::View)
              ios_tf_stack << ios_row2.as(UI::View)

              # Row 3: Password (secure entry)
              ios_row3 = UI::VStack.new(spacing: 3.0)
              ios_row3.alignment = UI::Alignment::Leading
              ios_lbl3 = UI::Label.new("Password:")
              ios_lbl3.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_lbl3.accessibility_label = "Password label"
              ios_tf3 = UI::TextField.new("Password")
              ios_tf3.secure_entry = true
              ios_tf3.text = "secretpassword"
              ios_tf3.minimum_width = 260.0
              ios_tf3.accessibility_label = "Password field"
              ios_row3 << ios_lbl3.as(UI::View)
              ios_row3 << ios_tf3.as(UI::View)
              ios_tf_stack << ios_row3.as(UI::View)

              # Row 4: Numeric (number pad keyboard)
              ios_row4 = UI::VStack.new(spacing: 3.0)
              ios_row4.alignment = UI::Alignment::Leading
              ios_lbl4 = UI::Label.new("Amount:")
              ios_lbl4.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_lbl4.accessibility_label = "Amount label"
              ios_tf4 = UI::TextField.new("0.00")
              ios_tf4.minimum_width = 160.0
              ios_tf4.keyboard_type = UI::KeyboardType::NumberPad
              ios_tf4.accessibility_label = "Amount field"
              ios_row4 << ios_lbl4.as(UI::View)
              ios_row4 << ios_tf4.as(UI::View)
              ios_tf_stack << ios_row4.as(UI::View)

              ios_tf_stack.as(UI::View)
            when "text-views"
              # HIG text-views: multi-line scrollable text on iOS UITextView.
              # HIG Best practices: "Use a text view when you need to display
              # text that's long, editable, or in a special format."
              # iOS / iPadOS: UITextView -- non-editable by default for read-only.

              ios_tv_stack = UI::VStack.new(spacing: 12.0)
              ios_tv_stack.minimum_width = 304.0
              ios_tv_stack.maximum_width = 304.0

              ios_tv_title = UI::Label.new("Reading surface")
              ios_tv_title.font = UI::Font.new(size: 16.0, weight: :semibold)
              ios_tv_title.accessibility_label = "Text views showcase title"
              ios_tv_stack << ios_tv_title

              ios_tv_desc = UI::Label.new("Short notes stay calm, legible, and easy to scan.")
              ios_tv_desc.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_tv_desc.text_color_role = UI::LabelRole::Secondary
              ios_tv_desc.accessibility_label = "Text views description"
              ios_tv_stack << ios_tv_desc

              ios_row1_lbl = UI::Label.new("Read-only")
              ios_row1_lbl.font = UI::Font.new(size: 13.0, weight: :semibold)
              ios_row1_lbl.text_color_role = UI::LabelRole::Secondary
              ios_row1_lbl.accessibility_label = "Read-only paragraph label"
              ios_tv_stack << ios_row1_lbl.as(UI::View)

              ios_tv1 = UI::RichText.new
              ios_tv1.add_span("Amber notes stay readable when the copy is short, wrapped, and left aligned.")
              ios_tv1.accessibility_label = "Read-only text view"
              ios_tv_stack << ios_tv1.as(UI::View)

              ios_row2_lbl = UI::Label.new("Editable")
              ios_row2_lbl.font = UI::Font.new(size: 13.0, weight: :semibold)
              ios_row2_lbl.text_color_role = UI::LabelRole::Secondary
              ios_row2_lbl.accessibility_label = "Attributed text label"
              ios_tv_stack << ios_row2_lbl.as(UI::View)

              ios_tv2 = UI::RichText.new
              ios_tv2.add_span("Quick draft: ", bold: true, italic: false)
              ios_tv2.add_span("shape the copy, trim the noise, and keep the rhythm calm.", bold: false, italic: false)
              ios_tv2.accessibility_label = "Attributed text view"
              ios_tv_stack << ios_tv2.as(UI::View)

              ios_tv_stack.as(UI::View)
            when "labels"
              # HIG Labels: 8-row typographic gallery exercising all four
              # LabelRole semantic color tokens (iteration-18 contract) plus
              # the full HIG text-size ladder approximated via font size+weight.
              # LabelRole tokens resolve to UIColor.labelColor /
              # secondaryLabelColor / tertiaryLabelColor / quaternaryLabelColor
              # at render time, tracking light/dark automatically.
              labels_stack = UI::VStack.new(spacing: 9.0)
              labels_stack.minimum_width = 288.0
              labels_stack.maximum_width = 288.0

              labels_title = UI::Label.new("Typography scale")
              labels_title.font = UI::Font.new(size: 16.0, weight: :semibold)
              labels_title.accessibility_label = "Labels showcase title"
              labels_stack << labels_title

              labels_desc = UI::Label.new("Amber text stays crisp at every weight.")
              labels_desc.font = UI::Font.new(size: 13.0, weight: :regular)
              labels_desc.text_color_role = UI::LabelRole::Secondary
              labels_desc.accessibility_label = "Labels description"
              labels_stack << labels_desc

              labels_row1 = UI::HStack.new(spacing: 10.0)
              labels_row1.alignment = UI::Alignment::Center
              labels_row1.minimum_width = 288.0
              labels_row1.maximum_width = 288.0
              labels_row1_style = UI::Label.new("Large title")
              labels_row1_style.font = UI::Font.new(size: 11.0, weight: :regular)
              labels_row1_style.text_color_role = UI::LabelRole::Secondary
              labels_row1_style.minimum_width = 78.0
              labels_row1_style.maximum_width = 78.0
              labels_row1 << labels_row1_style.as(UI::View)
              labels_row1_sample = UI::Label.new("Notes")
              labels_row1_sample.font = UI::Font.new(size: 28.0, weight: :bold)
              labels_row1_sample.text_color_role = UI::LabelRole::Primary
              labels_row1_sample.number_of_lines = 0
              labels_row1 << labels_row1_sample.as(UI::View)
              labels_stack << labels_row1.as(UI::View)

              labels_row2 = UI::HStack.new(spacing: 10.0)
              labels_row2.alignment = UI::Alignment::Center
              labels_row2.minimum_width = 288.0
              labels_row2.maximum_width = 288.0
              labels_row2_style = UI::Label.new("Headline")
              labels_row2_style.font = UI::Font.new(size: 11.0, weight: :regular)
              labels_row2_style.text_color_role = UI::LabelRole::Secondary
              labels_row2_style.minimum_width = 78.0
              labels_row2_style.maximum_width = 78.0
              labels_row2 << labels_row2_style.as(UI::View)
              labels_row2_sample = UI::Label.new("Today")
              labels_row2_sample.font = UI::Font.new(size: 18.0, weight: :semibold)
              labels_row2_sample.text_color_role = UI::LabelRole::Primary
              labels_row2_sample.number_of_lines = 0
              labels_row2 << labels_row2_sample.as(UI::View)
              labels_stack << labels_row2.as(UI::View)

              labels_row3 = UI::HStack.new(spacing: 10.0)
              labels_row3.alignment = UI::Alignment::Center
              labels_row3.minimum_width = 288.0
              labels_row3.maximum_width = 288.0
              labels_row3_style = UI::Label.new("Body")
              labels_row3_style.font = UI::Font.new(size: 11.0, weight: :regular)
              labels_row3_style.text_color_role = UI::LabelRole::Secondary
              labels_row3_style.minimum_width = 78.0
              labels_row3_style.maximum_width = 78.0
              labels_row3 << labels_row3_style.as(UI::View)
              labels_row3_sample = UI::Label.new("Pinned")
              labels_row3_sample.font = UI::Font.new(size: 17.0, weight: :regular)
              labels_row3_sample.text_color_role = UI::LabelRole::Primary
              labels_row3_sample.number_of_lines = 0
              labels_row3 << labels_row3_sample.as(UI::View)
              labels_stack << labels_row3.as(UI::View)

              labels_row4 = UI::HStack.new(spacing: 10.0)
              labels_row4.alignment = UI::Alignment::Center
              labels_row4.minimum_width = 288.0
              labels_row4.maximum_width = 288.0
              labels_row4_style = UI::Label.new("Secondary")
              labels_row4_style.font = UI::Font.new(size: 11.0, weight: :regular)
              labels_row4_style.text_color_role = UI::LabelRole::Secondary
              labels_row4_style.minimum_width = 78.0
              labels_row4_style.maximum_width = 78.0
              labels_row4 << labels_row4_style.as(UI::View)
              labels_row4_sample = UI::Label.new("Synced 2m ago")
              labels_row4_sample.font = UI::Font.new(size: 15.0, weight: :regular)
              labels_row4_sample.text_color_role = UI::LabelRole::Secondary
              labels_row4_sample.number_of_lines = 0
              labels_row4 << labels_row4_sample.as(UI::View)
              labels_stack << labels_row4.as(UI::View)

              labels_row5 = UI::HStack.new(spacing: 10.0)
              labels_row5.alignment = UI::Alignment::Center
              labels_row5.minimum_width = 288.0
              labels_row5.maximum_width = 288.0
              labels_row5_style = UI::Label.new("Caption")
              labels_row5_style.font = UI::Font.new(size: 11.0, weight: :regular)
              labels_row5_style.text_color_role = UI::LabelRole::Secondary
              labels_row5_style.minimum_width = 78.0
              labels_row5_style.maximum_width = 78.0
              labels_row5 << labels_row5_style.as(UI::View)
              labels_row5_sample = UI::Label.new("Meta")
              labels_row5_sample.font = UI::Font.new(size: 12.0, weight: :regular)
              labels_row5_sample.text_color_role = UI::LabelRole::Quaternary
              labels_row5_sample.number_of_lines = 0
              labels_row5 << labels_row5_sample.as(UI::View)
              labels_stack << labels_row5.as(UI::View)

              labels_row6 = UI::HStack.new(spacing: 10.0)
              labels_row6.alignment = UI::Alignment::Center
              labels_row6.minimum_width = 288.0
              labels_row6.maximum_width = 288.0
              labels_row6_style = UI::Label.new("Wrap")
              labels_row6_style.font = UI::Font.new(size: 11.0, weight: :regular)
              labels_row6_style.text_color_role = UI::LabelRole::Secondary
              labels_row6_style.minimum_width = 78.0
              labels_row6_style.maximum_width = 78.0
              labels_row6 << labels_row6_style.as(UI::View)
              labels_row6_sample = UI::Label.new("Wrap stays neat in a narrow column.")
              labels_row6_sample.font = UI::Font.new(size: 15.0, weight: :regular)
              labels_row6_sample.text_color_role = UI::LabelRole::Tertiary
              labels_row6_sample.number_of_lines = 0
              labels_row6 << labels_row6_sample.as(UI::View)
              labels_stack << labels_row6.as(UI::View)

              labels_stack.as(UI::View)
            when "sliders"
              # HIG Sliders: UISlider -- horizontal track, filled leading portion in
              # minimumTrackTintColor, circular rubber thumb.
              # Best practices: "Customize a slider's appearance if it adds value."
              # Best practices: "Use familiar slider directions" -- min leading, max trailing.
              # Showcase: four variants -- plain, labeled, volume-style SF Symbol, tinted.

              ios_sliders_stack = UI::VStack.new(spacing: 12.0)
              ios_sliders_stack.minimum_width = 300.0
              ios_sliders_stack.maximum_width = 300.0

              # Section title
              ios_sl_title = UI::Label.new("Amber sound mix")
              ios_sl_title.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_sl_title.text_color_role = UI::LabelRole::Primary
              ios_sl_title.accessibility_label = "Sliders showcase title"
              ios_sliders_stack << ios_sl_title

              # Variant 1: Plain slider at 40%
              ios_v1_cap = UI::Label.new("Ambient volume")
              ios_v1_cap.font = UI::Font.new(size: 11.0, weight: :regular)
              ios_v1_cap.text_color_role = UI::LabelRole::Secondary
              ios_v1_cap.accessibility_label = "Plain slider caption"
              ios_sliders_stack << ios_v1_cap

              ios_plain = UI::Slider.new(0.0, 100.0, 40.0)
              ios_plain.minimum_width = 228.0
              ios_plain.maximum_width = 228.0
              ios_plain.accessibility_label = "Plain slider at 40 percent"
              ios_sliders_stack << ios_plain

              # Variant 2: Labeled slider with min/max text and current value
              ios_v2_cap = UI::Label.new("Min / max labels")
              ios_v2_cap.font = UI::Font.new(size: 11.0, weight: :regular)
              ios_v2_cap.text_color_role = UI::LabelRole::Secondary
              ios_v2_cap.accessibility_label = "Labeled slider caption"
              ios_sliders_stack << ios_v2_cap

              ios_labeled_row = UI::HStack.new(spacing: 8.0)
              ios_labeled_row.alignment = UI::Alignment::Center
              ios_min_lbl = UI::Label.new("0")
              ios_min_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_min_lbl.text_color_role = UI::LabelRole::Secondary
              ios_labeled_row << ios_min_lbl

              ios_labeled_sl = UI::Slider.new(0.0, 100.0, 65.0)
              ios_labeled_sl.minimum_width = 180.0
              ios_labeled_sl.maximum_width = 180.0
              ios_labeled_sl.accessibility_label = "Brightness slider at 65 percent"
              ios_labeled_row << ios_labeled_sl

              ios_max_lbl = UI::Label.new("100")
              ios_max_lbl.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_max_lbl.text_color_role = UI::LabelRole::Secondary
              ios_labeled_row << ios_max_lbl
              ios_sliders_stack << ios_labeled_row

              # Variant 3: Volume-style slider with SF Symbol icons
              ios_v3_cap = UI::Label.new("Playback volume")
              ios_v3_cap.font = UI::Font.new(size: 11.0, weight: :regular)
              ios_v3_cap.text_color_role = UI::LabelRole::Secondary
              ios_v3_cap.accessibility_label = "Volume slider caption"
              ios_sliders_stack << ios_v3_cap

              ios_vol_row = UI::HStack.new(spacing: 8.0)
              ios_vol_row.alignment = UI::Alignment::Center
              ios_vol_min = UI::Image.new("speaker.slash")
              ios_vol_min.accessibility_label = "Speaker off"
              ios_vol_row << ios_vol_min

              ios_vol_sl = UI::Slider.new(0.0, 1.0, 0.55)
              ios_vol_sl.minimum_width = 176.0
              ios_vol_sl.maximum_width = 176.0
              ios_vol_sl.accessibility_label = "Volume slider at 55 percent"
              ios_vol_row << ios_vol_sl

              ios_vol_max = UI::Image.new("speaker.wave.3")
              ios_vol_max.accessibility_label = "Speaker full volume"
              ios_vol_row << ios_vol_max
              ios_sliders_stack << ios_vol_row

              # Variant 4: Tinted slider (brand orange)
              ios_v4_cap = UI::Label.new("Tinted track")
              ios_v4_cap.font = UI::Font.new(size: 11.0, weight: :regular)
              ios_v4_cap.text_color_role = UI::LabelRole::Secondary
              ios_v4_cap.accessibility_label = "Tinted slider caption"
              ios_sliders_stack << ios_v4_cap

              ios_tinted = UI::Slider.new(0.0, 100.0, 75.0)
              ios_tinted.minimum_width = 228.0
              ios_tinted.maximum_width = 228.0
              ios_tinted.tint_color = UI::Color.new(r: 1.0, g: 0.584, b: 0.0)
              ios_tinted.accessibility_label = "Tinted slider at 75 percent"
              ios_sliders_stack << ios_tinted

              ios_sliders_stack.as(UI::View)
            when "steppers"
              # Keep the value-and-stepper pairs compact and centered so the
              # control reads as a small study rather than a form dump.
              ios_steppers_body = UI::VStack.new(spacing: 12.0)
              ios_steppers_body.alignment = UI::Alignment::Leading
              ios_steppers_body.minimum_width = 272.0
              ios_steppers_body.maximum_width = 272.0

              ios_steppers_title = UI::Label.new("Steppers")
              ios_steppers_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_steppers_title.accessibility_label = "Steppers showcase title"
              ios_steppers_body << ios_steppers_title

              ios_steppers_desc = UI::Label.new("Pair the control with a value label.")
              ios_steppers_desc.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_steppers_desc.text_color_role = UI::LabelRole::Secondary
              ios_steppers_desc.number_of_lines = 0
              ios_steppers_desc.accessibility_label = "Steppers showcase description"
              ios_steppers_body << ios_steppers_desc

              # Row 1: normal state, value 3, range 0-10
              ios_row1_label = UI::Label.new("Quantity 3")
              ios_row1_label.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_row1_label.accessibility_label = "Quantity label, value 3"

              ios_row1_stepper = UI::Stepper.new(0.0, 10.0, 3.0)
              ios_row1_stepper.step_value = 1.0
              ios_row1_stepper.accessibility_label = "Quantity stepper, value 3"

              ios_row1 = UI::HStack.new(spacing: 8.0)
              ios_row1 << ios_row1_label
              ios_row1 << UI::Spacer.new.as(UI::View)
              ios_row1 << ios_row1_stepper
              ios_steppers_body << ios_row1.as(UI::View)

              # Row 2: at minimum -- minus segment auto-dimmed by UIStepper
              ios_row2_label = UI::Label.new("Minimum 0")
              ios_row2_label.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_row2_label.accessibility_label = "At minimum label, value 0"

              ios_row2_stepper = UI::Stepper.new(0.0, 10.0, 0.0)
              ios_row2_stepper.step_value = 1.0
              ios_row2_stepper.accessibility_label = "Stepper at minimum, value 0, minus disabled"

              ios_row2 = UI::HStack.new(spacing: 8.0)
              ios_row2 << ios_row2_label
              ios_row2 << UI::Spacer.new.as(UI::View)
              ios_row2 << ios_row2_stepper
              ios_steppers_body << ios_row2.as(UI::View)

              # Row 3: at maximum -- plus segment auto-dimmed by UIStepper
              ios_row3_label = UI::Label.new("Maximum 10")
              ios_row3_label.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_row3_label.accessibility_label = "At maximum label, value 10"

              ios_row3_stepper = UI::Stepper.new(0.0, 10.0, 10.0)
              ios_row3_stepper.step_value = 1.0
              ios_row3_stepper.accessibility_label = "Stepper at maximum, value 10, plus disabled"

              ios_row3 = UI::HStack.new(spacing: 8.0)
              ios_row3 << ios_row3_label
              ios_row3 << UI::Spacer.new.as(UI::View)
              ios_row3 << ios_row3_stepper
              ios_steppers_body << ios_row3.as(UI::View)

              centered_study_card(ios_steppers_body.as(UI::View), card_width: 320.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
            when "segmented-controls"
              # HIG: "A segmented control is a linear set of two or more segments,
              # each of which functions as a button." UISegmentedControl renders as
              # a pill-shaped grouped control; the selected segment has a filled
              # backing (system-tinted on iOS 26) in both light and dark appearances.
              # Showcase: text-only (Day/Week/Month, Week selected at index 1) plus
              # a compact layout-choice variant (4 segments, index 1 selected).
              # HIG: "Limit the number of segments in a control." -- 3 and 4 here.
              # HIG: "Use nouns or noun phrases for segment labels."

              ios_sc_outer = UI::VStack.new(spacing: 10.0)
              ios_sc_outer.minimum_width = 296.0
              ios_sc_outer.maximum_width = 296.0

              ios_sc_title = UI::Label.new("Selection style")
              ios_sc_title.font = UI::Font.new(size: 16.0, weight: :semibold)
              ios_sc_title.accessibility_label = "Segmented Controls showcase title"
              ios_sc_outer << ios_sc_title

              ios_sc_desc = UI::Label.new("Short nouns keep the control calm and readable.")
              ios_sc_desc.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_sc_desc.text_color_role = UI::LabelRole::Secondary
              ios_sc_desc.accessibility_label = "Segmented controls description"
              ios_sc_outer << ios_sc_desc

              ios_sc_text_caption = UI::Label.new("Text segments (Week selected, index 1)")
              ios_sc_text_caption.font = UI::Font.new(size: 11.0, weight: :regular)
              ios_sc_text_caption.accessibility_label = "Text segments caption"
              ios_sc_outer << ios_sc_text_caption

              # Text-only: 3 segments, index 1 (Week) selected -- HIG-aligned default
              ios_sc_text = UI::SegmentedControl.new(["Day", "Week", "Month"], 1)
              ios_sc_text.accessibility_label = "Day Week Month segmented control"
              ios_sc_outer << ios_sc_text

              ios_sc_icon_caption = UI::Label.new("Layout segments (4 segments, index 1 selected)")
              ios_sc_icon_caption.font = UI::Font.new(size: 11.0, weight: :regular)
              ios_sc_icon_caption.accessibility_label = "Icon segments caption"
              ios_sc_outer << ios_sc_icon_caption

              # Variant: 4 short labels, index 1 selected.
              ios_sc_icon = UI::SegmentedControl.new(
                ["List", "Grid", "Cards", "Stack"], 1
              )
              ios_sc_icon.accessibility_label = "Icon segmented control"
              ios_sc_outer << ios_sc_icon
              ios_sc_outer.as(UI::View)
            when "progress-indicators"
              # HIG: "Progress indicators let people know that your app isn't
              # stalled while it loads content or performs lengthy operations."
              # Gallery: spinner (medium), spinner (large, tinted), linear
              # determinate at 60%, linear indeterminate, labeled upload row
              # with cancel button.
              # HIG: "When possible, use a determinate progress indicator."
              # HIG: "If it's helpful, display a description that provides
              # additional context for the task."
              ios_gallery = UI::VStack.new(spacing: 16.0)
              ios_gallery.alignment = UI::Alignment::Leading
              ios_gallery.minimum_width = 318.0
              ios_gallery.maximum_width = 318.0
              ios_gallery.padding = UI::EdgeInsets.new(top: 10.0, trailing: 16.0, bottom: 10.0, leading: 16.0)

              # --- Section: Spinners ---
              ios_spinner_hdr = UI::Label.new("Loading")
              ios_spinner_hdr.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_spinner_hdr.accessibility_label = "Spinners section header"
              ios_gallery << ios_spinner_hdr

              ios_spinner_row = UI::HStack.new(spacing: 28.0)
              ios_spinner_row.alignment = UI::Alignment::Center

              # Medium spinner (UIActivityIndicatorViewStyle.medium = 100)
              ios_med = UI::ActivityIndicator.new(true, :medium)
              ios_med.accessibility_label = "Loading indicator medium"
              ios_spinner_row << ios_med

              # Large spinner, tinted with the Amber role color.
              ios_lg = UI::ActivityIndicator.new(true, :large)
              ios_lg.color = UI::Color.new(r: 1.0, g: 0.678, b: 0.2, a: 1.0)
              ios_lg.accessibility_label = "Loading indicator large"
              ios_spinner_row << ios_lg

              ios_gallery << ios_spinner_row

              # --- Section: Linear determinate at 60% ---
              ios_bar_hdr = UI::Label.new("Transfer")
              ios_bar_hdr.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_bar_hdr.accessibility_label = "Linear progress section header"
              ios_gallery << ios_bar_hdr

              ios_det_bar = UI::ProgressView.new(0.6, UI::ProgressStyle::Linear)
              ios_det_bar.label = "Uploading... 60%"
              ios_det_bar.minimum_width = 260.0
              ios_det_bar.accessibility_label = "Upload progress 60 percent"
              ios_gallery << ios_det_bar

              ios_det_lbl = UI::Label.new("Uploading... 60%")
              ios_det_lbl.font = UI::Font.new(size: 15.0, weight: :regular)
              ios_det_lbl.accessibility_label = "Upload progress label"
              ios_gallery << ios_det_lbl

              # --- Section: Linear indeterminate ---
              ios_indet_hdr = UI::Label.new("Syncing")
              ios_indet_hdr.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_indet_hdr.accessibility_label = "Indeterminate progress section header"
              ios_gallery << ios_indet_hdr

              ios_indet_bar = UI::ProgressView.new(nil, UI::ProgressStyle::Linear)
              ios_indet_bar.label = "Syncing..."
              ios_indet_bar.minimum_width = 260.0
              ios_indet_bar.accessibility_label = "Syncing progress indeterminate"
              ios_gallery << ios_indet_bar

              ios_indet_lbl = UI::Label.new("Syncing...")
              ios_indet_lbl.font = UI::Font.new(size: 15.0, weight: :regular)
              ios_indet_lbl.accessibility_label = "Syncing status label"
              ios_gallery << ios_indet_lbl

              # --- Section: Labeled upload row with cancel ---
              ios_upload_hdr = UI::Label.new("Upload")
              ios_upload_hdr.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_upload_hdr.accessibility_label = "Upload with cancel section header"
              ios_gallery << ios_upload_hdr

              ios_upload_row = UI::HStack.new(spacing: 12.0)
              ios_upload_row.alignment = UI::Alignment::Center
              ios_upload_lbl = UI::Label.new("Uploading archive.zip")
              ios_upload_lbl.font = UI::Font.new(size: 15.0, weight: :regular)
              ios_upload_lbl.accessibility_label = "Upload filename"
              ios_upload_row << ios_upload_lbl
              ios_upload_row << UI::Spacer.new.as(UI::View)
              ios_cancel_btn = UI::Button.new("Cancel")
              ios_cancel_btn.role = :cancel
              ios_cancel_btn.accessibility_label = "Cancel upload"
              ios_upload_row << ios_cancel_btn
              ios_gallery << ios_upload_row
              ios_upload_bar = UI::ProgressView.new(0.6, UI::ProgressStyle::Linear)
              ios_upload_bar.minimum_width = 260.0
              ios_gallery << ios_upload_bar.as(UI::View)

              ios_gallery.as(UI::View)
            when "activity-indicators" then UI::ActivityIndicator.new(true, :medium).as(UI::View)
            when "popovers"
              # HIG: "A popover is a transient view that appears above other content
              # when people click or tap a control or interactive area."
              # HIG Best practices: "Use a popover to expose a small amount of
              # information or functionality." -- Popovers / Best practices.
              #
              # Rendered inline (is_presented == false) for screenshot isolation.
              # Content: realistic filter panel -- title + two radio-style picker
              # options + "Clear filters" button at bottom. Mirrors the macOS arm.
              # iOS 26: UIVisualEffectView(UIGlassEffect) or UIBlurEffect(style:11)
              # wrapping a UIStackView, corner radius ~10pt.
              ios_popover_content = UI::VStack.new(spacing: 12.0)
              ios_popover_content.minimum_width = 252.0
              ios_popover_content.maximum_width = 252.0

              ios_filter_title = UI::Label.new("Filter")
              ios_filter_title.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_filter_title.accessibility_label = "Filter panel title"
              ios_popover_content << ios_filter_title

              ios_pop_div = UI::Divider.new(:horizontal)
              ios_popover_content << ios_pop_div

              ios_popover_content << popover_option_group("Sort by", [
                {"Newest", true},
                {"Oldest", false},
              ])

              ios_popover_content << popover_option_group("Vault", [
                {"Morning Pages", false},
                {"All vaults", true},
              ])

              ios_pop_div2 = UI::Divider.new(:horizontal)
              ios_popover_content << ios_pop_div2

              ios_clear_btn = UI::Button.new("Clear filters", role: :default)
              ios_clear_btn.accessibility_label = "Clear filters"
              ios_popover_content << ios_clear_btn

              ios_popover = UI::Popover.new(ios_popover_content.as(UI::View), :bottom)
              ios_popover.minimum_width = 272.0
              ios_popover.maximum_width = 272.0
              ios_popover.as(UI::View)
            when "pickers"
              # HIG: "For short lists, consider using a menu or segmented control
              # instead of a wheel picker." iOS renderer uses inline-list-with-
              # checkmarks (iOS Settings style) for static option sets. This is
              # legible in both light and dark appearances with no data-source wiring.
              picker_options = ["United States", "Canada", "Mexico",
                                "United Kingdom", "Germany"]
              picker = UI::Picker.new(picker_options, 0)
              picker.label = "Country"
              picker.accessibility_label = "Country picker"

              container = UI::VStack.new(spacing: 16.0)
              container << UI::Label.new("Select a country")
              container << picker
              container.as(UI::View)
            when "pop-up-buttons"
              # Keep the pop-up button examples compact and grouped so the
              # buttons stay centered with more of the amber backdrop visible.
              ios_popup_body = UI::VStack.new(spacing: 12.0)
              ios_popup_body.alignment = UI::Alignment::Leading
              ios_popup_body.minimum_width = 280.0
              ios_popup_body.maximum_width = 280.0

              ios_popup_title = UI::Label.new("Pop-up buttons")
              ios_popup_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_popup_title.accessibility_label = "Pop-up buttons showcase title"
              ios_popup_body << ios_popup_title

              ios_popup_desc = UI::Label.new("Choose from a short, flat list.")
              ios_popup_desc.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_popup_desc.text_color_role = UI::LabelRole::Secondary
              ios_popup_desc.number_of_lines = 0
              ios_popup_desc.accessibility_label = "Pop-up buttons showcase description"
              ios_popup_body << ios_popup_desc

              # Row 1: Alignment pop-up
              ios_row1_label = UI::Label.new("Alignment")
              ios_row1_label.font = UI::Font.new(size: 14.0, weight: :regular)
              ios_row1_btn = UI::MenuButton.new("Alignment")
              ios_row1_btn.add_item("Left")
              ios_row1_btn.add_item("Center")
              ios_row1_btn.add_item("Right")
              ios_row1_btn.add_item("Justified")
              ios_row1_btn.selected_index = 0
              ios_row1_btn.accessibility_label = "Alignment, pop-up button"
              ios_row1 = UI::HStack.new(spacing: 8.0)
              ios_row1 << ios_row1_label
              ios_row1 << UI::Spacer.new.as(UI::View)
              ios_row1 << ios_row1_btn
              ios_popup_body << ios_row1.as(UI::View)

              # Row 2: Font size pop-up (12pt selected)
              ios_row2_label = UI::Label.new("Font size")
              ios_row2_label.font = UI::Font.new(size: 14.0, weight: :regular)
              ios_row2_btn = UI::MenuButton.new("Font size")
              ios_row2_btn.add_item("9pt")
              ios_row2_btn.add_item("10pt")
              ios_row2_btn.add_item("11pt")
              ios_row2_btn.add_item("12pt")
              ios_row2_btn.add_item("14pt")
              ios_row2_btn.add_item("18pt")
              ios_row2_btn.selected_index = 3
              ios_row2_btn.accessibility_label = "Font size, pop-up button"
              ios_row2 = UI::HStack.new(spacing: 8.0)
              ios_row2 << ios_row2_label
              ios_row2 << UI::Spacer.new.as(UI::View)
              ios_row2 << ios_row2_btn
              ios_popup_body << ios_row2.as(UI::View)

              # Row 3: Theme pop-up (Auto selected)
              ios_row3_label = UI::Label.new("Theme")
              ios_row3_label.font = UI::Font.new(size: 14.0, weight: :regular)
              ios_row3_btn = UI::MenuButton.new("Theme")
              ios_row3_btn.add_item("Auto")
              ios_row3_btn.add_item("Light")
              ios_row3_btn.add_item("Dark")
              ios_row3_btn.selected_index = 0
              ios_row3_btn.accessibility_label = "Theme, pop-up button"
              ios_row3 = UI::HStack.new(spacing: 8.0)
              ios_row3 << ios_row3_label
              ios_row3 << UI::Spacer.new.as(UI::View)
              ios_row3 << ios_row3_btn
              ios_popup_body << ios_row3.as(UI::View)

              centered_study_card(ios_popup_body.as(UI::View), card_width: 332.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
            when "token-fields"
              # HIG token fields: a compact recipient-entry surface with chips,
              # a clear insertion point, and a short prompt.
              ios_token_field = UI::TokenField.new(
                [
                  UI::TokenField::Token.new("Ava", "person.fill"),
                  UI::TokenField::Token.new("Design"),
                ],
                "Name or email",
                "Recipients",
                "Add people or tags"
              )
              ios_token_field.selected_indexes = [0]
              ios_token_field.chip_spacing = 6.0
              ios_token_field.row_spacing = 8.0
              ios_token_field.chip_padding = UI::EdgeInsets.new(top: 5.0, trailing: 8.0, bottom: 5.0, leading: 8.0)
              ios_token_field.input_min_width = 112.0
              ios_token_field.input_max_width = 136.0
              ios_token_field.viewport_width = 272.0
              ios_token_field.viewport_height = 0.0
              ios_token_field.accessibility_label = "Recipients token field"
              ios_token_field.as(UI::View)
            when "image-wells"
              # HIG image wells: a centered, compact replacement surface for
              # profile photos or artwork. The image area stays visually framed
              # while the amber backdrop remains visible around it.
              ios_image_well = UI::ImageWell.new(
                nil,
                "Profile photo",
                "Choose a photo",
                "Square crop recommended.",
                "Drag here or choose from Photos."
              )
              ios_image_well.placeholder_icon = "person.crop.square"
              ios_image_well.well_width = 212.0
              ios_image_well.well_height = 152.0
              ios_image_well.preview_padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
              ios_image_well.viewport_width = 272.0
              ios_image_well.viewport_height = 0.0
              ios_image_well.accessibility_label = "Profile photo image well"
              ios_image_well.as(UI::View)
            when "gauges"
              # HIG gauges: a compact circular instrument that communicates a
              # single status metric at a glance without turning into a dense
              # dashboard.
              ios_gauge = UI::Gauge.new(
                72.0,
                0.0,
                100.0,
                "Battery reserve",
                "Quiet status at a glance",
                "Updated 2m ago",
                nil
              )
              ios_gauge.units = "%"
              ios_gauge.value_precision = 0
              ios_gauge.diameter = 156.0
              ios_gauge.ring_thickness = 12.0
              ios_gauge.track_color = UI::Color.new(r: 0.88, g: 0.83, b: 0.76)
              ios_gauge.progress_color = UI::Color.new(r: 0.84, g: 0.49, b: 0.12)
              ios_gauge.viewport_width = 280.0
              ios_gauge.viewport_height = 0.0
              ios_gauge.accessibility_label = "Battery reserve gauge"
              ios_gauge.as(UI::View)
            when "activity-rings"
              # HIG activity rings: a centered watch-style fitness summary that
              # needs a black field so the colored rings can breathe without
              # crowding the frame.
              ios_rings = UI::ActivityRings.new(0.82, 0.66, 0.58)
              ios_rings.size = 168.0
              ios_rings.thickness = 16.0
              ios_rings.gap = 6.0
              ios_rings.accessibility_label = "Activity rings summary"

              ios_rings_title = UI::Label.new("Activity rings")
              ios_rings_title.font = UI::Font.new(size: 17.0, weight: :semibold)

              ios_rings_subtitle = UI::Label.new("A centered study that keeps the black field and ring margins intact.")
              ios_rings_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_rings_subtitle.text_color_role = UI::LabelRole::Secondary
              ios_rings_subtitle.number_of_lines = 0

              ios_rings_body = UI::VStack.new(spacing: 12.0)
              ios_rings_body.alignment = UI::Alignment::Center
              ios_rings_body << ios_rings_title
              ios_rings_body << ios_rings_subtitle
              ios_rings_body << ios_rings.as(UI::View)
              ios_rings_body.as(UI::View)
            when "pull-down-buttons"
              # Keep the pull-down buttons grouped into one calmer study card.
              ios_pd_body = UI::VStack.new(spacing: 12.0)
              ios_pd_body.alignment = UI::Alignment::Leading
              ios_pd_body.minimum_width = 280.0
              ios_pd_body.maximum_width = 280.0

              ios_pd_title = UI::Label.new("Pull-down buttons")
              ios_pd_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_pd_title.accessibility_label = "Pull-down buttons showcase title"
              ios_pd_body << ios_pd_title

              ios_pd_desc = UI::Label.new("Primary actions with attached menus.")
              ios_pd_desc.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_pd_desc.text_color_role = UI::LabelRole::Secondary
              ios_pd_desc.number_of_lines = 0
              ios_pd_desc.accessibility_label = "Pull-down buttons showcase description"
              ios_pd_body << ios_pd_desc

              # --- 1. Add pull-down ---
              ios_add_btn = UI::MenuButton.new("Add")
              ios_add_btn.is_pull_down = true
              ios_add_btn.add_item("New Folder")
              ios_add_btn.add_item("New Document")
              ios_add_btn.add_item("New Template")
              ios_add_btn.add_item("Import\u2026")
              ios_add_btn.accessibility_label = "Add, pull-down button"
              ios_pd_row1 = UI::HStack.new(spacing: 8.0)
              ios_pd_row1 << UI::Label.new("Create").as(UI::View)
              ios_pd_row1 << UI::Spacer.new.as(UI::View)
              ios_pd_row1 << ios_add_btn
              ios_pd_body << ios_pd_row1.as(UI::View)

              # --- 2. Ellipsis more-actions ---
              ios_more_btn = UI::MenuButton.new("\u2026")
              ios_more_btn.is_pull_down = true
              ios_more_btn.add_item("Duplicate")
              ios_more_btn.add_item("Rename")
              ios_more_btn.add_item("Move\u2026")
              ios_more_btn.add_item("Delete", is_destructive: true)
              ios_more_btn.accessibility_label = "More actions, pull-down button"
              ios_pd_row2 = UI::HStack.new(spacing: 8.0)
              ios_pd_row2 << UI::Label.new("Item").as(UI::View)
              ios_pd_row2 << UI::Spacer.new.as(UI::View)
              ios_pd_row2 << ios_more_btn
              ios_pd_body << ios_pd_row2.as(UI::View)

              # --- 3. Export pull-down (prominent) ---
              ios_export_btn = UI::MenuButton.new("Export")
              ios_export_btn.is_pull_down = true
              ios_export_btn.button_style = :prominent
              ios_export_btn.add_item("PDF")
              ios_export_btn.add_item("CSV")
              ios_export_btn.add_item("HTML")
              ios_export_btn.add_item("Markdown")
              ios_export_btn.accessibility_label = "Export, pull-down button"
              ios_pd_row3 = UI::HStack.new(spacing: 8.0)
              ios_pd_row3 << UI::Label.new("Export").as(UI::View)
              ios_pd_row3 << UI::Spacer.new.as(UI::View)
              ios_pd_row3 << ios_export_btn
              ios_pd_body << ios_pd_row3.as(UI::View)

              centered_study_card(ios_pd_body.as(UI::View), card_width: 332.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
            when "scroll-views"
              # HIG: "A scroll view lets people view content that's larger than
              # the view's boundaries by moving the content vertically or
              # horizontally." Keep the composition small and calm so the
              # clipped viewport is the point of the screenshot, not the list
              # chrome around it.
              ios_sv_title = UI::Label.new("Scroll views")
              ios_sv_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_sv_title.accessibility_label = "scroll-views showcase title"

              ios_sv_subtitle = UI::Label.new("Vertical content inside a fixed viewport.")
              ios_sv_subtitle.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_sv_subtitle.text_color_role = UI::LabelRole::Secondary
              ios_sv_subtitle.number_of_lines = 0
              ios_sv_subtitle.accessibility_label = "scroll-views showcase subtitle"

              ios_sv_content = UI::VStack.new(spacing: 0.0)
              (1..24).each do |i|
                row_lbl = UI::Label.new("Row #{i}")
                row_lbl.font = UI::Font.new(size: 16.0, weight: :regular)
                row_lbl.accessibility_label = "Scroll row #{i}"
                ios_sv_content << row_lbl
                if i < 24
                  ios_sv_content << UI::Divider.new
                end
              end

              # frame_height=320 pins the UIScrollView viewport height inside
              # the parent UIStackView; 24 rows guarantees the content remains
              # visibly taller than the viewport in the static capture.
              ios_scroll = UI::ScrollView.new(ios_sv_content)
              ios_scroll.scroll_vertical = true
              ios_scroll.scroll_horizontal = false
              ios_scroll.shows_indicators = true
              ios_scroll.frame_height = 320.0
              ios_scroll.accessibility_label = "Vertical scroll view with 15 rows"

              ios_sv_outer = UI::VStack.new(spacing: 12.0)
              ios_sv_outer.alignment = UI::Alignment::Leading
              ios_sv_outer << ios_sv_title.as(UI::View)
              ios_sv_outer << ios_sv_subtitle.as(UI::View)
              ios_sv_outer << ios_scroll.as(UI::View)
              centered_study_card(ios_sv_outer.as(UI::View), card_width: 336.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
            when "toolbars"
              # HIG: "A toolbar provides convenient access to frequently used
              # commands, controls, navigation, and search." On iOS 26,
              # toolbars use UIGlassEffect / UIBlurEffect systemChromeMaterial
              # as the glass background. Items are icon-only UIButtons (44x44pt
              # hit targets, no circular borders per HIG Best practices).
              #
              # Showcase: Mail-style bottom action bar with 5 items + divider.
              # compose | archive | flag | trash(destructive) | reply
              #
              # HIG Best practices:
              #   "Prefer system-provided symbols without borders."
              #   "Prioritize only the most important items for inclusion in
              #    the main toolbar area." (iOS)

              ios_tb = UI::Toolbar.new
              ios_tb.minimum_width = 296.0
              ios_tb.maximum_width = 296.0
              ios_tb.accessibility_label = "Mail action toolbar"

              ios_tb.add_item("compose",  "Compose",  "square.and.pencil")
              ios_tb.add_item("archive",  "Archive",  "archivebox")
              ios_tb.add_item("sep1",     "---",      nil)
              ios_tb.add_item("flag",     "Flag",     "flag")
              ios_tb.add_item("trash",    "Delete",   "trash")
              ios_tb.add_item("reply",    "Reply",    "arrowshape.turn.up.left")

              ios_tb_outer = UI::VStack.new(spacing: 12.0)
              ios_tb_outer.minimum_width = 296.0
              ios_tb_outer.maximum_width = 296.0
              ios_tb_heading = UI::Label.new("Document actions")
              ios_tb_heading.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_tb_heading.accessibility_label = "Toolbars showcase heading"
              ios_tb_desc = UI::Label.new("Keep the toolbar compact so the symbols stay easy to scan.")
              ios_tb_desc.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_tb_desc.accessibility_label = "Toolbars showcase description"
              ios_tb_outer << ios_tb_heading
              ios_tb_outer << ios_tb
              ios_tb_outer << ios_tb_desc

              ios_tb_card = UI::Card.new(ios_tb_outer.as(UI::View))
              ios_tb_card.minimum_width = 332.0
              ios_tb_card.maximum_width = 332.0
              ios_tb_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
              ios_tb_card.is_outlined = true
              ios_tb_card.material = :secondary
              ios_tb_card.accessibility_label = "Toolbar study card"
              ios_tb_card.as(UI::View)
            when "search-fields"
              # HIG: "A search field lets people search a collection of content
              # for specific terms they enter." UISearchBar provides the
              # magnifying-glass leading icon, pill-shaped rounded field,
              # placeholder text in secondary color, and shows a trailing clear
              # button when text is present.
              # Showcase: two states side-by-side — empty (placeholder) and
              # filled (text + clear button visible).

              ios_sf_title = UI::Label.new("Search Fields — UISearchBar")
              ios_sf_title.font = UI::Font.new(size: 15.0, weight: :medium)
              ios_sf_title.accessibility_label = "Search Fields showcase title"

              # State 1: empty — placeholder in secondary color
              ios_sf_empty_label = UI::Label.new("Empty (placeholder visible)")
              ios_sf_empty_label.font = UI::Font.new(size: 11.0, weight: :regular)
              ios_sf_empty_label.accessibility_label = "Empty search field caption"

              ios_sf_empty = UI::SearchField.new("Shows, Movies, and More")
              ios_sf_empty.text = ""
              ios_sf_empty.shows_cancel_button = false
              ios_sf_empty.minimum_width = 296.0
              ios_sf_empty.maximum_width = 296.0
              ios_sf_empty.accessibility_label = "Empty search field"

              # State 2: filled — text in primary color, trailing clear button
              ios_sf_filled_label = UI::Label.new("Filled (clear button visible)")
              ios_sf_filled_label.font = UI::Font.new(size: 11.0, weight: :regular)
              ios_sf_filled_label.accessibility_label = "Filled search field caption"

              ios_sf_filled = UI::SearchField.new("Shows, Movies, and More")
              ios_sf_filled.text = "Apple HIG"
              ios_sf_filled.shows_cancel_button = true
              ios_sf_filled.minimum_width = 296.0
              ios_sf_filled.maximum_width = 296.0
              ios_sf_filled.accessibility_label = "Filled search field with Apple HIG query"

              ios_sf_outer = UI::VStack.new(spacing: 10.0)
              ios_sf_outer.minimum_width = 296.0
              ios_sf_outer.maximum_width = 296.0
              ios_sf_outer << ios_sf_title
              ios_sf_outer << ios_sf_empty_label
              ios_sf_outer << ios_sf_empty
              ios_sf_outer << ios_sf_filled_label
              ios_sf_outer << ios_sf_filled

              ios_sf_card = UI::Card.new(ios_sf_outer.as(UI::View))
              ios_sf_card.minimum_width = 332.0
              ios_sf_card.maximum_width = 332.0
              ios_sf_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
              ios_sf_card.is_outlined = true
              ios_sf_card.material = :secondary
              ios_sf_card.accessibility_label = "Search field study card"
              ios_sf_card.as(UI::View)
            when "sidebars"
              # iPhone: HIG Sidebars — Platform considerations: "Avoid using a
              # sidebar on iPhone." On iPhone, replace the sidebar with a bottom
              # tab bar (UITabBarController) per HIG guidance.
              ios_amber_gold = UI::Color.new(r: 1.0, g: 0.678, b: 0.2)
              ios_gray_sec   = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)

              sidebar_shell = UI::VStack.new(spacing: 10.0)
              sidebar_shell.alignment = UI::Alignment::Leading
              sidebar_shell.maximum_width = 292.0

              sidebar_title = UI::Label.new("Mail")
              sidebar_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              sidebar_title.accessibility_label = "Sidebar title"
              sidebar_shell << sidebar_title.as(UI::View)

              sidebar_sub = UI::Label.new("Compact navigation")
              sidebar_sub.font = UI::Font.new(size: 12.0, weight: :regular)
              sidebar_sub.text_color = ios_gray_sec
              sidebar_sub.accessibility_label = "Sidebar subtitle"
              sidebar_shell << sidebar_sub.as(UI::View)

              nav_stack = UI::VStack.new(spacing: 0.0)
              nav_stack.padding = UI::EdgeInsets.new(top: 8.0, trailing: 10.0, bottom: 8.0, leading: 10.0)
              nav_stack.background = UI::Color.new(r: 0.96, g: 0.92, b: 0.86, a: 0.72)
              nav_stack.corner_radius = 10.0
              [
                {"Inbox", "12", true},
                {"Rituals", nil, false},
                {"Vault", nil, false},
                {"Profile", nil, false},
              ].each_with_index do |(label, badge, selected), idx|
                if idx > 0
                  nav_stack << UI::Divider.new(:horizontal).as(UI::View)
                end

                row = UI::HStack.new(spacing: 10.0)
                row.padding = UI::EdgeInsets.new(top: 8.0, trailing: 4.0, bottom: 8.0, leading: 4.0)
                row.background = UI::Color.new(r: 1.0, g: 0.678, b: 0.2, a: selected ? 0.16 : 0.0)
                row.corner_radius = 8.0

                icon = UI::Image.new(selected ? "tray.fill" : "square.grid.2x2")
                icon.tint_color = selected ? ios_amber_gold : ios_gray_sec
                icon.minimum_width = 16.0
                icon.minimum_height = 16.0
                row << icon.as(UI::View)

                name = UI::Label.new(label)
                name.font = UI::Font.new(size: 15.0, weight: selected ? :semibold : :regular)
                name.accessibility_label = "#{label} navigation item"
                row << name.as(UI::View)
                row << UI::Spacer.new.as(UI::View)

                if badge
                  badge_lbl = UI::Label.new(badge)
                  badge_lbl.font = UI::Font.new(size: 12.0, weight: :semibold)
                  badge_lbl.text_color = ios_gray_sec
                  row << badge_lbl.as(UI::View)
                end

                nav_stack << row.as(UI::View)
              end
              sidebar_shell << nav_stack.as(UI::View)

              preview_title = UI::Label.new("Inbox preview")
              preview_title.font = UI::Font.new(size: 15.0, weight: :semibold)
              preview_title.accessibility_label = "Sidebar preview title"
              sidebar_shell << preview_title.as(UI::View)

              preview_body = UI::Label.new("Selected destination. Calm rhythm.")
              preview_body.font = UI::Font.new(size: 12.0, weight: :regular)
              preview_body.text_color = ios_gray_sec
              preview_body.accessibility_label = "Sidebar preview body"
              sidebar_shell << preview_body.as(UI::View)

              sidebar_shell.as(UI::View)

            when "split-views"
              # HIG: "A split view manages the presentation of multiple adjacent
              # panes of content." Distinct from sidebars (iter 41) — this slug
              # validates the FULL divided canvas: sidebar | list | detail.
              #
              # On iPhone (compact width) a NavigationSplitView collapses to a
              # NavigationStack showing one pane at a time. The iOS capture shows
              # the first pane (sidebar/navigation) with a compact summary,
              # then the list and detail below as a clear stacked adaptation
              # of the divided layout. Keep the copy short so the columns stay
              # inside the frame and read like a product sample.

              ios_sv_outer = UI::VStack.new(spacing: 8.0)
              ios_sv_outer.alignment = UI::Alignment::Leading
              ios_sv_outer.maximum_width = 300.0

              ios_sv_title = UI::Label.new("Split view")
              ios_sv_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_sv_title.accessibility_label = "Split view title"
              ios_sv_outer << ios_sv_title.as(UI::View)

              ios_sv_sub = UI::Label.new("Compact flow")
              ios_sv_sub.font = UI::Font.new(size: 11.0, weight: :regular)
              ios_sv_sub.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
              ios_sv_sub.accessibility_label = "Split view subtitle"
              ios_sv_outer << ios_sv_sub.as(UI::View)

              sidebar_stack = UI::VStack.new(spacing: 0.0)
              sidebar_stack.padding = UI::EdgeInsets.new(top: 8.0, trailing: 10.0, bottom: 8.0, leading: 10.0)
              sidebar_stack.background = UI::Color.new(r: 0.96, g: 0.92, b: 0.86, a: 0.72)
              sidebar_stack.corner_radius = 10.0
              [
                {"Inbox", "12", true},
                {"Rituals", nil, false},
                {"Vault", nil, false},
              ].each_with_index do |(label, badge, selected), idx|
                if idx > 0
                  sidebar_stack << UI::Divider.new(:horizontal).as(UI::View)
                end

                row = UI::HStack.new(spacing: 10.0)
                row.padding = UI::EdgeInsets.new(top: 7.0, trailing: 4.0, bottom: 7.0, leading: 4.0)
                row.background = UI::Color.new(r: 1.0, g: 0.678, b: 0.2, a: selected ? 0.16 : 0.0)
                row.corner_radius = 8.0

                dot = UI::Image.new(selected ? "circle.fill" : "circle")
                dot.tint_color = selected ? UI::Color.new(r: 1.0, g: 0.678, b: 0.2) : UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
                dot.minimum_width = 12.0
                dot.minimum_height = 12.0
                row << dot.as(UI::View)

                lbl = UI::Label.new(label)
                lbl.font = UI::Font.new(size: 14.0, weight: selected ? :semibold : :regular)
                row << lbl.as(UI::View)
                row << UI::Spacer.new.as(UI::View)

                if badge
                  badge_lbl = UI::Label.new(badge)
                  badge_lbl.font = UI::Font.new(size: 11.0, weight: :semibold)
                  badge_lbl.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
                  row << badge_lbl.as(UI::View)
                end

                sidebar_stack << row.as(UI::View)
              end
              ios_sv_outer << sidebar_stack.as(UI::View)

              list_stack = UI::VStack.new(spacing: 5.0)
              list_stack.padding = UI::EdgeInsets.new(top: 7.0, trailing: 9.0, bottom: 7.0, leading: 9.0)
              list_stack.background = UI::Color.new(r: 0.96, g: 0.92, b: 0.86, a: 0.68)
              list_stack.corner_radius = 10.0
              list_hdr = UI::Label.new("Inbox list")
              list_hdr.font = UI::Font.new(size: 14.0, weight: :semibold)
              list_stack << list_hdr.as(UI::View)
              [
                {"Alice Martin", "Quarterly report", "Q1 numbers ready."},
              ].each_with_index do |(sender, subject, preview), idx|
                if idx > 0
                  list_stack << UI::Divider.new(:horizontal).as(UI::View)
                end
                row = UI::VStack.new(spacing: 2.0)
                sender_lbl = UI::Label.new(sender)
                sender_lbl.font = UI::Font.new(size: 13.0, weight: :semibold)
                subject_lbl = UI::Label.new(subject)
                subject_lbl.font = UI::Font.new(size: 12.0, weight: :regular)
                preview_lbl = UI::Label.new(preview)
                preview_lbl.font = UI::Font.new(size: 11.0, weight: :regular)
                preview_lbl.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
                row << sender_lbl.as(UI::View)
                row << subject_lbl.as(UI::View)
                row << preview_lbl.as(UI::View)
                list_stack << row.as(UI::View)
              end
              ios_sv_outer << list_stack.as(UI::View)

              detail_stack = UI::VStack.new(spacing: 5.0)
              detail_stack.padding = UI::EdgeInsets.new(top: 7.0, trailing: 9.0, bottom: 7.0, leading: 9.0)
              detail_stack.background = UI::Color.new(r: 0.96, g: 0.92, b: 0.86, a: 0.68)
              detail_stack.corner_radius = 10.0
              detail_hdr = UI::Label.new("Message detail")
              detail_hdr.font = UI::Font.new(size: 14.0, weight: :semibold)
              detail_stack << detail_hdr.as(UI::View)
              detail_from = UI::Label.new("From Alice Martin")
              detail_from.font = UI::Font.new(size: 12.0, weight: :regular)
              detail_subject = UI::Label.new("Quarterly report")
              detail_subject.font = UI::Font.new(size: 12.0, weight: :semibold)
              detail_stack << detail_from.as(UI::View)
              detail_stack << detail_subject.as(UI::View)
              ios_sv_outer << detail_stack.as(UI::View)

              ios_sv_outer.as(UI::View)

            when "sheets"
              # Amber sheet: "Conjure Reminder" — Amber-voice scoped task sheet.
              # HIG: "A sheet helps people perform a scoped task that's closely
              # related to their current context." On iOS a sheet slides up from
              # the bottom with a grabber handle and resizes between detents.
              # Rendered inline (surface_style: :grouped_card) via
              # UIVisualEffectView + UIGlassEffect (iOS 26) / UIBlurEffect
              # (UIBlurEffectStyleSystemMaterial fallback). NOT via is_presented.
              # Fields use Amber copy per brand/amber.md.
              #
              # Architectural fix (June R2 review): sheet is now overlaid using
              # :bottom_sheet focal_position in the DashboardScene ZStack so it
              # sits atop the chrome rather than stacking below it and being
              # clipped. The sheet uses HStack form rows (label + field side by
              # side, one line each) so all content fits in the .medium detent
              # (~520pt). minimum_height=520 ensures the sheet fills to its detent.
              #
              # Action wiring: Conjure = primary CTA (Prominent, Amber gold fill);
              # Cancel = secondary (semibold, bordered/default style).
              # Grabber: 5pt tall, 36pt wide, secondary fill, centered at top.
              # Typography: title 17pt Headline; form labels 13pt regular.
              # HIG: "Include a grabber if the sheet can be resized."

              # Grabber handle — secondary fill pill, centered at sheet top.
              ios_sh_grabber_row = UI::HStack.new(spacing: 0.0)
              ios_sh_grabber_row << UI::Spacer.new.as(UI::View)
              ios_sh_grabber = UI::Label.new("          ")
              ios_sh_grabber.background = UI::Color.new(r: 0.55, g: 0.55, b: 0.55, a: 0.5)
              ios_sh_grabber.corner_radius = 2.5
              ios_sh_grabber.minimum_width = 36.0
              ios_sh_grabber.maximum_width = 36.0
              ios_sh_grabber.minimum_height = 5.0
              ios_sh_grabber.maximum_height = 5.0
              ios_sh_grabber.accessibility_label = "Sheet grabber"
              ios_sh_grabber_row << ios_sh_grabber.as(UI::View)
              ios_sh_grabber_row << UI::Spacer.new.as(UI::View)
              ios_sh_grabber_row.minimum_height = 20.0

              ios_sh_title = UI::Label.new("Conjure Reminder")
              ios_sh_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_sh_title.accessibility_label = "Sheet title: Conjure Reminder"

              ios_sh_divider = UI::Divider.new

              # Form rows: stacked label + field pairs.
              # Dark-appearance fix (June R3): text field background in dark mode is
              # lifted to 2nd-level material (~#2A1E0D with glass) so placeholder text
              # clears 4.5:1 against the field background.
              # TEST_RUNNER_HIG_APPEARANCE is read via LibC.getenv (runtime-safe).
              # UITextField uses UITextBorderStyleRoundedRect which provides a system
              # fill. We override the background color by setting view.background on
              # each field so apply_common_properties sets setBackgroundColor: on UITextField.
              ios_sh_is_dark = begin
                raw = LibC.getenv("TEST_RUNNER_HIG_APPEARANCE")
                !raw.null? && String.new(raw) == "dark"
              end
              # 2nd-level material dark fill: #2A1E0D (r=0.165 g=0.118 b=0.051, alpha=1).
              # In light mode: system default fill (UITextField with RoundedRect draws its
              # own system-appropriate fill, so we leave background unset in light).
              ios_sh_field_bg = ios_sh_is_dark ? UI::Color.new(r: 0.165, g: 0.118, b: 0.051, a: 1.0) : nil

              ios_sh_title_label = UI::Label.new("Title:")
              ios_sh_title_label.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_sh_title_label.accessibility_label = "Title field label"
              ios_sh_title_field = UI::TextField.new("Morning pages title")
              ios_sh_title_field.accessibility_label = "Reminder title field"
              if fbg = ios_sh_field_bg
                ios_sh_title_field.background = fbg
              end

              ios_sh_date_label = UI::Label.new("When:")
              ios_sh_date_label.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_sh_date_label.accessibility_label = "When field label"
              ios_sh_date_field = UI::TextField.new("e.g. Apr 15 \u00B7 7:00")
              ios_sh_date_field.accessibility_label = "Reminder date and time field"
              if fbg = ios_sh_field_bg
                ios_sh_date_field.background = fbg
              end

              ios_sh_priority_label = UI::Label.new("Weight:")
              ios_sh_priority_label.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_sh_priority_label.accessibility_label = "Weight field label"
              ios_sh_priority_field = UI::TextField.new("None / Low / Medium / High")
              ios_sh_priority_field.accessibility_label = "Reminder priority field"
              if fbg = ios_sh_field_bg
                ios_sh_priority_field.background = fbg
              end

              ios_sh_form = UI::VStack.new(spacing: 8.0)
              ios_sh_form << ios_sh_title_label
              ios_sh_form << ios_sh_title_field
              ios_sh_form << ios_sh_date_label
              ios_sh_form << ios_sh_date_field
              ios_sh_form << ios_sh_priority_label
              ios_sh_form << ios_sh_priority_field

              ios_sh_divider2 = UI::Divider.new

              # Bottom action bar: Cancel (role: :cancel) + Conjure (Prominent).
              # HIG: "Always include a button that dismisses the sheet" — Cancel.
              # HIG: "Use the Prominent (filled) style for the most likely action."
              ios_sh_cancel = UI::Button.new("Cancel", role: :cancel)
              ios_sh_cancel.accessibility_label = "Cancel sheet"
              ios_sh_cancel.minimum_height = 44.0

              ios_sh_save = UI::Button.new("Conjure", role: :default, style: UI::ButtonStyle::Prominent)
              ios_sh_save.accessibility_label = "Conjure reminder"
              ios_sh_save.minimum_height = 44.0

              ios_sh_actions = UI::HStack.new(spacing: 12.0)
              ios_sh_actions << ios_sh_cancel
              ios_sh_actions << UI::Spacer.new
              ios_sh_actions << ios_sh_save
              ios_sh_actions.minimum_height = 44.0

              ios_sh_body = UI::VStack.new(spacing: 12.0)
              ios_sh_body << ios_sh_grabber_row
              ios_sh_body << ios_sh_title
              ios_sh_body << ios_sh_divider
              ios_sh_body << ios_sh_form
              ios_sh_body << ios_sh_divider2
              ios_sh_body << ios_sh_actions

              # Glass height: exact 400pt constraint (minimum == maximum) applied via
              # apply_common_properties -> objc_constrain_height at priority 999.
              # This is set on the GLASS (ios_sh, UIVisualEffectView), NOT on ios_sh_body
              # (which lives inside the glass's inner UIStackView and would create
              # unsatisfiable conflicts with the 4-edge-pinned inner stack constraints).
              #
              # Why 400pt:
              #   grabber_row(20) + title(22) + divider(1) + form(196) + divider2(1)
              #   + actions(44) + 5 gaps*12(60) = 344pt content.
              #   + inner stack layout margins top+bottom(32) = 376pt.
              #   + 24pt breathing room = 400pt.
              #
              # With an exact 400pt glass, the scene VStack's sizeThatFits returns:
              #   top_bar(60) + divider(1) + backdrop(60) + glass(400) = 521pt.
              # SwiftUI sizes UIViewRepresentable to 521pt, then UIStackView fill
              # distribution stretches the glass to exactly 400pt (already constrained).
              # Inner stack = 400 - 32 margins = 368pt; ios_sh_body fills 368pt with
              # UIStackView stretching ios_sh_form by 24pt. Cancel + Conjure fully visible.
              ios_sh = UI::Sheet.new(ios_sh_body.as(UI::View), surface_style: :grouped_card)
              ios_sh.minimum_height = 400.0
              ios_sh.maximum_height = 400.0
              ios_sh.as(UI::View)
            when "image-views"
              # HIG: "An image view displays a single image on a transparent or
              # opaque background." Compact study for iOS that keeps the image
              # surface centered and the supporting copy quiet.
              gallery = UI::VStack.new(spacing: 12.0)
              gallery.minimum_width = 288.0
              gallery.maximum_width = 288.0

              img_title = UI::Label.new("Image surfaces")
              img_title.font = UI::Font.new(size: 16.0, weight: :semibold)
              img_title.accessibility_label = "Image views showcase title"
              gallery << img_title

              img_desc = UI::Label.new("Single-image placements stay focused against the amber frame.")
              img_desc.font = UI::Font.new(size: 13.0, weight: :regular)
              img_desc.text_color_role = UI::LabelRole::Secondary
              img_desc.accessibility_label = "Image views description"
              gallery << img_desc

              sym_hdr = UI::Label.new("Symbol")
              sym_hdr.font = UI::Font.new(size: 12.0, weight: :semibold)
              sym_hdr.text_color_role = UI::LabelRole::Secondary
              gallery << sym_hdr
              sym_tile = UI::Label.new("\nstar.fill\n")
              sym_tile.font = UI::Font.new(size: 14.0, weight: :semibold)
              sym_tile.text_color_role = nil
              sym_tile.text_color = UI::Color.new(r: 1.0, g: 1.0, b: 1.0)
              sym_tile.background = UI::Color.new(r: 0.84, g: 0.49, b: 0.12)
              sym_tile.corner_radius = 10.0
              gallery << sym_tile

              thumb_hdr = UI::Label.new("Thumbnail")
              thumb_hdr.font = UI::Font.new(size: 12.0, weight: :semibold)
              thumb_hdr.text_color_role = UI::LabelRole::Secondary
              gallery << thumb_hdr
              thumb_tile = UI::Label.new("\nPhoto placeholder\n")
              thumb_tile.font = UI::Font.new(size: 13.0, weight: :regular)
              thumb_tile.text_color_role = nil
              thumb_tile.text_color = UI::Color.new(r: 0.32, g: 0.28, b: 0.24)
              thumb_tile.background = UI::Color.new(r: 0.88, g: 0.83, b: 0.76)
              thumb_tile.border_width = 1.0
              thumb_tile.border_color = UI::Color.new(r: 0.72, g: 0.66, b: 0.60)
              thumb_tile.corner_radius = 10.0
              gallery << thumb_tile

              avatar_hdr = UI::Label.new("Avatar")
              avatar_hdr.font = UI::Font.new(size: 12.0, weight: :semibold)
              avatar_hdr.text_color_role = UI::LabelRole::Secondary
              gallery << avatar_hdr
              avatar_tile = UI::Label.new("\nAvatar\n")
              avatar_tile.font = UI::Font.new(size: 13.0, weight: :regular)
              avatar_tile.text_color_role = nil
              avatar_tile.text_color = UI::Color.new(r: 1.0, g: 1.0, b: 1.0)
              avatar_tile.background = UI::Color.new(r: 0.69, g: 0.56, b: 0.49)
              avatar_tile.border_width = 2.0
              avatar_tile.border_color = UI::Color.new(r: 1.0, g: 1.0, b: 1.0)
              avatar_tile.corner_radius = 28.0
              avatar_tile.clip_to_bounds = true
              gallery << avatar_tile

              state_hdr = UI::Label.new("Loading")
              state_hdr.font = UI::Font.new(size: 12.0, weight: :semibold)
              state_hdr.text_color_role = UI::LabelRole::Secondary
              gallery << state_hdr
              spinner_row = UI::HStack.new(spacing: 8.0)
              spinner_row.alignment = UI::Alignment::Center
              spinner = UI::ActivityIndicator.new(true, :medium)
              spinner_row << spinner
              spinner_row << UI::Label.new("Waiting for image")
              gallery << spinner_row

              gallery.as(UI::View)
            when "tab-bars"
              # HIG: "A tab bar lets people navigate between top-level sections of your app."
              # HIG tab-bars Platform considerations (iOS): "A tab bar floats above content at
              # the bottom of the screen. Its items rest on a Liquid Glass background that allows
              # content beneath to peek through."
              # Showcase: 5-tab bar -- house/Home, magnifyingglass/Search (selected, index 1),
              # heart/Favorites, bell/Activity, person/Profile.
              # UIGlassEffect (iOS 26) preferred; falls back to UIBlurEffectStyleSystemChromeMaterial.
              # HIG: "Consider using SF Symbols to provide familiar, scalable tab bar icons."
              # HIG: "Include tab labels to help with navigation."
              # HIG: "Use the appropriate number of tabs required to help people navigate your app."

              ios_home_content = UI::VStack.new(spacing: 8.0)
              ios_home_lbl = UI::Label.new("Home")
              ios_home_lbl.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_home_lbl.accessibility_label = "Home section content"
              ios_home_content << ios_home_lbl

              ios_search_content = UI::VStack.new(spacing: 8.0)
              ios_search_lbl = UI::Label.new("Search")
              ios_search_lbl.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_search_lbl.accessibility_label = "Search section content"
              ios_search_desc = UI::Label.new("Tab bars -- UIGlassEffect / UIVisualEffectView")
              ios_search_desc.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_search_desc.text_color_role = UI::LabelRole::Secondary
              ios_search_desc.accessibility_label = "Tab bar description"
              ios_search_content << ios_search_lbl
              ios_search_content << ios_search_desc

              ios_tabs = [
                UI::TabView::Tab.new(label: "Home",       icon: "house",           content: ios_home_content.as(UI::View)),
                UI::TabView::Tab.new(label: "Search",     icon: "magnifyingglass", content: ios_search_content.as(UI::View)),
                UI::TabView::Tab.new(label: "Favorites",  icon: "heart",           content: UI::Label.new("Favorites").as(UI::View)),
                UI::TabView::Tab.new(label: "Activity",   icon: "bell",            content: UI::Label.new("Activity").as(UI::View)),
                UI::TabView::Tab.new(label: "Profile",    icon: "person",          content: UI::Label.new("Profile").as(UI::View)),
              ]

              ios_tab_view = UI::TabView.new(ios_tabs, 1)
              ios_tab_view.glass_bar = true
              ios_tab_view.minimum_width = 296.0
              ios_tab_view.maximum_width = 296.0
              ios_tab_view.minimum_height = 208.0
              ios_tab_view.maximum_height = 208.0
              ios_tab_view.accessibility_label = "Tab bar navigation"

              ios_tab_bar_outer = UI::VStack.new(spacing: 12.0)
              ios_tab_bar_outer.minimum_width = 296.0
              ios_tab_bar_outer.maximum_width = 296.0
              ios_tab_bar_heading = UI::Label.new("Top-level navigation")
              ios_tab_bar_heading.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_tab_bar_heading.accessibility_label = "Tab bar heading"
              ios_tab_bar_desc = UI::Label.new("Keep the bar light enough that the selected destination reads at a glance.")
              ios_tab_bar_desc.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_tab_bar_desc.accessibility_label = "Tab bar description"
              ios_tab_bar_outer << ios_tab_bar_heading
              ios_tab_bar_outer << ios_tab_bar_desc
              ios_tab_bar_outer << ios_tab_view.as(UI::View)

              ios_tab_bar_card = UI::Card.new(ios_tab_bar_outer.as(UI::View))
              ios_tab_bar_card.minimum_width = 332.0
              ios_tab_bar_card.maximum_width = 332.0
              ios_tab_bar_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
              ios_tab_bar_card.is_outlined = true
              ios_tab_bar_card.material = :secondary
              ios_tab_bar_card.accessibility_label = "Tab bar study card"
              ios_tab_bar_card.as(UI::View)
            when "tab-views"
              # HIG tab-views: macOS-primary pattern (NSTabView). On iOS the HIG
              # explicitly states "Not supported in iOS, iPadOS" -- the platform
              # recommendation is a segmented control. For validation purposes we
              # render the same UITabBar-style bottom bar (bar_position: :bottom)
              # and note in the component doc that iOS apps should use SegmentedControl
              # instead of NSTabView-style top tabs.
              # The iOS showcase re-uses the UIGlassEffect glass surface from tab-bars.
              # HIG: "For similar functionality [on iOS], consider using a segmented
              # control instead." -- tab-views Platform considerations, iOS.

              ios_general_content = UI::VStack.new(spacing: 8.0)
              ios_general_lbl = UI::Label.new("General")
              ios_general_lbl.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_general_lbl.accessibility_label = "General settings heading"
              ios_general_note = UI::Label.new("Tab views are macOS-only (NSTabView). iOS: use SegmentedControl.")
              ios_general_note.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_general_note.text_color_role = UI::LabelRole::Secondary
              ios_general_note.accessibility_label = "Platform note"
              ios_general_content << ios_general_lbl
              ios_general_content << ios_general_note

              ios_tv_tabs = [
                UI::TabView::Tab.new(label: "General",  content: ios_general_content.as(UI::View)),
                UI::TabView::Tab.new(label: "Advanced", content: UI::Label.new("Advanced").as(UI::View)),
                UI::TabView::Tab.new(label: "Access.",  content: UI::Label.new("Accessibility").as(UI::View)),
                UI::TabView::Tab.new(label: "Updates",  content: UI::Label.new("Updates").as(UI::View)),
              ]

              ios_tv = UI::TabView.new(ios_tv_tabs, 0)
              ios_tv.bar_position = :bottom
              ios_tv.glass_bar = true
              ios_tv.minimum_width = 296.0
              ios_tv.maximum_width = 296.0
              ios_tv.minimum_height = 220.0
              ios_tv.maximum_height = 220.0
              ios_tv.accessibility_label = "Tab view navigation (iOS fallback)"

              ios_tab_view_outer = UI::VStack.new(spacing: 12.0)
              ios_tab_view_outer.minimum_width = 296.0
              ios_tab_view_outer.maximum_width = 296.0
              ios_tab_view_heading = UI::Label.new("Tabbed sections")
              ios_tab_view_heading.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_tab_view_heading.accessibility_label = "Tab view heading"
              ios_tab_view_desc = UI::Label.new("On iPhone, keep the fallback disciplined enough that the platform note doesn't overpower the component.")
              ios_tab_view_desc.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_tab_view_desc.accessibility_label = "Tab view description"
              ios_tab_view_outer << ios_tab_view_heading
              ios_tab_view_outer << ios_tab_view_desc
              ios_tab_view_outer << ios_tv.as(UI::View)

              ios_tab_view_card = UI::Card.new(ios_tab_view_outer.as(UI::View))
              ios_tab_view_card.minimum_width = 332.0
              ios_tab_view_card.maximum_width = 332.0
              ios_tab_view_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
              ios_tab_view_card.is_outlined = true
              ios_tab_view_card.material = :secondary
              ios_tab_view_card.accessibility_label = "Tab view study card"
              ios_tab_view_card.as(UI::View)
            when "charts"
              # Amber charts: "Focus minutes this week" bar chart, 7 days.
              # Bar fill: Amber plum (#5B3A94 -> r:0.357 g:0.227 b:0.58), NOT systemBlue.
              # iOS: the native ChartView already carries a fixed 340x220 size.
              # The tighter centered study card keeps the axis labels readable
              # against the Amber backdrop without the old scroll-container shell.
              ios_plum = UI::Color.new(r: 0.357, g: 0.227, b: 0.58)
              ios_chart = UI::ChartView.new
              ios_chart.chart_type = :bar
              ios_chart.title = "Focus minutes this week"
              ios_chart.data_points = [
                UI::ChartDataPoint.new(label: "Mon", value: 94.0,  color: ios_plum),
                UI::ChartDataPoint.new(label: "Tue", value: 120.0, color: ios_plum),
                UI::ChartDataPoint.new(label: "Wed", value: 45.0,  color: ios_plum),
                UI::ChartDataPoint.new(label: "Thu", value: 138.0, color: ios_plum),
                UI::ChartDataPoint.new(label: "Fri", value: 82.0,  color: ios_plum),
                UI::ChartDataPoint.new(label: "Sat", value: 157.0, color: ios_plum),
                UI::ChartDataPoint.new(label: "Sun", value: 63.0,  color: ios_plum),
              ]
              ios_chart.show_grid = true
              ios_chart.accessibility_label = "Focus minutes this week bar chart, Mon through Sun"
              ios_chart.as(UI::View)
            when "color-wells"
              # HIG Color wells: swatch button showing current color.
              # HIG Best practices: "Consider the system-provided color picker for a
              # familiar experience."
              # iOS now renders a native UIColorWell.
              ios_outer = UI::VStack.new(spacing: 16.0)

              # Row 1: labeled red color well.
              ios_row1 = UI::HStack.new(spacing: 12.0)
              ios_lbl1 = UI::Label.new("Stroke color")
              ios_lbl1.accessibility_label = "Stroke color label"
              ios_well1 = UI::ColorPicker.new
              ios_well1.selected_color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
              ios_well1.label = "Stroke color"
              ios_well1.accessibility_label = "Stroke color well, red"
              ios_row1 << ios_lbl1
              ios_row1 << ios_well1

              # Row 2: custom teal color well.
              ios_row2 = UI::HStack.new(spacing: 12.0)
              ios_lbl2 = UI::Label.new("Fill color")
              ios_lbl2.accessibility_label = "Fill color label"
              ios_well2 = UI::ColorPicker.new
              ios_well2.selected_color = UI::Color.new(r: 0.0, g: 0.537, b: 0.482)
              ios_well2.label = "Fill color"
              ios_well2.accessibility_label = "Fill color well, teal"
              ios_row2 << ios_lbl2
              ios_row2 << ios_well2

              # Row 3: "Pick a color..." label + orange color well.
              ios_row3 = UI::HStack.new(spacing: 12.0)
              ios_lbl3 = UI::Label.new("Pick a color...")
              ios_lbl3.accessibility_label = "Pick a color prompt"
              ios_well3 = UI::ColorPicker.new
              ios_well3.selected_color = UI::Color.new(r: 1.0, g: 0.584, b: 0.0)
              ios_well3.label = "Pick a color"
              ios_well3.accessibility_label = "Pick a color well, orange"
              ios_row3 << ios_lbl3
              ios_row3 << ios_well3

              ios_outer << ios_row1
              ios_outer << ios_row2
              ios_outer << ios_row3
              ios_outer.as(UI::View)
            when "web-views"
              # HIG Web views: embeds rich HTML/URL content inside an app.
              # Use a deterministic local HTML preview so the component taste is
              # judged on layout and polish rather than remote page variance.
              preview_html = <<-HTML
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      html, body { margin: 0; padding: 0; background: #f4efe8; color: #171311; font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif; }
      body { padding: 18px; }
      .shell { background: rgba(255,255,255,0.78); border: 1px solid rgba(127,102,77,0.12); border-radius: 22px; padding: 16px; box-shadow: 0 16px 36px rgba(56,35,20,0.10); }
      .eyebrow { font-size: 11px; letter-spacing: 0.08em; text-transform: uppercase; color: #8d6a45; margin-bottom: 10px; }
      h1 { margin: 0 0 8px; font-size: 22px; line-height: 1.08; font-weight: 650; }
      p { margin: 0; font-size: 14px; line-height: 1.46; color: #57463a; }
      .chips { display: flex; gap: 8px; margin: 16px 0; flex-wrap: wrap; }
      .chip { border-radius: 999px; padding: 7px 12px; font-size: 12px; font-weight: 600; }
      .chip.primary { background: #ffb14a; color: #2f1900; }
      .chip.secondary { background: rgba(141,106,69,0.12); color: #6e5746; }
      .list { border-radius: 16px; background: linear-gradient(180deg, rgba(255,255,255,0.92), rgba(249,240,231,0.92)); padding: 14px; border: 1px solid rgba(127,102,77,0.10); }
      .row { display: flex; justify-content: space-between; align-items: center; padding: 10px 0; border-bottom: 1px solid rgba(127,102,77,0.08); font-size: 13px; color: #3b2d23; }
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

              ios_wv_outer = UI::VStack.new(spacing: 12.0)

              ios_wv_label = UI::Label.new("Embedded web content")
              ios_wv_label.accessibility_label = "Embedded web content heading"

              ios_wv_desc = UI::Label.new("A web view should feel intentional, readable, and native to the surrounding surface.")
              ios_wv_desc.accessibility_label = "Web view description"

              ios_wv = UI::WebViewComponent.new(url: "https://amber.local/review")
              ios_wv.title = "Editorial Review"
              ios_wv.html = preview_html
              ios_wv.base_url = "https://amber.local"
              ios_wv.allows_navigation = true
              ios_wv.minimum_width = 320.0
              ios_wv.maximum_width = 320.0
              ios_wv.minimum_height = 296.0
              ios_wv.maximum_height = 296.0
              ios_wv.corner_radius = 22.0
              ios_wv.clip_to_bounds = true
              ios_wv.accessibility_label = "Web view: Editorial Review"

              ios_wv_outer << ios_wv_label
              ios_wv_outer << ios_wv_desc
              ios_wv_outer << ios_wv
              ios_wv_outer.as(UI::View)
            when "maps"
              ios_map_inner = UI::VStack.new(spacing: 12.0)

              ios_map_label = UI::Label.new("Neighborhood overview")
              ios_map_label.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_map_label.accessibility_label = "Maps heading"

              ios_map_desc = UI::Label.new("Maps should stay interactive and legible, with companion chrome kept intentionally quiet.")
              ios_map_desc.font = UI::Font.new(size: 13.0)
              ios_map_desc.accessibility_label = "Maps description"

              ios_map = UI::MapView.new
              ios_map.latitude = 37.8024
              ios_map.longitude = -122.4058
              ios_map.zoom_level = 12.5
              ios_map.map_type = :standard
              ios_map.minimum_width = 296.0
              ios_map.maximum_width = 296.0
              ios_map.minimum_height = 220.0
              ios_map.maximum_height = 220.0
              ios_map.corner_radius = 22.0
              ios_map.clip_to_bounds = true
              ios_map.border_width = 1.0
              ios_map.border_color = UI::Color.new(r: 0.78, g: 0.74, b: 0.68, a: 0.28)
              ios_map.accessibility_label = "Map centered on Coit Tower"
              ios_map.annotations << UI::MapAnnotation.new(
                latitude: 37.8024,
                longitude: -122.4058,
                title: "Coit Tower",
                subtitle: "Neighborhood walk"
              )
              ios_map.annotations << UI::MapAnnotation.new(
                latitude: 37.7983,
                longitude: -122.4078,
                title: "Reading Room",
                subtitle: "Quiet stop"
              )

              ios_map_inner << ios_map_label
              ios_map_inner << ios_map_desc
              ios_map_inner << ios_map

              ios_map_card = UI::Card.new(ios_map_inner.as(UI::View))
              ios_map_card.minimum_width = 332.0
              ios_map_card.maximum_width = 332.0
              ios_map_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
              ios_map_card.is_outlined = true
              ios_map_card.material = :secondary
              ios_map_card.accessibility_label = "Maps study card"
              ios_map_card.as(UI::View)
            when "playing-video"
              ios_video_inner = UI::VStack.new(spacing: 12.0)

              ios_video_label = UI::Label.new("Playback preview")
              ios_video_label.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_video_label.accessibility_label = "Video heading"

              ios_video_desc = UI::Label.new("Honor the system player shape. Keep copy secondary.")
              ios_video_desc.font = UI::Font.new(size: 13.0)
              ios_video_desc.accessibility_label = "Video description"

              ios_video = UI::VideoPlayer.new("https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")
              ios_video.shows_controls = true
              ios_video.auto_play = false
              ios_video.muted = true
              ios_video.minimum_width = 296.0
              ios_video.maximum_width = 296.0
              ios_video.minimum_height = 167.0
              ios_video.maximum_height = 167.0
              ios_video.corner_radius = 22.0
              ios_video.clip_to_bounds = true
              ios_video.background = UI::Color.new(r: 0.10, g: 0.10, b: 0.12, a: 1.0)
              ios_video.border_width = 1.0
              ios_video.border_color = UI::Color.new(r: 0.78, g: 0.74, b: 0.68, a: 0.28)
              ios_video.accessibility_label = "Playback preview surface"

              ios_video_inner << ios_video_label
              ios_video_inner << ios_video_desc
              ios_video_inner << ios_video

              ios_video_card = UI::Card.new(ios_video_inner.as(UI::View))
              ios_video_card.minimum_width = 332.0
              ios_video_card.maximum_width = 332.0
              ios_video_card.content_padding = UI::EdgeInsets.new(top: 18.0, trailing: 18.0, bottom: 18.0, leading: 18.0)
              ios_video_card.is_outlined = true
              ios_video_card.material = :secondary
              ios_video_card.accessibility_label = "Video study card"
              ios_video_card.as(UI::View)
            when "page-controls"
              # HIG: "A page control displays a row of indicator images, each of
              # which represents a page in a flat list." — Page controls, abstract.
              # UIPageControl on iOS 26. 5 pages, current = 2 (third dot filled).
              ios_pc_outer = UI::VStack.new(spacing: 10.0)
              ios_pc_outer.alignment = UI::Alignment::Center

              ios_pc_title = UI::Label.new("Pages")
              ios_pc_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_pc_title.accessibility_label = "Page control study title"
              ios_pc_outer << ios_pc_title.as(UI::View)

              ios_pc_sub = UI::Label.new("Amber marks the spot")
              ios_pc_sub.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_pc_sub.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
              ios_pc_sub.accessibility_label = "Page control study subtitle"
              ios_pc_outer << ios_pc_sub.as(UI::View)

              ios_pc_label1 = UI::Label.new("Default")
              ios_pc_label1.accessibility_label = "Default page control label"
              ios_pc_outer << ios_pc_label1

              ios_pc = UI::PageControl.new(total: 5, current: 2)
              ios_pc.accessibility_label = "Page 3 of 5"
              ios_pc_outer << ios_pc

              ios_pc_label2 = UI::Label.new("Amber")
              ios_pc_label2.accessibility_label = "Tinted page control label"
              ios_pc_outer << ios_pc_label2

              ios_pc_tinted = UI::PageControl.new(total: 5, current: 0)
              ios_pc_tinted.tint_color = UI::Color.new(r: 1.0, g: 0.58, b: 0.0)
              ios_pc_tinted.accessibility_label = "Page 1 of 5, orange tint"
              ios_pc_outer << ios_pc_tinted

              ios_pc_outer.as(UI::View)
            when "path-controls"
              # HIG path controls are macOS-only. The shared UI::PathControl
              # falls back to a breadcrumb-style row on iOS so the component
              # remains inspectable in previews without pretending UIKit has a
              # native equivalent.
              ios_path_outer = UI::VStack.new(spacing: 10.0)
              ios_path_outer.alignment = UI::Alignment::Leading

              ios_path_hdr = UI::Label.new("Export path")
              ios_path_hdr.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_path_hdr.accessibility_label = "Path controls heading"
              ios_path_outer << ios_path_hdr.as(UI::View)

              ios_path_sub = UI::Label.new("Current location")
              ios_path_sub.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_path_sub.text_color_role = UI::LabelRole::Secondary
              ios_path_sub.accessibility_label = "Current location label"
              ios_path_outer << ios_path_sub.as(UI::View)

              ios_standard = UI::PathControlWithWebFallback.new
              ios_standard.minimum_width = 280.0
              ios_standard.maximum_width = 280.0
              ios_standard.accessibility_label = "Current export destination path"
              ios_standard.add_component("Applications", icon: "folder")
              ios_standard.add_component("Amber", icon: "app")
              ios_standard.add_component("Exports", icon: "folder")
              ios_standard.add_component("Autumn Ritual.pdf", icon: "doc")
              ios_path_outer << ios_standard

              ios_path_hint = UI::Label.new("Recent locations")
              ios_path_hint.font = UI::Font.new(size: 12.0, weight: :regular)
              ios_path_hint.text_color_role = UI::LabelRole::Secondary
              ios_path_hint.accessibility_label = "Recent locations label"
              ios_path_outer << ios_path_hint.as(UI::View)

              ios_popup = UI::PathControlWithWebFallback.new(style: UI::PathControlStyle::PopUp)
              ios_popup.minimum_width = 256.0
              ios_popup.maximum_width = 256.0
              ios_popup.accessibility_label = "Recent export locations path menu"
              ios_popup.add_component("Library", icon: "folder")
              ios_popup.add_component("Templates", icon: "folder")
              ios_popup.add_component("Press Kits", icon: "doc.on.doc")
              ios_path_outer << ios_popup

              ios_path_outer.as(UI::View)
            when "outline-views"
              # HIG outline views: a compact hierarchical browser that keeps
              # the selected branch readable without turning into a blank demo
              # canvas. Use the fallback primitive directly so the iOS study
              # matches the same node model the shared renderer uses.
              outline = UI::OutlineView.new
              outline.viewport_width = 304.0
              outline.viewport_height = 248.0
              outline.row_spacing = 2.0
              outline.indent_width = 14.0
              outline.row_padding = UI::EdgeInsets.new(top: 5.0, trailing: 8.0, bottom: 5.0, leading: 8.0)
              outline.shows_disclosure_glyphs = true
              outline.accessibility_label = "Project outline"

              inbox = UI::OutlineView::Node.new("Inbox", "tray", "12", true, [] of UI::OutlineView::Node, false)
              drafts = UI::OutlineView::Node.new("Drafts", "doc.text", "3", true, [] of UI::OutlineView::Node, true)
              drafts.add_child(UI::OutlineView::Node.new("Landing page", "square.and.pencil", nil, false, [] of UI::OutlineView::Node, false))
              drafts.add_child(UI::OutlineView::Node.new("Release notes", "note.text", nil, false, [] of UI::OutlineView::Node, false))

              archive = UI::OutlineView::Node.new("Archive", "archivebox", nil, true, [] of UI::OutlineView::Node, false)
              archive.add_child(UI::OutlineView::Node.new("2025", "folder", nil, false, [] of UI::OutlineView::Node, false))
              archive.add_child(UI::OutlineView::Node.new("Shared", "person.2", nil, false, [] of UI::OutlineView::Node, false))

              outline.add_root(inbox)
              outline.add_root(drafts)
              outline.add_root(archive)

              outline_outer = UI::VStack.new(spacing: 10.0)
              outline_outer.alignment = UI::Alignment::Leading

              outline_title = UI::Label.new("Project Amber")
              outline_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              outline_title.accessibility_label = "Outline study title"
              outline_outer << outline_title.as(UI::View)

              outline_subtitle = UI::Label.new("Navigation sample")
              outline_subtitle.font = UI::Font.new(size: 12.0, weight: :regular)
              outline_subtitle.text_color_role = UI::LabelRole::Secondary
              outline_subtitle.accessibility_label = "Outline study subtitle"
              outline_outer << outline_subtitle.as(UI::View)

              outline_outer << outline.as(UI::View)
              outline_outer.as(UI::View)
            when "column-views"
              # HIG column views: a compact Finder-style drill-down browser.
              # Keep the hierarchy short so the study reads as a calm, centered
              # navigation sample with honest gutters around the columns.
              column_view = UI::ColumnView.new
              column_view.default_column_width = 146.0
              column_view.column_widths = [146.0, 156.0]
              column_view.column_spacing = 10.0
              column_view.row_spacing = 4.0
              column_view.row_padding = UI::EdgeInsets.new(top: 6.0, trailing: 8.0, bottom: 6.0, leading: 8.0)
              column_view.viewport_width = 306.0
              column_view.viewport_height = 232.0
              column_view.shows_disclosure_glyphs = true
              column_view.selected_indexes = [0, 1]

              inbox = UI::ColumnView::Item.new("Inbox", "tray", "12", [
                UI::ColumnView::Item.new("Today", "sun.max", "5"),
                UI::ColumnView::Item.new("Drafts", "doc.text", "3"),
                UI::ColumnView::Item.new("Archive", "archivebox", "24"),
              ])
              projects = UI::ColumnView::Item.new("Projects", "folder", "4", [
                UI::ColumnView::Item.new("Mobile", "iphone", "2"),
                UI::ColumnView::Item.new("Desktop", "macwindow", "1"),
                UI::ColumnView::Item.new("Brand", "paintbrush", "1"),
              ])
              shared = UI::ColumnView::Item.new("Shared", "person.2", nil, [
                UI::ColumnView::Item.new("Reviews", "checkmark.seal", "8"),
                UI::ColumnView::Item.new("Assets", "photo.on.rectangle", "16"),
              ])
              column_view.add_item(inbox)
              column_view.add_item(projects)
              column_view.add_item(shared)

              column_outer = UI::VStack.new(spacing: 10.0)
              column_outer.minimum_width = 306.0
              column_outer.maximum_width = 306.0

              column_title = UI::Label.new("Project browser")
              column_title.font = UI::Font.new(size: 16.0, weight: :semibold)
              column_title.accessibility_label = "Column views showcase title"
              column_outer << column_title

              column_desc = UI::Label.new("Drill down one branch at a time.")
              column_desc.font = UI::Font.new(size: 13.0, weight: :regular)
              column_desc.text_color_role = UI::LabelRole::Secondary
              column_desc.accessibility_label = "Column views description"
              column_outer << column_desc

              column_outer << column_view.as(UI::View)
              column_outer.as(UI::View)
            when "combo-boxes"
              # HIG Platform considerations: "Not supported in iOS, iPadOS,
              # tvOS, visionOS, or watchOS."
              # UIKit renderer falls back to a UITextField with a trailing
              # chevron.down SF Symbol button — the standard iOS pattern for
              # a text field with an attached picker/menu.
              ios_cb_outer = UI::VStack.new(spacing: 12.0)

              ios_cb_label = UI::Label.new("Country:")
              ios_cb_label.accessibility_label = "Country label"
              ios_cb_outer << ios_cb_label

              ios_cb = UI::ComboBox.new(
                value: "United States",
                options: ["United States", "Canada", "Mexico", "United Kingdom", "Germany"],
                placeholder: "Select or type\u2026",
                width: 280.0
              )
              ios_cb.accessibility_label = "Country combo box"
              ios_cb_outer << ios_cb

              ios_cb_label2 = UI::Label.new("Browser:")
              ios_cb_label2.accessibility_label = "Browser label"
              ios_cb_outer << ios_cb_label2

              ios_cb2 = UI::ComboBox.new(
                value: "",
                options: ["Safari", "Chrome", "Firefox", "Edge"],
                placeholder: "Select or type\u2026",
                width: 280.0
              )
              ios_cb2.accessibility_label = "Browser combo box"
              ios_cb_outer << ios_cb2

              ios_cb_outer.as(UI::View)
            when "rating-indicators"
              # HIG Platform considerations: "Not supported in iOS, iPadOS,
              # tvOS, visionOS, or watchOS." — NSLevelIndicator is macOS-only.
              # UIKit renderer synthesises a horizontal UIStackView of
              # UIImageViews carrying SF Symbol names "star.fill" / "star".
              ios_ri_outer = UI::VStack.new(spacing: 12.0)
              ios_ri_outer.alignment = UI::Alignment::Leading

              ios_ri_title = UI::Label.new("Ratings")
              ios_ri_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_ri_title.accessibility_label = "rating indicators showcase title"
              ios_ri_outer << ios_ri_title

              ios_ri_desc = UI::Label.new("Compact star samples with an amber frame.")
              ios_ri_desc.font = UI::Font.new(size: 13.0, weight: :regular)
              ios_ri_desc.text_color_role = UI::LabelRole::Secondary
              ios_ri_desc.number_of_lines = 0
              ios_ri_desc.accessibility_label = "rating indicators showcase subtitle"
              ios_ri_outer << ios_ri_desc

              ios_ri_row1 = UI::HStack.new(spacing: 12.0)
              ios_ri_row1.minimum_width = 280.0
              ios_ri_row1.maximum_width = 280.0
              ios_ri_lbl1 = UI::Label.new("Full")
              ios_ri_lbl1.accessibility_label = "5 of 5 stars label"
              ios_ri_full = UI::RatingIndicator.new(value: 5.0, max: 5)
              ios_ri_full.accessibility_label = "5 out of 5 stars"
              ios_ri_row1 << ios_ri_lbl1.as(UI::View)
              ios_ri_row1 << UI::Spacer.new.as(UI::View)
              ios_ri_row1 << ios_ri_full.as(UI::View)
              ios_ri_outer << ios_ri_row1.as(UI::View)

              ios_ri_row2 = UI::HStack.new(spacing: 12.0)
              ios_ri_row2.minimum_width = 280.0
              ios_ri_row2.maximum_width = 280.0
              ios_ri_lbl2 = UI::Label.new("Partial")
              ios_ri_lbl2.accessibility_label = "3 of 5 stars label"
              ios_ri_partial = UI::RatingIndicator.new(value: 3.0, max: 5)
              ios_ri_partial.accessibility_label = "3 out of 5 stars"
              ios_ri_row2 << ios_ri_lbl2.as(UI::View)
              ios_ri_row2 << UI::Spacer.new.as(UI::View)
              ios_ri_row2 << ios_ri_partial.as(UI::View)
              ios_ri_outer << ios_ri_row2.as(UI::View)

              ios_ri_row3 = UI::HStack.new(spacing: 12.0)
              ios_ri_row3.minimum_width = 280.0
              ios_ri_row3.maximum_width = 280.0
              ios_ri_lbl3 = UI::Label.new("Two stars")
              ios_ri_lbl3.accessibility_label = "2 of 5 stars label"
              ios_ri_two = UI::RatingIndicator.new(value: 2.0, max: 5)
              ios_ri_two.accessibility_label = "2 out of 5 stars"
              ios_ri_row3 << ios_ri_lbl3.as(UI::View)
              ios_ri_row3 << UI::Spacer.new.as(UI::View)
              ios_ri_row3 << ios_ri_two.as(UI::View)
              ios_ri_outer << ios_ri_row3.as(UI::View)

              ios_ri_row4 = UI::HStack.new(spacing: 12.0)
              ios_ri_row4.minimum_width = 280.0
              ios_ri_row4.maximum_width = 280.0
              ios_ri_lbl4 = UI::Label.new("Tinted")
              ios_ri_lbl4.accessibility_label = "3 of 5 stars blue tint label"
              ios_ri_tint = UI::RatingIndicator.new(
                value: 3.0,
                max: 5,
                tint_color: UI::Color.new(r: 0.0, g: 0.48, b: 1.0)
              )
              ios_ri_tint.accessibility_label = "3 out of 5 stars blue tint"
              ios_ri_row4 << ios_ri_lbl4.as(UI::View)
              ios_ri_row4 << UI::Spacer.new.as(UI::View)
              ios_ri_row4 << ios_ri_tint.as(UI::View)
              ios_ri_outer << ios_ri_row4.as(UI::View)

              centered_study_card(ios_ri_outer.as(UI::View), card_width: 320.0, content_padding: UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0))
            # -----------------------------------------------------------------
            # Phase 3 Remediation 3 — validation probe scenes.
            # Identifiers track docs/initiative-cross-platform-ui/phases/
            # phase-03-swiftui-native-bridge/validation.md §BX and §V exactly.
            # -----------------------------------------------------------------
            when "phase-03-action-tap-probe"
              ios_probe = UI::VStack.new(spacing: 16.0)
              ios_probe.alignment = UI::Alignment::Center

              ios_tap_counter = UI::Label.new(UI::Probes::TapProbe.current_text)
              ios_tap_counter.test_id = "tap-probe-counter"
              # Deliberately NOT setting accessibility_label: on a SwiftUI Text
              # the displayed text IS the AX label. Overriding it would
              # shadow the digit content the XCUITest reads through
              # `staticTexts["tap-probe-counter"].label`.
              ios_tap_counter.text_alignment = UI::Alignment::Center

              ios_tap = UI::Button.new("Tap me") do
                UI::Probes::TapProbe.increment
                ios_tap_counter.text = UI::Probes::TapProbe.current_text
              end
              ios_tap.test_id = "tap-probe-button"
              ios_tap.accessibility_label = "tap-probe-button"
              ios_tap.style = UI::ButtonStyle::Prominent
              ios_tap.minimum_height = 44.0
              ios_probe << ios_tap.as(UI::View)
              ios_probe << ios_tap_counter.as(UI::View)

              ios_probe.as(UI::View)
            when "phase-03-toggle-value-probe"
              ios_tv_probe = UI::VStack.new(spacing: 16.0)
              ios_tv_probe.alignment = UI::Alignment::Center

              ios_toggle_value = UI::Label.new(UI::Probes::ToggleProbe.current_text)
              ios_toggle_value.test_id = "toggle-probe-value"
              # Reactive mirror label — leave accessibility_label unset so the
              # SwiftUI Text exposes its content (true / false) as the AX label.
              ios_toggle_value.text_alignment = UI::Alignment::Center

              ios_toggle = UI::Toggle.new("Notify", UI::Probes::ToggleProbe.last_value) do |new_value|
                UI::Probes::ToggleProbe.set(new_value)
                ios_toggle_value.text = UI::Probes::ToggleProbe.current_text
              end
              ios_toggle.test_id = "toggle-probe-toggle"
              # Deliberately NOT setting accessibility_label: SwiftUI Toggle
              # synthesizes its AX label from the "Notify" content; overriding
              # would collapse the switch+label into a single element whose
              # tap doesn't reach the underlying UISwitch.
              ios_tv_probe << ios_toggle.as(UI::View)
              ios_tv_probe << ios_toggle_value.as(UI::View)

              ios_tv_probe.as(UI::View)
            when "phase-03-slider-value-probe"
              ios_sv_probe = UI::VStack.new(spacing: 16.0)
              ios_sv_probe.alignment = UI::Alignment::Center

              ios_slider_value = UI::Label.new(UI::Probes::SliderProbe.current_text)
              ios_slider_value.test_id = "slider-probe-value"
              # Reactive mirror label — leave accessibility_label unset so the
              # SwiftUI Text exposes its numeric content as the AX label.
              ios_slider_value.text_alignment = UI::Alignment::Center

              ios_slider = UI::Slider.new(0.0, 1.0, UI::Probes::SliderProbe.last_value) do |new_value|
                UI::Probes::SliderProbe.set(new_value)
                ios_slider_value.text = UI::Probes::SliderProbe.current_text
              end
              ios_slider.test_id = "slider-probe-slider"
              # Deliberately NOT setting accessibility_label so the SwiftUI
              # Slider's thumb/track adjustment surface stays addressable.
              ios_slider.minimum_width = 280.0
              ios_sv_probe << ios_slider.as(UI::View)
              ios_sv_probe << ios_slider_value.as(UI::View)

              ios_sv_probe.as(UI::View)
            when "phase-03-runtime-override-probe"
              # BX5: runtime background override now propagates via the
              # reactive `background=` setter (Phase 3 Remediation 4).
              ios_ov_probe = UI::VStack.new(spacing: 16.0)
              ios_ov_probe.alignment = UI::Alignment::Center

              ios_target = UI::Button.new("Override target")
              ios_target.test_id = "override-target"
              ios_target.accessibility_label = "override-target"
              ios_target.minimum_height = 44.0
              if UI::Probes::RuntimeOverrideProbe.target_red?
                ios_target.background = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
              end
              ios_ov_probe << ios_target.as(UI::View)

              ios_ov_state = UI::Label.new(UI::Probes::RuntimeOverrideProbe.current_text)
              ios_ov_state.test_id = "override-state"
              # Reactive mirror — leave label unset so the rendered text shows
              # through as the SwiftUI accessibility label.
              ios_ov_state.text_alignment = UI::Alignment::Center

              ios_trigger = UI::Button.new("Make Red") do
                UI::Probes::RuntimeOverrideProbe.set_red
                ios_target.background = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
                ios_ov_state.text = UI::Probes::RuntimeOverrideProbe.current_text
              end
              ios_trigger.test_id = "make-red-trigger"
              ios_trigger.accessibility_label = "make-red-trigger"
              ios_trigger.minimum_height = 44.0
              ios_ov_probe << ios_trigger.as(UI::View)
              ios_ov_probe << ios_ov_state.as(UI::View)

              ios_ov_probe.as(UI::View)
            when "phase-03-form-nested-buttons"
              ios_form_stack = UI::VStack.new(spacing: 12.0)
              ios_form_stack.alignment = UI::Alignment::Leading
              ios_form_stack.minimum_width = 320.0

              ios_row1 = UI::Button.new("Row 1")
              ios_row1.test_id = "form-row-1"
              ios_row1.accessibility_label = "form-row-1"
              ios_row1.minimum_height = 44.0
              ios_row1.minimum_width = 280.0
              ios_form_stack << ios_row1.as(UI::View)

              ios_form_counter = UI::Label.new(UI::Probes::FormRowProbe.current_text)
              ios_form_counter.test_id = "form-row-2-counter"
              # Reactive mirror — leave label unset so the digit text shows
              # through as the SwiftUI accessibility label.

              ios_row2 = UI::Button.new("Row 2") do
                UI::Probes::FormRowProbe.increment_row2
                ios_form_counter.text = UI::Probes::FormRowProbe.current_text
              end
              ios_row2.test_id = "form-row-2"
              ios_row2.accessibility_label = "form-row-2"
              ios_row2.minimum_height = 44.0
              ios_row2.minimum_width = 280.0
              ios_form_stack << ios_row2.as(UI::View)

              ios_row3 = UI::Button.new("Row 3")
              ios_row3.test_id = "form-row-3"
              ios_row3.accessibility_label = "form-row-3"
              ios_row3.minimum_height = 44.0
              ios_row3.minimum_width = 280.0
              ios_form_stack << ios_row3.as(UI::View)
              ios_form_stack << ios_form_counter.as(UI::View)

              ios_form_stack.as(UI::View)
            when "phase-03-sheet-focus-return"
              # Phase 3 Remediation 10 — reactive Sheet bridge slug.
              #
              # Hoist `ios_sheet_v` BEFORE the trigger / primary / cancel
              # button on_tap blocks so those blocks can capture it for
              # `is_presented = true / false`. The content stack is wired
              # AFTER the buttons (Sheet#content is a property, not a
              # constructor argument, so this ordering works cleanly).
              ios_sheet_probe = UI::VStack.new(spacing: 16.0)
              ios_sheet_probe.alignment = UI::Alignment::Center

              ios_sheet_v = UI::Sheet.new(nil, surface_style: :grouped_card)
              ios_sheet_v.accessibility_label = "sheet-surface"

              # Reactive mirror label for the dismiss reason. The Label
              # is hoisted so the button blocks below can drive it via
              # `text=` (which dispatches through APSKLabelState if the
              # SwiftKit reactive bridge is active).
              ios_sheet_reason = UI::Label.new(UI::Probes::DismissProbe.current_text)
              ios_sheet_reason.test_id = "dismiss-reason"

              ios_sheet_trigger = UI::Button.new("Open sheet") do
                # Clear any stale dismiss reason from a previous open/close
                # cycle so the next dismissal records its own reason cleanly.
                UI::Probes::DismissProbe.reset
                ios_sheet_reason.text = UI::Probes::DismissProbe.current_text
                ios_sheet_v.is_presented = true
              end
              ios_sheet_trigger.test_id = "sheet-trigger"
              ios_sheet_trigger.accessibility_label = "sheet-trigger"
              ios_sheet_trigger.minimum_height = 44.0
              ios_sheet_probe << ios_sheet_trigger.as(UI::View)

              ios_sheet_content = UI::VStack.new(spacing: 12.0)
              ios_sheet_content.test_id = "sheet-content"
              ios_sheet_content.accessibility_label = "sheet-content"
              ios_sheet_content.padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)

              ios_sheet_title = UI::Label.new("Confirm action")
              ios_sheet_title.font = UI::Font.new(size: 15.0, weight: :semibold)
              ios_sheet_content << ios_sheet_title.as(UI::View)

              ios_sheet_primary = UI::Button.new("Confirm", role: :default) do
                # Mark the dismissal as an explicit-button action so the
                # subsequent SwiftUI onDismiss (which fires after we flip
                # is_presented = false) doesn't overwrite with "swipe".
                UI::Probes::DismissProbe.mark_explicit("primary")
                ios_sheet_reason.text = UI::Probes::DismissProbe.current_text
                ios_sheet_v.is_presented = false
              end
              ios_sheet_primary.test_id = "sheet-primary"
              ios_sheet_primary.accessibility_label = "sheet-primary"
              ios_sheet_primary.style = UI::ButtonStyle::Prominent
              ios_sheet_primary.minimum_height = 44.0
              ios_sheet_content << ios_sheet_primary.as(UI::View)

              ios_sheet_cancel = UI::Button.new("Cancel", role: :cancel) do
                UI::Probes::DismissProbe.mark_explicit("cancel")
                ios_sheet_reason.text = UI::Probes::DismissProbe.current_text
                ios_sheet_v.is_presented = false
              end
              ios_sheet_cancel.test_id = "sheet-cancel"
              ios_sheet_cancel.accessibility_label = "sheet-cancel"
              ios_sheet_cancel.minimum_height = 44.0
              ios_sheet_content << ios_sheet_cancel.as(UI::View)

              # Wire the content into the hoisted Sheet now that the
              # children exist and the button on_tap blocks have closed
              # over `ios_sheet_v`.
              ios_sheet_v.content = ios_sheet_content.as(UI::View)

              # Sheet on_dismiss: SwiftUI fires this AFTER every
              # dismissal (interactive swipe AND button-driven). The
              # explicit-flag guard inside `handle_dismiss` ensures we
              # only record "swipe" for interactive dismissals.
              ios_sheet_v.on_dismiss = -> do
                UI::Probes::DismissProbe.handle_dismiss
                ios_sheet_reason.text = UI::Probes::DismissProbe.current_text
                nil
              end

              ios_sheet_probe << ios_sheet_v.as(UI::View)
              ios_sheet_probe << ios_sheet_reason.as(UI::View)

              ios_sheet_probe.as(UI::View)
            when "phase-03-button-default"
              ios_save = UI::Button.new("Save")
              ios_save.test_id = "save"
              ios_save.accessibility_label = "save"
              ios_save.minimum_height = 44.0
              ios_save.minimum_width = 100.0
              ios_save.as(UI::View)
            when "phase-03-button-background-override"
              ios_red = UI::Button.new("Save")
              ios_red.background = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
              ios_red.test_id = "save"
              ios_red.accessibility_label = "save"
              ios_red.minimum_height = 44.0
              ios_red.minimum_width = 100.0
              ios_red.as(UI::View)
            when "phase-03-button-square"
              ios_sq = UI::Button.new("Save")
              ios_sq.corner_radius = 0.0
              ios_sq.test_id = "save"
              ios_sq.accessibility_label = "save"
              ios_sq.minimum_height = 44.0
              ios_sq.minimum_width = 100.0
              ios_sq.as(UI::View)
            when "phase-03-toggle-default"
              ios_def_toggle = UI::Toggle.new("Notify", true)
              ios_def_toggle.test_id = "default-toggle"
              ios_def_toggle.accessibility_label = "default-toggle"
              ios_def_toggle.as(UI::View)
            when "phase-03-card-default"
              ios_card_body = UI::VStack.new(spacing: 8.0)
              ios_card_body.padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
              ios_card_title = UI::Label.new("Card Title")
              ios_card_title.font = UI::Font.new(size: 17.0, weight: :semibold)
              ios_card_body << ios_card_title.as(UI::View)
              ios_card_detail = UI::Label.new("This card uses the default GlassBackground cascade.")
              ios_card_body << ios_card_detail.as(UI::View)

              ios_def_card = UI::Card.new(ios_card_body.as(UI::View))
              ios_def_card.test_id = "default-card"
              ios_def_card.accessibility_label = "default-card"
              ios_def_card.minimum_width = 320.0
              ios_def_card.maximum_width = 320.0
              ios_def_card.as(UI::View)
            when "phase-03-form-default"
              ios_def_form = UI::Form.new
              ios_def_section = ios_def_form.add_section
              ios_def_section.fields << UI::Form::Field.new(label: "Notify", content: UI::Toggle.new("", true).as(UI::View))
              ios_def_section.fields << UI::Form::Field.new(label: "Username", content: UI::TextField.new("seth").as(UI::View))
              ios_def_picker = UI::Picker.new(["Daily", "Weekly", "Monthly"], 0)
              ios_def_section.fields << UI::Form::Field.new(label: "Frequency", content: ios_def_picker.as(UI::View))
              ios_def_form.test_id = "default-form"
              ios_def_form.accessibility_label = "default-form"
              ios_def_form.minimum_width = 360.0
              ios_def_form.as(UI::View)
            else                            UI::Label.new("Unknown slug: #{slug}").as(UI::View)
            end
    # For scene-wrapped slugs, return just the focal component (child) so the
    # scene composer gets a clean component without a wrapper VStack.
    # For non-scene slugs, tag the vstack with the accessibility root label so
    # the iOS XCUITest harness can confirm the app launched and rendered content.
    # (The old "HIG: <slug>" debug label that served as the root was removed per
    # Issue B; the test_id + accessibility_label on the vstack replaces it.)
    if scene_for_slug(slug)
      child
    else
      vstack << child
      vstack.accessibility_label = "hig-component-root"
      vstack.test_id = "hig-component-root"
      vstack.as(UI::View)
    end
  end
end

# ---------------------------------------------------------------------------
# C ABI exports -- callable from Swift via CrystalHIGHost-Bridging-Header.h
# ---------------------------------------------------------------------------

fun crystal_init : Void
  CrystalHIGHost::Bridge.initialize_runtime
end

# Build and render one component by slug. Returns a raw UIView* that Swift
# takes ownership of via Unmanaged.fromOpaque(..).takeRetainedValue().
#
# NOTE on pointer ownership: the asset_pipeline UIKit renderer allocates
# its native objects with "owned" semantics (+1 retain). The produced
# NativeHandle.ptr is that +1 pointer. We do NOT call release! here --
# ownership transfers to Swift. We keep @@last_native as a weak
# "don't-GC-the-tree-before-Swift-reads-it" anchor; Swift's takeRetainedValue
# bumps the retain count enough that Crystal GC tearing down NativeView
# later is safe (ObjC retain keeps UIKit object alive regardless).
fun crystal_render_slug(slug_ptr : LibC::Char*) : Void*
  CrystalHIGHost::Bridge.initialize_runtime
  slug = String.new(slug_ptr)
  view = CrystalHIGHost::Bridge.build_component(slug)
  renderer = UI::UIKit::Renderer.new
  native = renderer.render(view)
  CrystalHIGHost::Bridge.last_native = native

  # UI::NativeView exposes its native pointer via `handle.ptr!` (NativeHandle#ptr!).
  # See src/ui/native/native_handle.cr -- the documented retained-pointer API.
  native.handle.ptr!
end

{% end %}
