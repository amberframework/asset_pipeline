# Phase 6.10 — Voyager iOS bridge — exposed via build_crystal_lib.sh
# as libvoyager.a.
#
# C ABI:
#   void  voyager_init(void)
#       — must be called once before any render call. Seeds Crystal
#         probe singletons + builds the shared NavigationCoordinator
#         + State, both as INSTANCE state pinned in a module class
#         var (no class-var initializers — per the iOS class-init gap
#         memory item; we explicitly assign in voyager_init, never via
#         a class-var default value with side effects).
#
#   void* voyager_render(const char* slug)
#       — Builds a UI::View for the given slug (overrides any Crystal-
#         side current route; Swift drives the visible slug via the
#         @State binding). Renders via UIKit::Renderer and returns the
#         retained UIView*. Swift takes ownership via
#         takeRetainedValue().
#
#   const char* voyager_current_slug(void)
#       — Returns the slug-form of `coord.current.id` as a NUL-terminated
#         C string. The pointer is to a stable Crystal-managed buffer;
#         Swift may use it immediately but must not retain past the next
#         Crystal call. Used by the SwiftUI re-render trampoline.
#
#   void voyager_register_route_changed_callback(void (*cb)(const char*))
#       — Registers a C-callable Swift function pointer that Crystal
#         invokes inside coord.on_change with the new slug. This is the
#         runtime-navigation bridge: tapping a Crystal-rendered button
#         calls coord.push(...), which fires the registered callback,
#         which trips a Swift @State update, which causes SwiftUI to
#         re-render via voyager_render(new_slug).
#
# This file is the iOS-only twin of
# samples/initiative-cross-platform-ui-demo/ios/bridge.cr; both share
# the same cross-compile pattern documented in
# samples/initiative-cross-platform-ui-demo/ios/build_crystal_lib.sh.

{% if flag?(:ios) %}

  require "../app"
  require "../host_bootstrap"
  require "../../../src/ui/renderers/uikit_renderer"
  require "../../../src/ui/probes"

  module VoyagerBridge
    # Mirror Cascade's bridge: instance state held in module class
    # variables, but NO initializer side effects — explicit assignment
    # in initialize_runtime so the iOS class-init gap can't strand any
    # of these as nil.
    # IMPORTANT: NONE of these class vars carry an initializer with side
    # effects (no `= Bytes.new(64)`, no `= [] of ...`). The iOS class-init
    # gap (see `project_crystal_ios_class_init_gap` memory) silently
    # SKIPS class-var initializers when _main is hidden for Swift @main,
    # so any allocation that should happen at module load must happen
    # inside `initialize_runtime` (which we call explicitly from
    # voyager_init). Nilable defaults (`= nil`) are safe — the
    # underlying field is just a tagged nil pointer.
    @@initialized = false
    @@state : Voyager::State? = nil
    @@coord : UI::NavigationCoordinator? = nil
    # Phase 8D.2 — new collaborators owned by the dispatcher substrate.
    # `Voyager::HostBootstrap.build` constructs all four and we pin them
    # here so the GC doesn't collect them between Swift round-trips.
    # All declared as nilable with `= nil` defaults: iOS class-init gap
    # discipline (no initializer side effects).
    @@session : UI::Session::InProcess? = nil
    @@flash : UI::Flash::InProcess? = nil
    @@dispatcher : UI::ActionDispatcher? = nil
    @@last_native : UI::NativeView? = nil
    @@current_slug_buf : Bytes? = nil
    @@swift_route_changed_cb : (LibC::Char* -> Void)? = nil
    # Phase 6.10 Rem 4 — suppress the Swift route-changed callback
    # during the initial coord/slug resync (see render_slug). Without
    # this guard, replace_root → notify → Swift cb → render_slug →
    # resync loop fires recursively.
    @@suppress_route_changed = false

    def self.initialize_runtime
      return if @@initialized
      GC.init

      # Phase 6.10 Rem 3 — iOS class-init gap: bootstrap the Crystal
      # runtime subsystems that `__crystal_main`'s `init_runtime`
      # normally calls but the iOS embedding skips (because
      # `_main` is unexported in `build_crystal_lib.sh`).
      #
      # Without these three calls, any `Crystal::once`-guarded constant
      # (e.g. `String::CHAR_TO_DIGIT` used by `String#to_i?`) walks an
      # uninitialised `Thread::LinkedList(Fiber)` and SIGSEGVs at
      # `Thread::LinkedList(Fiber)#push` (KERN_INVALID_ADDRESS at 0x18).
      # Symptom in Rem 2: launching with
      # `VOYAGER_ROOT_SLUG=voyager-todo-editor` crashed silently inside
      # `Voyager.build_route` because the editor's
      # `(route.params[:id]? || "0").to_i?` triggered a const_read.
      # Crash trace preserved at
      # `~/Library/Logs/DiagnosticReports/VoyagerDemo-2026-05-23-155642.ips`.
      #
      # See `src/crystal/main.cr#init_runtime` for the upstream
      # invariant; the comment there reads:
      #   "`__crystal_once` directly or indirectly depends on `Fiber`
      #   and `Thread` so we explicitly initialize their class vars,
      #   then init crystal/once".
      #
      # This is the systematic fix the
      # `project_crystal_ios_class_init_gap` memory item flagged as
      # "Phase 5+ should address this systematically: either patch the
      # iOS embedding to explicitly call the missing init functions ..."
      Thread.init
      Fiber.init
      Crystal::Once.init

      UI::Probes::DismissProbe.reset
      UI::Probes::ToggleProbe.reset
      UI::Probes::SliderProbe.reset
      UI::Probes::TapProbe.reset
      UI::Probes::FormRowProbe.reset
      UI::Probes::RuntimeOverrideProbe.reset

      # Allocate the slug buffer here (NOT as a class-var default) so the
      # iOS class-init gap can't strand it as nil. 64 bytes accommodates
      # the longest known Voyager slug (~"voyager-todo-editor" = 19) with
      # huge headroom for future routes.
      @@current_slug_buf = Bytes.new(64)

      # Phase 8D.2 — call the canonical host-bootstrap helper. This
      # internally:
      #   * calls VoyagerApp.bootstrap! (registers all 4 screens —
      #     mandatory before any dispatcher action lookup; the iOS
      #     class-init gap means the compile-time class-var assignment
      #     in src/asset_pipeline/native_app.cr is skipped, so this
      #     re-runs the registrations defensively).
      #   * constructs Voyager::State + NavigationCoordinator (root
      #     :sign_in) + InProcess Session + InProcess Flash + a
      #     UI::ActionDispatcher.
      #   * calls dispatcher.mount_screen(coord.current) — bumps the
      #     mount_token and seeds FormState BEFORE any render so the
      #     wire-time TextField hook reads the new mount.
      #   * assigns Voyager.state + Voyager.dispatcher so screen
      #     callback closures dispatch through this host's dispatcher.
      #
      # We unpack the result into class-var pins so the GC won't
      # collect them across Swift round-trips.
      result = Voyager::HostBootstrap.build(:sign_in)
      @@state = result.state
      @@coord = result.coord
      @@session = result.session
      @@flash = result.flash
      @@dispatcher = result.dispatcher

      # Phase 8D.3b — capture-scenario hook. When the host launches with
      # VOYAGER_CAPTURE_SCENARIO set (XCUITest's launchEnvironment per the
      # capture-matrix test method), walk state + coord + dispatcher into
      # the target visual end state BEFORE the slug buf gets seeded
      # (below) so voyager_current_slug reflects the scenario-walked
      # route.id. No-op when the env var is unset.
      if scenario = ENV["VOYAGER_CAPTURE_SCENARIO"]?
        Voyager::CaptureScenarios.apply(scenario, result.state, result.coord, result.dispatcher)
      end

      # The reactive substrate: when any dispatcher-routed Navigate /
      # Pop / ReplaceRoot fires `translate_result`, the dispatcher
      # calls mount_screen FIRST (swapping FormState.current under the
      # new token) and THEN invokes the coord op that fires this
      # on_change. The subscriber here is RENDERER-NEUTRAL — it copies
      # the slug into the buffer and hops into Swift via the registered
      # C callback. Swift then trips its @State binding, which re-runs
      # voyager_render(new_slug) and SwiftUI swaps the hosted UIView.
      #
      # NO mount_screen call here: translate_result already mounted
      # before publishing on_change (mount-before-publish invariant,
      # Phase 8B Codex iter-4 finding #1 + 8D.1 macOS pattern).
      # Re-mounting here would double-bump the token.
      coord = @@coord.not_nil!
      coord.on_change do |route|
        slug = Voyager.slug_for_route_id(route.id)
        copy_slug_to_buf(slug)
        cb = @@swift_route_changed_cb
        buf = @@current_slug_buf
        if @@suppress_route_changed
          # Initial resync — Swift callback intentionally suppressed.
        elsif !cb.nil? && !buf.nil?
          cb.call(buf.to_unsafe.as(LibC::Char*))
        end
      end

      # Seed the slug buffer with the bootstrap route's slug BEFORE
      # @@initialized = true (Codex BLOCKER 1 — voyager_current_slug()
      # must return the correct initial value before any navigation
      # event fires).
      copy_slug_to_buf(Voyager.slug_for_route_id(coord.current.id))
      @@initialized = true
    end

    private def self.copy_slug_to_buf(slug : String) : Nil
      buf = @@current_slug_buf
      return if buf.nil? # initialize_runtime always allocates this; guard for safety
      bytes = slug.to_slice
      n = Math.min(bytes.size, buf.size - 1)
      n.times { |i| buf[i] = bytes[i] }
      buf[n] = 0_u8
    end

    def self.current_slug_ptr : LibC::Char*
      initialize_runtime
      @@current_slug_buf.not_nil!.to_unsafe.as(LibC::Char*)
    end

    def self.register_route_changed(cb : LibC::Char* -> Void) : Nil
      @@swift_route_changed_cb = cb
    end

    # Build + render the requested slug. The slug Swift passes is the
    # source of truth for the INITIAL launch resync (Swift's
    # VOYAGER_ROOT_SLUG arg drives the first cold render). After the
    # resync, `coord.current` is the authoritative route and we render
    # from it — so AX labels + test_ids reflect the actual mounted
    # screen, not whatever slug Swift requested.
    #
    # Phase 8D.2 — Voyager.build_route is NO LONGER called from this
    # path. The dispatcher (constructed in initialize_runtime via
    # Voyager::HostBootstrap.build) owns FormState / session / flash /
    # design_tokens / navigation. We build a ScreenContext::Native from
    # the dispatcher's live state on every render so screen builds
    # observe the same form-state + flash + session the controller
    # layer just wrote.
    def self.render_slug(slug : String) : UI::NativeView
      initialize_runtime
      coord = @@coord.not_nil!
      dispatcher = @@dispatcher.not_nil!

      route = Voyager.route_for_slug(slug)

      # Phase 6.10 Rem 4 (Item 1) + Phase 8D.2 Item 3 — coord/slug
      # initial-resync through the host-driven path.
      #
      # When Swift launches with VOYAGER_ROOT_SLUG=voyager-todos, the
      # Crystal coord is still at its constructor default (:sign_in).
      # Without resync, the user's Save → coord.pop returns to
      # :sign_in instead of :todos.
      #
      # The previous logic only synced "if no Swift callback yet" —
      # but the callback gets registered BEFORE the first render, so
      # the branch never fired and the coord stayed misaligned.
      #
      # New rule (8D.2): if the coord is at depth=1 (just the
      # constructor root) AND the requested slug doesn't match, treat
      # this call as a first-time sync from the Swift launch arg.
      #
      # Mount-before-publish: replace_root synchronously notifies
      # on_change subscribers, so we MUST mount_screen first so
      # FormState.current is the new mount's before any subscriber
      # fires. Guard with `@@suppress_route_changed` (begin/ensure) so
      # the resulting notify doesn't fire the Swift callback (which
      # would loop us back into render_slug for the same slug).
      if coord.current.id != route.id && coord.depth == 1
        @@suppress_route_changed = true
        begin
          dispatcher.mount_screen(route)
          coord.replace_root(route)
        ensure
          @@suppress_route_changed = false
        end
      end

      # AX labels reflect coord.current — authoritative after resync.
      # If Swift's requested slug disagreed with coord.current and no
      # resync fired (e.g. mid-app slug requests after navigation has
      # begun), the rendered screen and AX identity stay consistent.
      current_slug = Voyager.slug_for_route_id(coord.current.id)
      reg = VoyagerApp.registration_for(coord.current.id)
      screen_class = reg.screen_class

      # Phase 6.10 Rem 1 — fresh renderer per render call to match
      # Cascade's proven-working pattern. Reusing a single renderer
      # across slug changes produced inverted-order / collapsed-field
      # layouts on iOS even though the same screen authoring rendered
      # correctly with a fresh renderer. The exact root cause appears
      # to be UIHostingController state inside SwiftKit facades; a new
      # renderer instance defensively rebuilds every facade chain.
      #
      # Phase 8D.2 — constructed BEFORE screen.build because the
      # renderer's initializer installs the
      # `UI::DesignTokens::Device.install_provider` block that screens
      # query via `UI::DesignTokens::DeviceMetrics.current` during
      # their build phase (e.g. SignInScreen reads DeviceMetrics for
      # responsive layout). Constructing the renderer AFTER build
      # SIGSEGVs at PC=0 because no provider is installed when build
      # runs (verified via VoyagerDemo-2026-05-25-080058.ips: faulting
      # frame is `UI::DesignTokens::DeviceMetrics::current` inside
      # `Voyager::SignInScreen#build` inside `VoyagerBridge#render_slug`).
      # The macOS host avoids this by constructing the renderer ONCE
      # at startup; iOS uses a fresh renderer per call but must still
      # honor the install-before-query ordering.
      renderer = UI::UIKit::Renderer.new

      # Defensive guard — not robust unknown-slug handling
      # (route_for_slug already maps unknown slugs to :sign_in).
      # Catches future registration shapes where screen_class could be
      # nil (e.g. a web-only screen registered via the screen macro
      # without a controller_class — see Phase 8C web-only-screen
      # support in src/asset_pipeline/native_app.cr).
      if screen_class.nil?
        placeholder = UI::Label.new("Unknown screen for route: #{coord.current.id}")
        placeholder.accessibility_label = "Unknown route"
        placeholder.test_id = "voyager-root-unknown"
        native = renderer.render(placeholder.as(UI::View))
        @@last_native = native
        return native
      end

      # Build a fresh ScreenContext::Native from the dispatcher's live
      # FormState / session / flash / design_tokens / navigation. This
      # is the proven Phase 8B spike pattern + 8D.1 macOS host pattern
      # (samples/initiative-cross-platform-ui-voyager/macos/host.cr#rebuild_for).
      # action_params is empty at render time — it only carries values
      # during in-flight dispatches (e.g. swipe-row Edit's
      # {"todo_id" => "3"}).
      ctx = UI::ScreenContext::Native.new(
        form_state: dispatcher.current_form_state,
        session: dispatcher.session,
        flash: dispatcher.flash,
        design_tokens: dispatcher.design_tokens,
        navigation: dispatcher.navigation,
        action_params: {} of String => String,
      )
      view = screen_class.new.build(ctx)
      view.accessibility_label = "voyager-root-#{current_slug}" if view.accessibility_label.to_s.empty?
      view.test_id = "voyager-root-#{current_slug}" if view.test_id.to_s.empty?

      native = renderer.render(view)
      @@last_native = native
      native
    end
  end

  # ---------------------------------------------------------------------------
  # C ABI exports
  # ---------------------------------------------------------------------------

  fun voyager_init : Void
    VoyagerBridge.initialize_runtime
  end

  fun voyager_render(slug_ptr : LibC::Char*) : Void*
    VoyagerBridge.initialize_runtime
    slug = String.new(slug_ptr)
    native = VoyagerBridge.render_slug(slug)
    native.handle.ptr!
  end

  fun voyager_current_slug : LibC::Char*
    VoyagerBridge.current_slug_ptr
  end

  fun voyager_register_route_changed_callback(cb : LibC::Char* -> Void) : Void
    VoyagerBridge.register_route_changed(cb)
  end

{% end %}
