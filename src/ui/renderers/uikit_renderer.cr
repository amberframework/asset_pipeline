# iOS / UIKit platform renderer. Walks a UI::View tree and produces a native
# UIView hierarchy (UIStackView, UIButton, UILabel, UIVisualEffectView, ...).

{% if flag?(:ios) %}
  require "base64"
  require "../platform_visitor"
  require "../native/native_handle"
  require "../native/native_view"
  require "../native/callback_registry"
  require "../native/swiftkit_bridge"
  require "../native/swiftkit_overrides"
  require "../design_tokens"

  module UI::UIKit
    # ObjC bridge function bindings for UIKit rendering on iOS.
    #
    # UIKit shares the same ARM64 ObjC runtime as AppKit -- the same C bridge
    # functions (objc_bridge.c) work on iOS. The difference is the class names
    # and selector names passed to those functions (UILabel vs NSTextField, etc.).
    #
    # ## Struct types
    #
    # CGRect/CGPoint/CGSize are Homogeneous Floating-point Aggregates (HFA)
    # on ARM64. They are passed/returned in d0-d3 (CGRect), d0-d1 (CGPoint,
    # CGSize), NOT on the stack.
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
      fun objc_send_id_id_long(obj : Void*, sel : Void*, arg1 : Void*, arg2 : Void*, arg3 : Int64) : Void*

      # --- Section 2: Double/float register sends ---
      fun objc_send_1d(obj : Void*, sel : Void*, d0 : Float64) : Void
      fun objc_send_1d_ret_id(obj : Void*, sel : Void*, d0 : Float64) : Void*
      fun objc_send_2d_ret_id(obj : Void*, sel : Void*, d0 : Float64, d1 : Float64) : Void*
      fun objc_send_4d_ret_id(obj : Void*, sel : Void*, d0 : Float64, d1 : Float64, d2 : Float64, d3 : Float64) : Void*

      # --- Section 3: CGRect / HFA sends ---
      fun objc_send_rect(obj : Void*, sel : Void*, rect : CGRect) : Void*
      fun objc_send_rect_void(obj : Void*, sel : Void*, rect : CGRect) : Void
      fun objc_send_ret_bool(obj : Void*, sel : Void*) : Int32
      # Phase 10B.2a iter 2 (Codex Finding 3) — guarded setEnabled: helper
      # used to functionally disable UIControl-derived widgets when the
      # `:not_enabled` accessibility trait is set. No-ops on plain UIViews.
      fun ap_set_enabled_if_responds(obj : Void*, enabled : Int32) : Int32

      # Phase 10B.2b — Action + focus + keyboard accessibility helpers.
      # Add a custom accessibility action (block-based, iOS 13+).
      fun ap_view_add_accessibility_custom_action(view : Void*, name : UInt8*,
                                                  token : UInt64) : Int32
      # Add a UIKeyCommand to a UIViewController (or buffer on an associated
      # object for plain UIViews).
      fun ap_view_add_key_command(view : Void*, input : UInt8*,
                                  modifier_mask : UInt64, token : UInt64) : Int32
      # Focus management.
      fun ap_view_become_first_responder(view : Void*) : Bool
      fun ap_view_resign_first_responder(view : Void*) : Int32
      # ComboBox value-drop fix — wire a raw UITextField's editing events
      # (EditingChanged | EditingDidEnd) to the Crystal string callback
      # `token`, routing the field text via crystal_ui_string_callback_dispatch.
      fun ap_text_field_wire_string_change(field : Void*, token : UInt64) : Int32

      # --- Section 4: Convenience helpers ---
      fun nsstring_from_cstr(str : UInt8*) : Void*
      fun nscolor_rgba(r : Float64, g : Float64, b : Float64, a : Float64) : Void*
      fun nscolor_white_alpha(white : Float64, alpha : Float64) : Void*
      fun nscolor_label_primary : Void*
      fun nscolor_label_secondary : Void*
      fun nscolor_label_tertiary : Void*
      fun nscolor_label_quaternary : Void*
      # Phase 6.12A — UIColor.tintColor (class accessor; iOS 15+). Returned
      # by the bridge when the renderer resolves a `Color::SYSTEM_ACCENT`
      # sentinel via `token_nscolor`.
      fun uicolor_tint : Void*
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
      fun objc_constrain_required_width(view : Void*, w : Float64) : Void
      fun objc_constrain_height(view : Void*, h : Float64) : Void
      fun objc_constrain_minimum_height(view : Void*, min_h : Float64) : Void
      fun objc_constrain_minimum_width(view : Void*, min_w : Float64) : Void
      fun objc_constrain_maximum_width(view : Void*, max_w : Float64) : Void
      fun objc_constrain_fluid_width(view : Void*, min_w : Float64, max_w : Float64) : Void
      fun objc_constrain_equal_width(child : Void*, parent : Void*) : Void
      fun objc_constrain_equal_width_offset(child : Void*, parent : Void*, delta : Float64) : Void
      fun objc_pin_child_to_layout_margins(parent : Void*, child : Void*) : Void
      # Phase 10D-refocus — pin a child view to its parent's bounds
      # (no insets). Used by FullScreenCover + Inspector visit paths
      # where the parent is a bare UIView/NSView wrapper and the child
      # needs to fill the parent edge-to-edge.
      fun objc_pin_child_to_superview_edges(parent : Void*, child : Void*) : Void
      # ZStack directional-alignment child pin (Leading/Trailing/Top/Bottom).
      # Mirrors the appkit path: pins the aligned edge + cross-axis edges, soft-fills
      # the opposite edge (priority 499) so an unconstrained child fills while a
      # fixed-size child keeps its size and aligns. align: 0=leading 1=trailing 2=top 3=bottom.
      fun objc_pin_child_aligned(parent : Void*, child : Void*, align : Int32) : Void
      fun objc_set_horizontal_fixed_priority(view : Void*) : Void
      fun objc_set_horizontal_fill_priority(view : Void*) : Void
      # Spacer flex priority: drop content-hugging to 1 on BOTH axes so a Spacer
      # reliably absorbs all slack in a VStack or HStack (beats content's 250).
      fun objc_set_flex_spacer_priority(view : Void*) : Void
      fun uiscrollview_pin_content(scroll_view : Void*, content_view : Void*) : Void
      # Phase 6.11 — swipe-reveal row factory. Builds a horizontal-scroll
      # UIScrollView with [content | action₁ | action₂ ...] children where
      # only `content` is visible initially; user pans left to reveal the
      # actions. See `make_swipe_reveal_row` in objc_bridge.m.
      fun make_swipe_reveal_row(content_view : Void*, action_views : Void**, action_count : Int32, row_width : Float64) : Void*
      fun objc_screen_width : Float64
      fun objc_screen_height : Float64
      fun objc_macos_screen_width : Float64
      fun objc_safe_area_top : Float64
      fun objc_safe_area_bottom : Float64
      fun objc_safe_area_leading : Float64
      fun objc_safe_area_trailing : Float64
      fun objc_horizontal_size_class : Int32
      fun objc_vertical_size_class : Int32
      fun uislider_build_synthetic_track(value_fraction : Float64, filled_color : Void*, unfilled_color : Void*, slider_ptr : Void*) : Void*
      fun nsimageview_make_symbol(symbol_name : UInt8*, tint_color : Void*, size_pts : Float64) : Void*
      fun uiview_install_amber_gradient_layer(view : Void*) : Void
      fun wkwebview_new(url : UInt8*, html : UInt8*, base_url : UInt8*, title : UInt8*, allows_navigation : Int32, allows_scripts : Int32) : Void*
      fun wkwebview_set_callback_tags(web_view : Void*, policy_tag : UInt64, start_tag : UInt64, finish_tag : UInt64, allows_navigation : Int32) : Void
      fun mkmapview_new(latitude : Float64, longitude : Float64, latitude_delta : Float64, longitude_delta : Float64, map_type : Int64, shows_user_location : Int32) : Void*
      fun mkmapview_add_annotation(map_view : Void*, latitude : Float64, longitude : Float64, title : UInt8*, subtitle : UInt8*) : Void
      fun video_player_view_new(url : UInt8*, shows_controls : Int32, auto_play : Int32, muted : Int32, loop : Int32) : Void*
      fun ap_ring_view_new(width : Float64, height : Float64, center_x : Float64, center_y : Float64, radius : Float64, track_start_angle : Float64, track_end_angle : Float64, progress_start_angle : Float64, progress_end_angle : Float64, line_width : Float64, track_r : Float64, track_g : Float64, track_b : Float64, track_a : Float64, progress_r : Float64, progress_g : Float64, progress_b : Float64, progress_a : Float64) : Void*
      fun ap_activity_rings_view_new(size : Float64, thickness : Float64, gap : Float64, move_progress : Float64, exercise_progress : Float64, stand_progress : Float64) : Void*
      fun ap_path_view_new(width : Float64, height : Float64, seg_data : Float64*, seg_count : Int32, has_fill : Int32, fr : Float64, fg : Float64, fb : Float64, fa : Float64, sr : Float64, sg : Float64, sb : Float64, sa : Float64, line_width : Float64) : Void*
      fun ap_canvas_view_new(width : Float64, height : Float64, op_data : Float64*, op_count : Int32) : Void*
      fun uiactivityview_present(anchor_view : Void*, text : UInt8*, url : UInt8*, subject : UInt8*) : Void

      # --- ObjC runtime ---
      fun sel_registerName(name : UInt8*) : Void*
      fun objc_getClass(name : UInt8*) : Void*

      # --- Section 6: Discrete gesture surface ---
      # Attach a UISwipeGestureRecognizer for `direction` (Left=0, Right=1,
      # Up=2, Down=3). `token` is the CallbackRegistry id dispatched on
      # recognition. Returns 1 on success.
      fun objc_attach_swipe_gesture(view : Void*, direction : Int32, token : UInt64) : Int32
      # Attach a UILongPressGestureRecognizer. `min_duration` is the hold
      # threshold in seconds (0.5 recommended). cancelsTouchesInView = NO
      # so child button taps are not swallowed by an adjacent long-press.
      # Returns 1 on success.
      fun objc_attach_long_press_gesture(view : Void*, token : UInt64, min_duration : Float64) : Int32
    end

    # Renders a UI::View tree to native UIKit views via the ObjC bridge.
    #
    # Each `visit` method:
    #   1. Allocates and initializes the appropriate UIKit view class
    #   2. Configures its properties (text, font, color, etc.)
    #   3. Wraps the raw pointer in a `NativeHandle` (owned)
    #   4. Creates a `NativeView` node
    #   5. If inside a container, adds as arranged subview or addSubview:
    #   6. If top-level, sets as `@result`
    #
    # ## UIKit vs AppKit differences
    #
    # - Labels use UILabel (not NSTextField). UILabel has setText:/setFont:/setTextColor:
    #   directly rather than requiring a non-editable NSTextField.
    # - Buttons use UIButton (buttonWithType: UIButtonTypeSystem=1).
    #   UIButton uses addTarget:action:forControlEvents: for callbacks.
    # - Stacks use UIStackView (same axis/alignment semantics, different constants).
    # - ZStack uses UIView with addSubview:. Children fill parent via autoresizing.
    # - Images use UIImageView with UIImage(named:) and contentMode.
    # - TextFields use UITextField (placeholder, secureTextEntry, keyboardType).
    # - ScrollView uses UIScrollView.
    # - Spacer uses UIView with low content hugging priority.
    # - Toggle uses UISwitch.
    # - Checkbox uses UIButton toggled as a checkmark (no native UICheckbox on iOS).
    # - RadioGroup uses a UIStackView of UIButtons acting as radio options.
    # - Slider uses UISlider (minimumValue, maximumValue, value).
    #
    # ## Usage
    #
    # ```
    # label = UI::Label.new("Hello, iOS!")
    # renderer = UI::UIKit::Renderer.new
    # label.accept(renderer)
    # native_view = renderer.result # => NativeView wrapping a UILabel
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

      # Tracks which NativeViews on the stack are UIStackViews (true) vs
      # plain UIViews (false). UIStackView uses addArrangedSubview:, plain
      # UIView uses addSubview:.
      @stack_is_uistack : Array(Bool)

      # Scoped preferred UILabel wrapping widths inherited from exact-width
      # containers. This keeps multi-line labels from reporting their single-line
      # intrinsic width during UIKit fitting passes.
      @label_preferred_max_layout_width_stack : Array(Float64)

      # Latches once `apsk_runtime_initialize` has handed the Crystal
      # action trampoline pointer to AssetPipelineSwiftKit's `APSKRuntime`.
      # Process-wide install, but kept per-renderer so the spec lifecycle
      # of multi-renderer test runs is easier to reason about.
      @swiftkit_action_trampoline_installed : Bool = false

      # Phase 10B.2c iter 2 — environment-driven render reactivity.
      # Hosts set this via `renderer.environment = UI::Environment.from_uikit(...)`
      # at boot or per-frame; default is the conservative baseline.
      # iOS-native snackbars are static UILabel overlays — the dismiss
      # timer is owned by host code. Threading the environment lets
      # host code read `view.effective_duration(@environment)` when
      # scheduling its own dismiss.
      property environment : UI::Environment = UI::Environment.default

      # Phase 10D-polish iter 2 (B-POPOVER-ANCHOR-VIEW) — registry of
      # test_id → ObjC view pointer populated as each view is built.
      # The Popover visit looks the source view up by its
      # `anchor_view_id` and passes the pointer to the SwiftKit facade
      # for `UIPopoverPresentationController` anchoring.
      @test_id_registry : Hash(String, Void*) = {} of String => Void*

      # Phase 12.C iter-4 (V1 fix Option A) — when the bridge passes a
      # reuse registry, the renderer's visit methods for reactive
      # presentations (Sheet, ConfirmationDialog, ActionSheet) check
      # for a matching identity. On hit, they return the EXISTING
      # NativeView verbatim instead of allocating a fresh
      # UIHostingView + APSKSheetState. This preserves the SwiftUI
      # .sheet modifier's presentation across Voyager rerenders —
      # without it, the .id() bump in ContentView.swift forces the
      # parent UIView to be discarded, unmounting the SheetHost and
      # causing the V1 auto-dismiss.
      @reuse_registry : Hash(String, NativeView)?

      # Phase 12.D (continuing-presentation reuse) — the prior render's
      # root, captured when the host constructs the renderer with
      # `reuse_from:`. Retained so `retire_prior!` can detach the reused
      # subtree from it + run the orphan dismissal sweep AFTER the fresh
      # render completes, without the host having to thread the prior
      # root through a second call. Nil for the Voyager hosts (which
      # still pass a pre-built `reuse_registry:` and drive detach/sweep
      # themselves) and on first render.
      @reuse_prior : NativeView?

      # Phase 12.D — plain-host ergonomic entry point. `reuse_from:`
      # accepts the PRIOR render's root NativeView and internally builds
      # the identity-keyed reuse registry (via
      # `NativeView.build_reuse_registry`). A plain host (happy_coach's
      # `render_current`, not just the Voyager sample bridge) adopts
      # continuing-presentation survival with a single construction +
      # one `retire_prior!` after swap — no hand-rolled registry/detach/
      # sweep ceremony. `reuse_registry:` remains for the Voyager hosts
      # that already build the registry themselves; passing both is a
      # caller error (reuse_from wins, the explicit registry is ignored).
      def initialize(reuse_registry : Hash(String, NativeView)? = nil, *, reuse_from : NativeView? = nil)
        @stack = [] of NativeView
        @stack_is_uistack = [] of Bool
        @label_preferred_max_layout_width_stack = [] of Float64
        @test_id_registry = {} of String => Void*
        @reuse_prior = reuse_from
        @reuse_registry = reuse_from ? NativeView.build_reuse_registry(reuse_from) : reuse_registry

        # Phase 6.10 Rem 4 (Item 2B/2C) — install the runtime device-
        # metrics provider so screens can query `UI::DesignTokens::
        # DeviceMetrics.current` for the live screen bounds, safe-area
        # insets, and size class. The block is captured by reference so
        # every call gets a fresh snapshot — critical on orientation
        # change / multitasking resize.
        UI::DesignTokens::Device.install_provider do
          UI::DesignTokens::DeviceMetrics.new(
            screen_width_pt: LibObjCBridge.objc_screen_width,
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

      # Maps the C enum result (0/1/2) from `objc_horizontal_size_class`
      # / `objc_vertical_size_class` into the Crystal `SizeClass` enum.
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
        # tint before traversing the tree. Mirrors the AppKit renderer's
        # cascade contract — see appkit_renderer.cr#render for the design
        # context.
        ensure_swiftkit_runtime!
        view.accept(self)
        result
      end

      # Phase 12.C iter-4 (V1 fix Option A) / Phase 12.D — check the
      # reuse registry for a presentation with the given identity + kind.
      # Returns the existing NativeView (with `reused = true` flagged)
      # when there's a hit; nil otherwise. Called from each reactive-
      # presentation visit method before allocating a fresh
      # UIHostingView.
      #
      # Phase 12.D — STATE-HANDLE ADOPTION. The `view` is the FRESH
      # tree's reactive-presentation View (e.g. the new `UI::Sheet`
      # instance the screen just rebuilt). On a reuse hit we copy the
      # surviving handle's `state_handle` onto it so subsequent
      # `is_presented=` / `dismiss!` calls on the NEW view drive the
      # SAME SwiftUI binding the prior render mounted. Without this the
      # new view's `@swiftkit_state_handle` stays nil and a controller
      # that closes the sheet on the post-rerender instance silently
      # no-ops (the bug this phase fixes). The marker makes the reuse
      # decision observable in the interaction-contracts harness.
      private def try_reuse(view : UI::View, identity : String?, kind : Symbol) : NativeView?
        return nil if identity.nil?
        registry = @reuse_registry
        return nil if registry.nil?
        existing = registry[identity]?
        return nil if existing.nil?
        return nil if existing.state.torn_down?
        return nil if existing.handle.released?
        return nil unless existing.handle.reactive_kind == kind
        state = existing.handle.state_handle
        return nil if state.nil?
        existing.reused = true
        view.swiftkit_state_handle = state
        {% if flag?(:macos) || flag?(:ios) %}
          UI::InteractionContracts.emit_for(
            "Sheet",
            "continuing-presentation-reused",
            identity,
            kind: kind.to_s,
            content: "prior-shell-retained",
          )
        {% end %}
        existing
      end

      # Phase 12.D — plain-host retirement helper. A host that built the
      # renderer with `reuse_from:` calls this AFTER `render` and AFTER
      # it has swapped in the fresh root. It (1) detaches the reused
      # NativeViews from the prior tree so its teardown/GC pass doesn't
      # double-release the shared NativeHandle, then (2) runs the
      # identity-aware orphan sweep so a presentation whose identity
      # vanished from the fresh tree flips its SwiftUI binding to false
      # (cause=binding-dismiss, not tree-removal) — preserving the
      # existing `dismiss_reactive_presentations!` behaviour for
      # orphaned sheets. No-op when constructed without `reuse_from:`.
      # `fresh` is the root this renderer just produced.
      def retire_prior!(fresh : NativeView) : Nil
        prior = @reuse_prior
        return if prior.nil?
        prior.detach_reused!
        NativeView.dismiss_reactive_presentations!(prior, fresh: fresh)
        nil
      end

      # Phase 12.C — cross-render reactive-presentation sweep
      # delegate. The canonical implementation is
      # `UI::NativeView.dismiss_reactive_presentations!(prior, fresh)`.
      # This shim forwards both args so identity-aware skipping
      # (Codex iter-1 BLOCKER 2) works for callers that still reach
      # for the renderer class method. New callers should prefer the
      # NativeView class method directly — it is platform-agnostic.
      def self.dismiss_reactive_presentations!(prior : NativeView?, fresh : NativeView? = nil) : Nil
        NativeView.dismiss_reactive_presentations!(prior, fresh: fresh)
      end

      # -----------------------------------------------------------------
      # Visit: Label -> UILabel
      # -----------------------------------------------------------------
      # Visit: Label -> SwiftUI Text hosted in UIHostingController.
      # See Button visit comment for the Phase 3 migration rationale.
      def visit(view : UI::Label)
        overrides_ptr = LibSwiftKitBridge.apsk_label_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_label(target_str, view, sender)

        # Reactive path: state pointer is written back through out_state.
        state_slot = Pointer(Void).null.as(Void*)
        state_box = pointerof(state_slot)
        # Pin `text` into a local before reaching for `to_unsafe` so the
        # Crystal GC keeps the String body alive across the FFI call.
        text = view.text
        ptr = LibSwiftKitBridge.apsk_make_label_reactive(
          text.to_unsafe, overrides_ptr, state_box,
        )

        LibObjCBridge.objc_send_bool(ptr, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
        handle = ObjC.owned(ptr, label: "UIHostingController[Label]")
        unless state_slot.null?
          handle.state_handle = state_slot
          view.swiftkit_state_handle = state_slot
        end
        native = NativeView.new(handle)
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Button -> SwiftUI Button hosted in UIHostingController
      #
      # Phase 3a migration (Option B — SwiftUI Default Supremacy):
      #
      # The renderer no longer constructs a UIButton with per-widget brand
      # colour injection (amber-gold base, plum-for-destructive, dark-mode
      # tint contrast pass, role × style matrix). Instead it routes
      # through AssetPipelineSwiftKit's `APSKButtonFacade`, which emits a
      # raw SwiftUI `Button(role:action:)` and inherits brand identity via
      # the `.tint()` cascade installed by `apsk_runtime_set_brand_tint`
      # (see `render(...)` / `ensure_swiftkit_runtime!`).
      #
      # Default behaviour is now whatever SwiftUI gives us:
      #   - System tint (resolved to `brand_primary` via the tint cascade)
      #   - System body font + Dynamic Type
      #   - Built-in hover / press / focus animations
      #   - VoiceOver `.button` trait + automatic dark-mode tracking
      #   - Liquid Glass treatment for `.borderedProminent` on iOS 26+
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
      # UIButton implementation this replaces.
      # -----------------------------------------------------------------
      def visit(view : UI::Button)
        # 1. Allocate a fresh APSKButtonOverrides instance and populate it
        #    via the Sender contract. The String target identifier is a
        #    debug aid; the production sender closes over the pointer.
        overrides_ptr = LibSwiftKitBridge.apsk_button_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_button(target_str, view, sender)

        # 2. Register the tap handler. Token 0 means "no callback wired."
        action_token = 0_u64
        if tap_handler = view.on_tap
          action_token = UI::CallbackRegistry.register_action(&tap_handler)
        end

        # 3. Build the SwiftUI Button and hand the underlying UIView back.
        #    Use the reactive entry so Crystal-side property mutations on
        #    UI::Button (background, foreground_color, corner_radius) flow
        #    through to a SwiftUI re-render via APSKButtonState.
        state_slot = Pointer(Void).null.as(Void*)
        state_box = pointerof(state_slot)
        # See `visit(UI::Label)` for the local-pin rationale.
        button_label = view.label
        ptr = LibSwiftKitBridge.apsk_make_button_reactive(
          button_label.to_unsafe, overrides_ptr, action_token, state_box,
        )

        # 4. Wrap and track. The UIHostingController is associated with the
        #    UIView via objc_setAssociatedObject inside HostingHelpers.host,
        #    so the controller's lifetime tracks the view's.
        handle = ObjC.owned(ptr, label: "UIHostingController[Button]")
        unless state_slot.null?
          handle.state_handle = state_slot
          view.swiftkit_state_handle = state_slot
        end

        # 5. Force UIKit-side minimum_height / minimum_width constraints
        #    on the UIHostingController.view. SwiftUI's `.frame(minHeight:)`
        #    only constrains the layout proposal; UIHostingController's
        #    intrinsicContentSize keeps reporting the Button's natural
        #    25.125pt body-text height and the parent UIStackView sizes
        #    the host at that natural height — failing the BX9 / BX6 44pt
        #    touch-target rubric. A UIKit Auto Layout >= constraint at the
        #    host-view level pins the floor unambiguously.
        if mh = view.minimum_height
          LibObjCBridge.objc_constrain_minimum_height(ptr, mh)
        end
        if mw = view.minimum_width
          LibObjCBridge.objc_constrain_minimum_width(ptr, mw)
        end

        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: VStack -> UIStackView (vertical)
      # -----------------------------------------------------------------
      def visit(view : UI::VStack)
        ptr = alloc_init("UIStackView")

        # UILayoutConstraintAxisVertical = 1
        LibObjCBridge.objc_send_long(ptr, sel("setAxis:"), 1_i64)

        # Spacing
        LibObjCBridge.objc_send_1d(ptr, sel("setSpacing:"), view.spacing)

        # UIStackView alignment for vertical axis:
        # UIStackViewAlignmentLeading=1, UIStackViewAlignmentCenter=3,
        # UIStackViewAlignmentTrailing=4, UIStackViewAlignmentFill=0
        #
        # Default is Fill (0) rather than Center (3): a vertical UIStackView
        # should stretch its children to the full container width by default
        # on iOS. Centering collapses children that have no intrinsic width
        # (e.g. nested UIStackViews), breaking HStack rows inside ListViews.
        alignment_val = case view.alignment
                        when Alignment::Leading  then 1_i64
                        when Alignment::Center   then 3_i64
                        when Alignment::Trailing then 4_i64
                        when Alignment::Fill     then 0_i64
                        else                          0_i64 # Fill by default
                        end
        LibObjCBridge.objc_send_long(ptr, sel("setAlignment:"), alignment_val)

        # Common properties
        apply_common_properties(ptr, view)
        apply_stack_padding(ptr, view)

        handle = ObjC.owned(ptr, label: "UIStackView[v]")
        native = NativeView.new(handle)

        # Push onto stack, visit children, pop
        push_stack(native, is_uistack: true)
        view.children.each do |child|
          child.accept(self)
        end
        pop_stack

        # Phase B — a fluid container fills its leaf children. UIStackView fill
        # alignment doesn't stretch facade-hosted controls (UIHostingController
        # hugs intrinsic width), so a fluid container's controls would render at
        # intrinsic width. Pin each child's width == the stack so they fill the
        # resizable column, unless the child has its own width intent.
        if view.fluid_width
          view.children.each_with_index do |child_view, i|
            next if child_view.minimum_width || child_view.maximum_width || child_view.fluid_width
            cn = native.children[i]?
            next unless cn && cn.handle.valid?
            LibObjCBridge.objc_constrain_equal_width(cn.handle.ptr!, ptr)
          end
        end

        # A VStack child marked `fill_horizontal` fills the stack's WIDTH — the
        # cross-axis analog of the HStack spacer-fill (appkit parity, mirrors
        # 34fb2b9f). Plain fill_horizontal only lowers content-hugging, which is
        # a NO-OP on the cross axis under a non-Fill UIStackView alignment
        # (Center/Leading/Trailing size each arranged subview to its intrinsic
        # width) — so a full-width band collapsed to its content width (e.g. a
        # left-aligned section title inside a Center-aligned sheet column
        # rendered centered at text width). Pin width == stack at required
        # priority. A child's own exact width pin still wins; skip when
        # fluid_width already pinned every child above.
        unless view.fluid_width
          # Respect the stack's own horizontal padding (layoutMargins +
          # isLayoutMarginsRelativeArrangement) so a padded screen container
          # gives its fill_horizontal children gutters instead of bleeding them
          # edge-to-edge. delta = -(leading + trailing); a non-Fill alignment
          # then positions the narrower child inside the margins.
          h_pad = view.padding.leading + view.padding.trailing
          view.children.each_with_index do |child_view, i|
            next unless child_view.fill_horizontal
            next if child_view.minimum_width || child_view.maximum_width
            cn = native.children[i]?
            next unless cn && cn.handle.valid?
            if h_pad > 0.0
              LibObjCBridge.objc_constrain_equal_width_offset(cn.handle.ptr!, ptr, -h_pad)
            else
              LibObjCBridge.objc_constrain_equal_width(cn.handle.ptr!, ptr)
            end
          end
        end

        push_native(native)

        # Phase B — fluid container fills its parent (capped at max, floored at
        # min) so the column reflows. Must run AFTER push_native (superview set on
        # add). See objc_constrain_fluid_width.
        if fw = view.fluid_width
          LibObjCBridge.objc_constrain_fluid_width(
            ptr, fw.native_min_px || 0.0, fw.native_max_px || 100_000.0)
        end
      end

      # -----------------------------------------------------------------
      # Visit: HStack -> UIStackView (horizontal)
      # -----------------------------------------------------------------
      def visit(view : UI::HStack)
        ptr = alloc_init("UIStackView")

        # UILayoutConstraintAxisHorizontal = 0
        LibObjCBridge.objc_send_long(ptr, sel("setAxis:"), 0_i64)

        # Spacing
        LibObjCBridge.objc_send_1d(ptr, sel("setSpacing:"), view.spacing)

        # UIStackView alignment for horizontal axis:
        # UIStackViewAlignmentTop=1, UIStackViewAlignmentCenter=3,
        # UIStackViewAlignmentBottom=4, UIStackViewAlignmentFill=0
        alignment_val = case view.alignment
                        when Alignment::Top    then 1_i64
                        when Alignment::Center then 3_i64
                        when Alignment::Bottom then 4_i64
                        when Alignment::Fill   then 0_i64
                        else                        3_i64
                        end
        LibObjCBridge.objc_send_long(ptr, sel("setAlignment:"), alignment_val)

        # Equal-width cells (tab bar / equal button row). UIStackView's default
        # Fill distribution stretches ONE child by hugging priority, cramming
        # the rest to their intrinsic size — FillEqually (1) splits N evenly.
        # (Mirrors the appkit_renderer; was silently ignored on iOS.)
        if view.fill_equally
          LibObjCBridge.objc_send_long(ptr, sel("setDistribution:"), 1_i64)
        end

        # Common properties
        apply_common_properties(ptr, view)
        apply_stack_padding(ptr, view)

        handle = ObjC.owned(ptr, label: "UIStackView[h]")
        native = NativeView.new(handle)

        push_stack(native, is_uistack: true)
        view.children.each do |child|
          child.accept(self)
        end
        pop_stack

        # B2.1 — cure the "50/50 layout disease". A UIStackView defaults to
        # .fill distribution, which stretches EVERY arranged subview that lacks
        # an explicit width and sits at the same content-hugging priority. A
        # hosted control (UIHostingController-backed Button / IconButton /
        # Image) reports no intrinsic width to the stack's fitting pass, so a
        # row like `HStack[Button(fill_horizontal), IconButton]` split ~50/50:
        # the chevron host stretched to half the row while the label compressed
        # below intrinsic and wrapped. NSStackView's default GravityAreas
        # distribution hugs no-width children automatically (appkit reference);
        # UIKit has no equivalent, so we recreate it here. For each child that
        # is NOT the flex element (no fill_horizontal) and has no explicit
        # width pin, raise horizontal hugging + compression resistance to
        # Required so the child hugs its intrinsic width and the fill child (or
        # an interior Spacer) absorbs the slack. A child WITH an exact width pin
        # already received objc_set_horizontal_fixed_priority in
        # apply_common_properties; skip it. Spacers manage their own (low)
        # hugging — skip them so they still flex. fill_horizontal children keep
        # their flex priority (high compression resistance, low hugging) from
        # apply_common_properties.
        view.children.each_with_index do |child_view, i|
          next if child_view.fill_horizontal
          next if child_view.is_a?(UI::Spacer)
          next if child_view.minimum_width || child_view.maximum_width || child_view.fluid_width
          cn = native.children[i]?
          next unless cn && cn.handle.valid?
          LibObjCBridge.objc_set_horizontal_fixed_priority(cn.handle.ptr!)
        end

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ZStack -> UIView (overlay container)
      #
      # Children are added as subviews in order. Later children are drawn
      # on top. Each child gets an autoresizing mask to fill the parent.
      # -----------------------------------------------------------------
      def visit(view : UI::ZStack)
        ptr = alloc_init("UIView")

        # Common properties
        apply_common_properties(ptr, view)

        handle = ObjC.owned(ptr, label: "UIView[zstack]")
        native = NativeView.new(handle)

        push_stack(native, is_uistack: false)
        view.children.each do |child|
          child.accept(self)
        end
        pop_stack

        # ZStack children overlap and fill the container. The autoresizing MASK
        # (FlexibleWidth|FlexibleHeight) is IGNORED here because every rendered
        # child sets translatesAutoresizingMaskIntoConstraints = NO for Auto Layout
        # — so the old objc_set_autoresize(18) was a dead no-op: a child with no
        # explicit size collapsed to its intrinsic height/position instead of
        # filling (e.g. a content VStack's bottom Spacer couldn't expand, so a
        # "push to the bottom" tray floated mid-screen; a full-bleed bg only
        # covered part of the frame). Pin each child's edges to the ZStack via
        # Auto Layout instead — exactly as the appkit renderer does. This also
        # makes UIKit honor ZStack#alignment: Center/Fill (and the default) keep
        # the all-4-edges fill every full-bleed hero relies on (zero-regression),
        # while the directional cases (Leading/Trailing/Top/Bottom) pin the
        # aligned edge and soft-fill the opposite so a fixed-size child sits
        # aligned to that side (drawer panel, toast, badge) while unconstrained
        # children still fill. See objc_pin_child_aligned.
        align_code = case view.alignment
                     when UI::Alignment::Leading  then 0
                     when UI::Alignment::Trailing then 1
                     when UI::Alignment::Top      then 2
                     when UI::Alignment::Bottom   then 3
                     else                              -1 # Center / Fill → legacy all-edges fill
                     end
        native.children.each do |child_nv|
          next unless child_nv.handle.valid?
          child_ptr = child_nv.handle.ptr!
          if align_code < 0
            LibObjCBridge.objc_pin_child_to_superview_edges(ptr, child_ptr)
          else
            LibObjCBridge.objc_pin_child_aligned(ptr, child_ptr, align_code)
          end
        end

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Image -> UIImageView
      # -----------------------------------------------------------------
      def visit(view : UI::Image)
        overrides_ptr = LibSwiftKitBridge.apsk_image_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_image(target_str, view, sender)

        ptr = LibSwiftKitBridge.apsk_make_image(view.source.to_unsafe, overrides_ptr)
        emit(ptr, "UIHostingController[Image]")
      end

      # -----------------------------------------------------------------
      # Visit: TextField -> UITextField (or with secureTextEntry for passwords)
      # -----------------------------------------------------------------
      # Visit: TextField -> SwiftUI TextField (or SecureField) hosted in
      # UIHostingController. See appkit counterpart for the action-token
      # caveat regarding string round-trip.
      def visit(view : UI::TextField)
        overrides_ptr = LibSwiftKitBridge.apsk_text_field_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_text_field(target_str, view, sender)

        # Phase 6.10 Rem 4 (Item 1) — TextField on_change must receive
        # the actual typed text, not just a "something changed" signal.
        # Register a `Proc(String, Nil)` callback via
        # `register_string`; the string trampoline
        # `ap_swiftkit_invoke_action_string` resolves the token and
        # calls the closure with the real text. The previous
        # `register_action_with_value` path collapsed every char event
        # to `change_handler.call("")` — breaking the Editor's
        # `draft.title = value` propagation and shipping empty-title
        # todos on Save.
        #
        # Phase 8B iter 3 (Item 4) — FormState wiring. See the AppKit
        # counterpart for the rationale.
        wrapped_handler = UI::FormStateRendererHook.wrap_text_handler(view)
        action_token = 0_u64
        if wrapped_handler
          action_token = UI::CallbackRegistry.register_string(wrapped_handler)
        end

        ptr = LibSwiftKitBridge.apsk_make_text_field(
          view.placeholder.to_unsafe, view.text.to_unsafe,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingController[TextField]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ScrollView -> UIScrollView
      # -----------------------------------------------------------------
      def visit(view : UI::ScrollView)
        ptr = alloc_init("UIScrollView")

        # Scroll indicator visibility
        LibObjCBridge.objc_send_bool(ptr, sel("setShowsVerticalScrollIndicator:"),
          (view.scroll_vertical && view.shows_indicators) ? 1 : 0)
        LibObjCBridge.objc_send_bool(ptr, sel("setShowsHorizontalScrollIndicator:"),
          (view.scroll_horizontal && view.shows_indicators) ? 1 : 0)

        # Bounce behavior: disable vertical bounce if not scrolling vertically
        unless view.scroll_vertical
          LibObjCBridge.objc_send_bool(ptr, sel("setAlwaysBounceVertical:"), 0)
        end
        unless view.scroll_horizontal
          LibObjCBridge.objc_send_bool(ptr, sel("setAlwaysBounceHorizontal:"), 0)
        end

        # Explicit viewport size constraint.  UIScrollView inside a UIStackView
        # collapses to zero height because UIScrollView has no intrinsicContentSize
        # that the stack can use; the stack sees a (0, 0) fittingSize and collapses
        # the view.  objc_constrain_height pins the viewport height, letting the
        # content inside the scroll view remain taller (scrollable).
        if view.frame_width > 0.0 && view.frame_height > 0.0
          LibObjCBridge.objc_constrain_size(ptr, view.frame_width, view.frame_height)
        elsif view.frame_height > 0.0
          LibObjCBridge.objc_constrain_height(ptr, view.frame_height)
        end

        # Common properties
        apply_common_properties(ptr, view)

        handle = ObjC.owned(ptr, label: "UIScrollView")
        native = NativeView.new(handle)

        # Visit the content subtree in isolation (render_detached) to get the
        # content UIView pointer.  Then:
        #   1. Add it as a subview of the UIScrollView.
        #   2. Call uiscrollview_pin_content to wire the content view's edges
        #      to the UIScrollView's contentLayoutGuide and its width to the
        #      frameLayoutGuide.  Without these constraints, UIScrollView's
        #      contentSize stays at {0,0} and the content collapses to zero.
        if content = view.content
          if content_nv = render_detached(content)
            native.add_child(content_nv)
            if content_nv.handle.valid?
              content_ptr = content_nv.handle.ptr!
              LibObjCBridge.objc_add_subview(ptr, content_ptr)
              LibObjCBridge.uiscrollview_pin_content(ptr, content_ptr)
            end
          end
        end

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Spacer -> UIView (empty, flexible)
      #
      # Spacers in a UIStackView expand to fill available space because
      # UIStackView distributes space among arranged subviews. A plain
      # UIView with no content hugging priority set achieves this.
      # Setting content hugging priority to 1 (UILayoutPriorityFittingSizeLevel=50,
      # lower = easier to stretch) allows the spacer to expand freely.
      # -----------------------------------------------------------------
      def visit(view : UI::Spacer)
        ptr = alloc_init("UIView")

        # Disable autoresizing mask translation so Auto Layout controls size
        LibObjCBridge.objc_send_bool(ptr, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)

        # Drop content-hugging to 1 on both axes so the Spacer unambiguously absorbs
        # the stack's slack (a plain UIView and ordinary content both default to 250,
        # which ties under UIStackView .fill and resolves arbitrarily — e.g. a
        # [Spacer, card, Spacer] column would pin the card to the top instead of
        # centering). This is what the long-standing comment always claimed but the
        # code never did, which is why VStack Spacers were unreliable on iOS.
        LibObjCBridge.objc_set_flex_spacer_priority(ptr)

        # If min_length > 0, set the frame as a minimum size hint.
        if view.min_length > 0
          min = view.min_length
          rect = LibObjCBridge::CGRect.new(x: 0.0, y: 0.0, width: min, height: min)
          LibObjCBridge.objc_set_frame(ptr, rect)
        end

        # Common properties
        apply_common_properties(ptr, view)

        emit(ptr, "UIView[spacer]")
      end

      # -----------------------------------------------------------------
      # Visit: Toggle -> UISwitch
      #
      # UISwitch is the native iOS toggle control. It has setOn:animated:
      # for state and setOnTintColor: for tint.
      #
      # Dark mode appearance fix (June R3): UISwitch OFF-state track renders
      # "cream" in dark captures because the switch inherits a light trait
      # collection when created outside the window hierarchy. Fix: set
      # overrideUserInterfaceStyle (UIUserInterfaceStyleDark=2, Light=1) on
      # the UISwitch directly from TEST_RUNNER_HIG_APPEARANCE before adding
      # it to the view tree. This forces the switch to resolve its OFF-state
      # gray track against the correct dark palette immediately.
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
        handle = ObjC.owned(ptr, label: "UIHostingController[Toggle]")
        unless state_slot.null?
          handle.state_handle = state_slot
          view.swiftkit_state_handle = state_slot
        end
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Checkbox -> UIButton (configured as a checkbox toggle)
      #
      # iOS has no native UICheckbox. We simulate one using a UIButton
      # that displays a system checkmark image when checked. The button
      # toggles its checked state on tap and calls the on_change handler.
      #
      # Symbol names (SF Symbols): "checkmark.square.fill" (checked),
      # "square" (unchecked). These are available on iOS 13+.
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
          view.label.to_unsafe, view.is_checked ? 1 : 0,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingController[Checkbox]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: RadioGroup -> UIStackView of UIButtons (radio options)
      #
      # iOS has no native UIRadioGroup. We simulate one as a UIStackView
      # (vertical) containing one UIButton per option. The selected option
      # is indicated by a filled circle SF Symbol; others show empty circles.
      #
      # Symbol names: "largecircle.fill.circle" (selected), "circle" (unselected).
      # Available on iOS 13+.
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

        opt_count = view.options.size
        opts_buf = Pointer(UInt8*).malloc(opt_count.to_u64)
        view.options.each_with_index { |o, i| opts_buf[i] = o.to_unsafe }

        ptr = LibSwiftKitBridge.apsk_make_radio_group(
          opts_buf.as(Void*), opt_count.to_i32, view.selected_index.to_i32,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingController[RadioGroup]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Slider -> synthetic UIView container + invisible UISlider
      #
      # UISlider's track is drawn via private CALayer sublayers that XCUITest
      # rasterization does not composite into screenshots.  Instead we build a
      # screenshot-stable synthetic track:
      #   - A UIView container (44pt tall, TAMIC=NO) as the outer hit target.
      #   - A background track UIView (full width, 4pt, corner radius 2pt,
      #     UIColor.systemFillColor) for the unfilled portion.
      #   - A filled track UIView (leading fraction of width, same height,
      #     system blue or tint_color) for the filled portion.
      #   - A 28pt circular thumb UIView (white, drop shadow) at the fraction
      #     position.
      #   - The real UISlider at alpha 0.0 on top, so touch events still route
      #     correctly and UIControlEventValueChanged still fires.
      #
      # All frame layout is deferred to the next run-loop turn (after UIStackView
      # resolves the container width) via dispatch_async from the C helper
      # uislider_build_synthetic_track.
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
        handle = ObjC.owned(ptr, label: "UIHostingController[Slider]")
        unless state_slot.null?
          handle.state_handle = state_slot
          view.swiftkit_state_handle = state_slot
        end
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ProgressView -> UIProgressView (linear) or UIActivityIndicatorView (circular)
      # -----------------------------------------------------------------
      # -----------------------------------------------------------------
      # Visit: NavigationStack -> UIView (container for navigation content)
      # -----------------------------------------------------------------
      def visit(view : UI::NavigationStack)
        overrides_ptr = LibSwiftKitBridge.apsk_navigation_stack_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_navigation_stack(target_str, view, sender)

        children_native = [] of NativeView
        if d = render_detached(view.current_view)
          children_native << d
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_navigation_stack(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "UIHostingView[NavigationStack]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      def visit(view : UI::NavigationLink)
        overrides_ptr = LibSwiftKitBridge.apsk_navigation_link_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_navigation_link(target_str, view, sender)

        children_native = [] of NativeView
        if d = render_detached(view.destination)
          children_native << d
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_navigation_link(
          view.label.to_unsafe, child_buf.as(Void*),
          children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "UIHostingView[NavigationLink]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: TabView -> UIVisualEffectView (Liquid Glass root) containing
      #                   a vertical UIStackView with content + tab bar row.
      #
      # HIG tab-bars Platform considerations (iOS): "A tab bar floats above
      # content at the bottom of the screen. Its items rest on a Liquid Glass
      # background that allows content beneath to peek through."
      #
      # Structure:
      #   UIVisualEffectView (glass root: UIGlassEffect iOS 26 / UIBlurEffect
      #                        systemChromeMaterial=11 fallback)
      #     contentView
      #       UIStackView (outer, vertical, no spacing)
      #         UIStackView (content area: grows, vertical)
      #           <selected tab content>
      #         UIView (separator: 0.5pt horizontal hairline)
      #         UIStackView (tab row: horizontal, equal-width cells)
      #           cell_0 .. cell_N (vertical: UIImageView + UILabel)
      #
      # Selected tab: UIColor.systemBlueColor (or selected_tint_color).
      # Unselected tabs: UIColor.secondaryLabelColor (appearance-tracking).
      # -----------------------------------------------------------------
      def visit(view : UI::TabView)
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
            empty_ptr = alloc_init("UIView")
            children_native << NativeView.new(ObjC.owned(empty_ptr, label: "UIView[tab-empty]"))
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_tab_view(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingView[TabView]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ProgressView -> UIProgressView (linear) or UIActivityIndicatorView (circular)
      # -----------------------------------------------------------------
      def visit(view : UI::ProgressView)
        if view.style == UI::ProgressStyle::Circular
          ptr = alloc_init("UIActivityIndicatorView")

          if view.value.nil?
            # UIActivityIndicatorView.startAnimating
            LibObjCBridge.objc_send(ptr, sel("startAnimating"))
          end

          apply_common_properties(ptr, view)

          emit(ptr, "UIActivityIndicatorView[progress]")
        else
          ptr = alloc_init("UIProgressView")

          if val = view.value
            # setProgress:animated: - animated:NO=0
            LibObjCBridge.objc_send_id_long(ptr, sel("setProgress:animated:"),
              Pointer(Void).new((val * 1000.0).round.to_u64), 0_i64)
          end

          if tint = view.tint_color
            tint_ptr = LibObjCBridge.nscolor_rgba(tint.r, tint.g, tint.b, tint.a)
            LibObjCBridge.objc_send_id(ptr, sel("setProgressTintColor:"), tint_ptr)
          end

          apply_common_properties(ptr, view)

          emit(ptr, "UIProgressView")
        end
      end

      # -----------------------------------------------------------------
      # Visit: ActivityIndicator -> UIActivityIndicatorView
      # -----------------------------------------------------------------
      def visit(view : UI::ActivityIndicator)
        ptr = alloc_init("UIActivityIndicatorView")

        # UIActivityIndicatorViewStyle: medium=100, large=101 (iOS 13+)
        style_val = view.size == :large ? 101_i64 : 100_i64
        LibObjCBridge.objc_send_long(ptr, sel("setActivityIndicatorViewStyle:"), style_val)

        if view.is_animating
          LibObjCBridge.objc_send(ptr, sel("startAnimating"))
        else
          LibObjCBridge.objc_send(ptr, sel("stopAnimating"))
        end

        if tint = view.color
          tint_ptr = LibObjCBridge.nscolor_rgba(tint.r, tint.g, tint.b, tint.a)
          LibObjCBridge.objc_send_id(ptr, sel("setColor:"), tint_ptr)
        end

        apply_common_properties(ptr, view)

        emit(ptr, "UIActivityIndicatorView")
      end

      # -----------------------------------------------------------------
      # Visit: Alert -> UIVisualEffectView inline card (Liquid Glass)
      #
      # HIG: Alerts are surface components requiring Liquid Glass. On iOS 26
      # we prefer UIGlassEffect; on older SDKs UIBlurEffect(systemMaterial=7)
      # provides the frosted-glass appearance.
      #
      # For production use the caller should present UIAlertController modally.
      # This inline rendering path is used by the HIG validation host for
      # screenshot isolation. Material, corner radius, and role-coloring are
      # HIG-faithful — hudWindow-equivalent on iOS is systemMaterial.
      # -----------------------------------------------------------------
      def visit(view : UI::Alert)
        overrides_ptr = LibSwiftKitBridge.apsk_alert_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_alert(target_str, view, sender)

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
        handle = ObjC.owned(ptr, label: "UIHostingView[Alert]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Picker -> inline list with checkmarks (iOS Settings style)
      #
      # HIG short-list recommendation: "For short lists, consider using a menu
      # or segmented control instead of a wheel picker." For static option sets
      # we render an inset-grouped list of rows, each showing the option label
      # leading-aligned and a "checkmark" SF Symbol tinted systemBlue on the
      # selected row. This is the dominant picker shape in iOS Settings and
      # is legible in both light and dark appearances.
      #
      # Root: UIStackView (vertical, axis=1, alignment=Fill). UIStackView has
      # intrinsic content size from its arranged subviews — it sizes correctly
      # inside a parent UIStackView without explicit anchor constraints.
      # Corner radius + secondarySystemGroupedBackground on the root stack.
      #
      # Row anatomy (horizontal UIStackView per row, isLayoutMarginsRelativeArrangement=YES):
      #   16pt leading margin | UILabel (expands, leading-aligned, 17pt) | UIImageView (20x20pt "checkmark") | 16pt trailing margin
      #
      # The outer vertical stack uses spacing=0. A 0.5pt separator UIView is
      # inserted between rows (NOT after the last row).
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
        handle = ObjC.owned(ptr, label: "UIHostingController[Picker]")
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
        handle = ObjC.owned(ptr, label: "UIHostingController[IconButton]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64

        # B2.1 (suspect 3) — pin the HOST view's width to the icon's footprint.
        # The Swift facade sizes the glyph into an exact W×H frame
        # (icon_width/icon_height cover-crop, or the square icon_size), but
        # without a UIKit width constraint on the host UIView the host has no
        # intrinsic width for UIStackView's .fill distribution to respect — so
        # the chevron / play-circle host stretched to half the row (the "50/50
        # disease"). Pinning the host width makes the IconButton hug its icon
        # box so the HStack fixed-priority pass and the row's fill child resolve
        # the layout unambiguously. Only pin a BARE icon (bordered=false), where
        # the host width == the icon box; a bordered icon adds platform chrome
        # insets, so for it we rely on the HStack intrinsic-hug pass instead of
        # an exact pin that would clip the bezel.
        unless view.bordered
          icon_w = view.effective_icon_box_width
          if icon_w > 0.0
            LibObjCBridge.objc_constrain_width(ptr, icon_w)
            LibObjCBridge.objc_set_horizontal_fixed_priority(ptr)
          end
        end

        # Register this IconButton's view under its test_id so a later
        # UI::Popover visit can resolve it as the popover's anchor source
        # view. visit(IconButton) does NOT route through
        # apply_common_properties (it owns its overrides population), so
        # without this the registry has no entry for the button and the
        # Popover silently falls back to the SwiftUI `.popover` path —
        # which on an iPhone (compact width) adapts to a bottom SHEET
        # instead of an anchored bubble. (The overflow "•••" menu rendered
        # as a bottom sheet for exactly this reason.)
        if tid = view.test_id
          @test_id_registry[tid] = ptr
        end

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ListView -> SwiftUI `List { Section { ... } }` via
      # APSKListViewFacade (UIHostingController on iOS).
      #
      # Items are flattened across all sections into a single child-views
      # array; populator emits `setSectionItemCounts` so the facade can
      # slice them back into SwiftUI `Section`s. List style (Plain /
      # Inset / Grouped / InsetGrouped / Sidebar) flows through the
      # populator as a string key the facade switches on.
      #
      # The legacy raw-UIStackView body is preserved as
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
              empty_ptr = alloc_init("UIView")
              children_native << NativeView.new(ObjC.owned(empty_ptr, label: "UIView[list-empty]"))
            end
          end
        end

        # Phase 10D-final — per-row swipe + tap + drag-reorder token
        # registration. The flat-index walk parallels the childViews
        # ordering above so absolute row index `n` in the facade
        # corresponds to `children_native[n]`.
        callback_ids = [] of UInt64
        total_rows = children_native.size

        # Row tap tokens (one per row; 0 = no whole-row tap).
        row_tap_tokens = Array(UInt64).new(total_rows, 0_u64)
        if row_tap = view.on_row_tap
          (0...total_rows).each do |idx|
            tok = UI::CallbackRegistry.register_action { row_tap.call(idx) }
            row_tap_tokens[idx] = tok
            callback_ids << tok
          end
          sender.set_uint64_array(target_str, :setRowTapTokens, row_tap_tokens)
        end

        # Drag-reorder string-channel token.
        if move = view.on_move
          move_tok = UI::CallbackRegistry.register_string(->(payload : String) {
            # Payload shape: "from=N,to=M". Parse defensively — a
            # malformed payload is a silent no-op rather than a crash.
            from_idx = -1
            to_idx = -1
            payload.split(",").each do |kv|
              parts = kv.split("=", 2)
              next unless parts.size == 2
              case parts[0]
              when "from" then from_idx = parts[1].to_i? || -1
              when "to"   then to_idx = parts[1].to_i? || -1
              end
            end
            if from_idx >= 0 && to_idx >= 0
              move.call(from_idx, to_idx)
            end
            nil
          })
          sender.set_uint64(target_str, :setMoveToken, move_tok)
          callback_ids << move_tok
        end

        # Per-row leading swipe actions. Build flat + counts arrays.
        # Phase 10D-polish iter 2 — honor SwipeAction#tint when set;
        # emit SwipeAction#label_style into the parallel label-styles
        # array so the facade can force icon-only / title-only tiles.
        if leading_fn = view.leading_swipe_actions
          leading_labels = [] of String
          leading_icons = [] of String
          leading_tokens = [] of UInt64
          leading_roles = [] of String
          leading_tints = [] of String
          leading_label_styles = [] of String
          leading_counts = [] of Int32

          (0...total_rows).each do |idx|
            actions = leading_fn.call(idx)
            leading_counts << actions.size.to_i32
            actions.each do |action|
              leading_labels << action.label
              leading_icons << (action.icon || "")
              leading_roles << action.role.to_s
              leading_tints << (action.tint.try(&.to_s) || default_tint_for_leading(action.role))
              leading_label_styles << action.label_style.to_s
              if tap = action.on_tap
                tok = UI::CallbackRegistry.register_action(&tap)
                leading_tokens << tok
                callback_ids << tok
              else
                leading_tokens << 0_u64
              end
            end
          end
          sender.set_string_array(target_str, :setLeadingActionLabels, leading_labels)
          sender.set_string_array(target_str, :setLeadingActionIcons, leading_icons)
          sender.set_uint64_array(target_str, :setLeadingActionTokens, leading_tokens)
          sender.set_string_array(target_str, :setLeadingActionRoles, leading_roles)
          sender.set_string_array(target_str, :setLeadingActionTints, leading_tints)
          sender.set_string_array(target_str, :setLeadingActionLabelStyles, leading_label_styles)
          sender.set_int_array(target_str, :setLeadingActionCounts, leading_counts)
        end

        # Per-row trailing swipe actions. Same shape as leading.
        if trailing_fn = view.trailing_swipe_actions
          trailing_labels = [] of String
          trailing_icons = [] of String
          trailing_tokens = [] of UInt64
          trailing_roles = [] of String
          trailing_tints = [] of String
          trailing_label_styles = [] of String
          trailing_counts = [] of Int32

          (0...total_rows).each do |idx|
            actions = trailing_fn.call(idx)
            trailing_counts << actions.size.to_i32
            actions.each do |action|
              trailing_labels << action.label
              trailing_icons << (action.icon || "")
              trailing_roles << action.role.to_s
              trailing_tints << (action.tint.try(&.to_s) || default_tint_for_trailing(action.role))
              trailing_label_styles << action.label_style.to_s
              if tap = action.on_tap
                tok = UI::CallbackRegistry.register_action(&tap)
                trailing_tokens << tok
                callback_ids << tok
              else
                trailing_tokens << 0_u64
              end
            end
          end
          sender.set_string_array(target_str, :setTrailingActionLabels, trailing_labels)
          sender.set_string_array(target_str, :setTrailingActionIcons, trailing_icons)
          sender.set_uint64_array(target_str, :setTrailingActionTokens, trailing_tokens)
          sender.set_string_array(target_str, :setTrailingActionRoles, trailing_roles)
          sender.set_string_array(target_str, :setTrailingActionTints, trailing_tints)
          sender.set_string_array(target_str, :setTrailingActionLabelStyles, trailing_label_styles)
          sender.set_int_array(target_str, :setTrailingActionCounts, trailing_counts)
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_list_view(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "UIHostingView[ListView]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      # Phase 10D-final — default tint per role for leading swipe.
      # Mirrors `populate_swipe_action_row` (leading positive → green).
      private def default_tint_for_leading(role : Symbol) : String
        case role
        when :destructive then "red"
        else                   "green"
        end
      end

      # Phase 10D-final — default tint per role for trailing swipe.
      # Destructive returns "" so SwiftUI's `.destructive` role uses the
      # platform-native danger tint (system red).
      private def default_tint_for_trailing(role : Symbol) : String
        case role
        when :destructive then ""
        else                   "blue"
        end
      end

      # Legacy UIKit ListView body, retained for reference.
      private def _legacy_list_view(view : UI::ListView)
        outer_ptr = alloc_init("UIStackView")

        # UILayoutConstraintAxisVertical = 1
        LibObjCBridge.objc_send_long(outer_ptr, sel("setAxis:"), 1_i64)
        LibObjCBridge.objc_send_1d(outer_ptr, sel("setSpacing:"), view.item_spacing)
        # UIStackViewAlignmentFill = 0 — children stretch to fill the full width,
        # ensuring HStack rows span the list width rather than sizing to content.
        LibObjCBridge.objc_send_long(outer_ptr, sel("setAlignment:"), 0_i64)

        apply_common_properties(outer_ptr, view)

        handle = ObjC.owned(outer_ptr, label: "UIStackView[list]")
        native = NativeView.new(handle)

        push_stack(native, is_uistack: true)

        view.sections.each do |section|
          if header = section.header
            header_ptr = alloc_init("UILabel")
            header_str = LibObjCBridge.nsstring_from_cstr(header.to_unsafe)
            LibObjCBridge.objc_send_id(header_ptr, sel("setText:"), header_str)
            emit(header_ptr, "UILabel[list-header]")
          end

          if view.layout == UI::ListLayout::Grid && view.columns > 1
            # Grid mode: chunk items into rows of `columns` width.
            # Each row is a horizontal UIStackView of equal-width cells.
            cols = view.columns
            items = section.items
            row_idx = 0
            while row_idx < items.size
              row_ptr = alloc_init("UIStackView")
              # UILayoutConstraintAxisHorizontal = 0
              LibObjCBridge.objc_send_long(row_ptr, sel("setAxis:"), 0_i64)
              LibObjCBridge.objc_send_1d(row_ptr, sel("setSpacing:"), view.item_spacing)
              # UIStackViewDistributionFillEqually = 2
              LibObjCBridge.objc_send_long(row_ptr, sel("setDistribution:"), 2_i64)
              # TAMIC = NO so the outer vertical UIStackView can Auto Layout this row.
              LibObjCBridge.objc_send_bool(row_ptr, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)

              row_handle = ObjC.owned(row_ptr, label: "UIStackView[grid-row]")
              row_native = NativeView.new(row_handle)
              push_stack(row_native, is_uistack: true)

              col_count = 0
              while col_count < cols && (row_idx + col_count) < items.size
                items[row_idx + col_count].accept(self)
                col_count += 1
              end

              # Pad incomplete last row with empty spacer views for alignment
              while col_count < cols
                spacer_ptr = alloc_init("UIView")
                emit(spacer_ptr, "UIView[grid-pad]")
                col_count += 1
              end

              pop_stack
              emit(row_ptr, "UIStackView[grid-row]")

              row_idx += cols
            end
          else
            # List mode: items appended to the outer vertical UIStackView.
            # When shows_separators is true, insert a thin UIView (0.5pt tall,
            # UIColor.separatorColor) between each pair of items -- mimicking
            # UITableView hairline dividers. InsetGrouped style wraps items in
            # a rounded-card UIView with corner radius 10pt.
            if view.style == UI::ListStyle::InsetGrouped
              # Rounded card: plain UIView container with rounded corners and
              # a system-secondary fill. Items are nested in a UIStackView
              # inside the card so separators can be inserted.
              card_ptr = alloc_init("UIView")
              LibObjCBridge.objc_send_bool(card_ptr, sel("setClipsToBounds:"), 1)
              # Set corner radius via CALayer (no appearance-tracking issue here
              # since corner radius is not appearance-dependent).
              card_layer = LibObjCBridge.objc_send(card_ptr, sel("layer"))
              unless card_layer.null?
                # token_radius(:card) — inset-grouped card corner.
                LibObjCBridge.objc_send_1d(card_layer, sel("setCornerRadius:"), token_radius(:card))
              end
              # Use UIView.setBackgroundColor: (NOT layer.backgroundColor) so that
              # the dynamic UIColor tracks appearance automatically. Setting CGColor
              # on the layer captures a static snapshot at conversion time and does
              # NOT track dark/light appearance changes.
              sec_bg_cls = LibObjCBridge.objc_getClass("UIColor")
              sec_bg = LibObjCBridge.objc_send(sec_bg_cls, sel("secondarySystemGroupedBackgroundColor"))
              LibObjCBridge.objc_send_id(card_ptr, sel("setBackgroundColor:"), sec_bg) unless sec_bg.null?
              # Inner UIStackView holds the items.
              inner_ptr = alloc_init("UIStackView")
              LibObjCBridge.objc_send_long(inner_ptr, sel("setAxis:"), 1_i64)
              LibObjCBridge.objc_send_1d(inner_ptr, sel("setSpacing:"), 0.0)
              # UIStackViewAlignmentFill = 0: inner stack children fill the card width.
              LibObjCBridge.objc_send_long(inner_ptr, sel("setAlignment:"), 0_i64)
              LibObjCBridge.objc_send_bool(inner_ptr, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
              LibObjCBridge.objc_add_subview(card_ptr, inner_ptr)
              # Pin inner UIStackView to the card UIView's edges so it sizes
              # correctly inside the card. Without these constraints, the inner
              # stack has no frame and all its arranged subviews are invisible.
              {
                {"topAnchor", "topAnchor"},
                {"leadingAnchor", "leadingAnchor"},
                {"trailingAnchor", "trailingAnchor"},
                {"bottomAnchor", "bottomAnchor"},
              }.each do |inner_anch_name, card_anch_name|
                inner_anch = LibObjCBridge.objc_send(inner_ptr, sel(inner_anch_name))
                card_anch = LibObjCBridge.objc_send(card_ptr, sel(card_anch_name))
                unless inner_anch.null? || card_anch.null?
                  # constraintEqualToAnchor: returns NSLayoutConstraint (an id).
                  c = LibObjCBridge.objc_send_id(inner_anch, sel("constraintEqualToAnchor:"), card_anch)
                  LibObjCBridge.objc_send_bool(c, sel("setActive:"), 1) unless c.null?
                end
              end

              inner_handle = ObjC.owned(inner_ptr, label: "UIStackView[inset-grouped-inner]")
              inner_native = NativeView.new(inner_handle)
              # Card UIView must also have TAMIC = NO so the outer ListView
              # UIStackView can apply Auto Layout to it correctly.
              LibObjCBridge.objc_send_bool(card_ptr, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
              card_handle = ObjC.owned(card_ptr, label: "UIView[inset-grouped-card]")
              card_native = NativeView.new(card_handle)
              # Push the inner stack for item rendering.
              push_stack(inner_native, is_uistack: true)
              screen_w_ig = LibObjCBridge.objc_screen_width
              item_w_ig = screen_w_ig > 0.0 ? screen_w_ig - 64.0 : 280.0
              section.items.each_with_index do |item, idx|
                item.accept(self)
                # Same width-pinning fix as plain list mode -- UIStackView
                # fill alignment doesn't propagate into nested UIStackViews.
                if parent_native = @stack.last?
                  if last_child = parent_native.children.last?
                    if last_child.handle.valid?
                      row_ptr = last_child.handle.ptr!
                      w_anch = LibObjCBridge.objc_send(row_ptr, sel("widthAnchor"))
                      unless w_anch.null?
                        wc = LibObjCBridge.objc_send_1d_ret_id(w_anch, sel("constraintEqualToConstant:"), item_w_ig)
                        LibObjCBridge.objc_send_bool(wc, sel("setActive:"), 1) unless wc.null?
                      end
                    end
                  end
                end
                if view.shows_separators && idx < section.items.size - 1
                  sep_ptr = alloc_init("UIView")
                  # 0.5pt separator; height constrained via objc_constrain_size.
                  LibObjCBridge.objc_constrain_size(sep_ptr, 0.0, 0.5)
                  uicolor_cls = LibObjCBridge.objc_getClass("UIColor")
                  sep_color = LibObjCBridge.objc_send(uicolor_cls, sel("separatorColor"))
                  unless sep_color.null?
                    sep_cg = LibObjCBridge.objc_send(sep_color, sel("CGColor"))
                    unless sep_cg.null?
                      sep_layer = LibObjCBridge.objc_send(sep_ptr, sel("layer"))
                      LibObjCBridge.objc_send_void_id(sep_layer, sel("setBackgroundColor:"), sep_cg) unless sep_layer.null?
                    end
                  end
                  emit(sep_ptr, "UIView[list-sep]")
                end
              end
              pop_stack
              # Attach inner_native as a child of card_native for the NativeView tree.
              card_native.add_child(inner_native)
              push_native(card_native)
            else
              # Plain / Grouped / Sidebar: flat list with optional separators.
              section.items.each_with_index do |item, idx|
                item.accept(self)
                # After visiting the item, explicitly pin the item's width to the
                # ListView outer UIStackView's width. UIStackView alignment=fill
                # does NOT propagate width constraints into nested UIStackViews
                # via the standard mechanism when their intrinsicContentSize.width
                # is UIViewNoIntrinsicMetric (e.g., a UIStackView containing a
                # UI::Spacer). This creates a circular dependency in the layout
                # engine: item.width = list.width, but list.width = max(item widths).
                #
                # The correct fix: pin item.width to a CONSTANT derived from the
                # screen width, not to the list's anchor. Then the item gets a
                # definite width without the circular reference, and UIStackView's
                # fill alignment on the list properly anchors the item's trailing.
                # Standard horizontal padding = 32pt (2 × 16pt), matching the
                # SwiftUI .padding() applied in ContentView.
                if parent_native = @stack.last?
                  if last_child = parent_native.children.last?
                    if last_child.handle.valid?
                      row_ptr = last_child.handle.ptr!
                      screen_w = LibObjCBridge.objc_screen_width
                      item_w = screen_w > 0.0 ? screen_w - 32.0 : 320.0
                      w_anch = LibObjCBridge.objc_send(row_ptr, sel("widthAnchor"))
                      unless w_anch.null?
                        wc = LibObjCBridge.objc_send_1d_ret_id(w_anch, sel("constraintEqualToConstant:"), item_w)
                        LibObjCBridge.objc_send_bool(wc, sel("setActive:"), 1) unless wc.null?
                      end
                    end
                  end
                end
                if view.shows_separators && idx < section.items.size - 1
                  sep_ptr = alloc_init("UIView")
                  LibObjCBridge.objc_constrain_size(sep_ptr, 0.0, 0.5)
                  uicolor_cls = LibObjCBridge.objc_getClass("UIColor")
                  sep_color = LibObjCBridge.objc_send(uicolor_cls, sel("separatorColor"))
                  unless sep_color.null?
                    sep_cg = LibObjCBridge.objc_send(sep_color, sel("CGColor"))
                    unless sep_cg.null?
                      sep_layer = LibObjCBridge.objc_send(sep_ptr, sel("layer"))
                      LibObjCBridge.objc_send_void_id(sep_layer, sel("setBackgroundColor:"), sep_cg) unless sep_layer.null?
                    end
                  end
                  emit(sep_ptr, "UIView[list-sep]")
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
      # Visit: SecureField -> UITextField with secureTextEntry = true
      # -----------------------------------------------------------------
      def visit(view : UI::SecureField)
        overrides_ptr = LibSwiftKitBridge.apsk_secure_field_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_secure_field(target_str, view, sender)

        # FormState wiring — identical to TextField. The SecureField
        # SwiftUI facade reuses TextFieldFacade's `TextStorage`, whose
        # binding fires `CallbackBridge.fireString(token, newValue)` with
        # the REAL typed cleartext. So we register on the string channel
        # (`register_string`) exactly like TextField, and the typed
        # password flows into FormState under the field's `name` key.
        # (Earlier this used the numeric channel + `call("")`, which
        # silently dropped the password — making any form that gates on a
        # non-empty password, e.g. sign-in, impossible to submit.)
        wrapped_handler = UI::FormStateRendererHook.wrap_secure_handler(view)
        action_token = 0_u64
        if wrapped_handler
          action_token = UI::CallbackRegistry.register_string(wrapped_handler)
        end

        ptr = LibSwiftKitBridge.apsk_make_secure_field(
          view.placeholder.to_unsafe, view.text.to_unsafe,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingController[SecureField]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

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
        handle = ObjC.owned(ptr, label: "UIHostingController[Stepper]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

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
        handle = ObjC.owned(ptr, label: "UIHostingController[SegmentedControl]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # Phase 10D-polish — iOS class-init-gap workaround for Time#to_unix.
      # Crystal's `Time::UNIX_EPOCH` constant (62_135_596_800 — seconds from
      # year 1 to 1970) doesn't initialize on iOS due to the documented
      # class-init gap (see [[crystal-ios-class-init-gap]] memory). When the
      # constant evaluates to 0, `Time#to_unix` returns the raw internal
      # `@seconds` (year-1-rooted) instead of the Unix epoch, producing the
      # year ~3995 = 2026 + 1969 display bug in the DatePicker.
      # Workaround: detect a value that's obviously year-1-rooted and
      # subtract the literal offset ourselves.
      TIME_UNIX_EPOCH_OFFSET_SECONDS_FROM_YEAR_1 = 62_135_596_800_i64

      private def safe_time_to_unix(t : Time) : Int64
        raw = t.to_unix
        # If the raw value is greater than ~year 2100 in seconds (4_102_444_800),
        # the constant didn't initialize and we got @seconds back. Subtract.
        if raw > 4_102_444_800_i64
          raw - TIME_UNIX_EPOCH_OFFSET_SECONDS_FROM_YEAR_1
        else
          raw
        end
      end

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

        epoch = safe_time_to_unix(view.selected_date).to_f64
        ptr = LibSwiftKitBridge.apsk_make_date_picker(
          view.label.to_unsafe, epoch, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingController[DatePicker]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

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
        handle = ObjC.owned(ptr, label: "UIHostingController[TimePicker]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      def visit(view : UI::SearchField)
        overrides_ptr = LibSwiftKitBridge.apsk_search_field_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_search_field(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          # The SwiftUI facade reuses TextStorage, whose binding fires
          # CallbackBridge.fireString(token, value) with the REAL typed
          # text. Register on the STRING channel so the handler receives
          # the actual text — NOT the numeric channel + call(""), which
          # silently dropped every keystroke (the SecureField bug class).
          action_token = UI::CallbackRegistry.register_string(change_handler)
        end

        ptr = LibSwiftKitBridge.apsk_make_search_field(
          view.placeholder.to_unsafe, view.text.to_unsafe,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingController[SearchField]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      def visit(view : UI::TextArea)
        overrides_ptr = LibSwiftKitBridge.apsk_text_area_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_text_area(target_str, view, sender)

        action_token = 0_u64
        if change_handler = view.on_change
          # The SwiftUI facade reuses TextStorage, whose binding fires
          # CallbackBridge.fireString(token, value) with the REAL typed
          # text. Register on the STRING channel so the handler receives
          # the actual text — NOT the numeric channel + call(""), which
          # silently dropped every keystroke (the SecureField bug class).
          action_token = UI::CallbackRegistry.register_string(change_handler)
        end

        ptr = LibSwiftKitBridge.apsk_make_text_area(
          view.placeholder.to_unsafe, view.text.to_unsafe,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingController[TextArea]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Grid -> UIStackView (grid approximation)
      # -----------------------------------------------------------------
      def visit(view : UI::Grid)
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
        handle = ObjC.owned(ptr, label: "UIHostingView[Grid]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Form -> UIStackView (form sections)
      # -----------------------------------------------------------------
      def visit(view : UI::Form)
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
                empty_ptr = alloc_init("UIView")
                children_native << NativeView.new(ObjC.owned(empty_ptr, label: "UIView[form-empty]"))
              end
            else
              empty_ptr = alloc_init("UIView")
              children_native << NativeView.new(ObjC.owned(empty_ptr, label: "UIView[form-empty]"))
            end
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_form(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "UIHostingView[Form]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: NavigationSplitView -> UIView (horizontal split container)
      #        with UIVisualEffectView sidebar column (Liquid Glass)
      #
      # HIG: "sidebars float above content in the Liquid Glass layer."
      # On iPhone, NavigationSplitView collapses to a NavigationStack root,
      # so the sidebar column IS the visible capture. On iPad, the split
      # layout is shown.
      #
      # iOS 26: prefer UIGlassContainerEffect for the sidebar surface;
      # fallback to UIBlurEffect(systemChromeMaterial=11) on older SDKs.
      # -----------------------------------------------------------------
      def visit(view : UI::NavigationSplitView)
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
              empty_ptr = alloc_init("UIView")
              children_native << NativeView.new(ObjC.owned(empty_ptr, label: "UIView[split-empty]"))
            end
          else
            empty_ptr = alloc_init("UIView")
            children_native << NativeView.new(ObjC.owned(empty_ptr, label: "UIView[split-empty]"))
          end
        end

        child_buf = build_child_buffer(children_native)
        ptr = LibSwiftKitBridge.apsk_make_navigation_split_view(
          child_buf.as(Void*), children_native.size.to_i32, overrides_ptr,
        )
        handle = ObjC.owned(ptr, label: "UIHostingView[NavigationSplitView]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Toolbar -> UIVisualEffectView (Liquid Glass) + horizontal
      #                   UIStackView of icon-button items.
      #
      # HIG: "A toolbar provides convenient access to frequently used
      # commands, controls, navigation, and search." On iOS 26, toolbars
      # use UIGlassEffect (iOS 26+) or UIBlurEffect.systemChromeMaterial
      # (iOS 15+) as the background material.
      #
      # Structure:
      #   UIVisualEffectView (glass root)
      #     contentView
      #       UIStackView (horizontal, 4pt spacing, 8pt h-insets, 4pt v-insets)
      #         item_0..item_N:
      #           UIButton (icon-only, 44x44pt minimum, borderless)
      #             UIImageView (SF Symbol, no circular border per HIG)
      #
      # HIG Best practices: "Prefer system-provided symbols without borders."
      # HIG iOS: "Prioritize only the most important items for inclusion in
      # the main toolbar area."
      # -----------------------------------------------------------------
      def visit(view : UI::Toolbar)
        overrides_ptr = LibSwiftKitBridge.apsk_toolbar_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_toolbar(target_str, view, sender)

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
        handle = ObjC.owned(ptr, label: "UIHostingView[Toolbar]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Sheet -> UIVisualEffectView + inner UIStackView (Liquid Glass)
      # -----------------------------------------------------------------
      def visit(view : UI::Sheet)
        # Phase 12.C iter-4 (V1 fix Option A) — REUSE PATH. If the
        # prior tree had a sheet at this identity, reuse its NativeView
        # so the SheetHost UIHostingView (and its APSKSheetState +
        # SwiftUI .sheet modifier presentation) survive the Voyager
        # rerender. Without this, the .id() bump in ContentView.swift
        # would discard the parent UIView, unmount the SheetHost, and
        # SwiftUI would dismiss the modal (V1).
        identity = view.test_id || view.accessibility_label
        if existing = try_reuse(view, identity, :sheet)
          push_native(existing)
          return
        end

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

        # Phase 3 Remediation 10 — call the reactive entry point so
        # the Swift side returns the APSKSheetState pointer through
        # `state_box`. Crystal stores it on `handle.state_handle` and
        # `view.swiftkit_state_handle` so `UI::Sheet#is_presented=`
        # can drive `.sheet(isPresented:)` after mount.
        state_slot = Pointer(Void).null.as(Void*)
        state_box = pointerof(state_slot)
        ptr = LibSwiftKitBridge.apsk_make_sheet_reactive(
          child_buf.as(Void*), children_native.size.to_i32,
          overrides_ptr, dismiss_token, state_box,
        )
        handle = ObjC.owned(ptr, label: "UIHostingView[Sheet]")
        unless state_slot.null?
          handle.state_handle = state_slot
          # Phase 12.C — tag this handle so the cross-render sweep in
          # `NativeView.dismiss_reactive_presentations!` can route it
          # through `apsk_sheet_set_presented` before the next render
          # discards the underlying UIView (C1 invariant). The
          # presentation_identity (test_id, falling back to
          # accessibility label) gates the sweep — surviving identities
          # are NOT flipped.
          handle.reactive_kind = :sheet
          handle.presentation_identity = view.test_id || view.accessibility_label
          view.swiftkit_state_handle = state_slot
        end
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Popover -> UIVisualEffectView inline card (Liquid Glass)
      #
      # HIG: Popovers are surface components requiring Liquid Glass on iOS 26.
      # Production usage on iOS uses UIPopoverPresentationController for the
      # full presentation lifecycle with arrow. The inline path (is_presented
      # == false) renders the glass surface directly into the host view tree
      # for screenshot isolation in the HIG validation loop.
      #
      # Material: UIGlassEffect (iOS 26) preferred; falls back to
      # UIBlurEffectStyleSystemChromeMaterial (= 11, tracks appearance) on
      # older SDKs.
      #
      # Arrow/tail: UIPopoverPresentationController provides the arrow when
      # used in the presented path. The inline validation path does not emit
      # a native arrow -- logged as a systemic gap in gaps.md.
      #
      # Corner radius ~10pt via CALayer.setCornerRadius: matching HIG popover
      # default. Content insets 16pt leading/trailing, 12pt top/bottom.
      # -----------------------------------------------------------------
      def visit(view : UI::Popover)
        overrides_ptr = LibSwiftKitBridge.apsk_popover_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_popover(target_str, view, sender)

        # Phase 10D-polish iter 2 (B-POPOVER-ANCHOR-VIEW) — look up
        # the anchor source view by test_id in the per-renderer registry.
        # When found, hand the UIView pointer through to the facade so
        # UIPopoverPresentationController anchors the bubble's arrow
        # at the source view's frame.
        if anchor_id = view.anchor_view_id
          if anchor_ptr = @test_id_registry[anchor_id]?
            LibSwiftKitBridge.apsk_overrides_set_object_ptr(
              overrides_ptr,
              "setAnchorSourceView:".to_unsafe,
              anchor_ptr,
            )
          end
        end

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
        handle = ObjC.owned(ptr, label: "UIHostingView[Popover]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ConfirmationDialog -> UIAlertController (action sheet style)
      # -----------------------------------------------------------------
      def visit(view : UI::ConfirmationDialog)
        # Phase 12.C iter-4 (V1 fix Option A) — reuse path.
        identity = view.test_id || view.accessibility_label
        if existing = try_reuse(view, identity, :confirmation_dialog)
          push_native(existing)
          return
        end

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

        # Phase 12.C — reactive entry (Codex iter-1 BLOCKER 1). Returns the
        # BoolStorage pointer through state_box so the cross-render sweep
        # can flip the presentation binding before the next render's tree
        # swap. Without this, V1 (auto-dismiss-on-rerender) still hits the
        # ConfirmationDialog share flow.
        state_slot = Pointer(Void).null.as(Void*)
        state_box = pointerof(state_slot)
        ptr = LibSwiftKitBridge.apsk_make_confirmation_dialog_reactive(
          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr, state_box,
        )
        handle = ObjC.owned(ptr, label: "UIHostingView[ConfirmationDialog]")
        unless state_slot.null?
          handle.state_handle = state_slot
          handle.reactive_kind = :confirmation_dialog
          handle.presentation_identity = view.test_id || view.accessibility_label
        end
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Snackbar -> UILabel (toast overlay)
      #
      # Phase 10B.2c iter 2 — iOS snackbars are static UILabel
      # overlays at the renderer layer; the dismiss timer is owned by
      # host code (Liquid Glass toasts on iOS 26+ typically use a
      # presentation controller with its own dispatch_after). The
      # view's `effective_duration(@environment)` is the canonical
      # source of truth — host code reads it from the renderer's
      # environment when scheduling its own dismiss. The visit method
      # itself does not own the timer.
      # -----------------------------------------------------------------
      def visit(view : UI::Snackbar)
        ptr = alloc_init("UILabel")

        msg_str = LibObjCBridge.nsstring_from_cstr(view.message.to_unsafe)
        LibObjCBridge.objc_send_id(ptr, sel("setText:"), msg_str)

        if view.is_presented
          LibObjCBridge.objc_send_bool(ptr, sel("setHidden:"), 0)
        else
          LibObjCBridge.objc_send_bool(ptr, sel("setHidden:"), 1)
        end

        apply_common_properties(ptr, view)

        emit(ptr, "UILabel[snackbar]")
      end

      # -----------------------------------------------------------------
      # Visit: Card -> UIView (grouped card container)
      #
      # HIG Boxes - Platform considerations, iOS/iPadOS: "iOS and iPadOS
      # use the secondary and tertiary background colors in boxes." The card
      # chrome is an outer UIView so its rounded background and exact width are
      # not stretched by an ancestor UIStackView's Fill distribution. Content is
      # arranged by an inner pinned UIStackView.
      # -----------------------------------------------------------------
      def visit(view : UI::Card)
        # A Card whose content holds an interactive control (Button /
        # IconButton / Toggle / ...) MUST render as a raw UIKit container, not
        # a SwiftUI UIHostingController. The SwiftUI card (`_swiftui_card`)
        # re-hosts its content through `APSKHostedChild` (a UIViewRepresentable)
        # inside its own UIHostingController — so every interactive child, which
        # is itself a UIHostingController, becomes a UIHostingController NESTED
        # inside another one. A SwiftUI Button nested across that second hosting
        # boundary never receives the tap: the child VC parents correctly (Path
        # A), the button is hit-testable, but the outer hosting layer's gesture
        # arbitration swallows the touch, so the button's action never fires.
        # This dead-tapped the play-circle inside every tracks/home/onboarding
        # card on iOS (HappyCoach testAudioPlayerPlayPauseSmoke).
        #
        # The raw-UIKit body adds the content through the normal visit path, so
        # an interactive child is a direct UIStackView arranged subview whose
        # own hosting controller's responder chain reaches the root view
        # controller — taps fire exactly like a button in a plain HStack (the
        # affirmation-review cards, which never wrap their buttons in a Card,
        # prove this path works). It also renders the Card's explicit
        # background/corner/border verbatim via apply_common_properties instead
        # of layering SwiftUI's `.regularMaterial` over the requested colour.
        render_uikit_card(view)
      end

      # SwiftUI-hosted Card body (material / Liquid-Glass chrome). Retained for
      # non-iOS surfaces / reference; NOT used on iOS because it re-hosts content
      # through a nested UIHostingController and dead-taps interactive children
      # (see visit(UI::Card)).
      private def _swiftui_card(view : UI::Card)
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
        handle = ObjC.owned(ptr, label: "UIHostingView[Card]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # Raw-UIKit Card body: an outer UIView (rounded background + exact width,
      # not stretched by an ancestor UIStackView Fill) with an inner pinned
      # UIStackView that arranges the content via the normal visit path. This is
      # the active iOS Card renderer — it keeps interactive children tappable by
      # not introducing a second SwiftUI hosting boundary (see visit(UI::Card)).
      private def render_uikit_card(view : UI::Card)
        outer = alloc_init("UIView")
        inner = alloc_init("UIStackView")
        # Vertical axis (UILayoutConstraintAxisVertical = 1).
        LibObjCBridge.objc_send_long(inner, sel("setAxis:"), 1_i64)
        # HIG-standard ~8pt inter-row spacing.
        LibObjCBridge.objc_send_1d(inner, sel("setSpacing:"), 8.0)
        # Fill alignment (0) so children use the card's full width.
        LibObjCBridge.objc_send_long(inner, sel("setAlignment:"), 0_i64)

        # UI::Card#content_padding is the cross-platform contract for readable
        # rounded containers. Install it on the outer chrome and pin the inner
        # content stack to the layoutMarginsGuide.
        card_pad = view.content_padding
        card_insets = LibObjCBridge::CGRect.new(
          x: card_pad.top,
          y: card_pad.leading,
          width: card_pad.bottom,
          height: card_pad.trailing
        )
        LibObjCBridge.objc_send_rect_void(outer, sel("setLayoutMargins:"), card_insets)
        label_preferred_width = exact_card_label_preferred_width(view)

        # Grouped-container background per HIG. UIColor class method
        # selection based on UI::Card#material -- default :secondary.
        color_sel = case view.material
                    when :tertiary
                      sel("tertiarySystemBackgroundColor")
                    else
                      sel("secondarySystemBackgroundColor")
                    end
        uicolor_cls = LibObjCBridge.objc_getClass("UIColor")
        bg_color = LibObjCBridge.objc_send(uicolor_cls, color_sel)
        unless bg_color.null?
          LibObjCBridge.objc_send_id(outer, sel("setBackgroundColor:"), bg_color)
        end

        # token_radius(:card) (~10pt), HIG grouped-container default on iOS 26.
        layer = LibObjCBridge.objc_send(outer, sel("layer"))
        unless layer.null?
          LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), token_radius(:card))
        end
        LibObjCBridge.objc_send_bool(outer, sel("setClipsToBounds:"), 1)

        apply_common_properties(outer, view)
        LibObjCBridge.objc_send_bool(inner, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
        LibObjCBridge.objc_add_subview(outer, inner)
        LibObjCBridge.objc_pin_child_to_layout_margins(outer, inner)

        outer_handle = ObjC.owned(outer, label: "UIView[card]")
        native = NativeView.new(outer_handle)
        inner_handle = ObjC.owned(inner, label: "UIStackView[card-content]")
        inner_native = NativeView.new(inner_handle)
        native.add_child(inner_native)

        # Prepend an optional headline title label inside the card stack.
        if title = view.title
          title_ptr = alloc_init("UILabel")
          LibObjCBridge.objc_send_bool(title_ptr, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
          title_ns = LibObjCBridge.nsstring_from_cstr(title.to_unsafe)
          LibObjCBridge.objc_send_id(title_ptr, sel("setText:"), title_ns)
          # Headline weight (semibold 17pt) -- matches HIG for grouped
          # card titles on iOS.
          headline_font = LibObjCBridge.nsfont_system_weight(17.0, 0.3)
          LibObjCBridge.objc_send_id(title_ptr, sel("setFont:"), headline_font)
          if preferred_width = label_preferred_width
            LibObjCBridge.objc_send_long(title_ptr, sel("setNumberOfLines:"), 0_i64)
            LibObjCBridge.objc_send_1d(title_ptr, sel("setPreferredMaxLayoutWidth:"), preferred_width)
          end
          # Add as first arranged subview.
          LibObjCBridge.objc_send_void_id(inner, sel("addArrangedSubview:"), title_ptr)

          title_handle = ObjC.owned(title_ptr, label: "UILabel[card-title]")
          inner_native.add_child(NativeView.new(title_handle))
        end

        if content = view.content
          # Push the card stack as a uistack parent so children flow in
          # via addArrangedSubview: and are laid out / sized by the stack.
          if preferred_width = label_preferred_width
            @label_preferred_max_layout_width_stack.push(preferred_width)
            push_stack(inner_native, is_uistack: true)
            content.accept(self)
            pop_stack
            @label_preferred_max_layout_width_stack.pop
          else
            push_stack(inner_native, is_uistack: true)
            content.accept(self)
            pop_stack
          end
        end

        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Surface -> UIView (elevated surface container)
      # -----------------------------------------------------------------
      def visit(view : UI::Surface)
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
        handle = ObjC.owned(ptr, label: "UIHostingView[Surface]")
        native = NativeView.new(handle)
        children_native.each { |c| native.add_child(c) }
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: Divider -> UIView (thin separator line)
      # -----------------------------------------------------------------
      def visit(view : UI::Divider)
        overrides_ptr = LibSwiftKitBridge.apsk_divider_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_divider(target_str, view, sender)

        ptr = LibSwiftKitBridge.apsk_make_divider(overrides_ptr)
        emit(ptr, "UIHostingController[Divider]")
      end

      # -----------------------------------------------------------------
      # Visit: GlassBackground -> SwiftUI .glassEffect() (iOS 26+) /
      # `.background(<Material>)` fallback on iOS 16..25.
      #
      # Phase 3 remediation: migrated to the populator + facade flow so
      # the "headline visual differentiator" the Phase 3 README names
      # (Liquid Glass on default Card/Sheet surfaces) is wired through
      # the same default-detection cascade as every other widget.
      # -----------------------------------------------------------------
      def visit(view : UI::GlassBackground)
        # Phase 5 v2: Apple material is the DECLARED step — brand
        # intensity is advisory on Apple per I-10. Quantizer applies
        # on web + Android; on Apple, declared step wins so consumers
        # can rely on SwiftUI Material enum semantic stability.
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
        handle = ObjC.owned(ptr, label: "UIHostingController[GlassBackground]")
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
        ptr = alloc_init("UIImageView")
        # No async URL loader exists on this path; callers that want a real
        # picture pre-fetch the bytes into `preloaded_data` (see the demo
        # shell's ImageCache) and we decode them synchronously here. Bytes ride
        # in as base64 because the ObjC bridge has no (ptr, len) send — NSData
        # base64EncodedString + UIImage imageWithData: cover it.
        if data = view.preloaded_data
          b64 = Base64.strict_encode(data)
          ns_b64 = LibObjCBridge.nsstring_from_cstr(b64.to_unsafe)
          nsdata_cls = LibObjCBridge.objc_getClass("NSData")
          nsdata = LibObjCBridge.objc_send_id_long(
            LibObjCBridge.objc_send(nsdata_cls, sel("alloc")),
            sel("initWithBase64EncodedString:options:"), ns_b64, 1_i64) # 1 = ignore unknown chars
          unless nsdata.null?
            uiimage_cls = LibObjCBridge.objc_getClass("UIImage")
            img = LibObjCBridge.objc_send_id(uiimage_cls, sel("imageWithData:"), nsdata)
            LibObjCBridge.objc_send_void_id(ptr, sel("setImage:"), img) unless img.null?
          end
        end
        # ContentMode: 1 = scaleAspectFit, 2 = scaleAspectFill.
        mode = view.content_mode == UI::ContentMode::Fill ? 2_i64 : 1_i64
        LibObjCBridge.objc_send_long(ptr, sel("setContentMode:"), mode)
        LibObjCBridge.objc_send_bool(ptr, sel("setClipsToBounds:"), 1)
        # A UIImageView's intrinsic content size is the BITMAP size — a 1920px
        # photo blows out the whole layout unless the frame is pinned. An exact
        # height + aspect-fill + clips gives the web `<img object-fit: cover>`
        # behavior.
        if h = view.maximum_height
          LibObjCBridge.objc_constrain_height(ptr, h)
        end
        if w = view.maximum_width
          LibObjCBridge.objc_constrain_required_width(ptr, w)
        end
        if view.corner_radius > 0
          layer = LibObjCBridge.objc_send(ptr, sel("layer"))
          LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), view.corner_radius) unless layer.null?
        end
        apply_common_properties(ptr, view)
        emit(ptr, "UIImageView[async]")
      end

      # -----------------------------------------------------------------
      # Visit: RichText -> UITextView
      #
      # HIG "Text views": "A text view displays multiline, styled text
      # content, which can optionally be editable."
      # UIKit: UITextView provides multi-line text with scrolling.
      # Non-editable by default for read-only rich content.
      #
      # Text color: sentinel-swap applied identical to the text-fields
      # iter-48 fix.  Default Color{0,0,0,1} sentinel maps to
      # UIColor.labelColor for appearance-tracking (near-black in light,
      # near-white in dark).
      # -----------------------------------------------------------------
      def visit(view : UI::RichText)
        ptr = alloc_init("UITextView")

        # Populate text from spans.
        plain = view.plain_text
        unless plain.empty?
          text_str = LibObjCBridge.nsstring_from_cstr(plain.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setText:"), text_str)
        end

        LibObjCBridge.objc_send_bool(ptr, sel("setEditable:"), 0)
        # Disable scroll so UITextView adopts intrinsic content size in UIStackView.
        # UITextView with scrollEnabled=YES collapses to zero height in a stack
        # unless given explicit sizing constraints. scrollEnabled=NO lets the text
        # view size itself to fit its content, which is the HIG-aligned pattern
        # for embedded read-only text areas. The parent UIScrollView provides
        # scrolling for longer content.
        LibObjCBridge.objc_send_bool(ptr, sel("setScrollEnabled:"), 0)

        # Font: use first span's font if present, else system body 17pt.
        # Tier 2 platform default: 17pt = iOS HIG body label size.
        first_font = view.spans.first?.try(&.font)
        font_ptr = first_font ? resolve_font(first_font) : LibObjCBridge.nsfont_system(17.0)
        LibObjCBridge.objc_send_id(ptr, sel("setFont:"), font_ptr) unless font_ptr.null?

        # Text color: sentinel-swap for dark-mode legibility.
        first_color = view.spans.first?.try(&.color)
        if fc = first_color
          if fc.r == 0.0 && fc.g == 0.0 && fc.b == 0.0 && fc.a == 1.0
            color_ptr = LibObjCBridge.nscolor_label_primary
          else
            color_ptr = LibObjCBridge.nscolor_rgba(fc.r, fc.g, fc.b, fc.a)
          end
        else
          color_ptr = LibObjCBridge.nscolor_label_primary
        end
        LibObjCBridge.objc_send_id(ptr, sel("setTextColor:"), color_ptr)

        apply_common_properties(ptr, view)
        emit(ptr, "UITextView[rich]")
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
        handle = ObjC.owned(ptr, label: "UIHostingController[LinkButton]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: MenuButton -> UIButton
      #
      # Pop-up mode (is_pull_down: false, default):
      #   UIButton configured with the current selection label and a trailing
      #   "chevron.up.chevron.down" SF Symbol.  Styled as a capsule via
      #   UIButtonConfiguration grayButtonConfiguration.
      #   HIG: "Use a pop-up button to present a flat list of mutually exclusive
      #   options or states." -- Pop-up buttons / Best practices.
      #
      # Pull-down mode (is_pull_down: true):
      #   UIButton showing the button's own label (a verb: "Add", "Export", etc.)
      #   with a single "chevron.down" SF Symbol.  No selection label is shown;
      #   no "chevron.up" component appears.  On iOS 14+ the button uses
      #   showsMenuAsPrimaryAction = true to present a UIMenu on primary tap;
      #   in this validation renderer we construct the visual chrome directly
      #   (title + chevron.down, UIButtonConfiguration filledButtonConfiguration
      #   for :prominent, grayButtonConfiguration for :default).
      #   HIG: "Use a pull-down button to present commands or items that are
      #   directly related to the button's action." -- Pull-down buttons / Best
      #   practices.
      # -----------------------------------------------------------------
      def visit(view : UI::MenuButton)
        overrides_ptr = LibSwiftKitBridge.apsk_menu_button_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_menu_button(target_str, view, sender)

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
        handle = ObjC.owned(ptr, label: "UIHostingView[MenuButton]")
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      # Legacy UIKit MenuButton body, retained for reference.
      private def _legacy_menu_button(view : UI::MenuButton)
        uibutton_cls = LibObjCBridge.objc_getClass("UIButton")
        if view.is_pull_down
          # Pull-down: button face = view.label + chevron.down.
          config_cls = LibObjCBridge.objc_getClass("UIButtonConfiguration")
          config = if !config_cls.null?
                     if view.button_style == :prominent
                       LibObjCBridge.objc_send(config_cls, sel("filledButtonConfiguration"))
                     else
                       LibObjCBridge.objc_send(config_cls, sel("grayButtonConfiguration"))
                     end
                   else
                     Pointer(Void).null
                   end

          ptr = if !config.null?
                  LibObjCBridge.objc_send_id_id(
                    uibutton_cls,
                    sel("buttonWithConfiguration:primaryAction:"),
                    config,
                    Pointer(Void).null
                  )
                else
                  LibObjCBridge.objc_send_long(uibutton_cls, sel("buttonWithType:"), 1_i64)
                end

          title_str = LibObjCBridge.nsstring_from_cstr(view.label.to_unsafe)
          LibObjCBridge.objc_send_id_long(ptr, sel("setTitle:forState:"), title_str, 0_i64)

          # chevron.down is the canonical pull-down indicator (single chevron,
          # pointing down only -- distinguishes pull-down from pop-up).
          uiimage_cls = LibObjCBridge.objc_getClass("UIImage")
          chevron_name = "chevron.down"
          chevron_ns = LibObjCBridge.nsstring_from_cstr(chevron_name.to_unsafe)
          chevron_img = LibObjCBridge.objc_send_id(uiimage_cls, sel("systemImageNamed:"), chevron_ns)
          unless chevron_img.null?
            LibObjCBridge.objc_send_id_long(ptr, sel("setImage:forState:"), chevron_img, 0_i64)
          end

          # Wire showsMenuAsPrimaryAction (iOS 14+) so the button title's tap
          # presents the menu rather than firing a default action.
          LibObjCBridge.objc_send_bool(ptr, sel("setShowsMenuAsPrimaryAction:"), 1)

          # Accessibility: label a pull-down button distinctly from pop-up.
          acc_text = view.accessibility_label || "#{view.label}, pull-down button"
          acc_str = LibObjCBridge.nsstring_from_cstr(acc_text.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), acc_str)

          apply_common_properties(ptr, view)
          emit(ptr, "UIButton[pull-down]")
        else
          # Pop-up mode (default).
          uicolor_cls = LibObjCBridge.objc_getClass("UIColor")

          # Determine current selection label.
          current_label = if !view.items.empty? && view.selected_index < view.items.size
                            view.items[view.selected_index].label
                          else
                            view.label
                          end

          # Try UIButtonConfiguration (iOS 15+) for the capsule pop-up style.
          config_cls = LibObjCBridge.objc_getClass("UIButtonConfiguration")
          config = config_cls.null? ? Pointer(Void).null : LibObjCBridge.objc_send(config_cls, sel("grayButtonConfiguration"))

          ptr = if !config.null?
                  LibObjCBridge.objc_send_id_id(
                    uibutton_cls,
                    sel("buttonWithConfiguration:primaryAction:"),
                    config,
                    Pointer(Void).null
                  )
                else
                  LibObjCBridge.objc_send_long(uibutton_cls, sel("buttonWithType:"), 1_i64)
                end

          # Set the current selection as the button title.
          title_str = LibObjCBridge.nsstring_from_cstr(current_label.to_unsafe)
          LibObjCBridge.objc_send_id_long(ptr, sel("setTitle:forState:"), title_str, 0_i64)

          # Attach the up/down chevron SF Symbol.
          uiimage_cls = LibObjCBridge.objc_getClass("UIImage")
          chevron_name = "chevron.up.chevron.down"
          chevron_ns = LibObjCBridge.nsstring_from_cstr(chevron_name.to_unsafe)
          chevron_img = LibObjCBridge.objc_send_id(uiimage_cls, sel("systemImageNamed:"), chevron_ns)
          unless chevron_img.null?
            LibObjCBridge.objc_send_id_long(ptr, sel("setImage:forState:"), chevron_img, 0_i64)
          end

          # Accessibility label -- required on interactive elements per HIG.
          acc_text = view.accessibility_label || "#{view.label}, pop-up button"
          acc_str = LibObjCBridge.nsstring_from_cstr(acc_text.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), acc_str)

          _ = uicolor_cls
          apply_common_properties(ptr, view)
          emit(ptr, "UIButton[pop-up]")
        end
      end

      def visit(view : UI::ContextMenu)
        # Phase 5 v2 — token-driven semantic material. ContextMenu's HIG
        # canonical role is `Menu`; the iOS SDK-verified approximation
        # maps Menu to UIBlurEffectStyleSystemUltraThinMaterial = 6.
        # SystemResolved returns the -1 sentinel — when hit, the v2
        # contract REQUIRES suppressing the explicit UIBlurEffect override
        # (pass nil to UIVisualEffectView so Apple defaults apply).
        menu_semantic = UI::DesignTokens::AppleSemantic::Menu
        menu_style = uikit_blur_effect_style_for_semantic(menu_semantic)

        glass_cls = LibObjCBridge.objc_getClass("UIGlassEffect")
        blur_effect = if !glass_cls.null?
                        LibObjCBridge.objc_send(
                          LibObjCBridge.objc_send(glass_cls, sel("alloc")),
                          sel("init"))
                      elsif menu_style != -1_i64
                        ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
                        LibObjCBridge.objc_send_long(ublur_cls, sel("effectWithStyle:"), menu_style)
                      else
                        # SystemResolved sentinel — emit NO explicit
                        # UIBlurEffect. UIVisualEffectView with a nil
                        # effect renders without blur, letting Apple
                        # defaults compose downstream.
                        Pointer(Void).null
                      end

        uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
        effect_alloc = LibObjCBridge.objc_send(uveff_cls, sel("alloc"))
        effect = LibObjCBridge.objc_send_id(effect_alloc, sel("initWithEffect:"), blur_effect)
        LibObjCBridge.objc_send_bool(effect, sel("setClipsToBounds:"), 1)

        effect_layer = LibObjCBridge.objc_send(effect, sel("layer"))
        unless effect_layer.null?
          # token_radius(:sheet) (14pt) — sheet/glass-card corner.
          LibObjCBridge.objc_send_1d(effect_layer, sel("setCornerRadius:"), token_radius(:sheet))
          LibObjCBridge.objc_send_bool(effect_layer, sel("setMasksToBounds:"), 1)
        end

        inner = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(inner, sel("setAxis:"), 1_i64)
        LibObjCBridge.objc_send_1d(inner, sel("setSpacing:"), 0.0)
        LibObjCBridge.objc_send_long(inner, sel("setAlignment:"), 0_i64)
        insets = LibObjCBridge::CGRect.new(x: 8.0, y: 10.0, width: 8.0, height: 10.0)
        LibObjCBridge.objc_send_rect_void(inner, sel("setLayoutMargins:"), insets)
        LibObjCBridge.objc_send_bool(inner, sel("setLayoutMarginsRelativeArrangement:"), 1)
        LibObjCBridge.objc_send_bool(inner, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)

        content_view = LibObjCBridge.objc_send(effect, sel("contentView"))
        anchor_host = if content_view.null?
                        LibObjCBridge.objc_add_subview(effect, inner)
                        effect
                      else
                        LibObjCBridge.objc_add_subview(content_view, inner)
                        content_view
                      end

        %w(topAnchor bottomAnchor leadingAnchor trailingAnchor).each do |anchor_sel|
          inner_anchor = LibObjCBridge.objc_send(inner, sel(anchor_sel))
          host_anchor = LibObjCBridge.objc_send(anchor_host, sel(anchor_sel))
          next if inner_anchor.null? || host_anchor.null?
          constraint = LibObjCBridge.objc_send_id(inner_anchor, sel("constraintEqualToAnchor:"), host_anchor)
          LibObjCBridge.objc_send_bool(constraint, sel("setActive:"), 1) unless constraint.null?
        end

        inner_handle = ObjC.borrowed(inner, label: "UIStackView[context-menu-inner]")
        inner_native = NativeView.new(inner_handle)

        uicolor_cls = LibObjCBridge.objc_getClass("UIColor")
        destructive_color = LibObjCBridge.objc_send(uicolor_cls, sel("systemRedColor"))
        destructive_color = resolve_color(UI::Color.new(r: 1.0, g: 0.23, b: 0.19)) if destructive_color.null?

        view.items.each do |entry|
          case entry
          when UI::ContextMenu::Separator
            sep = alloc_init("UIView")
            LibObjCBridge.objc_send_id(sep, sel("setBackgroundColor:"), LibObjCBridge.nscolor_label_quaternary)
            LibObjCBridge.objc_constrain_height(sep, 1.0)
            sep_handle = ObjC.owned(sep, label: "UIView[context-menu-separator]")
            sep_native = NativeView.new(sep_handle)
            inner_native.add_child(sep_native)
            LibObjCBridge.objc_send_id(inner, sel("addArrangedSubview:"), sep)
          when UI::ContextMenu::Item
            row = alloc_init("UIStackView")
            LibObjCBridge.objc_send_long(row, sel("setAxis:"), 0_i64)
            LibObjCBridge.objc_send_1d(row, sel("setSpacing:"), 10.0)
            LibObjCBridge.objc_send_long(row, sel("setAlignment:"), 3_i64)
            row_insets = LibObjCBridge::CGRect.new(x: 8.0, y: 10.0, width: 8.0, height: 10.0)
            LibObjCBridge.objc_send_rect_void(row, sel("setLayoutMargins:"), row_insets)
            LibObjCBridge.objc_send_bool(row, sel("setLayoutMarginsRelativeArrangement:"), 1)
            LibObjCBridge.objc_constrain_height(row, 36.0)

            row_handle = ObjC.owned(row, label: "UIStackView[context-menu-row]")
            row_native = NativeView.new(row_handle)
            inner_native.add_child(row_native)

            if icon = entry.icon
              image_cls = LibObjCBridge.objc_getClass("UIImage")
              icon_ns = LibObjCBridge.nsstring_from_cstr(icon.to_unsafe)
              image = LibObjCBridge.objc_send_id(image_cls, sel("systemImageNamed:"), icon_ns)
              unless image.null?
                image_view = alloc_init("UIImageView")
                LibObjCBridge.objc_send_id(image_view, sel("setImage:"), image)
                tint = if entry.is_destructive
                         destructive_color
                       elsif entry.is_disabled
                         LibObjCBridge.nscolor_label_tertiary
                       else
                         LibObjCBridge.nscolor_label_secondary
                       end
                LibObjCBridge.objc_send_id(image_view, sel("setTintColor:"), tint) unless tint.null?
                LibObjCBridge.objc_constrain_size(image_view, 16.0, 16.0)
                image_handle = ObjC.owned(image_view, label: "UIImageView[context-menu-icon]")
                image_native = NativeView.new(image_handle)
                row_native.add_child(image_native)
                LibObjCBridge.objc_send_id(row, sel("addArrangedSubview:"), image_view)
              end
            end

            label = alloc_init("UILabel")
            label_str = LibObjCBridge.nsstring_from_cstr(entry.label.to_unsafe)
            LibObjCBridge.objc_send_id(label, sel("setText:"), label_str)
            # Tier 2 platform default: 17pt = iOS HIG body label size.
            LibObjCBridge.objc_send_id(label, sel("setFont:"), LibObjCBridge.nsfont_system(17.0))
            text_color = if entry.is_destructive
                           destructive_color
                         elsif entry.is_disabled
                           LibObjCBridge.nscolor_label_tertiary
                         else
                           LibObjCBridge.nscolor_label_primary
                         end
            LibObjCBridge.objc_send_id(label, sel("setTextColor:"), text_color) unless text_color.null?
            label_handle = ObjC.owned(label, label: "UILabel[context-menu-label]")
            label_native = NativeView.new(label_handle)
            row_native.add_child(label_native)
            LibObjCBridge.objc_send_id(row, sel("addArrangedSubview:"), label)

            LibObjCBridge.objc_send_id(inner, sel("addArrangedSubview:"), row)
          end
        end

        ax_text = view.accessibility_label || "Context menu"
        ax_str = LibObjCBridge.nsstring_from_cstr(ax_text.to_unsafe)
        LibObjCBridge.objc_send_id(effect, sel("setAccessibilityLabel:"), ax_str)

        apply_common_properties(effect, view)
        outer_handle = ObjC.owned(effect, label: "UIVisualEffectView[context-menu]")
        outer_native = NativeView.new(outer_handle)
        outer_native.add_child(inner_native)
        push_native(outer_native)
      end

      def visit(view : UI::ToggleButton)
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
        handle = ObjC.owned(ptr, label: "UIHostingView[ToggleButton]")
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
          # The SwiftUI facade reuses TextStorage, whose binding fires
          # CallbackBridge.fireString(token, value) with the REAL typed
          # text. Register on the STRING channel so the handler receives
          # the actual text — NOT the numeric channel + call(""), which
          # silently dropped every keystroke (the SecureField bug class).
          action_token = UI::CallbackRegistry.register_string(change_handler)
        end

        ptr = LibSwiftKitBridge.apsk_make_text_editor(
          view.placeholder.to_unsafe, view.text.to_unsafe,
          overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingController[TextEditor]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # P3 Stub Visit methods
      # -----------------------------------------------------------------

      def visit(view : UI::Circle)
        ptr = alloc_init("UIView")
        bg_color = resolve_color(view.fill_color)
        LibObjCBridge.objc_send_id(ptr, sel("setBackgroundColor:"), bg_color)
        layer = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer.null?
          LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), view.size / 2.0)
          if sc = view.stroke_color
            LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), view.stroke_width)
            border_color = resolve_color(sc)
            cg_border = LibObjCBridge.objc_send(border_color, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setBorderColor:"), cg_border)
          end
        end
        LibObjCBridge.objc_send_bool(ptr, sel("setClipsToBounds:"), 1)
        apply_common_properties(ptr, view)
        emit(ptr, "UIView[circle]")
      end

      def visit(view : UI::Rectangle)
        ptr = alloc_init("UIView")
        bg_color = resolve_color(view.fill_color)
        LibObjCBridge.objc_send_id(ptr, sel("setBackgroundColor:"), bg_color)
        layer = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer.null?
          if sc = view.stroke_color
            LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), view.stroke_width)
            border_color = resolve_color(sc)
            cg_border = LibObjCBridge.objc_send(border_color, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setBorderColor:"), cg_border)
          end
        end
        apply_common_properties(ptr, view)
        emit(ptr, "UIView[rectangle]")
      end

      def visit(view : UI::RoundedRectangle)
        ptr = alloc_init("UIView")
        bg_color = resolve_color(view.fill_color)
        LibObjCBridge.objc_send_id(ptr, sel("setBackgroundColor:"), bg_color)
        layer = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer.null?
          LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), view.corner_radius)
          if sc = view.stroke_color
            LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), view.stroke_width)
            border_color = resolve_color(sc)
            cg_border = LibObjCBridge.objc_send(border_color, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setBorderColor:"), cg_border)
          end
        end
        LibObjCBridge.objc_send_bool(ptr, sel("setClipsToBounds:"), 1)
        apply_common_properties(ptr, view)
        emit(ptr, "UIView[rounded-rectangle]")
      end

      def visit(view : UI::Capsule)
        ptr = alloc_init("UIView")
        bg_color = resolve_color(view.fill_color)
        LibObjCBridge.objc_send_id(ptr, sel("setBackgroundColor:"), bg_color)
        layer = LibObjCBridge.objc_send(ptr, sel("layer"))
        unless layer.null?
          LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), view.height / 2.0)
          if sc = view.stroke_color
            LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), view.stroke_width)
            border_color = resolve_color(sc)
            cg_border = LibObjCBridge.objc_send(border_color, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setBorderColor:"), cg_border)
          end
        end
        LibObjCBridge.objc_send_bool(ptr, sel("setClipsToBounds:"), 1)
        apply_common_properties(ptr, view)
        emit(ptr, "UIView[capsule]")
      end

      def visit(view : UI::Canvas)
        # Keep the optimized ring special-case (used by ActivityRing); fall
        # back to a general op-stream replay instead of a blank UIView.
        ptr = native_ring_canvas_view(view)
        if ptr.null?
          ops = view.operations
          flat = Array(Float64).new(ops.size * 14)
          ops.each do |op|
            cmd = case op.command
                  when UI::DrawCommand::MoveTo         then 0.0
                  when UI::DrawCommand::LineTo         then 1.0
                  when UI::DrawCommand::Arc            then 2.0
                  when UI::DrawCommand::QuadCurveTo    then 3.0
                  when UI::DrawCommand::BezierCurveTo  then 4.0
                  when UI::DrawCommand::ClosePath      then 5.0
                  when UI::DrawCommand::Fill           then 6.0
                  when UI::DrawCommand::Stroke         then 7.0
                  when UI::DrawCommand::SetFillColor   then 8.0
                  when UI::DrawCommand::SetStrokeColor then 9.0
                  when UI::DrawCommand::SetLineWidth   then 10.0
                  when UI::DrawCommand::BeginPath      then 11.0
                  else                                      0.0
                  end
            c = op.color
            flat << cmd << op.x << op.y << op.x2 << op.y2 << op.x3 << op.y3 \
              << op.radius << op.start_angle << op.end_angle \
              << c.r << c.g << c.b << c.a
          end
          ptr = LibObjCBridge.ap_canvas_view_new(view.width, view.height, flat.to_unsafe, ops.size)
          ptr = alloc_init("UIView") if ptr.null?
          LibObjCBridge.objc_constrain_size(ptr, view.width, view.height)
        end
        apply_common_properties(ptr, view)
        emit(ptr, "UIView[canvas]")
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
        emit(ptr, "UIView[activity-rings]")
      end

      def visit(view : UI::PathView)
        # Serialize segments into a flat Float64 array (7 per segment:
        # command, x, y, cx1, cy1, cx2, cy2) and hand them to the native
        # CAShapeLayer builder. command codes mirror ap_path_view_new:
        # 0=MoveTo 1=LineTo 2=QuadCurveTo 3=CurveTo 4=Close.
        segs = view.segments
        flat = Array(Float64).new(segs.size * 7)
        segs.each do |s|
          cmd = case s.command
                when UI::PathCommand::MoveTo      then 0.0
                when UI::PathCommand::LineTo      then 1.0
                when UI::PathCommand::QuadCurveTo then 2.0
                when UI::PathCommand::CurveTo     then 3.0
                when UI::PathCommand::Close       then 4.0
                else                                   1.0
                end
          flat << cmd << s.x << s.y << s.control_x1 << s.control_y1 << s.control_x2 << s.control_y2
        end

        fill = view.fill_color
        has_fill = fill ? 1 : 0
        fr = fill ? fill.r : 0.0
        fg = fill ? fill.g : 0.0
        fb = fill ? fill.b : 0.0
        fa = fill ? fill.a : 0.0
        stroke = view.stroke_color

        ptr = LibObjCBridge.ap_path_view_new(
          view.width, view.height,
          flat.to_unsafe, segs.size, has_fill,
          fr, fg, fb, fa,
          stroke.r, stroke.g, stroke.b, stroke.a,
          view.stroke_width,
        )
        ptr = alloc_init("UIView") if ptr.null?
        LibObjCBridge.objc_constrain_size(ptr, view.width, view.height)
        apply_common_properties(ptr, view)
        emit(ptr, "UIView[path]")
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
        ptr = alloc_init("UIView") if ptr.null?

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
        apply_default_surface_size(ptr, view, 320.0, 220.0)
        emit(ptr, "MKMapView")
      end

      # -----------------------------------------------------------------
      # Visit: ChartView -> UIStackView-based bar / line chart
      #
      # HIG Charts: "Organize data in a chart to communicate information
      # with clarity and visual appeal." Same rendering strategy as the
      # AppKit renderer — UIStackViews compose bars and labels without
      # requiring Core Graphics drawing primitives.
      # -----------------------------------------------------------------
      def visit(view : UI::ChartView)
        # UIKit: do NOT use ENV[] here -- accessing ENV from within a UIKit
        # layout callback crashes Crystal's thread initializer on iOS (the
        # Crystal env lock is lazily initialized and requires Crystal's fiber
        # subsystem to be set up, which may not yet be the case when SwiftUI
        # calls makeUIView from its layout pass).
        # Instead, use static appearance-independent colors for UIKit; the
        # UIView CALayer accepts UIColor.CGColor and UITraitCollection tracks
        # appearance automatically for semantic colors.

        chart_w = 340.0
        chart_h = 220.0
        plot_h = 160.0
        bar_spacing = 8.0
        label_h = 24.0

        # Use neutral values that work in both appearances.
        # Background: clear (transparent) lets the hosting VC background show.
        # Bar area: subtle gray -- 0.92 alpha works in light; dark mode uses
        # UITraitCollection overrideUserInterfaceStyle, so the system bar area
        # background adapts via UIColor.secondarySystemBackground semantics.
        # We bake a single set of values. The UIKit renderer applies
        # overrideUserInterfaceStyle on the host window level for dark-mode
        # captures, so system colors track appearance automatically.
        bar_area_bg = 0.94 # ~systemGroupedBackground light equivalent

        # System blue (light equivalent) -- UIView CALayer backgroundColor
        # does NOT track traitCollection, so we must bake a value. Use the
        # light-mode system blue; the dark capture uses the same value.
        # For the validation captures this gives blue bars in both captures,
        # which is legible. A production app would use UIColor dynamic provider.
        bar_r = 0.0
        bar_g = 0.478
        bar_b = 1.0
        bar_a = 1.0

        line_r = 1.0
        line_g = 0.58
        line_b = 0.0
        line_a = 1.0

        grid_gray = 0.75
        lbl_gray = 0.15

        # Outer UIStackView (vertical). UIView is always layer-backed on iOS;
        # setWantsLayer: is AppKit-only and must NOT be called on UIView.
        outer = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(outer, sel("setAxis:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(outer, sel("setSpacing:"), 6.0)
        LibObjCBridge.objc_send_long(outer, sel("setAlignment:"), 3_i64) # center

        # TAMIC = NO is required before adding explicit Auto Layout constraints.
        # Without this, UIKit generates autoresizing mask constraints that conflict
        # with the explicit width/height anchors from objc_constrain_size, causing
        # the layout engine to resolve the conflict by collapsing the view to zero.
        LibObjCBridge.objc_send_bool(outer, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)

        # Explicit size: 340pt wide, 220pt tall. UIStackView has no intrinsic
        # content size that the parent UIStackView can use -- only its arranged
        # subviews contribute. Without this constraint the chart collapses to
        # zero height in any parent UIStackView.
        LibObjCBridge.objc_constrain_size(outer, chart_w, chart_h)

        # Title
        unless view.title.empty?
          title_lbl = alloc_init("UILabel")
          title_str = LibObjCBridge.nsstring_from_cstr(view.title.to_unsafe)
          LibObjCBridge.objc_send_id(title_lbl, sel("setText:"), title_str)
          title_font = LibObjCBridge.nsfont_system_weight(14.0, 0.4)
          LibObjCBridge.objc_send_id(title_lbl, sel("setFont:"), title_font)
          # Use UIColor.labelColor (appearance-tracking semantic color) for the
          # title so it renders near-black in light and near-white in dark.
          # nscolor_label_primary is safe to call here (no Crystal ENV access).
          title_color = LibObjCBridge.nscolor_label_primary
          LibObjCBridge.objc_send_id(title_lbl, sel("setTextColor:"), title_color)
          LibObjCBridge.objc_send_long(title_lbl, sel("setTextAlignment:"), 1_i64) # center
          LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), title_lbl)
        end

        pts = view.data_points
        max_val = pts.empty? ? 1.0 : pts.map(&.value).max
        max_val = 1.0 if max_val <= 0.0

        if view.chart_type == :bar
          plot_stack = alloc_init("UIStackView")
          LibObjCBridge.objc_send_long(plot_stack, sel("setAxis:"), 0_i64) # horizontal
          LibObjCBridge.objc_send_1d(plot_stack, sel("setSpacing:"), bar_spacing)
          LibObjCBridge.objc_send_long(plot_stack, sel("setAlignment:"), 4_i64) # bottom

          plot_layer = LibObjCBridge.objc_send(plot_stack, sel("layer"))
          unless plot_layer.null?
            pa_bg = LibObjCBridge.nscolor_rgba(bar_area_bg, bar_area_bg, bar_area_bg, 1.0)
            unless pa_bg.null?
              pa_cg = LibObjCBridge.objc_send(pa_bg, sel("CGColor"))
              LibObjCBridge.objc_send_void_id(plot_layer, sel("setBackgroundColor:"), pa_cg) unless pa_cg.null?
            end
            # token_radius(:lg) (8pt) — plot area background corner.
            LibObjCBridge.objc_send_1d(plot_layer, sel("setCornerRadius:"), token_radius(:lg))
          end
          LibObjCBridge.objc_constrain_size(plot_stack, chart_w - 16.0, plot_h + label_h + 4.0)

          n_pts = pts.size
          bar_w = n_pts > 0 ? ((chart_w - 16.0 - bar_spacing * (n_pts - 1).to_f) / n_pts.to_f).clamp(8.0, 56.0) : 36.0

          pts.each_with_index do |pt, _i|
            norm = max_val > 0 ? pt.value / max_val : 0.0
            bar_h = (norm * (plot_h - 8.0)).clamp(2.0, plot_h - 8.0)

            col = alloc_init("UIStackView")
            LibObjCBridge.objc_send_long(col, sel("setAxis:"), 1_i64) # vertical
            LibObjCBridge.objc_send_1d(col, sel("setSpacing:"), 2.0)
            LibObjCBridge.objc_send_long(col, sel("setAlignment:"), 3_i64) # center
            LibObjCBridge.objc_constrain_width(col, bar_w)

            spacer_v = alloc_init("UIView")
            spacer_h = (plot_h - bar_h - 8.0).clamp(0.0, plot_h)
            LibObjCBridge.objc_constrain_size(spacer_v, bar_w, spacer_h)
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), spacer_v)

            bar_v = alloc_init("UIView")
            LibObjCBridge.objc_constrain_size(bar_v, bar_w, bar_h)
            bar_layer = LibObjCBridge.objc_send(bar_v, sel("layer"))
            unless bar_layer.null?
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

            lbl = alloc_init("UILabel")
            lbl_str = LibObjCBridge.nsstring_from_cstr(pt.label.to_unsafe)
            LibObjCBridge.objc_send_id(lbl, sel("setText:"), lbl_str)
            # Tier 2 platform default: 10pt = UIFont caption2 micro-label size
            # for chart axis labels — smaller than the brand caption (12.5pt).
            lbl_font = LibObjCBridge.nsfont_system(10.0)
            LibObjCBridge.objc_send_id(lbl, sel("setFont:"), lbl_font)
            lbl_color = LibObjCBridge.nscolor_label_secondary
            LibObjCBridge.objc_send_id(lbl, sel("setTextColor:"), lbl_color)
            LibObjCBridge.objc_send_long(lbl, sel("setTextAlignment:"), 1_i64) # center
            LibObjCBridge.objc_constrain_height(lbl, label_h)
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), lbl)

            LibObjCBridge.objc_send_id(plot_stack, sel("addArrangedSubview:"), col)
          end

          LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), plot_stack)
        elsif view.chart_type == :line
          plot_stack = alloc_init("UIStackView")
          LibObjCBridge.objc_send_long(plot_stack, sel("setAxis:"), 0_i64)
          LibObjCBridge.objc_send_1d(plot_stack, sel("setSpacing:"), 4.0)
          LibObjCBridge.objc_send_long(plot_stack, sel("setAlignment:"), 4_i64)

          plot_layer = LibObjCBridge.objc_send(plot_stack, sel("layer"))
          unless plot_layer.null?
            pa_bg = LibObjCBridge.nscolor_rgba(bar_area_bg, bar_area_bg, bar_area_bg, 1.0)
            unless pa_bg.null?
              pa_cg = LibObjCBridge.objc_send(pa_bg, sel("CGColor"))
              LibObjCBridge.objc_send_void_id(plot_layer, sel("setBackgroundColor:"), pa_cg) unless pa_cg.null?
            end
            # token_radius(:lg) (8pt) — line plot background corner.
            LibObjCBridge.objc_send_1d(plot_layer, sel("setCornerRadius:"), token_radius(:lg))
          end
          LibObjCBridge.objc_constrain_size(plot_stack, chart_w - 16.0, plot_h + label_h + 4.0)

          n_pts = pts.size
          col_w = n_pts > 0 ? ((chart_w - 16.0 - 4.0 * (n_pts - 1).to_f) / n_pts.to_f).clamp(8.0, 56.0) : 36.0

          pts.each_with_index do |pt, _i|
            norm = max_val > 0 ? pt.value / max_val : 0.0
            dot_h = (norm * (plot_h - 16.0)).clamp(4.0, plot_h - 16.0)

            col = alloc_init("UIStackView")
            LibObjCBridge.objc_send_long(col, sel("setAxis:"), 1_i64)
            LibObjCBridge.objc_send_1d(col, sel("setSpacing:"), 2.0)
            LibObjCBridge.objc_send_long(col, sel("setAlignment:"), 3_i64)
            LibObjCBridge.objc_constrain_width(col, col_w)

            spacer_v = alloc_init("UIView")
            spacer_h = (plot_h - dot_h - 16.0).clamp(0.0, plot_h)
            LibObjCBridge.objc_constrain_size(spacer_v, col_w, spacer_h)
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), spacer_v)

            dot_v = alloc_init("UIView")
            dot_size = 8.0
            LibObjCBridge.objc_constrain_size(dot_v, dot_size, dot_size)
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

            stem_h = dot_h - dot_size
            if stem_h > 0
              stem_v = alloc_init("UIView")
              LibObjCBridge.objc_constrain_size(stem_v, 2.0, stem_h)
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

            lbl = alloc_init("UILabel")
            lbl_str = LibObjCBridge.nsstring_from_cstr(pt.label.to_unsafe)
            LibObjCBridge.objc_send_id(lbl, sel("setText:"), lbl_str)
            # Tier 2 platform default: 10pt = UIFont caption2 micro-label size
            # for chart axis labels — smaller than the brand caption (12.5pt).
            lbl_font = LibObjCBridge.nsfont_system(10.0)
            LibObjCBridge.objc_send_id(lbl, sel("setFont:"), lbl_font)
            lbl_color = LibObjCBridge.nscolor_label_secondary
            LibObjCBridge.objc_send_id(lbl, sel("setTextColor:"), lbl_color)
            LibObjCBridge.objc_send_long(lbl, sel("setTextAlignment:"), 1_i64)
            LibObjCBridge.objc_constrain_height(lbl, label_h)
            LibObjCBridge.objc_send_id(col, sel("addArrangedSubview:"), lbl)

            LibObjCBridge.objc_send_id(plot_stack, sel("addArrangedSubview:"), col)
          end

          LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), plot_stack)
        else
          # :pie placeholder
          pie_v = alloc_init("UIView")
          LibObjCBridge.objc_constrain_size(pie_v, 120.0, 120.0)
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

        # Baseline separator
        grid_v = alloc_init("UIView")
        LibObjCBridge.objc_constrain_size(grid_v, chart_w - 16.0, 1.0)
        grid_layer = LibObjCBridge.objc_send(grid_v, sel("layer"))
        unless grid_layer.null?
          grid_col = LibObjCBridge.nscolor_rgba(grid_gray, grid_gray, grid_gray, 1.0)
          unless grid_col.null?
            grid_cg = LibObjCBridge.objc_send(grid_col, sel("CGColor"))
            LibObjCBridge.objc_send_void_id(grid_layer, sel("setBackgroundColor:"), grid_cg) unless grid_cg.null?
          end
        end
        LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), grid_v)

        # Accessibility
        ax_label = view.accessibility_label || (view.title.empty? ? "Chart" : "Chart: #{view.title}")
        ax_str = LibObjCBridge.nsstring_from_cstr(ax_label.to_unsafe)
        LibObjCBridge.objc_send_id(outer, sel("setAccessibilityLabel:"), ax_str)

        apply_common_properties(outer, view)
        emit(outer, "UIStackView[chart]")
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
        ptr = alloc_init("UIView") if ptr.null?

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
        apply_default_surface_size(ptr, view, 320.0, 280.0)

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

        # The Swift ColorStorage binding fires CallbackBridge.fireString(
        # token, "r,g,b,a") with the NEW pick (sRGB 0..1). Register on the
        # STRING channel and parse the RGBA back into a UI::Color, calling
        # the original on_change with the actual picked colour. (Previously
        # register_action_with_value re-emitted the ORIGINAL selected_color
        # — the pick was dropped.)
        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_string(->(payload : String) {
            if color = UI::ColorPicker.parse_rgba(payload)
              change_handler.call(color)
            end
            nil
          })
        end

        c = view.selected_color
        ptr = LibSwiftKitBridge.apsk_make_color_picker(
          view.label.to_unsafe, c.r, c.g, c.b, c.a, overrides_ptr, action_token,
        )
        handle = ObjC.owned(ptr, label: "UIHostingController[ColorPicker]")
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
        ptr = alloc_init("UIView") if ptr.null?

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
        apply_default_surface_size(ptr, view, 320.0, 180.0)
        emit(ptr, "AVPlayerViewController")
      end

      def visit(view : UI::Tooltip)
        ptr = alloc_init("UIView")
        unless view.text.empty?
          tooltip_str = LibObjCBridge.nsstring_from_cstr(view.text.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), tooltip_str)
        end
        apply_common_properties(ptr, view)
        handle = ObjC.owned(ptr, label: "UIView[tooltip]")
        native = NativeView.new(handle)
        if content = view.content
          push_stack(native, is_uistack: false)
          content.accept(self)
          pop_stack
        end
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: ActivityView -> UIVisualEffectView + four layout zones
      #
      # Production note: when `view.is_presented` is true and a share payload
      # exists, the renderer presents a real UIActivityViewController. The inline
      # layout below still renders all four HIG zones for validation and preview
      # flows so the component remains inspectable in screenshots.
      #
      # Material: UIGlassEffect (iOS 26) or
      #           UIBlurEffect(systemChromeMaterial=11) fallback.
      # -----------------------------------------------------------------
      def visit(view : UI::ActivityView)
        # Amber gold tint — applied to all destination icon UIButtons, action icon
        # UIButtons, and the Cancel UIButton so the ActivityView renders in the Amber
        # brand accent rather than the default systemBlue. Routes through the
        # token shim so a brand override on `design_tokens` cascades here too.
        # UIButton.tintColor routes template-mode SF Symbol images through the color.
        amber_gold = amber_brand_gold

        # Phase 5 v2 — token-driven semantic material. ActivityView's HIG-
        # canonical role is `Sheet`; the iOS SDK-verified approximation
        # maps Sheet to UIBlurEffectStyleSystemThickMaterial = 9.
        # SystemResolved (-1) suppresses the explicit override per the v2
        # contract (passes nil to UIVisualEffectView).
        activity_semantic = UI::DesignTokens::AppleSemantic::Sheet
        activity_style = uikit_blur_effect_style_for_semantic(activity_semantic)

        # Build the glass surface effect (same pattern as visit(UI::Sheet)).
        glass_cls = LibObjCBridge.objc_getClass("UIGlassEffect")
        blur_effect = if !glass_cls.null?
                        LibObjCBridge.objc_send(
                          LibObjCBridge.objc_send(glass_cls, sel("alloc")),
                          sel("init"))
                      elsif activity_style != -1_i64
                        ublur_cls = LibObjCBridge.objc_getClass("UIBlurEffect")
                        LibObjCBridge.objc_send_long(ublur_cls, sel("effectWithStyle:"), activity_style)
                      else
                        # SystemResolved sentinel — emit NO explicit
                        # UIBlurEffect. Apple defaults apply.
                        Pointer(Void).null
                      end

        uveff_cls = LibObjCBridge.objc_getClass("UIVisualEffectView")
        effect_alloc = LibObjCBridge.objc_send(uveff_cls, sel("alloc"))
        effect = LibObjCBridge.objc_send_id(effect_alloc, sel("initWithEffect:"), blur_effect)

        LibObjCBridge.objc_send_bool(effect, sel("setClipsToBounds:"), 1)
        eff_layer = LibObjCBridge.objc_send(effect, sel("layer"))
        unless eff_layer.null?
          # token_radius(:x2l) (16pt) — large glass card corner (ActivityView).
          LibObjCBridge.objc_send_1d(eff_layer, sel("setCornerRadius:"), token_radius(:x2l))
          # setMaskedCorners: 15 (all four: layerMinXMinYCorner | layerMaxXMinYCorner |
          # layerMinXMaxYCorner | layerMaxXMaxYCorner). Without the explicit mask some
          # SDK versions leave the top-left corner flat when UIGlassEffect is the effect.
          LibObjCBridge.objc_send_ulong(eff_layer, sel("setMaskedCorners:"), 15_u64)
          LibObjCBridge.objc_send_bool(eff_layer, sel("setMasksToBounds:"), 1)
          # 0.5pt hairline border using UIColor.separatorColor so the card rim is
          # visible in dark-mode captures where the glass tint and backdrop are
          # isoluminant. Matches the fix applied to visit(UI::Sheet) in iter-6.
          uicolor_cls_act = LibObjCBridge.objc_getClass("UIColor")
          sep_color_act = LibObjCBridge.objc_send(uicolor_cls_act, sel("separatorColor"))
          unless sep_color_act.null?
            cg_sep_act = LibObjCBridge.objc_send(sep_color_act, sel("CGColor"))
            unless cg_sep_act.null?
              LibObjCBridge.objc_send_1d(eff_layer, sel("setBorderWidth:"), 0.5)
              LibObjCBridge.objc_send_id(eff_layer, sel("setBorderColor:"), cg_sep_act)
            end
          end
        end

        content_view = LibObjCBridge.objc_send(effect, sel("contentView"))
        anchor_host = content_view.null? ? effect : content_view

        # Outer vertical UIStackView hosts all four zones.
        outer_stack = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(outer_stack, sel("setAxis:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(outer_stack, sel("setSpacing:"), 12.0)
        LibObjCBridge.objc_send_long(outer_stack, sel("setAlignment:"), 0_i64) # fill
        insets = LibObjCBridge::CGRect.new(x: 16.0, y: 16.0, width: 16.0, height: 16.0)
        LibObjCBridge.objc_send_rect_void(outer_stack, sel("setLayoutMargins:"), insets)
        LibObjCBridge.objc_send_bool(outer_stack, sel("setLayoutMarginsRelativeArrangement:"), 1)
        LibObjCBridge.objc_send_bool(outer_stack, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
        LibObjCBridge.objc_add_subview(anchor_host, outer_stack)

        %w(topAnchor bottomAnchor leadingAnchor trailingAnchor).each do |anch|
          ia = LibObjCBridge.objc_send(outer_stack, sel(anch))
          ha = LibObjCBridge.objc_send(anchor_host, sel(anch))
          next if ia.null? || ha.null?
          c = LibObjCBridge.objc_send_id(ia, sel("constraintEqualToAnchor:"), ha)
          LibObjCBridge.objc_send_bool(c, sel("setActive:"), 1) unless c.null?
        end

        # --- Zone 1: Header (thumbnail + VStack(title, subtitle)) ---
        header_stack = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(header_stack, sel("setAxis:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(header_stack, sel("setSpacing:"), 12.0)
        LibObjCBridge.objc_send_long(header_stack, sel("setAlignment:"), 3_i64) # center

        if thumb = view.thumbnail
          thumb_view = alloc_init("UIImageView")
          LibObjCBridge.objc_send_bool(thumb_view, sel("setClipsToBounds:"), 1)
          tl = LibObjCBridge.objc_send(thumb_view, sel("layer"))
          unless tl.null?
            # token_radius(:lg) (8pt) — thumbnail corner.
            LibObjCBridge.objc_send_1d(tl, sel("setCornerRadius:"), token_radius(:lg))
          end
          LibObjCBridge.objc_send_id(header_stack, sel("addArrangedSubview:"), thumb_view)
        end

        text_stack = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(text_stack, sel("setAxis:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(text_stack, sel("setSpacing:"), 2.0)

        title_lbl = alloc_init("UILabel")
        title_str = LibObjCBridge.nsstring_from_cstr(view.title.to_unsafe)
        LibObjCBridge.objc_send_id(title_lbl, sel("setText:"), title_str)
        title_font = LibObjCBridge.nsfont_system_weight(15.0, 0.4)
        LibObjCBridge.objc_send_id(title_lbl, sel("setFont:"), title_font) unless title_font.null?
        lbl_color = LibObjCBridge.nscolor_label_primary
        LibObjCBridge.objc_send_id(title_lbl, sel("setTextColor:"), lbl_color) unless lbl_color.null?
        LibObjCBridge.objc_send_id(text_stack, sel("addArrangedSubview:"), title_lbl)

        if sub = view.subtitle
          sub_lbl = alloc_init("UILabel")
          sub_str = LibObjCBridge.nsstring_from_cstr(sub.to_unsafe)
          LibObjCBridge.objc_send_id(sub_lbl, sel("setText:"), sub_str)
          # Tier 2 platform default: 13pt = UIFont subheadline size.
          sub_font = LibObjCBridge.nsfont_system(13.0)
          LibObjCBridge.objc_send_id(sub_lbl, sel("setFont:"), sub_font) unless sub_font.null?
          sec_color = LibObjCBridge.nscolor_label_secondary
          LibObjCBridge.objc_send_id(sub_lbl, sel("setTextColor:"), sec_color) unless sec_color.null?
          LibObjCBridge.objc_send_id(text_stack, sel("addArrangedSubview:"), sub_lbl)
        end

        LibObjCBridge.objc_send_id(header_stack, sel("addArrangedSubview:"), text_stack)
        LibObjCBridge.objc_send_id(outer_stack, sel("addArrangedSubview:"), header_stack)

        # --- Zone 2: Destination row (horizontal UIStackView of circular icons) ---
        # Use a plain UIStackView as a direct arranged subview (not wrapped in
        # UIScrollView) so the stack auto-sizes and the outer UIStackView can
        # measure it. UIScrollView with un-constrained content collapses to zero
        # height in a UIStackView context, making zone 2 invisible.
        dest_row = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(dest_row, sel("setAxis:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(dest_row, sel("setSpacing:"), 16.0)
        LibObjCBridge.objc_send_long(dest_row, sel("setAlignment:"), 1_i64) # top

        view.destinations.each do |dest|
          dest_vstack = alloc_init("UIStackView")
          LibObjCBridge.objc_send_long(dest_vstack, sel("setAxis:"), 1_i64) # vertical
          LibObjCBridge.objc_send_1d(dest_vstack, sel("setSpacing:"), 4.0)
          LibObjCBridge.objc_send_long(dest_vstack, sel("setAlignment:"), 3_i64) # center

          # Circular icon button (~60pt)
          uibtn_cls = LibObjCBridge.objc_getClass("UIButton")
          icon_btn = LibObjCBridge.objc_send_long(uibtn_cls, sel("buttonWithType:"), 1_i64)
          dest_sym_ns = LibObjCBridge.nsstring_from_cstr(dest.icon_symbol.to_unsafe)
          dest_uiimg = LibObjCBridge.objc_send_id(
            LibObjCBridge.objc_getClass("UIImage"),
            sel("systemImageNamed:"), dest_sym_ns)
          LibObjCBridge.objc_send_id_long(icon_btn, sel("setImage:forState:"), dest_uiimg, 0_i64) unless dest_uiimg.null?
          # Amber gold tint: UIButton.tintColor routes template-mode SF Symbol through
          # the color, replacing systemBlue with Amber gold (#FFAD33).
          LibObjCBridge.objc_send_id(icon_btn, sel("setTintColor:"), amber_gold) unless amber_gold.null?
          LibObjCBridge.objc_send_bool(icon_btn, sel("setClipsToBounds:"), 1)
          ibtn_layer = LibObjCBridge.objc_send(icon_btn, sel("layer"))
          unless ibtn_layer.null?
            # token_radius(:avatar) (30pt) — 60pt destination icon button (half-side).
            LibObjCBridge.objc_send_1d(ibtn_layer, sel("setCornerRadius:"), token_radius(:avatar))
          end
          LibObjCBridge.objc_send_id(dest_vstack, sel("addArrangedSubview:"), icon_btn)

          # Label below icon
          dest_lbl = alloc_init("UILabel")
          dest_lbl_str = LibObjCBridge.nsstring_from_cstr(dest.label.to_unsafe)
          LibObjCBridge.objc_send_id(dest_lbl, sel("setText:"), dest_lbl_str)
          # Tier 2 platform default: 11pt = UIFont caption1 size for destination
          # button labels.
          dest_font = LibObjCBridge.nsfont_system(11.0)
          LibObjCBridge.objc_send_id(dest_lbl, sel("setFont:"), dest_font) unless dest_font.null?
          sec2 = LibObjCBridge.nscolor_label_secondary
          LibObjCBridge.objc_send_id(dest_lbl, sel("setTextColor:"), sec2) unless sec2.null?
          LibObjCBridge.objc_send_long(dest_lbl, sel("setTextAlignment:"), 1_i64) # center
          LibObjCBridge.objc_send_id(dest_vstack, sel("addArrangedSubview:"), dest_lbl)

          LibObjCBridge.objc_send_id(dest_row, sel("addArrangedSubview:"), dest_vstack)
        end

        LibObjCBridge.objc_send_id(outer_stack, sel("addArrangedSubview:"), dest_row)

        # --- Zone 3: Action grid (2-col UIStackView pairs) ---
        grid_vstack = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(grid_vstack, sel("setAxis:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(grid_vstack, sel("setSpacing:"), 8.0)

        actions = view.actions
        row_idx = 0
        while row_idx < actions.size
          pair_row = alloc_init("UIStackView")
          LibObjCBridge.objc_send_long(pair_row, sel("setAxis:"), 0_i64) # horizontal
          LibObjCBridge.objc_send_1d(pair_row, sel("setSpacing:"), 8.0)
          LibObjCBridge.objc_send_long(pair_row, sel("setDistribution:"), 3_i64) # fillEqually

          [actions[row_idx]?, actions[row_idx + 1]?].each do |act|
            next unless act

            tile = alloc_init("UIStackView")
            LibObjCBridge.objc_send_long(tile, sel("setAxis:"), 0_i64) # horizontal
            LibObjCBridge.objc_send_1d(tile, sel("setSpacing:"), 8.0)
            LibObjCBridge.objc_send_long(tile, sel("setAlignment:"), 3_i64) # center
            LibObjCBridge.objc_send_bool(tile, sel("setClipsToBounds:"), 1)
            tile_layer = LibObjCBridge.objc_send(tile, sel("layer"))
            unless tile_layer.null?
              # token_radius(:card) (10pt) — action tile corner.
              LibObjCBridge.objc_send_1d(tile_layer, sel("setCornerRadius:"), token_radius(:card))
            end

            act_btn2 = LibObjCBridge.objc_send_long(
              LibObjCBridge.objc_getClass("UIButton"), sel("buttonWithType:"), 1_i64)
            act_sym_ns2 = LibObjCBridge.nsstring_from_cstr(act.icon_symbol.to_unsafe)
            act_uiimg = LibObjCBridge.objc_send_id(
              LibObjCBridge.objc_getClass("UIImage"),
              sel("systemImageNamed:"), act_sym_ns2)
            LibObjCBridge.objc_send_id_long(act_btn2, sel("setImage:forState:"), act_uiimg, 0_i64) unless act_uiimg.null?
            # Amber gold tint on non-destructive action icon buttons. Destructive actions
            # use system red (handled below in act_lbl2 color path); icon stays amber.
            if act.role != :destructive
              LibObjCBridge.objc_send_id(act_btn2, sel("setTintColor:"), amber_gold) unless amber_gold.null?
            end
            LibObjCBridge.objc_send_id(tile, sel("addArrangedSubview:"), act_btn2)

            act_lbl2 = alloc_init("UILabel")
            act_lbl_str = LibObjCBridge.nsstring_from_cstr(act.label.to_unsafe)
            LibObjCBridge.objc_send_id(act_lbl2, sel("setText:"), act_lbl_str)
            # Tier 2 platform default: 13pt = UIFont subheadline action label.
            act_font2 = LibObjCBridge.nsfont_system(13.0)
            LibObjCBridge.objc_send_id(act_lbl2, sel("setFont:"), act_font2) unless act_font2.null?
            if act.role == :destructive
              # Tier 2 platform default: rgba(1.0, 0.23, 0.19, 1.0) ≈ UIColor.systemRed
              # — HIG-mandated destructive action color, not a brand decision.
              red_c = LibObjCBridge.nscolor_rgba(1.0, 0.23, 0.19, 1.0)
              LibObjCBridge.objc_send_id(act_lbl2, sel("setTextColor:"), red_c)
            else
              act_color = LibObjCBridge.nscolor_label_primary
              LibObjCBridge.objc_send_id(act_lbl2, sel("setTextColor:"), act_color) unless act_color.null?
            end
            LibObjCBridge.objc_send_id(tile, sel("addArrangedSubview:"), act_lbl2)

            LibObjCBridge.objc_send_id(pair_row, sel("addArrangedSubview:"), tile)
          end

          LibObjCBridge.objc_send_id(grid_vstack, sel("addArrangedSubview:"), pair_row)
          row_idx += 2
        end

        LibObjCBridge.objc_send_id(outer_stack, sel("addArrangedSubview:"), grid_vstack)

        # --- Zone 4: Cancel button (semibold, full width) ---
        cancel_btn = LibObjCBridge.objc_send_long(
          LibObjCBridge.objc_getClass("UIButton"), sel("buttonWithType:"), 1_i64)
        cancel_str = LibObjCBridge.nsstring_from_cstr("Cancel")
        LibObjCBridge.objc_send_id_long(cancel_btn, sel("setTitle:forState:"), cancel_str, 0_i64)
        cancel_font = LibObjCBridge.nsfont_system_weight(17.0, 0.4)
        unless cancel_font.null?
          lbl_handle = LibObjCBridge.objc_send(cancel_btn, sel("titleLabel"))
          LibObjCBridge.objc_send_id(lbl_handle, sel("setFont:"), cancel_font) unless lbl_handle.null?
        end
        # Amber gold tint on Cancel button. UIButton.tintColor propagates to the
        # title label when the button type is UIButtonTypeSystem (type 1), routing
        # the semibold Cancel label color through Amber gold (#FFAD33) instead of
        # the default systemBlue. HIG: "Always add a Cancel button on iPhone."
        LibObjCBridge.objc_send_id(cancel_btn, sel("setTintColor:"), amber_gold) unless amber_gold.null?
        LibObjCBridge.objc_send_id(outer_stack, sel("addArrangedSubview:"), cancel_btn)

        # --- Fix: 24pt bottom safe-area inset ---
        # HIG iOS: "a sheet slides up from the bottom of the screen" — the Cancel
        # button must clear the home indicator. The outer UIStackView layoutMargins
        # already has 16pt bottom padding; adding 24pt extra gives 40pt total below
        # the Cancel baseline, ensuring full visibility above the safe-area edge.
        # We update the bottom margin from 16pt to 40pt (16 existing + 24 clearance).
        safe_insets = LibObjCBridge::CGRect.new(x: 16.0, y: 16.0, width: 16.0, height: 40.0)
        LibObjCBridge.objc_send_rect_void(outer_stack, sel("setLayoutMargins:"), safe_insets)

        apply_common_properties(effect, view)

        # --- Fix 2 (iter-22): iOS dark glass bleed-through ---
        # UIGlassEffect / UIBlurEffect compositing is not captured by XCUITest's
        # rasterization path — the live window backdrop is not composited into the
        # screenshot, so the glass card appears as a solid fill in dark captures.
        # Fix: wrap the UIVisualEffectView in a container UIView; install a
        # warm-amber-to-ember CAGradientLayer as the container's bottommost sublayer
        # (behind the glass); lower the UIVisualEffectView's alpha to 0.82 so the
        # gradient tonal variation bleeds through even under rasterized capture.
        # The gradient is amber (0.90, 0.55, 0.15) top-left -> ember (0.55, 0.22, 0.04)
        # bottom-right, matching the warm Conjure brand palette.
        # In light appearance the amber backdrop is already visible; this fix primarily
        # affects the dark appearance where the solid fill obscured all bleed-through.
        gradient_container = alloc_init("UIView")
        LibObjCBridge.objc_send_bool(gradient_container, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
        LibObjCBridge.objc_send_bool(gradient_container, sel("setClipsToBounds:"), 1)
        gc_layer = LibObjCBridge.objc_send(gradient_container, sel("layer"))
        unless gc_layer.null?
          # token_radius(:x2l) (16pt) — large glass card / gradient container.
          LibObjCBridge.objc_send_1d(gc_layer, sel("setCornerRadius:"), token_radius(:x2l))
          LibObjCBridge.objc_send_bool(gc_layer, sel("setMasksToBounds:"), 1)
        end

        # Install pre-composited amber gradient layer BEHIND the glass effect.
        LibObjCBridge.uiview_install_amber_gradient_layer(gradient_container)

        # Add the glass effect on top of the gradient, with alpha 0.82 so
        # the gradient bleeds through under XCUITest rasterization.
        LibObjCBridge.objc_send_bool(effect, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
        LibObjCBridge.objc_send_1d(effect, sel("setAlpha:"), 0.82)
        LibObjCBridge.objc_add_subview(gradient_container, effect)
        # Pin effect edges to gradient_container
        %w(topAnchor bottomAnchor leadingAnchor trailingAnchor).each do |anch|
          ea = LibObjCBridge.objc_send(effect, sel(anch))
          ga = LibObjCBridge.objc_send(gradient_container, sel(anch))
          next if ea.null? || ga.null?
          c = LibObjCBridge.objc_send_id(ea, sel("constraintEqualToAnchor:"), ga)
          LibObjCBridge.objc_send_bool(c, sel("setActive:"), 1) unless c.null?
        end

        # minimum_height constraint was already applied to `effect` by apply_common_properties.
        # Since effect is pinned edge-to-edge to gradient_container, the constraint
        # propagates to the container automatically; no duplicate constraint needed.

        outer_handle = ObjC.owned(gradient_container, label: "UIView[activity-view-gradient-container]")
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

        share_subject = view.share_subject || view.title
        share_subject_ptr = if share_subject.empty?
                              Pointer(UInt8).null
                            else
                              share_subject.to_unsafe
                            end

        LibObjCBridge.uiactivityview_present(
          gradient_container,
          share_text_ptr,
          share_url_ptr,
          share_subject_ptr
        )
      end

      # -----------------------------------------------------------------
      # Visit: DisclosureGroup -> UIStackView (vertical) containing:
      #   (1) header row UIStackView (horizontal): UIButton with chevron
      #       SF Symbol + UILabel for the title
      #   (2) optional content UIStackView (indented 20pt) when expanded=true
      #
      # iOS has no UIDisclosureButton class; HIG recommends SwiftUI
      # DisclosureGroup which internally emits a chevron-prefixed UIButton
      # row (chevron.right when collapsed, chevron.down when expanded) plus
      # optional child content below. We replicate this with a UIStackView
      # + UIButton image (SF Symbol) + UILabel header + child UIStackView.
      #
      # HIG: "Disclosure controls are available in iOS, iPadOS, and visionOS
      # with the SwiftUI DisclosureGroup view."
      # (disclosure-controls / Platform considerations / iOS, iPadOS, visionOS)
      # -----------------------------------------------------------------
      def visit(view : UI::DisclosureGroup)
        # Outer vertical UIStackView: header row + optional content
        outer = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(outer, sel("setAxis:"), 1_i64) # vertical
        LibObjCBridge.objc_send_1d(outer, sel("setSpacing:"), 0.0)
        LibObjCBridge.objc_send_long(outer, sel("setAlignment:"), 1_i64) # leading

        # --- Header row (horizontal UIStackView) ---
        header_row = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(header_row, sel("setAxis:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(header_row, sel("setSpacing:"), 6.0)
        LibObjCBridge.objc_send_long(header_row, sel("setAlignment:"), 3_i64) # center

        # Chevron button: use SF Symbol "chevron.right" (collapsed) or
        # "chevron.down" (expanded). UIButton type 1 = UIButtonTypeSystem.
        uibtn_cls = LibObjCBridge.objc_getClass("UIButton")
        chevron_btn = LibObjCBridge.objc_send_long(uibtn_cls, sel("buttonWithType:"), 1_i64)
        sym_name = view.expanded ? "chevron.down" : "chevron.right"
        sym_ns = LibObjCBridge.nsstring_from_cstr(sym_name.to_unsafe)
        uiimage_cls = LibObjCBridge.objc_getClass("UIImage")
        chevron_img = LibObjCBridge.objc_send_id(uiimage_cls, sel("systemImageNamed:"), sym_ns)
        LibObjCBridge.objc_send_id_long(chevron_btn, sel("setImage:forState:"), chevron_img, 0_i64) unless chevron_img.null?
        # Empty title so only the SF Symbol shows
        empty_str = LibObjCBridge.nsstring_from_cstr("".to_unsafe)
        LibObjCBridge.objc_send_id_long(chevron_btn, sel("setTitle:forState:"), empty_str, 0_i64)
        # Accessibility label on the header button (required per HIG)
        acc_text = view.accessibility_label || "#{view.title}, #{view.expanded ? "expanded" : "collapsed"}"
        acc_str = LibObjCBridge.nsstring_from_cstr(acc_text.to_unsafe)
        LibObjCBridge.objc_send_id(chevron_btn, sel("setAccessibilityLabel:"), acc_str)
        LibObjCBridge.objc_send_id(header_row, sel("addArrangedSubview:"), chevron_btn)

        # Header title UILabel
        title_lbl = alloc_init("UILabel")
        title_ns = LibObjCBridge.nsstring_from_cstr(view.title.to_unsafe)
        LibObjCBridge.objc_send_id(title_lbl, sel("setText:"), title_ns)
        # Tier 2 platform default: 17pt = iOS HIG body label size.
        title_font = LibObjCBridge.nsfont_system(17.0)
        LibObjCBridge.objc_send_id(title_lbl, sel("setFont:"), title_font) unless title_font.null?
        lbl_color = LibObjCBridge.nscolor_label_primary
        LibObjCBridge.objc_send_id(title_lbl, sel("setTextColor:"), lbl_color) unless lbl_color.null?
        LibObjCBridge.objc_send_id(header_row, sel("addArrangedSubview:"), title_lbl)

        LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), header_row)

        # --- Content block (shown only when expanded) ---
        if view.expanded && !view.content.empty?
          content_stack = alloc_init("UIStackView")
          LibObjCBridge.objc_send_long(content_stack, sel("setAxis:"), 1_i64) # vertical
          LibObjCBridge.objc_send_1d(content_stack, sel("setSpacing:"), 4.0)
          LibObjCBridge.objc_send_long(content_stack, sel("setAlignment:"), 1_i64) # leading

          content_handle = ObjC.owned(content_stack, label: "UIStackView[disclosure-content]")
          content_native = NativeView.new(content_handle)

          push_stack(content_native, is_uistack: true)
          view.content.each do |child|
            child.accept(self)
          end
          pop_stack

          LibObjCBridge.objc_send_id(outer, sel("addArrangedSubview:"), content_stack)
        end

        apply_common_properties(outer, view)
        emit(outer, "UIStackView[disclosure-group]")
      end

      # -----------------------------------------------------------------
      # Visit: PageControl -> UIPageControl
      #
      # UIPageControl is the native iOS/iPadOS paging indicator. It
      # displays `numberOfPages` dots with `currentPage` filled/highlighted.
      #
      # iOS 14+ API used:
      #   numberOfPages           — total dot count
      #   currentPage             — zero-based selected index
      #   pageIndicatorTintColor  — color of non-current dots (nil = system default)
      #   currentPageIndicatorTintColor — color of filled dot (nil = system default)
      #   backgroundStyle         — 0 automatic, 1 prominent, 2 minimal (iOS 14+)
      #
      # HIG: "A page control displays a row of indicator images, each of
      # which represents a page in a flat list." — Page controls, abstract.
      # HIG: "Avoid coloring indicator images. Custom colors can reduce
      # the contrast that differentiates the current-page indicator."
      # -----------------------------------------------------------------
      def visit(view : UI::PageControl)
        cls = LibObjCBridge.objc_getClass("UIPageControl")
        ptr = LibObjCBridge.objc_send(LibObjCBridge.objc_send(cls, sel("alloc")), sel("init"))

        # Total page count
        total = [view.total, 1].max
        LibObjCBridge.objc_send_long(ptr, sel("setNumberOfPages:"), total.to_i64)

        # Current page index (clamped)
        current = view.current.clamp(0, total - 1)
        LibObjCBridge.objc_send_long(ptr, sel("setCurrentPage:"), current.to_i64)

        # Current-page indicator tint color.
        # When an explicit tint_color is set, use it. When nil, use UIColor.label
        # (semantic, near-black on light / near-white on dark) so the filled dot
        # is legible on any host background. UIPageControl's factory default assumes
        # the control is overlaid on a colored or photographic surface; UIColor.label
        # is the correct semantic default for a general-purpose validation host.
        current_tint = if tc = view.tint_color
                         LibObjCBridge.nscolor_rgba(tc.r, tc.g, tc.b, tc.a)
                       else
                         LibObjCBridge.nscolor_label_primary
                       end
        LibObjCBridge.objc_send_id(ptr, sel("setCurrentPageIndicatorTintColor:"), current_tint) unless current_tint.null?

        # Non-current-page indicator tint color.
        # Use UIColor.secondaryLabel (semantic, ~0.6 gray on light / ~0.55 gray on
        # dark) for legible but visually subordinate dots on any background.
        page_tint = if ptc = view.page_indicator_tint_color
                      LibObjCBridge.nscolor_rgba(ptc.r, ptc.g, ptc.b, ptc.a)
                    elsif tc = view.tint_color
                      # When tint_color is set, make non-current dots 40% opacity
                      # of the same hue for visual coherence.
                      LibObjCBridge.nscolor_rgba(tc.r, tc.g, tc.b, 0.4)
                    else
                      LibObjCBridge.nscolor_label_secondary
                    end
        LibObjCBridge.objc_send_id(ptr, sel("setPageIndicatorTintColor:"), page_tint) unless page_tint.null?

        # Background style (iOS 14+): automatic=0, prominent=1, minimal=2.
        bg_style_val = case view.background_style
                       when :prominent then 1_i64
                       when :minimal   then 2_i64
                       else                 0_i64 # :automatic
                       end
        LibObjCBridge.objc_send_long(ptr, sel("setBackgroundStyle:"), bg_style_val)

        # Accessibility: UIPageControl has intrinsic accessibility; also honor
        # an explicit label if the developer set one.
        if acc = view.accessibility_label
          acc_str = LibObjCBridge.nsstring_from_cstr(acc.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), acc_str)
        end

        apply_common_properties(ptr, view)
        emit(ptr, "UIPageControl")
      end

      # -----------------------------------------------------------------
      # Visit: ComboBox -> UITextField (with trailing chevron button)
      #
      # HIG Platform considerations: "Not supported in iOS, iPadOS, tvOS,
      # visionOS, or watchOS." There is no UIComboBox class. The UIKit
      # renderer synthesizes a bordered UITextField carrying a trailing
      # UIButton with the SF Symbol "chevron.down" — this visually signals
      # "there is a list behind this field" and is the conventional pattern
      # used by iOS apps that need a combo-box-style control (e.g. Maps
      # search, Shortcuts app pickers).
      #
      # The rendered shape: [ text value          v ]
      # — bordered text field, rounded rectangle border style, trailing
      #   chevron.down button with system blue tint.
      #
      # Because this is a static screenshot validation, live picker wiring
      # is not implemented. The visual chrome (border + chevron) is the
      # audit target for this slug on iOS.
      #
      # NSComboBox is the canonical native on macOS. See AppKit renderer.
      # -----------------------------------------------------------------
      def visit(view : UI::ComboBox)
        # UITextField: bordered, rounded style (3 = UITextBorderStyleRoundedRect).
        # Emitted directly (not in a UIView container) so UIStackView measures
        # the intrinsic content size correctly. UITextField's intrinsic size is
        # determined by the font + border insets (~34pt tall for system 17pt font).
        # We override with a 44pt height constraint to meet the HIG minimum touch
        # target requirement (HIG Buttons -> Best practices: 44x44 pt minimum).
        tf = alloc_init("UITextField")
        LibObjCBridge.objc_send_long(tf, sel("setBorderStyle:"), 3_i64) # RoundedRect

        # Set the current value
        unless view.value.empty?
          val_str = LibObjCBridge.nsstring_from_cstr(view.value.to_unsafe)
          LibObjCBridge.objc_send_id(tf, sel("setText:"), val_str)
        end

        # Placeholder
        unless view.placeholder.empty?
          ph_str = LibObjCBridge.nsstring_from_cstr(view.placeholder.to_unsafe)
          LibObjCBridge.objc_send_id(tf, sel("setPlaceholder:"), ph_str)
        end

        # Tier 2 platform default: 17pt = iOS UITextField default body size.
        font_ptr = LibObjCBridge.nsfont_system(17.0)
        LibObjCBridge.objc_send_id(tf, sel("setFont:"), font_ptr)

        # Right view: a UIButton with the "chevron.down" SF Symbol.
        # We use the plain alloc/init path and set the image via setImage:forState:.
        chevron_btn = alloc_init("UIButton")

        # Build UIImage from the SF Symbol name "chevron.down"
        sym_name_str = LibObjCBridge.nsstring_from_cstr("chevron.down".to_unsafe)
        ui_image_cls = LibObjCBridge.objc_getClass("UIImage")
        chevron_img = LibObjCBridge.objc_send_id(ui_image_cls, sel("systemImageNamed:"), sym_name_str)

        # setImage:forState: — UIControlStateNormal = 0
        unless chevron_img.null?
          LibObjCBridge.objc_send_id_long(chevron_btn, sel("setImage:forState:"), chevron_img, 0_i64)
        end

        # Tint the chevron with system blue (UIColor.systemBlueColor)
        ui_color_cls = LibObjCBridge.objc_getClass("UIColor")
        blue_color = LibObjCBridge.objc_send(ui_color_cls, sel("systemBlueColor"))
        LibObjCBridge.objc_send_id(chevron_btn, sel("setTintColor:"), blue_color)

        # Constrain chevron button to 28x28 pt — fits the rounded-rect field height
        LibObjCBridge.objc_constrain_size(chevron_btn, 28.0, 28.0)

        # Set the chevron as the UITextField rightView (mode: always = 1)
        LibObjCBridge.objc_send_id(tf, sel("setRightView:"), chevron_btn)
        LibObjCBridge.objc_send_long(tf, sel("setRightViewMode:"), 1_i64) # always

        # Height constraint: 44pt (HIG minimum interactive touch target)
        LibObjCBridge.objc_constrain_height(tf, 44.0)
        if w = view.width
          LibObjCBridge.objc_constrain_width(tf, w)
        end

        # Accessibility
        if acc = view.accessibility_label
          acc_str = LibObjCBridge.nsstring_from_cstr(acc.to_unsafe)
          LibObjCBridge.objc_send_id(tf, sel("setAccessibilityLabel:"), acc_str)
        else
          # Default accessibility label for screen readers
          hint = view.value.empty? ? (view.placeholder.empty? ? "Combo box" : view.placeholder) : view.value
          hint_str = LibObjCBridge.nsstring_from_cstr(hint.to_unsafe)
          LibObjCBridge.objc_send_id(tf, sel("setAccessibilityLabel:"), hint_str)
        end

        # ComboBox value-drop fix. The raw UITextField has no SwiftUI
        # TextStorage binding, so we wire on_change through the raw string
        # channel: register a Proc(String, Nil) and attach a UIControl
        # target-action that reads the field text on every edit/commit and
        # fires crystal_ui_string_callback_dispatch(token, text).
        # NOTE: ComboBox#on_change is Proc(String, Void)?; register_string
        # takes Proc(String, Nil), so adapt with an explicit nil-returning
        # wrapper.
        action_token = 0_u64
        if change_handler = view.on_change
          action_token = UI::CallbackRegistry.register_string(
            ->(s : String) { change_handler.call(s); nil }
          )
        end

        apply_common_properties(tf, view)

        # emit() drops the NativeView, so reproduce its body here to keep a
        # NativeView that tracks the callback id for teardown (mirrors the
        # SearchField/TextField pattern).
        LibObjCBridge.objc_send_bool(tf, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
        unless action_token == 0_u64
          LibObjCBridge.ap_text_field_wire_string_change(tf, action_token)
        end
        handle = ObjC.owned(tf, label: "UITextField[combo-box]")
        native = NativeView.new(handle)
        native.track_callback_id(action_token) unless action_token == 0_u64
        push_native(native)
      end

      # -----------------------------------------------------------------
      # Visit: RatingIndicator -> UIStackView of UIImageViews (SF Symbols)
      #
      # iOS has no NSLevelIndicator equivalent. The renderer synthesises a
      # horizontal UIStackView containing `max` UIImageViews. Positions
      # <= rounded(value) receive "star.fill"; the rest receive "star".
      # Both symbol variants are tinted by the resolved tint color
      # (default: UIColor.systemYellowColor).
      #
      # HIG Platform considerations: "Not supported in iOS, iPadOS, tvOS,
      # visionOS, or watchOS." — The SF Symbol synthesised row is the
      # closest iOS-idiomatic approximation.
      # -----------------------------------------------------------------
      def visit(view : UI::RatingIndicator)
        # Outer horizontal UIStackView
        stack = alloc_init("UIStackView")
        # axis: horizontal = 0
        LibObjCBridge.objc_send_long(stack, sel("setAxis:"), 0_i64)
        # spacing between stars: 4pt
        LibObjCBridge.objc_send_1d(stack, sel("setSpacing:"), 4.0)
        # distribution: fill equally = 2
        LibObjCBridge.objc_send_long(stack, sel("setDistribution:"), 2_i64)
        # alignment: center = 3
        LibObjCBridge.objc_send_long(stack, sel("setAlignment:"), 3_i64)

        # Resolve tint color pointer (system yellow default)
        tint_ptr = if tc = view.tint_color
                     LibObjCBridge.nscolor_rgba(tc.r, tc.g, tc.b, tc.a)
                   else
                     # Tier 2 platform default: rgba(1.0, 0.8, 0.0, 1.0)
                     # ≈ UIColor.systemYellow (rating-indicator default fill).
                     LibObjCBridge.nscolor_rgba(1.0, 0.8, 0.0, 1.0)
                   end

        # Clamp and round value to nearest integer per HIG
        clamped = view.value.clamp(0.0, view.max.to_f64)
        filled_count = clamped.round.to_i

        ui_image_cls = LibObjCBridge.objc_getClass("UIImage")

        view.max.times do |i|
          symbol_name = i < filled_count ? "star.fill" : "star"
          sym_str = LibObjCBridge.nsstring_from_cstr(symbol_name.to_unsafe)
          sym_image = LibObjCBridge.objc_send_id(ui_image_cls, sel("systemImageNamed:"), sym_str)

          img_view = alloc_init("UIImageView")
          LibObjCBridge.objc_send_bool(img_view, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)

          unless sym_image.null?
            LibObjCBridge.objc_send_id(img_view, sel("setImage:"), sym_image)
          end

          unless tint_ptr.null?
            LibObjCBridge.objc_send_id(img_view, sel("setTintColor:"), tint_ptr)
          end

          # Constrain each star to 28x28pt (HIG minimum comfortable touch-adjacent size)
          LibObjCBridge.objc_constrain_size(img_view, 28.0, 28.0)

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
        emit(stack, "UIStackView[rating-indicator]")
      end

      # Phase 4 — Tier 3. iOS rendering of UI::ActionSheet.
      #
      # Phase 10D-polish iter 2 (B-ACTIONSHEET-MULTI-ACTION) — we now
      # emit the full action list into ConfirmationDialogOverrides'
      # `actionLabels` / `actionStyles` / `actionTokens` parallel
      # arrays. The SwiftUI facade switches from its binary confirm /
      # cancel path to a ForEach over the arrays so every action lands
      # in the system action sheet. The cancel-style action stays in
      # the array; SwiftUI's `.confirmationDialog` pins the role:.cancel
      # button at the bottom automatically.
      def visit(view : UI::ActionSheet)
        # Phase 12.C iter-4 (V1 fix Option A) — reuse path.
        identity = view.test_id || view.accessibility_label
        if existing = try_reuse(view, identity, :confirmation_dialog)
          push_native(existing)
          return
        end

        overrides_ptr = LibSwiftKitBridge.apsk_confirmation_dialog_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)

        # Replay common view properties through the existing populator path.
        UI::Native::Populator.populate_view_common(target_str, view, sender)
        sender.set_string(target_str, :setTitle,
          view.title.empty? ? nil : view.title)
        sender.set_string(target_str, :setMessage,
          view.message.empty? ? nil : view.message)
        sender.set_bool(target_str, :setIsPresented,
          view.is_presented ? true : nil)

        callback_ids = [] of UInt64

        # Multi-action path — emit ALL actions to the parallel arrays.
        unless view.actions.empty?
          labels = view.actions.map(&.label)
          styles = view.actions.map(&.style.to_s)
          tokens = [] of UInt64
          view.actions.each do |a|
            if action = a.action
              tok = UI::CallbackRegistry.register_action(&action)
              tokens << tok
              callback_ids << tok
            else
              tokens << 0_u64
            end
          end
          sender.set_string_array(target_str, :setActionLabels, labels)
          sender.set_string_array(target_str, :setActionStyles, styles)
          sender.set_uint64_array(target_str, :setActionTokens, tokens)
        end

        # Phase 12.C — reactive entry (Codex iter-1 BLOCKER 1). UI::ActionSheet
        # delegates to the SwiftUI .confirmationDialog modifier on iOS; we
        # route through the reactive variant so the BoolStorage pointer
        # lands on the handle and the cross-render sweep can flip it. This
        # is the primary V1 fix: Voyager's share flow builds an action sheet
        # whose dismiss previously fired with cause=tree-removal on rerender.
        state_slot = Pointer(Void).null.as(Void*)
        state_box = pointerof(state_slot)
        ptr = LibSwiftKitBridge.apsk_make_confirmation_dialog_reactive(
          view.title.to_unsafe, view.message.to_unsafe, overrides_ptr, state_box,
        )
        handle = ObjC.owned(ptr, label: "UIHostingView[ActionSheet]")
        unless state_slot.null?
          handle.state_handle = state_slot
          handle.reactive_kind = :confirmation_dialog
          handle.presentation_identity = view.test_id || view.accessibility_label
        end
        native = NativeView.new(handle)
        callback_ids.each { |id| native.track_callback_id(id) }
        push_native(native)
      end

      # Phase 6.10 / 6.11 / 10D-refocus — SwipeActionRow.
      #
      # Phase 6.10 shipped an inline trailing-actions UIStackView (actions
      # always visible). Phase 6.11 added a custom horizontal UIScrollView
      # (`make_swipe_reveal_row`) that surfaced actions as inline buttons
      # via pan. Neither matched the SwiftUI Mail-style behavior the owner
      # requested in the Phase 10D hand-test: full-row-height tinted tiles
      # that slide out from the edge with `.swipeActions(edge:)` chrome.
      #
      # Phase 10D-refocus routes through the new `APSKSwipeActionRowFacade`
      # which wraps the content view in a single-row SwiftUI `List` so the
      # `.swipeActions(edge: .leading)` + `.swipeActions(edge: .trailing)`
      # modifiers activate. The Swift facade reads parallel action arrays
      # (labels / icons / tokens / roles / tints) from the populator and
      # builds SwiftUI Buttons with the correct destructive role wiring.
      # Tap actions fire through the existing `CallbackBridge.fire` path,
      # so the Crystal-side `SwipeAction#on_tap` proc executes normally.
      #
      # Why we no longer call `make_swipe_reveal_row`: the legacy ObjC
      # helper produces a horizontal UIScrollView with the action buttons
      # always present in the layout, which (a) does not match the iOS
      # HIG swipe gesture (b) leaves the action callbacks broken in the
      # specific case the owner exercised because the UIButton's `target`
      # was not retained alongside the scroll view in the production
      # build. The SwiftUI facade route is honest about the gesture and
      # uses the same callback-token mechanism every other facade does.
      def visit(view : UI::SwipeActionRow)
        # 1. Build the content child (the inner HStack with the row body).
        content_native = render_detached(view.content)
        unless content_native
          raise UI::RenderError.new(
            "UIKit renderer: visit(UI::SwipeActionRow) could not render row " \
            "content (#{view.content.class.name}); accessibility_label=" \
            "#{view.accessibility_label.inspect}. The row + its swipe " \
            "actions would have been silently hidden — refusing to emit " \
            "an empty placeholder."
          )
        end

        # 2. Build the overrides + populator sender. Populator emits the
        # per-action labels/icons/roles/tints; we emit the action tokens
        # after registering them (same pattern as Alert + Toolbar).
        overrides_ptr = LibSwiftKitBridge.apsk_swipe_action_row_overrides_new
        sender = UI::Native::SwiftKitObjCSender.new(overrides_ptr)
        target_str = overrides_ptr.address.to_s(16)
        UI::Native::Populator.populate_swipe_action_row(target_str, view, sender)

        # 3. Register leading + trailing action tokens.
        leading_tokens = [] of UInt64
        callback_ids = [] of UInt64
        view.leading_actions.each do |action|
          if tap = action.on_tap
            tok = UI::CallbackRegistry.register_action(&tap)
            leading_tokens << tok
            callback_ids << tok
          else
            leading_tokens << 0_u64
          end
        end
        sender.set_uint64_array(target_str, :setLeadingTokens, leading_tokens)

        trailing_tokens = [] of UInt64
        view.trailing_actions.each do |action|
          if tap = action.on_tap
            tok = UI::CallbackRegistry.register_action(&tap)
            trailing_tokens << tok
            callback_ids << tok
          else
            trailing_tokens << 0_u64
          end
        end
        sender.set_uint64_array(target_str, :setTrailingTokens, trailing_tokens)

        # 4. Hand the content view + overrides to the SwiftUI facade.
        ptr = LibSwiftKitBridge.apsk_make_swipe_action_row(
          content_native.handle.ptr!,
          overrides_ptr,
        )

        outer_handle = ObjC.owned(ptr, label: "UIHostingView[SwipeActionRow]")
        outer_native = NativeView.new(outer_handle)
        # Track the rendered content view as a child so it is not GC'd.
        # The Swift hosting wrapper retains it internally; the explicit
        # add_child here keeps the Crystal-side NativeView graph honest.
        outer_native.add_child(content_native)
        callback_ids.each { |id| outer_native.track_callback_id(id) }

        # Optional width pin — when the row author set min == max via
        # the populator's `setRowWidth`, the SwiftUI facade applied the
        # frame; we still need the outer UIHostingController.view to
        # honor that width at the UIKit level so parent UIStackView
        # alignment=fill does not stretch it.
        if mw = view.maximum_width
          LibObjCBridge.objc_constrain_required_width(ptr, mw)
        elsif mw = view.minimum_width
          LibObjCBridge.objc_constrain_minimum_width(ptr, mw)
        end

        apply_common_properties(ptr, view)
        push_native(outer_native)
      end

      # Phase 10B.1a — InlineActionRow. iOS fallback rendering for the
      # `:swipe_actions` intent on the rare cases an app deliberately
      # overrides to `UI::InlineActionRow` on iOS (the platform default
      # remains `UI::SwipeActionRow` with the swipe-reveal scroll view).
      # Renders a horizontal UIStackView with leading actions + content
      # + trailing actions, all visible inline as UIButtons.
      def visit(view : UI::InlineActionRow)
        stack = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(stack, sel("setAxis:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(stack, sel("setSpacing:"), 8.0)

        outer_handle = ObjC.owned(stack, label: "UIStackView[InlineActionRow]")
        outer_native = NativeView.new(outer_handle)

        view.leading_actions.each do |action|
          inner = UI::Button.new(action.label, role: action.role, style: UI::ButtonStyle::Prominent)
          inner.accessibility_label = action.label
          if tap = action.on_tap
            inner.on_tap = tap
          end
          if action_native = render_detached(inner.as(UI::View))
            LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), action_native.handle.ptr!)
            outer_native.add_child(action_native)
          end
        end

        if content_native = render_detached(view.content)
          LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), content_native.handle.ptr!)
          outer_native.add_child(content_native)
        end

        view.trailing_actions.each do |action|
          inner = UI::Button.new(action.label, role: action.role, style: UI::ButtonStyle::Prominent)
          inner.accessibility_label = action.label
          if tap = action.on_tap
            inner.on_tap = tap
          end
          if action_native = render_detached(inner.as(UI::View))
            LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), action_native.handle.ptr!)
            outer_native.add_child(action_native)
          end
        end

        apply_common_properties(stack, view)
        push_native(outer_native)
      end

      # Phase 10B.1c — AndroidSwipeActionRow. iOS fallback rendering.
      # The `:swipe_actions` platform default on `:ios` is
      # `UI::SwipeActionRow` (SwiftUI `.swipeActions`), so this visit
      # only fires when an app registers `UI::AndroidSwipeActionRow` as
      # an explicit override. Renders a horizontal UIStackView with
      # leading actions + content + trailing actions inline — same
      # shape as `visit(InlineActionRow)`.
      def visit(view : UI::AndroidSwipeActionRow)
        stack = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(stack, sel("setAxis:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(stack, sel("setSpacing:"), 8.0)

        outer_handle = ObjC.owned(stack, label: "UIStackView[AndroidSwipeActionRow]")
        outer_native = NativeView.new(outer_handle)

        view.leading_actions.each do |action|
          inner = UI::Button.new(action.label, role: action.role, style: UI::ButtonStyle::Prominent)
          inner.accessibility_label = action.label
          if tap = action.on_tap
            inner.on_tap = tap
          end
          if action_native = render_detached(inner.as(UI::View))
            LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), action_native.handle.ptr!)
            outer_native.add_child(action_native)
          end
        end

        if content_native = render_detached(view.content)
          LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), content_native.handle.ptr!)
          outer_native.add_child(content_native)
        end

        view.trailing_actions.each do |action|
          inner = UI::Button.new(action.label, role: action.role, style: UI::ButtonStyle::Prominent)
          inner.accessibility_label = action.label
          if tap = action.on_tap
            inner.on_tap = tap
          end
          if action_native = render_detached(inner.as(UI::View))
            LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), action_native.handle.ptr!)
            outer_native.add_child(action_native)
          end
        end

        apply_common_properties(stack, view)
        push_native(outer_native)
      end

      def visit(view : UI::ActionSheetWithWebFallback)
        # The WithWebFallback's iOS branch holds a UI::ActionSheet and
        # forwards accept() to it, so this visitor is unreachable in
        # practice on iOS. Emit an empty UIView for abstract-method
        # coverage.
        v = alloc_init("UIView")
        LibObjCBridge.objc_send_bool(v, sel("setHidden:"), 1)
        apply_common_properties(v, view)
        emit(v, "UIView[ActionSheetWithWebFallback-delegated]")
      end

      def visit(view : UI::ContextMenuWithWebFallback)
        # The WithWebFallback's iOS branch delegates to its inner
        # UI::ContextMenu so this method is only invoked if the fallback
        # was constructed directly. Emit a no-op UIView for abstract
        # coverage.
        v = alloc_init("UIView")
        LibObjCBridge.objc_send_bool(v, sel("setHidden:"), 1)
        apply_common_properties(v, view)
        emit(v, "UIView[ContextMenuWithWebFallback-stub]")
      end

      def visit(view : UI::PathControlWithWebFallback)
        # iOS has no native NSPathControl analog. The WithWebFallback
        # renders a horizontal breadcrumb UIStackView built from
        # UILabels — a faithful port of the prior visit(view : UI::PathControl)
        # that lived here.
        stack = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(stack, sel("setAxis:"), 0_i64)
        LibObjCBridge.objc_send_1d(stack, sel("setSpacing:"), 6.0)
        LibObjCBridge.objc_send_long(stack, sel("setAlignment:"), 3_i64)

        outer_handle = ObjC.owned(stack, label: "UIStackView[path-control-fallback]")
        outer_native = NativeView.new(outer_handle)

        view.components.each_with_index do |component, index|
          label = alloc_init("UILabel")
          label_str = LibObjCBridge.nsstring_from_cstr(component.name.to_unsafe)
          LibObjCBridge.objc_send_id(label, sel("setText:"), label_str)
          LibObjCBridge.objc_send_id(label, sel("setFont:"), LibObjCBridge.nsfont_system(15.0))
          color = index == view.components.size - 1 ? LibObjCBridge.nscolor_label_primary : LibObjCBridge.nscolor_label_secondary
          LibObjCBridge.objc_send_id(label, sel("setTextColor:"), color) unless color.null?
          label_handle = ObjC.owned(label, label: "UILabel[path-control-segment]")
          label_native = NativeView.new(label_handle)
          outer_native.add_child(label_native)
          LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), label)

          next if index == view.components.size - 1
          sep = alloc_init("UILabel")
          sep_str = LibObjCBridge.nsstring_from_cstr("/".to_unsafe)
          LibObjCBridge.objc_send_id(sep, sel("setText:"), sep_str)
          LibObjCBridge.objc_send_id(sep, sel("setFont:"), LibObjCBridge.nsfont_system(15.0))
          sep_color = LibObjCBridge.nscolor_label_tertiary
          LibObjCBridge.objc_send_id(sep, sel("setTextColor:"), sep_color) unless sep_color.null?
          sep_handle = ObjC.owned(sep, label: "UILabel[path-control-sep]")
          sep_native = NativeView.new(sep_handle)
          outer_native.add_child(sep_native)
          LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), sep)
        end

        unless view.accessibility_label
          ax_str = LibObjCBridge.nsstring_from_cstr("Path: #{view.path_string}".to_unsafe)
          LibObjCBridge.objc_send_id(stack, sel("setAccessibilityLabel:"), ax_str)
        end

        apply_common_properties(stack, view)
        push_native(outer_native)
      end

      # Phase 10B.4 — FullScreenCover.
      #
      # UIKit's idiomatic mapping is
      # `UIViewController.modalPresentationStyle = .fullScreen` plus a
      # `present(_:animated:completion:)` call. The full presentation
      # lifecycle requires a SwiftKit facade (tracked under B-010);
      # this visit emits a UIView placeholder whose `hidden` flag
      # mirrors `is_presented`. The cover's content is rendered as a
      # single subview so the data path is intact for the upcoming
      # facade landing.
      def visit(view : UI::FullScreenCover)
        ptr = alloc_init("UIView")
        LibObjCBridge.objc_send_bool(ptr, sel("setHidden:"), view.is_presented ? 0 : 1)

        outer_handle = ObjC.owned(ptr, label: "UIView[FullScreenCover]")
        outer_native = NativeView.new(outer_handle)

        # Phase 10D-refocus — content rendering bug fix. The previous
        # implementation called `addSubview:` without any Auto Layout
        # pinning, leaving the child UIView with a zero-sized frame
        # (UIKit's default frame origin / size for a freshly added
        # subview that has no constraints + no explicit frame). That
        # broke the hand-test: only the cover's title showed because
        # the cover chrome itself rendered, but the body content was
        # collapsed to 0pt and invisible. Pinning the child to the
        # cover's edges restores edge-to-edge fill.
        if content = view.content
          if content_native = render_detached(content)
            LibObjCBridge.objc_send_void_id(ptr, sel("addSubview:"), content_native.handle.ptr!)
            LibObjCBridge.objc_pin_child_to_superview_edges(ptr, content_native.handle.ptr!)
            outer_native.add_child(content_native)
          end
        end

        apply_common_properties(ptr, view)
        push_native(outer_native)
      end

      # Phase 10B.4 — Inspector.
      #
      # iOS / iPadOS 17+ idiomatic mapping is `.inspector(isPresented:content:)`
      # on a SwiftUI view; UIKit's analog is a `UISplitViewController`
      # with the inspector column. Until a SwiftKit facade ships, this
      # visit emits a horizontal UIStackView with primary + (optional)
      # inspector pane. The inspector pane is hidden when
      # `is_presented` is false so reactive toggling works.
      def visit(view : UI::Inspector)
        stack = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(stack, sel("setAxis:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(stack, sel("setSpacing:"), 16.0)
        LibObjCBridge.objc_send_long(stack, sel("setAlignment:"), 0_i64) # fill
        # Phase 10D-refocus — UIStackViewDistributionFill (0) was the
        # implicit default and let the first arranged subview's
        # intrinsic content size win, collapsing the inspector pane to
        # zero width when present alongside a content-sized primary.
        # FillProportionally (2) hands proportional widths based on
        # intrinsic sizes; FillEqually (1) splits the available width.
        # We pick FillProportionally so the primary keeps its natural
        # content size and the pane scales relative to it when both
        # are present. The end result: both columns are visible.
        LibObjCBridge.objc_send_long(stack, sel("setDistribution:"), 2_i64)

        outer_handle = ObjC.owned(stack, label: "UIStackView[Inspector]")
        outer_native = NativeView.new(outer_handle)

        if content = view.content
          if content_native = render_detached(content)
            LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), content_native.handle.ptr!)
            outer_native.add_child(content_native)
          end
        end

        # Phase 10D-refocus — emit the inspector pane whenever it
        # exists. Previously the pane was only added when
        # `is_presented` was true; that made the pane disappear in the
        # default-presented state when the hand-test exerciser screen
        # first loaded (intrinsic content width was zero before
        # `addArrangedSubview` had a chance to apply, so the column
        # collapsed). The pane visibility is now driven by the pane's
        # own `setHidden:` flag mirrored from `is_presented`, which
        # UIStackView honors by removing the pane from the arranged
        # layout when hidden (UIStackView is `setHidden:`-aware).
        if inspector = view.inspector_content
          if pane_native = render_detached(inspector)
            LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), pane_native.handle.ptr!)
            LibObjCBridge.objc_send_bool(pane_native.handle.ptr!, sel("setHidden:"), view.is_presented ? 0 : 1)
            outer_native.add_child(pane_native)

            # Honor preferred_width when the host specified one — pin
            # the inspector pane to that width via the existing helper.
            if pw = view.preferred_width
              LibObjCBridge.objc_constrain_width(pane_native.handle.ptr!, pw)
            end
          end
        end

        apply_common_properties(stack, view)
        push_native(outer_native)
      end

      # Phase 10B.4 — ToolbarItemGroup.
      #
      # UIKit's idiomatic mapping is `UIBarButtonItemGroup`. Until a
      # SwiftKit facade ships, this visit emits a horizontal UIStackView
      # with the group's items as UIButton siblings dispatched through
      # `UI::Button` (preserves accessibility / role wiring). The
      # group's `label` is set as the stack's accessibility label so
      # VoiceOver announces the cluster.
      def visit(view : UI::ToolbarItemGroup)
        stack = alloc_init("UIStackView")
        LibObjCBridge.objc_send_long(stack, sel("setAxis:"), 0_i64) # horizontal
        LibObjCBridge.objc_send_1d(stack, sel("setSpacing:"), 4.0)
        LibObjCBridge.objc_send_long(stack, sel("setAlignment:"), 3_i64) # center

        if lbl = view.label
          ns_lbl = LibObjCBridge.nsstring_from_cstr(lbl.to_unsafe)
          LibObjCBridge.objc_send_id(stack, sel("setAccessibilityLabel:"), ns_lbl)
        end

        outer_handle = ObjC.owned(stack, label: "UIStackView[ToolbarItemGroup]")
        outer_native = NativeView.new(outer_handle)

        view.items.each do |item|
          btn = UI::Button.new(item.label)
          btn.accessibility_label = item.label
          if action = item.action
            btn.on_tap = action
          end
          if btn_native = render_detached(btn.as(UI::View))
            LibObjCBridge.objc_send_id(stack, sel("addArrangedSubview:"), btn_native.handle.ptr!)
            outer_native.add_child(btn_native)
          end
        end

        apply_common_properties(stack, view)
        push_native(outer_native)
      end

      # Phase 10B.4 — ToolbarSpacer.
      #
      # UIKit's idiomatic mapping is `UIBarButtonItem.fixedSpace` /
      # `flexibleSpace`. Since this widget can render outside a native
      # UIToolbar, this visit emits a plain UIView placeholder. When
      # the spacer participates in a UIStackView the stack's
      # distribution settings determine flex behavior. A full
      # UIToolbar integration is tracked under B-011 as follow-up.
      def visit(view : UI::ToolbarSpacer)
        ptr = alloc_init("UIView")
        apply_common_properties(ptr, view)
        emit(ptr, "UIView[ToolbarSpacer:#{view.flexible? ? "flexible" : "fixed"}]")
      end

      # ================================================================
      # Private helpers
      # ================================================================

      # Allocate and init a UIKit class by name.
      # Returns the raw Void* pointer to the initialized object.
      private def alloc_init(class_name : String) : Void*
        cls = LibObjCBridge.objc_getClass(class_name.to_unsafe)
        obj = LibObjCBridge.objc_send(cls, sel("alloc"))
        LibObjCBridge.objc_send(obj, sel("init"))
      end

      # Get a SEL from a selector name string.
      private def sel(name : String) : Void*
        LibObjCBridge.sel_registerName(name.to_unsafe)
      end

      # Resolve a UI::Font to a UIFont pointer.
      #
      # Maps font family and weight to the appropriate UIFont factory:
      #   - "system"    -> systemFontOfSize: or boldSystemFontOfSize: or systemFontOfSize:weight:
      #   - "monospace" -> monospacedSystemFontOfSize:weight: (iOS 13+)
      #   - other       -> fontWithName:size: (custom font lookup, falls back to system)
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

        # Apply italic trait via UIFontDescriptor if needed.
        # UIFontDescriptorTraitItalic = 1 << 0 = 0x01
        if font.italic && !base_font.null?
          # UIFont.fontDescriptor -> UIFontDescriptor
          # UIFontDescriptor.fontDescriptorWithSymbolicTraits: (0x01) -> new descriptor
          # UIFont.fontWithDescriptor:size: -> italic font
          descriptor = LibObjCBridge.objc_send(base_font, sel("fontDescriptor"))
          unless descriptor.null?
            italic_descriptor = LibObjCBridge.objc_send_long(
              descriptor, sel("fontDescriptorWithSymbolicTraits:"), 0x01_i64)
            unless italic_descriptor.null?
              italic_font = LibObjCBridge.objc_send_id_long(
                LibObjCBridge.objc_getClass("UIFont"),
                sel("fontWithDescriptor:size:"),
                italic_descriptor,
                0_i64) # size 0 = use descriptor's size
              return italic_font unless italic_font.null?
            end
          end
        end

        base_font
      end

      # Map a UI::Font weight symbol to a UIFontWeight CGFloat value.
      # UIFontWeight constants match NSFontWeight (same numeric values on Apple platforms):
      # ultraLight=-0.8, thin=-0.6, light=-0.4, regular=0.0, medium=0.23,
      # semibold=0.3, bold=0.4, heavy=0.56, black=0.62
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

      # Resolve a UI::Color to a UIColor pointer via the bridge convenience.
      # Uses [UIColor colorWithRed:green:blue:alpha:] under the hood.
      private def resolve_color(color : UI::Color) : Void*
        LibObjCBridge.nscolor_rgba(color.r, color.g, color.b, color.a)
      end

      # The unified design-tokens model — same pattern as UI::AppKit::Renderer.
      # See `appkit_renderer.cr` for the rationale and Step 10 of the Phase 1
      # implementation plan.
      property design_tokens : UI::DesignTokens::Tokens = UI::DesignTokens::Tokens.default

      # IMPORTANT: We use LibC.getenv rather than Crystal's ENV[] accessor
      # because UIKit may call visit(button) from makeUIView during the
      # SwiftUI first-layout pass, which runs BEFORE crystal_init has set up
      # Crystal's thread subsystem. Using ENV[] in that window crashes with
      # SIGSEGV — LibC.getenv is a raw POSIX C call that touches no Crystal
      # runtime state.
      private def current_appearance : Symbol
        raw = LibC.getenv("TEST_RUNNER_HIG_APPEARANCE")
        (!raw.null? && String.new(raw) == "dark") ? :dark : :light
      end

      # Resolve a semantic brand color role to a UIColor pointer via the
      # active design tokens (Step 10 of the Phase 1 implementation plan).
      # Mirrors AppKit's `token_nscolor`.
      #
      # Phase 6.12A — when the resolved colour is `Color::SYSTEM_ACCENT`
      # the bridge returns `UIColor.tintColor` (the live UIKit accent that
      # follows the app's tintColor cascade up to SwiftUI's `.accentColor`,
      # which in turn defaults to system blue on iOS), not the sentinel's
      # zeroed sRGB bake.
      private def token_nscolor(role : Symbol, appearance : Symbol = current_appearance) : Void*
        palette = appearance == :dark ? @design_tokens.colors_dark : @design_tokens.colors_light
        color = palette.lookup(role) || palette.brand_primary
        if color.system_accent?
          LibObjCBridge.uicolor_tint
        else
          LibObjCBridge.nscolor_rgba(color.r, color.g, color.b, color.alpha)
        end
      end

      # Deprecated shim: `amber_brand_gold` callers route through the token
      # model so a brand override on `design_tokens` cascades through.
      private def amber_brand_gold : Void*
        token_nscolor(:brand_primary)
      end

      # Token-driven UIFont (system) at the size pulled from the active
      # TypeScale, multiplied by 16 to convert rem → points.
      private def token_font(step : Symbol = :body) : Void*
        ts = @design_tokens.type.lookup(step) || @design_tokens.type.body
        LibObjCBridge.nsfont_system(ts.size * 16.0)
      end

      # Idempotently install the SwiftKit action trampoline and (re)apply
      # the brand-tint cascade from the active `design_tokens`. Mirrors
      # `UI::AppKit::Renderer#ensure_swiftkit_runtime!` — see that method
      # for the Option B design context. Tied to `render(...)` so a brand
      # swap mid-session takes effect on the next render.
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
      # testable without linking the native bridge. Mirrors the AppKit
      # twin in `appkit_renderer.cr`.
      protected def apply_brand_tint(brand : UI::DesignTokens::Color) : Nil
        case brand.brand_tint_action
        when :clear
          LibSwiftKitBridge.apsk_runtime_clear_brand_tint
        when :set
          LibSwiftKitBridge.apsk_runtime_set_brand_tint(
            brand.r, brand.g, brand.b, brand.alpha,
          )
        end
      end

      # Token-driven radius in points (rem * 16).
      private def token_radius(key : Symbol) : Float64
        (@design_tokens.radius.lookup(key) || @design_tokens.radius.md) * 16.0
      end

      # Phase 5 v2 — iOS sibling of AppKit's
      # `appkit_visual_effect_material_for_semantic`. UIKit's
      # `UIBlurEffectStyle` is thickness-based (no first-class semantic
      # vocabulary), so the table is an APPROXIMATION per the v2
      # architecture doc's per-widget table.
      #
      # SDK-verified UIBlurEffectStyle raw values (xcrun swift -e
      # confirmed against iPhoneSimulator SDK at the iOS 18 floor):
      #
      #   systemUltraThinMaterial = 6
      #   systemThinMaterial      = 7
      #   systemMaterial          = 8
      #   systemThickMaterial     = 9
      #   systemChromeMaterial    = 10
      #
      # Approximation mapping (AppleSemantic → UIBlurEffectStyle raw):
      #
      #   Menu              → systemUltraThinMaterial = 6  (thinnest; HIG menu is light)
      #   Popover           → systemMaterial          = 8
      #   Sidebar           → systemThinMaterial      = 7
      #   Sheet             → systemThickMaterial     = 9  (heaviest non-chrome)
      #   HeaderView        → systemChromeMaterial    = 10
      #   WindowBackground  → systemMaterial          = 8
      #   HUDWindow         → systemChromeMaterial    = 10
      #   Titlebar          → systemMaterial          = 8  (brief row 1)
      #   SystemResolved    → -1 (SENTINEL — caller must skip setEffect:)
      #
      # Brief.yml adapter_cardinality row 1 documents the approximation
      # is consumer-visible degradation; consumers wanting per-platform
      # fidelity beyond the approximation must override per-widget.
      #
      # NOTE: brief.yml's per-widget table cited stale raw integers
      # (Menu→8, Popover→7, etc.). The SDK-verified values above are
      # authoritative and were confirmed empirically via Codex review
      # round 3.
      private def uikit_blur_effect_style_for_semantic(semantic : UI::DesignTokens::AppleSemantic) : Int64
        case semantic
        in .menu?              then 6_i64  # UIBlurEffectStyleSystemUltraThinMaterial
        in .popover?           then 8_i64  # UIBlurEffectStyleSystemMaterial
        in .sidebar?           then 7_i64  # UIBlurEffectStyleSystemThinMaterial
        in .sheet?             then 9_i64  # UIBlurEffectStyleSystemThickMaterial
        in .header_view?       then 10_i64 # UIBlurEffectStyleSystemChromeMaterial
        in .window_background? then 8_i64  # UIBlurEffectStyleSystemMaterial (brief row 1)
        in .hud_window?        then 10_i64 # UIBlurEffectStyleSystemChromeMaterial
        in .titlebar?          then 8_i64  # UIBlurEffectStyleSystemMaterial (brief row 1)
        in .system_resolved?   then -1_i64 # SENTINEL — caller must skip setEffect:
        end
      end

      # Apply common View base-class properties to a raw UIKit view pointer.
      #
      #   - hidden       -> setHidden:
      #   - opacity      -> setAlpha:
      #   - background   -> setBackgroundColor: (UIColor)
      #   - corner_radius -> layer.cornerRadius (requires setClipsToBounds: YES)
      #   - clip_to_bounds -> setClipsToBounds:
      #   - shadow        -> layer shadow properties
      #   - border        -> layer borderWidth + borderColor
      #   - accessibility_label -> setAccessibilityLabel:
      private def apply_common_properties(ptr : Void*, view : UI::View) : Nil
        # Auto Layout requires translatesAutoresizingMaskIntoConstraints = NO on
        # every UIView that is managed by UIStackView or pinned with anchors.
        # Without this, the auto-resizing mask produces conflicting constraints
        # and inner UIStackViews report intrinsicContentSize of CGSizeZero,
        # collapsing to zero height in any parent UIStackView.
        LibObjCBridge.objc_send_bool(ptr, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)

        # Informational overlays opt out of hit-testing entirely — otherwise a
        # full-screen overlay (the demo "Demo only" ribbon) swallows every
        # touch aimed at the interactive content beneath it.
        if view.touch_passthrough
          LibObjCBridge.objc_send_bool(ptr, sel("setUserInteractionEnabled:"), 0)
        end

        # Hidden
        if view.hidden
          LibObjCBridge.objc_send_bool(ptr, sel("setHidden:"), 1)
        end

        # Opacity (UIView uses setAlpha:, not setAlphaValue:)
        if view.opacity < 1.0
          LibObjCBridge.objc_send_1d(ptr, sel("setAlpha:"), view.opacity)
        end

        # Background color
        if bg = view.background
          bg_color = resolve_color(bg)
          LibObjCBridge.objc_send_id(ptr, sel("setBackgroundColor:"), bg_color)
        end

        # Corner radius and clipping via CALayer
        if view.corner_radius > 0.0 || view.clip_to_bounds
          layer = LibObjCBridge.objc_send(ptr, sel("layer"))
          unless layer.null?
            if view.corner_radius > 0.0
              LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), view.corner_radius)
            end
          end
          if view.clip_to_bounds || view.corner_radius > 0.0
            LibObjCBridge.objc_send_bool(ptr, sel("setClipsToBounds:"), 1)
          end
        end

        # Shadow via CALayer
        if view.shadow_radius > 0.0
          layer = LibObjCBridge.objc_send(ptr, sel("layer"))
          unless layer.null?
            sc = view.shadow_color || UI::Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.3)
            shadow_color = resolve_color(sc)
            cg_color = LibObjCBridge.objc_send(shadow_color, sel("CGColor"))
            LibObjCBridge.objc_send_id(layer, sel("setShadowColor:"), cg_color)
            LibObjCBridge.objc_send_1d(layer, sel("setShadowOpacity:"), sc.a)
            LibObjCBridge.objc_send_1d(layer, sel("setShadowRadius:"), view.shadow_radius)
            # Shadow offset via CGSize struct (width, height) -- use 2d variant
            LibObjCBridge.objc_send_2d_ret_id(layer, sel("setShadowOffset:"),
              view.shadow_offset_x, view.shadow_offset_y)
          end
        end

        # Border via CALayer
        if view.border_width > 0.0
          layer = LibObjCBridge.objc_send(ptr, sel("layer"))
          unless layer.null?
            LibObjCBridge.objc_send_1d(layer, sel("setBorderWidth:"), view.border_width)
            if bc = view.border_color
              bc_color = resolve_color(bc)
              cg_border = LibObjCBridge.objc_send(bc_color, sel("CGColor"))
              LibObjCBridge.objc_send_id(layer, sel("setBorderColor:"), cg_border)
            end
          end
        end

        # Minimum / maximum height constraints from UI::View base properties.
        # These are applied via Auto Layout height anchors at priority 999 so they
        # coexist with UIStackView distribution without creating unsatisfiable
        # constraint conflicts.
        #   - minimum_height && maximum_height == minimum_height -> exact height
        #   - minimum_height only -> >= constraint (content can grow taller)
        #   - maximum_height only -> <= constraint (content can shrink shorter)
        min_h = view.minimum_height
        max_h = view.maximum_height
        if !min_h.nil? && !max_h.nil? && min_h == max_h
          # Exact height: both min and max are the same value.
          LibObjCBridge.objc_constrain_height(ptr, min_h.not_nil!)
        else
          if mh = min_h
            LibObjCBridge.objc_constrain_minimum_height(ptr, mh)
          end
          if mxh = max_h
            # Maximum height: heightAnchor <= max_h via a <= constraint.
            # Use objc_constrain_height (equality at 999) as an upper bound proxy —
            # when max_h alone is set without min_h, we treat it as exact (content
            # should not grow beyond this). This matches the UI::View semantics where
            # maximum_height is intended as a hard cap.
            LibObjCBridge.objc_constrain_height(ptr, mxh)
          end
        end

        # Minimum / maximum width constraints from UI::View base properties.
        # These mirror the height semantics above:
        #   - minimum_width && maximum_width == minimum_width -> exact width
        #   - minimum_width only -> >= constraint
        #   - maximum_width only -> exact cap proxy
        #
        # UIKit validation previews rely on exact min/max pairs for cards,
        # tiles, grabbers, and tab shells. Ignoring maximum_width lets
        # UIStackView stretch a component until text and chrome clip at the
        # screenshot edge.
        min_w = view.minimum_width
        max_w = view.maximum_width
        # UI::Fluid width is NOT handled here — it is applied in the container
        # visits (visit(VStack) etc.) via objc_constrain_fluid_width AFTER the
        # view is added to its superview, because the fluid "fill the parent,
        # capped at max" relation needs the superview's width anchor.
        if !min_w.nil? && !max_w.nil? && min_w == max_w
          LibObjCBridge.objc_constrain_required_width(ptr, min_w.not_nil!)
          LibObjCBridge.objc_set_horizontal_fixed_priority(ptr)
        else
          if mw = min_w
            LibObjCBridge.objc_constrain_minimum_width(ptr, mw)
          end
          if mxw = max_w
            LibObjCBridge.objc_constrain_width(ptr, mxw)
          end
        end

        # UI::View#fill_horizontal — the cross-platform flex-grow primitive. Lower the
        # horizontal content-hugging so UIStackView's Fill distribution stretches this
        # view to absorb the row's slack (e.g. a compose TextField growing beside a
        # fixed send button). Only meaningful without an exact width pin.
        if view.fill_horizontal
          LibObjCBridge.objc_set_horizontal_fill_priority(ptr)
        end

        # Phase 6.10 Rem 4 (Item 2D) — root_fill honors the current
        # device's runtime screen bounds. The Crystal-side author sets
        # `view.root_fill = true` (or chains `view.fill_screen!`) on
        # the outermost root of a screen; the renderer pins this view's
        # width to the live device screen width minus safe-area leading
        # / trailing insets so the content always tracks the real
        # device (iPhone 17 Pro = 402pt content; iPad Mini = 768pt
        # content; etc).
        #
        # Crucially this does NOT bake a per-device number into tokens
        # — `DeviceMetrics.current` queries `UIScreen.main.bounds` +
        # `keyWindow.safeAreaInsets` at render time.
        if view.root_fill && view.minimum_width.nil? && view.maximum_width.nil? && view.fluid_width.nil?
          metrics = UI::DesignTokens::DeviceMetrics.current
          fill_width = metrics.content_width_pt
          if fill_width > 0.0
            LibObjCBridge.objc_constrain_required_width(ptr, fill_width)
            LibObjCBridge.objc_set_horizontal_fixed_priority(ptr)
          end
        end

        # Accessibility label
        #
        # IMPORTANT (Phase 6.10 Rem 1): On UIKit, calling
        # `setAccessibilityLabel:` on a plain UIView (UIStackView included)
        # auto-promotes the view to `isAccessibilityElement = YES`, which
        # MASKS every descendant from the AX tree. For containers (VStack /
        # HStack / ZStack / ScrollView / NavigationStack / etc.) we want
        # the label to act as a "section title" the screen reader announces
        # AT the group, while the descendants stay individually navigable.
        # The fix: explicitly clamp `isAccessibilityElement = NO` for
        # container views and set it to YES for leaf controls. This mirrors
        # UIKit's intrinsic behavior for UIControl subclasses (which default
        # to YES) and UIView (which defaults to NO).
        is_container = view.is_a?(UI::VStack) || view.is_a?(UI::HStack) ||
                       view.is_a?(UI::ZStack) || view.is_a?(UI::ScrollView) ||
                       view.is_a?(UI::NavigationStack) || view.is_a?(UI::NavigationLink) ||
                       view.is_a?(UI::Form) || view.is_a?(UI::Grid) ||
                       view.is_a?(UI::Card) || view.is_a?(UI::Surface)
        if a11y = view.accessibility_label
          a11y_str = LibObjCBridge.nsstring_from_cstr(a11y.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityLabel:"), a11y_str)
          # If this is a container, force isAccessibilityElement = NO so
          # children remain visible to the AX tree. Without this, the
          # whole subtree collapses into a single opaque AX element with
          # the container's label and XCUITest cannot find the leaves.
          if is_container
            LibObjCBridge.objc_send_bool(ptr, sel("setIsAccessibilityElement:"), 0)
          end
        elsif is_container
          # Even without a label, defensively clamp to NO. UIStackView
          # alone is fine (defaults to NO), but UIScrollView wraps a
          # content view that some code paths may have promoted via a
          # later setter — we want the consistent contract.
          LibObjCBridge.objc_send_bool(ptr, sel("setIsAccessibilityElement:"), 0)
        end

        # Phase 10B.2a — Accessibility hint -> setAccessibilityHint:.
        # UIKit reads this string AFTER the label, with a brief pause, to
        # explain the result of activating the element ("Double-tap to
        # open settings").
        if hint = view.accessibility_hint
          hint_str = LibObjCBridge.nsstring_from_cstr(hint.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityHint:"), hint_str)
        end

        # Phase 10B.2a — Accessibility value -> setAccessibilityValue:.
        if value = view.accessibility_value
          value_str = LibObjCBridge.nsstring_from_cstr(value.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityValue:"), value_str)
        end

        # Phase 10B.2a — Accessibility traits. UIKit traits are a
        # `UIAccessibilityTraits` bitmask (UInt64). We OR the requested
        # symbols together and call `setAccessibilityTraits:`. Unmapped
        # symbols silently fall through.
        unless view.accessibility_traits.empty?
          mask = 0_u64
          view.accessibility_traits.each do |trait|
            mask |= uikit_trait_bitmask(trait)
          end
          if mask != 0_u64
            LibObjCBridge.objc_send_ulong(ptr, sel("setAccessibilityTraits:"), mask)
          end

          # Iter 2 (Codex Finding 3): `:not_enabled` is the canonical
          # disable trait. In addition to the accessibility trait flag
          # above, functionally disable the underlying UIControl (button,
          # switch, slider, segmented control, etc.) via setEnabled:NO.
          # The helper guards on respondsToSelector: so plain UIViews
          # silently no-op.
          if view.accessibility_traits.includes?(:not_enabled)
            LibObjCBridge.ap_set_enabled_if_responds(ptr, 0)
          end
        end

        # Phase 10B.2a — Role inference for UIKit happens via traits, not
        # an explicit role setter. When the explicit / default role maps
        # to a trait (e.g. `:header` -> `UIAccessibilityTraitHeader`,
        # `:button` -> `UIAccessibilityTraitButton`) OR it onto the
        # existing traits mask. `:none` and roles with no trait analog
        # fall through unchanged.
        if role_sym = view.effective_accessibility_role
          role_trait = uikit_role_trait_bitmask(role_sym)
          if role_trait != 0_u64
            # Compose with any explicit traits already set.
            existing = view.accessibility_traits.empty? ? 0_u64 : view.accessibility_traits.reduce(0_u64) { |a, t| a | uikit_trait_bitmask(t) }
            LibObjCBridge.objc_send_ulong(ptr, sel("setAccessibilityTraits:"), existing | role_trait)
          end
        end

        # Phase 10B.2a — Explicit accessibility_identifier wins over
        # test_id on UIKit, mirroring the AppKit precedence.
        if aid = view.accessibility_identifier
          aid_str = LibObjCBridge.nsstring_from_cstr(aid.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityIdentifier:"), aid_str)
        elsif tid = view.test_id
          tid_str = LibObjCBridge.nsstring_from_cstr(tid.to_unsafe)
          LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityIdentifier:"), tid_str)
        end

        # Phase 10D-polish iter 2 (B-POPOVER-ANCHOR-VIEW) — register
        # this view's ObjC pointer under its test_id so a later
        # UI::Popover visit can look up the anchor source view.
        if tid = view.test_id
          @test_id_registry[tid] = ptr
        end

        # Phase 10B.2b — Custom accessibility actions. Each action gets
        # registered with the CallbackRegistry (so Crystal keeps a
        # strong reference to the Proc) and the returned token is passed
        # to `ap_view_add_accessibility_custom_action` which builds a
        # block-based UIAccessibilityCustomAction and appends it to the
        # view's accessibilityCustomActions array.
        view.accessibility_actions.each do |action|
          token = UI::CallbackRegistry.register(action.callback)
          LibObjCBridge.ap_view_add_accessibility_custom_action(
            ptr, action.name.to_unsafe, token)
        end

        # Phase 10B.2b — Keyboard shortcut. UIKit `UIKeyCommand` is
        # attached via the host UIViewController's `addKeyCommand:`;
        # for plain UIViews we buffer the command on an associated
        # object so a containing VC can read it back (best-effort —
        # the brief lists this as expected behavior; raw UIView has
        # no first-class key-commands setter).
        if ks = view.keyboard_shortcut
          # We register a sentinel callback so the dispatcher token
          # routes back to a no-op if no app-level action_token was
          # supplied — keyboard shortcuts typically duplicate an
          # action that's already wired via the widget's button
          # target/action, so the token here is the safety net.
          token = UI::CallbackRegistry.register(-> { nil.as(Nil) })
          LibObjCBridge.ap_view_add_key_command(
            ptr, ks.key.to_unsafe, ks.uikit_modifier_mask, token)
        end

        # Phase 10B.2b — Focus management. When `focused` is true the
        # view becomes first responder right after render. Mutation of
        # `focused` at runtime is honored by the reactive dispatcher's
        # rerender path (see `UI::ActionDispatcher#apply`).
        if view.focused
          LibObjCBridge.ap_view_become_first_responder(ptr)
        end

        # Phase 10B.2b — Focusability override. When the caller set
        # `focusable = false` explicitly we mark the view as a NON-
        # accessibility element so VoiceOver / keyboard focus skips it.
        # When `focusable = true` is set on a non-default-focusable
        # widget (e.g. a Label or container) we flip it on. The widget
        # default already aligns with UIKit's intrinsic focus model.
        case view.focusable
        when false
          LibObjCBridge.objc_send_bool(ptr, sel("setIsAccessibilityElement:"), 0)
        when true
          # Only flip on for views whose default IS false — otherwise the
          # existing container clamp logic above already handled it.
          unless view.default_focusable
            LibObjCBridge.objc_send_bool(ptr, sel("setIsAccessibilityElement:"), 1)
          end
        end

        # Discrete gesture surface — swipe (4 directions) + long-press.
        #
        # Tokens are registered in the CallbackRegistry (strong Crystal reference)
        # and the bridge pins the target object on the native view via
        # objc_setAssociatedObject so the Proc stays alive for the view's lifetime.
        # Token teardown mirrors the accessibility_actions pattern used above:
        # tokens are not tracked on NativeView here because `native` is not yet
        # constructed at the `apply_common_properties` call site. Call sites that
        # need strict teardown tracking can call `native.track_callback_id` on the
        # IDs returned from a separate helper if needed in a future phase.
        #
        # UISwipeGestureRecognizer: cancelsTouchesInView defaults to YES so the
        # swipe gesture takes priority over incidental child-button touches in
        # the swiped area (standard iOS list-row swipe behavior).
        if handlers = view.swipe_handlers
          handlers.each do |direction, handler|
            token = UI::CallbackRegistry.register(handler)
            dir_int = direction.value.to_i32
            LibObjCBridge.objc_attach_swipe_gesture(ptr, dir_int, token)
          end
        end

        # UILongPressGestureRecognizer (0.5 s threshold). cancelsTouchesInView
        # is set to NO by the bridge so short taps on child buttons fire normally.
        if lp = view.on_long_press
          token = UI::CallbackRegistry.register(lp)
          LibObjCBridge.objc_attach_long_press_gesture(ptr, token, 0.5_f64)
        end
      end

      # Phase 10B.2a — Map a Crystal trait symbol to the matching
      # `UIAccessibilityTraits` bitmask value. The constants below are
      # the documented public values; unmapped traits return 0.
      #
      # Values per Apple's `UIAccessibilityConstants.h`
      # (UIAccessibility, iOS 16+):
      #   UIAccessibilityTraitButton              = 1 << 0  (0x0001)
      #   UIAccessibilityTraitLink                = 1 << 1  (0x0002)
      #   UIAccessibilityTraitSearchField         = 1 << 2  (0x0004)
      #   UIAccessibilityTraitImage               = 1 << 3  (0x0008)
      #   UIAccessibilityTraitSelected            = 1 << 4  (0x0010)
      #   UIAccessibilityTraitPlaysSound          = 1 << 5  (0x0020)
      #   UIAccessibilityTraitKeyboardKey         = 1 << 6  (0x0040)
      #   UIAccessibilityTraitStaticText          = 1 << 7  (0x0080)
      #   UIAccessibilityTraitSummaryElement      = 1 << 8  (0x0100)
      #   UIAccessibilityTraitNotEnabled          = 1 << 9  (0x0200)
      #   UIAccessibilityTraitUpdatesFrequently   = 1 << 10 (0x0400)
      #   UIAccessibilityTraitStartsMediaSession  = 1 << 11 (0x0800)
      #   UIAccessibilityTraitAdjustable          = 1 << 12 (0x1000)
      #   UIAccessibilityTraitAllowsDirectInteraction = 1 << 13 (0x2000)
      #   UIAccessibilityTraitCausesPageTurn      = 1 << 14 (0x4000)
      #   UIAccessibilityTraitTabBar              = 1 << 15 (0x8000)
      #   UIAccessibilityTraitHeader              = 1 << 16 (0x10000)
      #
      # Iter 2 (Codex Finding 2): corrected previously incorrect bit
      # positions for Selected, NotEnabled, PlaysSound, StartsMediaSession,
      # CausesPageTurn, UpdatesFrequently, AllowsDirectInteraction, and
      # is_busy (now no analog — UIKit has no "busy" trait; remove the
      # bogus SummaryElement mapping).
      private def uikit_trait_bitmask(trait : Symbol) : UInt64
        case trait
        when :selected                  then 0x0000000000000010_u64 # Selected (1 << 4)
        when :not_enabled               then 0x0000000000000200_u64 # NotEnabled (1 << 9)
        when :plays_sound               then 0x0000000000000020_u64 # PlaysSound (1 << 5)
        when :starts_media              then 0x0000000000000800_u64 # StartsMediaSession (1 << 11)
        when :causes_page_turn          then 0x0000000000004000_u64 # CausesPageTurn (1 << 14)
        when :updates_frequently        then 0x0000000000000400_u64 # UpdatesFrequently (1 << 10)
        when :is_busy                   then 0_u64                  # No UIKit trait — UIKit has no "busy" analog
        when :allows_direct_interaction then 0x0000000000002000_u64 # AllowsDirectInteraction (1 << 13)
        when :adjustable                then 0x0000000000001000_u64 # Adjustable (1 << 12)
        when :is_required               then 0_u64                  # No UIKit trait
        when :is_invalid                then 0_u64                  # No UIKit trait
        else                                 0_u64
        end
      end

      # Phase 10B.2a — Translate a role symbol into a UIAccessibilityTrait
      # bitmask. UIKit doesn't have a separate "role" channel; it overloads
      # the traits bitmask with role flags like `Button`, `Header`,
      # `Link`, `Image`, `SearchField`. Roles UIKit doesn't represent as
      # a trait return 0 — the underlying UIKit class typically already
      # carries the correct intrinsic role.
      #
      # Iter 2 (Codex Finding 2): corrected SearchField (was 0x80000,
      # actual 0x0004), StaticText (was 0x40000, actual 0x0080), and
      # TabBar (was 1 << 29, actual 1 << 15 = 0x8000).
      private def uikit_role_trait_bitmask(role : Symbol) : UInt64
        case role
        when :button      then 0x0000000000000001_u64 # Button (1 << 0)
        when :link        then 0x0000000000000002_u64 # Link (1 << 1)
        when :header      then 0x0000000000010000_u64 # Header (1 << 16)
        when :image, :img then 0x0000000000000008_u64 # Image (1 << 3)
        when :search      then 0x0000000000000004_u64 # SearchField (1 << 2)
        when :text        then 0x0000000000000080_u64 # StaticText (1 << 7)
        when :tab         then 0x0000000000008000_u64 # TabBar (1 << 15)
        else                   0_u64
        end
      end

      # Push a container NativeView onto the nesting stack.
      private def push_stack(native : NativeView, is_uistack : Bool) : Nil
        @stack.push(native)
        @stack_is_uistack.push(is_uistack)
      end

      # Pop the top container from the nesting stack.
      private def pop_stack : Nil
        @stack.pop
        @stack_is_uistack.pop
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
      # without adding it to the current parent stack.  Used by UIScrollView
      # to obtain the content view pointer for uiscrollview_pin_content wiring.
      private def render_detached(view : UI::View) : NativeView?
        saved_stack = @stack.dup
        saved_is_uistack = @stack_is_uistack.dup
        saved_result = @result
        @stack = [] of NativeView
        @stack_is_uistack = [] of Bool
        @result = nil
        view.accept(self)
        detached = @result
        @stack = saved_stack
        @stack_is_uistack = saved_is_uistack
        @result = saved_result
        detached
      end

      private def apply_stack_padding(ptr : Void*, view : UI::View) : Nil
        p = view.padding
        return unless p.top > 0.0 || p.leading > 0.0 || p.bottom > 0.0 || p.trailing > 0.0

        insets = LibObjCBridge::CGRect.new(x: p.top, y: p.leading, width: p.bottom, height: p.trailing)
        LibObjCBridge.objc_send_rect_void(ptr, sel("setLayoutMargins:"), insets)
        LibObjCBridge.objc_send_bool(ptr, sel("setLayoutMarginsRelativeArrangement:"), 1)
      end

      private def exact_card_label_preferred_width(view : UI::Card) : Float64?
        min_w = view.minimum_width
        max_w = view.maximum_width
        return nil unless min_w && max_w && min_w == max_w

        p = view.content_padding
        content_width = min_w - p.leading - p.trailing
        content_width > 0.0 ? content_width : nil
      end

      # Wrap a raw pointer in NativeHandle + NativeView and register it
      # with the current parent or set as root result.
      #
      # This is the standard emit path for leaf views (Label, Image, Spacer)
      # that do not need custom callback registration.
      #
      # Sets translatesAutoresizingMaskIntoConstraints = NO unconditionally so
      # that every emitted view is Auto Layout-managed. This mirrors the same
      # call made in apply_common_properties for views that go through the
      # full visit path; inline-constructed views (separators, grid padding,
      # header labels) need the same treatment or the intrinsic-size chain
      # breaks in any UIStackView parent.
      private def emit(ptr : Void*, label : String) : Nil
        LibObjCBridge.objc_send_bool(ptr, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)
        handle = ObjC.owned(ptr, label: label)
        native = NativeView.new(handle)
        push_native(native)
      end

      # Register a NativeView with the current parent container, or set it
      # as the root result if there is no parent.
      #
      # When inside a container (VStack/HStack/ZStack/ScrollView), this:
      #   1. Adds the NativeView as a child of the parent NativeView tree
      #   2. Adds the native UIKit view to the parent:
      #      - UIStackView parents use addArrangedSubview: (preserves stack ordering)
      #      - Plain UIView parents use addSubview: (ZStack, ScrollView content)
      private def push_native(native : NativeView) : Nil
        if parent = @stack.last?
          parent.add_child(native)

          # Add native UIKit view to parent's native view
          if parent.handle.valid? && native.handle.valid?
            parent_ptr = parent.handle.ptr!
            child_ptr = native.handle.ptr!

            # Use the parallel tracking array to decide add method
            if @stack_is_uistack.last?
              LibObjCBridge.objc_send_void_id(parent_ptr, sel("addArrangedSubview:"), child_ptr)
            else
              LibObjCBridge.objc_add_subview(parent_ptr, child_ptr)
            end
          end
        else
          @result = native
        end
      end
    end
  end
{% end %}
