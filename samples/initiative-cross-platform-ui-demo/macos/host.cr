# Phase 6 macOS host — renders one demo screen by slug in a native
# AppKit window. Used by:
#   - human exploration (`make macos run SLUG=demo-dashboard`)
#   - AXTest screenshots (`HIG_SCREENSHOT_PATH=/tmp/foo.png HIG_SLUG=demo-detail bin/cascade`)
#
# Slug source: ENV["DEMO_SLUG"] || ARGV[0] || "demo-sign-in".
#
# Build: `make -C samples/initiative-cross-platform-ui-demo macos`.
# That target compiles the asset_pipeline ObjC bridge, the
# AssetPipelineSwiftKit Swift facade, and a tiny window_helper.m
# (reused verbatim from samples/cross_platform/macos_host) before
# `crystal-alpha build -Dmacos`.

require "../app"
require "../../../src/ui/renderers/appkit_renderer"

{% if flag?(:macos) %}
  SLUG = ENV["DEMO_SLUG"]? || ARGV[0]? || "demo-sign-in"
  APPEARANCE = ENV["DEMO_APPEARANCE"]? || ENV["HIG_APPEARANCE"]? || "light"

  # Window helper compiled into the binary at link time (see Makefile).
  # The same window_helper.m the existing HIG host uses — we reuse it
  # verbatim rather than fork it.
  lib LibWindowHelper
    fun hig_create_window(x : Float64, y : Float64, w : Float64, h : Float64, title : UInt8*) : Void*
    fun hig_run_app(window : Void*) : Void
    fun objc_create_capture_window(width : Float64, height : Float64, appearance : UInt8*) : Void*
    fun objc_install_content_view(window : Void*, content_view : Void*) : Void
    fun objc_capture_view_offscreen(window : Void*, output_path : UInt8*, width : Float64, height : Float64) : Int32
    fun objc_capture_window_to_png(window : Void*, output_path : UInt8*) : Int32
    fun objc_close_capture_window(window : Void*) : Void
    fun objc_run_loop_for(seconds : Float64) : Void
  end

  lib LibObjCBridgeCascade
    fun objc_send_void_id(obj : Void*, sel : Void*, arg : Void*) : Void
    fun sel_registerName(name : UInt8*) : Void*
  end

  module CascadeHost
    def self.build_view_for(slug : String) : UI::View
      state = InitiativeDemo::State.new
      InitiativeDemo.build_screen(slug, state)
    end

    # Window dimensions chosen to approximate a modest mac window. The
    # screenshot path will use a slightly smaller capture window so the
    # output PNGs are comparable across surfaces.
    WINDOW_WIDTH  = 880.0
    WINDOW_HEIGHT = 720.0

    CAPTURE_WIDTH  = 720.0
    CAPTURE_HEIGHT = 640.0

    def self.run!
      focal = build_view_for(SLUG)
      renderer = UI::AppKit::Renderer.new
      renderer.design_tokens = InitiativeDemo.brand_tokens
      native = renderer.render(focal)
      gc_guard = native

      screenshot_path = ENV["HIG_SCREENSHOT_PATH"]?
      if screenshot_path
        # Offscreen capture path — used by the AXTest harness + the
        # quad-comparison capture script. We use the offscreen
        # cacheDisplayInRect helper which does NOT require Screen
        # Recording TCC permission; layout is faithful even though
        # NSVisualEffectView blur degrades to a solid fill.
        title = "Cascade: #{SLUG} (#{APPEARANCE}) capture"
        window = LibWindowHelper.objc_create_capture_window(CAPTURE_WIDTH, CAPTURE_HEIGHT, APPEARANCE.to_unsafe)
        LibWindowHelper.objc_install_content_view(window, native.handle.ptr!)
        LibWindowHelper.objc_run_loop_for(0.4) # settle layout
        rc = LibWindowHelper.objc_capture_view_offscreen(
          window, screenshot_path.to_unsafe, CAPTURE_WIDTH, CAPTURE_HEIGHT,
        )
        LibWindowHelper.objc_close_capture_window(window)
        STDERR.puts "[cascade] screenshot rc=#{rc} -> #{screenshot_path}"
        gc_guard
        # window_helper.m returns 1 for success, 0 for failure.
        # Translate to process exit code (0 success, 1 failure).
        exit(rc == 1 ? 0 : 1)
      end

      # Interactive path — open a titled window on screen and run the
      # AppKit run loop until the user quits the app.
      title_str = "Cascade: #{SLUG}"
      window = LibWindowHelper.hig_create_window(120.0, 120.0, WINDOW_WIDTH, WINDOW_HEIGHT, title_str.to_unsafe)
      set_content = LibObjCBridgeCascade.sel_registerName("setContentView:".to_unsafe)
      LibObjCBridgeCascade.objc_send_void_id(window, set_content, native.handle.ptr!)
      LibWindowHelper.hig_run_app(window)
      gc_guard
    end
  end

  CascadeHost.run!
{% else %}
  STDERR.puts "samples/initiative-cross-platform-ui-demo/macos/host.cr must be built with -Dmacos"
  exit 1
{% end %}
