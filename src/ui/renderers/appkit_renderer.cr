# macOS / AppKit platform renderer. Walks a UI::View tree and produces a native
# NSView hierarchy (NSStackView, NSButton, NSTextField, NSVisualEffectView, ...).

{% if flag?(:macos) %}
  require "../platform_visitor"
  require "../native/native_handle"
  require "../native/native_view"
  require "../native/callback_registry"
  require "../native/swiftkit_bridge"
  require "../native/swiftkit_overrides"
  require "../design_tokens"

  module UI::AppKit
    # ObjC bridge function bindings for the type-safe ARM64 wrappers
    # defined in objc_bridge.c. These function signatures MUST match
    # the C wrappers exactly -- on ARM64, each double argument occupies
    # a dedicated d-register and the cast must be precise.
    #
    # ## Struct types
    #
    # CGRect/CGPoint/CGSize are Homogeneous Floating-point Aggregates (HFA)
    # on ARM64. They are passed/returned in d0-d3 (CGRect), d0-d1 (CGPoint,
    # CGSize), NOT on the stack. Crystal passes these as value types that
    # map directly to the C struct layout.
    lib LibObjCBridge
      struct CGRect
        x : Float64
        y : Float64
        width : Float64
        height : Float64
      end

      # --- Section 1: Basic message sends (integer/pointer args) ---
      fun objc_send(obj : Void*, sel : Void*) : Void*
      fun objc_send_id(obj : Void*, sel : Void*, arg : Void*) : Void*
      fun objc_send_id_id(obj : Void*, sel : Void*, arg1 : Void*, arg2 : Void*) : Void*
      fun objc_send_id_id_id(obj : Void*, sel : Void*, arg1 : Void*, arg2 : Void*, arg3 : Void*) : Void*
      fun objc_send_bool(obj : Void*, sel : Void*, val : Int32) : Void
      fun objc_send_long(obj : Void*, sel : Void*, val : Int64) : Void*
      fun objc_send_ulong(obj : Void*, sel : Void*, val : UInt64) : Void*
      fun objc_send_void_id(obj : Void*, sel : Void*, arg : Void*) : Void
      fun objc_send_sel(obj : Void*, sel : Void*, arg : Void*) : Void
      fun objc_send_id_long(obj : Void*, sel : Void*, arg1 : Void*, arg2 : Int64) : Void*

      # --- Section 2: Double/float register sends ---
      fun objc_send_1d(obj : Void*, sel : Void*, d0 : Float64) : Void
      fun objc_send_1d_ret_id(obj : Void*, sel : Void*, d0 : Float64) : Void*
      fun objc_send_2d_ret_id(obj : Void*, sel : Void*, d0 : Float64, d1 : Float64) : Void*
      fun objc_send_4d_ret_id(obj : Void*, sel : Void*, d0 : Float64, d1 : Float64, d2 : Float64, d3 : Float64) : Void*

      # --- Section 3: CGRect / HFA sends ---
      fun objc_send_rect(obj : Void*, sel : Void*, rect : CGRect) : Void*
      fun objc_send_rect_void(obj : Void*, sel : Void*, rect : CGRect) : Void
      fun objc_send_ret_bool(obj : Void*, sel : Void*) : Int32

      # --- Section 4: Convenience helpers ---
      fun nsstring_from_cstr(str : UInt8*) : Void*
      fun nscolor_rgba(r : Float64, g : Float64, b : Float64, a : Float64) : Void*
      fun nscolor_white_alpha(white : Float64, alpha : Float64) : Void*
      fun nscolor_label_primary : Void*
      fun nscolor_label_secondary : Void*
      fun nscolor_label_tertiary : Void*
      fun nscolor_label_quaternary : Void*
      fun nscolor_control_background : Void*
      fun nscolor_separator : Void*
      # Phase 6.12A — NSColor.controlAccentColor for SYSTEM_ACCENT.
      fun nscolor_control_accent : Void*
      fun nsfont_system(size : Float64) : Void*
      fun nsfont_bold_system(size : Float64) : Void*
      fun nsfont_system_weight(size : Float64, weight : Float64) : Void*
      fun nsfont_monospaced_system(size : Float64, weight : Float64) : Void*
      fun nsfont_named(name : Void*, size : Float64) : Void*
      fun objc_add_subview(parent : Void*, child : Void*) : Void
      fun objc_set_autoresize(view : Void*, mask : UInt64) : Void
      fun objc_set_frame(obj : Void*, frame : CGRect) : Void
      fun objc_constrain_size(view : Void*, w : Float64, h : Float64) : Void
      fun objc_constrain_width(view : Void*, w : Float64) : Void
      fun objc_constrain_minimum_width(view : Void*, min_w : Float64) : Void
      fun objc_constrain_height(view : Void*, h : Float64) : Void
      fun nsscrollview_set_document_view(scroll_view : Void*, doc_view : Void*) : Void
      fun nsbutton_set_colored_title(button : Void*, title : Void*, color : Void*, font : Void*) : Void
      fun nsslider_set_track_fill_color(slider : Void*, color : Void*) : Void
      fun nsimageview_make_symbol(symbol_name : UInt8*, tint_color : Void*, size_pts : Float64) : Void*
      fun wkwebview_new(url : UInt8*, html : UInt8*, base_url : UInt8*, title : UInt8*, allows_navigation : Int32, allows_scripts : Int32) : Void*
      fun wkwebview_set_callback_tags(web_view : Void*, policy_tag : UInt64, start_tag : UInt64, finish_tag : UInt64, allows_navigation : Int32) : Void
      fun mkmapview_new(latitude : Float64, longitude : Float64, latitude_delta : Float64, longitude_delta : Float64, map_type : Int64, shows_user_location : Int32) : Void*
      fun mkmapview_add_annotation(map_view : Void*, latitude : Float64, longitude : Float64, title : UInt8*, subtitle : UInt8*) : Void
      fun video_player_view_new(url : UInt8*, shows_controls : Int32, auto_play : Int32, muted : Int32, loop : Int32) : Void*
      fun ap_ring_view_new(width : Float64, height : Float64, center_x : Float64, center_y : Float64, radius : Float64, track_start_angle : Float64, track_end_angle : Float64, progress_start_angle : Float64, progress_end_angle : Float64, line_width : Float64, track_r : Float64, track_g : Float64, track_b : Float64, track_a : Float64, progress_r : Float64, progress_g : Float64, progress_b : Float64, progress_a : Float64) : Void*
      fun ap_activity_rings_view_new(size : Float64, thickness : Float64, gap : Float64, move_progress : Float64, exercise_progress : Float64, stand_progress : Float64) : Void*
      fun nssharingservicepicker_present(anchor_view : Void*, text : UInt8*, url : UInt8*) : Void

      # --- Section 5a: NSSwitch factory (macOS 10.15+) ---
      fun nsswitch_new(state_on : Int32, enabled : Int32) : Void*
      fun nsswitch_set_tint(sw_ptr : Void*, color : Void*) : Void

      # --- ObjC runtime ---
      fun sel_registerName(name : UInt8*) : Void*
      fun objc_getClass(name : UInt8*) : Void*

      # --- Section 5: CrystalActionDispatcher registration ---
      fun register_crystal_action_dispatcher : Void

      # Phase 6.10 Rem 4 (Item 2B/2C) — runtime device-metrics queries
      # (same wrappers as the UIKit renderer; macOS branch returns 0
      # for safe-area insets and derives size class from window width).
      fun objc_screen_width : Float64
      fun objc_screen_height : Float64
      fun objc_macos_screen_width : Float64
      fun objc_safe_area_top : Float64
      fun objc_safe_area_bottom : Float64
      fun objc_safe_area_leading : Float64
      fun objc_safe_area_trailing : Float64
      fun objc_horizontal_size_class : Int32
      fun objc_vertical_size_class : Int32
    end

    # Renders a UI::View tree to native AppKit views via the ObjC bridge.
    #
    # Each `visit` method:
    #   1. Allocates and initializes the appropriate AppKit view class
    #   2. Configures its properties (text, font, color, etc.)
    #   3. Wraps the raw pointer in a `NativeHandle` (owned)
    #   4. Creates a `NativeView` node
    #   5. If inside a container, adds as arranged subview + child node
    #   6. If top-level, sets as `@result`
    #
    # ## Usage
    #
    # ```
    # label = UI::Label.new("Hello, macOS!")
    # renderer = UI::AppKit::Renderer.new
    # label.accept(renderer)
    # native_view = renderer.result # => NativeView wrapping an NSTextField
    # ```
    #
    # ## Memory Management
    #
    # All native views created by the renderer are owned (+1 retain count)
    # via `ObjC.owned`. Call `NativeView#teardown!` on the root result to
    # release the entire tree.
    class Renderer < UI::PlatformVisitor
      # The root NativeView produced by visiting the top-level view.
      @result : NativeView? = nil

      # Stack of NativeViews for container nesting. When visiting children
      # inside a VStack/HStack/ZStack/ScrollView, the parent is on top of
      # the stack so children can be added to it.
      @stack : Array(NativeView)

      # Tracks which NativeViews on the stack are NSStackViews (true) vs
      # plain NSViews (false). Used by push_native to decide between
      # addArrangedSubview: and addSubview:.
      @stack_is_nsstack : Array(Bool)

      # Latches once `apsk_runtime_initialize` has handed the Crystal action
      # trampoline pointer to AssetPipelineSwiftKit's `APSKRuntime`. The
      # trampoline is process-wide so the install only needs to happen once
      # per renderer lifetime (no harm in repeating, but no benefit either).
      @swiftkit_action_trampoline_installed : Bool = false

      def initialize
        @stack = [] of NativeView
        @stack_is_nsstack = [] of Bool
        LibObjCBridge.register_crystal_action_dispatcher

        # Phase 6.10 Rem 4 (Item 2B/2C) — install the runtime device-
        # metrics provider so screens can query
        # `UI::DesignTokens::DeviceMetrics.current` for the live screen
        # bounds + size class. macOS has no safe-area concept, so
        # `safe_area_*_pt` are always 0; size class is derived from the
        # main window width (768pt threshold).
        UI::DesignTokens::Device.install_provider do
          UI::DesignTokens::DeviceMetrics.new(
            screen_width_pt: LibObjCBridge.objc_macos_screen_width,
            screen_height_pt: LibObjCBridge.objc_screen_height,
            safe_area_top_pt: LibObjCBridge.objc_safe_area_top,
            safe_area_bottom_pt: LibObjCBridge.objc_safe_area_bottom,
            safe_area_leading_pt: LibObjCBridge.objc_safe_area_leading,
            safe_area_trailing_pt: LibObjCBridge.objc_safe_area_trailing,
            horizontal_size_class: size_class_from_int(LibObjCBridge.objc_horizontal_size_class),
            vertical_size_class: size_class_from_int(LibObjCBridge.objc_vertical_size_class),
          )
        end
      end

      private def size_class_from_int(value : Int32) : UI::DesignTokens::SizeClass
        case value
        when 1 then UI::DesignTokens::SizeClass::Compact
        when 2 then UI::DesignTokens::SizeClass::Regular
        else        UI::DesignTokens::SizeClass::Unspecified
        end
      end

      # Returns the root NativeView produced by the last top-level visit.
      # Raises if no view has been visited yet.
      def result : NativeView
        @result.not_nil!
      end

      # Convenience: visit a view and return its NativeView.
      def render(view : UI::View) : NativeView
        # Initialise the SwiftKit runtime and propagate the active brand
        # tint before traversing the tree. Re-applying the brand tint on
        # every render entry is what makes
        # `renderer.design_tokens = Tokens.default.with_brand(...)` flip
        # the rendered button pixel on the next render — the Option B
        # cascade contract surfaced by the Architect handoff
        # `phase-03-stopped-early-2026-05-20.md`.
        ensure_swiftkit_runtime!

        view.accept(self)
        nv = result
        # Wire tab order for editable text fields
        fields = [] of Void*
        collect_text_fields(nv, fields)
        if fields.size >= 2
          fields.each_with_index do |ptr, i|
            next_ptr = fields[(i + 1) % fields.size]
            LibObjCBridge.objc_send_void_id(ptr, sel("setNextKeyView:"), next_ptr)
          end
        end
        nv
      end

      # -----------------------------------------------------------------
      # Visit: Label -> NSTextField (non-editable)
      # -----------------------------------------------------------------
      # Visit: Label -> SwiftUI Text hosted in NSHostingView.
      # See Button visit comment for the Phase 3 migration rationale.
      def visit(view : UI::Label)
        overrides_ptr = LibSwiftKitBridge.apsk_label_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_label(target_str, view, sender)

        state_slot = Pointer(Void).null.as(Void*)
        state_box = pointerof(state_slot)
        # Pin `text` into a local before reaching for `to_unsafe` so the
        # Crystal GC keeps the String body alive across the FFI call.
        text = view.text
        ptr = LibSwiftKitBridge.apsk_make_label_reactive(
          text.to_unsafe, overrides_ptr, state_box,
        )

        handle = ObjC.owned(ptr, label: "NSHostingView[Label]")
        unless state_slot.null?
          handle.state_handle = state_slot
          view.swiftkit_state_handle = state_slot
        end
        native = NativeView.new(handle)
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Button -> SwiftUI Button hosted in NSHostingController
      #
      # Phase 3a migration (Option B — SwiftUI Default Supremacy):
      #
      # The renderer no longer constructs an NSButton with per-widget brand
      # colour injection (amber-gold fill, plum-for-destructive, dark-mode
      # contrast cascade, role × style matrix). Instead it routes through
      # AssetPipelineSwiftKit's `APSKButtonFacade`, which emits a raw
      # SwiftUI `Button(role:action:)` and inherits brand identity via the
      # `.tint()` cascade installed by `apsk_runtime_set_brand_tint` (see
      # `render(...)` / `ensure_swiftkit_runtime!`).
      #
      # Default behaviour is now whatever SwiftUI gives us:
      #   - System tint (resolved to `brand_primary` via the tint cascade)
      #   - System body font + Dynamic Type
      #   - Built-in hover / press / focus animations
      #   - VoiceOver `.button` trait + Dark Aqua tracking
      #   - Liquid Glass treatment for `.borderedProminent` on macOS 26+
      #
      # Per-widget overrides only fire when the developer explicitly sets
      # the matching `UI::Button` property (`view.background`,
      # `view.foreground_color`, `view.style`, `view.role`,
      # `view.disabled`, `view.symbol`, etc.) — the default-detection
      # invariant in `Populator.populate_button` skips every setter whose
      # backing property is still at its type default.
      #
      # See `docs/initiative-cross-platform-ui/handoff/phase-03-stopped-early-2026-05-20.md`
      # for the architectural decision context and the prior ~230-line
      # NSButton implementation this replaces.
      # -----------------------------------------------------------------
      def visit(view : UI::Button)
        # 1. Allocate a fresh APSKButtonOverrides instance and populate it
        #    via the Sender contract. The String target identifier is a
        #    debug aid (used by spec recorders); the production sender
        #    closes over the pointer and ignores the string.
        overrides_ptr = LibSwiftKitBridge.apsk_button_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_button(target_str, view, sender)

        # 2. Register the tap handler. Token 0 means "no callback wired."
        #    APSKRuntime invokes `ap_swiftkit_invoke_action(token, 0.0)` on
        #    tap; the trampoline routes via `CallbackRegistry.invoke_swiftkit`
        #    back to the original Crystal Proc.
        action_token = 0_u64
        if tap_handler = view.on_tap
          action_token = UI::CallbackRegistry.register_action(&tap_handler)
        end

        # 3. Build the SwiftUI Button and hand the underlying NSView back.
        #    Reactive entry so Crystal-side property mutations (background,
        #    foreground_color, corner_radius) re-render through SwiftUI.
        state_slot = Pointer(Void).null.as(Void*)
        state_box = pointerof(state_slot)
        # Pin `label` into a local before reaching for `to_unsafe` so the
        # Crystal GC keeps the String body alive across the FFI call.
        button_label = view.label
        ptr = LibSwiftKitBridge.apsk_make_button_reactive(
          button_label.to_unsafe, overrides_ptr, action_token, state_box,
        )

        # 4. Wrap and track. The NSHostingController is associated with the
        #    NSView via objc_setAssociatedObject inside HostingHelpers.host,
        #    so the controller's lifetime tracks the view's.
        handle = ObjC.owned(ptr, label: "NSHostingController[Button]")
        unless state_slot.null?
          handle.state_handle = state_slot
          view.swiftkit_state_handle = state_slot
        end
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: VStack -> NSStackView (vertical, orientation = 1)
      # -----------------------------------------------------------------
      def visit(view : UI::VStack)
        ptr = alloc_init("NSStackView")

        # NSUserInterfaceLayoutOrientationVertical = 1
        LibObjCBridge.objc_send_long(ptr, sel("setOrientation:"), 1_i64)

        # Spacing
        LibObjCBridge.objc_send_1d(ptr, sel("setSpacing:"), view.spacing)

        # NSStackView alignment for vertical orientation uses NSLayoutAttribute.
        # NSLayoutAttributeLeading=5, NSLayoutAttributeCenterX=9, NSLayoutAttributeTrailing=6
        # Alignment::Fill -> Leading (5). For a VStack, "fill" means children stretch
        # to fill the VStack's WIDTH (the cross-axis). NSLayoutAttributeLeading pins
        # children to the leading edge. The default GravityAreas distribution controls
        # height (main-axis) so each child keeps its intrinsic height -- which is what
        # we want for a page VStack (top_bar ~50pt, divider ~1pt, body fills rest).
        # Do NOT set setDistribution:0 on VStack -- that would distribute HEIGHT
        # equally among all children, breaking the page layout.
        alignment_val = case view.alignment
                        when Alignment::Leading  then 5_i64
                        when Alignment::Center   then 9_i64
                        when Alignment::Trailing then 6_i64
                        when Alignment::Fill     then 5_i64 # Leading edge; GravityAreas keeps intrinsic heights
                        else                          9_i64
                        end
        LibObjCBridge.objc_send_long(ptr, sel("setAlignment:"), alignment_val)

        # Padding via NSStackView.edgeInsets (NSEdgeInsets = 4 doubles, same ABI as CGRect)
        p = view.padding
        if p.top > 0 || p.leading > 0 || p.bottom > 0 || p.trailing > 0
          insets = LibObjCBridge::CGRect.new(x: p.top, y: p.leading, width: p.bottom, height: p.trailing)
          LibObjCBridge.objc_send_rect_void(ptr, sel("setEdgeInsets:"), insets)
        end

        # Common properties
        apply_common_properties(ptr, view)

        # Dark-mode bake (gaps.md iteration-21 pattern): NSStackView's offscreen
        # cacheDisplayInRect: path renders the layer background as transparent
        # when no explicit fill is set, so subview text (which NSTextField renders
        # via NSColor.labelColor -> near-white in dark) is lost on the white bitmap.
        # Enable wantsLayer and bake an explicit CGColor fill keyed off HIG_APPEARANCE
        # so all VStack captures are legible in both appearances.
        # IMPORTANT: CALayer.setBackgroundColor: takes a CGColorRef, NOT an NSColor.
        # Call nscolor.CGColor first; pass the result to the layer.
        #
        # When the view has an EXPLICIT background color set (view.background != nil),
        # honour that color instead of the hardcoded white/dark fill. This prevents
        # scene-container VStacks (e.g. DockScene's focal_column) from overriding
        # their transparent or brand-colored backgrounds with an opaque white fill.
        #
        # When HIG_BACKDROP_PATH is set, the capture window has a backdrop NSImageView
        # beneath the chrome and NSVisualEffectView with .withinWindow blending samples
        # it. Any opaque CALayer fill on a nested VStack blocks the compositor from
        # reaching the backdrop, producing solid fills instead of frosted glass.
        # Use clearColor (alpha = 0) so every NSStackView in the chrome hierarchy is
        # transparent and the compositor blurs the backdrop through the glass card.
        # Text legibility is preserved because NSTextField uses NSColor.labelColor,
        # which the live-compositor window applies correctly via its appearance.
        #
        # When no backdrop is set (offscreen path for non-glass slugs), fall back to
        # the iter-21 opaque fill so standalone VStack captures remain legible.
        LibObjCBridge.objc_send_bool(ptr, sel("setWantsLayer:"), 1)
        layer_ptr = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer_ptr.null?
          explicit_bg = view.background
          bg_ns = if c = explicit_bg
                    # View has an explicit background — use it. Alpha=0 means transparent.
                    LibObjCBridge.nscolor_rgba(c.r, c.g, c.b, c.a)
                  elsif ENV["HIG_BACKDROP_PATH"]? && !ENV["HIG_BACKDROP_PATH"].to_s.empty?
                    # Backdrop-mode: keep VStack transparent so NSVisualEffectView can blur
                    # the backdrop NSImageView beneath. The live-window NSWindow provides the
                    # appearance-correct surface; opaque fills here would block the glass compositor.
                    # Tier 2 platform default: fully-transparent fallback (alpha=0).
                    LibObjCBridge.nscolor_rgba(0.0, 0.0, 0.0, 0.0)
                  else
                    # No backdrop — apply the dark-mode legibility fix (gaps.md iter-21).
                    # Tier 2 platform defaults: NSColor.windowBackgroundColor approximations
                    # for dark/light appearance in the offscreen capture path.
                    dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")
                    dark_mode ? LibObjCBridge.nscolor_rgba(0.12, 0.12, 0.12, 1.0) :  # Tier 2 dark
LibObjCBridge.nscolor_rgba(1.0, 1.0, 1.0, 1.0)                                       # Tier 2 light
                  end
          unless bg_ns.null?
            cg_bg = LibObjCBridge.objc_send(bg_ns, sel("CGColor"))
            LibObjCBridge.objc_send_void_id(layer_ptr, sel("setBackgroundColor:"), cg_bg) unless cg_bg.null?
          end
        end

        handle = ObjC.owned(ptr, label: "NSStackView[v]")
        native = NativeView.new(handle)

        # Push onto stack, visit children, pop
        push_stack(native, is_nsstack: true)
        view.children.each do |child|
          child.accept(self)
        end
        pop_stack

        # Each child NativeView was added to native.children and its raw
        # ptr was added as an arranged subview during push_native.

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: HStack -> NSStackView (horizontal, orientation = 0)
      # -----------------------------------------------------------------
      def visit(view : UI::HStack)
        ptr = alloc_init("NSStackView")

        # NSUserInterfaceLayoutOrientationHorizontal = 0
        LibObjCBridge.objc_send_long(ptr, sel("setOrientation:"), 0_i64)

        # Spacing
        LibObjCBridge.objc_send_1d(ptr, sel("setSpacing:"), view.spacing)

        # NSStackView alignment for horizontal orientation uses NSLayoutAttribute.
        # NSLayoutAttributeTop=3, NSLayoutAttributeCenterY=10, NSLayoutAttributeBottom=4
        # Alignment::Fill -> NSLayoutAttributeTop (3) so children align to top edge.
        # NSStackViewDistributionFill (0) is set for Fill alignment so that arranged
        # subviews without explicit width constraints expand to fill available space.
        alignment_val = case view.alignment
                        when Alignment::Top    then 3_i64
                        when Alignment::Center then 10_i64
                        when Alignment::Bottom then 4_i64
                        when Alignment::Fill   then 3_i64 # top-align; fill handled by distribution
                        else                        10_i64
                        end
        LibObjCBridge.objc_send_long(ptr, sel("setAlignment:"), alignment_val)

        # NSStackViewDistribution: GravityAreas=-1, Fill=0, FillEqually=1,
        # FillProportionally=2, EqualSpacing=3, EqualCentering=4.
        # For Alignment::Fill, use Fill (0) so the last unconstrained arranged
        # subview expands to fill all remaining horizontal space.
        # For all other alignments, use GravityAreas (-1, the AppKit default).
        if view.alignment == Alignment::Fill
          LibObjCBridge.objc_send_long(ptr, sel("setDistribution:"), 0_i64)
        end

        # Padding via NSStackView.edgeInsets (NSEdgeInsets = 4 doubles, same ABI as CGRect)
        p = view.padding
        if p.top > 0 || p.leading > 0 || p.bottom > 0 || p.trailing > 0
          insets = LibObjCBridge::CGRect.new(x: p.top, y: p.leading, width: p.bottom, height: p.trailing)
          LibObjCBridge.objc_send_rect_void(ptr, sel("setEdgeInsets:"), insets)
        end

        # Common properties
        apply_common_properties(ptr, view)

        handle = ObjC.owned(ptr, label: "NSStackView[h]")
        native = NativeView.new(handle)

        push_stack(native, is_nsstack: true)
        view.children.each do |child|
          child.accept(self)
        end
        pop_stack

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ZStack -> NSView (overlay container)
      #
      # Children are added as subviews in order. Later children are drawn
      # on top. Each child gets an autoresizing mask to fill the parent.
      # -----------------------------------------------------------------
      def visit(view : UI::ZStack)
        ptr = alloc_init("NSView")

        # Common properties
        apply_common_properties(ptr, view)

        handle = ObjC.owned(ptr, label: "NSView[zstack]")
        native = NativeView.new(handle)

        push_stack(native, is_nsstack: false)
        view.children.each do |child|
          child.accept(self)
        end
        pop_stack

        # For ZStack children, set autoresizing mask to fill parent:
        # NSViewWidthSizable (2) | NSViewHeightSizable (16) = 18
        native.children.each do |child_nv|
          if child_nv.handle.valid?
            child_ptr = child_nv.handle.ptr!
            LibObjCBridge.objc_set_autoresize(child_ptr, 18_u64)
          end
        end

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Image -> SwiftUI Image hosted in NSHostingView.
      # -----------------------------------------------------------------
      def visit(view : UI::Image)
        overrides_ptr = LibSwiftKitBridge.apsk_image_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_image(target_str, view, sender)

        ptr = LibSwiftKitBridge.apsk_make_image(view.source.to_unsafe, overrides_ptr)
        emit(ptr, "NSHostingView[Image]")
      end

      # -----------------------------------------------------------------
      # Visit: TextField -> SwiftUI TextField hosted in NSHostingView.
      # When `secure_entry == true` the facade emits SwiftUI.SecureField.
      # The action token carries a value-changed dispatch through
      # CallbackBridge; the Crystal-side proc receives a String — Phase 3
      # ships an action-only stub (token value channel is the new length),
      # richer string-bound dispatch is a Phase 5 follow-up.
      # -----------------------------------------------------------------
      def visit(view : UI::TextField)
        overrides_ptr = LibSwiftKitBridge.apsk_text_field_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_text_field(target_str, view, sender)

        # Phase 6.10 Rem 4 (Item 1) — string-typed on_change channel.
        # See the matching uikit_renderer.cr fix for the rationale; the
        # cross-platform TextFieldFacade fires both the legacy numeric
        # length signal and the new `fireString` trampoline.
        #
        # Phase 8B iter 3 (Item 4) — FormState wiring. If the TextField
        # has a non-empty `name` property, wrap the user's on_change so
        # it ALSO calls `form_state.update(name, new_value)`. The
        # wrapper captures the current FormState reference AND its
        # mount token at wire-time; stale callbacks (fired after
        # navigation away from this screen) are no-ops.
        wrapped_handler = UI::FormStateRendererHook.wrap_text_handler(view)
        action_token = 0_u64
        if wrapped_handler
          action_token = UI::CallbackRegistry.register_string(wrapped_handler)
        end

        ptr = LibSwiftKitBridge.apsk_make_text_field(
          view.placeholder.to_unsafe, view.text.to_unsafe,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[TextField]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ScrollView -> NSScrollView
      # -----------------------------------------------------------------
      def visit(view : UI::ScrollView)
        ptr = alloc_init("NSScrollView")

        # Scroll axes
        LibObjCBridge.objc_send_bool(ptr, sel("setHasVerticalScroller:"), view.scroll_vertical ? 1 : 0)
        LibObjCBridge.objc_send_bool(ptr, sel("setHasHorizontalScroller:"), view.scroll_horizontal ? 1 : 0)

        # Scroll indicators visibility
        unless view.shows_indicators
          # NSScrollerKnobStyleDefault = 0; setting scrollerStyle to overlay (1)
          # hides the scroller chrome when not actively scrolling.
          LibObjCBridge.objc_send_long(ptr, sel("setScrollerStyle:"), 1_i64)
        end

        # Explicit viewport size constraint.  NSScrollView inside an NSStackView
        # collapses to zero height if neither a hugging-priority nor an explicit
        # Auto Layout constraint is set, because the stack cannot determine the
        # scroll view's intrinsicContentSize from its (arbitrarily tall) content.
        # Use objc_constrain_height (height-only) when only height is specified;
        # use objc_constrain_size when both axes are explicitly set.
        if view.frame_width > 0.0 && view.frame_height > 0.0
          LibObjCBridge.objc_constrain_size(ptr, view.frame_width, view.frame_height)
        elsif view.frame_height > 0.0
          LibObjCBridge.objc_constrain_height(ptr, view.frame_height)
        end

        # Common properties
        apply_common_properties(ptr, view)

        handle = ObjC.owned(ptr, label: "NSScrollView")
        native = NativeView.new(handle)

        # Visit the content subtree in isolation (render_detached) so its
        # NSStackView is NOT added as a plain subview of NSScrollView via
        # addSubview:.  Use nsscrollview_set_document_view which calls
        # setDocumentView: AND wires Auto Layout constraints (leading/trailing/top
        # pinned to NSClipView) so the NSStackView fills the scroll width and
        # can grow vertically.  Without the width constraint the NSStackView has
        # no reference width and collapses to zero.
        if content = view.content
          if content_nv = render_detached(content)
            native.add_child(content_nv)
            if content_nv.handle.valid?
              LibObjCBridge.nsscrollview_set_document_view(ptr, content_nv.handle.ptr!)
            end
          end
        end

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Spacer -> NSView (empty, flexible)
      #
      # Spacers in an NSStackView expand to fill available space by having
      # low content hugging priority. In a non-stack context they act as
      # empty transparent views.
      # -----------------------------------------------------------------
      def visit(view : UI::Spacer)
        ptr = alloc_init("NSView")

        # Disable autoresizing mask translation so Auto Layout controls size
        LibObjCBridge.objc_send_bool(ptr, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)

        # If min_length > 0, set the frame as a minimum size hint.
        if view.min_length > 0
          min = view.min_length
          rect = LibObjCBridge::CGRect.new(x: 0.0, y: 0.0, width: min, height: min)
          LibObjCBridge.objc_set_frame(ptr, rect)
        end

        # Common properties
        apply_common_properties(ptr, view)

        emit(ptr, "NSView[spacer]")
      end

      # -----------------------------------------------------------------
      # Visit: Toggle -> NSSwitch (pill-shaped switch, macOS 10.15+)
      #
      # NSSwitch is the HIG-correct control for a binary on/off setting on
      # macOS. It renders as a pill-shaped track (green when on, gray when
      # off) -- the same shape as UISwitch on iOS. NSButton with
      # buttonType:NSSwitchButton (3) is the checkbox style and is WRONG for
      # this component.
      #
      # API notes:
      #   setState: NSControlStateValueOn (1) / NSControlStateValueOff (0)
      #   setEnabled: BOOL -- dimmed when NO
      #   setContentTintColor: NSColor -- overrides the green track tint
      #     (macOS 12+). Ignored silently on 10.15/11 if the selector is
      #     absent, so we send it unconditionally when tint_color is set.
      #   setTranslatesAutoresizingMaskIntoConstraints:NO -- required so
      #     NSStackView can drive layout without ambiguous constraint warnings.
      # -----------------------------------------------------------------
      def visit(view : UI::Toggle)
        overrides_ptr = LibSwiftKitBridge.apsk_toggle_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_toggle(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(v != 0.0)
          end
        end

        state_slot = Pointer(Void).null.as(Void*)
        state_box = pointerof(state_slot)
        ptr = LibSwiftKitBridge.apsk_make_toggle_reactive(
          view.label.to_unsafe, view.is_on ? 1 : 0, overrides_ptr,
          action_token, state_box,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Toggle]")
        unless state_slot.null?
          handle.state_handle = state_slot
          view.swiftkit_state_handle = state_slot
        end
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Checkbox -> NSButton (checkbox style)
      # -----------------------------------------------------------------
      def visit(view : UI::Checkbox)
        overrides_ptr = LibSwiftKitBridge.apsk_checkbox_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_checkbox(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(v != 0.0)
          end
        end

        ptr = LibSwiftKitBridge.apsk_make_checkbox(
          view.label.to_unsafe, view.is_checked ? 1 : 0, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Checkbox]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: RadioGroup -> SwiftUI Picker(...).pickerStyle(.radioGroup).
      # -----------------------------------------------------------------
      def visit(view : UI::RadioGroup)
        overrides_ptr = LibSwiftKitBridge.apsk_radio_group_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_radio_group(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(v.to_i32)
          end
        end

        # Build a C array of UTF-8 pointers for the options.
        opt_count = view.options.size
        opts_buf = Pointer(UInt8*).malloc(opt_count.to_u64)
        view.options.each_with_index do |opt, idx|
          opts_buf[idx] = opt.to_unsafe
        end

        ptr = LibSwiftKitBridge.apsk_make_radio_group(
          opts_buf.as(Void*), opt_count.to_i32, view.selected_index.to_i32,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[RadioGroup]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Slider -> SwiftUI Slider(value:in:).
      # -----------------------------------------------------------------
      def visit(view : UI::Slider)
        overrides_ptr = LibSwiftKitBridge.apsk_slider_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_slider(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(v)
          end
        end

        state_slot = Pointer(Void).null.as(Void*)
        state_box = pointerof(state_slot)
        ptr = LibSwiftKitBridge.apsk_make_slider_reactive(
          view.value, view.minimum, view.maximum, overrides_ptr,
          action_token, state_box,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Slider]")
        unless state_slot.null?
          handle.state_handle = state_slot
          view.swiftkit_state_handle = state_slot
        end
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: NavigationStack -> NSView (container for navigation content)
      # -----------------------------------------------------------------
      def visit(view : UI::NavigationStack)
        # SwiftUI NavigationStack facade. The current top-of-stack view
        # is rendered detached to obtain its native pointer, then handed
        # to the facade as a one-element children array.
        overrides_ptr = LibSwiftKitBridge.apsk_navigation_stack_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_navigation_stack(target_str, view, sender)

        children_native = [] of NativeView
        if detached = render_detached(view.current_view)
          children_native << detached
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_navigation_stack(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[NavigationStack]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: NavigationLink -> SwiftUI NavigationLink facade.
      # -----------------------------------------------------------------
      def visit(view : UI::NavigationLink)
        overrides_ptr = LibSwiftKitBridge.apsk_navigation_link_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_navigation_link(target_str, view, sender)

        children_native = [] of NativeView
        if detached = render_detached(view.destination)
          children_native << detached
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_navigation_link(
          view.label.to_unsafe, child_buf.as(Void*),
          children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[NavigationLink]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: TabView -> NSVisualEffectView (Liquid Glass root) containing
      #                   a vertical NSStackView with content + tab bar row.
      #
      # HIG tab-bars: "A tab bar lets people navigate between top-level
      # sections of your app." On iOS the bar floats at the bottom with
      # a Liquid Glass background. On macOS there is no direct UITabBar
      # equivalent; we render the whole component inside NSVisualEffectView
      # (NSVisualEffectMaterialMenu = 10, tracks light/dark automatically)
      # so the glass is unambiguously present and the AXScreenshot captures it.
      #
      # Structure:
      #   NSVisualEffectView (glass root)
      #     NSStackView (outer, vertical, no spacing)
      #       NSStackView (content area, grows to fill)
      #         <selected tab content>
      #       NSBox (separator, 0.5pt horizontal divider)
      #       NSStackView (tab row, horizontal, equal-width cells)
      #         cell_0 .. cell_N  (vertical: NSImageView + NSTextField)
      #
      # Selected tab: system blue 0.0/0.478/1.0 (or selected_tint_color).
      # Unselected tabs: NSColor.secondaryLabelColor (appearance-tracking).
      # -----------------------------------------------------------------
      def visit(view : UI::TabView)
        # SwiftUI TabView facade. Each tab's content is rendered detached
        # to obtain a native pointer; the facade wraps each in
        # APSKHostedChild + applies .tabItem with the parallel label/icon
        # arrays from the overrides.
        overrides_ptr = LibSwiftKitBridge.apsk_tab_view_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_tab_view(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(v.to_i32)
          end
        end

        children_native = [] of NativeView
        view.tabs.each do |tab|
          if d = render_detached(tab.content)
            children_native << d
          else
            empty_ptr = alloc_init("NSView")
            children_native << NativeView.new(ObjC.owned(empty_ptr, label: "NSView[tab-empty]"))
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_tab_view(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[TabView]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ProgressView -> NSProgressIndicator
      # -----------------------------------------------------------------
      def visit(view : UI::ProgressView)
        ptr = alloc_init("NSProgressIndicator")

        # NSProgressIndicatorStyleBar = 0, NSProgressIndicatorStyleSpinning = 1
        style_val = view.style == UI::ProgressStyle::Circular ? 1_i64 : 0_i64
        LibObjCBridge.objc_send_long(ptr, sel("setStyle:"), style_val)

        if val = view.value
          # Determinate progress (0.0 to 1.0, displayed as 0-100)
          LibObjCBridge.objc_send_bool(ptr, sel("setIndeterminate:"), 0)
          LibObjCBridge.objc_send_1d(ptr, sel("setMaxValue:"), 1.0)
          LibObjCBridge.objc_send_1d(ptr, sel("setDoubleValue:"), val)
        else
          # Indeterminate (spinning)
          LibObjCBridge.objc_send_bool(ptr, sel("setIndeterminate:"), 1)
          LibObjCBridge.objc_send(ptr, sel("startAnimation:"))
        end

        apply_common_properties(ptr, view)

        emit(ptr, "NSProgressIndicator")
      end

      # -----------------------------------------------------------------
      # Visit: ActivityIndicator -> NSProgressIndicator (spinning)
      # -----------------------------------------------------------------
      def visit(view : UI::ActivityIndicator)
        ptr = alloc_init("NSProgressIndicator")

        # NSProgressIndicatorStyleSpinning = 1
        LibObjCBridge.objc_send_long(ptr, sel("setStyle:"), 1_i64)
        LibObjCBridge.objc_send_bool(ptr, sel("setIndeterminate:"), 1)

        if view.is_animating
          LibObjCBridge.objc_send(ptr, sel("startAnimation:"))
        else
          LibObjCBridge.objc_send(ptr, sel("stopAnimation:"))
        end

        apply_common_properties(ptr, view)

        emit(ptr, "NSProgressIndicator[spinner]")
      end

      # -----------------------------------------------------------------
      # Visit: Alert -> NSVisualEffectView (hudWindow material) inline card
      #
      # HIG: Alerts are surface components (presentation category). They
      # require Liquid Glass. NSVisualEffectMaterialHUDWindow (= 7) is the
      # correct material — it renders the frosted-glass HUD panel that Apple
      # uses for system alerts on macOS.
      #
      # For production use, callers that want a true modal NSAlert should
      # present via NSAlert directly. This inline rendering path is used
      # by the HIG validation host (screenshot isolation). The material,
      # corner radius, and role-coloring are HIG-faithful.
      # -----------------------------------------------------------------
      def visit(view : UI::Alert)
        # SwiftUI .alert(title:isPresented:actions:message:) facade.
        overrides_ptr = LibSwiftKitBridge.apsk_alert_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_alert(target_str, view, sender)

        # Register each button's action token; pass as UInt64 array.
        tokens = [] of UInt64
        callback_ids = [] of UInt64
        view.buttons.each do |btn|
          if action = btn.action
            tok = UI::CallbackRegistry.register_action(&action)
            tokens << tok
            callback_ids << tok
          else
            tokens << 0_u64
          end
        end
        sender.set_uint64_array(target_str, :setButtonTokens, tokens)

        ptr = LibSwiftKitBridge.apsk_make_alert(
          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Alert]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Picker -> NSPopUpButton (menu style) or NSSegmentedControl
      # -----------------------------------------------------------------
      def visit(view : UI::Picker)
        overrides_ptr = LibSwiftKitBridge.apsk_picker_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_picker(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(v.to_i32)
          end
        end

        opt_count = view.options.size
        opts_buf = Pointer(UInt8*).malloc(opt_count.to_u64)
        view.options.each_with_index { |o, i| opts_buf[i] = o.to_unsafe }

        ptr = LibSwiftKitBridge.apsk_make_picker(
          view.label.to_unsafe, opts_buf.as(Void*), opt_count.to_i32,
          view.selected_index.to_i32, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Picker]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: IconButton -> SwiftUI Button with SF Symbol label.
      # -----------------------------------------------------------------
      def visit(view : UI::IconButton)
        overrides_ptr = LibSwiftKitBridge.apsk_icon_button_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_icon_button(target_str, view, sender)

        action_token = 0_u64
        if tap_handler = view.on_tap
          action_token = UI::CallbackRegistry.register_action(&tap_handler)
        end

        ptr = LibSwiftKitBridge.apsk_make_icon_button(
          view.icon.to_unsafe, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[IconButton]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ListView -> SwiftUI `List { Section { ... } }` via
      # APSKListViewFacade (NSHostingController on macOS).
      #
      # Items are flattened across all sections into a single child-views
      # array; populator emits `setSectionItemCounts` so the facade can
      # slice them back into SwiftUI `Section`s. List style (Plain /
      # Inset / Grouped / InsetGrouped / Sidebar) flows through the
      # populator as a string key the facade switches on.
      #
      # The legacy raw-NSStackView body is preserved as
      # `_legacy_list_view` for diffing during this migration; it is no
      # longer reached.
      # -----------------------------------------------------------------
      def visit(view : UI::ListView)
        overrides_ptr = LibSwiftKitBridge.apsk_list_view_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_list_view(target_str, view, sender)

        children_native = [] of NativeView
        view.sections.each do |section|
          section.items.each do |item|
            if d = render_detached(item)
              children_native << d
            else
              empty_ptr = alloc_init("NSView")
              children_native << NativeView.new(ObjC.owned(empty_ptr, label: "NSView[list-empty]"))
            end
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_list_view(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[ListView]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # Legacy AppKit ListView body, retained for reference.
      private def _legacy_list_view(view : UI::ListView)
        outer_ptr = alloc_init("NSStackView")

        # NSUserInterfaceLayoutOrientationVertical = 1
        LibObjCBridge.objc_send_long(outer_ptr, sel("setOrientation:"), 1_i64)
        LibObjCBridge.objc_send_1d(outer_ptr, sel("setSpacing:"), view.item_spacing)

        # Layer-backed so we can bake the background for dark-mode offscreen renders.
        LibObjCBridge.objc_send_bool(outer_ptr, sel("setWantsLayer:"), 1)
        layer_ptr = LibObjCBridge.objc_send(outer_ptr, sel("layer"))
        unless layer_ptr.null?
          dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")
          bg_rgba = if dark_mode
                      # Tier 2 platform default: NSColor.controlBackgroundColor dark.
                      LibObjCBridge.nscolor_rgba(0.11, 0.11, 0.11, 1.0)
                    else
                      # Tier 2 platform default: NSColor.controlBackgroundColor light.
                      LibObjCBridge.nscolor_rgba(1.0, 1.0, 1.0, 1.0)
                    end
          unless bg_rgba.null?
            cg = LibObjCBridge.objc_send(bg_rgba, sel("CGColor"))
            LibObjCBridge.objc_send_void_id(layer_ptr, sel("setBackgroundColor:"), cg) unless cg.null?
          end
        end

        apply_common_properties(outer_ptr, view)

        handle = ObjC.owned(outer_ptr, label: "NSStackView[list]")
        native = NativeView.new(handle)

        push_stack(native, is_nsstack: true)

        view.sections.each do |section|
          if header = section.header
            header_ptr = alloc_init("NSTextField")
            header_str = LibObjCBridge.nsstring_from_cstr(header.to_unsafe)
            LibObjCBridge.objc_send_id(header_ptr, sel("setStringValue:"), header_str)
            LibObjCBridge.objc_send_bool(header_ptr, sel("setEditable:"), 0)
            LibObjCBridge.objc_send_bool(header_ptr, sel("setBezeled:"), 0)
            LibObjCBridge.objc_send_bool(header_ptr, sel("setDrawsBackground:"), 0)
            emit(header_ptr, "NSTextField[list-header]")
          end

          if view.layout == UI::ListLayout::Grid && view.columns > 1
            # Grid mode: chunk items into rows of `columns` width.
            # Each row is a horizontal NSStackView of equal-width cells.
            cols = view.columns
            items = section.items
            row_idx = 0
            while row_idx < items.size
              row_ptr = alloc_init("NSStackView")
              # NSUserInterfaceLayoutOrientationHorizontal = 0
              LibObjCBridge.objc_send_long(row_ptr, sel("setOrientation:"), 0_i64)
              LibObjCBridge.objc_send_1d(row_ptr, sel("setSpacing:"), view.item_spacing)
              # NSStackViewDistributionFillEqually = 2
              LibObjCBridge.objc_send_long(row_ptr, sel("setDistribution:"), 2_i64)

              row_handle = ObjC.owned(row_ptr, label: "NSStackView[grid-row]")
              row_native = NativeView.new(row_handle)
              push_stack(row_native, is_nsstack: true)

              col_count = 0
              while col_count < cols && (row_idx + col_count) < items.size
                items[row_idx + col_count].accept(self)
                col_count += 1
              end

              # Pad incomplete last row with empty spacer views for alignment
              while col_count < cols
                spacer_ptr = alloc_init("NSView")
                emit(spacer_ptr, "NSView[grid-pad]")
                col_count += 1
              end

              pop_stack
              emit(row_ptr, "NSStackView[grid-row]")

              row_idx += cols
            end
          else
            # List mode: items appended to the outer vertical stack.
            # When shows_separators is true and style is Plain or Grouped,
            # insert an NSBox separator (boxType=NSBoxSeparator=2) between
            # each pair of items -- mimicking UITableView hairline dividers.
            # InsetGrouped: wrap all items in a rounded layer-backed container
            # NSStackView first, then emit the container to the outer stack.
            if view.style == UI::ListStyle::InsetGrouped
              # Rounded card container: layer-backed NSStackView with
              # corner radius ~10pt and a hairline border, matching HIG
              # inset-grouped rounded-card style (UITableView.Style.insetGrouped).
              card_ptr = alloc_init("NSStackView")
              LibObjCBridge.objc_send_long(card_ptr, sel("setOrientation:"), 1_i64)
              LibObjCBridge.objc_send_1d(card_ptr, sel("setSpacing:"), 0.0)
              LibObjCBridge.objc_send_bool(card_ptr, sel("setWantsLayer:"), 1)
              dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")
              card_layer = LibObjCBridge.objc_send(card_ptr, sel("layer"))
              unless card_layer.null?
                # Card background: slightly elevated from window background.
                card_bg_gray : Float64 = dark_mode ? 0.20 : 0.97
                card_bg = LibObjCBridge.nscolor_rgba(card_bg_gray, card_bg_gray, card_bg_gray, 1.0)
                unless card_bg.null?
                  cg_card_bg = LibObjCBridge.objc_send(card_bg, sel("CGColor"))
                  LibObjCBridge.objc_send_void_id(card_layer, sel("setBackgroundColor:"), cg_card_bg) unless cg_card_bg.null?
                end
                # token_radius(:card) (~10pt) matching HIG InsetGrouped card radius.
                LibObjCBridge.objc_send_1d(card_layer, sel("setCornerRadius:"), token_radius(:card))
                # Hairline border.
                sep_gray : Float64 = dark_mode ? 0.35 : 0.78
                border_color = LibObjCBridge.nscolor_rgba(sep_gray, sep_gray, sep_gray, 1.0)
                unless border_color.null?
                  cg_border = LibObjCBridge.objc_send(border_color, sel("CGColor"))
                  LibObjCBridge.objc_send_void_id(card_layer, sel("setBorderColor:"), cg_border) unless cg_border.null?
                end
                LibObjCBridge.objc_send_1d(card_layer, sel("setBorderWidth:"), 0.5)
              end
              card_handle = ObjC.owned(card_ptr, label: "NSStackView[inset-grouped-card]")
              card_native = NativeView.new(card_handle)
              push_stack(card_native, is_nsstack: true)
              section.items.each_with_index do |item, idx|
                item.accept(self)
                if view.shows_separators && idx < section.items.size - 1
                  sep_ptr = alloc_init("NSBox")
                  LibObjCBridge.objc_send_long(sep_ptr, sel("setBoxType:"), 2_i64)
                  emit(sep_ptr, "NSBox[list-sep]")
                end
              end
              pop_stack
              emit(card_ptr, "NSStackView[inset-grouped-card]")
            else
              # Plain / Grouped / Sidebar: flat vertical list with optional
              # NSBox separator lines between rows.
              section.items.each_with_index do |item, idx|
                item.accept(self)
                if view.shows_separators && idx < section.items.size - 1
                  sep_ptr = alloc_init("NSBox")
                  LibObjCBridge.objc_send_long(sep_ptr, sel("setBoxType:"), 2_i64)
                  emit(sep_ptr, "NSBox[list-sep]")
                end
              end
            end
          end
        end

        pop_stack

        push_native(native)
      end

      def visit(view : UI::OutlineView)
        view.fallback_view.accept(self)
      end

      def visit(view : UI::ColumnView)
        view.fallback_view.accept(self)
      end

      def visit(view : UI::TokenField)
        view.fallback_view.accept(self)
      end

      def visit(view : UI::ImageWell)
        view.fallback_view.accept(self)
      end

      # -----------------------------------------------------------------
      # Visit: SecureField -> NSSecureTextField
      # -----------------------------------------------------------------
      def visit(view : UI::SecureField)
        overrides_ptr = LibSwiftKitBridge.apsk_secure_field_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_secure_field(target_str, view, sender)

        # Phase 8B iter 3 — same FormState-wiring pattern as TextField.
        # The legacy on_change for SecureField receives "" (the SwiftUI
        # bridge doesn't yet carry the cleartext through). FormState
        # therefore stores "" for the SecureField's name; the controller
        # sees the empty string in ctx.params. Authors who need true
        # password capture on macOS for Phase 8B should use a plain
        # UI::TextField for now. A future SwiftKit bridge iteration
        # will carry the typed cleartext through.
        wrapped_handler = UI::FormStateRendererHook.wrap_secure_handler(view)
        action_token = 0_u64
        if wrapped_handler
          action_token = UI::CallbackRegistry.register_action_with_value do |_v|
            wrapped_handler.call("")
          end
        end

        ptr = LibSwiftKitBridge.apsk_make_secure_field(
          view.placeholder.to_unsafe, view.text.to_unsafe, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[SecureField]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Stepper -> SwiftUI Stepper(value:in:step:).
      # -----------------------------------------------------------------
      def visit(view : UI::Stepper)
        overrides_ptr = LibSwiftKitBridge.apsk_stepper_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_stepper(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(v)
          end
        end

        ptr = LibSwiftKitBridge.apsk_make_stepper(
          view.label.to_unsafe, view.value, view.minimum, view.maximum,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Stepper]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: SegmentedControl -> SwiftUI Picker(.segmented).
      # -----------------------------------------------------------------
      def visit(view : UI::SegmentedControl)
        overrides_ptr = LibSwiftKitBridge.apsk_segmented_control_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_segmented_control(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(v.to_i32)
          end
        end

        seg_count = view.segments.size
        segs_buf = Pointer(UInt8*).malloc(seg_count.to_u64)
        view.segments.each_with_index { |s, i| segs_buf[i] = s.to_unsafe }

        ptr = LibSwiftKitBridge.apsk_make_segmented_control(
          segs_buf.as(Void*), seg_count.to_i32, view.selected_index.to_i32,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[SegmentedControl]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: DatePicker -> SwiftUI DatePicker(...).
      # -----------------------------------------------------------------
      def visit(view : UI::DatePicker)
        overrides_ptr = LibSwiftKitBridge.apsk_date_picker_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_date_picker(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(Time.unix(v.to_i64))
          end
        end

        epoch = view.selected_date.to_unix.to_f64
        ptr = LibSwiftKitBridge.apsk_make_date_picker(
          view.label.to_unsafe, epoch, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[DatePicker]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: TimePicker -> SwiftUI DatePicker(.hourAndMinute).
      # -----------------------------------------------------------------
      def visit(view : UI::TimePicker)
        overrides_ptr = LibSwiftKitBridge.apsk_time_picker_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_time_picker(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            change_handler.call(Time.unix(v.to_i64))
          end
        end

        epoch = view.selected_time.to_unix.to_f64
        ptr = LibSwiftKitBridge.apsk_make_time_picker(
          view.label.to_unsafe, epoch, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[TimePicker]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: SearchField -> SwiftUI search-field composite.
      # -----------------------------------------------------------------
      def visit(view : UI::SearchField)
        overrides_ptr = LibSwiftKitBridge.apsk_search_field_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_search_field(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |_v|
            change_handler.call("")
          end
        end

        ptr = LibSwiftKitBridge.apsk_make_search_field(
          view.placeholder.to_unsafe, view.text.to_unsafe,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[SearchField]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: TextArea -> NSTextView inside NSScrollView
      # -----------------------------------------------------------------
      def visit(view : UI::TextArea)
        overrides_ptr = LibSwiftKitBridge.apsk_text_area_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_text_area(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |_v|
            change_handler.call("")
          end
        end

        ptr = LibSwiftKitBridge.apsk_make_text_area(
          view.placeholder.to_unsafe, view.text.to_unsafe,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[TextArea]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Grid -> NSGridView
      # -----------------------------------------------------------------
      def visit(view : UI::Grid)
        # SwiftUI Grid { GridRow { ... } } facade. Children are flattened
        # row-by-row; the populator emits row_cell_counts so the facade
        # can slice the flat array back into rows.
        overrides_ptr = LibSwiftKitBridge.apsk_grid_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_grid(target_str, view, sender)

        children_native = [] of NativeView
        view.children.each do |row|
          row.each do |cell|
            if d = render_detached(cell)
              children_native << d
            end
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_grid(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Grid]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Form -> NSStackView (vertical, with sections)
      # -----------------------------------------------------------------
      def visit(view : UI::Form)
        # SwiftUI Form { Section { ... } } facade. Field contents are
        # flattened across all sections; the populator carries the
        # per-section counts so the facade can slice them back.
        overrides_ptr = LibSwiftKitBridge.apsk_form_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_form(target_str, view, sender)

        children_native = [] of NativeView
        view.sections.each do |section|
          section.fields.each do |field|
            if content = field.content
              if d = render_detached(content)
                children_native << d
              else
                empty_ptr = alloc_init("NSView")
                children_native << NativeView.new(ObjC.owned(empty_ptr, label: "NSView[form-empty]"))
              end
            else
              empty_ptr = alloc_init("NSView")
              children_native << NativeView.new(ObjC.owned(empty_ptr, label: "NSView[form-empty]"))
            end
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_form(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Form]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: NavigationSplitView -> NSStackView (horizontal split container)
      #        with NSVisualEffectView sidebar column (Liquid Glass)
      #
      # HIG: "sidebars float above content in the Liquid Glass layer."
      # The sidebar column wraps in NSVisualEffectView with
      # NSVisualEffectMaterialSidebar (= 7). The content / detail
      # columns sit in NSStackView columns to the right, laid out as
      # arranged subviews of the horizontal outer NSStackView so that
      # AutoLayout gives each column a real frame.
      #
      # Root structure:
      #   outer NSStackView (horizontal, Fill distribution)
      #     NSVisualEffectView[sidebar-glass] (sidebar width pinned)
      #       NSStackView[sidebar-inner] (vertical, pinned to edges)
      #         <sidebar children>
      #     [thin 1pt NSBox separator]
      #     NSStackView[content-col] (vertical, fills remaining width)
      #       <content children>
      #     [thin 1pt NSBox separator — only if detail present]
      #     NSStackView[detail-col] (vertical, fills remaining width)
      #       <detail children>
      # -----------------------------------------------------------------
      def visit(view : UI::NavigationSplitView)
        # SwiftUI NavigationSplitView facade. Three slots: sidebar /
        # content / detail. Empty slots are passed as an empty NSView
        # placeholder so the facade can address them by index.
        overrides_ptr = LibSwiftKitBridge.apsk_navigation_split_view_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_navigation_split_view(target_str, view, sender)

        children_native = [] of NativeView
        [view.sidebar, view.content, view.detail].each do |slot|
          if slot
            if d = render_detached(slot)
              children_native << d
            else
              empty_ptr = alloc_init("NSView")
              children_native << NativeView.new(ObjC.owned(empty_ptr, label: "NSView[split-empty]"))
            end
          else
            empty_ptr = alloc_init("NSView")
            children_native << NativeView.new(ObjC.owned(empty_ptr, label: "NSView[split-empty]"))
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_navigation_split_view(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[NavigationSplitView]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Toolbar -> NSVisualEffectView (Liquid Glass) + horizontal
      #                   NSStackView of icon-button items.
      #
      # HIG: "A toolbar provides convenient access to frequently used
      # commands, controls, navigation, and search." Toolbars are surface
      # components classified under navigation/chrome. On macOS 26, the
      # toolbar background is a Liquid Glass translucent NSVisualEffectView.
      # Material: NSVisualEffectMaterialToolBar = 10 (tracks appearance).
      #
      # Structure:
      #   NSVisualEffectView (glass root, toolbar material)
      #     NSStackView (horizontal, leading-aligned, 8pt spacing)
      #       [title NSTextField? if view.title && view.shows_title]
      #       NSBox (vertical separator) -- between groups
      #       item_0..item_N:
      #         NSButton (icon-only or icon+label, borderless, 44x28pt)
      #           NSImageView (SF Symbol, 20pt, no border per HIG Actions)
      #
      # HIG Best practices: "Prefer system-provided symbols without borders."
      # HIG Best practices: "Choose items deliberately to avoid overcrowding."
      # -----------------------------------------------------------------
      def visit(view : UI::Toolbar)
        # SwiftUI .toolbar(...) facade. The Toolbar carries item arrays
        # (labels/icons/placements) plus action tokens registered here.
        overrides_ptr = LibSwiftKitBridge.apsk_toolbar_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_toolbar(target_str, view, sender)

        # Register each item's action; pass tokens through as a parallel
        # UInt64 array.
        tokens = [] of UInt64
        callback_ids = [] of UInt64
        view.items.each do |item|
          if action = item.action
            tok = UI::CallbackRegistry.register_action(&action)
            tokens << tok
            callback_ids << tok
          else
            tokens << 0_u64
          end
        end
        sender.set_uint64_array(target_str, :setItemTokens, tokens)

        ptr = LibSwiftKitBridge.apsk_make_toolbar(
          Pointer(Void*).null.as(Void*), 0_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Toolbar]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Sheet -> NSVisualEffectView + inner NSStackView (Liquid Glass)
      # -----------------------------------------------------------------
      def visit(view : UI::Sheet)
        # SwiftUI .sheet(isPresented:) facade. The Sheet's content is
        # rendered detached; the facade hosts a 1pt clear rect that
        # carries the .sheet modifier, presenting the content modally.
        overrides_ptr = LibSwiftKitBridge.apsk_sheet_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_sheet(target_str, view, sender)

        dismiss_token = 0_u64
        callback_ids = [] of UInt64
        if dismiss = view.on_dismiss
          dismiss_token = UI::CallbackRegistry.register_action(&dismiss)
          callback_ids << dismiss_token
        end

        children_native = [] of NativeView
        if content = view.content
          if d = render_detached(content)
            children_native << d
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_sheet(
          child_buf.as(Void*), children_native.size.to_i32,
          overrides_ptr, dismiss_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Sheet]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Popover -> NSVisualEffectView (popover material) inline card
      #
      # HIG: Popovers are surface components classified under "Presentation /
      # Windows and overlays." They require Liquid Glass.
      #
      # NSVisualEffectMaterialPopover = 6. Tracks light/dark appearance
      # automatically. BlendingMode BehindWindow = 0 so the glass samples
      # the window backdrop for true translucency. State Active = 1 keeps the
      # material live regardless of key state.
      #
      # The inline path (is_presented == false) renders the glass surface and
      # content directly into the host view tree -- used by the HIG validation
      # host for screenshot isolation. A production app would use NSPopover with
      # showRelativeToRect:ofView:preferredEdge: for full popover lifecycle.
      #
      # Arrow/tail: NSPopover provides the arrow natively when used in the
      # presented path. In the inline validation path we emit a small arrow-glyph
      # label (up-pointing triangle character U+25B2) above the surface to signal
      # the popover origin. This is not a rendered NSPopoverArrow -- it is a
      # validation-only visual cue. Logged as a systemic gap in gaps.md.
      #
      # Corner radius ~10pt matching NSVisualEffectMaterialPopover default.
      # -----------------------------------------------------------------
      def visit(view : UI::Popover)
        # SwiftUI .popover(isPresented:) facade.
        overrides_ptr = LibSwiftKitBridge.apsk_popover_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_popover(target_str, view, sender)

        dismiss_token = 0_u64
        callback_ids = [] of UInt64
        if dismiss = view.on_dismiss
          dismiss_token = UI::CallbackRegistry.register_action(&dismiss)
          callback_ids << dismiss_token
        end

        children_native = [] of NativeView
        if content = view.content
          if d = render_detached(content)
            children_native << d
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_popover(
          child_buf.as(Void*), children_native.size.to_i32,
          overrides_ptr, dismiss_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Popover]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ConfirmationDialog -> NSAlert
      # -----------------------------------------------------------------
      def visit(view : UI::ConfirmationDialog)
        # SwiftUI .confirmationDialog(...) facade.
        overrides_ptr = LibSwiftKitBridge.apsk_confirmation_dialog_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_confirmation_dialog(target_str, view, sender)

        callback_ids = [] of UInt64
        if confirm = view.on_confirm
          tok = UI::CallbackRegistry.register_action(&confirm)
          callback_ids << tok
          LibSwiftKitBridge.apsk_overrides_set_int(
            overrides_ptr, "setConfirmToken:".to_unsafe, tok.to_i64,
          )
        end
        if cancel = view.on_cancel
          tok = UI::CallbackRegistry.register_action(&cancel)
          callback_ids << tok
          LibSwiftKitBridge.apsk_overrides_set_int(
            overrides_ptr, "setCancelToken:".to_unsafe, tok.to_i64,
          )
        end

        ptr = LibSwiftKitBridge.apsk_make_confirmation_dialog(
          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[ConfirmationDialog]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Snackbar -> NSView (toast-style overlay)
      # -----------------------------------------------------------------
      def visit(view : UI::Snackbar)
        ptr = alloc_init("NSTextField")

        msg_str = LibObjCBridge.nsstring_from_cstr(view.message.to_unsafe)
        LibObjCBridge.objc_send_id(ptr, sel("setStringValue:"), msg_str)
        LibObjCBridge.objc_send_bool(ptr, sel("setEditable:"), 0)
        LibObjCBridge.objc_send_bool(ptr, sel("setBezeled:"), 0)

        if view.is_presented
          LibObjCBridge.objc_send_bool(ptr, sel("setHidden:"), 0)
        else
          LibObjCBridge.objc_send_bool(ptr, sel("setHidden:"), 1)
        end

        apply_common_properties(ptr, view)

        emit(ptr, "NSTextField[snackbar]")
      end

      # -----------------------------------------------------------------
      # Visit: Card -> NSStackView + CALayer (grouped box container)
      #
      # HIG Boxes: "A box creates a visually distinct group of logically
      # related information and components." and "By default, a box uses a
      # visible border or background color to separate its contents from
      # the rest of the interface."
      #
      # Prior implementation used NSBox, which relies on the Quartz
      # compositor for appearance-resolved fills. NSBox's fillColor draws
      # opaque white in offscreen bitmaps even when the window appearance
      # is dark, producing white-on-white captures (gaps.md iteration-21).
      #
      # This implementation uses NSStackView (vertical) + wantsLayer=YES +
      # explicit NSColor.controlBackgroundColor resolved via CGColor.
      # NSColor.controlBackgroundColor is a dynamic system color; via
      # -[NSAppearance performAsCurrentDrawingAppearance:] in the snapshot
      # path it correctly resolves to light gray in light and dark charcoal
      # in dark. The hairline border is drawn via layer.borderColor and
      # layer.borderWidth. On macOS 26, NSBox is still emitted for
      # production app embedding (in SwiftUI interop) but for the
      # validation path an NSStackView renders correctly.
      #
      # HIG macOS platform note: "By default, macOS displays a box's title
      # above it." We prepend a title NSTextField as the first arranged
      # subview, matching that platform behaviour.
      # -----------------------------------------------------------------
      def visit(view : UI::Card)
        # SwiftUI Card facade (custom composition).
        overrides_ptr = LibSwiftKitBridge.apsk_card_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_card(target_str, view, sender)

        children_native = [] of NativeView
        if content = view.content
          if d = render_detached(content)
            children_native << d
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_card(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Card]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # Legacy AppKit Card body, retained for reference.
      private def _legacy_card(view : UI::Card)
        ptr = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(ptr, sel("setOrientation:"), 1_i64)
        # 8pt inter-row spacing (HIG default for grouped content rows).
        LibObjCBridge.objc_send_1d(ptr, sel("setSpacing:"), 8.0)
        # Leading alignment (NSLayoutAttributeLeading = 5).
        LibObjCBridge.objc_send_long(ptr, sel("setAlignment:"), 5_i64)
        # Honor the card's authored content padding so preview studies and
        # runtime cards both keep content off the corners by default.
        p = view.content_padding
        insets = LibObjCBridge::CGRect.new(x: p.top, y: p.leading, width: p.bottom, height: p.trailing)
        LibObjCBridge.objc_send_rect_void(ptr, sel("setEdgeInsets:"), insets)

        # Enable layer-backed rendering so we can set fill + rounded border.
        LibObjCBridge.objc_send_bool(ptr, sel("setWantsLayer:"), 1)

        layer = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer.null?
          # token_radius(:card) (~10pt) -- matches HIG grouped-container default.
          LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), token_radius(:card))

          # Background fill. layer.backgroundColor requires a baked CGColor.
          # Dynamic NSColor -> CGColor bakes the color at call time, before the
          # drawing appearance is set, so it does NOT track dark/light via the
          # performAsCurrentDrawingAppearance: path used by window_helper.m.
          # We use an explicit RGBA: light appearance -> near-white grouped fill
          # (NSColor.controlBackgroundColor light ~0.97 RGB); dark -> dark-charcoal
          # (NSColor.controlBackgroundColor dark ~0.14 RGB). Reading HIG_APPEARANCE
          # here ensures the validation snapshot matches the correct appearance.
          # In production, a real app would subclass NSStackView and override
          # updateLayer to pick the system-resolved color.
          #
          # Backdrop-mode exception: when HIG_BACKDROP_PATH is set, the capture
          # window has an NSImageView backdrop. Card NSStackViews with opaque fills
          # block the NSVisualEffectView compositor from reaching the backdrop.
          # Use a semi-transparent fill so the backdrop bleeds through the card
          # surface as frosted glass. The border and corner radius remain.
          dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")
          backdrop_mode = ENV["HIG_BACKDROP_PATH"]? && !ENV["HIG_BACKDROP_PATH"].to_s.empty?
          # All four `nscolor_rgba` literals below are Tier 2 platform defaults —
          # NSColor.controlBackgroundColor approximations. The translucent variants
          # are the same color at 0.75 alpha for backdrop-mode card surfaces.
          # Not brand decisions; track the system grouped-card chrome.
          bg_color = if backdrop_mode
                       # Tier 2: semi-transparent fill so the backdrop bleeds through.
                       dark_mode ? LibObjCBridge.nscolor_rgba(0.12, 0.12, 0.14, 0.75) : LibObjCBridge.nscolor_rgba(0.96, 0.96, 0.97, 0.75)
                     elsif dark_mode
                       # Tier 2 platform default: NSColor.controlBackgroundColor dark.
                       LibObjCBridge.nscolor_rgba(0.145, 0.145, 0.145, 1.0)
                     else
                       # Tier 2 platform default: NSColor.controlBackgroundColor light.
                       LibObjCBridge.nscolor_rgba(0.970, 0.970, 0.970, 1.0)
                     end
          unless bg_color.null?
            cg_bg = LibObjCBridge.objc_send(bg_color, sel("CGColor"))
            LibObjCBridge.objc_send_void_id(layer, sel("setBackgroundColor:"), cg_bg) unless cg_bg.null?
          end

          # Hairline separator-color border matching HIG grouped-box chrome.
          # Same issue: bake appropriate gray for each appearance.
          sep_gray : Float64 = dark_mode ? 0.35 : 0.78
          sep_color = LibObjCBridge.nscolor_rgba(sep_gray, sep_gray, sep_gray, 1.0)
          unless sep_color.null?
            cg_sep = LibObjCBridge.objc_send(sep_color, sel("CGColor"))
            LibObjCBridge.objc_send_void_id(layer, sel("setBorderColor:"), cg_sep) unless cg_sep.null?
          end
          LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), 0.5)
        end

        apply_common_properties(ptr, view)

        outer_handle = ObjC.owned(ptr, label: "NSStackView[card]")
        outer_native = NativeView.new(outer_handle)

        # HIG macOS: "By default, macOS displays a box's title above it."
        # Prepend a title label as the first arranged subview.
        if title = view.title
          title_ptr = alloc_init("NSTextField")
          title_ns = LibObjCBridge.nsstring_from_cstr(title.to_unsafe)
          LibObjCBridge.objc_send_id(title_ptr, sel("setStringValue:"), title_ns)
          LibObjCBridge.objc_send_bool(title_ptr, sel("setEditable:"), 0)
          LibObjCBridge.objc_send_bool(title_ptr, sel("setBezeled:"), 0)
          LibObjCBridge.objc_send_bool(title_ptr, sel("setDrawsBackground:"), 0)
          LibObjCBridge.objc_send_bool(title_ptr, sel("setSelectable:"), 0)
          # 11pt bold -- matches macOS grouped-box title convention.
          title_font = LibObjCBridge.nsfont_system_weight(11.0, 0.4)
          LibObjCBridge.objc_send_id(title_ptr, sel("setFont:"), title_font)
          # Label-color (dynamic): dark-mode white, light-mode near-black.
          primary_color = LibObjCBridge.nscolor_label_primary
          LibObjCBridge.objc_send_id(title_ptr, sel("setTextColor:"), primary_color)
          LibObjCBridge.objc_send_void_id(ptr, sel("addArrangedSubview:"), title_ptr)

          title_handle = ObjC.owned(title_ptr, label: "NSTextField[card-title]")
          outer_native.add_child(NativeView.new(title_handle))
        end

        if content = view.content
          push_stack(outer_native, is_nsstack: true)
          content.accept(self)
          pop_stack
        end

        push_native(outer_native)
      end

      # -----------------------------------------------------------------
      # Visit: Surface -> NSView (elevated container)
      # -----------------------------------------------------------------
      def visit(view : UI::Surface)
        # SwiftUI Surface facade (thin container with optional shape).
        overrides_ptr = LibSwiftKitBridge.apsk_surface_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_surface(target_str, view, sender)

        children_native = [] of NativeView
        if content = view.content
          if d = render_detached(content)
            children_native << d
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_surface(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[Surface]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Divider -> NSBox (separator)
      # -----------------------------------------------------------------
      def visit(view : UI::Divider)
        overrides_ptr = LibSwiftKitBridge.apsk_divider_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_divider(target_str, view, sender)

        ptr = LibSwiftKitBridge.apsk_make_divider(overrides_ptr)
        emit(ptr, "NSHostingView[Divider]")
      end

      # -----------------------------------------------------------------
      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26 / macOS 26)
      # with `.background(<Material>)` fallback on pre-26 OSes.
      #
      # Phase 3 remediation: migrated to the populator + facade flow so
      # the "headline visual differentiator" the Phase 3 README names
      # (Liquid Glass on default Card/Sheet surfaces) is wired through
      # the same default-detection cascade as every other widget.
      # -----------------------------------------------------------------
      def visit(view : UI::GlassBackground)
        # Phase 5 v2: Apple material is the DECLARED step — brand
        # intensity is advisory on Apple per I-10. The architecture's
        # quantizer model applies on web + Android; on Apple, declared
        # step wins so consumers can rely on SwiftUI Material enum
        # semantic stability. The populator's `apple_step` parameter
        # therefore receives `view.material` unchanged (NOT routed
        # through `Material#apple_step` which would re-quantize via the
        # v2 thickness_for_brand path).
        apple_step = view.material

        overrides_ptr = LibSwiftKitBridge.apsk_glass_background_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_glass_background(target_str, view, sender, apple_step: apple_step)

        child_ptr = Pointer(Void).null
        child_native : NativeView? = nil
        if content = view.content
          if d = render_detached(content)
            child_native = d
            child_ptr = d.handle.ptr!
          end
        end

        ptr = LibSwiftKitBridge.apsk_make_glass_background(overrides_ptr, child_ptr)
        handle = ObjC.owned(ptr, label: "NSHostingView[GlassBackground]")
        native = NativeView.new(handle)
        if c = child_native
          native.add_child(c)
        end
        push_native(native)
      end

      # -----------------------------------------------------------------
      # P2 Wave 3 Visit methods
      # -----------------------------------------------------------------

      def visit(view : UI::AsyncImage)
        ptr = alloc_init("NSImageView")
        apply_common_properties(ptr, view)
        emit(ptr, "NSImageView[async]")
      end

      # -----------------------------------------------------------------
      # Visit: RichText -> NSTextView (inside NSScrollView for wrapping)
      #
      # HIG "Text views": "A text view displays multiline, styled text
      # content, which can optionally be editable."
      # AppKit: NSTextView is always embedded in NSScrollView to provide
      # the expected scrolling and layout behaviour for multi-line content.
      #
      # Text color: when the Span default sentinel (r=0,g=0,b=0,a=1) is
      # detected we substitute NSColor.labelColor so dark-mode text is
      # near-white rather than baked-black.  This mirrors the fix applied
      # to UI::TextField in iter-48.
      # -----------------------------------------------------------------
      def visit(view : UI::RichText)
        scroll_ptr = alloc_init("NSScrollView")
        LibObjCBridge.objc_send_bool(scroll_ptr, sel("setHasVerticalScroller:"), 1)
        LibObjCBridge.objc_send_bool(scroll_ptr, sel("setAutohidesScrollers:"), 1)

        text_ptr = alloc_init("NSTextView")

        # Populate text from spans -- join plain text for initial render.
        plain = view.plain_text
        unless plain.empty?
          text_str = LibObjCBridge.nsstring_from_cstr(plain.to_unsafe)
          LibObjCBridge.objc_send_id(text_ptr, sel("setString:"), text_str)
        end

        # Non-editable by default for UI::RichText.
        LibObjCBridge.objc_send_bool(text_ptr, sel("setEditable:"), 0)
        LibObjCBridge.objc_send_bool(text_ptr, sel("setRichText:"), 1)

        # Font: use first span's font if present, else system body 17pt.
        # Tier 2 platform default: 17pt = Apple HIG body label size on iOS;
        # used on macOS RichText for parity with iOS rendering.
        first_font = view.spans.first?.try(&.font)
        font_ptr = first_font ? resolve_font(first_font) : LibObjCBridge.nsfont_system(17.0)
        LibObjCBridge.objc_send_id(text_ptr, sel("setFont:"), font_ptr) unless font_ptr.null?

        # Text color: sentinel-swap for appearance tracking.
        # Use the first span color if there is one; otherwise labelColor.
        first_color = view.spans.first?.try(&.color)
        color_ptr = if fc = first_color
                      if fc.r == 0.0 && fc.g == 0.0 && fc.b == 0.0 && fc.a == 1.0
                        LibObjCBridge.nscolor_label_primary
                      else
                        LibObjCBridge.nscolor_rgba(fc.r, fc.g, fc.b, fc.a)
                      end
                    else
                      LibObjCBridge.nscolor_label_primary
                    end
        LibObjCBridge.objc_send_id(text_ptr, sel("setTextColor:"), color_ptr)

        LibObjCBridge.objc_send_id(scroll_ptr, sel("setDocumentView:"), text_ptr)
        apply_common_properties(scroll_ptr, view)
        emit(scroll_ptr, "NSScrollView[richtextview]")
      end

      def visit(view : UI::LinkButton)
        overrides_ptr = LibSwiftKitBridge.apsk_link_button_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_link_button(target_str, view, sender)

        action_token = 0_u64
        if tap_handler = view.on_tap
          action_token = UI::CallbackRegistry.register_action(&tap_handler)
        end

        ptr = LibSwiftKitBridge.apsk_make_link_button(
          view.label.to_unsafe, view.url.to_unsafe, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[LinkButton]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: MenuButton -> NSPopUpButton
      #
      # Pop-up mode (is_pull_down: false, default):
      #   NSPopUpButton with pullsDown: false.  Displays the currently selected
      #   item's title and a trailing up/down chevron (NSPopUpButton disclosure
      #   indicator).  Clicking opens an NSMenu; the selected item shows a
      #   checkmark automatically.
      #   HIG: "Use a pop-up button to present a flat list of mutually exclusive
      #   options or states." -- Pop-up buttons / Best practices.
      #
      # Pull-down mode (is_pull_down: true):
      #   NSPopUpButton with pullsDown: true (setIsPullDown: YES).  Displays the
      #   button's own label (a verb) and a single downward chevron (chevron.down).
      #   No item is pre-selected; no checkmarks are shown in the menu.
      #   HIG: "Use a pull-down button to present commands or items that are
      #   directly related to the button's action." -- Pull-down buttons / Best
      #   practices.
      # -----------------------------------------------------------------
      def visit(view : UI::MenuButton)
        # SwiftUI Menu { ... } facade.
        overrides_ptr = LibSwiftKitBridge.apsk_menu_button_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_menu_button(target_str, view, sender)

        # Register per-item actions; pass tokens through as a parallel
        # UInt64 array.
        tokens = [] of UInt64
        callback_ids = [] of UInt64
        view.items.each do |item|
          if action = item.action
            tok = UI::CallbackRegistry.register_action(&action)
            tokens << tok
            callback_ids << tok
          else
            tokens << 0_u64
          end
        end
        sender.set_uint64_array(target_str, :setItemTokens, tokens) unless tokens.empty?

        ptr = LibSwiftKitBridge.apsk_make_menu_button(
          view.label.to_unsafe, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[MenuButton]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      def visit(view : UI::ContextMenu)
        # Phase 5 v2 — token-driven semantic material. ContextMenu's HIG-
        # canonical role is `Menu` (NSVisualEffectMaterialMenu = 5).
        # Brand intensity is ADVISORY on Apple semantic surfaces (the
        # AppleSemantic axis is role-based, not intensity-scaled).
        # `SystemResolved` returns the 0 sentinel — skip setMaterial: in
        # that branch.
        menu_semantic = UI::DesignTokens::AppleSemantic::Menu
        menu_material = appkit_visual_effect_material_for_semantic(menu_semantic)
        effect = alloc_init("NSVisualEffectView")
        if menu_material != 0_i64
          LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), menu_material) # Menu -> 5
        end
        LibObjCBridge.objc_send_long(effect, sel("setBlendingMode:"), 1_i64) # WithinWindow
        LibObjCBridge.objc_send_long(effect, sel("setState:"), 1_i64)        # Active
        LibObjCBridge.objc_send_bool(effect, sel("setWantsLayer:"), 1)

        effect_layer = LibObjCBridge.objc_send(effect, sel("layer"))
        unless effect_layer.null?
          # token_radius(:sheet) (14pt) — menu / sheet glass card corner.
          LibObjCBridge.objc_send_1d(effect_layer, sel("setCornerRadius:"), token_radius(:sheet))
          LibObjCBridge.objc_send_bool(effect_layer, sel("setMasksToBounds:"), 1)
          sep_color = LibObjCBridge.nscolor_separator
          unless sep_color.null?
            sep_cg = LibObjCBridge.objc_send(sep_color, sel("CGColor"))
            LibObjCBridge.objc_send_void_id(effect_layer, sel("setBorderColor:"), sep_cg) unless sep_cg.null?
          end
          LibObjCBridge.objc_send_1d(effect_layer, sel("setBorderWidth:"), 1.0)
        end

        inner = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(inner, sel("setOrientation:"), 1_i64)
        LibObjCBridge.objc_send_1d(inner, sel("setSpacing:"), 0.0)
        LibObjCBridge.objc_send_long(inner, sel("setAlignment:"), 5_i64)
        insets = LibObjCBridge::CGRect.new(x: 8.0, y: 8.0, width: 8.0, height: 8.0)
        LibObjCBridge.objc_send_rect_void(inner, sel("setEdgeInsets:"), insets)
        LibObjCBridge.objc_send_bool(inner, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
        LibObjCBridge.objc_add_subview(effect, inner)

        %w(topAnchor bottomAnchor leadingAnchor trailingAnchor).each do |anchor_sel|
          inner_anchor = LibObjCBridge.objc_send(inner, sel(anchor_sel))
          effect_anchor = LibObjCBridge.objc_send(effect, sel(anchor_sel))
          next if inner_anchor.null? || effect_anchor.null?
          constraint = LibObjCBridge.objc_send_id(inner_anchor, sel("constraintEqualToAnchor:"), effect_anchor)
          LibObjCBridge.objc_send_bool(constraint, sel("setActive:"), 1) unless constraint.null?
        end

        inner_handle = ObjC.borrowed(inner, label: "NSStackView[context-menu-inner]")
        inner_native = NativeView.new(inner_handle)

        red_cls = LibObjCBridge.objc_getClass("NSColor")
        destructive_color = LibObjCBridge.objc_send(red_cls, sel("systemRedColor"))
        # Tier 2 platform default: rgba(1.0, 0.23, 0.19, 1.0) ≈ NSColor.systemRed
        # — HIG-mandated destructive action color fallback when the class lookup fails.
        destructive_color = LibObjCBridge.nscolor_rgba(1.0, 0.23, 0.19, 1.0) if destructive_color.null?

        view.items.each do |entry|
          case entry
          when UI::ContextMenu::Separator
            sep = alloc_init("NSBox")
            LibObjCBridge.objc_send_long(sep, sel("setBoxType:"), 2_i64)
            LibObjCBridge.objc_constrain_height(sep, 1.0)
            sep_handle = ObjC.owned(sep, label: "NSBox[context-menu-separator]")
            sep_native = NativeView.new(sep_handle)
            inner_native.add_child(sep_native)
            LibObjCBridge.objc_send_id(inner, sel("addArrangedSubview:"), sep)
          when UI::ContextMenu::Item
            row = alloc_init("NSButton")
            row_title = LibObjCBridge.nsstring_from_cstr(entry.label.to_unsafe)
            LibObjCBridge.objc_send_id(row, sel("setTitle:"), row_title)
            LibObjCBridge.objc_send_bool(row, sel("setBordered:"), 0)
            LibObjCBridge.objc_send_long(row, sel("setBezelStyle:"), 0_i64)
            LibObjCBridge.objc_constrain_height(row, 32.0)
            LibObjCBridge.objc_constrain_minimum_width(row, 220.0)

            row_handle = ObjC.owned(row, label: "NSButton[context-menu-row]")
            row_native = NativeView.new(row_handle)
            inner_native.add_child(row_native)

            if icon = entry.icon
              icon_tint = entry.is_destructive ? destructive_color : LibObjCBridge.nscolor_label_secondary
              icon_view = LibObjCBridge.nsimageview_make_symbol(icon.to_unsafe, icon_tint, 14.0)
              unless icon_view.null?
                image = LibObjCBridge.objc_send(icon_view, sel("image"))
                unless image.null?
                  LibObjCBridge.objc_send_id(row, sel("setImage:"), image)
                  LibObjCBridge.objc_send_long(row, sel("setImagePosition:"), 7_i64)
                end
              end
            end

            text_color = if entry.is_destructive
                           destructive_color
                         elsif entry.is_disabled
                           LibObjCBridge.nscolor_label_tertiary
                         else
                           LibObjCBridge.nscolor_label_primary
                         end
            # Tier 2 platform default: 13pt = NSFont.systemFontSize.
            text_font = LibObjCBridge.nsfont_system(13.0)
            LibObjCBridge.nsbutton_set_colored_title(row, row_title, text_color, text_font)
            LibObjCBridge.objc_send_bool(row, sel("setEnabled:"), entry.is_disabled ? 0 : 1)

            LibObjCBridge.objc_send_id(inner, sel("addArrangedSubview:"), row)
          end
        end

        ax_text = view.accessibility_label || "Context menu"
        ax_str = LibObjCBridge.nsstring_from_cstr(ax_text.to_unsafe)
        LibObjCBridge.objc_send_id(effect, sel("setAccessibilityLabel:"), ax_str)

        apply_common_properties(effect, view)
        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[context-menu]")
        outer_native = NativeView.new(outer_handle)
        outer_native.add_child(inner_native)
        push_native(outer_native)
      end

      def visit(view : UI::ToggleButton)
        # SwiftUI Toggle with .toggleStyle(.button) facade.
        overrides_ptr = LibSwiftKitBridge.apsk_toggle_button_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_toggle_button(target_str, view, sender)

        action_token = 0_u64
        if toggle_handler = view.on_toggle
          action_token = UI::CallbackRegistry.register_action_with_value do |v|
            toggle_handler.call(v != 0.0)
          end
        end

        ptr = LibSwiftKitBridge.apsk_make_toggle_button(
          view.label.to_unsafe, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[ToggleButton]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      def visit(view : UI::TextEditor)
        overrides_ptr = LibSwiftKitBridge.apsk_text_editor_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_text_editor(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |_v|
            change_handler.call("")
          end
        end

        ptr = LibSwiftKitBridge.apsk_make_text_editor(
          view.placeholder.to_unsafe, view.text.to_unsafe,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[TextEditor]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # P3 Stub Visit methods
      # -----------------------------------------------------------------

      def visit(view : UI::Circle)
        ptr = alloc_init("NSView")
        LibObjCBridge.objc_send_bool(ptr, sel("setWantsLayer:"), 1)
        # NSStackView: TAMIC:NO + NSLayoutConstraints pins the diameter.
        LibObjCBridge.objc_constrain_size(ptr, view.size, view.size)
        layer = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer.null?
          bg_nscolor = resolve_color(view.fill_color)
          cg_color = LibObjCBridge.objc_send(bg_nscolor, sel("CGColor"))
          LibObjCBridge.objc_send_id(layer, sel("setBackgroundColor:"), cg_color)
          # Half of the expected size for a perfect circle
          LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), view.size / 2.0)
          if sc = view.stroke_color
            LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), view.stroke_width)
            border_nscolor = resolve_color(sc)
            cg_border = LibObjCBridge.objc_send(border_nscolor, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setBorderColor:"), cg_border)
          end
        end
        apply_common_properties(ptr, view)
        emit(ptr, "NSView[circle]")
      end

      def visit(view : UI::Rectangle)
        ptr = alloc_init("NSView")
        LibObjCBridge.objc_send_bool(ptr, sel("setWantsLayer:"), 1)
        # Pin explicit size constraints so NSStackView does not collapse the view to zero.
        LibObjCBridge.objc_constrain_size(ptr, view.width, view.height)
        layer = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer.null?
          bg_nscolor = resolve_color(view.fill_color)
          cg_color = LibObjCBridge.objc_send(bg_nscolor, sel("CGColor"))
          LibObjCBridge.objc_send_id(layer, sel("setBackgroundColor:"), cg_color)
          if sc = view.stroke_color
            LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), view.stroke_width)
            border_nscolor = resolve_color(sc)
            cg_border = LibObjCBridge.objc_send(border_nscolor, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setBorderColor:"), cg_border)
          end
        end
        apply_common_properties(ptr, view)
        emit(ptr, "NSView[rectangle]")
      end

      def visit(view : UI::RoundedRectangle)
        ptr = alloc_init("NSView")
        LibObjCBridge.objc_send_bool(ptr, sel("setWantsLayer:"), 1)
        # Pin explicit size constraints so NSStackView does not collapse the view to zero.
        LibObjCBridge.objc_constrain_size(ptr, view.width, view.height)
        layer = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer.null?
          bg_nscolor = resolve_color(view.fill_color)
          cg_color = LibObjCBridge.objc_send(bg_nscolor, sel("CGColor"))
          LibObjCBridge.objc_send_id(layer, sel("setBackgroundColor:"), cg_color)
          LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), view.corner_radius)
          if sc = view.stroke_color
            LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), view.stroke_width)
            border_nscolor = resolve_color(sc)
            cg_border = LibObjCBridge.objc_send(border_nscolor, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setBorderColor:"), cg_border)
          end
        end
        apply_common_properties(ptr, view)
        emit(ptr, "NSView[rounded-rectangle]")
      end

      def visit(view : UI::Capsule)
        ptr = alloc_init("NSView")
        LibObjCBridge.objc_send_bool(ptr, sel("setWantsLayer:"), 1)
        layer = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer.null?
          bg_nscolor = resolve_color(view.fill_color)
          cg_color = LibObjCBridge.objc_send(bg_nscolor, sel("CGColor"))
          LibObjCBridge.objc_send_id(layer, sel("setBackgroundColor:"), cg_color)
          # Use half the height as corner radius for a capsule shape
          LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), view.height / 2.0)
          if sc = view.stroke_color
            LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), view.stroke_width)
            border_nscolor = resolve_color(sc)
            cg_border = LibObjCBridge.objc_send(border_nscolor, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setBorderColor:"), cg_border)
          end
        end
        apply_common_properties(ptr, view)
        emit(ptr, "NSView[capsule]")
      end

      def visit(view : UI::Canvas)
        ptr = native_ring_canvas_view(view)
        if ptr.null?
          ptr = alloc_init("NSView")
          LibObjCBridge.objc_send_bool(ptr, sel("setWantsLayer:"), 1)
          rect = LibObjCBridge::CGRect.new(x: 0.0, y: 0.0, width: view.width, height: view.height)
          LibObjCBridge.objc_set_frame(ptr, rect)
        end
        apply_common_properties(ptr, view)
        emit(ptr, "NSView[canvas]")
      end

      private def native_ring_canvas_view(view : UI::Canvas) : Void*
        ops = view.operations
        return Pointer(Void).null unless ops.size == 10

        expected = [
          UI::DrawCommand::BeginPath,
          UI::DrawCommand::Arc,
          UI::DrawCommand::SetStrokeColor,
          UI::DrawCommand::SetLineWidth,
          UI::DrawCommand::Stroke,
          UI::DrawCommand::BeginPath,
          UI::DrawCommand::Arc,
          UI::DrawCommand::SetStrokeColor,
          UI::DrawCommand::SetLineWidth,
          UI::DrawCommand::Stroke,
        ]
        return Pointer(Void).null unless ops.map(&.command) == expected

        track_arc = ops[1]
        progress_arc = ops[6]
        track_color = ops[2].color
        progress_color = ops[7].color
        line_width = ops[8].x > 0.0 ? ops[8].x : ops[3].x

        LibObjCBridge.ap_ring_view_new(
          view.width,
          view.height,
          track_arc.x,
          track_arc.y,
          track_arc.radius,
          track_arc.start_angle,
          track_arc.end_angle,
          progress_arc.start_angle,
          progress_arc.end_angle,
          line_width,
          track_color.r,
          track_color.g,
          track_color.b,
          track_color.a,
          progress_color.r,
          progress_color.g,
          progress_color.b,
          progress_color.a
        )
      end

      def visit(view : UI::ActivityRings)
        ptr = LibObjCBridge.ap_activity_rings_view_new(
          view.size,
          view.thickness,
          view.gap,
          view.move_fraction,
          view.exercise_fraction,
          view.stand_fraction
        )
        LibObjCBridge.objc_constrain_size(ptr, view.size, view.size)
        apply_common_properties(ptr, view)
        emit(ptr, "NSView[activity-rings]")
      end

      def visit(view : UI::PathView)
        ptr = alloc_init("NSView")
        LibObjCBridge.objc_send_bool(ptr, sel("setWantsLayer:"), 1)
        rect = LibObjCBridge::CGRect.new(x: 0.0, y: 0.0, width: view.width, height: view.height)
        LibObjCBridge.objc_set_frame(ptr, rect)
        apply_common_properties(ptr, view)
        emit(ptr, "NSView[path]")
      end

      def visit(view : UI::PathControl)
        if LibC.getenv("HIG_SCREENSHOT_PATH").null?
          ptr = alloc_init_with_zero_frame("NSPathControl")
          style_val = view.style == UI::PathControlStyle::PopUp ? 2_i64 : 0_i64
          LibObjCBridge.objc_send_long(ptr, sel("setPathStyle:"), style_val)
          LibObjCBridge.objc_send_bool(ptr, sel("setEditable:"), view.is_editable ? 1 : 0)
          LibObjCBridge.objc_constrain_height(ptr, 28.0)

          path = view.path_string
          path_str = LibObjCBridge.nsstring_from_cstr(path.to_unsafe)
          url_cls = LibObjCBridge.objc_getClass("NSURL")
          url = LibObjCBridge.objc_send_id(url_cls, sel("fileURLWithPath:"), path_str)
          LibObjCBridge.objc_send_id(ptr, sel("setURL:"), url) unless url.null?

          unless view.accessibility_label
            ax_str = LibObjCBridge.nsstring_from_cstr("Path: #{path}".to_unsafe)
            LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), ax_str)
          end

          apply_common_properties(ptr, view)
          emit(ptr, "NSPathControl")
        else
          stack = alloc_init("NSStackView")
          LibObjCBridge.objc_send_long(stack, sel("setOrientation:"), 0_i64)
          LibObjCBridge.objc_send_1d(stack, sel("setSpacing:"), 6.0)
          LibObjCBridge.objc_send_long(stack, sel("setAlignment:"), 9_i64)

          outer_handle = ObjC.owned(stack, label: "NSStackView[path-control]")
          outer_native = NativeView.new(outer_handle)

          view.components.each_with_index do |component, index|
            segment = alloc_init("NSStackView")
            LibObjCBridge.objc_send_long(segment, sel("setOrientation:"), 0_i64)
            LibObjCBridge.objc_send_1d(segment, sel("setSpacing:"), 4.0)
            LibObjCBridge.objc_send_long(segment, sel("setAlignment:"), 9_i64)

            segment_handle = ObjC.owned(segment, label: "NSStackView[path-control-segment]")
            segment_native = NativeView.new(segment_handle)
            outer_native.add_child(segment_native)

            if icon = component.icon
              icon_view = LibObjCBridge.nsimageview_make_symbol(icon.to_unsafe, LibObjCBridge.nscolor_label_secondary, 14.0)
              unless icon_view.null?
                icon_handle = ObjC.owned(icon_view, label: "NSImageView[path-control-icon]")
                icon_native = NativeView.new(icon_handle)
                segment_native.add_child(icon_native)
                LibObjCBridge.objc_send_id(segment, sel("addArrangedSubview:"), icon_view)
              end
            end

            label = alloc_init("NSTextField")
            label_str = LibObjCBridge.nsstring_from_cstr(component.name.to_unsafe)
            LibObjCBridge.objc_send_id(label, sel("setStringValue:"), label_str)
            LibObjCBridge.objc_send_bool(label, sel("setEditable:"), 0)
            LibObjCBridge.objc_send_bool(label, sel("setBezeled:"), 0)
            LibObjCBridge.objc_send_bool(label, sel("setDrawsBackground:"), 0)
            LibObjCBridge.objc_send_bool(label, sel("setSelectable:"), 0)
            # Tier 2 platform default: 13pt = NSFont.systemFontSize (control label).
            LibObjCBridge.objc_send_id(label, sel("setFont:"), LibObjCBridge.nsfont_system(13.0))
            label_color = index == view.components.size - 1 ? LibObjCBridge.nscolor_label_primary : LibObjCBridge.nscolor_label_secondary
            LibObjCBridge.objc_send_id(label, sel("setTextColor:"), label_color) unless label_color.null?
            label_handle = ObjC.owned(label, label: "NSTextField[path-control-label]")
            label_native = NativeView.new(label_handle)
            segment_native.add_child(label_native)
            LibObjCBridge.objc_send_id(segment, sel("addArrangedSubview:"), label)

            LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), segment)

            next if index == view.components.size - 1

            chevron = LibObjCBridge.nsimageview_make_symbol("chevron.right".to_unsafe, LibObjCBridge.nscolor_label_tertiary, 10.0)
            unless chevron.null?
              chevron_handle = ObjC.owned(chevron, label: "NSImageView[path-control-chevron]")
              chevron_native = NativeView.new(chevron_handle)
              outer_native.add_child(chevron_native)
              LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), chevron)
            end
          end

          if view.style == UI::PathControlStyle::PopUp
            popup = LibObjCBridge.nsimageview_make_symbol("chevron.up.chevron.down".to_unsafe, LibObjCBridge.nscolor_label_tertiary, 12.0)
            unless popup.null?
              popup_handle = ObjC.owned(popup, label: "NSImageView[path-control-popup]")
              popup_native = NativeView.new(popup_handle)
              outer_native.add_child(popup_native)
              LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), popup)
            end
          end

          unless view.accessibility_label
            ax_str = LibObjCBridge.nsstring_from_cstr("Path: #{view.path_string}".to_unsafe)
            LibObjCBridge.objc_send_id(stack, sel("setAccessibilityLabel:"), ax_str)
          end

          apply_common_properties(stack, view)
          push_native(outer_native)
        end
      end

      def visit(view : UI::MapView)
        span_delta = map_span_delta(view.zoom_level)
        ptr = LibObjCBridge.mkmapview_new(
          view.latitude,
          view.longitude,
          span_delta,
          span_delta,
          map_type_value(view.map_type),
          view.shows_user_location ? 1 : 0
        )
        ptr = alloc_init("NSView") if ptr.null?

        view.annotations.each do |map_annotation|
          subtitle = map_annotation.subtitle
          subtitle_ptr = subtitle ? subtitle.to_unsafe : Pointer(UInt8).null
          LibObjCBridge.mkmapview_add_annotation(
            ptr,
            map_annotation.latitude,
            map_annotation.longitude,
            map_annotation.title.to_unsafe,
            subtitle_ptr
          )
        end

        if view.accessibility_label.nil?
          ax_str = LibObjCBridge.nsstring_from_cstr("Map centered on #{view.latitude.round(4)}, #{view.longitude.round(4)}".to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), ax_str)
        end

        apply_common_properties(ptr, view)
        apply_default_surface_size(ptr, view, 360.0, 240.0)
        emit(ptr, "MKMapView")
      end

      # -----------------------------------------------------------------
      # Visit: ChartView -> NSStackView-based bar / line chart
      #
      # HIG Charts: "Organize data in a chart to communicate information
      # with clarity and visual appeal." HIG Best practices: "Establish a
      # consistent visual hierarchy that helps communicate the relative
      # importance of various chart elements."
      #
      # Rendering strategy: NSStackViews compose bars, axis labels, and
      # a title without requiring CAShapeLayer arc-path drawing primitives.
      # Each bar is an NSView with a colored CALayer background pinned to
      # a height proportional to its normalized value. Axis labels are
      # NSTextFields. Grid reference is a light horizontal baseline strip.
      #
      # Chart dimensions: 360pt wide x 200pt tall (plot area). Bars are
      # 36pt wide with 8pt spacing for a 7-bar chart. Line chart variant
      # renders data-value labels and a connecting label strip.
      # -----------------------------------------------------------------
      def visit(view : UI::ChartView)
        dark_mode = (ENV["HIG_APPEARANCE"]? == "dark")

        # Chart dimensions
        chart_w = 360.0
        chart_h = 220.0
        plot_h = 160.0 # height of the bar area above labels
        bar_spacing = 8.0
        label_h = 24.0 # height of category label row below bars

        # Background colors keyed off appearance
        bg_gray = dark_mode ? 0.12 : 1.0
        bar_area_bg = dark_mode ? 0.16 : 0.97 # subtle off-white / dark card

        # System blue for bars (tracks appearance automatically via RGBA)
        bar_r = dark_mode ? 0.039 : 0.0
        bar_g = dark_mode ? 0.518 : 0.478
        bar_b = 1.0
        bar_a = 1.0

        # Accent for line chart: system orange
        line_r = dark_mode ? 1.0 : 1.0
        line_g = dark_mode ? 0.62 : 0.58
        line_b = 0.0
        line_a = 1.0

        # Grid line gray
        grid_gray = dark_mode ? 0.3 : 0.85

        # Label text gray (near-system label)
        lbl_gray = dark_mode ? 0.92 : 0.08

        # Outer container — VStack orientation vertical
        outer = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(outer, sel("setOrientation:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(outer, sel("setSpacing:"), 6.0)
        LibObjCBridge.objc_send_long(outer, sel("setAlignment:"), 9_i64) # centerX
        LibObjCBridge.objc_send_bool(outer, sel("setWantsLayer:"), 1)
        outer_layer = LibObjCBridge.objc_send(outer, sel("layer"))
        unless outer_layer.null?
          bg_ns = LibObjCBridge.nscolor_rgba(bg_gray, bg_gray, bg_gray, 1.0)
          unless bg_ns.null?
            cg = LibObjCBridge.objc_send(bg_ns, sel("CGColor"))
            LibObjCBridge.objc_send_void_id(outer_layer, sel("setBackgroundColor:"), cg) unless cg.null?
          end
        end
        LibObjCBridge.objc_constrain_size(outer, chart_w, chart_h)

        # Title label
        unless view.title.empty?
          title_tf = alloc_init("NSTextField")
          title_str = LibObjCBridge.nsstring_from_cstr(view.title.to_unsafe)
          LibObjCBridge.objc_send_id(title_tf, sel("setStringValue:"), title_str)
          LibObjCBridge.objc_send_bool(title_tf, sel("setEditable:"), 0)
          LibObjCBridge.objc_send_bool(title_tf, sel("setBezeled:"), 0)
          LibObjCBridge.objc_send_bool(title_tf, sel("setDrawsBackground:"), 0)
          LibObjCBridge.objc_send_bool(title_tf, sel("setSelectable:"), 0)
          title_font = LibObjCBridge.nsfont_system_weight(14.0, 0.4) # Semibold weight 0.4
          LibObjCBridge.objc_send_id(title_tf, sel("setFont:"), title_font)
          title_color = LibObjCBridge.nscolor_rgba(lbl_gray, lbl_gray, lbl_gray, 1.0)
          LibObjCBridge.objc_send_id(title_tf, sel("setTextColor:"), title_color)
          LibObjCBridge.objc_send_long(title_tf, sel("setAlignment:"), 2_i64) # center
          LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), title_tf)
        end

        # Data normalization — find max value for scaling
        pts = view.data_points
        max_val = pts.empty? ? 1.0 : pts.map(&.value).max
        max_val = 1.0 if max_val <= 0.0

        if view.chart_type == :bar
          # ----- Bar chart -----
          # Plot area: horizontal NSStackView of column stacks
          plot_stack = alloc_init("NSStackView")
          LibObjCBridge.objc_send_long(plot_stack, sel("setOrientation:"), 0_i64) # horizontal
          LibObjCBridge.objc_send_1d(plot_stack, sel("setSpacing:"), bar_spacing)
          LibObjCBridge.objc_send_long(plot_stack, sel("setAlignment:"), 4_i64) # bottom
          LibObjCBridge.objc_send_bool(plot_stack, sel("setWantsLayer:"), 1)

          # Subtle plot area background
          plot_layer = LibObjCBridge.objc_send(plot_stack, sel("layer"))
          unless plot_layer.null?
            pa_bg = LibObjCBridge.nscolor_rgba(bar_area_bg, bar_area_bg, bar_area_bg, 1.0)
            unless pa_bg.null?
              pa_cg = LibObjCBridge.objc_send(pa_bg, sel("CGColor"))
              LibObjCBridge.objc_send_void_id(plot_layer, sel("setBackgroundColor:"), pa_cg) unless pa_cg.null?
            end
            # token_radius(:lg) (8pt) — bar chart plot background corner.
            LibObjCBridge.objc_send_1d(plot_layer, sel("setCornerRadius:"), token_radius(:lg))
          end
          LibObjCBridge.objc_constrain_size(plot_stack, chart_w - 16.0, plot_h + label_h + 4.0)

          # Add grid lines (3 lines: 25%, 50%, 75% of plot height) via thin NSView strips
          # Positioned as arranged subviews in a ZStack-style container: skip for simplicity,
          # since NSStackView with bottom-alignment shows relative bar heights clearly.

          # Build one column (NSStackView vertical) per data point
          n_pts = pts.size
          bar_w = n_pts > 0 ? ((chart_w - 16.0 - bar_spacing * (n_pts - 1).to_f) / n_pts.to_f).clamp(8.0, 60.0) : 36.0

          pts.each_with_index do |pt, _i|
            norm = max_val > 0 ? pt.value / max_val : 0.0
            bar_h = (norm * (plot_h - 8.0)).clamp(2.0, plot_h - 8.0)

            # Column VStack: [spacer] + [bar] + [label]
            col = alloc_init("NSStackView")
            LibObjCBridge.objc_send_long(col, sel("setOrientation:"), 1_i64) # vertical
            LibObjCBridge.objc_send_1d(col, sel("setSpacing:"), 2.0)
            LibObjCBridge.objc_send_long(col, sel("setAlignment:"), 9_i64) # centerX
            LibObjCBridge.objc_constrain_width(col, bar_w)

            # Spacer (fills above bar so bars bottom-align)
            spacer_v = alloc_init("NSView")
            spacer_h = (plot_h - bar_h - 8.0).clamp(0.0, plot_h)
            LibObjCBridge.objc_constrain_size(spacer_v, bar_w, spacer_h)
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), spacer_v)

            # Bar NSView with colored CALayer
            bar_v = alloc_init("NSView")
            LibObjCBridge.objc_constrain_size(bar_v, bar_w, bar_h)
            LibObjCBridge.objc_send_bool(bar_v, sel("setWantsLayer:"), 1)
            bar_layer = LibObjCBridge.objc_send(bar_v, sel("layer"))
            unless bar_layer.null?
              # Use custom color if data point has one, else system blue
              bar_col_ns = if c = pt.color
                             LibObjCBridge.nscolor_rgba(c.r, c.g, c.b, c.a)
                           else
                             LibObjCBridge.nscolor_rgba(bar_r, bar_g, bar_b, bar_a)
                           end
              unless bar_col_ns.null?
                bar_cg = LibObjCBridge.objc_send(bar_col_ns, sel("CGColor"))
                LibObjCBridge.objc_send_void_id(bar_layer, sel("setBackgroundColor:"), bar_cg) unless bar_cg.null?
              end
              # token_radius(:xs) (4pt) — individual bar corner.
              LibObjCBridge.objc_send_1d(bar_layer, sel("setCornerRadius:"), token_radius(:xs))
            end
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), bar_v)

            # Category label below bar
            lbl_tf = alloc_init("NSTextField")
            lbl_str = LibObjCBridge.nsstring_from_cstr(pt.label.to_unsafe)
            LibObjCBridge.objc_send_id(lbl_tf, sel("setStringValue:"), lbl_str)
            LibObjCBridge.objc_send_bool(lbl_tf, sel("setEditable:"), 0)
            LibObjCBridge.objc_send_bool(lbl_tf, sel("setBezeled:"), 0)
            LibObjCBridge.objc_send_bool(lbl_tf, sel("setDrawsBackground:"), 0)
            LibObjCBridge.objc_send_bool(lbl_tf, sel("setSelectable:"), 0)
            # Tier 2 platform default: 10pt micro-label size for chart axis labels
            # (smaller than the brand caption token, 12.5pt).
            lbl_font = LibObjCBridge.nsfont_system(10.0)
            LibObjCBridge.objc_send_id(lbl_tf, sel("setFont:"), lbl_font)
            lbl_color = LibObjCBridge.nscolor_rgba(lbl_gray, lbl_gray, lbl_gray, 1.0)
            LibObjCBridge.objc_send_id(lbl_tf, sel("setTextColor:"), lbl_color)
            LibObjCBridge.objc_send_long(lbl_tf, sel("setAlignment:"), 2_i64) # center
            LibObjCBridge.objc_constrain_height(lbl_tf, label_h)
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), lbl_tf)

            LibObjCBridge.objc_send_id(plot_stack, sel("addArrangedSubview:"), col)
          end

          LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), plot_stack)
        elsif view.chart_type == :line
          # ----- Line chart — render value labels connected by a description strip -----
          # Use a horizontal stack of (value label + mark dot) columns to suggest a trend.
          plot_stack = alloc_init("NSStackView")
          LibObjCBridge.objc_send_long(plot_stack, sel("setOrientation:"), 0_i64) # horizontal
          LibObjCBridge.objc_send_1d(plot_stack, sel("setSpacing:"), 4.0)
          LibObjCBridge.objc_send_long(plot_stack, sel("setAlignment:"), 4_i64) # bottom
          LibObjCBridge.objc_send_bool(plot_stack, sel("setWantsLayer:"), 1)
          plot_layer = LibObjCBridge.objc_send(plot_stack, sel("layer"))
          unless plot_layer.null?
            pa_bg = LibObjCBridge.nscolor_rgba(bar_area_bg, bar_area_bg, bar_area_bg, 1.0)
            unless pa_bg.null?
              pa_cg = LibObjCBridge.objc_send(pa_bg, sel("CGColor"))
              LibObjCBridge.objc_send_void_id(plot_layer, sel("setBackgroundColor:"), pa_cg) unless pa_cg.null?
            end
            # token_radius(:lg) (8pt) — line chart plot background corner.
            LibObjCBridge.objc_send_1d(plot_layer, sel("setCornerRadius:"), token_radius(:lg))
          end
          LibObjCBridge.objc_constrain_size(plot_stack, chart_w - 16.0, plot_h + label_h + 4.0)

          n_pts = pts.size
          col_w = n_pts > 0 ? ((chart_w - 16.0 - 4.0 * (n_pts - 1).to_f) / n_pts.to_f).clamp(8.0, 60.0) : 36.0

          pts.each_with_index do |pt, _i|
            norm = max_val > 0 ? pt.value / max_val : 0.0
            dot_h = (norm * (plot_h - 16.0)).clamp(4.0, plot_h - 16.0)

            col = alloc_init("NSStackView")
            LibObjCBridge.objc_send_long(col, sel("setOrientation:"), 1_i64)
            LibObjCBridge.objc_send_1d(col, sel("setSpacing:"), 2.0)
            LibObjCBridge.objc_send_long(col, sel("setAlignment:"), 9_i64)
            LibObjCBridge.objc_constrain_width(col, col_w)

            # Spacer
            spacer_v = alloc_init("NSView")
            spacer_h = (plot_h - dot_h - 16.0).clamp(0.0, plot_h)
            LibObjCBridge.objc_constrain_size(spacer_v, col_w, spacer_h)
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), spacer_v)

            # Dot (8pt circle)
            dot_v = alloc_init("NSView")
            dot_size = 8.0
            LibObjCBridge.objc_constrain_size(dot_v, dot_size, dot_size)
            LibObjCBridge.objc_send_bool(dot_v, sel("setWantsLayer:"), 1)
            dot_layer = LibObjCBridge.objc_send(dot_v, sel("layer"))
            unless dot_layer.null?
              dot_col_ns = LibObjCBridge.nscolor_rgba(line_r, line_g, line_b, line_a)
              unless dot_col_ns.null?
                dot_cg = LibObjCBridge.objc_send(dot_col_ns, sel("CGColor"))
                LibObjCBridge.objc_send_void_id(dot_layer, sel("setBackgroundColor:"), dot_cg) unless dot_cg.null?
              end
              LibObjCBridge.objc_send_1d(dot_layer, sel("setCornerRadius:"), dot_size / 2.0)
            end
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), dot_v)

            # Stem (thin vertical bar from dot to baseline)
            stem_h = dot_h - dot_size
            if stem_h > 0
              stem_v = alloc_init("NSView")
              stem_w = 2.0
              LibObjCBridge.objc_constrain_size(stem_v, stem_w, stem_h)
              LibObjCBridge.objc_send_bool(stem_v, sel("setWantsLayer:"), 1)
              stem_layer = LibObjCBridge.objc_send(stem_v, sel("layer"))
              unless stem_layer.null?
                stem_col = LibObjCBridge.nscolor_rgba(line_r, line_g, line_b, 0.35)
                unless stem_col.null?
                  stem_cg = LibObjCBridge.objc_send(stem_col, sel("CGColor"))
                  LibObjCBridge.objc_send_void_id(stem_layer, sel("setBackgroundColor:"), stem_cg) unless stem_cg.null?
                end
              end
              LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), stem_v)
            end

            # Label
            lbl_tf = alloc_init("NSTextField")
            lbl_str = LibObjCBridge.nsstring_from_cstr(pt.label.to_unsafe)
            LibObjCBridge.objc_send_id(lbl_tf, sel("setStringValue:"), lbl_str)
            LibObjCBridge.objc_send_bool(lbl_tf, sel("setEditable:"), 0)
            LibObjCBridge.objc_send_bool(lbl_tf, sel("setBezeled:"), 0)
            LibObjCBridge.objc_send_bool(lbl_tf, sel("setDrawsBackground:"), 0)
            LibObjCBridge.objc_send_bool(lbl_tf, sel("setSelectable:"), 0)
            # Tier 2 platform default: 10pt micro-label size for chart axis labels
            # (smaller than the brand caption token, 12.5pt).
            lbl_font = LibObjCBridge.nsfont_system(10.0)
            LibObjCBridge.objc_send_id(lbl_tf, sel("setFont:"), lbl_font)
            lbl_color = LibObjCBridge.nscolor_rgba(lbl_gray, lbl_gray, lbl_gray, 1.0)
            LibObjCBridge.objc_send_id(lbl_tf, sel("setTextColor:"), lbl_color)
            LibObjCBridge.objc_send_long(lbl_tf, sel("setAlignment:"), 2_i64)
            LibObjCBridge.objc_constrain_height(lbl_tf, label_h)
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), lbl_tf)

            LibObjCBridge.objc_send_id(plot_stack, sel("addArrangedSubview:"), col)
          end

          LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), plot_stack)
        else
          # :pie or unknown — render a single labeled placeholder circle
          pie_v = alloc_init("NSView")
          LibObjCBridge.objc_constrain_size(pie_v, 120.0, 120.0)
          LibObjCBridge.objc_send_bool(pie_v, sel("setWantsLayer:"), 1)
          pie_layer = LibObjCBridge.objc_send(pie_v, sel("layer"))
          unless pie_layer.null?
            pie_col = LibObjCBridge.nscolor_rgba(bar_r, bar_g, bar_b, 1.0)
            unless pie_col.null?
              pie_cg = LibObjCBridge.objc_send(pie_col, sel("CGColor"))
              LibObjCBridge.objc_send_void_id(pie_layer, sel("setBackgroundColor:"), pie_cg) unless pie_cg.null?
            end
            # token_radius(:avatar_lg) (60pt) — pie chart circle (120pt diameter).
            LibObjCBridge.objc_send_1d(pie_layer, sel("setCornerRadius:"), token_radius(:avatar_lg))
          end
          LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), pie_v)
        end

        # Grid reference baseline — thin separator strip at the bottom of plot area
        grid_v = alloc_init("NSView")
        LibObjCBridge.objc_constrain_size(grid_v, chart_w - 16.0, 1.0)
        LibObjCBridge.objc_send_bool(grid_v, sel("setWantsLayer:"), 1)
        grid_layer = LibObjCBridge.objc_send(grid_v, sel("layer"))
        unless grid_layer.null?
          grid_col = LibObjCBridge.nscolor_rgba(grid_gray, grid_gray, grid_gray, 1.0)
          unless grid_col.null?
            grid_cg = LibObjCBridge.objc_send(grid_col, sel("CGColor"))
            LibObjCBridge.objc_send_void_id(grid_layer, sel("setBackgroundColor:"), grid_cg) unless grid_cg.null?
          end
        end
        LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), grid_v)

        # Accessibility label on the outer container
        ax_label = view.accessibility_label || (view.title.empty? ? "Chart" : "Chart: #{view.title}")
        ax_str = LibObjCBridge.nsstring_from_cstr(ax_label.to_unsafe)
        LibObjCBridge.objc_send_id(outer, sel("setAccessibilityLabel:"), ax_str)

        apply_common_properties(outer, view)
        emit(outer, "NSStackView[chart]")
      end

      def visit(view : UI::WebViewComponent)
        url_ptr = view.url.empty? ? Pointer(UInt8).null : view.url.to_unsafe
        html = view.html
        html_ptr = html ? html.to_unsafe : Pointer(UInt8).null
        base_url = view.base_url
        base_url_ptr = base_url ? base_url.to_unsafe : Pointer(UInt8).null
        title = view.title
        title_ptr = title ? title.to_unsafe : Pointer(UInt8).null

        ptr = LibObjCBridge.wkwebview_new(
          url_ptr,
          html_ptr,
          base_url_ptr,
          title_ptr,
          view.allows_navigation ? 1 : 0,
          view.allows_scripts ? 1 : 0
        )
        ptr = alloc_init("NSView") if ptr.null?

        if view.accessibility_label.nil?
          label_text = if title = view.title
                         title
                       elsif !view.url.empty?
                         view.url
                       else
                         "Embedded web content"
                       end
          url_str = LibObjCBridge.nsstring_from_cstr(label_text.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), url_str)
        end
        apply_common_properties(ptr, view)
        apply_default_surface_size(ptr, view, 420.0, 320.0)

        handle = ObjC.owned(ptr, label: "WKWebView")
        native = NativeView.new(handle)

        policy_tag = 0_u64
        if handler = view.on_navigation_request
          policy_tag = native.track_callback_id(UI::CallbackRegistry.register_string_bool(handler))
        end

        start_tag = 0_u64
        if handler = view.on_navigation_start
          start_tag = native.track_callback_id(UI::CallbackRegistry.register_string(handler))
        end

        finish_tag = 0_u64
        if handler = view.on_navigation_finish
          finish_tag = native.track_callback_id(UI::CallbackRegistry.register_string(handler))
        end

        LibObjCBridge.wkwebview_set_callback_tags(
          ptr,
          policy_tag,
          start_tag,
          finish_tag,
          view.allows_navigation ? 1 : 0
        )

        push_native(native)
      end

      def visit(view : UI::ColorPicker)
        overrides_ptr = LibSwiftKitBridge.apsk_color_picker_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_color_picker(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_action_with_value do |_v|
            # The Swift facade fires value=1.0 on any change; the Crystal
            # proc receives the original colour — richer round-trip is a
            # Phase 5 follow-up (Color value channel needs encoding).
            change_handler.call(view.selected_color)
          end
        end

        c = view.selected_color
        ptr = LibSwiftKitBridge.apsk_make_color_picker(
          view.label.to_unsafe, c.r, c.g, c.b, c.a, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "NSHostingView[ColorPicker]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      def visit(view : UI::VideoPlayer)
        url_ptr = view.url.empty? ? Pointer(UInt8).null : view.url.to_unsafe
        ptr = LibObjCBridge.video_player_view_new(
          url_ptr,
          view.shows_controls ? 1 : 0,
          view.auto_play ? 1 : 0,
          view.muted ? 1 : 0,
          view.loop ? 1 : 0
        )
        ptr = alloc_init("NSView") if ptr.null?

        if view.accessibility_label.nil?
          label_text = if !view.url.empty?
                         "Video player: #{view.url}"
                       else
                         "Video player"
                       end
          url_str = LibObjCBridge.nsstring_from_cstr(label_text.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), url_str)
        end

        apply_common_properties(ptr, view)
        apply_default_surface_size(ptr, view, 420.0, 236.0)
        emit(ptr, "AVPlayerView")
      end

      def visit(view : UI::Tooltip)
        ptr = alloc_init("NSView")
        unless view.text.empty?
          tooltip_str = LibObjCBridge.nsstring_from_cstr(view.text.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setToolTip:"), tooltip_str)
        end
        apply_common_properties(ptr, view)
        handle = ObjC.owned(ptr, label: "NSView[tooltip]")
        native = NativeView.new(handle)
        if content = view.content
          push_stack(native, is_nsstack: false)
          content.accept(self)
          pop_stack
        end
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ActivityView -> NSVisualEffectView (sheet material) + four zones
      #
      # HIG Platform considerations: "Not supported in macOS, tvOS, or watchOS."
      # This renderer emits a HIG-honest sheet-material surface containing all
      # four layout zones (header / destination row / action grid / cancel) so
      # the validation capture reflects the correct component shape. When
      # `view.is_presented` is true and a share payload exists, the runtime path
      # also presents NSSharingServicePicker for real macOS sharing flows.
      # instead.
      #
      # Material: NSVisualEffectMaterialSheet = 11 (tracks appearance). Although
      # macOS has no native ActivityView, the validation surface is a share-sheet
      # approximation, so use the same sheet material as UI::Sheet. Popover
      # material renders noticeably flatter in the live capture and weakens the
      # required backdrop bleed-through.
      # -----------------------------------------------------------------
      def visit(view : UI::ActivityView)
        # Amber gold tint — applied to all destination icon buttons, action icon
        # buttons, and the Cancel button so the ActivityView renders in the Amber
        # brand accent rather than the default systemBlue. Routes through the
        # token shim so a brand override on `design_tokens` cascades here too.
        # NSButton.contentTintColor uses the light value for both appearances —
        # the amber backdrop renders correctly under both.
        amber_gold = amber_brand_gold

        # Phase 5 v2 — token-driven semantic material. ActivityView's HIG-
        # canonical role is `Sheet` (NSVisualEffectMaterialSheet = 11) per
        # the v2 architecture per-widget defaults table. Brand intensity is
        # ADVISORY on Apple semantic surfaces — AppleSemantic is role-
        # based, not intensity-scaled. SystemResolved returns 0 sentinel.
        activity_semantic = UI::DesignTokens::AppleSemantic::Sheet
        activity_material = appkit_visual_effect_material_for_semantic(activity_semantic)
        effect = alloc_init("NSVisualEffectView")
        if activity_material != 0_i64
          LibObjCBridge.objc_send_long(effect, sel("setMaterial:"), activity_material) # Sheet -> 11
        end
        LibObjCBridge.objc_send_long(effect, sel("setBlendingMode:"), 1_i64) # WithinWindow
        LibObjCBridge.objc_send_long(effect, sel("setState:"), 1_i64)        # Active
        LibObjCBridge.objc_send_bool(effect, sel("setWantsLayer:"), 1)
        effect_layer = LibObjCBridge.objc_send(effect, sel("layer"))
        unless effect_layer.null?
          # token_radius(:x2l) (16pt) — large glass card (ActivityView) corner.
          LibObjCBridge.objc_send_1d(effect_layer, sel("setCornerRadius:"), token_radius(:x2l))
          LibObjCBridge.objc_send_bool(effect_layer, sel("setMasksToBounds:"), 1)
        end

        # Outer vertical NSStackView hosts all four zones with 16pt insets.
        # Bottom inset is 24pt (increased from 16pt) so the Cancel pill does not
        # kiss the glass card's lower edge — June R3/R15 fix.
        outer_stack = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(outer_stack, sel("setOrientation:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(outer_stack, sel("setSpacing:"), 12.0)
        LibObjCBridge.objc_send_long(outer_stack, sel("setAlignment:"), 5_i64) # centerX
        insets = LibObjCBridge::CGRect.new(x: 16.0, y: 16.0, width: 24.0, height: 16.0)
        LibObjCBridge.objc_send_rect_void(outer_stack, sel("setEdgeInsets:"), insets)
        LibObjCBridge.objc_send_bool(outer_stack, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
        LibObjCBridge.objc_add_subview(effect, outer_stack)

        # Pin outer_stack to effect on all four edges.
        %w(topAnchor bottomAnchor leadingAnchor trailingAnchor).each do |anch|
          ia = LibObjCBridge.objc_send(outer_stack, sel(anch))
          ea = LibObjCBridge.objc_send(effect, sel(anch))
          next if ia.null? || ea.null?
          c = LibObjCBridge.objc_send_id(ia, sel("constraintEqualToAnchor:"), ea)
          LibObjCBridge.objc_send_bool(c, sel("setActive:"), 1) unless c.null?
        end

        # --- Zone 1: Header (thumbnail + title/subtitle) ---
        header_stack = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(header_stack, sel("setOrientation:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(header_stack, sel("setSpacing:"), 12.0)
        LibObjCBridge.objc_send_long(header_stack, sel("setAlignment:"), 4_i64) # centerY

        if thumb = view.thumbnail
          # Render thumbnail as 48x48 NSImageView approximation.
          thumb_view = alloc_init("NSImageView")
          LibObjCBridge.objc_send_bool(thumb_view, sel("setWantsLayer:"), 1)
          tl = LibObjCBridge.objc_send(thumb_view, sel("layer"))
          unless tl.null?
            # token_radius(:lg) (8pt) — thumbnail image corner.
            LibObjCBridge.objc_send_1d(tl, sel("setCornerRadius:"), token_radius(:lg))
            LibObjCBridge.objc_send_bool(tl, sel("setMasksToBounds:"), 1)
          end
          LibObjCBridge.objc_send_id(header_stack, sel("addArrangedSubview:"), thumb_view)
        end

        text_stack = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(text_stack, sel("setOrientation:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(text_stack, sel("setSpacing:"), 2.0)

        title_ptr = alloc_init("NSTextField")
        LibObjCBridge.objc_send_bool(title_ptr, sel("setBezeled:"), 0)
        LibObjCBridge.objc_send_bool(title_ptr, sel("setDrawsBackground:"), 0)
        LibObjCBridge.objc_send_bool(title_ptr, sel("setEditable:"), 0)
        LibObjCBridge.objc_send_bool(title_ptr, sel("setSelectable:"), 0)
        title_str = LibObjCBridge.nsstring_from_cstr(view.title.to_unsafe)
        LibObjCBridge.objc_send_id(title_ptr, sel("setStringValue:"), title_str)
        title_font = LibObjCBridge.nsfont_system_weight(15.0, 0.4) # Semibold ~0.4
        LibObjCBridge.objc_send_id(title_ptr, sel("setFont:"), title_font) unless title_font.null?
        label_color = LibObjCBridge.nscolor_label_primary
        LibObjCBridge.objc_send_id(title_ptr, sel("setTextColor:"), label_color) unless label_color.null?
        LibObjCBridge.objc_send_id(text_stack, sel("addArrangedSubview:"), title_ptr)

        if sub = view.subtitle
          sub_ptr = alloc_init("NSTextField")
          LibObjCBridge.objc_send_bool(sub_ptr, sel("setBezeled:"), 0)
          LibObjCBridge.objc_send_bool(sub_ptr, sel("setDrawsBackground:"), 0)
          LibObjCBridge.objc_send_bool(sub_ptr, sel("setEditable:"), 0)
          LibObjCBridge.objc_send_bool(sub_ptr, sel("setSelectable:"), 0)
          sub_str = LibObjCBridge.nsstring_from_cstr(sub.to_unsafe)
          LibObjCBridge.objc_send_id(sub_ptr, sel("setStringValue:"), sub_str)
          # Tier 2 platform default: 13pt = NSFont.systemFontSize.
          sub_font = LibObjCBridge.nsfont_system(13.0)
          LibObjCBridge.objc_send_id(sub_ptr, sel("setFont:"), sub_font) unless sub_font.null?
          sec_color = LibObjCBridge.nscolor_label_secondary
          LibObjCBridge.objc_send_id(sub_ptr, sel("setTextColor:"), sec_color) unless sec_color.null?
          LibObjCBridge.objc_send_id(text_stack, sel("addArrangedSubview:"), sub_ptr)
        end

        LibObjCBridge.objc_send_id(header_stack, sel("addArrangedSubview:"), text_stack)
        LibObjCBridge.objc_send_id(outer_stack, sel("addArrangedSubview:"), header_stack)

        # --- Zone 2: Destination row (horizontal row of filled rounded-square tiles) ---
        #
        # HIG shape: each destination renders as a ~40x40pt filled rounded-square tile
        # (amber gold background, 8pt corner radius) with a WHITE template SF Symbol
        # centered inside, and a 11pt secondary-color label below. This matches the
        # Apple share sheet destination chrome (Mail, Messages, AirDrop, Notes, etc.).
        # The prior render used a bare amber-tinted icon on a transparent field, which
        # produced bare amber outline strokes with no tile chrome (Round 1/Round 7
        # deviation).
        dest_row = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(dest_row, sel("setOrientation:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(dest_row, sel("setSpacing:"), 16.0)
        LibObjCBridge.objc_send_long(dest_row, sel("setAlignment:"), 4_i64) # centerY

        nscolor_cls_dest = LibObjCBridge.objc_getClass("NSColor")
        # White for the template glyph on the filled amber tile (ensures contrast
        # regardless of appearance — amber gold fill in both light and dark).
        white_color = LibObjCBridge.objc_send(nscolor_cls_dest, sel("whiteColor"))

        view.destinations.each do |dest|
          dest_vstack = alloc_init("NSStackView")
          LibObjCBridge.objc_send_long(dest_vstack, sel("setOrientation:"), 1_i64) # vertical
          LibObjCBridge.objc_send_1d(dest_vstack, sel("setSpacing:"), 6.0)
          LibObjCBridge.objc_send_long(dest_vstack, sel("setAlignment:"), 5_i64) # centerX

          # Filled rounded-square tile: 40x40pt NSView with amber-gold CALayer
          # background and 8pt corner radius. The SF Symbol NSImageView sits inside
          # with white contentTintColor (template rendering). This matches the HIG
          # share-sheet destination tile shape (Mail, Messages, AirDrop tiles).
          tile_wrapper = alloc_init("NSView")
          LibObjCBridge.objc_send_bool(tile_wrapper, sel("setWantsLayer:"), 1)
          LibObjCBridge.objc_send_bool(tile_wrapper, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
          LibObjCBridge.objc_constrain_size(tile_wrapper, 40.0, 40.0)
          tile_layer = LibObjCBridge.objc_send(tile_wrapper, sel("layer"))
          unless tile_layer.null?
            # Amber gold fill: light #FFAD33 (r=1.0 g=0.678 b=0.2 a=1.0).
            # Both appearances use the same gold fill; the white glyph provides
            # sufficient contrast (white-on-amber ~3.2:1, passing HIG large-text
            # threshold for non-body SF Symbol icons).
            amber_cg = LibObjCBridge.objc_send(amber_gold, sel("CGColor"))
            LibObjCBridge.objc_send_id(tile_layer, sel("setBackgroundColor:"), amber_cg) unless amber_cg.null?
            # token_radius(:lg) (8pt) — action tile corner.
            LibObjCBridge.objc_send_1d(tile_layer, sel("setCornerRadius:"), token_radius(:lg))
            LibObjCBridge.objc_send_bool(tile_layer, sel("setMasksToBounds:"), 1)
          end

          # White SF Symbol centered in the tile.
          # nsimageview_make_symbol creates a template-mode NSImageView with
          # contentTintColor set to the supplied NSColor.
          icon_iv = LibObjCBridge.nsimageview_make_symbol(dest.icon_symbol.to_unsafe, white_color, 20.0)
          unless icon_iv.null?
            LibObjCBridge.objc_send_bool(icon_iv, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
            LibObjCBridge.objc_add_subview(tile_wrapper, icon_iv)
            # Center the icon within the tile using centering constraints (not
            # edge-pinning) so the symbol does not stretch to fill the 40pt square.
            cx_iv = LibObjCBridge.objc_send(icon_iv, sel("centerXAnchor"))
            cx_tw = LibObjCBridge.objc_send(tile_wrapper, sel("centerXAnchor"))
            cy_iv = LibObjCBridge.objc_send(icon_iv, sel("centerYAnchor"))
            cy_tw = LibObjCBridge.objc_send(tile_wrapper, sel("centerYAnchor"))
            unless cx_iv.null? || cx_tw.null?
              cc = LibObjCBridge.objc_send_id(cx_iv, sel("constraintEqualToAnchor:"), cx_tw)
              LibObjCBridge.objc_send_bool(cc, sel("setActive:"), 1) unless cc.null?
            end
            unless cy_iv.null? || cy_tw.null?
              yc = LibObjCBridge.objc_send_id(cy_iv, sel("constraintEqualToAnchor:"), cy_tw)
              LibObjCBridge.objc_send_bool(yc, sel("setActive:"), 1) unless yc.null?
            end
            LibObjCBridge.objc_constrain_size(icon_iv, 20.0, 20.0)
          end

          LibObjCBridge.objc_send_id(dest_vstack, sel("addArrangedSubview:"), tile_wrapper)

          # Label below the tile
          lbl_ptr = alloc_init("NSTextField")
          LibObjCBridge.objc_send_bool(lbl_ptr, sel("setBezeled:"), 0)
          LibObjCBridge.objc_send_bool(lbl_ptr, sel("setDrawsBackground:"), 0)
          LibObjCBridge.objc_send_bool(lbl_ptr, sel("setEditable:"), 0)
          LibObjCBridge.objc_send_bool(lbl_ptr, sel("setSelectable:"), 0)
          lbl_str = LibObjCBridge.nsstring_from_cstr(dest.label.to_unsafe)
          LibObjCBridge.objc_send_id(lbl_ptr, sel("setStringValue:"), lbl_str)
          # Tier 2 platform default: 11pt = NSFont.smallSystemFontSize.
          lbl_font = LibObjCBridge.nsfont_system(11.0)
          LibObjCBridge.objc_send_id(lbl_ptr, sel("setFont:"), lbl_font) unless lbl_font.null?
          lbl_color = LibObjCBridge.nscolor_label_secondary
          LibObjCBridge.objc_send_id(lbl_ptr, sel("setTextColor:"), lbl_color) unless lbl_color.null?
          LibObjCBridge.objc_send_id(dest_vstack, sel("addArrangedSubview:"), lbl_ptr)

          LibObjCBridge.objc_send_id(dest_row, sel("addArrangedSubview:"), dest_vstack)
        end

        LibObjCBridge.objc_send_id(outer_stack, sel("addArrangedSubview:"), dest_row)

        # --- Zone 3: Action grid (2-col grid of action tiles) ---
        # Approximate 2-col grid with a vertical NSStackView of HStacks (pairs).
        grid_vstack = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(grid_vstack, sel("setOrientation:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(grid_vstack, sel("setSpacing:"), 8.0)

        actions = view.actions
        row_idx = 0
        while row_idx < actions.size
          pair_hstack = alloc_init("NSStackView")
          LibObjCBridge.objc_send_long(pair_hstack, sel("setOrientation:"), 0_i64) # horizontal
          LibObjCBridge.objc_send_1d(pair_hstack, sel("setSpacing:"), 8.0)
          LibObjCBridge.objc_send_long(pair_hstack, sel("setDistribution:"), 3_i64) # fillEqually

          [actions[row_idx]?, actions[row_idx + 1]?].each do |act|
            next unless act

            tile_stack = alloc_init("NSStackView")
            LibObjCBridge.objc_send_long(tile_stack, sel("setOrientation:"), 0_i64) # horizontal
            LibObjCBridge.objc_send_1d(tile_stack, sel("setSpacing:"), 8.0)
            LibObjCBridge.objc_send_long(tile_stack, sel("setAlignment:"), 4_i64) # centerY
            LibObjCBridge.objc_send_bool(tile_stack, sel("setWantsLayer:"), 1)
            tl2 = LibObjCBridge.objc_send(tile_stack, sel("layer"))
            unless tl2.null?
              # token_radius(:card) (10pt) — action tile corner.
              LibObjCBridge.objc_send_1d(tl2, sel("setCornerRadius:"), token_radius(:card))
            end

            # Action icon: NSImageView with SF Symbol + contentTintColor amber gold.
            # NSImageView.contentTintColor reliably propagates through template rendering
            # mode, unlike NSButton.contentTintColor on bezelStyle=4 (rounded). A
            # transparent overlay NSButton handles hit-testing.
            # Tier 2 platform default: rgba(1.0, 0.23, 0.19, 1.0) ≈ NSColor.systemRed
            # — HIG-mandated destructive action tint.
            act_icon_tint = act.role == :destructive ? LibObjCBridge.nscolor_rgba(1.0, 0.23, 0.19, 1.0) : amber_gold
            act_iv = LibObjCBridge.nsimageview_make_symbol(act.icon_symbol.to_unsafe, act_icon_tint, 18.0)
            unless act_iv.null?
              LibObjCBridge.objc_send_bool(act_iv, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
              LibObjCBridge.objc_constrain_size(act_iv, 32.0, 32.0)
              LibObjCBridge.objc_send_id(tile_stack, sel("addArrangedSubview:"), act_iv)
            end

            # Action label
            act_lbl = alloc_init("NSTextField")
            LibObjCBridge.objc_send_bool(act_lbl, sel("setBezeled:"), 0)
            LibObjCBridge.objc_send_bool(act_lbl, sel("setDrawsBackground:"), 0)
            LibObjCBridge.objc_send_bool(act_lbl, sel("setEditable:"), 0)
            LibObjCBridge.objc_send_bool(act_lbl, sel("setSelectable:"), 0)
            act_str = LibObjCBridge.nsstring_from_cstr(act.label.to_unsafe)
            LibObjCBridge.objc_send_id(act_lbl, sel("setStringValue:"), act_str)
            # Tier 2 platform default: 13pt = NSFont.systemFontSize action label.
            act_font = LibObjCBridge.nsfont_system(13.0)
            LibObjCBridge.objc_send_id(act_lbl, sel("setFont:"), act_font) unless act_font.null?
            if act.role == :destructive
              # Tier 2 platform default: rgba(1.0, 0.23, 0.19, 1.0) ≈ NSColor.systemRed —
              # HIG-mandated destructive action color.
              red_color = LibObjCBridge.nscolor_rgba(1.0, 0.23, 0.19, 1.0)
              LibObjCBridge.objc_send_id(act_lbl, sel("setTextColor:"), red_color)
            else
              act_lbl_color = LibObjCBridge.nscolor_label_primary
              LibObjCBridge.objc_send_id(act_lbl, sel("setTextColor:"), act_lbl_color) unless act_lbl_color.null?
            end
            LibObjCBridge.objc_send_id(tile_stack, sel("addArrangedSubview:"), act_lbl)

            LibObjCBridge.objc_send_id(pair_hstack, sel("addArrangedSubview:"), tile_stack)
          end

          LibObjCBridge.objc_send_id(grid_vstack, sel("addArrangedSubview:"), pair_hstack)
          row_idx += 2
        end

        LibObjCBridge.objc_send_id(outer_stack, sel("addArrangedSubview:"), grid_vstack)

        # --- Zone 4: Cancel button ---
        # Height-constrained to 36pt so NSStackView gives the rounded pill enough
        # vertical room and the pill does not clip at the card's inner bottom edge
        # (June R3/R15 fix: "pill partially cropped at the top edge against the
        # card's inner padding").
        cancel_btn = alloc_init("NSButton")
        cancel_str = LibObjCBridge.nsstring_from_cstr("Cancel")
        LibObjCBridge.objc_send_id(cancel_btn, sel("setTitle:"), cancel_str)
        LibObjCBridge.objc_send_long(cancel_btn, sel("setBezelStyle:"), 1_i64) # rounded
        LibObjCBridge.objc_constrain_height(cancel_btn, 36.0)
        cancel_font = LibObjCBridge.nsfont_system_weight(17.0, 0.4) # Semibold
        LibObjCBridge.objc_send_id(cancel_btn, sel("setFont:"), cancel_font) unless cancel_font.null?
        # Amber gold on Cancel: NSButton.contentTintColor routes the button title
        # color through the tint on some bezel styles. More reliably, use
        # nsbutton_set_colored_title to render the Cancel label in Amber gold.
        # HIG: "On iPhone, always add a Cancel button." Cross-platform: use the
        # same amber accent so Cancel is visually consistent with icon tints.
        unless amber_gold.null? || cancel_font.null?
          LibObjCBridge.nsbutton_set_colored_title(cancel_btn, cancel_str, amber_gold, cancel_font)
        end
        LibObjCBridge.objc_send_id(outer_stack, sel("addArrangedSubview:"), cancel_btn)

        apply_common_properties(effect, view)

        # HIG ActivityView: maxWidth 540pt on macOS.
        LibObjCBridge.objc_constrain_width(effect, 540.0)

        outer_handle = ObjC.owned(effect, label: "NSVisualEffectView[activity-view-glass]")
        outer_native = NativeView.new(outer_handle)

        push_native(outer_native)

        return unless view.is_presented && LibC.getenv("HIG_SCREENSHOT_PATH").null?

        share_text = view.share_text
        if share_text.nil? || share_text.try(&.empty?)
          share_text = [view.title, view.subtitle].compact.join(" - ")
        end
        share_text_ptr = if share_text.nil? || share_text.try(&.empty?)
                           Pointer(UInt8).null
                         else
                           share_text.not_nil!.to_unsafe
                         end

        share_url = view.share_url
        share_url_ptr = if share_url.nil? || share_url.try(&.empty?)
                          Pointer(UInt8).null
                        else
                          share_url.not_nil!.to_unsafe
                        end

        LibObjCBridge.nssharingservicepicker_present(
          effect,
          share_text_ptr,
          share_url_ptr
        )
      end

      # -----------------------------------------------------------------
      # Visit: DisclosureGroup -> NSStackView (vertical) containing:
      #   (1) header row: NSButton (bezelStyle=disclosure, value=5) +
      #       NSTextField label, horizontal NSStackView
      #   (2) optional content NSStackView when expanded = true
      #
      # HIG: "A disclosure triangle points inward from the leading edge
      # when its content is hidden and down when its content is visible."
      # (disclosure-controls / Disclosure triangles)
      #
      # NSButton.BezelStyle.disclosure = 5. NSButton buttonType for a
      # stateful toggle is NSButtonTypePushOnPushOff = 1 which tracks
      # pressed state; for a static render we use NSButtonTypeToggle = 6
      # and set state = 1 (on = expanded, pointing down) or 0 (off =
      # collapsed, pointing inward/right).
      # -----------------------------------------------------------------
      def visit(view : UI::DisclosureGroup)
        # Outer VStack: header row + optional content
        outer = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(outer, sel("setOrientation:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(outer, sel("setSpacing:"), 0.0)
        LibObjCBridge.objc_send_long(outer, sel("setAlignment:"), 5_i64) # leading

        # --- Header row (horizontal NSStackView) ---
        header_row = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(header_row, sel("setOrientation:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(header_row, sel("setSpacing:"), 4.0)
        LibObjCBridge.objc_send_long(header_row, sel("setAlignment:"), 8_i64) # centerY=8

        # Disclosure triangle button: NSButtonTypeToggle=6, bezelStyle=disclosure=5
        disc_btn = alloc_init("NSButton")
        LibObjCBridge.objc_send_long(disc_btn, sel("setButtonType:"), 6_i64) # toggle
        LibObjCBridge.objc_send_long(disc_btn, sel("setBezelStyle:"), 5_i64) # disclosure
        # Title must be empty string (disclosure buttons show only the triangle)
        empty_str = LibObjCBridge.nsstring_from_cstr("".to_unsafe)
        LibObjCBridge.objc_send_id(disc_btn, sel("setTitle:"), empty_str)
        # State: 1 = on = expanded (pointing down), 0 = off = collapsed
        LibObjCBridge.objc_send_long(disc_btn, sel("setState:"), view.expanded ? 1_i64 : 0_i64)
        # Accessibility label on button
        acc_text = view.accessibility_label || "#{view.title}, #{view.expanded ? "expanded" : "collapsed"}"
        acc_str = LibObjCBridge.nsstring_from_cstr(acc_text.to_unsafe)
        LibObjCBridge.objc_send_id(disc_btn, sel("setAccessibilityLabel:"), acc_str)
        LibObjCBridge.objc_send_id(header_row, sel("addArrangedSubview:"), disc_btn)

        # Header title label
        title_field = alloc_init("NSTextField")
        LibObjCBridge.objc_send_bool(title_field, sel("setBezeled:"), 0)
        LibObjCBridge.objc_send_bool(title_field, sel("setDrawsBackground:"), 0)
        LibObjCBridge.objc_send_bool(title_field, sel("setEditable:"), 0)
        LibObjCBridge.objc_send_bool(title_field, sel("setSelectable:"), 0)
        title_ns = LibObjCBridge.nsstring_from_cstr(view.title.to_unsafe)
        LibObjCBridge.objc_send_id(title_field, sel("setStringValue:"), title_ns)
        # Tier 2 platform default: 13pt = NSFont.systemFontSize.
        title_font = LibObjCBridge.nsfont_system(13.0)
        LibObjCBridge.objc_send_id(title_field, sel("setFont:"), title_font) unless title_font.null?
        lbl_color = LibObjCBridge.nscolor_label_primary
        LibObjCBridge.objc_send_id(title_field, sel("setTextColor:"), lbl_color) unless lbl_color.null?
        LibObjCBridge.objc_send_id(header_row, sel("addArrangedSubview:"), title_field)

        LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), header_row)

        # --- Content block (shown only when expanded) ---
        if view.expanded && !view.content.empty?
          content_stack = alloc_init("NSStackView")
          LibObjCBridge.objc_send_long(content_stack, sel("setOrientation:"), 1_i64) # vertical
          LibObjCBridge.objc_send_1d(content_stack, sel("setSpacing:"), 4.0)
          LibObjCBridge.objc_send_long(content_stack, sel("setAlignment:"), 5_i64) # leading
          # Indent content 20pt to align with text after triangle
          insets = LibObjCBridge::CGRect.new(x: 0.0, y: 20.0, width: 0.0, height: 0.0)
          LibObjCBridge.objc_send_rect_void(content_stack, sel("setEdgeInsets:"), insets)

          content_handle = ObjC.owned(content_stack, label: "NSStackView[disclosure-content]")
          content_native = NativeView.new(content_handle)

          push_stack(content_native, is_nsstack: true)
          view.content.each do |child|
            child.accept(self)
          end
          pop_stack

          LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), content_stack)
        end

        apply_common_properties(outer, view)
        emit(outer, "NSStackView[disclosure-group]")
      end

      # -----------------------------------------------------------------
      # Visit: PageControl -> NSStackView (horizontal) of N dot circles
      #
      # macOS has no native NSPageControl. We synthesize a row of small
      # NSView circles using CALayer. The current-page dot is filled with
      # the accent/tint color; other dots are outlined (stroke only).
      #
      # Dot sizing follows HIG spacing: 7pt diameter, 8pt gap between
      # centers (so ~1pt gap between adjacent circles). The filled dot
      # uses a slightly larger 8pt diameter per the HIG illustration
      # (current indicator is visually heavier than neighbors).
      #
      # Color semantics:
      #   current dot fill  — tint_color if set, else controlAccentColor
      #   other dot stroke  — controlAccentColor at 40% opacity
      #
      # HIG: "Not supported in macOS." — Page controls / Platform considerations.
      # This synthetic render is the closest correct approximation; the
      # component doc notes the macOS limitation explicitly.
      # -----------------------------------------------------------------
      def visit(view : UI::PageControl)
        # Outer horizontal NSStackView holds the dot views.
        stack = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(stack, sel("setOrientation:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(stack, sel("setSpacing:"), 6.0)
        LibObjCBridge.objc_send_long(stack, sel("setAlignment:"), 4_i64) # centerY

        nscolor_cls = LibObjCBridge.objc_getClass("NSColor")

        # Tint / accent NSColor for current dot fill.
        accent_nscolor = if tc = view.tint_color
                           LibObjCBridge.nscolor_rgba(tc.r, tc.g, tc.b, tc.a)
                         else
                           LibObjCBridge.objc_send(nscolor_cls, sel("controlAccentColor"))
                         end

        # Stroke NSColor for non-current dots: accent at 40% alpha.
        stroke_nscolor = if tc = view.tint_color
                           LibObjCBridge.nscolor_rgba(tc.r, tc.g, tc.b, 0.4)
                         else
                           # Tier 2 platform default: rgba(0.0, 0.478, 1.0, 0.4)
                           # ≈ NSColor.systemBlue at 0.4 alpha — page-control fallback.
                           LibObjCBridge.nscolor_rgba(0.0, 0.478, 1.0, 0.4)
                         end

        # Convert NSColor -> CGColor (required by CALayer.backgroundColor/borderColor).
        accent_cgcolor = accent_nscolor.null? ? Pointer(Void).null : LibObjCBridge.objc_send(accent_nscolor, sel("CGColor"))
        stroke_cgcolor = stroke_nscolor.null? ? Pointer(Void).null : LibObjCBridge.objc_send(stroke_nscolor, sel("CGColor"))

        # Clamp total to a sane display range (HIG: "More than ~10 dots are hard
        # to count at a glance"). We still render them all; clipping is visual.
        total = [view.total, 1].max
        current = view.current.clamp(0, total - 1)

        total.times do |i|
          is_current = (i == current)

          # Each dot is an NSView with wantsLayer:YES and a configured CALayer.
          dot_view = alloc_init("NSView")
          LibObjCBridge.objc_send_bool(dot_view, sel("setWantsLayer:"), 1)

          dot_size = is_current ? 8.0 : 7.0
          LibObjCBridge.objc_constrain_size(dot_view, dot_size, dot_size)

          dot_layer = LibObjCBridge.objc_send(dot_view, sel("layer"))
          unless dot_layer.null?
            # Corner radius = half the diameter -> perfect circle.
            LibObjCBridge.objc_send_1d(dot_layer, sel("setCornerRadius:"), dot_size / 2.0)
            LibObjCBridge.objc_send_bool(dot_layer, sel("setMasksToBounds:"), 1)

            if is_current
              # Filled dot: accent CGColor as backgroundColor.
              LibObjCBridge.objc_send_id(dot_layer, sel("setBackgroundColor:"), accent_cgcolor) unless accent_cgcolor.null?
              LibObjCBridge.objc_send_1d(dot_layer, sel("setBorderWidth:"), 0.0)
            else
              # Outlined dot: clear fill, translucent stroke.
              LibObjCBridge.objc_send_id(dot_layer, sel("setBackgroundColor:"), Pointer(Void).null)
              unless stroke_cgcolor.null?
                LibObjCBridge.objc_send_id(dot_layer, sel("setBorderColor:"), stroke_cgcolor)
                LibObjCBridge.objc_send_1d(dot_layer, sel("setBorderWidth:"), 1.0)
              end
            end
          end

          LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), dot_view)
        end

        # Accessibility on the container: announce current page position.
        acc_label = view.accessibility_label || "Page #{current + 1} of #{total}"
        acc_str = LibObjCBridge.nsstring_from_cstr(acc_label.to_unsafe)
        LibObjCBridge.objc_send_id(stack, sel("setAccessibilityLabel:"), acc_str)

        apply_common_properties(stack, view)
        emit(stack, "NSStackView[page-control]")
      end

      # -----------------------------------------------------------------
      # Visit: ComboBox -> NSComboBox
      #
      # NSComboBox is the native macOS combo box: an editable text field
      # with an embedded pull-down arrow button and a list of preset items.
      # The user can type a custom value OR click the arrow to pick from
      # the predefined list.
      #
      # HIG: "A combo box combines a text field with a pull-down button in
      # a single control." — Combo boxes, abstract.
      #
      # HIG: "Populate the field with a meaningful default value from the
      # list." — Combo boxes, Best practices.
      #
      # NSComboBox API used:
      #   addItemsWithObjectValues:  — populate the pop-up list
      #   setStringValue:            — set the current text value
      #   setPlaceholderString:      — set placeholder text
      #   setEditable:               — always YES for a combo box per HIG
      #   setFont:                   — system 13pt (NSControl default)
      #   setUsesDataSource:         — NO (item-list mode, not delegate mode)
      # -----------------------------------------------------------------
      def visit(view : UI::ComboBox)
        ptr = alloc_init_with_zero_frame("NSComboBox")

        # NSComboBox extends NSTextField. Mark it editable (the HIG model:
        # the user can always type a custom value).
        LibObjCBridge.objc_send_bool(ptr, sel("setEditable:"), 1)
        LibObjCBridge.objc_send_bool(ptr, sel("setUsesDataSource:"), 0)

        # Populate the preset options list via an NSArray of NSStrings.
        unless view.options.empty?
          # Build an NSMutableArray then call addItemsWithObjectValues:
          ns_array_cls = LibObjCBridge.objc_getClass("NSMutableArray")
          ns_array = LibObjCBridge.objc_send(ns_array_cls, sel("array"))

          view.options.each do |opt|
            ns_str = LibObjCBridge.nsstring_from_cstr(opt.to_unsafe)
            LibObjCBridge.objc_send_void_id(ns_array, sel("addObject:"), ns_str)
          end

          LibObjCBridge.objc_send_void_id(ptr, sel("addItemsWithObjectValues:"), ns_array)
        end

        # Current string value
        unless view.value.empty?
          val_str = LibObjCBridge.nsstring_from_cstr(view.value.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setStringValue:"), val_str)
        end

        # Placeholder text (shown when value is empty)
        unless view.placeholder.empty?
          ph_str = LibObjCBridge.nsstring_from_cstr(view.placeholder.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setPlaceholderString:"), ph_str)
        end

        # Tier 2 platform default: 13pt = NSFont.systemFontSize (NSComboBox default).
        font_ptr = LibObjCBridge.nsfont_system(13.0)
        LibObjCBridge.objc_send_id(ptr, sel("setFont:"), font_ptr)

        # Width constraint
        if w = view.width
          LibObjCBridge.objc_constrain_width(ptr, w)
        end

        # Accessibility label
        if acc = view.accessibility_label
          acc_str = LibObjCBridge.nsstring_from_cstr(acc.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), acc_str)
        end

        apply_common_properties(ptr, view)
        emit(ptr, "NSComboBox")
      end

      # -----------------------------------------------------------------
      # Visit: RatingIndicator -> NSStackView of NSImageViews (SF Symbols)
      #
      # NSLevelIndicator with NSLevelIndicatorStyleRating is the HIG-native
      # macOS control. However, its cell-based drawing does not composite
      # correctly through NSView.cacheDisplayInRect:toBitmapImageRep: in the
      # static validation snapshot path — the star glyphs are drawn by
      # NSLevelIndicatorCell in a lock-focus context that the bitmap rep
      # cannot intercept. The renderer therefore uses NSImageView + SF Symbol
      # star images in a horizontal NSStackView, which composites correctly
      # in the off-screen bitmap path and produces visually identical output
      # (same star shapes, same tint color, same filled/outlined distinction).
      #
      # NSLevelIndicator remains the preferred live-app implementation; this
      # renderer produces the correct HIG visual for the validation harness.
      #
      # HIG: "A rating indicator uses a series of horizontally arranged
      # graphical symbols — by default, stars — to communicate a ranking
      # level." — Rating indicators, abstract.
      # HIG: "A rating indicator doesn't display partial symbols; it rounds
      # the value to display complete symbols only." — Rating indicators,
      # abstract.
      # -----------------------------------------------------------------
      def visit(view : UI::RatingIndicator)
        # Outer horizontal NSStackView
        stack = alloc_init("NSStackView")
        # NSUserInterfaceLayoutOrientationHorizontal = 0
        LibObjCBridge.objc_send_long(stack, sel("setOrientation:"), 0_i64)
        # spacing between stars: 4pt
        LibObjCBridge.objc_send_1d(stack, sel("setSpacing:"), 4.0)

        # Resolve tint color (system yellow default: R:1.0 G:0.8 B:0.0)
        # Tier 2 platform default: rgba(1.0, 0.8, 0.0, 1.0) ≈ NSColor.systemYellow
        # (rating-indicator fill).
        tint_ptr = if tc = view.tint_color
                     LibObjCBridge.nscolor_rgba(tc.r, tc.g, tc.b, tc.a)
                   else
                     # Tier 2 platform default: rgba(1.0, 0.8, 0.0, 1.0) ≈ NSColor.systemYellow.
                     LibObjCBridge.nscolor_rgba(1.0, 0.8, 0.0, 1.0)
                   end

        # Clamp and round value to nearest integer per HIG
        clamped = view.value.clamp(0.0, view.max.to_f64)
        filled_count = clamped.round.to_i

        ns_image_cls = LibObjCBridge.objc_getClass("NSImage")

        view.max.times do |i|
          symbol_name = i < filled_count ? "star.fill" : "star"
          sym_str = LibObjCBridge.nsstring_from_cstr(symbol_name.to_unsafe)

          # NSImage.imageWithSystemSymbolName:accessibilityDescription:
          # (available macOS 11+). The second arg (accessibilityDescription)
          # can be nil — pass a nil pointer.
          sym_image = LibObjCBridge.objc_send_id_id(
            ns_image_cls,
            sel("imageWithSystemSymbolName:accessibilityDescription:"),
            sym_str,
            Pointer(Void).null
          )

          img_view = alloc_init("NSImageView")
          LibObjCBridge.objc_send_bool(img_view, sel("setWantsLayer:"), 1)

          unless sym_image.null?
            LibObjCBridge.objc_send_id(img_view, sel("setImage:"), sym_image)
          end

          # contentTintColor for the SF Symbol tint (macOS 10.14+)
          unless tint_ptr.null?
            LibObjCBridge.objc_send_id(img_view, sel("setContentTintColor:"), tint_ptr)
          end

          # Constrain each star to 20x20pt (compact, matches NSLevelIndicator cells)
          LibObjCBridge.objc_constrain_width(img_view, 20.0)
          LibObjCBridge.objc_constrain_height(img_view, 20.0)

          LibObjCBridge.objc_send_void_id(stack, sel("addArrangedSubview:"), img_view)
        end

        # Accessibility: announce as "X out of Y stars"
        if acc = view.accessibility_label
          acc_str = LibObjCBridge.nsstring_from_cstr(acc.to_unsafe)
          LibObjCBridge.objc_send_id(stack, sel("setAccessibilityLabel:"), acc_str)
        else
          default_label = "#{filled_count} out of #{view.max} stars"
          lbl_str = LibObjCBridge.nsstring_from_cstr(default_label.to_unsafe)
          LibObjCBridge.objc_send_id(stack, sel("setAccessibilityLabel:"), lbl_str)
        end

        apply_common_properties(stack, view)
        emit(stack, "NSStackView[rating-indicator]")
      end

      # Phase 4 — Tier 3. UI::ActionSheet is iOS-only via flag?(:ios) in
      # src/ui/views/action_sheet.cr, so there is no AppKit visitor — the
      # class itself does not exist on -Dmacos. macOS applications use
      # UI::ActionSheetWithWebFallback (below), which synthesizes a
      # ConfirmationDialog and routes through the existing visitor.

      def visit(view : UI::ContextMenuWithWebFallback)
        # On macOS, the WithWebFallback's accept() delegates to its
        # inner UI::ContextMenu so this visitor is reachable only when
        # the fallback was constructed directly (extremely rare). Emit
        # a no-op NSView so the abstract method is satisfied.
        v = alloc_init("NSView")
        apply_common_properties(v, view)
        emit(v, "NSView[ContextMenuWithWebFallback-stub]")
      end

      def visit(view : UI::PathControlWithWebFallback)
        # On macOS the WithWebFallback delegates to its inner
        # UI::PathControl; this visitor is unreachable in practice.
        # Emit a no-op NSView for abstract-method coverage.
        v = alloc_init("NSView")
        apply_common_properties(v, view)
        emit(v, "NSView[PathControlWithWebFallback-stub]")
      end

      # Phase 6.10 — SwipeActionRow. macOS HIG explicitly does NOT have
      # swipe-to-reveal; the idiomatic equivalent is visible trailing
      # buttons (NSTableView row actions are the closest analog and they
      # too render as visible chrome on hover/select). We render an
      # NSStackView with content + trailing-action NSButtons inline.
      def visit(view : UI::SwipeActionRow)
        ptr = alloc_init("NSStackView")
        LibObjCBridge.objc_send_long(ptr, sel("setOrientation:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(ptr, sel("setSpacing:"), 8.0)

        outer_handle = ObjC.owned(ptr, label: "NSStackView[SwipeActionRow]")
        outer_native = NativeView.new(outer_handle)

        if content_native = render_detached(view.content)
          LibObjCBridge.objc_send_id(ptr, sel("addArrangedSubview:"), content_native.handle.ptr!)
          outer_native.add_child(content_native)
        end

        view.trailing_actions.each do |action|
          btn = alloc_init("NSButton")
          title_ns = LibObjCBridge.nsstring_from_cstr(action.label.to_unsafe)
          LibObjCBridge.objc_send_id(btn, sel("setTitle:"), title_ns)
          LibObjCBridge.objc_send_id(ptr, sel("addArrangedSubview:"), btn)
          btn_handle = ObjC.owned(btn, label: "NSButton[SwipeAction:#{action.label}]")
          outer_native.add_child(NativeView.new(btn_handle))
        end

        apply_common_properties(ptr, view)
        push_native(outer_native)
      end

      def visit(view : UI::ActionSheetWithWebFallback)
        # macOS lacks a native action-sheet idiom (HIG steers developers to
        # NSAlert / modal sheets). We synthesize a UI::ConfirmationDialog
        # from the first non-cancel + cancel pair and delegate to the
        # existing visitor so the macOS rendering matches the rest of the
        # ConfirmationDialog ecosystem. Multi-action fidelity is deferred
        # to Phase 5 (multi-action SwiftKit facade).
        primary = view.actions.find { |a| a.style != :cancel }
        cancel = view.actions.find { |a| a.style == :cancel }
        dialog = UI::ConfirmationDialog.new(view.title, view.message)
        dialog.is_presented = view.is_presented
        if primary
          dialog.confirm_label = primary.label
          dialog.confirm_style = primary.style == :destructive ? :destructive : :default
          dialog.on_confirm = primary.action
        end
        if cancel
          dialog.cancel_label = cancel.label
          dialog.on_cancel = cancel.action
        end
        visit(dialog)
      end

      # ================================================================
      # Private helpers
      # ================================================================

      # Allocate and init an ObjC class by name.
      # Returns the raw Void* pointer to the initialized object.
      private def alloc_init(class_name : String) : Void*
        cls = LibObjCBridge.objc_getClass(class_name.to_unsafe)
        obj = LibObjCBridge.objc_send(cls, sel("alloc"))
        LibObjCBridge.objc_send(obj, sel("init"))
      end

      # Allocate and init an ObjC class using initWithFrame:NSZeroRect.
      # Required for NSControl subclasses (NSSwitch, NSSlider, etc.) that
      # return nil or crash from plain -init.
      private def alloc_init_with_zero_frame(class_name : String) : Void*
        cls = LibObjCBridge.objc_getClass(class_name.to_unsafe)
        obj = LibObjCBridge.objc_send(cls, sel("alloc"))
        zero = LibObjCBridge::CGRect.new(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        LibObjCBridge.objc_send_rect(obj, sel("initWithFrame:"), zero)
      end

      # Get a SEL from a selector name string.
      private def sel(name : String) : Void*
        LibObjCBridge.sel_registerName(name.to_unsafe)
      end

      # Resolve a UI::Font to an NSFont pointer.
      #
      # Maps font family and weight to the appropriate NSFont factory:
      #   - "system"    -> systemFontOfSize: or boldSystemFontOfSize: or systemFontOfSize:weight:
      #   - "monospace" -> monospacedSystemFontOfSize:weight:
      #   - other       -> fontWithName:size: (custom font name lookup, falls back to system)
      private def resolve_font(font : UI::Font) : Void*
        weight = font_weight_value(font.weight)

        base_font = case font.family
                    when "system"
                      if font.weight == :bold
                        LibObjCBridge.nsfont_bold_system(font.size)
                      elsif font.weight == :regular
                        LibObjCBridge.nsfont_system(font.size)
                      else
                        LibObjCBridge.nsfont_system_weight(font.size, weight)
                      end
                    when "monospace"
                      LibObjCBridge.nsfont_monospaced_system(font.size, weight)
                    else
                      name_str = LibObjCBridge.nsstring_from_cstr(font.family.to_unsafe)
                      result = LibObjCBridge.nsfont_named(name_str, font.size)
                      # Fall back to system font if the named font was not found
                      if result.null?
                        LibObjCBridge.nsfont_system(font.size)
                      else
                        result
                      end
                    end

        # Apply italic trait via NSFontManager if needed.
        # convertFont:toHaveTrait: with NSItalicFontMask = 0x01
        if font.italic && !base_font.null?
          fm = LibObjCBridge.objc_send(
            LibObjCBridge.objc_getClass("NSFontManager"),
            sel("sharedFontManager"))
          unless fm.null?
            italic_font = LibObjCBridge.objc_send_id_long(
              fm, sel("convertFont:toHaveTrait:"), base_font, 0x01_i64)
            return italic_font unless italic_font.null?
          end
        end

        base_font
      end

      # Map a UI::Font weight symbol to an NSFontWeight CGFloat value.
      # NSFontWeight constants: ultraLight=-0.8, thin=-0.6, light=-0.4,
      # regular=0.0, medium=0.23, semibold=0.3, bold=0.4, heavy=0.56, black=0.62
      private def font_weight_value(weight : Symbol) : Float64
        case weight
        when :thin     then -0.6
        when :light    then -0.4
        when :regular  then 0.0
        when :medium   then 0.23
        when :semibold then 0.3
        when :bold     then 0.4
        else                0.0
        end
      end

      private def map_type_value(map_type : Symbol) : Int64
        case map_type
        when :satellite then 1_i64
        when :hybrid    then 2_i64
        else                 0_i64
        end
      end

      private def map_span_delta(zoom_level : Float64) : Float64
        zoom = zoom_level.clamp(1.0, 18.0)
        (360.0 / (2.0 ** zoom)).clamp(0.005, 120.0)
      end

      private def apply_default_surface_size(ptr : Void*, view : UI::View, default_width : Float64, default_height : Float64) : Nil
        return if ptr.null?

        unless view.minimum_width || view.maximum_width
          LibObjCBridge.objc_constrain_minimum_width(ptr, default_width)
        end

        unless view.minimum_height || view.maximum_height
          LibObjCBridge.objc_constrain_height(ptr, default_height)
        end
      end

      # Resolve a UI::Color to an NSColor pointer via the bridge convenience.
      private def resolve_color(color : UI::Color) : Void*
        LibObjCBridge.nscolor_rgba(color.r, color.g, color.b, color.a)
      end

      # The unified design-tokens model. Host apps can swap this with a
      # brand-overridden Tokens before render to cascade their identity into
      # every visit method that calls `token_nscolor` / `token_radius` /
      # `token_font_size`. Defaults to `UI::DesignTokens::Tokens.default`,
      # which mirrors the canonical Amber palette transcribed from the web
      # token bag.
      property design_tokens : UI::DesignTokens::Tokens = UI::DesignTokens::Tokens.default

      # Current appearance (light / dark) resolved from HIG_APPEARANCE — the
      # same env var the validation capture harness sets before launching the
      # host binary. Production apps should substitute their own runtime
      # check (e.g. NSAppearance.currentAppearance.name).
      private def current_appearance : Symbol
        (ENV["HIG_APPEARANCE"]? == "dark") ? :dark : :light
      end

      # Resolve a semantic brand color role to an NSColor pointer via the
      # active design tokens (Step 9 of the Phase 1 implementation plan).
      # `amber_brand_gold` previously hardcoded `#FFAD33` / `#FFB84D`; that
      # helper is gone — every caller now passes through here so a brand
      # override on `design_tokens` cascades through.
      #
      # Phase 6.12A — when the resolved colour is `Color::SYSTEM_ACCENT`
      # the bridge returns `NSColor.controlAccentColor` (the live macOS
      # system accent that follows the user's General > Accent choice and
      # the active appearance automatically), not the sentinel's zeroed
      # sRGB bake.
      private def token_nscolor(role : Symbol, appearance : Symbol = current_appearance) : Void*
        palette = appearance == :dark ? @design_tokens.colors_dark : @design_tokens.colors_light
        color = palette.lookup(role) || palette.brand_primary
        if color.system_accent?
          LibObjCBridge.nscolor_control_accent
        else
          LibObjCBridge.nscolor_rgba(color.r, color.g, color.b, color.alpha)
        end
      end

      # Deprecated shim: `amber_brand_gold` callers now resolve through the
      # token model. Retained as an alias to keep the call sites readable
      # while Step 9 mechanically migrates them; the function is private to
      # this file so it's not part of the public API.
      private def amber_brand_gold : Void*
        token_nscolor(:brand_primary)
      end

      # Token-driven NSFont (system) at the size pulled from the active
      # TypeScale, multiplied by 16 to convert rem → points.
      private def token_font(step : Symbol = :body) : Void*
        ts = @design_tokens.type.lookup(step) || @design_tokens.type.body
        LibObjCBridge.nsfont_system(ts.size * 16.0)
      end

      # Idempotently install the SwiftKit action trampoline and (re)apply
      # the brand-tint cascade from the active `design_tokens`. Called from
      # `render(...)` so every top-level render observes the current brand,
      # which is what makes `renderer.design_tokens = Tokens.default.with_brand(...)`
      # a hot swap.
      #
      # The brand-primary colour is read from the light palette — Apple's
      # `.tint()` accent cascade adapts contrast automatically across light
      # and dark via the dynamic colour the SwiftUI runtime derives from
      # the supplied sRGB triple, so we do not need to gate on
      # `HIG_APPEARANCE` here.
      private def ensure_swiftkit_runtime! : Nil
        unless @swiftkit_action_trampoline_installed
          LibSwiftKitBridge.apsk_runtime_install_default_action_trampoline
          @swiftkit_action_trampoline_installed = true
        end
        apply_brand_tint(@design_tokens.colors_light.brand_primary)
      end

      # Phase 6.12A — pure routing of a brand colour to the SwiftKit
      # runtime. The decision (`:clear` vs `:set`) lives on
      # `UI::DesignTokens::Color#brand_tint_action` so it is unit-
      # testable without linking the native bridge. This method is
      # the production dispatch that translates the decision into the
      # corresponding `LibSwiftKitBridge` C call.
      protected def apply_brand_tint(brand : UI::DesignTokens::Color) : Nil
        case brand.brand_tint_action
        when :clear
          LibSwiftKitBridge.apsk_runtime_clear_brand_tint
          # Phase 6.12C — Codex-requested assertion. Voyager (and any
          # consumer using `Tokens.default` SYSTEM_ACCENT) reaches this
          # branch, which is what keeps `APSKRuntime.brandTint == nil`
          # and routes `ButtonFacade case "prominent"` through the stock
          # `.borderedProminent` path instead of the new
          # `APSKBrandProminentButtonStyle`. The log line is opt-in via
          # the `APSK_BRAND_TINT_LOG` env var so it is silent in normal
          # use but available for verification.
          if ENV["APSK_BRAND_TINT_LOG"]?
            STDERR.puts "[apsk] brand_tint=cleared (APSKRuntime.brandTint == nil)"
          end
        when :set
          LibSwiftKitBridge.apsk_runtime_set_brand_tint(
            brand.r, brand.g, brand.b, brand.alpha,
          )
          if ENV["APSK_BRAND_TINT_LOG"]?
            STDERR.puts "[apsk] brand_tint=set r=#{brand.r} g=#{brand.g} b=#{brand.b}"
          end
        end
      end

      # Token-driven radius in points (rem * 16).
      private def token_radius(key : Symbol) : Float64
        (@design_tokens.radius.lookup(key) || @design_tokens.radius.md) * 16.0
      end

      # Resolve a Phase-5 Material step Symbol to its NSVisualEffectMaterial
      # integer constant for the direct-AppKit visit paths that bypass the
      # SwiftKit facade (NavigationSplitView legacy sidebar, ContextMenu,
      # ActivityView).
      #
      # Scope is intentionally narrow: only the step Symbols actually
      # consumed by those call sites are mapped here. Expanding this
      # table requires re-validating each new Symbol against Apple's
      # NSVisualEffectMaterial semantics; implementation.md L562 sketches
      # a UIKit-constant <-> AppKit-constant translation that this helper
      # does NOT implement (Phase 5 shipped the SwiftKit facade path
      # instead, so the integer translation table the doc envisioned was
      # never built).
      #
      # The portable Material steps (`:thin`, `:thick`) match the
      # cross-platform token scale. `:menu` is an **AppKit platform
      # surface semantic** — a renderer-private key for
      # `NSVisualEffectMaterialMenu` (no SwiftUI Material enum analogue).
      # `:menu` must NOT be advertised as part of the portable Material
      # token contract; it exists only so `UI::ContextMenu` can have its
      # HIG-correct native material while routing through the brand
      # cascade infrastructure.
      #
      # Unknown / unhandled Symbols fall through to `NSVisualEffectMaterialHeaderView`
      # (10), a safe modern default. Adding new Symbols requires:
      #   (a) verifying the Apple NSVisualEffectMaterial semantics,
      #   (b) updating the call site + comment to declare the choice.
      #
      # Per Phase 5 implementation.md (lines 226-237), this case/switch is
      # the ONE allowed hard-coded glass switch in the file and must carry
      # the exact marker comment on the line directly above. Phase 5
      # validation.md check #22 greps for that marker. Do not add this
      # marker anywhere else in the codebase.
      # Phase 5 v2 — renamed from `appkit_visual_effect_material(step : Symbol)`
      # to take the v2 `AppleSemantic` enum directly. Maps each semantic to
      # the matching `NSVisualEffectMaterial` integer.
      #
      # `SystemResolved` returns `0_i64` as a SENTINEL — the caller is
      # responsible for checking the result and skipping `setMaterial:` when
      # it's zero. Zero is not a valid NSVisualEffectMaterial (the smallest
      # valid is `NSVisualEffectMaterialTitlebar = 3`), so this is an
      # unambiguous "do not emit" signal. The two active call sites
      # (`visit(UI::ContextMenu)`, `visit(UI::ActivityView)`) and the inline
      # sidebar effect inside `visit(UI::NavigationSplitView)` always pass a
      # concrete non-SystemResolved semantic for their HIG-canonical
      # defaults, so the sentinel branch is reached only when a consumer
      # explicitly overrides to `:system_resolved`.
      private def appkit_visual_effect_material_for_semantic(semantic : UI::DesignTokens::AppleSemantic) : Int64
        # AppKit material translation table — only allowed hard-coded glass switch
        case semantic
        in .menu?              then  5_i64 # NSVisualEffectMaterialMenu
        in .popover?           then  6_i64 # NSVisualEffectMaterialPopover
        in .sidebar?           then  7_i64 # NSVisualEffectMaterialSidebar
        in .header_view?       then 10_i64 # NSVisualEffectMaterialHeaderView
        in .sheet?             then 11_i64 # NSVisualEffectMaterialSheet
        in .window_background? then 12_i64 # NSVisualEffectMaterialWindowBackground
        in .hud_window?        then 13_i64 # NSVisualEffectMaterialHUDWindow
        in .titlebar?          then  3_i64 # NSVisualEffectMaterialTitlebar
        in .system_resolved?   then  0_i64 # SENTINEL — caller must skip setMaterial:
        end
      end

      # Phase 5 v2 — legacy Symbol-shim. Preserves the pre-v2
      # `appkit_visual_effect_material(:foo)` callsite shape used by the
      # 6 `_legacy_*` methods (Phase 5.5 cleanup target). Maps the legacy
      # thickness-style symbols to the closest v2 AppleSemantic and
      # delegates. The active dispatch path uses the semantic helper
      # directly; this shim exists only so the legacy bodies still
      # compile until Phase 5.5 deletes them.
      private def appkit_visual_effect_material(step : Symbol) : Int64
        semantic = case step
                   when :thin  then UI::DesignTokens::AppleSemantic::Sidebar
                   when :thick then UI::DesignTokens::AppleSemantic::Sheet
                   when :menu  then UI::DesignTokens::AppleSemantic::Menu
                   else             UI::DesignTokens::AppleSemantic::HeaderView
                   end
        appkit_visual_effect_material_for_semantic(semantic)
      end

      # Apply common View base-class properties to a raw AppKit view pointer.
      #
      #   - hidden  -> setHidden:
      #   - opacity -> setAlphaValue:
      #   - background -> setWantsLayer: + layer.setBackgroundColor:
      #   - accessibility_label -> setAccessibilityLabel:
      #   - minimum_width / minimum_height -> NSLayoutConstraint (width/height >= x)
      #   - maximum_width / maximum_height -> NSLayoutConstraint (width/height <= x)
      private def apply_common_properties(ptr : Void*, view : UI::View) : Nil
        # Hidden
        if view.hidden
          LibObjCBridge.objc_send_bool(ptr, sel("setHidden:"), 1)
        end

        # Opacity
        if view.opacity < 1.0
          LibObjCBridge.objc_send_1d(ptr, sel("setAlphaValue:"), view.opacity)
        end

        # Background color requires enabling layer-backing first.
        # setWantsLayer:YES tells AppKit to create a CALayer, then we
        # set the layer's backgroundColor to the CGColor representation.
        if bg = view.background
          LibObjCBridge.objc_send_bool(ptr, sel("setWantsLayer:"), 1)
          layer = LibObjCBridge.objc_send(ptr, sel("layer"))
          unless layer.null?
            bg_nscolor = resolve_color(bg)
            cg_color = LibObjCBridge.objc_send(bg_nscolor, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setBackgroundColor:"), cg_color)
          end
        end

        # Size constraints via Auto Layout.
        # When minimum_width == maximum_width: exact-width pin via equality constraint
        #   (NSStackView GravityAreas respects this; used for sidebar columns).
        # When only minimum_width is set: minimum-width constraint (>=) at priority 500
        #   so content panels expand to at least that width without fighting exact pins.
        # When only maximum_width is set: exact pin at that width (capping behavior).
        if min_w = view.minimum_width
          if max_w = view.maximum_width
            # Both set: exact pin at min_w (== max_w for fixed-width columns).
            LibObjCBridge.objc_constrain_width(ptr, min_w)
          else
            # Only minimum: use >= constraint at priority 500 so panel fills space.
            LibObjCBridge.objc_constrain_minimum_width(ptr, min_w)
          end
        elsif max_w = view.maximum_width
          LibObjCBridge.objc_constrain_width(ptr, max_w)
        end

        if min_h = view.minimum_height
          LibObjCBridge.objc_constrain_height(ptr, min_h)
        end

        # Phase 6.10 Rem 4 (Item 2D) — root_fill sizes to the live
        # macOS window. The author opts a root view in via
        # `view.root_fill = true`. macOS has no safe-area concept so
        # the full screen width is used; the host window honors the
        # constraint by setting the contentView to match.
        if view.root_fill && view.minimum_width.nil? && view.maximum_width.nil?
          metrics = UI::DesignTokens::DeviceMetrics.current
          fill_width = metrics.content_width_pt
          if fill_width > 0.0
            LibObjCBridge.objc_constrain_width(ptr, fill_width)
          end
        end

        # Accessibility label
        #
        # IMPORTANT (Phase 6.10 Rem 1): On AppKit's NSAccessibility
        # protocol, an NSView with a non-nil `accessibilityLabel` is
        # exposed to VoiceOver as an opaque AX element by default. For
        # containers (VStack / HStack / ZStack / ScrollView / etc.) we
        # explicitly mark them as NOT accessibility elements so their
        # descendants stay individually navigable. The label still
        # surfaces via NSAccessibility's container query, but the
        # element-with-label collapse that masks leaves on iOS is also
        # a risk on macOS — explicit clamp removes ambiguity.
        is_container = view.is_a?(UI::VStack) || view.is_a?(UI::HStack) ||
                       view.is_a?(UI::ZStack) || view.is_a?(UI::ScrollView) ||
                       view.is_a?(UI::NavigationStack) || view.is_a?(UI::NavigationLink) ||
                       view.is_a?(UI::Form) || view.is_a?(UI::Grid) ||
                       view.is_a?(UI::Card) || view.is_a?(UI::Surface)
        if a11y = view.accessibility_label
          a11y_str = LibObjCBridge.nsstring_from_cstr(a11y.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), a11y_str)
          if is_container
            LibObjCBridge.objc_send_bool(ptr, sel("setAccessibilityElement:"), 0)
          end
        elsif is_container
          LibObjCBridge.objc_send_bool(ptr, sel("setAccessibilityElement:"), 0)
        end

        # Test identifier -> accessibilityIdentifier for automated UI testing
        if tid = view.test_id
          tid_str = LibObjCBridge.nsstring_from_cstr(tid.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityIdentifier:"), tid_str)
        end
      end

      # Push a container NativeView onto the nesting stack.
      private def push_stack(native : NativeView, is_nsstack : Bool) : Nil
        @stack.push(native)
        @stack_is_nsstack.push(is_nsstack)
      end

      # Pop the top container from the nesting stack.
      private def pop_stack : Nil
        @stack.pop
        @stack_is_nsstack.pop
      end

      # Build a contiguous `Void*` buffer of native-view pointers from a
      # list of detached `NativeView`s. Returns a pointer suitable for
      # passing to a `LibSwiftKitBridge.apsk_make_*` facade as its
      # `child_views` arg. When `natives` is empty the buffer is a
      # 1-element pad pointer (the facade reads zero entries because
      # `child_count == 0`).
      private def build_child_buffer(natives : Array(NativeView)) : Pointer(Void*)
        size = natives.size == 0 ? 1_u64 : natives.size.to_u64
        buf = Pointer(Void*).malloc(size)
        natives.each_with_index { |nv, i| buf[i] = nv.handle.ptr! }
        buf
      end

      # Visit a child view subtree in isolation, returning its NativeView
      # without adding it to the current parent stack.  Used by NSScrollView
      # to obtain the documentView NativeView pointer before wiring it with
      # setDocumentView:, avoiding the double-placement that occurs when both
      # addSubview: (via push_native) and setDocumentView: target the same view.
      private def render_detached(view : UI::View) : NativeView?
        saved_stack = @stack.dup
        saved_is_nsstack = @stack_is_nsstack.dup
        saved_result = @result
        @stack = [] of NativeView
        @stack_is_nsstack = [] of Bool
        @result = nil
        view.accept(self)
        detached = @result
        @stack = saved_stack
        @stack_is_nsstack = saved_is_nsstack
        @result = saved_result
        detached
      end

      # Wrap a raw pointer in NativeHandle + NativeView and register it
      # with the current parent or set as root result.
      #
      # This is the standard emit path for leaf views (Label, Image, Spacer)
      # that do not need custom callback registration.
      private def emit(ptr : Void*, label : String) : Nil
        handle = ObjC.owned(ptr, label: label)
        native = NativeView.new(handle)
        push_native(native)
      end

      # Register a NativeView with the current parent container, or set it
      # as the root result if there is no parent.
      #
      # When inside a container (VStack/HStack/ZStack/ScrollView), this:
      #   1. Adds the NativeView as a child of the parent NativeView tree
      #   2. Adds the native AppKit view to the parent:
      #      - NSStackView parents use addArrangedSubview: (preserves stack ordering)
      #      - Plain NSView parents use addSubview: (ZStack, ScrollView content)
      private def push_native(native : NativeView) : Nil
        if parent = @stack.last?
          parent.add_child(native)

          # Add native AppKit view to parent's native view
          if parent.handle.valid? && native.handle.valid?
            parent_ptr = parent.handle.ptr!
            child_ptr = native.handle.ptr!

            # Use the parallel tracking array to decide add method
            if @stack_is_nsstack.last?
              LibObjCBridge.objc_send_void_id(parent_ptr, sel("addArrangedSubview:"), child_ptr)
            else
              LibObjCBridge.objc_add_subview(parent_ptr, child_ptr)
            end
          end
        else
          @result = native
        end
      end

      # Collect raw Void* pointers for editable text fields in tree order.
      # Excludes NSTextField[label] (non-editable labels) by checking handle label.
      private def collect_text_fields(nv : NativeView, result_fields : Array(Void*)) : Nil
        if nv.handle.valid?
          lbl = nv.handle.label
          if lbl == "NSTextField" || lbl == "NSSecureTextField"
            result_fields << nv.handle.ptr!
          end
        end
        nv.children.each { |child| collect_text_fields(child, result_fields) }
      end
    end
  end
{% end %}
