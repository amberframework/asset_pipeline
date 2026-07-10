# lint:disable=family_1/screen_file_suffix,family_1/controller_file_suffix
# Phase 10A.0a: this is an intentional single-file spike that declares multiple
# screens + controllers; per-class file-suffix rules are disabled accordingly.
# Phase 8B macOS spike — Sign-in -> Todos with read-back proof.
#
# Demonstrates the full Phase 8B native flow:
#   - SignInScreen has an email TextField + a password SecureField + Sign-in Button.
#   - User types "seth@example.com" into the email TextField.
#   - The TextField's renderer-wired on_change calls FormState.update("email", ...)
#     via UI::FormStateRendererHook.wrap_text_handler.
#   - User clicks Sign in. The Button's on_tap dispatches the :submit action.
#   - SignInController.submit reads context.params["email"], stashes it in
#     session["user_email"], and returns navigate_to(:todos).
#   - Dispatcher's translate_result calls mount_screen(:todos) THEN coord.push.
#   - macOS host's on_change subscriber rebuilds the view tree for the new
#     route — TodosScreen reads context.session["user_email"] and renders
#     `Welcome, seth@example.com` as a Label.
#
# Closing gate per Codex finding #4: the screenshot must visibly contain
# the typed email. A generic "Welcome" is INSUFFICIENT.

require "../../../src/asset_pipeline/action_dispatcher"

{% if flag?(:macos) %}
  require "../../../src/ui/renderers/appkit_renderer"

  # ---------- Screens ----------------------------------------------------

  class SignInScreen < UI::Screen
    def build(context : UI::ScreenContext) : UI::View
      stack = UI::VStack.new(spacing: 16.0)
      stack.padding = UI::EdgeInsets.new(top: 24.0, bottom: 24.0, leading: 32.0, trailing: 32.0)

      title = UI::Label.new("Sign in")
      title.accessibility_label = "Sign in title"

      email_field = UI::TextField.new(
        placeholder: "Email",
        name: "email",
        text: context.params["email"]? || "",
      )
      email_field.accessibility_label = "Email"
      email_field.minimum_width = 360.0

      password_field = UI::SecureField.new(
        placeholder: "Password",
        name: "password",
      )
      password_field.accessibility_label = "Password"
      password_field.minimum_width = 360.0

      submit_button = UI::Button.new(
        "Sign in",
        style: UI::ButtonStyle::Prominent,
      ) { Spike.dispatch_submit }
      submit_button.accessibility_label = "Sign in button"

      stack << title
      stack << email_field
      stack << password_field
      stack << submit_button
      stack
    end
  end

  class TodosScreen < UI::Screen
    def build(context : UI::ScreenContext) : UI::View
      stack = UI::VStack.new(spacing: 16.0)
      stack.padding = UI::EdgeInsets.new(top: 24.0, bottom: 24.0, leading: 32.0, trailing: 32.0)

      # READ-BACK PROOF: the typed email flowed FormState -> controller ->
      # session -> here. The screenshot must visibly contain it.
      email = context.session["user_email"]? || "<no email>"
      welcome = UI::Label.new("Welcome, #{email}")
      welcome.accessibility_label = "Welcome label"

      back_button = UI::Button.new("Back") { Spike.dispatch_back }
      back_button.accessibility_label = "Back button"

      stack << welcome
      stack << back_button
      stack
    end
  end

  # ---------- Controllers ------------------------------------------------

  class SignInController < UI::Controller
    def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
      case name
      when :submit then submit(context)
      else raise UI::Controller::UnknownActionError.new("SignInController has no :#{name}")
      end
    end

    def submit(context) : UI::ActionResult
      email = context.params["email"]? || ""
      context.session["user_email"] = email
      navigate_to(:todos)
    end
  end

  class TodosController < UI::Controller
    def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
      case name
      when :back then pop_navigation
      else raise UI::Controller::UnknownActionError.new("TodosController has no :#{name}")
      end
    end
  end

  # ---------- App --------------------------------------------------------

  class SpikeApp < UI::App
    initial_route :sign_in
    screen :sign_in, SignInController, screen_class: SignInScreen
    screen :todos, TodosController, screen_class: TodosScreen
  end

  # ---------- macOS host -------------------------------------------------

  lib LibWindowHelper
    fun hig_create_window_with_min(
      x : Float64, y : Float64, w : Float64, h : Float64,
      min_w : Float64, min_h : Float64,
      title : UInt8*, appearance : UInt8*,
    ) : Void*
    fun hig_run_app(window : Void*) : Void
    fun objc_create_capture_window(width : Float64, height : Float64, appearance : UInt8*) : Void*
    fun objc_install_content_view(window : Void*, content_view : Void*) : Void
    fun objc_capture_view_offscreen(window : Void*, output_path : UInt8*, width : Float64, height : Float64) : Int32
    fun objc_close_capture_window(window : Void*) : Void
    fun objc_run_loop_for(seconds : Float64) : Void
  end

  lib LibObjCBridgeSpike
    fun objc_send_void_id(obj : Void*, sel : Void*, arg : Void*) : Void
    fun sel_registerName(name : UInt8*) : Void*
  end

  module Spike
    WINDOW_WIDTH  = 520.0
    WINDOW_HEIGHT = 380.0
    MIN_WIDTH     = 360.0
    MIN_HEIGHT    = 260.0

    @@dispatcher : UI::ActionDispatcher? = nil
    @@renderer : UI::AppKit::Renderer? = nil
    @@window_ptr : Void* = Pointer(Void).null
    @@set_content_sel : Void* = Pointer(Void).null
    @@active_native : UI::NativeView? = nil
    # `objc_create_capture_window` returns a Void** PAIR (backdrop + capture
    # windows). `objc_install_content_view(pair_ptr, ...)` knows how to
    # write into the right NSWindow inside the pair. `hig_create_window_with_min`
    # returns a regular NSWindow pointer, where we use setContentView: via
    # objc_send_void_id. Track which path we're on so rebuild_for can
    # dispatch correctly.
    @@is_capture_path : Bool = false

    def self.dispatch_submit : Nil
      d = @@dispatcher
      d.dispatch(:submit) if d
    end

    def self.dispatch_back : Nil
      d = @@dispatcher
      d.dispatch(:back) if d
    end

    def self.rebuild_for(route : UI::NavigationCoordinator::Route) : Nil
      renderer = @@renderer.not_nil!
      d = @@dispatcher.not_nil!

      registration = SpikeApp.registration_for(route.id)
      # Phase 8C: screen_class is now nilable (web-only screens have no
      # native screen class). Native dispatch only reaches this point
      # for registrations where the macro guaranteed non-nil (positional
      # controller + derived/explicit screen_class). Crash loud rather
      # than silently fall through.
      screen_class = registration.screen_class
      raise "SpikeApp.rebuild_for: route #{route.id.inspect} has nil screen_class (web-only registration)" if screen_class.nil?
      screen = screen_class.new

      ctx = UI::ScreenContext::Native.new(
        form_state: d.current_form_state,
        session: d.session,
        flash: d.flash,
        design_tokens: d.design_tokens,
        navigation: d.navigation,
        action_params: {} of String => String,
      )

      view = screen.build(ctx)
      native = renderer.render(view)
      @@active_native = native
      if @@is_capture_path
        # Capture window is a void** pair returned by
        # objc_create_capture_window — install via the helper, NOT
        # setContentView: (the pair isn't an NSWindow).
        LibWindowHelper.objc_install_content_view(@@window_ptr, native.handle.ptr!)
      else
        # Interactive window is a plain NSWindow — setContentView:
        # via direct objc_send_void_id.
        LibObjCBridgeSpike.objc_send_void_id(
          @@window_ptr, @@set_content_sel, native.handle.ptr!,
        )
      end
    end

    def self.run!
      SpikeApp.bootstrap!

      coord = UI::NavigationCoordinator.new(
        UI::NavigationCoordinator::Route.new(:sign_in)
      )
      renderer = UI::AppKit::Renderer.new
      session = UI::Session::InProcess.new
      flash = UI::Flash::InProcess.new

      dispatcher = UI::ActionDispatcher.new(
        app: SpikeApp,
        navigation: coord,
        session: session,
        flash: flash,
        design_tokens: UI::DesignTokens::Tokens.default,
      )
      # Mount the initial route so FormState is ready for the renderer
      # to capture wire-time.
      dispatcher.mount_screen(coord.current)

      @@dispatcher = dispatcher
      @@renderer = renderer

      screenshot_path = ENV["PHASE8B_SCREENSHOT_PATH"]?
      appearance = ENV["PHASE8B_APPEARANCE"]? || "light"

      if screenshot_path
        # Offscreen capture path — uses objc_create_capture_window which
        # returns a void** pair (backdrop + capture NSWindows).
        # rebuild_for must use objc_install_content_view, NOT setContentView:.
        window = LibWindowHelper.objc_create_capture_window(
          WINDOW_WIDTH, WINDOW_HEIGHT, appearance.to_unsafe,
        )
        @@window_ptr = window
        @@is_capture_path = true

        # PHASE8B_AUTOFILL_EMAIL — simulate "user typed in the email
        # field" by writing the value into the dispatcher's current
        # FormState. The renderer rebuilds with this pre-populated
        # so the screenshot visibly shows the typed email.
        if autofill_email = ENV["PHASE8B_AUTOFILL_EMAIL"]?
          dispatcher.current_form_state.update("email", autofill_email)
        end

        # PHASE8B_DEMO_SUBMIT — simulate "user clicked Sign in" by
        # dispatching the :submit action. translate_result will mount
        # the :todos screen + push the route + notify our on_change
        # subscriber (which we wire below before this call).
        if ENV["PHASE8B_DEMO_SUBMIT"]? == "1"
          coord.on_change do |route|
            Spike.rebuild_for(route)
          end
          dispatcher.dispatch(:submit)
        end

        rebuild_for(coord.current)
        LibWindowHelper.objc_run_loop_for(0.4)
        rc = LibWindowHelper.objc_capture_view_offscreen(
          window, screenshot_path.to_unsafe, WINDOW_WIDTH, WINDOW_HEIGHT,
        )
        LibWindowHelper.objc_close_capture_window(window)
        STDERR.puts "[phase-08b spike] screenshot rc=#{rc} -> #{screenshot_path}"
        exit(rc == 1 ? 0 : 1)
      end

      # Interactive path
      title_str = "Phase 8B Spike"
      appearance_arg = (ENV["PHASE8B_APPEARANCE"]? ? appearance.to_unsafe : Pointer(UInt8).null)
      window = LibWindowHelper.hig_create_window_with_min(
        120.0, 120.0, WINDOW_WIDTH, WINDOW_HEIGHT,
        MIN_WIDTH, MIN_HEIGHT,
        title_str.to_unsafe, appearance_arg,
      )
      set_content = LibObjCBridgeSpike.sel_registerName("setContentView:".to_unsafe)
      @@window_ptr = window
      @@set_content_sel = set_content

      rebuild_for(coord.current)

      # Subscribe to coord.on_change AFTER the initial render — the
      # dispatcher's translate_result will fire this with the new route
      # AFTER mount_screen has already swapped UI::FormState.current.
      coord.on_change do |route|
        Spike.rebuild_for(route)
      end

      STDERR.puts "[phase-08b spike] launching interactive run"
      LibWindowHelper.hig_run_app(window)
    end
  end

  Spike.run!
{% else %}
  STDERR.puts "samples/phase-08b-native-spike/src/spike_app.cr must be built with -Dmacos"
  exit 1
{% end %}
