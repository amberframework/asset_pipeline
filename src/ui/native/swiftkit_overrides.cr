# Per-view-type override modules that customize how each UI::View is bridged
# into the SwiftKit hosting layer on Apple platforms.

require "../view"
require "../views/button"
require "../views/label"
require "../views/image"
require "../views/text_field"
require "../views/secure_field"
require "../views/search_field"
require "../views/text_area"
require "../views/text_editor"
require "../views/link_button"
require "../views/icon_button"
require "../views/divider"
require "../views/spacer"
require "../views/toggle"
require "../views/checkbox"
require "../views/radio_group"
require "../views/slider"
require "../views/stepper"
require "../views/segmented_control"
require "../views/picker"
require "../views/date_picker"
require "../views/time_picker"
require "../views/color_picker"
require "../views/navigation_stack"
require "../views/navigation_link"
require "../views/navigation_split_view"
require "../views/tab_view"
require "../views/sheet"
require "../views/popover"
require "../views/alert"
require "../views/confirmation_dialog"
require "../views/toolbar"
require "../views/form"
require "../views/grid"
require "../views/card"
require "../views/surface"
require "../views/menu_button"
require "../views/toggle_button"
require "../views/list_view"
require "../views/glass_background"
require "./swiftkit_bridge"

module UI
  module Native
    # SwiftKit override populator.
    #
    # Phase 3's renderer migration moves overrides population OUT of each
    # visit method and INTO this module so the populator can be exercised
    # in plain `crystal spec` runs (no `-Dmacos` / `-Dios` flag, no
    # AppKit / UIKit / SwiftKit frameworks linked).
    #
    # The contract:
    #
    #   `Populator.populate_button(overrides_ptr, view)` walks the
    #   `UI::Button`'s common-view properties (background, corner_radius,
    #   padding, opacity, hidden, border_*, shadow_*, min/max_*,
    #   accessibility_label, test_id) PLUS the button-specific properties
    #   (role, style, disabled, symbol) and ONLY sends the setter when
    #   the property differs from its type default. This is the
    #   "default-detection" invariant — implementation.md §11 calls it
    #   "the single most important behavioral invariant of phase 3."
    #
    #   The populator does not call `objc_msgSend` directly. It calls
    #   into an injected `Sender` interface. In production builds the
    #   sender is `LibObjCBridge`-backed (renderer integration); in spec
    #   builds it is `FakeLibObjCBridge`-backed and merely records each
    #   setter invocation.
    #
    # This indirection lets the renderer's visit method shrink from
    # ~230 lines to ~5: `populate_button(ovr, view); make_button(...)`.
    module Populator
      # Setter sender interface. The renderer supplies a `LibObjCBridge`-
      # backed implementation; specs supply a `FakeLibObjCBridge`-backed
      # one. Methods are deliberately String-typed for the spec side —
      # the production sender stringifies its args once at the boundary
      # and passes the real `Void*` / `Float64` / `String` through.
      abstract class Sender
        # Set an `NSColor?`/`UIColor?` field. `nil` means leave unset.
        abstract def set_color(target : String, setter : Symbol, color : UI::Color?)
        # Set an `NSNumber?` field from a `Float64?`. `nil` skips.
        abstract def set_number(target : String, setter : Symbol, value : Float64?)
        # Set an `NSNumber?` field from a `Bool?`. `nil` skips.
        abstract def set_bool(target : String, setter : Symbol, value : Bool?)
        # Set an `NSString?` field. `nil` skips.
        abstract def set_string(target : String, setter : Symbol, value : String?)

        # Group 3 array setters. Container widgets carry parallel arrays
        # (tab labels / icons / tokens, form section field counts, etc.).
        # Empty arrays are skipped.
        def set_string_array(target : String, setter : Symbol, values : Array(String))
        end

        def set_int_array(target : String, setter : Symbol, values : Array(Int32))
        end

        def set_uint64_array(target : String, setter : Symbol, values : Array(UInt64))
        end

        def set_bool_array(target : String, setter : Symbol, values : Array(Bool))
        end

        # Scalar Int setter (selectedIndex etc.). nil skips.
        def set_int(target : String, setter : Symbol, value : Int32?)
        end
      end

      # Populate the common `APSKViewOverrides` fields from any `UI::View`.
      #
      # Every per-widget populator calls this helper first, then layers
      # widget-specific setters on top. Keeps each per-widget populator to
      # the minimal "what is unique about THIS widget?" surface.
      #
      # All setters are skipped when the matching property is at its type
      # default — that is the default-detection invariant in §11.
      def self.populate_view_common(target : String, view : UI::View, sender : Sender)
        sender.set_color(target, :setBackgroundColor, view.background)

        cr = view.corner_radius
        sender.set_number(target, :setCornerRadius, cr == 0.0 ? nil : cr)

        pad = view.padding
        sender.set_number(target, :setPaddingTop, pad.top == 0.0 ? nil : pad.top)
        sender.set_number(target, :setPaddingLeading, pad.leading == 0.0 ? nil : pad.leading)
        sender.set_number(target, :setPaddingBottom, pad.bottom == 0.0 ? nil : pad.bottom)
        sender.set_number(target, :setPaddingTrailing, pad.trailing == 0.0 ? nil : pad.trailing)

        op = view.opacity
        sender.set_number(target, :setOpacity, op == 1.0 ? nil : op)

        sender.set_bool(target, :setHidden, view.hidden ? true : nil)

        bw = view.border_width
        sender.set_number(target, :setBorderWidth, bw == 0.0 ? nil : bw)
        sender.set_color(target, :setBorderColor, view.border_color)

        sr = view.shadow_radius
        sender.set_number(target, :setShadowRadius, sr == 0.0 ? nil : sr)
        sender.set_color(target, :setShadowColor, view.shadow_color)
        ox = view.shadow_offset_x
        oy = view.shadow_offset_y
        sender.set_number(target, :setShadowOffsetX, ox == 0.0 ? nil : ox)
        sender.set_number(target, :setShadowOffsetY, oy == 0.0 ? nil : oy)

        sender.set_number(target, :setMinWidth, view.minimum_width)
        sender.set_number(target, :setMinHeight, view.minimum_height)
        sender.set_number(target, :setMaxWidth, view.maximum_width)
        sender.set_number(target, :setMaxHeight, view.maximum_height)

        sender.set_string(target, :setAccessibilityIdentifier, view.test_id)
        # Renamed selector — see ViewOverrides.swift. The accessor remains
        # `apskAccessibilityLabel`; the setter is `setApskAccessibilityLabel:`.
        # Avoids the iOS UIAccessibility.accessibilityLabel selector clash.
        sender.set_string(target, :setApskAccessibilityLabel, view.accessibility_label)
      end

      # Populate an `APSKButtonOverrides` instance from a `UI::Button`.
      #
      # The `target` parameter is the Crystal-side identifier for the
      # overrides object (in production it's a stringified pointer; in
      # specs it's the sentinel from `FakeLibObjCBridge.next_sentinel_pointer`).
      def self.populate_button(target : String, view : UI::Button, sender : Sender)
        populate_view_common(target, view, sender)

        # ---- Button-specific overrides -----------------------------------
        # Role: :default is the type default; anything else surfaces a
        # role string the Swift facade switches on.
        role_str = view.role == :default ? nil : view.role.to_s
        sender.set_string(target, :setRole, role_str)

        # Style: only emit when non-Default. The Swift facade falls back
        # to SwiftUI's `.automatic` style when role is nil.
        style_str = case view.style
                    when UI::ButtonStyle::Prominent  then "prominent"
                    when UI::ButtonStyle::Tinted     then "tinted"
                    when UI::ButtonStyle::Bordered   then "bordered"
                    when UI::ButtonStyle::Borderless then "borderless"
                    else                                  nil
                    end
        sender.set_string(target, :setStyle, style_str)

        # Disabled: false is the type default.
        sender.set_bool(target, :setDisabled, view.disabled ? true : nil)

        # SF Symbol leading glyph.
        sender.set_string(target, :setSymbolName, view.symbol)
      end

      # ---------------------------------------------------------------
      # Group 1 — value display and simple input widgets.
      # ---------------------------------------------------------------

      def self.populate_label(target : String, view : UI::Label, sender : Sender)
        populate_view_common(target, view, sender)
        # Label uses LabelRole::Primary as the type default; only emit when
        # the developer explicitly overrode the role or set a brand colour.
        if view.text_color_role.nil?
          # Brand RGBA path — the Swift facade reads textColor only when
          # textColorRole is nil. Roles are mutually exclusive with raw RGBA.
          c = view.text_color
          sender.set_color(target, :setForegroundColor, c)
        else
          role = view.text_color_role
          unless role == UI::LabelRole::Primary
            sender.set_string(target, :setLabelRole, role.to_s.downcase)
          end
        end

        align = view.text_alignment
        unless align == UI::Alignment::Leading
          sender.set_string(target, :setTextAlignment, align.to_s.downcase)
        end

        nl = view.number_of_lines
        sender.set_number(target, :setNumberOfLines, nl == 0 ? nil : nl.to_f64)

        # Font size + weight. The Crystal `UI::Font` type default is
        # `Font.new(size: 17.0, weight: :regular)` — exactly SwiftUI's
        # body default — so we only emit when the developer overrode
        # one of those fields. Without this propagation the Crystal-side
        # `font = Font.new(size: 34.0, weight: :bold)` value was being
        # silently dropped and every Label rendered at SwiftUI body.
        font = view.font
        if font.size != 17.0
          sender.set_number(target, :setFontSize, font.size)
        end
        if font.weight != :regular
          sender.set_number(target, :setFontWeight,
            swiftui_font_weight_rawvalue(font.weight).to_f64)
        end

        # Phase 6.11 — strikethrough toggle. Emit only when set so the
        # SwiftUI facade keeps its default (no strikethrough) untouched.
        if view.strikethrough
          sender.set_bool(target, :setStrikethrough, true)
        end
      end

      # Map a Crystal `UI::Font.weight` Symbol to the SwiftUI
      # `Font.Weight` rawValue Int the Swift facade init reads. The
      # mapping mirrors ButtonFacade.swift's private `Font.Weight`
      # extension. ultraLight = -3, thin = -2, light = -1, regular = 0,
      # medium = 1, semibold = 2, bold = 3, heavy = 4, black = 5.
      def self.swiftui_font_weight_rawvalue(weight : Symbol) : Int32
        case weight
        when :ultra_light, :ultralight then -3
        when :thin                     then -2
        when :light                    then -1
        when :regular                  then 0
        when :medium                   then 1
        when :semibold                 then 2
        when :bold                     then 3
        when :heavy                    then 4
        when :black                    then 5
        else                                0
        end
      end

      def self.populate_image(target : String, view : UI::Image, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_color(target, :setForegroundColor, view.tint_color)
        mode = view.content_mode
        unless mode == UI::ContentMode::Fit
          sender.set_string(target, :setContentMode, mode.to_s.downcase)
        end
      end

      def self.populate_text_field(target : String, view : UI::TextField, sender : Sender)
        populate_view_common(target, view, sender)
        # Placeholder + text are positional args on apsk_make_text_field;
        # only secure-entry needs to flow through overrides.
        sender.set_bool(target, :setSecureEntry, view.secure_entry ? true : nil)
        kt = view.keyboard_type
        unless kt == UI::KeyboardType::Default
          sender.set_string(target, :setKeyboardType, kt.to_s.downcase)
        end
      end

      def self.populate_secure_field(target : String, view : UI::SecureField, sender : Sender)
        populate_view_common(target, view, sender)
        # No widget-specific overrides today; the SwiftUI SecureField default
        # already handles obscured entry + accessibility traits.
      end

      def self.populate_search_field(target : String, view : UI::SearchField, sender : Sender)
        populate_view_common(target, view, sender)
        # Default placeholder is "Search"; the Swift facade falls back to
        # localizedSystemSearchLabel when no override surfaces.
        unless view.shows_cancel_button
          sender.set_bool(target, :setShowsCancelButton, false)
        end
      end

      def self.populate_text_area(target : String, view : UI::TextArea, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_bool(target, :setEditable, view.is_editable ? nil : false)
        sender.set_bool(target, :setScrollable, view.is_scrollable ? nil : false)
        if ll = view.line_limit
          sender.set_number(target, :setLineLimit, ll.to_f64)
        end
      end

      def self.populate_text_editor(target : String, view : UI::TextEditor, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_bool(target, :setEditable, view.is_editable ? nil : false)
        if sh = view.syntax_highlighting
          sender.set_string(target, :setSyntaxHighlighting, sh.to_s)
        end
      end

      def self.populate_link_button(target : String, view : UI::LinkButton, sender : Sender)
        populate_view_common(target, view, sender)
        # No widget-specific overrides — label + url are positional.
      end

      def self.populate_icon_button(target : String, view : UI::IconButton, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_color(target, :setForegroundColor, view.tint_color)
        sender.set_number(target, :setIconSize, view.icon_size == 24.0 ? nil : view.icon_size)
        sender.set_bool(target, :setDisabled, view.disabled ? true : nil)
        sender.set_string(target, :setLabel, view.label)
      end

      def self.populate_divider(target : String, view : UI::Divider, sender : Sender)
        populate_view_common(target, view, sender)
        # Divider's tint default is hard-coded grey; only surface a colour
        # when it has been explicitly set (cannot detect — emit always).
        sender.set_color(target, :setForegroundColor, view.color)
        sender.set_number(target, :setThickness, view.thickness == 1.0 ? nil : view.thickness)
        # orientation is :horizontal by default.
        unless view.orientation == :horizontal
          sender.set_string(target, :setOrientation, view.orientation.to_s)
        end
      end

      def self.populate_spacer(target : String, view : UI::Spacer, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_number(target, :setMinLength, view.min_length == 0.0 ? nil : view.min_length)
      end

      # ---------------------------------------------------------------
      # Group 2 — selection and form controls.
      # ---------------------------------------------------------------

      def self.populate_toggle(target : String, view : UI::Toggle, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_color(target, :setForegroundColor, view.tint_color)
        sender.set_bool(target, :setDisabled, view.disabled ? true : nil)
        unless view.style == UI::ToggleStyle::Switch
          sender.set_string(target, :setToggleStyle, view.style.to_s.downcase)
        end
      end

      def self.populate_checkbox(target : String, view : UI::Checkbox, sender : Sender)
        populate_view_common(target, view, sender)
      end

      def self.populate_radio_group(target : String, view : UI::RadioGroup, sender : Sender)
        populate_view_common(target, view, sender)
      end

      def self.populate_slider(target : String, view : UI::Slider, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_color(target, :setForegroundColor, view.tint_color)
        sender.set_number(target, :setStep, view.step == 0.0 ? nil : view.step)
      end

      def self.populate_stepper(target : String, view : UI::Stepper, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_number(target, :setStep, view.step_value == 1.0 ? nil : view.step_value)
        sender.set_bool(target, :setWraps, view.wraps ? true : nil)
      end

      def self.populate_segmented_control(target : String, view : UI::SegmentedControl, sender : Sender)
        populate_view_common(target, view, sender)
      end

      def self.populate_picker(target : String, view : UI::Picker, sender : Sender)
        populate_view_common(target, view, sender)
        unless view.style == UI::PickerStyle::Menu
          sender.set_string(target, :setPickerStyle, view.style.to_s.downcase)
        end
      end

      def self.populate_date_picker(target : String, view : UI::DatePicker, sender : Sender)
        populate_view_common(target, view, sender)
        unless view.mode == UI::DatePickerMode::Date
          sender.set_string(target, :setDatePickerMode, view.mode.to_s.downcase)
        end
      end

      def self.populate_time_picker(target : String, view : UI::TimePicker, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_bool(target, :setShows24Hour, view.shows_24_hour ? true : nil)
        sender.set_number(target, :setMinuteInterval, view.minute_interval == 1 ? nil : view.minute_interval.to_f64)
      end

      def self.populate_color_picker(target : String, view : UI::ColorPicker, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_bool(target, :setSupportsOpacity, view.supports_alpha ? true : nil)
      end

      # ---------------------------------------------------------------
      # Group 3 — navigation / surfaces / forms / menus.
      # ---------------------------------------------------------------

      def self.populate_navigation_stack(target : String, view : UI::NavigationStack, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_string(target, :setTitle, view.title)
        sender.set_bool(target, :setLargeTitle, view.large_title ? true : nil)
        sender.set_bool(target, :setShowsNavigationBar,
          view.shows_navigation_bar ? nil : false)
      end

      def self.populate_navigation_link(target : String, view : UI::NavigationLink, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_string(target, :setIcon, view.icon)
        sender.set_bool(target, :setShowsDisclosure,
          view.shows_disclosure ? nil : false)
      end

      def self.populate_navigation_split_view(target : String, view : UI::NavigationSplitView, sender : Sender)
        populate_view_common(target, view, sender)
        sw = view.sidebar_width
        sender.set_number(target, :setSidebarWidth, sw == 250.0 ? nil : sw)
        cv = view.column_visibility
        unless cv == :all
          sender.set_string(target, :setColumnVisibility, cv.to_s)
        end
        # Phase 5 v2: forward AppleSemantic override (or HIG default :sidebar)
        # so the SwiftKit facade applies `.background(<Material>)` on the
        # sidebar pane VStack only.
        ms = view.material_semantic
        key = ms.nil? ? "sidebar" : ms.to_s
        sender.set_string(target, :setMaterialSemantic, key)
      end

      def self.populate_tab_view(target : String, view : UI::TabView, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_color(target, :setSelectedTintColor, view.selected_tint_color)
        unless view.bar_position == :bottom
          sender.set_string(target, :setTabBarPosition, view.bar_position.to_s)
        end
        sender.set_bool(target, :setGlassBar, view.glass_bar ? nil : false)
        # Always emit the parallel arrays so the facade can render tabItems.
        sender.set_string_array(target, :setTabLabels, view.tabs.map(&.label))
        sender.set_string_array(target, :setTabIcons, view.tabs.map { |t| t.icon || "" })
        sender.set_int(target, :setSelectedIndex,
          view.selected_index == 0 ? nil : view.selected_index)
        # Phase 5 v2: ALWAYS emit a materialSemantic key. Default is
        # :system_resolved → SwiftUI .bar fallback inside the facade;
        # explicit overrides flow through.
        ms = view.material_semantic
        sender.set_string(target, :setMaterialSemantic,
          ms.nil? ? "system_resolved" : ms.to_s)
      end

      def self.populate_sheet(target : String, view : UI::Sheet, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_bool(target, :setIsPresented, view.is_presented ? true : nil)
        unless view.surface_style == :auto
          sender.set_string(target, :setSurfaceStyle, view.surface_style.to_s)
        end
        # Detents — default is [:medium, :large]; only emit when changed.
        default_detents = [:medium, :large]
        unless view.detents == default_detents
          sender.set_string_array(target, :setDetents, view.detents.map(&.to_s))
        end
        sender.set_bool(target, :setShowsDragIndicator,
          view.shows_drag_indicator ? nil : false)
        # Phase 5 v2: forward AppleSemantic override (or HIG default :sheet)
        # so the SwiftKit facade applies `.presentationBackground(.thickMaterial)`
        # on the presented sheet body (iOS 16.4+ / macOS 13.3+).
        ms = view.material_semantic
        key = ms.nil? ? "sheet" : ms.to_s
        sender.set_string(target, :setMaterialSemantic, key)
      end

      def self.populate_popover(target : String, view : UI::Popover, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_bool(target, :setIsPresented, view.is_presented ? true : nil)
        unless view.arrow_edge == :bottom
          sender.set_string(target, :setArrowEdge, view.arrow_edge.to_s)
        end
        sender.set_number(target, :setPreferredWidth, view.preferred_width)
        sender.set_number(target, :setPreferredHeight, view.preferred_height)
        # Phase 5 v2: HIG default is :popover; the facade applies
        # `.presentationBackground(.regularMaterial)` on iOS 16.4+ / macOS 13.3+.
        ms = view.material_semantic
        key = ms.nil? ? "popover" : ms.to_s
        sender.set_string(target, :setMaterialSemantic, key)
      end

      def self.populate_alert(target : String, view : UI::Alert, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_string(target, :setTitle, view.title.empty? ? nil : view.title)
        sender.set_string(target, :setMessage, view.message.empty? ? nil : view.message)
        sender.set_bool(target, :setIsPresented, view.is_presented ? true : nil)
        # Parallel button arrays — always emit when buttons present.
        unless view.buttons.empty?
          sender.set_string_array(target, :setButtonLabels, view.buttons.map(&.label))
          sender.set_string_array(target, :setButtonStyles, view.buttons.map(&.style.to_s))
          # Tokens registered by the visit method; populator can't see them.
          # The visit method emits set_uint64_array itself after registering.
        end
        # Phase 5 v2: HIG default is :system_resolved (SwiftUI .alert is
        # system-drawn). Only emit when the caller overrides — preserved for
        # cross-platform symmetry with the other Category B widgets'
        # material override surface; field is inert on the .alert path.
        if ms = view.material_semantic
          sender.set_string(target, :setMaterialSemantic, ms.to_s)
        end
      end

      def self.populate_confirmation_dialog(target : String, view : UI::ConfirmationDialog, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_string(target, :setTitle, view.title.empty? ? nil : view.title)
        sender.set_string(target, :setMessage, view.message.empty? ? nil : view.message)
        sender.set_bool(target, :setIsPresented, view.is_presented ? true : nil)
        unless view.confirm_label == "Confirm"
          sender.set_string(target, :setConfirmLabel, view.confirm_label)
        end
        unless view.cancel_label == "Cancel"
          sender.set_string(target, :setCancelLabel, view.cancel_label)
        end
        unless view.confirm_style == :default
          sender.set_string(target, :setConfirmStyle, view.confirm_style.to_s)
        end
      end

      def self.populate_toolbar(target : String, view : UI::Toolbar, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_string(target, :setTitle, view.title)
        sender.set_bool(target, :setShowsTitle, view.shows_title ? nil : false)
        unless view.items.empty?
          sender.set_string_array(target, :setItemLabels, view.items.map(&.label))
          sender.set_string_array(target, :setItemIcons, view.items.map { |i| i.icon || "" })
          # Default all placements to "primary"; the visit method may
          # override per-item if a richer placement model is wired later.
          sender.set_string_array(target, :setItemPlacements,
            view.items.map { |_| "primary" })
        end
        # Phase 5 v2: ALWAYS emit a materialSemantic key. Default is
        # :system_resolved → SwiftUI .bar fallback inside the facade;
        # explicit overrides flow through.
        ms = view.material_semantic
        sender.set_string(target, :setMaterialSemantic,
          ms.nil? ? "system_resolved" : ms.to_s)
      end

      def self.populate_form(target : String, view : UI::Form, sender : Sender)
        populate_view_common(target, view, sender)
        unless view.sections.empty?
          sender.set_string_array(target, :setSectionHeaders,
            view.sections.map { |s| s.header || "" })
          sender.set_string_array(target, :setSectionFooters,
            view.sections.map { |s| s.footer || "" })
          sender.set_int_array(target, :setSectionFieldCounts,
            view.sections.map(&.fields.size))
          # Flat array of all field labels across all sections.
          all_labels = [] of String
          view.sections.each do |s|
            s.fields.each { |f| all_labels << f.label }
          end
          sender.set_string_array(target, :setSectionFieldLabels, all_labels)
        end
      end

      def self.populate_grid(target : String, view : UI::Grid, sender : Sender)
        populate_view_common(target, view, sender)
        rs = view.row_spacing
        sender.set_number(target, :setRowSpacing, rs == 8.0 ? nil : rs)
        cs = view.column_spacing
        sender.set_number(target, :setColumnSpacing, cs == 8.0 ? nil : cs)
        unless view.alignment == UI::Alignment::Leading
          sender.set_string(target, :setAlignment, view.alignment.to_s.downcase)
        end
        # Always emit per-row cell counts when children exist; facade
        # slices the flat children array using these counts.
        unless view.children.empty?
          sender.set_int_array(target, :setRowCellCounts,
            view.children.map(&.size))
        end
      end

      def self.populate_card(target : String, view : UI::Card, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_string(target, :setTitle, view.title)
        sender.set_bool(target, :setIsOutlined, view.is_outlined ? true : nil)
        el = view.elevation
        sender.set_number(target, :setElevation, el == 1.0 ? nil : el)
        unless view.material == :secondary
          sender.set_string(target, :setMaterial, view.material.to_s)
        end
      end

      def self.populate_surface(target : String, view : UI::Surface, sender : Sender)
        populate_view_common(target, view, sender)
        el = view.elevation
        sender.set_number(target, :setElevation, el == 0.0 ? nil : el)
        te = view.tonal_elevation
        sender.set_number(target, :setTonalElevation, te == 0.0 ? nil : te)
        unless view.shape == :rectangle
          sender.set_string(target, :setShape, view.shape.to_s)
        end
      end

      def self.populate_menu_button(target : String, view : UI::MenuButton, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_string(target, :setIcon, view.icon)
        sender.set_bool(target, :setIsPullDown, view.is_pull_down ? true : nil)
        unless view.button_style == :default
          sender.set_string(target, :setButtonStyle, view.button_style.to_s)
        end
        sender.set_int(target, :setSelectedIndex,
          view.selected_index == 0 ? nil : view.selected_index)
        unless view.items.empty?
          sender.set_string_array(target, :setItemLabels, view.items.map(&.label))
          sender.set_string_array(target, :setItemIcons, view.items.map { |i| i.icon || "" })
          sender.set_bool_array(target, :setItemIsDestructive,
            view.items.map(&.is_destructive))
        end
      end

      def self.populate_toggle_button(target : String, view : UI::ToggleButton, sender : Sender)
        populate_view_common(target, view, sender)
        sender.set_string(target, :setIcon, view.icon)
        sender.set_bool(target, :setIsSelected, view.is_selected ? true : nil)
      end

      # `UI::ListView` (§6 #25). The Crystal side carries a sectioned list
      # (`Array(Section)`) with optional headers / footers per section and
      # a list-wide `ListStyle` enum. The Swift facade rebuilds the
      # SwiftUI `List { Section { ... } }` hierarchy from a flat
      # `childViews` array sliced by `setSectionItemCounts`.
      #
      # `selection_mode` is not a Crystal-side property today (verified
      # against `src/ui/views/list_view.cr`); the facade therefore uses
      # SwiftUI's default selection model. The `on_item_tap` Proc lives
      # on the view itself and is wired by the renderer's visit method
      # via callback-token registration (not through overrides).
      def self.populate_list_view(target : String, view : UI::ListView, sender : Sender)
        populate_view_common(target, view, sender)

        # ListStyle: Plain is the type default. Map the enum to the
        # camelCase facade key the Swift switch reads.
        unless view.style == UI::ListStyle::Plain
          key = case view.style
                when UI::ListStyle::Inset        then "inset"
                when UI::ListStyle::Grouped      then "grouped"
                when UI::ListStyle::InsetGrouped then "insetGrouped"
                when UI::ListStyle::Sidebar      then "sidebar"
                else                                  view.style.to_s.downcase
                end
          sender.set_string(target, :setListStyle, key)
        end

        # Separators default to true (SwiftUI default). Only emit when
        # the developer turned them off — the facade reads
        # `showsSeparators == false` as "hide row separators."
        unless view.shows_separators
          sender.set_bool(target, :setShowsSeparators, false)
        end

        # Per-section parallel arrays. Always emit when sections present
        # so the facade can slice the flat childViews back into sections.
        unless view.sections.empty?
          sender.set_string_array(target, :setSectionHeaders,
            view.sections.map { |s| s.header || "" })
          sender.set_string_array(target, :setSectionFooters,
            view.sections.map { |s| s.footer || "" })
          sender.set_int_array(target, :setSectionItemCounts,
            view.sections.map { |s| s.items.size })
        end
      end

      # ---------------------------------------------------------------
      # Glass — the Phase 3 "headline visual differentiator". On iOS 26 /
      # macOS 26 the facade routes through `.glassEffect()` for real
      # Liquid Glass; on pre-26 OSes it falls back to `.background(<Material>)`.
      #
      # `material` mirrors the Crystal `UI::GlassBackground.material`
      # symbol (:regular | :thin | :ultra_thin | :thick | :chrome). The
      # facade switch normalises camelCase keys (`ultraThin`) on the
      # Swift side; we emit them in the same shape so the facade
      # dispatch stays simple.
      # Glass populator. `apple_step` is the Apple-quantized step Symbol the
      # renderer has resolved via `tokens.material.apple_step(view.material)`.
      # The populator emits the facade `setMaterial:` key derived from the
      # resolved Symbol, not from `view.material` directly, so brand
      # intensity overrides cascade onto the SwiftUI Material enum case per
      # the Phase 5 brief's adapter_cardinality row 1 contract.
      #
      # `apple_step` defaults to `view.material` so spec-level callers that
      # don't have a renderer can still exercise the populator without
      # threading tokens through the test fixtures.
      def self.populate_glass_background(target : String, view : UI::GlassBackground, sender : Sender, apple_step : Symbol = view.material)
        populate_view_common(target, view, sender)

        # Map quantized Crystal Symbol -> Swift facade key. `:regular` is
        # the SwiftUI default; we still emit when the resolved step IS
        # :regular AND the view's declared material differs (brand
        # quantization shifted the step), so the facade receives the
        # resolved value rather than its own default.
        emit = apple_step != :regular || view.material != :regular
        if emit
          key = case apple_step
                when :ultra_thin  then "ultraThin"
                when :thin        then "thin"
                when :regular     then "regular"
                when :thick       then "thick"
                when :chrome      then "ultraThick" # closest SwiftUI Material analogue
                else                   apple_step.to_s
                end
          sender.set_string(target, :setMaterial, key)
        end
      end

      # Symbol-to-ObjC-selector helper. The Populator emits setter
      # symbols without a trailing colon (`:setStyle`,
      # `:setBackgroundColor`) because that's the shape the spec
      # recording sender asserts against. ObjC selectors for single-
      # argument setters need the colon; the production
      # `SwiftKitObjCSender` routes through this helper at the boundary
      # so the populator contract and the spec recording remain
      # symmetric.
      #
      # Idempotent: passing a Symbol that already ends in `:` returns
      # its String form unchanged so a future caller that knows the
      # ObjC convention can pass the canonical Symbol directly.
      def self.objc_setter_selector(setter : Symbol) : String
        name = setter.to_s
        name.ends_with?(':') ? name : "#{name}:"
      end
    end

    # ---------------------------------------------------------------------
    # Production `Sender` backed by `LibSwiftKitBridge`.
    #
    # This is the sender the AppKit / UIKit renderer's `visit(UI::Button)`
    # constructs. It holds the raw `APSK*Overrides` pointer the C
    # trampoline returned and forwards every `set_*` invocation to the
    # matching `apsk_overrides_set_*` `fun`. The `target : String`
    # argument the abstract contract passes is ignored — the production
    # sender already knows which overrides object it is populating from
    # the pointer captured at construction time. Symbol setter names are
    # stringified once at the C boundary via `to_s.to_unsafe`.
    #
    # The sender is gated on `flag?(:macos) || flag?(:ios)` because
    # `LibSwiftKitBridge` only resolves under those builds. The web /
    # Android renderers never reach this code path.
    # ---------------------------------------------------------------------
    {% if flag?(:macos) || flag?(:ios) %}
      class SwiftKitObjCSender < Populator::Sender
        # The `APSK*Overrides` pointer returned by `apsk_*_overrides_new`.
        # Lives at least as long as the sender; the renderer drops the
        # sender immediately after the matching `apsk_make_*` call, which
        # is the next ObjC autorelease-pool drain at the latest.
        getter overrides_ptr : Void*

        def initialize(@overrides_ptr : Void*)
        end

        def set_color(target : String, setter : Symbol, color : UI::Color?)
          return if color.nil?
          LibSwiftKitBridge.apsk_overrides_set_color(
            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
            color.r, color.g, color.b, color.a,
          )
        end

        def set_number(target : String, setter : Symbol, value : Float64?)
          return if value.nil?
          LibSwiftKitBridge.apsk_overrides_set_number(
            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe, value,
          )
        end

        def set_bool(target : String, setter : Symbol, value : Bool?)
          return if value.nil?
          LibSwiftKitBridge.apsk_overrides_set_bool(
            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe, value ? 1 : 0,
          )
        end

        def set_string(target : String, setter : Symbol, value : String?)
          return if value.nil?
          LibSwiftKitBridge.apsk_overrides_set_string(
            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe, value.to_unsafe,
          )
        end

        def set_string_array(target : String, setter : Symbol, values : Array(String))
          return if values.empty?
          # Build a stable buffer of UInt8* pointers. Crystal's String#to_unsafe
          # returns a pointer into the GC'd string body; the array itself must
          # outlive the trampoline call, which it does because we hold @buf
          # locally until apsk_overrides_set_string_array returns.
          count = values.size
          buf = Pointer(UInt8*).malloc(count.to_u64)
          values.each_with_index { |s, i| buf[i] = s.to_unsafe }
          LibSwiftKitBridge.apsk_overrides_set_string_array(
            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
            buf.as(Void*), count.to_i32,
          )
        end

        def set_int_array(target : String, setter : Symbol, values : Array(Int32))
          return if values.empty?
          count = values.size
          buf = Pointer(Int64).malloc(count.to_u64)
          values.each_with_index { |v, i| buf[i] = v.to_i64 }
          LibSwiftKitBridge.apsk_overrides_set_int_array(
            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
            buf, count.to_i32,
          )
        end

        def set_uint64_array(target : String, setter : Symbol, values : Array(UInt64))
          return if values.empty?
          count = values.size
          buf = Pointer(UInt64).malloc(count.to_u64)
          values.each_with_index { |v, i| buf[i] = v }
          LibSwiftKitBridge.apsk_overrides_set_uint64_array(
            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
            buf, count.to_i32,
          )
        end

        def set_bool_array(target : String, setter : Symbol, values : Array(Bool))
          return if values.empty?
          count = values.size
          buf = Pointer(Int32).malloc(count.to_u64)
          values.each_with_index { |v, i| buf[i] = v ? 1 : 0 }
          LibSwiftKitBridge.apsk_overrides_set_bool_array(
            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
            buf, count.to_i32,
          )
        end

        def set_int(target : String, setter : Symbol, value : Int32?)
          return if value.nil?
          LibSwiftKitBridge.apsk_overrides_set_int(
            @overrides_ptr, Populator.objc_setter_selector(setter).to_unsafe,
            value.to_i64,
          )
        end
      end
    {% end %}
  end
end
