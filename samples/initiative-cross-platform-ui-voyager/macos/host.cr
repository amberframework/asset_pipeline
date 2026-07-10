# Phase 6.10 + Phase 8D.1 — Voyager macOS host.
#
# Phase 6.10 shape: a NavigationCoordinator-driven AppKit app — initial
# build, install as NSWindow contentView, subscribe to `coord.on_change`,
# swap contentView on every push / pop / replace_root.
#
# Phase 8D.1 migration: user-intent callbacks now flow through
# `UI::ActionDispatcher`. The host:
#   1. Calls `VoyagerApp.bootstrap!` to register the 4 screens.
#   2. Creates a `UI::NavigationCoordinator` + `UI::AppKit::Renderer` +
#      session + flash + `UI::ActionDispatcher`.
#   3. Assigns `Voyager.dispatcher = dispatcher` so screen callback
#      closures route action refs through the dispatcher.
#   4. Calls `dispatcher.mount_screen(coord.current)` to seed the
#      mount-scoped FormState before the initial render.
#   5. Subscribes to `coord.on_change` with a renderer-only callback
#      that does NOT call mount_screen (per the brief's stack-policy
#      contract + spike pattern — the dispatcher's translate_result
#      already mounts before notify).
#
# Slug source: ENV["VOYAGER_ROOT_SLUG"] || ARGV[0] || "voyager-sign-in".
# Set VOYAGER_ROOT_SLUG=voyager-todos to skip the auth flow during
# manual verification.

require "../app"
require "../../../src/ui/renderers/appkit_renderer"

{% if flag?(:macos) %}
  ROOT_SLUG  = ENV["VOYAGER_ROOT_SLUG"]? || ARGV[0]? || "voyager-sign-in"
  APPEARANCE = ENV["VOYAGER_APPEARANCE"]? || ENV["HIG_APPEARANCE"]? || "light"

  # Window helper compiled into the binary at link time (see Makefile).
  lib LibWindowHelper
    fun hig_create_window(x : Float64, y : Float64, w : Float64, h : Float64, title : UInt8*) : Void*
    fun hig_create_window_with_min(
      x : Float64, y : Float64, w : Float64, h : Float64,
      min_w : Float64, min_h : Float64,
      title : UInt8*, appearance : UInt8*,
    ) : Void*
    fun hig_run_app(window : Void*) : Void
    fun objc_create_capture_window(width : Float64, height : Float64, appearance : UInt8*) : Void*
    fun objc_install_content_view(window : Void*, content_view : Void*) : Void
    fun objc_capture_view_offscreen(window : Void*, output_path : UInt8*, width : Float64, height : Float64) : Int32
    fun objc_capture_window_to_png(window : Void*, output_path : UInt8*) : Int32
    fun objc_close_capture_window(window : Void*) : Void
    fun objc_run_loop_for(seconds : Float64) : Void
  end

  lib LibObjCBridgeVoyager
    fun objc_send_void_id(obj : Void*, sel : Void*, arg : Void*) : Void
    fun sel_registerName(name : UInt8*) : Void*
  end

  module VoyagerHost
    WINDOW_WIDTH  = 880.0
    WINDOW_HEIGHT = 640.0
    MIN_WIDTH     = 480.0
    MIN_HEIGHT    = 400.0

    CAPTURE_WIDTH  = (ENV["VOYAGER_CAPTURE_WIDTH"]?.try(&.to_f?) || 720.0)
    CAPTURE_HEIGHT = (ENV["VOYAGER_CAPTURE_HEIGHT"]?.try(&.to_f?) || 640.0)

    # GC-pinned references so the AppKit run loop doesn't collect the
    # Crystal-side state, coordinator, renderer, dispatcher, or active
    # NativeView. NONE carry default initializers — explicit assignment
    # in `run!` so the iOS class-init gap pattern is symmetric across
    # hosts (macOS doesn't suffer the gap; we keep the discipline so the
    # iOS bridge can lift this pattern in Phase 8D.2 unchanged).
    @@coord : UI::NavigationCoordinator? = nil
    @@renderer : UI::AppKit::Renderer? = nil
    @@dispatcher : UI::ActionDispatcher? = nil
    @@window_ptr : Void* = Pointer(Void).null
    @@set_content_sel : Void* = Pointer(Void).null
    @@active_native : UI::NativeView? = nil
    # Tracks whether we're on the capture-window pair (objc_install_content_view)
    # or the regular NSWindow path (setContentView: via objc_send_void_id).
    # Set in `run!` once the window is created.
    @@is_capture_path : Bool = false

    def self.install_view(view : UI::View) : Nil
      renderer = @@renderer.not_nil!
      native = renderer.render(view)
      @@active_native = native
      if @@is_capture_path
        LibWindowHelper.objc_install_content_view(@@window_ptr, native.handle.ptr!)
      else
        LibObjCBridgeVoyager.objc_send_void_id(
          @@window_ptr, @@set_content_sel, native.handle.ptr!,
        )
      end
    end

    # Render the route the dispatcher just mounted (FormState already
    # swapped via translate_result's mount-before-notify ordering).
    def self.rebuild_for(route : UI::NavigationCoordinator::Route) : Nil
      dispatcher = @@dispatcher.not_nil!
      reg = VoyagerApp.registration_for(route.id)
      screen_class = reg.screen_class
      if screen_class.nil?
        placeholder = UI::Label.new("Unknown screen for route: #{route.id}")
        placeholder.accessibility_label = "Unknown route"
        install_view(placeholder.as(UI::View))
        return
      end

      # Build a fresh ScreenContext::Native from the dispatcher's live
      # FormState / session / flash / design_tokens / navigation. This
      # is the proven Phase 8B spike pattern
      # (samples/phase-08b-native-spike/src/spike_app.cr#rebuild_for).
      # action_params is empty at render time — it only carries values
      # during in-flight dispatches.
      ctx = UI::ScreenContext::Native.new(
        form_state: dispatcher.current_form_state,
        session: dispatcher.session,
        flash: dispatcher.flash,
        design_tokens: dispatcher.design_tokens,
        navigation: dispatcher.navigation,
        action_params: {} of String => String,
      )
      view = screen_class.new.build(ctx)
      install_view(view)
    end

    def self.run!
      # Phase 8D.1 — bootstrap registers all 4 screens. macOS doesn't
      # suffer the iOS class-init gap but we keep the call symmetric
      # with the spike + the iOS bridge (Phase 8D.2 will use the same
      # call).
      VoyagerApp.bootstrap!

      # Seed the singleton state so screens that read `Voyager.state`
      # see the same instance across all 4 routes.
      Voyager.state = Voyager::State.new

      coord = UI::NavigationCoordinator.new(Voyager.route_for_slug(ROOT_SLUG))
      renderer = UI::AppKit::Renderer.new
      session = UI::Session::InProcess.new
      flash = UI::Flash::InProcess.new

      dispatcher = UI::ActionDispatcher.new(
        app: VoyagerApp,
        navigation: coord,
        session: session,
        flash: flash,
        design_tokens: UI::DesignTokens::Tokens.default,
      )
      # Initial mount — bumps the dispatcher's mount_token + seeds
      # form_state from coord.current.params + swaps the renderer's
      # wire-time FormState. Must happen BEFORE the first render so
      # the TextField wire-time hook sees the new mount.
      dispatcher.mount_screen(coord.current)

      @@coord = coord
      @@renderer = renderer
      @@dispatcher = dispatcher

      # Phase 8D.1 — wire screens to dispatch through this host's
      # dispatcher.
      Voyager.dispatcher = dispatcher

      # Phase 8D.3b — capture-scenario hook. When the host launches with
      # VOYAGER_CAPTURE_SCENARIO set (driven by bin/capture_voyager_macos.sh),
      # walk state + coord + dispatcher into the target visual end state
      # BEFORE rebuild_for(coord.current) is called (either the capture
      # branch below or the interactive branch). No-op when unset.
      if scenario = ENV["VOYAGER_CAPTURE_SCENARIO"]?
        Voyager::CaptureScenarios.apply(scenario, Voyager.state, coord, dispatcher)
      end

      screenshot_path = ENV["VOYAGER_SCREENSHOT_PATH"]? || ENV["HIG_SCREENSHOT_PATH"]?
      if screenshot_path
        # Offscreen capture path — capture window is a Void** pair.
        window = LibWindowHelper.objc_create_capture_window(CAPTURE_WIDTH, CAPTURE_HEIGHT, APPEARANCE.to_unsafe)
        @@window_ptr = window
        @@is_capture_path = true

        rebuild_for(coord.current)
        LibWindowHelper.objc_run_loop_for(0.4)
        rc = LibWindowHelper.objc_capture_view_offscreen(
          window, screenshot_path.to_unsafe, CAPTURE_WIDTH, CAPTURE_HEIGHT,
        )
        LibWindowHelper.objc_close_capture_window(window)
        STDERR.puts "[voyager] screenshot rc=#{rc} -> #{screenshot_path}"
        exit(rc == 1 ? 0 : 1)
      end

      # Interactive path — titled NSWindow + setContentView:.
      title_str = "Voyager"
      appearance_arg = if ENV["VOYAGER_APPEARANCE"]? || ENV["HIG_APPEARANCE"]?
                         APPEARANCE.to_unsafe
                       else
                         Pointer(UInt8).null
                       end
      window = LibWindowHelper.hig_create_window_with_min(
        120.0, 120.0, WINDOW_WIDTH, WINDOW_HEIGHT,
        MIN_WIDTH, MIN_HEIGHT,
        title_str.to_unsafe, appearance_arg,
      )
      set_content = LibObjCBridgeVoyager.sel_registerName("setContentView:".to_unsafe)
      @@window_ptr = window
      @@set_content_sel = set_content
      @@is_capture_path = false

      # Initial render of the bootstrap route.
      rebuild_for(coord.current)

      # The reactive substrate: every dispatcher-routed Navigate / Pop /
      # ReplaceRoot fires `translate_result`, which calls mount_screen
      # FIRST (swapping FormState.current under the new token) and THEN
      # invokes the coord op that fires this on_change. The subscriber
      # here only RENDERS — no mount_screen call. Per brief Item 4 +
      # spike pattern.
      coord.on_change do |route|
        VoyagerHost.rebuild_for(route)
      end

      STDERR.puts "[voyager macos] launching with root slug=#{ROOT_SLUG} appearance=#{APPEARANCE}"
      LibWindowHelper.hig_run_app(window)
    end
  end

  VoyagerHost.run!
{% else %}
  STDERR.puts "samples/initiative-cross-platform-ui-voyager/macos/host.cr must be built with -Dmacos"
  exit 1
{% end %}
