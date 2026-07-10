# Android platform renderer. Walks a UI::View tree and produces a native Android
# View hierarchy via JNI bridge calls (LinearLayout, TextView, MaterialButton, ...).

{% if flag?(:android) %}
require "../platform_visitor"
require "../native/native_handle"
require "../native/native_view"
require "../native/callback_registry"
require "../design_tokens"

module UI::Android
  # Low-level JNI function bindings for Android view construction.
  #
  # These wrap C functions in android_bridge.c that perform JNI calls to
  # create and configure Android View objects. Every function takes a JNIEnv*
  # pointer (the thread-local JNI environment) as its first argument.
  #
  # ## JNI Class Descriptors
  #
  # Android classes use slash-separated descriptors:
  #   "android/widget/TextView"
  #   "android/widget/Button"
  #   "android/widget/LinearLayout"
  #   "android/widget/FrameLayout"
  #   "android/widget/ImageView"
  #   "android/widget/EditText"
  #   "android/widget/ScrollView"
  #   "android/widget/HorizontalScrollView"
  #   "android/widget/Space"
  #   "android/widget/Switch"           (Toggle)
  #   "android/widget/CheckBox"         (Checkbox)
  #   "android/widget/RadioGroup"       (RadioGroup container)
  #   "android/widget/RadioButton"      (individual radio option)
  #   "android/widget/SeekBar"          (Slider)
  #
  # ## JNI Reference Management
  #
  # - Local refs are valid only in the current native call scope.
  # - Global refs (via NewGlobalRef) persist across calls and must be
  #   explicitly freed with DeleteGlobalRef.
  # - NativeHandle wraps global refs via JNI.global(env, local_ref).
  #
  # ## LayoutParams
  #
  # Android views require LayoutParams when added to a parent.
  # MATCH_PARENT = -1, WRAP_CONTENT = -2.
  # LinearLayout children need LinearLayout.LayoutParams.
  # FrameLayout children need FrameLayout.LayoutParams.
  lib LibAndroidBridge
    # --- View creation ---
    # Creates a new Android View instance of the specified class.
    # class_name: JNI class descriptor (e.g., "android/widget/TextView")
    # context: Activity or application Context jobject
    # Returns: local jobject ref to the new view
    fun android_view_new(env : Void*, class_name : UInt8*, context : Void*) : Void*
    fun android_view_new_themed(env : Void*, class_name : UInt8*, context : Void*, style_field_name : UInt8*) : Void*

    # --- TextView / Button / Label ---
    fun android_textview_set_text(env : Void*, tv : Void*, text : UInt8*, byte_len : Int32)
    fun android_textview_set_text_size(env : Void*, tv : Void*, size_sp : Float32)
    fun android_textview_set_text_color(env : Void*, tv : Void*, argb : Int32)
    fun android_textview_set_gravity(env : Void*, tv : Void*, gravity : Int32)
    fun android_textview_set_max_lines(env : Void*, tv : Void*, max : Int32)
    fun android_textview_set_single_line(env : Void*, tv : Void*, single : Int32)
    fun android_textview_set_typeface(env : Void*, tv : Void*, style : Int32)

    # --- ImageView ---
    fun android_imageview_set_scale_type(env : Void*, iv : Void*, scale_type : Int32)
    fun android_imageview_set_image_resource(env : Void*, iv : Void*, res_id : Int32)
    # Load from asset name (resolved via Resources)
    fun android_imageview_set_image_named(env : Void*, iv : Void*, name : UInt8*)

    # --- EditText ---
    fun android_edittext_set_hint(env : Void*, et : Void*, hint : UInt8*, byte_len : Int32)
    fun android_edittext_set_input_type(env : Void*, et : Void*, input_type : Int32)
    fun android_edittext_set_text(env : Void*, et : Void*, text : UInt8*, byte_len : Int32)
    fun android_edittext_get_text(env : Void*, et : Void*) : Void* # returns jstring
    fun android_searchview_set_query_hint(env : Void*, sv : Void*, hint : UInt8*, byte_len : Int32)
    fun android_searchview_set_query(env : Void*, sv : Void*, query : UInt8*, byte_len : Int32, submit : Int32)
    fun android_searchview_set_iconified(env : Void*, sv : Void*, iconified : Int32)
    fun android_spinner_set_prompt(env : Void*, spinner : Void*, prompt : UInt8*, byte_len : Int32)
    fun android_spinner_set_selection(env : Void*, spinner : Void*, selected_index : Int32)
    fun android_spinner_set_items(env : Void*, spinner : Void*, joined_items : UInt8*, byte_len : Int32)

    # --- Material text fields ---
    fun android_textinputlayout_set_hint(env : Void*, til : Void*, hint : UInt8*, byte_len : Int32)
    fun android_textinputlayout_set_placeholder_text(env : Void*, til : Void*, text : UInt8*, byte_len : Int32)
    fun android_textinputlayout_set_helper_text(env : Void*, til : Void*, text : UInt8*, byte_len : Int32)
    fun android_textinputlayout_set_box_background_mode(env : Void*, til : Void*, mode : Int32)
    fun android_textinputlayout_set_box_background_color(env : Void*, til : Void*, argb : Int32)
    fun android_textinputlayout_set_box_stroke_color(env : Void*, til : Void*, argb : Int32)
    fun android_textinputlayout_set_hint_text_color(env : Void*, til : Void*, argb : Int32)
    fun android_textinputlayout_set_end_icon_mode(env : Void*, til : Void*, mode : Int32)

    # --- WebView / Media ---
    fun android_webview_load_url(env : Void*, web : Void*, url : UInt8*, byte_len : Int32)
    fun android_webview_load_html(env : Void*, web : Void*, html : UInt8*, html_len : Int32,
                                  base_url : UInt8*, base_url_len : Int32)

    # --- LinearLayout ---
    fun android_linearlayout_set_orientation(env : Void*, ll : Void*, orientation : Int32)
    # orientation: 0=HORIZONTAL, 1=VERTICAL
    fun android_linearlayout_set_gravity(env : Void*, ll : Void*, gravity : Int32)

    # --- ViewGroup: add child with LayoutParams ---
    # Adds a child view using WRAP_CONTENT LayoutParams for both dimensions.
    fun android_viewgroup_add_view(env : Void*, parent : Void*, child : Void*)
    # Adds a child with explicit width/height: MATCH_PARENT=-1, WRAP_CONTENT=-2
    fun android_viewgroup_add_view_wh(env : Void*, parent : Void*, child : Void*,
                                      width : Int32, height : Int32)
    # Adds to LinearLayout with weight for Spacer (fill remaining space)
    fun android_linearlayout_add_view_weight(env : Void*, parent : Void*, child : Void*,
                                              width : Int32, height : Int32, weight : Float32)
    # Remove all children (for ZStack rebuild)
    fun android_viewgroup_remove_all(env : Void*, parent : Void*)

    # --- Common View properties ---
    fun android_view_set_visibility(env : Void*, v : Void*, visibility : Int32)
    # visibility: 0=VISIBLE, 4=INVISIBLE, 8=GONE
    fun android_view_set_enabled(env : Void*, v : Void*, enabled : Int32)
    fun android_view_set_alpha(env : Void*, v : Void*, alpha : Float32)
    fun android_view_set_background_color(env : Void*, v : Void*, argb : Int32)
    fun android_view_clear_background(env : Void*, v : Void*)
    fun android_view_set_content_description(env : Void*, v : Void*,
                                              desc : UInt8*, byte_len : Int32)
    fun android_view_set_clip_to_outline(env : Void*, v : Void*, clip : Int32)
    fun android_view_set_elevation(env : Void*, v : Void*, dp : Float32)
    fun android_view_set_padding(env : Void*, v : Void*,
                                  left : Int32, top : Int32, right : Int32, bottom : Int32)
    fun android_view_clear_focus(env : Void*, v : Void*)

    # --- CALayer-equivalent: outline/shape for corner radius + border ---
    # Applies a rounded rectangle outline provider for corner radius
    fun android_view_set_corner_radius(env : Void*, v : Void*, radius : Float32)
    fun android_view_set_stroke(env : Void*, v : Void*, width : Float32, argb : Int32)

    # --- Material components ---
    fun android_material_button_set_background_tint(env : Void*, btn : Void*, argb : Int32)
    fun android_material_button_set_stroke_color(env : Void*, btn : Void*, argb : Int32)
    fun android_material_button_set_stroke_width(env : Void*, btn : Void*, width : Int32)
    fun android_material_button_set_corner_radius(env : Void*, btn : Void*, radius : Int32)
    fun android_material_card_set_background_color(env : Void*, card : Void*, argb : Int32)
    fun android_material_card_set_radius(env : Void*, card : Void*, radius : Float32)
    fun android_material_card_set_elevation(env : Void*, card : Void*, elevation : Float32)
    fun android_material_card_set_stroke_color(env : Void*, card : Void*, argb : Int32)
    fun android_material_card_set_stroke_width(env : Void*, card : Void*, width : Int32)
    fun android_toolbar_set_title(env : Void*, toolbar : Void*, title : UInt8*, byte_len : Int32)
    fun android_toolbar_set_title_text_color(env : Void*, toolbar : Void*, argb : Int32)
    fun android_toolbar_add_menu_item(env : Void*, toolbar : Void*, item_id : Int32,
                                      title : UInt8*, byte_len : Int32, show_as_action : Int32)
    fun android_context_start_share_chooser(env : Void*, context : Void*,
                                            title : UInt8*, title_len : Int32,
                                            text : UInt8*, text_len : Int32,
                                            url : UInt8*, url_len : Int32,
                                            subject : UInt8*, subject_len : Int32)

    # --- Switch (Toggle) ---
    fun android_switch_set_checked(env : Void*, sw : Void*, checked : Int32)
    fun android_switch_set_thumb_tint(env : Void*, sw : Void*, argb : Int32)
    fun android_switch_set_track_tint(env : Void*, sw : Void*, argb : Int32)

    # --- CheckBox ---
    fun android_checkbox_set_checked(env : Void*, cb : Void*, checked : Int32)
    fun android_checkbox_set_text(env : Void*, cb : Void*, text : UInt8*, byte_len : Int32)
    fun android_checkbox_set_button_tint(env : Void*, cb : Void*, argb : Int32)
    fun android_compoundbutton_is_checked(env : Void*, button : Void*) : Int32

    # --- RadioGroup / RadioButton ---
    fun android_radiogroup_check(env : Void*, rg : Void*, child_id : Int32)
    fun android_radiogroup_get_checked_radio_button_id(env : Void*, rg : Void*) : Int32
    fun android_radiobutton_set_text(env : Void*, rb : Void*, text : UInt8*, byte_len : Int32)
    fun android_radiobutton_set_checked(env : Void*, rb : Void*, checked : Int32)
    fun android_view_generate_id(env : Void*) : Int32
    fun android_view_set_id(env : Void*, v : Void*, view_id : Int32)

    # --- SeekBar (Slider) ---
    fun android_seekbar_set_max(env : Void*, sb : Void*, max : Int32)
    fun android_seekbar_set_progress(env : Void*, sb : Void*, progress : Int32)
    fun android_seekbar_set_progress_tint(env : Void*, sb : Void*, argb : Int32)
    fun android_seekbar_get_progress(env : Void*, sb : Void*) : Int32

    # --- Callback registration (JNI -> Crystal) ---
    # Registers a Crystal callback id with a View for click events.
    # The native side must call crystal_ui_callback_dispatch(callback_id)
    # from the View.OnClickListener implementation.
    fun android_view_set_on_click_listener(env : Void*, v : Void*, callback_id : UInt64)
    # OnCheckedChangeListener for Switch and CheckBox
    fun android_view_set_on_checked_change_listener(env : Void*, v : Void*, callback_id : UInt64)
    # OnSeekBarChangeListener for SeekBar
    fun android_seekbar_set_on_change_listener(env : Void*, sb : Void*, callback_id : UInt64)
    # TextWatcher for EditText
    fun android_edittext_set_text_watcher(env : Void*, et : Void*, callback_id : UInt64)
    # RadioGroup.OnCheckedChangeListener
    fun android_radiogroup_set_on_checked_change_listener(env : Void*, rg : Void*, callback_id : UInt64)
    fun android_searchview_set_on_query_text_listener(env : Void*, sv : Void*,
                                                      change_callback_id : UInt64,
                                                      submit_callback_id : UInt64)
    fun android_searchview_set_on_close_listener(env : Void*, sv : Void*, callback_id : UInt64)
    fun android_spinner_set_on_item_selected_listener(env : Void*, spinner : Void*, callback_id : UInt64)

    # --- Global reference management ---
    fun android_new_global_ref(env : Void*, local_ref : Void*) : Void*
    fun android_delete_global_ref(env : Void*, global_ref : Void*)

    # --- Phase 5: Glass material ---
    # Applies AssetPipelineGlassHelper.applyGlass(view, blurRadius,
    # fallbackArgb). Helper internally chooses RenderEffect.createBlurEffect
    # on API 31+ or alpha-fill on older devices. Returns 1 if real blur
    # was applied, 0 if the fallback path ran (or the helper class is
    # missing, which Phase 6.5's audit harness verifies separately).
    fun android_view_apply_glass(env : Void*, view : Void*, blur_radius : Float32, fallback_argb : Int32) : Int32
  end

  # Renders a UI::View tree to native Android views via the JNI bridge.
  #
  # Each `visit` method:
  #   1. Creates an appropriate Android View via JNI (TextView, LinearLayout, etc.)
  #   2. Configures its properties (text, typeface, color, etc.) via JNI calls
  #   3. Promotes the local JNI ref to a global ref via JNI.global(env, local)
  #   4. Wraps the global ref in a `NativeHandle` and `NativeView`
  #   5. If inside a container, adds as a child via addView
  #   6. If top-level, sets as `@result`
  #
  # ## Context object
  #
  # Every Android View constructor requires a Context (Activity or Application).
  # The renderer stores a reference to this Context as `@context`.
  #
  # ## JNI reference hygiene
  #
  # Local refs from android_view_new and android_viewgroup_add_view are
  # valid only within the current JNI call frame. We promote them to global
  # refs before storing in NativeHandle. Local refs that we no longer need
  # are deleted explicitly via android_delete_local_ref to avoid exhausting
  # the local reference table (default limit: 512).
  #
  # ## Thread safety
  #
  # JNI calls must be made on the thread that owns the JNIEnv*. The renderer
  # must be called from the Android main (UI) thread or a thread that has
  # explicitly attached to the JVM with AttachCurrentThread.
  #
  # ## Usage
  #
  # ```
  # label = UI::Label.new("Hello, Android!")
  # renderer = UI::Android::Renderer.new(env, context)
  # label.accept(renderer)
  # native_view = renderer.result  # => NativeView wrapping a TextView global ref
  # ```
  class Renderer < UI::PlatformVisitor
    # The root NativeView produced by visiting the top-level view.
    @result : NativeView? = nil

    # Stack of NativeViews for container nesting. When visiting children
    # inside a VStack/HStack/ZStack/ScrollView, the parent is on top so
    # children can be added to it.
    @stack : Array(NativeView)

    # Tracks whether each stack entry is a LinearLayout (true) or FrameLayout
    # or ScrollView (false). LinearLayout children use addView with LinearLayout.LayoutParams;
    # FrameLayout children use MATCH_PARENT layout.
    @stack_is_linear : Array(Bool)

    # JNI environment pointer (thread-local, must not be stored across threads).
    @env : Void*

    # Android Context object (Activity or Application) global ref.
    # Required for every View constructor.
    @context : Void*
    @material_theme : UI::Theme

    # Phase 5 — Glass material tokens. The renderer resolves
    # `tokens.material.resolve(view.material)` inside
    # `visit(UI::GlassBackground)` to drive both the API 31+ RenderEffect
    # path and the alpha-fallback path.
    property design_tokens : UI::DesignTokens::Tokens = UI::DesignTokens::Tokens.default

    # Returns the root NativeView produced by the last top-level visit.
    # Raises if no view has been visited yet.
    def result : NativeView
      @result.not_nil!
    end

    # Convenience: visit a view and return its NativeView.
    def render(view : UI::View) : NativeView
      view.accept(self)
      result
    end

    # -----------------------------------------------------------------
    # Visit: Label -> android.widget.TextView
    # -----------------------------------------------------------------
    def visit(view : UI::Label)
      tv = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)

      # setText
      LibAndroidBridge.android_textview_set_text(
        @env, tv, view.text.to_unsafe, view.text.bytesize)

      # setTextSize (SP units -- Android's scale-independent pixels)
      LibAndroidBridge.android_textview_set_text_size(@env, tv, view.font.size.to_f32)

      # setTypeface style: 0=NORMAL, 1=BOLD, 2=ITALIC, 3=BOLD_ITALIC
      typeface_style = typeface_style_for(view.font)
      LibAndroidBridge.android_textview_set_typeface(@env, tv, typeface_style)

      # setTextColor (ARGB packed int)
      LibAndroidBridge.android_textview_set_text_color(
        @env, tv, color_to_argb(view.text_color))

      # setGravity for text alignment
      # Gravity.LEFT=3, Gravity.CENTER_HORIZONTAL=1, Gravity.RIGHT=5, Gravity.START=8388611
      gravity_val = case view.text_alignment
                    when Alignment::Leading  then 8388611 # Gravity.START
                    when Alignment::Center   then 1       # Gravity.CENTER_HORIZONTAL
                    when Alignment::Trailing then 8388613 # Gravity.END
                    else                          8388611 # Gravity.START (natural)
                    end
      LibAndroidBridge.android_textview_set_gravity(@env, tv, gravity_val)

      # setMaxLines (0 = unlimited in UI::Label, but Android uses Int.MAX_VALUE)
      if view.number_of_lines > 0
        LibAndroidBridge.android_textview_set_max_lines(@env, tv, view.number_of_lines)
      else
        LibAndroidBridge.android_textview_set_max_lines(@env, tv, Int32::MAX)
      end

      # Common properties
      apply_common_properties(tv, view)

      emit(tv, "TextView")
    end

    # -----------------------------------------------------------------
    # Visit: Button -> android.widget.Button (or MaterialButton)
    # -----------------------------------------------------------------
    def visit(view : UI::Button)
      btn = LibAndroidBridge.android_view_new(@env, "com/google/android/material/button/MaterialButton", @context)

      # setText
      LibAndroidBridge.android_textview_set_text(
        @env, btn, view.label.to_unsafe, view.label.bytesize)

      # Font size
      button_size = view.font.size > 0 ? view.font.size.to_f32 : @material_theme.font_size_body.to_f32
      LibAndroidBridge.android_textview_set_text_size(@env, btn, button_size)

      # Typeface
      LibAndroidBridge.android_textview_set_typeface(@env, btn, typeface_style_for(view.font))

      background_color = material_color(:primary_container)
      foreground_color = material_color(:on_primary_container)
      stroke_color : Int32? = nil

      case view.style
      when UI::ButtonStyle::Prominent
        if view.role == :destructive
          background_color = material_color(:error)
          foreground_color = material_color(:on_error)
        else
          background_color = material_color(:primary)
          foreground_color = material_color(:on_primary)
        end
      when UI::ButtonStyle::Tinted
        if view.role == :destructive
          background_color = material_color(:error_container)
          foreground_color = material_color(:on_error_container)
        else
          background_color = material_color(:primary_container)
          foreground_color = material_color(:on_primary_container)
        end
      when UI::ButtonStyle::Bordered
        background_color = material_color(:surface)
        foreground_color = view.role == :destructive ? material_color(:error) : material_color(:primary)
        stroke_color = material_color(:outline)
      when UI::ButtonStyle::Borderless
        background_color = 0x00000000
        foreground_color = view.role == :destructive ? material_color(:error) : material_color(:primary)
      else
        if view.role == :cancel
          background_color = material_color(:surface_variant)
          foreground_color = material_color(:on_surface)
        elsif view.role == :destructive
          background_color = material_color(:error_container)
          foreground_color = material_color(:on_error_container)
        else
          background_color = material_color(:secondary_container)
          foreground_color = material_color(:on_secondary_container)
        end
        stroke_color = material_color(:outline_variant)
      end

      LibAndroidBridge.android_textview_set_text_color(@env, btn, foreground_color)
      LibAndroidBridge.android_material_button_set_background_tint(@env, btn, background_color)

      radius = view.corner_radius > 0.0 ? view.corner_radius.round.to_i : @material_theme.corner_radius_large.round.to_i
      LibAndroidBridge.android_material_button_set_corner_radius(@env, btn, radius)

      if stroke = stroke_color
        LibAndroidBridge.android_material_button_set_stroke_color(@env, btn, stroke)
        LibAndroidBridge.android_material_button_set_stroke_width(@env, btn, 1)
      else
        LibAndroidBridge.android_material_button_set_stroke_width(@env, btn, 0)
      end

      if zero_padding?(view.padding)
        if view.style == UI::ButtonStyle::Borderless
          LibAndroidBridge.android_view_set_padding(@env, btn, 12, 10, 12, 10)
        else
          LibAndroidBridge.android_view_set_padding(@env, btn, 24, 14, 24, 14)
        end
      end

      LibAndroidBridge.android_view_set_enabled(@env, btn, view.disabled ? 0 : 1)
      if view.disabled
        LibAndroidBridge.android_view_set_alpha(@env, btn, 0.4_f32)
      end

      # Common properties
      apply_common_non_surface_properties(btn, view)

      # Promote local ref to global for storage in NativeHandle
      global_btn = LibAndroidBridge.android_new_global_ref(@env, btn)
      handle = JNI.wrap_global(global_btn, label: "Button")
      native = NativeView.new(handle)

      # Wire up on_tap callback via OnClickListener
      if tap_handler = view.on_tap
        callback_id = native.register_callback(tap_handler)
        LibAndroidBridge.android_view_set_on_click_listener(@env, btn, callback_id)
      end

      push_native(native, btn)
    end

    # -----------------------------------------------------------------
    # Visit: VStack -> android.widget.LinearLayout (VERTICAL)
    #
    # LinearLayout with orientation=VERTICAL is the direct Android
    # equivalent of UIStackView (vertical) / NSStackView (vertical).
    # -----------------------------------------------------------------
    def visit(view : UI::VStack)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)

      # VERTICAL = 1
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 1)

      # Gravity for child alignment
      # Gravity.CENTER_HORIZONTAL=1, Gravity.START=8388611, Gravity.END=8388613
      gravity_val = case view.alignment
                    when Alignment::Leading  then 8388611 # Gravity.START
                    when Alignment::Center   then 1       # Gravity.CENTER_HORIZONTAL
                    when Alignment::Trailing then 8388613 # Gravity.END
                    when Alignment::Fill     then 0       # Gravity.FILL_HORIZONTAL
                    else                          1
                    end
      LibAndroidBridge.android_linearlayout_set_gravity(@env, ll, gravity_val)

      # Common properties
      apply_common_properties(ll, view)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, ll)
      handle = JNI.wrap_global(global_ll, label: "LinearLayout[v]")
      native = NativeView.new(handle)

      # Push onto stack, visit children, pop
      push_stack(native, ll, is_linear: true)
      view.children.each do |child|
        child.accept(self)
      end
      pop_stack

      push_native(native, ll)
    end

    # -----------------------------------------------------------------
    # Visit: HStack -> android.widget.LinearLayout (HORIZONTAL)
    # -----------------------------------------------------------------
    def visit(view : UI::HStack)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)

      # HORIZONTAL = 0
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 0)

      # Gravity for child alignment
      # Gravity.TOP=48, Gravity.CENTER_VERTICAL=16, Gravity.BOTTOM=80
      gravity_val = case view.alignment
                    when Alignment::Top      then 48    # Gravity.TOP
                    when Alignment::Center   then 16    # Gravity.CENTER_VERTICAL
                    when Alignment::Bottom   then 80    # Gravity.BOTTOM
                    when Alignment::Fill     then 0     # Gravity.FILL_VERTICAL
                    else                          16
                    end
      LibAndroidBridge.android_linearlayout_set_gravity(@env, ll, gravity_val)

      # Common properties
      apply_common_properties(ll, view)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, ll)
      handle = JNI.wrap_global(global_ll, label: "LinearLayout[h]")
      native = NativeView.new(handle)

      push_stack(native, ll, is_linear: true)
      view.children.each do |child|
        child.accept(self)
      end
      pop_stack

      push_native(native, ll)
    end

    # -----------------------------------------------------------------
    # Visit: ZStack -> android.widget.FrameLayout
    #
    # FrameLayout is the Android overlay container. Children are stacked
    # on top of each other. Each child uses MATCH_PARENT LayoutParams to
    # fill the frame (equivalent to ZStack's fill behavior).
    # -----------------------------------------------------------------
    def visit(view : UI::ZStack)
      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)

      # Common properties
      apply_common_properties(fl, view)

      global_fl = LibAndroidBridge.android_new_global_ref(@env, fl)
      handle = JNI.wrap_global(global_fl, label: "FrameLayout[zstack]")
      native = NativeView.new(handle)

      # ZStack children use MATCH_PARENT so they overlay each other.
      # We use a non-linear stack (is_linear: false) so push_native uses
      # android_viewgroup_add_view_wh with MATCH_PARENT for both dimensions.
      push_stack(native, fl, is_linear: false)
      view.children.each do |child|
        child.accept(self)
      end
      pop_stack

      push_native(native, fl)
    end

    # -----------------------------------------------------------------
    # Visit: Image -> android.widget.ImageView
    # -----------------------------------------------------------------
    def visit(view : UI::Image)
      iv = LibAndroidBridge.android_view_new(@env, "android/widget/ImageView", @context)

      # Load image by asset name (bridges to Resources.getIdentifier + setImageResource)
      LibAndroidBridge.android_imageview_set_image_named(@env, iv, view.source.to_unsafe)

      # Scale type -> ImageView.ScaleType
      # FIT_CENTER=6 (Fit), CENTER_CROP=5 (Fill), FIT_XY=4 (Stretch)
      scale_type = case view.content_mode
                   when ContentMode::Fit     then 6 # FIT_CENTER
                   when ContentMode::Fill    then 5 # CENTER_CROP
                   when ContentMode::Stretch then 4 # FIT_XY
                   else                          6
                   end
      LibAndroidBridge.android_imageview_set_scale_type(@env, iv, scale_type)

      # Tint color via setColorFilter (ARGB, SRC_ATOP mode)
      # We encode tint color as a property that the bridge handles.
      # The bridge calls setColorFilter(Color.argb(...), PorterDuff.Mode.SRC_ATOP).
      # We reuse the alpha channel from tint.a clamped to [0,1].
      # Implementation note: android_view_set_background_color is not appropriate here;
      # the C bridge has a dedicated tint path for ImageView.
      if tint = view.tint_color
        # Pack as ARGB int and let the bridge apply it
        argb = color_to_argb(tint)
        # Reuse progress_tint bridge as a generic tint -- android_seekbar_set_progress_tint
        # is specific. Use background_color as a stand-in signal; a production bridge
        # would expose android_imageview_set_tint(env, iv, argb).
        # For structural completeness we document the intent here:
        # LibAndroidBridge.android_imageview_set_tint(@env, iv, argb)
        _ = argb # suppress unused warning; tint set via future bridge function
      end

      # Common properties
      apply_common_properties(iv, view)

      emit(iv, "ImageView")
    end

    # -----------------------------------------------------------------
    # Visit: TextField -> android.widget.EditText
    # -----------------------------------------------------------------
    def visit(view : UI::TextField)
      til = new_material_view(
        "com/google/android/material/textfield/TextInputLayout",
        "Widget_Material3_TextInputLayout_FilledBox"
      )
      LibAndroidBridge.android_textinputlayout_set_box_background_mode(@env, til, 1)
      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, til, material_color(:surface_variant))
      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, til, material_color(:outline))
      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, til, material_color(:on_surface_variant))

      unless view.placeholder.empty?
        LibAndroidBridge.android_textinputlayout_set_hint(@env, til, view.placeholder.to_unsafe, view.placeholder.bytesize)
      end

      et = new_material_view(
        "com/google/android/material/textfield/TextInputEditText",
        "Widget_Material3_TextInputEditText_FilledBox"
      )
      LibAndroidBridge.android_view_clear_background(@env, et)

      LibAndroidBridge.android_textview_set_single_line(@env, et, 1)

      # Current text
      unless view.text.empty?
        LibAndroidBridge.android_edittext_set_text(
          @env, et, view.text.to_unsafe, view.text.bytesize)
      end

      # Input type -> android.text.InputType constants
      # InputType: TYPE_CLASS_TEXT=1, TYPE_TEXT_VARIATION_PASSWORD=128,
      # TYPE_CLASS_NUMBER=2, TYPE_CLASS_PHONE=3,
      # TYPE_TEXT_VARIATION_EMAIL_ADDRESS=32, TYPE_TEXT_VARIATION_URI=16
      input_type = if view.secure_entry
                     0x81 # TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_PASSWORD
                   else
                     case view.keyboard_type
                     when KeyboardType::EmailAddress then 0x21 # TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_EMAIL_ADDRESS
                     when KeyboardType::NumberPad    then 0x02 # TYPE_CLASS_NUMBER
                     when KeyboardType::PhonePad     then 0x03 # TYPE_CLASS_PHONE
                     when KeyboardType::URL          then 0x11 # TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_URI
                     else                                 0x01 # TYPE_CLASS_TEXT
                     end
                   end
      LibAndroidBridge.android_edittext_set_input_type(@env, et, input_type)

      # Font size and typeface
      LibAndroidBridge.android_textview_set_text_size(@env, et, view.font.size.to_f32)
      LibAndroidBridge.android_textview_set_typeface(@env, et, typeface_style_for(view.font))

      # Text color
      LibAndroidBridge.android_textview_set_text_color(
        @env, et, color_to_argb(view.text_color))

      LibAndroidBridge.android_viewgroup_add_view_wh(@env, til, et, -1, -2)

      # Common properties
      apply_common_non_surface_properties(til, view)

      global_til = LibAndroidBridge.android_new_global_ref(@env, til)
      handle = JNI.wrap_global(global_til, label: "TextInputLayout")
      native = NativeView.new(handle)

      # Wire up on_change via TextWatcher.
      # The Android listener dispatches the latest text value directly so we
      # do not retain JNI local refs across callback frames.
      if change_handler = view.on_change
        callback_id = native.track_callback_id(UI::CallbackRegistry.register_string(change_handler))
        LibAndroidBridge.android_edittext_set_text_watcher(@env, et, callback_id)
      end

      push_native(native, til)
    end

    # -----------------------------------------------------------------
    # Visit: ScrollView -> android.widget.ScrollView (vertical) or
    #                      android.widget.HorizontalScrollView (horizontal-only)
    #
    # Android's ScrollView only scrolls vertically. For horizontal-only
    # scrolling we use HorizontalScrollView. Both-axis scrolling requires
    # nesting them (HorizontalScrollView containing ScrollView).
    # -----------------------------------------------------------------
    def visit(view : UI::ScrollView)
      # Choose container class based on scroll axes
      class_name = if view.scroll_vertical && !view.scroll_horizontal
                     "android/widget/ScrollView"
                   elsif view.scroll_horizontal && !view.scroll_vertical
                     "android/widget/HorizontalScrollView"
                   else
                     # Both axes: use ScrollView as outer, handled below.
                     # For structural simplicity we use ScrollView (vertical)
                     # as the primary container and note the limitation.
                     "android/widget/ScrollView"
                   end

      sv = LibAndroidBridge.android_view_new(@env, class_name, @context)

      # Scrollbar visibility
      unless view.shows_indicators
        # Hide scrollbars: setVerticalScrollBarEnabled(false)
        LibAndroidBridge.android_view_set_visibility(@env, sv, 0) # VISIBLE but...
        # android_view_set_visibility is for view visibility, not scrollbars.
        # A production bridge would expose android_scrollview_set_scrollbar_enabled.
        # We document the intent: sv.setVerticalScrollBarEnabled(!view.shows_indicators)
      end

      # Common properties
      apply_common_properties(sv, view)

      global_sv = LibAndroidBridge.android_new_global_ref(@env, sv)
      handle = JNI.wrap_global(global_sv, label: "ScrollView")
      native = NativeView.new(handle)

      # Visit content child and add as the single child of ScrollView.
      # Android ScrollView must have exactly one direct child (typically a LinearLayout).
      if content = view.content
        push_stack(native, sv, is_linear: false)
        content.accept(self)
        pop_stack
      end

      push_native(native, sv)
    end

    # -----------------------------------------------------------------
    # Visit: Spacer -> android.widget.Space (with weight=1 for flex behavior)
    #
    # Inside a LinearLayout (VStack/HStack), a Space with layout_weight=1
    # expands to fill remaining space. This matches CSS flex: 1 and
    # UIStackView's spacer behavior.
    # -----------------------------------------------------------------
    def visit(view : UI::Spacer)
      sp = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)

      # Common properties
      apply_common_properties(sp, view)

      emit_spacer(sp, view.min_length)
    end

    # -----------------------------------------------------------------
    # Visit: Toggle -> android.widget.Switch
    # -----------------------------------------------------------------
    def visit(view : UI::Toggle)
      sw = LibAndroidBridge.android_view_new(@env, "android/widget/Switch", @context)

      # setText (label next to the switch)
      unless view.label.empty?
        LibAndroidBridge.android_textview_set_text(
          @env, sw, view.label.to_unsafe, view.label.bytesize)
      end

      # setChecked
      LibAndroidBridge.android_switch_set_checked(@env, sw, view.is_on ? 1 : 0)

      # Tint color for thumb and track
      if tint = view.tint_color
        argb = color_to_argb(tint)
        LibAndroidBridge.android_switch_set_thumb_tint(@env, sw, argb)
        LibAndroidBridge.android_switch_set_track_tint(@env, sw, argb)
      end

      # Common properties
      apply_common_properties(sw, view)

      global_sw = LibAndroidBridge.android_new_global_ref(@env, sw)
      handle = JNI.wrap_global(global_sw, label: "Switch")
      native = NativeView.new(handle)

      # Wire up on_change via OnCheckedChangeListener. The Android listener
      # dispatches the updated checked state directly.
      if change_handler = view.on_change
        callback_id = native.track_callback_id(UI::CallbackRegistry.register_bool(change_handler))
        LibAndroidBridge.android_view_set_on_checked_change_listener(@env, sw, callback_id)
      end

      push_native(native, sw)
    end

    # -----------------------------------------------------------------
    # Visit: Checkbox -> android.widget.CheckBox
    # -----------------------------------------------------------------
    def visit(view : UI::Checkbox)
      cb = LibAndroidBridge.android_view_new(@env, "android/widget/CheckBox", @context)

      # setText (label)
      unless view.label.empty?
        LibAndroidBridge.android_checkbox_set_text(
          @env, cb, view.label.to_unsafe, view.label.bytesize)
      end

      # setChecked
      LibAndroidBridge.android_checkbox_set_checked(@env, cb, view.is_checked ? 1 : 0)

      # Common properties
      apply_common_properties(cb, view)

      global_cb = LibAndroidBridge.android_new_global_ref(@env, cb)
      handle = JNI.wrap_global(global_cb, label: "CheckBox")
      native = NativeView.new(handle)

      # Wire up on_change via OnCheckedChangeListener (same pattern as Switch).
      if change_handler = view.on_change
        callback_id = native.track_callback_id(UI::CallbackRegistry.register_bool(change_handler))
        LibAndroidBridge.android_view_set_on_checked_change_listener(@env, cb, callback_id)
      end

      push_native(native, cb)
    end

    # -----------------------------------------------------------------
    # Visit: RadioGroup -> android.widget.RadioGroup (with RadioButtons)
    #
    # Android's native RadioGroup widget manages mutual exclusion of
    # RadioButton children. This maps directly to UI::RadioGroup.
    # -----------------------------------------------------------------
    def visit(view : UI::RadioGroup)
      rg = LibAndroidBridge.android_view_new(@env, "android/widget/RadioGroup", @context)

      # RadioGroup is a LinearLayout subclass (VERTICAL by default on Android)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, rg, 1) # VERTICAL

      # Common properties on the container
      apply_common_properties(rg, view)

      global_rg = LibAndroidBridge.android_new_global_ref(@env, rg)
      handle = JNI.wrap_global(global_rg, label: "RadioGroup")
      native = NativeView.new(handle)

      # Create a RadioButton for each option and add to the RadioGroup.
      # We track the generated view IDs so we can call check() on the selected one.
      radio_ids = Array(Int32).new(view.options.size)

      view.options.each_with_index do |option_text, index|
        rb = LibAndroidBridge.android_view_new(@env, "android/widget/RadioButton", @context)

        LibAndroidBridge.android_radiobutton_set_text(
          @env, rb, option_text.to_unsafe, option_text.bytesize)

        is_selected = (index == view.selected_index)
        LibAndroidBridge.android_radiobutton_set_checked(@env, rb, is_selected ? 1 : 0)

        # Generate a unique view ID for this RadioButton
        rb_id = LibAndroidBridge.android_view_generate_id(@env)
        radio_ids << rb_id
        LibAndroidBridge.android_view_set_id(@env, rb, rb_id)

        # Add RadioButton to RadioGroup
        LibAndroidBridge.android_viewgroup_add_view(@env, rg, rb)

        # Track RadioButton as child NativeView
        global_rb = LibAndroidBridge.android_new_global_ref(@env, rb)
        rb_handle = JNI.wrap_global(global_rb, label: "RadioButton[#{index}]")
        rb_native = NativeView.new(rb_handle)
        native.add_child(rb_native)
      end

      # Select the initially selected radio button
      if view.selected_index >= 0 && view.selected_index < radio_ids.size
        LibAndroidBridge.android_radiogroup_check(@env, rg, radio_ids[view.selected_index])
      end

      # Wire up on_change via OnCheckedChangeListener on the RadioGroup. The
      # listener dispatches the checked child view ID directly and we map it
      # back to the shared option index in Crystal.
      if change_handler = view.on_change
        captured_radio_ids = radio_ids
        fallback_index = view.selected_index
        callback_id = native.track_callback_id(
          UI::CallbackRegistry.register_int(
            ->(checked_id : Int32) do
              resolved_index = captured_radio_ids.index(checked_id) || fallback_index
              change_handler.call(resolved_index)
            end
          )
        )
        LibAndroidBridge.android_radiogroup_set_on_checked_change_listener(@env, rg, callback_id)
      end

      push_native(native, rg)
    end

    # -----------------------------------------------------------------
    # Visit: Slider -> android.widget.SeekBar
    #
    # SeekBar is Android's native slider. It works with integer progress
    # values (0..max), so we scale the Crystal Float64 range to integers.
    #
    # For a slider with minimum=0, maximum=1, step=0.01, we use max=100
    # and scale progress accordingly. For continuous sliders we use max=1000
    # for reasonable precision.
    # -----------------------------------------------------------------
    def visit(view : UI::Slider)
      sb = LibAndroidBridge.android_view_new(@env, "android/widget/SeekBar", @context)

      # Determine integer scale for the SeekBar
      range = view.maximum - view.minimum
      # Use step-based scaling if step is set, otherwise 1000 steps
      steps = if view.step > 0.0
                (range / view.step).round.to_i.clamp(1, 10000)
              else
                1000
              end

      LibAndroidBridge.android_seekbar_set_max(@env, sb, steps)

      # Initial progress scaled from value
      initial_progress = if range > 0.0
                           ((view.value - view.minimum) / range * steps).round.to_i.clamp(0, steps)
                         else
                           0
                         end
      LibAndroidBridge.android_seekbar_set_progress(@env, sb, initial_progress)

      # Tint color for the progress track
      if tint = view.tint_color
        LibAndroidBridge.android_seekbar_set_progress_tint(@env, sb, color_to_argb(tint))
      end

      # Common properties
      apply_common_properties(sb, view)

      global_sb = LibAndroidBridge.android_new_global_ref(@env, sb)
      handle = JNI.wrap_global(global_sb, label: "SeekBar")
      native = NativeView.new(handle)

      # Wire up on_change via OnSeekBarChangeListener. The listener dispatches
      # raw progress directly and we convert that integer progress back to the
      # shared Float64 slider range in Crystal.
      if change_handler = view.on_change
        captured_min = view.minimum
        captured_range = range
        captured_steps = steps
        captured_step = view.step

        callback_id = native.track_callback_id(
          UI::CallbackRegistry.register_float(
            ->(raw_progress_value : Float64) do
              raw_progress = raw_progress_value.round.to_i
              raw_value = if captured_steps > 0
                            captured_min + (raw_progress.to_f64 / captured_steps) * captured_range
                          else
                            captured_min
                          end
              actual_value = if captured_step > 0.0
                               snapped = (raw_value / captured_step).round * captured_step
                               snapped.clamp(captured_min, captured_min + captured_range)
                             else
                               raw_value.clamp(captured_min, captured_min + captured_range)
                             end
              change_handler.call(actual_value)
            end
          )
        )
        LibAndroidBridge.android_seekbar_set_on_change_listener(@env, sb, callback_id)
      end

      push_native(native, sb)
    end

    # -----------------------------------------------------------------
    # Visit: NavigationStack -> android.widget.FrameLayout (navigation container)
    # -----------------------------------------------------------------
    def visit(view : UI::NavigationStack)
      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)

      apply_common_properties(fl, view)

      global_fl = LibAndroidBridge.android_new_global_ref(@env, fl)
      handle = JNI.wrap_global(global_fl, label: "FrameLayout[nav-stack]")
      native = NativeView.new(handle)

      # Render the current view (top of stack or root) into this container
      push_stack(native, fl, is_linear: false)
      view.current_view.accept(self)
      pop_stack

      push_native(native, fl)
    end

    # -----------------------------------------------------------------
    # Visit: NavigationLink -> android.widget.Button (link row)
    # -----------------------------------------------------------------
    def visit(view : UI::NavigationLink)
      btn = LibAndroidBridge.android_view_new(@env, "android/widget/Button", @context)

      LibAndroidBridge.android_textview_set_text(
        @env, btn, view.label.to_unsafe, view.label.bytesize)

      apply_common_properties(btn, view)

      emit(btn, "Button[nav-link]")
    end

    # -----------------------------------------------------------------
    # Visit: TabView -> android.widget.FrameLayout (tab container)
    # -----------------------------------------------------------------
    def visit(view : UI::TabView)
      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)

      apply_common_properties(fl, view)

      global_fl = LibAndroidBridge.android_new_global_ref(@env, fl)
      handle = JNI.wrap_global(global_fl, label: "FrameLayout[tab-view]")
      native = NativeView.new(handle)

      if content = view.current_content
        push_stack(native, fl, is_linear: false)
        content.accept(self)
        pop_stack
      end

      push_native(native, fl)
    end

    # -----------------------------------------------------------------
    # Visit: ProgressView -> android.widget.ProgressBar
    # -----------------------------------------------------------------
    def visit(view : UI::ProgressView)
      # ProgressBar default style is indeterminate circular spinner.
      # For determinate linear we use android/widget/ProgressBar with horizontal style.
      pb = LibAndroidBridge.android_view_new(@env, "android/widget/ProgressBar", @context)

      if val = view.value
        # Determinate: setIndeterminate(false), setProgress(0..10000)
        LibAndroidBridge.android_seekbar_set_max(@env, pb, 10000)
        progress = (val * 10000).round.to_i.clamp(0, 10000)
        LibAndroidBridge.android_seekbar_set_progress(@env, pb, progress)
      end
      # else indeterminate: ProgressBar default behavior is indeterminate

      if tint = view.tint_color
        LibAndroidBridge.android_seekbar_set_progress_tint(@env, pb, color_to_argb(tint))
      end

      apply_common_properties(pb, view)

      emit(pb, "ProgressBar")
    end

    # -----------------------------------------------------------------
    # Visit: ActivityIndicator -> android.widget.ProgressBar (spinner)
    # -----------------------------------------------------------------
    def visit(view : UI::ActivityIndicator)
      spinner = LibAndroidBridge.android_view_new(@env, "android/widget/ProgressBar", @context)

      # Visibility: VISIBLE=0, INVISIBLE=4, GONE=8
      unless view.is_animating
        LibAndroidBridge.android_view_set_visibility(@env, spinner, 4) # INVISIBLE
      end

      if tint = view.color
        LibAndroidBridge.android_seekbar_set_progress_tint(@env, spinner, color_to_argb(tint))
      end

      apply_common_properties(spinner, view)

      emit(spinner, "ProgressBar[spinner]")
    end

    # -----------------------------------------------------------------
    # Visit: Alert -> inline Material dialog study surface
    # -----------------------------------------------------------------
    def visit(view : UI::Alert)
      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 1)

      if view.hidden || !view.is_presented
        LibAndroidBridge.android_view_set_visibility(@env, card, 8)
      end

      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
      LibAndroidBridge.android_material_card_set_elevation(@env, card, 6.0_f32)
      LibAndroidBridge.android_view_set_padding(@env, ll, 24, 24, 24, 20)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, card, ll, -1, -2)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, card)
      handle = JNI.wrap_global(global_ll, label: "MaterialCardView[alert]")
      native = NativeView.new(handle)

      title_tv = new_text_view(view.title, 22.0_f32, material_color(:on_surface), 1)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, ll, title_tv, -1, -2)

      unless view.message.empty?
        msg_tv = new_text_view(view.message, 15.0_f32, material_color(:on_surface_variant), 0)
        LibAndroidBridge.android_view_set_padding(@env, msg_tv, 0, 12, 0, 0)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, ll, msg_tv, -1, -2)
      end

      button_row = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, button_row, 0)
      LibAndroidBridge.android_view_set_padding(@env, button_row, 0, 20, 0, 0)

      push_spacer = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)
      LibAndroidBridge.android_linearlayout_add_view_weight(@env, button_row, push_spacer, 0, -2, 1.0_f32)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, ll, button_row, -1, -2)

      push_stack(native, button_row, is_linear: true)
      if view.buttons.empty?
        UI::Button.new("OK", role: :default, style: UI::ButtonStyle::Borderless).accept(self)
      else
        view.buttons.each do |action|
          role = case action.style
                 when :destructive then :destructive
                 when :cancel      then :cancel
                 else                   :default
                 end
          button = UI::Button.new(action.label, role: role, style: UI::ButtonStyle::Borderless)
          button.on_tap = action.action if action.action
          button.accept(self)
        end
      end
      pop_stack

      apply_common_non_surface_properties(card, view)
      push_native(native, card)
    end

    # -----------------------------------------------------------------
    # Visit: Picker -> android.widget.Spinner
    # -----------------------------------------------------------------
    def visit(view : UI::Picker)
      case view.style
      when UI::PickerStyle::Segmented
        segmented = if change_handler = view.on_change
                      captured_change_handler = change_handler
                      UI::SegmentedControl.new(view.options, view.selected_index) do |selected_index|
                        captured_change_handler.call(selected_index)
                      end
                    else
                      UI::SegmentedControl.new(view.options, view.selected_index)
                    end
        unless view.label.empty?
          segmented.accessibility_label = view.label
        end
        segmented.accept(self)
        return
      when UI::PickerStyle::Inline
        container = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
        LibAndroidBridge.android_linearlayout_set_orientation(@env, container, 1)
        LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
        LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
        LibAndroidBridge.android_view_set_clip_to_outline(@env, container, 1)
        LibAndroidBridge.android_view_set_elevation(@env, container, 2.0_f32)
        LibAndroidBridge.android_view_set_padding(@env, container, 16, 16, 16, 16)

        if !view.label.empty?
          heading = new_text_view(view.label, 14.0_f32, material_color(:on_surface_variant), 1)
          LibAndroidBridge.android_view_set_padding(@env, heading, 0, 0, 0, 12)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, heading, -1, -2)
        end

        apply_common_properties(container, view)

        global_container = LibAndroidBridge.android_new_global_ref(@env, container)
        handle = JNI.wrap_global(global_container, label: "LinearLayout[picker-inline]")
        native = NativeView.new(handle)

        radio_group = if change_handler = view.on_change
                        captured_change_handler = change_handler
                        UI::RadioGroup.new(view.options, view.selected_index) do |selected_index|
                          captured_change_handler.call(selected_index)
                        end
                      else
                        UI::RadioGroup.new(view.options, view.selected_index)
                      end
        push_stack(native, container, is_linear: true)
        radio_group.accept(self)
        pop_stack

        push_native(native, container)
        return
      else
      end

      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
      content = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, content, 1)

      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_medium.to_f32)
      LibAndroidBridge.android_material_card_set_elevation(@env, card, 2.0_f32)
      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
      LibAndroidBridge.android_view_set_padding(@env, content, 16, 16, 16, 12)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, card, content, -1, -2)

      if !view.label.empty?
        heading = new_text_view(view.label, 14.0_f32, material_color(:on_surface_variant), 1)
        LibAndroidBridge.android_view_set_padding(@env, heading, 0, 0, 0, 12)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, heading, -1, -2)
      end

      spinner = LibAndroidBridge.android_view_new(@env, "android/widget/Spinner", @context)
      LibAndroidBridge.android_view_set_background_color(@env, spinner, material_color(:surface_variant))
      LibAndroidBridge.android_view_set_corner_radius(@env, spinner, @material_theme.corner_radius_medium.to_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, spinner, 1)
      LibAndroidBridge.android_view_set_padding(@env, spinner, 12, 10, 12, 10)

      unless view.label.empty?
        LibAndroidBridge.android_spinner_set_prompt(@env, spinner, view.label.to_unsafe, view.label.bytesize)
      end

      if view.options.empty?
        empty_state = new_text_view("No options available", 13.0_f32, material_color(:on_surface_variant), 0)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, empty_state, -1, -2)
      else
        joined_options = view.options.join("\n")
        LibAndroidBridge.android_spinner_set_items(@env, spinner, joined_options.to_unsafe, joined_options.bytesize)
        selected_index = view.selected_index.clamp(0, view.options.size - 1)
        LibAndroidBridge.android_spinner_set_selection(@env, spinner, selected_index)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, spinner, -1, -2)
      end

      apply_common_non_surface_properties(card, view)

      global_card = LibAndroidBridge.android_new_global_ref(@env, card)
      handle = JNI.wrap_global(global_card, label: "MaterialCardView[picker]")
      native = NativeView.new(handle)

      if !view.options.empty? && (change_handler = view.on_change)
        callback_id = native.track_callback_id(UI::CallbackRegistry.register_int(change_handler))
        LibAndroidBridge.android_spinner_set_on_item_selected_listener(@env, spinner, callback_id)
      end

      push_native(native, card)
    end

    # -----------------------------------------------------------------
    # Visit: IconButton -> android.widget.ImageButton
    # -----------------------------------------------------------------
    def visit(view : UI::IconButton)
      ib = LibAndroidBridge.android_view_new(@env, "android/widget/ImageButton", @context)

      # Load icon by name (treated as a drawable resource name)
      LibAndroidBridge.android_imageview_set_image_named(@env, ib, view.icon.to_unsafe)

      if view.disabled
        LibAndroidBridge.android_view_set_alpha(@env, ib, 0.4_f32)
      end

      apply_common_properties(ib, view)

      global_ib = LibAndroidBridge.android_new_global_ref(@env, ib)
      handle = JNI.wrap_global(global_ib, label: "ImageButton[icon]")
      native = NativeView.new(handle)

      if tap_handler = view.on_tap
        callback_id = native.register_callback(tap_handler)
        LibAndroidBridge.android_view_set_on_click_listener(@env, ib, callback_id)
      end

      push_native(native, ib)
    end

    # -----------------------------------------------------------------
    # Visit: ListView -> android.widget.LinearLayout (vertical, with rows)
    # -----------------------------------------------------------------
    def visit(view : UI::ListView)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)

      # VERTICAL = 1
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 1)

      apply_common_properties(ll, view)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, ll)
      handle = JNI.wrap_global(global_ll, label: "LinearLayout[list]")
      native = NativeView.new(handle)

      push_stack(native, ll, is_linear: true)

      view.sections.each do |section|
        if header = section.header
          header_tv = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)
          LibAndroidBridge.android_textview_set_text(
            @env, header_tv, header.to_unsafe, header.bytesize)
          emit(header_tv, "TextView[list-header]")
        end

        section.items.each do |item|
          item.accept(self)
        end
      end

      pop_stack

      push_native(native, ll)
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
    # Visit: SecureField -> android.widget.EditText (password input type)
    # -----------------------------------------------------------------
    def visit(view : UI::SecureField)
      til = new_material_view(
        "com/google/android/material/textfield/TextInputLayout",
        "Widget_Material3_TextInputLayout_FilledBox"
      )
      LibAndroidBridge.android_textinputlayout_set_box_background_mode(@env, til, 1)
      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, til, material_color(:surface_variant))
      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, til, material_color(:outline))
      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, til, material_color(:on_surface_variant))

      unless view.placeholder.empty?
        LibAndroidBridge.android_textinputlayout_set_hint(@env, til, view.placeholder.to_unsafe, view.placeholder.bytesize)
      end

      et = new_material_view(
        "com/google/android/material/textfield/TextInputEditText",
        "Widget_Material3_TextInputEditText_FilledBox"
      )
      LibAndroidBridge.android_view_clear_background(@env, et)

      LibAndroidBridge.android_textview_set_single_line(@env, et, 1)

      unless view.text.empty?
        LibAndroidBridge.android_edittext_set_text(
          @env, et, view.text.to_unsafe, view.text.bytesize)
      end

      # TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_PASSWORD = 0x81
      LibAndroidBridge.android_edittext_set_input_type(@env, et, 0x81)

      LibAndroidBridge.android_textview_set_text_size(@env, et, view.font.size.to_f32)
      LibAndroidBridge.android_textview_set_text_color(
        @env, et, color_to_argb(view.text_color))
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, til, et, -1, -2)

      apply_common_non_surface_properties(til, view)

      global_til = LibAndroidBridge.android_new_global_ref(@env, til)
      handle = JNI.wrap_global(global_til, label: "TextInputLayout[secure]")
      native = NativeView.new(handle)

      if change_handler = view.on_change
        callback_id = native.track_callback_id(UI::CallbackRegistry.register_string(change_handler))
        LibAndroidBridge.android_edittext_set_text_watcher(@env, et, callback_id)
      end

      push_native(native, til)
    end

    # -----------------------------------------------------------------
    # Visit: Stepper -> android.widget.LinearLayout (increment/decrement buttons)
    # -----------------------------------------------------------------
    def visit(view : UI::Stepper)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)

      # HORIZONTAL = 0
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 0)

      apply_common_properties(ll, view)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, ll)
      handle = JNI.wrap_global(global_ll, label: "LinearLayout[stepper]")
      native = NativeView.new(handle)

      push_stack(native, ll, is_linear: true)

      if change_handler = view.on_change
        decrement_handler = change_handler
        minus_button = UI::Button.new("-", style: UI::ButtonStyle::Bordered)
        minus_button.on_tap = Proc(Nil).new do
          next_value = view.value - view.step_value
          if next_value < view.minimum
            next_value = view.wraps ? view.maximum : view.minimum
          end
          decrement_handler.call(next_value)
        end
        minus_button.accept(self)
      else
        UI::Button.new("-", style: UI::ButtonStyle::Bordered).accept(self)
      end

      value_text = if view.value.round == view.value
                     view.value.round.to_i.to_s
                   else
                     view.value.to_s
                   end
      label_text = view.label.empty? ? value_text : "#{view.label}: #{value_text}"
      value_tv = new_text_view(label_text, 16.0_f32, material_color(:on_surface), 1)
      LibAndroidBridge.android_view_set_padding(@env, value_tv, 12, 0, 12, 0)
      emit(value_tv, "TextView[stepper-value]")

      if change_handler = view.on_change
        increment_handler = change_handler
        plus_button = UI::Button.new("+", style: UI::ButtonStyle::Bordered)
        plus_button.on_tap = Proc(Nil).new do
          next_value = view.value + view.step_value
          if next_value > view.maximum
            next_value = view.wraps ? view.minimum : view.maximum
          end
          increment_handler.call(next_value)
        end
        plus_button.accept(self)
      else
        UI::Button.new("+", style: UI::ButtonStyle::Bordered).accept(self)
      end

      pop_stack

      push_native(native, ll)
    end

    # -----------------------------------------------------------------
    # Visit: SegmentedControl -> android.widget.RadioGroup (segmented style)
    # -----------------------------------------------------------------
    def visit(view : UI::SegmentedControl)
      rg = LibAndroidBridge.android_view_new(@env, "android/widget/RadioGroup", @context)

      # HORIZONTAL = 0
      LibAndroidBridge.android_linearlayout_set_orientation(@env, rg, 0)

      apply_common_properties(rg, view)

      segment_ids = Array(Int32).new(view.segments.size)

      view.segments.each_with_index do |segment, index|
        rb = LibAndroidBridge.android_view_new(@env, "android/widget/RadioButton", @context)
        LibAndroidBridge.android_radiobutton_set_text(@env, rb, segment.to_unsafe, segment.bytesize)
        LibAndroidBridge.android_radiobutton_set_checked(@env, rb, index == view.selected_index ? 1 : 0)
        rb_id = LibAndroidBridge.android_view_generate_id(@env)
        segment_ids << rb_id
        LibAndroidBridge.android_view_set_id(@env, rb, rb_id)
        LibAndroidBridge.android_viewgroup_add_view(@env, rg, rb)
      end

      if view.selected_index >= 0 && view.selected_index < segment_ids.size
        LibAndroidBridge.android_radiogroup_check(@env, rg, segment_ids[view.selected_index])
      end

      global_rg = LibAndroidBridge.android_new_global_ref(@env, rg)
      handle = JNI.wrap_global(global_rg, label: "RadioGroup[segmented]")
      native = NativeView.new(handle)

      if change_handler = view.on_change
        captured_segment_ids = segment_ids
        fallback_index = view.selected_index
        callback_id = native.track_callback_id(
          UI::CallbackRegistry.register_int(
            ->(checked_id : Int32) do
              resolved_index = captured_segment_ids.index(checked_id) || fallback_index
              change_handler.call(resolved_index)
            end
          )
        )
        LibAndroidBridge.android_radiogroup_set_on_checked_change_listener(@env, rg, callback_id)
      end

      push_native(native, rg)
    end

    # -----------------------------------------------------------------
    # Visit: DatePicker -> android.widget.DatePicker
    # -----------------------------------------------------------------
    def visit(view : UI::DatePicker)
      dp = LibAndroidBridge.android_view_new(@env, "android/widget/DatePicker", @context)

      apply_common_properties(dp, view)

      emit(dp, "DatePicker")
    end

    # -----------------------------------------------------------------
    # Visit: TimePicker -> android.widget.TimePicker
    # -----------------------------------------------------------------
    def visit(view : UI::TimePicker)
      tp = LibAndroidBridge.android_view_new(@env, "android/widget/TimePicker", @context)

      apply_common_properties(tp, view)

      emit(tp, "TimePicker")
    end

    # -----------------------------------------------------------------
    # Visit: SearchField -> android.widget.SearchView
    # -----------------------------------------------------------------
    def visit(view : UI::SearchField)
      sv = LibAndroidBridge.android_view_new(@env, "android/widget/SearchView", @context)
      LibAndroidBridge.android_searchview_set_iconified(@env, sv, 0)

      unless view.placeholder.empty?
        LibAndroidBridge.android_searchview_set_query_hint(@env, sv, view.placeholder.to_unsafe, view.placeholder.bytesize)
      end

      unless view.text.empty?
        LibAndroidBridge.android_searchview_set_query(@env, sv, view.text.to_unsafe, view.text.bytesize, 0)
      end

      apply_common_properties(sv, view)

      global_sv = LibAndroidBridge.android_new_global_ref(@env, sv)
      handle = JNI.wrap_global(global_sv, label: "SearchView")
      native = NativeView.new(handle)

      change_callback_id = if change_handler = view.on_change
                             native.track_callback_id(UI::CallbackRegistry.register_string(change_handler))
                           else
                             0_u64
                           end

      submit_callback_id = if submit_handler = view.on_submit
                             native.track_callback_id(UI::CallbackRegistry.register_string(submit_handler))
                           else
                             0_u64
                           end

      if change_callback_id != 0_u64 || submit_callback_id != 0_u64
        LibAndroidBridge.android_searchview_set_on_query_text_listener(
          @env,
          sv,
          change_callback_id,
          submit_callback_id
        )
      end

      if cancel_handler = view.on_cancel
        callback_id = native.register_callback(cancel_handler)
        LibAndroidBridge.android_searchview_set_on_close_listener(@env, sv, callback_id)
      end

      LibAndroidBridge.android_view_clear_focus(@env, sv)

      push_native(native, sv)
    end

    # -----------------------------------------------------------------
    # Visit: PageControl -> Material-style row of page indicator dots
    # -----------------------------------------------------------------
    def visit(view : UI::PageControl)
      total = [view.total, 1].max
      current = view.current.clamp(0, total - 1)

      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 0)
      LibAndroidBridge.android_linearlayout_set_gravity(@env, ll, 17)
      LibAndroidBridge.android_view_set_padding(@env, ll, 8, 8, 8, 8)

      total.times do |index|
        dot = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
        is_current = index == current
        fill = if is_current
                 if tint = view.tint_color
                   color_to_argb(tint)
                 else
                   material_color(:on_surface)
                 end
               elsif tint = view.page_indicator_tint_color
                 color_to_argb(tint)
               elsif tint = view.tint_color
                 color_to_argb(tint)
               else
                 material_color(:outline_variant)
               end
        size = is_current ? 18 : 12
        LibAndroidBridge.android_view_set_background_color(@env, dot, fill)
        LibAndroidBridge.android_view_set_corner_radius(@env, dot, (size / 2).to_f32)
        LibAndroidBridge.android_view_set_clip_to_outline(@env, dot, 1)
        if !is_current && view.page_indicator_tint_color.nil?
          LibAndroidBridge.android_view_set_stroke(@env, dot, 1.0_f32, material_color(:outline))
        end
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, ll, dot, size, size)
      end

      acc_label = view.accessibility_label || "Page #{current + 1} of #{total}"
      LibAndroidBridge.android_view_set_content_description(@env, ll, acc_label.to_unsafe, acc_label.bytesize)
      apply_common_properties(ll, view)
      emit(ll, "LinearLayout[page-control]")
    end

    # -----------------------------------------------------------------
    # Visit: ComboBox -> outlined text field + trailing chevron affordance
    # -----------------------------------------------------------------
    def visit(view : UI::ComboBox)
      shell = new_material_view(
        "com/google/android/material/textfield/TextInputLayout",
        "Widget_Material3_TextInputLayout_OutlinedBox_ExposedDropdownMenu"
      )
      LibAndroidBridge.android_textinputlayout_set_box_background_mode(@env, shell, 2)
      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, shell, material_color(:surface))
      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, shell, material_color(:outline))
      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, shell, material_color(:on_surface_variant))
      LibAndroidBridge.android_textinputlayout_set_end_icon_mode(@env, shell, 3)

      unless view.placeholder.empty?
        LibAndroidBridge.android_textinputlayout_set_hint(@env, shell, view.placeholder.to_unsafe, view.placeholder.bytesize)
      end
      if !view.options.empty?
        helper_text = "#{view.options.size} options"
        LibAndroidBridge.android_textinputlayout_set_helper_text(@env, shell, helper_text.to_unsafe, helper_text.bytesize)
      end

      field = new_material_view(
        "com/google/android/material/textfield/MaterialAutoCompleteTextView",
        "Widget_Material3_AutoCompleteTextView_OutlinedBox"
      )
      LibAndroidBridge.android_view_clear_background(@env, field)
      unless view.value.empty?
        LibAndroidBridge.android_edittext_set_text(@env, field, view.value.to_unsafe, view.value.bytesize)
      end
      LibAndroidBridge.android_textview_set_single_line(@env, field, 1)
      LibAndroidBridge.android_textview_set_text_size(@env, field, @material_theme.font_size_body.to_f32)
      LibAndroidBridge.android_textview_set_text_color(@env, field, material_color(:on_surface))
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, shell, field, -1, -2)

      if acc = view.accessibility_label
        LibAndroidBridge.android_view_set_content_description(@env, shell, acc.to_unsafe, acc.bytesize)
      elsif !view.placeholder.empty?
        LibAndroidBridge.android_view_set_content_description(@env, shell, view.placeholder.to_unsafe, view.placeholder.bytesize)
      end

      apply_common_non_surface_properties(shell, view)
      emit(shell, "TextInputLayout[combo-box]")
    end

    # -----------------------------------------------------------------
    # Visit: RatingIndicator -> Material-style star row using TextViews
    # -----------------------------------------------------------------
    def visit(view : UI::RatingIndicator)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 0)
      LibAndroidBridge.android_linearlayout_set_gravity(@env, ll, 16)

      clamped = view.value.clamp(0.0, view.max.to_f64)
      filled_count = clamped.round.to_i
      tint = if color = view.tint_color
               color_to_argb(color)
             else
               0xFFFFC107_u32.to_i32
             end

      view.max.times do |index|
        star = new_text_view(index < filled_count ? "★" : "☆", 20.0_f32, tint, 0)
        LibAndroidBridge.android_view_set_padding(@env, star, 0, 0, 4, 0)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, ll, star, -2, -2)
      end

      acc = view.accessibility_label || "#{filled_count} out of #{view.max} stars"
      LibAndroidBridge.android_view_set_content_description(@env, ll, acc.to_unsafe, acc.bytesize)
      apply_common_properties(ll, view)
      emit(ll, "LinearLayout[rating-indicator]")
    end

    # -----------------------------------------------------------------
    # Visit: TextArea -> android.widget.EditText (multiline)
    # -----------------------------------------------------------------
    def visit(view : UI::TextArea)
      til = new_material_view(
        "com/google/android/material/textfield/TextInputLayout",
        "Widget_Material3_TextInputLayout_FilledBox"
      )
      LibAndroidBridge.android_textinputlayout_set_box_background_mode(@env, til, 1)
      LibAndroidBridge.android_textinputlayout_set_box_background_color(@env, til, material_color(:surface_variant))
      LibAndroidBridge.android_textinputlayout_set_box_stroke_color(@env, til, material_color(:outline))
      LibAndroidBridge.android_textinputlayout_set_hint_text_color(@env, til, material_color(:on_surface_variant))

      unless view.placeholder.empty?
        LibAndroidBridge.android_textinputlayout_set_hint(@env, til, view.placeholder.to_unsafe, view.placeholder.bytesize)
      end

      et = new_material_view(
        "com/google/android/material/textfield/TextInputEditText",
        "Widget_Material3_TextInputEditText_FilledBox"
      )
      LibAndroidBridge.android_view_clear_background(@env, et)

      unless view.text.empty?
        LibAndroidBridge.android_edittext_set_text(
          @env, et, view.text.to_unsafe, view.text.bytesize)
      end

      # InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE = 0x00020001
      LibAndroidBridge.android_edittext_set_input_type(@env, et, 0x00020001)

      LibAndroidBridge.android_textview_set_text_size(@env, et, view.font.size.to_f32)
      LibAndroidBridge.android_textview_set_typeface(@env, et, typeface_style_for(view.font))
      LibAndroidBridge.android_textview_set_text_color(@env, et, color_to_argb(view.text_color))
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, til, et, -1, -2)

      apply_common_non_surface_properties(til, view)

      global_et = LibAndroidBridge.android_new_global_ref(@env, til)
      handle = JNI.wrap_global(global_et, label: "TextInputLayout[textarea]")
      native = NativeView.new(handle)

      if change_handler = view.on_change
        callback_id = native.track_callback_id(UI::CallbackRegistry.register_string(change_handler))
        LibAndroidBridge.android_edittext_set_text_watcher(@env, et, callback_id)
      end

      push_native(native, til)
    end

    # -----------------------------------------------------------------
    # Visit: Grid -> android.widget.LinearLayout (grid rows)
    # -----------------------------------------------------------------
    def visit(view : UI::Grid)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)

      # VERTICAL = 1
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 1)

      apply_common_properties(ll, view)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, ll)
      handle = JNI.wrap_global(global_ll, label: "LinearLayout[grid]")
      native = NativeView.new(handle)

      push_stack(native, ll, is_linear: true)
      view.children.each do |row|
        row.each do |cell|
          cell.accept(self)
        end
      end
      pop_stack

      push_native(native, ll)
    end

    # -----------------------------------------------------------------
    # Visit: Form -> android.widget.LinearLayout (form sections)
    # -----------------------------------------------------------------
    def visit(view : UI::Form)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)

      # VERTICAL = 1
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 1)

      apply_common_properties(ll, view)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, ll)
      handle = JNI.wrap_global(global_ll, label: "LinearLayout[form]")
      native = NativeView.new(handle)

      push_stack(native, ll, is_linear: true)

      view.sections.each do |section|
        if header = section.header
          header_tv = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)
          LibAndroidBridge.android_textview_set_text(@env, header_tv, header.to_unsafe, header.bytesize)
          emit(header_tv, "TextView[form-header]")
        end

        section.fields.each do |field|
          row_ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
          LibAndroidBridge.android_linearlayout_set_orientation(@env, row_ll, 0) # HORIZONTAL

          unless field.label.empty?
            lbl_tv = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)
            LibAndroidBridge.android_textview_set_text(@env, lbl_tv, field.label.to_unsafe, field.label.bytesize)
            LibAndroidBridge.android_viewgroup_add_view(@env, row_ll, lbl_tv)
          end

          if content = field.content
            row_global = LibAndroidBridge.android_new_global_ref(@env, row_ll)
            row_handle = JNI.wrap_global(row_global, label: "LinearLayout[form-row]")
            row_native = NativeView.new(row_handle)
            push_stack(row_native, row_ll, is_linear: true)
            content.accept(self)
            pop_stack
            LibAndroidBridge.android_viewgroup_add_view(@env, ll, row_ll)
          else
            LibAndroidBridge.android_viewgroup_add_view(@env, ll, row_ll)
          end
        end

        if footer = section.footer
          footer_tv = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)
          LibAndroidBridge.android_textview_set_text(@env, footer_tv, footer.to_unsafe, footer.bytesize)
          emit(footer_tv, "TextView[form-footer]")
        end
      end

      pop_stack

      push_native(native, ll)
    end

    # -----------------------------------------------------------------
    # Visit: NavigationSplitView -> android.widget.LinearLayout (horizontal split)
    # -----------------------------------------------------------------
    def visit(view : UI::NavigationSplitView)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)

      # HORIZONTAL = 0
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 0)

      apply_common_properties(ll, view)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, ll)
      handle = JNI.wrap_global(global_ll, label: "LinearLayout[split]")
      native = NativeView.new(handle)

      push_stack(native, ll, is_linear: true)

      if view.shows_sidebar
        if sidebar = view.sidebar
          sidebar.accept(self)
        end
      end

      if content = view.content
        content.accept(self)
      end

      if detail = view.detail
        detail.accept(self)
      end

      pop_stack

      push_native(native, ll)
    end

    # -----------------------------------------------------------------
    # Visit: Toolbar -> android.widget.LinearLayout (toolbar container)
    # -----------------------------------------------------------------
    def visit(view : UI::Toolbar)
      toolbar = LibAndroidBridge.android_view_new(@env, "com/google/android/material/appbar/MaterialToolbar", @context)
      LibAndroidBridge.android_view_set_elevation(@env, toolbar, 3.0_f32)
      LibAndroidBridge.android_view_set_padding(@env, toolbar, 12, 8, 12, 8)
      LibAndroidBridge.android_toolbar_set_title_text_color(@env, toolbar, material_color(:on_surface))

      if view.shows_title
        title_text = view.title || "Material study"
        LibAndroidBridge.android_toolbar_set_title(@env, toolbar, title_text.to_unsafe, title_text.bytesize)
      end

      view.items.each_with_index do |item, index|
        LibAndroidBridge.android_toolbar_add_menu_item(@env, toolbar, index + 1, item.label.to_unsafe, item.label.bytesize, 6)
      end

      apply_common_non_surface_properties(toolbar, view)
      emit(toolbar, "MaterialToolbar")
    end

    # -----------------------------------------------------------------
    # Visit: Sheet -> inline Material bottom-sheet surface
    # -----------------------------------------------------------------
    def visit(view : UI::Sheet)
      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
      content = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, content, 1)

      unless view.is_presented
        LibAndroidBridge.android_view_set_visibility(@env, card, 8)
      end

      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
      LibAndroidBridge.android_material_card_set_elevation(@env, card, 10.0_f32)
      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
      LibAndroidBridge.android_view_set_padding(@env, content, 20, 16, 20, 20)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, card, content, -1, -2)

      if view.shows_drag_indicator
        handle_bar = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
        LibAndroidBridge.android_view_set_background_color(@env, handle_bar, material_color(:outline))
        LibAndroidBridge.android_view_set_corner_radius(@env, handle_bar, 3.0_f32)
        LibAndroidBridge.android_view_set_alpha(@env, handle_bar, 0.7_f32)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, handle_bar, 48, 6)
      end

      detents = view.detents.map(&.to_s.gsub('_', ' ').capitalize).join(" • ")
      title = new_text_view("Bottom sheet", 18.0_f32, material_color(:on_surface), 1)
      subtitle = new_text_view("Detents: #{detents}  Active: #{view.selected_detent.to_s.gsub('_', ' ').capitalize}", 13.0_f32, material_color(:on_surface_variant), 0)
      LibAndroidBridge.android_view_set_padding(@env, title, 0, 12, 0, 4)
      LibAndroidBridge.android_view_set_padding(@env, subtitle, 0, 0, 0, 16)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, title, -1, -2)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, subtitle, -1, -2)

      global_card = LibAndroidBridge.android_new_global_ref(@env, card)
      handle = JNI.wrap_global(global_card, label: "MaterialCardView[sheet]")
      native = NativeView.new(handle)

      if content_view = view.content
        inner = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
        LibAndroidBridge.android_linearlayout_set_orientation(@env, inner, 1)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, inner, -1, -2)
        push_stack(native, inner, is_linear: true)
        content_view.accept(self)
        pop_stack
      end

      if dismiss_handler = view.on_dismiss
        footer = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
        LibAndroidBridge.android_linearlayout_set_orientation(@env, footer, 0)
        LibAndroidBridge.android_view_set_padding(@env, footer, 0, 16, 0, 0)
        spacer = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)
        LibAndroidBridge.android_linearlayout_add_view_weight(@env, footer, spacer, 0, -2, 1.0_f32)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, footer, -1, -2)
        push_stack(native, footer, is_linear: true)
        dismiss_button = UI::Button.new("Dismiss", role: :cancel, style: UI::ButtonStyle::Borderless)
        dismiss_button.on_tap = dismiss_handler
        dismiss_button.accept(self)
        pop_stack
      end

      apply_common_non_surface_properties(card, view)
      push_native(native, card)
    end

    # -----------------------------------------------------------------
    # Visit: Popover -> inline Material callout surface
    # -----------------------------------------------------------------
    def visit(view : UI::Popover)
      outer = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      is_horizontal = view.arrow_edge == :leading || view.arrow_edge == :trailing
      LibAndroidBridge.android_linearlayout_set_orientation(@env, outer, is_horizontal ? 0 : 1)

      unless view.is_presented
        LibAndroidBridge.android_view_set_visibility(@env, outer, 8)
      end

      arrow_glyph = case view.arrow_edge
                    when :top      then "▲"
                    when :leading  then "◀"
                    when :trailing then "▶"
                    else                "▼"
                    end
      arrow = new_text_view(arrow_glyph, 20.0_f32, material_color(:primary), 1)

      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
      content = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, content, 1)
      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_medium.to_f32)
      LibAndroidBridge.android_material_card_set_elevation(@env, card, 6.0_f32)
      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
      LibAndroidBridge.android_view_set_padding(@env, content, 18, 18, 18, 18)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, card, content, -1, -2)

      if view.arrow_edge == :top || view.arrow_edge == :leading
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, outer, arrow, -2, -2)
      end
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, outer, card, view.preferred_width.try(&.round.to_i) || -2, view.preferred_height.try(&.round.to_i) || -2)
      if view.arrow_edge == :bottom || view.arrow_edge == :trailing
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, outer, arrow, -2, -2)
      end

      title = new_text_view("Popover", 16.0_f32, material_color(:on_surface), 1)
      subtitle = new_text_view("Arrow edge: #{view.arrow_edge.to_s.capitalize}", 12.0_f32, material_color(:on_surface_variant), 0)
      LibAndroidBridge.android_view_set_padding(@env, title, 0, 0, 0, 4)
      LibAndroidBridge.android_view_set_padding(@env, subtitle, 0, 0, 0, 12)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, title, -1, -2)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, subtitle, -1, -2)

      global_outer = LibAndroidBridge.android_new_global_ref(@env, outer)
      handle = JNI.wrap_global(global_outer, label: "LinearLayout[popover]")
      native = NativeView.new(handle)

      if content_view = view.content
        inner = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
        LibAndroidBridge.android_linearlayout_set_orientation(@env, inner, 1)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, inner, -1, -2)
        push_stack(native, inner, is_linear: true)
        content_view.accept(self)
        pop_stack
      end

      if dismiss_handler = view.on_dismiss
        footer = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
        LibAndroidBridge.android_linearlayout_set_orientation(@env, footer, 0)
        LibAndroidBridge.android_view_set_padding(@env, footer, 0, 14, 0, 0)
        spacer = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)
        LibAndroidBridge.android_linearlayout_add_view_weight(@env, footer, spacer, 0, -2, 1.0_f32)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, footer, -1, -2)
        push_stack(native, footer, is_linear: true)
        dismiss_button = UI::Button.new("Close", role: :cancel, style: UI::ButtonStyle::Borderless)
        dismiss_button.on_tap = dismiss_handler
        dismiss_button.accept(self)
        pop_stack
      end

      apply_common_non_surface_properties(outer, view)
      push_native(native, outer)
    end

    # -----------------------------------------------------------------
    # Visit: ConfirmationDialog -> inline Material dialog study surface
    # -----------------------------------------------------------------
    def visit(view : UI::ConfirmationDialog)
      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
      content = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, content, 1)

      unless view.is_presented
        LibAndroidBridge.android_view_set_visibility(@env, card, 8)
      end

      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
      LibAndroidBridge.android_material_card_set_elevation(@env, card, 6.0_f32)
      LibAndroidBridge.android_view_set_padding(@env, content, 24, 24, 24, 20)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, card, content, -1, -2)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, card)
      handle = JNI.wrap_global(global_ll, label: "MaterialCardView[confirmation-dialog]")
      native = NativeView.new(handle)

      title_tv = new_text_view(view.title, 22.0_f32, material_color(:on_surface), 1)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, title_tv, -1, -2)

      unless view.message.empty?
        msg_tv = new_text_view(view.message, 15.0_f32, material_color(:on_surface_variant), 0)
        LibAndroidBridge.android_view_set_padding(@env, msg_tv, 0, 12, 0, 0)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, msg_tv, -1, -2)
      end

      button_row = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, button_row, 0)
      LibAndroidBridge.android_view_set_padding(@env, button_row, 0, 20, 0, 0)
      push_spacer = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)
      LibAndroidBridge.android_linearlayout_add_view_weight(@env, button_row, push_spacer, 0, -2, 1.0_f32)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, button_row, -1, -2)

      push_stack(native, button_row, is_linear: true)
      cancel_button = UI::Button.new(view.cancel_label, role: :cancel, style: UI::ButtonStyle::Borderless)
      cancel_button.on_tap = view.on_cancel if view.on_cancel
      cancel_button.accept(self)
      confirm_style = view.confirm_style == :destructive ? UI::ButtonStyle::Prominent : UI::ButtonStyle::Tinted
      confirm_role = view.confirm_style == :destructive ? :destructive : :default
      confirm_button = UI::Button.new(view.confirm_label, role: confirm_role, style: confirm_style)
      confirm_button.on_tap = view.on_confirm if view.on_confirm
      confirm_button.accept(self)
      pop_stack

      apply_common_non_surface_properties(card, view)
      push_native(native, card)
    end

    # -----------------------------------------------------------------
    # Visit: Snackbar -> inline Material snackbar surface
    # -----------------------------------------------------------------
    def visit(view : UI::Snackbar)
      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
      row = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, row, 0)
      LibAndroidBridge.android_linearlayout_set_gravity(@env, row, 16)

      unless view.is_presented
        LibAndroidBridge.android_view_set_visibility(@env, card, 8)
      end

      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:inverse_surface))
      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
      LibAndroidBridge.android_material_card_set_elevation(@env, card, 6.0_f32)
      LibAndroidBridge.android_view_set_padding(@env, row, 16, 14, 16, 14)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, card, row, -1, -2)

      message = new_text_view(view.message, 14.0_f32, material_color(:inverse_on_surface), 0)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, row, message, -2, -2)

      spacer = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)
      LibAndroidBridge.android_linearlayout_add_view_weight(@env, row, spacer, 0, -2, 1.0_f32)

      global_card = LibAndroidBridge.android_new_global_ref(@env, card)
      handle = JNI.wrap_global(global_card, label: "MaterialCardView[snackbar]")
      native = NativeView.new(handle)

      if action_label = view.action_label
        push_stack(native, row, is_linear: true)
        action_button = UI::Button.new(action_label, style: UI::ButtonStyle::Borderless)
        action_button.on_tap = view.on_action if view.on_action
        action_button.accept(self)
        pop_stack
      else
        duration = new_text_view("#{view.duration.round.to_i}s", 12.0_f32, material_color(:primary), 1)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, row, duration, -2, -2)
      end

      apply_common_non_surface_properties(card, view)
      push_native(native, card)
    end

    # -----------------------------------------------------------------
    # Visit: Card -> com.google.android.material.card.MaterialCardView (via FrameLayout)
    # -----------------------------------------------------------------
    def visit(view : UI::Card)
      fl = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)

      global_fl = LibAndroidBridge.android_new_global_ref(@env, fl)
      handle = JNI.wrap_global(global_fl, label: "MaterialCardView[card]")
      native = NativeView.new(handle)

      LibAndroidBridge.android_material_card_set_background_color(
        @env, fl,
        material_color(view.material == :tertiary ? :surface_variant : :surface))
      LibAndroidBridge.android_material_card_set_radius(
        @env, fl,
        (view.corner_radius > 0.0 ? view.corner_radius : @material_theme.corner_radius_medium).to_f32)
      LibAndroidBridge.android_material_card_set_elevation(
        @env, fl,
        (view.elevation > 0 ? view.elevation : 2.0).to_f32)
      if view.is_outlined
        LibAndroidBridge.android_material_card_set_stroke_color(@env, fl, material_color(:outline_variant))
        LibAndroidBridge.android_material_card_set_stroke_width(@env, fl, 1)
      else
        LibAndroidBridge.android_material_card_set_stroke_width(@env, fl, 0)
      end

      content_ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, content_ll, 1)
      padding = view.content_padding
      LibAndroidBridge.android_view_set_padding(
        @env, content_ll,
        padding.leading.round.to_i,
        padding.top.round.to_i,
        padding.trailing.round.to_i,
        padding.bottom.round.to_i)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, fl, content_ll, -1, -2)

      if title = view.title
        title_tv = new_text_view(title, 18.0_f32, material_color(:on_surface), 1)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content_ll, title_tv, -1, -2)
      end

      if content = view.content
        push_stack(native, content_ll, is_linear: true)
        content.accept(self)
        pop_stack
      end

      apply_common_non_surface_properties(fl, view)
      push_native(native, fl)
    end

    # -----------------------------------------------------------------
    # Visit: Surface -> android.widget.FrameLayout (elevated surface)
    # -----------------------------------------------------------------
    def visit(view : UI::Surface)
      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)

      if view.elevation > 0
        LibAndroidBridge.android_view_set_elevation(@env, fl, view.elevation.to_f32)
      end

      apply_common_properties(fl, view)

      global_fl = LibAndroidBridge.android_new_global_ref(@env, fl)
      handle = JNI.wrap_global(global_fl, label: "FrameLayout[surface]")
      native = NativeView.new(handle)

      if content = view.content
        push_stack(native, fl, is_linear: false)
        content.accept(self)
        pop_stack
      end

      push_native(native, fl)
    end

    # -----------------------------------------------------------------
    # Visit: Divider -> android.view.View (thin separator)
    # -----------------------------------------------------------------
    def visit(view : UI::Divider)
      v = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)

      c = view.color
      LibAndroidBridge.android_view_set_background_color(@env, v, color_to_argb(c))

      apply_common_properties(v, view)

      emit(v, "View[divider]")
    end

    # -----------------------------------------------------------------
    # Visit: GlassBackground -> android.widget.FrameLayout + RenderEffect
    #
    # Phase 5 v2: tokenized via the quantizer model. Brand intensity
    # selects the EFFECTIVE ThicknessStep through `Material#resolve(...)`;
    # the effective step's PREDEFINED `blur_radius` drives RenderEffect
    # on API 31+, and the effective step's PREDEFINED `opacity` drives
    # the FrameLayout alpha fallback on API < 31. This replaces iter1's
    # proportional `step.blur_radius * intensity` scaling — the call
    # site here is unchanged because v2's `resolve()` returns the
    # quantizer's effective step's predefined values directly. See
    # brief.yml adapter_cardinality row 3.
    #
    # Empirical verification (real RenderEffect render on a real device)
    # is Phase 6.5's audit harness work per the Phase 5 brief.
    # -----------------------------------------------------------------
    def visit(view : UI::GlassBackground)
      resolved = @design_tokens.material.resolve(view.material)

      fl = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)

      # Compose fallback ARGB: white tint (0xFFFFFF) at per-step opacity.
      # Matches the previous hard-coded alpha-byte table when opacity is
      # at the default values (0.20/0.40/0.60/0.73/0.87 -> 0x33/0x66/0x99/0xBB/0xDD).
      alpha_byte = (resolved.opacity * 255.0).round.to_i.clamp(0, 255)
      fallback_argb = ((alpha_byte.to_u32 << 24) | 0x00FFFFFF_u32).to_i32!

      applied_real_blur = LibAndroidBridge.android_view_apply_glass(
        @env, fl, resolved.blur_radius.to_f32, fallback_argb
      )

      # Defensive: if the helper class wasn't bundled (returns 0 even on
      # API 31+), fall through to the legacy alpha background so the
      # surface remains visually distinguishable.
      if applied_real_blur == 0
        LibAndroidBridge.android_view_set_background_color(@env, fl, fallback_argb)
      end

      apply_common_properties(fl, view)

      global_fl = LibAndroidBridge.android_new_global_ref(@env, fl)
      handle = JNI.wrap_global(global_fl, label: "FrameLayout[glass]")
      native = NativeView.new(handle)

      if content = view.content
        push_stack(native, fl, is_linear: false)
        content.accept(self)
        pop_stack
      end

      push_native(native, fl)
    end

    # -----------------------------------------------------------------
    # P2 Wave 3 Visit methods
    # -----------------------------------------------------------------

    def visit(view : UI::AsyncImage)
      iv = LibAndroidBridge.android_view_new(@env, "android/widget/ImageView", @context)
      apply_common_properties(iv, view)
      emit(iv, "ImageView[async]")
    end

    def visit(view : UI::RichText)
      tv = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)
      unless view.plain_text.empty?
        LibAndroidBridge.android_textview_set_text(
          @env, tv, view.plain_text.to_unsafe, view.plain_text.bytesize)
      end
      apply_common_properties(tv, view)
      emit(tv, "TextView[rich]")
    end

    def visit(view : UI::LinkButton)
      btn = LibAndroidBridge.android_view_new(@env, "android/widget/Button", @context)
      LibAndroidBridge.android_textview_set_text(
        @env, btn, view.label.to_unsafe, view.label.bytesize)
      apply_common_properties(btn, view)
      emit(btn, "Button[link]")
    end

    def visit(view : UI::MenuButton)
      btn = LibAndroidBridge.android_view_new(@env, "android/widget/Button", @context)
      LibAndroidBridge.android_textview_set_text(
        @env, btn, view.label.to_unsafe, view.label.bytesize)
      apply_common_properties(btn, view)
      emit(btn, "Button[menu]")
    end

    # Phase 4 — Tier 3. UI::ContextMenu is Apple-family only (flag?(:macos)
    # || flag?(:ios)); the class does not exist on -Dandroid, so no
    # visitor for it. Android applications use
    # UI::ContextMenuWithWebFallback (below), which renders as a
    # LinearLayout dropdown (preserves the prior visitor shape).
    def visit(view : UI::ContextMenuWithWebFallback)
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 1)
      apply_common_properties(ll, view)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, ll)
      handle = JNI.wrap_global(global_ll, label: "LinearLayout[context-menu-fallback]")
      native = NativeView.new(handle)

      view.items.each do |entry|
        case entry
        when UI::ContextMenuWithWebFallback::Separator
          sep = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
          LibAndroidBridge.android_view_set_background_color(@env, sep, 0x2E3C3C43)
          sep_global = LibAndroidBridge.android_new_global_ref(@env, sep)
          sep_handle = JNI.wrap_global(sep_global, label: "View[context-menu-separator]")
          sep_native = NativeView.new(sep_handle)
          native.add_child(sep_native)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, ll, sep, -1, 1)
        when UI::ContextMenuWithWebFallback::Item
          tv = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)
          LibAndroidBridge.android_textview_set_text(@env, tv, entry.label.to_unsafe, entry.label.bytesize)
          color = if entry.is_destructive
                    0xFFFF3B30_u32
                  elsif entry.is_disabled
                    0xFF8E8E93_u32
                  else
                    0xFF111111_u32
                  end
          LibAndroidBridge.android_textview_set_text_color(@env, tv, color.to_i32)
          LibAndroidBridge.android_view_set_padding(@env, tv, 24, 18, 24, 18)
          tv_global = LibAndroidBridge.android_new_global_ref(@env, tv)
          tv_handle = JNI.wrap_global(tv_global, label: "TextView[context-menu-item]")
          tv_native = NativeView.new(tv_handle)
          native.add_child(tv_native)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, ll, tv, -1, -2)
        end
      end

      push_native(native, ll)
    end

    def visit(view : UI::ToggleButton)
      btn = LibAndroidBridge.android_view_new(@env, "android/widget/ToggleButton", @context)
      LibAndroidBridge.android_textview_set_text(
        @env, btn, view.label.to_unsafe, view.label.bytesize)
      apply_common_properties(btn, view)
      emit(btn, "ToggleButton")
    end

    def visit(view : UI::TextEditor)
      et = LibAndroidBridge.android_view_new(@env, "android/widget/EditText", @context)
      unless view.text.empty?
        LibAndroidBridge.android_edittext_set_text(
          @env, et, view.text.to_unsafe, view.text.bytesize)
      end
      unless view.placeholder.empty?
        LibAndroidBridge.android_edittext_set_hint(
          @env, et, view.placeholder.to_unsafe, view.placeholder.bytesize)
      end
      apply_common_properties(et, view)
      emit(et, "EditText[editor]")
    end

    # -----------------------------------------------------------------
    # P3 Visit methods
    # -----------------------------------------------------------------

    # Circle: android.view.View with background color, corner radius = size/2
    # (full circle via outline provider), and optional stroke.
    def visit(view : UI::Circle)
      v = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)

      # Fill color as background
      LibAndroidBridge.android_view_set_background_color(
        @env, v, color_to_argb(view.fill_color))

      # Corner radius = half the size to make a circle
      radius = (view.size / 2.0).to_f32
      LibAndroidBridge.android_view_set_corner_radius(@env, v, radius)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, v, 1)

      # Optional stroke
      if view.stroke_width > 0.0
        stroke_color = view.stroke_color || UI::Color.new(r: 0.0, g: 0.0, b: 0.0)
        LibAndroidBridge.android_view_set_stroke(
          @env, v, view.stroke_width.to_f32, color_to_argb(stroke_color))
      end

      apply_common_properties(v, view)
      emit(v, "View[circle]")
    end

    # Rectangle: android.view.View with background color and optional stroke.
    def visit(view : UI::Rectangle)
      v = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)

      # Fill color as background
      LibAndroidBridge.android_view_set_background_color(
        @env, v, color_to_argb(view.fill_color))

      # Optional stroke
      if view.stroke_width > 0.0
        stroke_color = view.stroke_color || UI::Color.new(r: 0.0, g: 0.0, b: 0.0)
        LibAndroidBridge.android_view_set_stroke(
          @env, v, view.stroke_width.to_f32, color_to_argb(stroke_color))
      end

      apply_common_properties(v, view)
      emit(v, "View[rectangle]")
    end

    # RoundedRectangle: android.view.View with corner radius, fill, and stroke.
    def visit(view : UI::RoundedRectangle)
      v = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)

      # Fill color as background
      LibAndroidBridge.android_view_set_background_color(
        @env, v, color_to_argb(view.fill_color))

      # Corner radius
      if view.corner_radius > 0.0
        LibAndroidBridge.android_view_set_corner_radius(
          @env, v, view.corner_radius.to_f32)
        LibAndroidBridge.android_view_set_clip_to_outline(@env, v, 1)
      end

      # Optional stroke
      if view.stroke_width > 0.0
        stroke_color = view.stroke_color || UI::Color.new(r: 0.0, g: 0.0, b: 0.0)
        LibAndroidBridge.android_view_set_stroke(
          @env, v, view.stroke_width.to_f32, color_to_argb(stroke_color))
      end

      apply_common_properties(v, view)
      emit(v, "View[rounded-rectangle]")
    end

    # Capsule: android.view.View with corner radius = height/2 for pill shape,
    # fill color, and optional stroke.
    def visit(view : UI::Capsule)
      v = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)

      # Fill color as background
      LibAndroidBridge.android_view_set_background_color(
        @env, v, color_to_argb(view.fill_color))

      # Pill shape: corner radius = half height
      radius = (view.height / 2.0).to_f32
      LibAndroidBridge.android_view_set_corner_radius(@env, v, radius)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, v, 1)

      # Optional stroke
      if view.stroke_width > 0.0
        stroke_color = view.stroke_color || UI::Color.new(r: 0.0, g: 0.0, b: 0.0)
        LibAndroidBridge.android_view_set_stroke(
          @env, v, view.stroke_width.to_f32, color_to_argb(stroke_color))
      end

      apply_common_properties(v, view)
      emit(v, "View[capsule]")
    end

    # Canvas: android.view.View sized to width/height.
    # Custom drawing requires a subclass (SurfaceView or custom View) in full
    # Android integration; here we establish the sized placeholder.
    def visit(view : UI::Canvas)
      v = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)

      # Set content description with operation count for accessibility / testing
      unless view.operations.empty?
        desc = "canvas:#{view.operations.size}ops"
        LibAndroidBridge.android_view_set_content_description(
          @env, v, desc.to_unsafe, desc.bytesize)
      end

      apply_common_properties(v, view)
      emit(v, "View[canvas]")
    end

    # PathView: android.view.View sized to width/height.
    # SVG path data stored as content description for downstream processing.
    def visit(view : UI::PathView)
      v = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)

      # Encode SVG path data in content description for accessibility / testing
      unless view.segments.empty?
        svg = view.to_svg_path
        LibAndroidBridge.android_view_set_content_description(
          @env, v, svg.to_unsafe, svg.bytesize)
      end

      # Stroke color as background approximation for outline visibility
      if view.stroke_width > 0.0
        LibAndroidBridge.android_view_set_stroke(
          @env, v, view.stroke_width.to_f32, color_to_argb(view.stroke_color))
      end

      apply_common_properties(v, view)
      emit(v, "View[path]")
    end


    # MapView: Android-native study composition using real View primitives.
    def visit(view : UI::MapView)
      container = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, container, 1)
      LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
      LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, container, 1)
      LibAndroidBridge.android_view_set_elevation(@env, container, 4.0_f32)
      LibAndroidBridge.android_view_set_padding(@env, container, 16, 16, 16, 16)

      desc = "map:#{view.map_type}:annotations=#{view.annotations.size}:user=#{view.shows_user_location}"
      LibAndroidBridge.android_view_set_content_description(
        @env, container, desc.to_unsafe, desc.bytesize)

      title = new_text_view("Map preview", 18.0_f32, material_color(:on_surface), 1)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, title, -1, -2)

      subtitle_text = "#{view.map_type.to_s.capitalize} map  #{view.annotations.size} pins  #{view.shows_user_location ? "user on" : "user off"}"
      subtitle = new_text_view(subtitle_text, 13.0_f32, material_color(:on_surface_variant), 0)
      LibAndroidBridge.android_view_set_padding(@env, subtitle, 0, 8, 0, 12)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, subtitle, -1, -2)

      canvas = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, canvas, 1)
      LibAndroidBridge.android_view_set_background_color(@env, canvas, material_color(:surface_variant))
      LibAndroidBridge.android_view_set_corner_radius(@env, canvas, 24.0_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, canvas, 1)
      LibAndroidBridge.android_view_set_padding(@env, canvas, 16, 16, 16, 16)

      route = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
      LibAndroidBridge.android_view_set_background_color(@env, route, material_color(:primary))
      LibAndroidBridge.android_view_set_corner_radius(@env, route, 4.0_f32)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, canvas, route, -1, 8)

      block_strip = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
      LibAndroidBridge.android_view_set_background_color(@env, block_strip, material_color(:outline_variant))
      LibAndroidBridge.android_view_set_corner_radius(@env, block_strip, 4.0_f32)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, canvas, block_strip, -1, 8)

      meta = new_text_view(
        view.annotations.empty? ? "Annotations: none" : "Annotations: #{view.annotations.size}",
        13.0_f32,
        material_color(:on_surface_variant),
        0
      )
      LibAndroidBridge.android_view_set_padding(@env, meta, 0, 12, 0, 0)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, canvas, meta, -1, -2)

      if view.shows_user_location
        user = new_text_view("User location enabled", 12.0_f32, material_color(:primary), 1)
        LibAndroidBridge.android_view_set_padding(@env, user, 0, 8, 0, 0)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, canvas, user, -1, -2)
      end

      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, canvas, -1, 220)

      apply_common_properties(container, view)
      emit(container, "LinearLayout[map]")
    end

    # ChartView: Android-native chart study built from View primitives.
    def visit(view : UI::ChartView)
      container = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, container, 1)
      LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
      LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, container, 1)
      LibAndroidBridge.android_view_set_elevation(@env, container, 4.0_f32)
      LibAndroidBridge.android_view_set_padding(@env, container, 16, 16, 16, 16)

      chart_title = view.title.empty? ? "chart" : view.title
      desc = "chart:#{view.chart_type}:#{chart_title}:#{view.data_points.size}pts"
      LibAndroidBridge.android_view_set_content_description(
        @env, container, desc.to_unsafe, desc.bytesize)

      title = new_text_view(chart_title, 18.0_f32, material_color(:on_surface), 1)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, title, -1, -2)

      subtitle = new_text_view(
        "#{view.chart_type.to_s.capitalize} chart  #{view.data_points.size} points",
        13.0_f32,
        material_color(:on_surface_variant),
        0
      )
      LibAndroidBridge.android_view_set_padding(@env, subtitle, 0, 8, 0, 12)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, subtitle, -1, -2)

      plot = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, plot, 0)
      LibAndroidBridge.android_linearlayout_set_gravity(@env, plot, 80)
      LibAndroidBridge.android_view_set_background_color(@env, plot, material_color(:surface_variant))
      LibAndroidBridge.android_view_set_corner_radius(@env, plot, 24.0_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, plot, 1)
      LibAndroidBridge.android_view_set_padding(@env, plot, 12, 18, 12, 16)

      if view.data_points.empty?
        empty_label = new_text_view("No series data", 14.0_f32, material_color(:on_surface_variant), 0)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, plot, empty_label, -2, -2)
      elsif view.chart_type == :line
        max_value = view.data_points.map(&.value).max
        max_value = 1.0 if max_value <= 0.0
        view.data_points.each do |point|
          column = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
          LibAndroidBridge.android_linearlayout_set_orientation(@env, column, 1)
          LibAndroidBridge.android_linearlayout_set_gravity(@env, column, 1)

          normalized = (point.value / max_value).clamp(0.0, 1.0)
          stem_height = (normalized * 96.0).round.to_i
          spacer = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, spacer, 32, 100 - stem_height)

          dot = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
          dot_color = if c = point.color
                        color_to_argb(c)
                      else
                        material_color(:primary)
                      end
          LibAndroidBridge.android_view_set_background_color(@env, dot, dot_color)
          LibAndroidBridge.android_view_set_corner_radius(@env, dot, 6.0_f32)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, dot, 12, 12)

          if stem_height > 12
            stem = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
            LibAndroidBridge.android_view_set_background_color(@env, stem, dot_color)
            LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, stem, 2, stem_height - 12)
          end

          label = new_text_view(point.label, 11.0_f32, material_color(:on_surface_variant), 0)
          LibAndroidBridge.android_view_set_padding(@env, label, 0, 8, 0, 0)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, label, 48, -2)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, plot, column, 56, -2)
        end
      else
        max_value = view.data_points.map(&.value).max
        max_value = 1.0 if max_value <= 0.0
        view.data_points.each do |point|
          column = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
          LibAndroidBridge.android_linearlayout_set_orientation(@env, column, 1)
          LibAndroidBridge.android_linearlayout_set_gravity(@env, column, 1)

          normalized = (point.value / max_value).clamp(0.0, 1.0)
          bar_height = [(normalized * 116.0).round.to_i, 8].max
          spacer = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, spacer, 32, 124 - bar_height)

          bar = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
          bar_color = if c = point.color
                        color_to_argb(c)
                      else
                        material_color(:primary)
                      end
          LibAndroidBridge.android_view_set_background_color(@env, bar, bar_color)
          LibAndroidBridge.android_view_set_corner_radius(@env, bar, 6.0_f32)
          LibAndroidBridge.android_view_set_clip_to_outline(@env, bar, 1)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, bar, 28, bar_height)

          label = new_text_view(point.label, 11.0_f32, material_color(:on_surface_variant), 0)
          LibAndroidBridge.android_view_set_padding(@env, label, 0, 8, 0, 0)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, column, label, 48, -2)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, plot, column, 56, -2)
        end
      end

      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, plot, -1, 180)

      if view.show_legend && !view.data_points.empty?
        legend = new_text_view("Legend: #{view.data_points.map(&.label).join(", ")}", 12.0_f32, material_color(:on_surface_variant), 0)
        LibAndroidBridge.android_view_set_padding(@env, legend, 0, 12, 0, 0)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, legend, -1, -2)
      end

      apply_common_properties(container, view)
      emit(container, "LinearLayout[chart]")
    end

    # WebViewComponent: native WebView mounted inside a Material study frame.
    def visit(view : UI::WebViewComponent)
      container = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, container, 1)
      LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
      LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, container, 1)
      LibAndroidBridge.android_view_set_elevation(@env, container, 4.0_f32)
      LibAndroidBridge.android_view_set_padding(@env, container, 16, 16, 16, 16)

      heading_text = view.title || (view.url.empty? ? "Embedded web content" : "Web preview")
      heading = new_text_view(heading_text, 18.0_f32, material_color(:on_surface), 1)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, heading, -1, -2)

      source_text = if !view.url.empty?
                      view.url
                    elsif view.html
                      "Inline HTML document"
                    else
                      "Waiting for host-side content load"
                    end
      source = new_text_view(source_text, 12.0_f32, material_color(:on_surface_variant), 0)
      LibAndroidBridge.android_view_set_padding(@env, source, 0, 8, 0, 12)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, source, -1, -2)

      web = LibAndroidBridge.android_view_new(@env, "android/webkit/WebView", @context)
      LibAndroidBridge.android_view_set_background_color(@env, web, material_color(:surface_variant))
      LibAndroidBridge.android_view_set_corner_radius(@env, web, 18.0_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, web, 1)
      LibAndroidBridge.android_view_set_content_description(
        @env, web, source_text.to_unsafe, source_text.bytesize)
      if html = view.html
        base_url = view.base_url || "https://asset-pipeline.local/android-material"
        LibAndroidBridge.android_webview_load_html(
          @env,
          web,
          html.to_unsafe,
          html.bytesize,
          base_url.to_unsafe,
          base_url.bytesize
        )
      elsif !view.url.empty?
        LibAndroidBridge.android_webview_load_url(@env, web, view.url.to_unsafe, view.url.bytesize)
      end
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, web, -1, 260)

      apply_common_properties(container, view)
      emit(container, "LinearLayout[webview]")
    end

    # ColorPicker: inline swatch palette with selected-color preview.
    def visit(view : UI::ColorPicker)
      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
      content = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, content, 1)
      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_medium.to_f32)
      LibAndroidBridge.android_material_card_set_elevation(@env, card, 4.0_f32)
      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
      LibAndroidBridge.android_view_set_padding(@env, content, 16, 16, 16, 16)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, card, content, -1, -2)

      title_text = view.label.empty? ? "Color selection" : view.label
      title = new_text_view(title_text, 18.0_f32, material_color(:on_surface), 1)
      subtitle = new_text_view("Selected: #{hex_color(view.selected_color)}", 13.0_f32, material_color(:on_surface_variant), 0)
      LibAndroidBridge.android_view_set_padding(@env, title, 0, 0, 0, 4)
      LibAndroidBridge.android_view_set_padding(@env, subtitle, 0, 0, 0, 14)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, title, -1, -2)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, subtitle, -1, -2)

      preview_row = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, preview_row, 0)
      LibAndroidBridge.android_linearlayout_set_gravity(@env, preview_row, 16)
      LibAndroidBridge.android_view_set_padding(@env, preview_row, 0, 0, 0, 16)
      preview_swatch = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
      LibAndroidBridge.android_view_set_background_color(@env, preview_swatch, color_to_argb(view.selected_color))
      LibAndroidBridge.android_view_set_corner_radius(@env, preview_swatch, 16.0_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, preview_swatch, 1)
      LibAndroidBridge.android_view_set_stroke(@env, preview_swatch, 1.5_f32, material_color(:outline))
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, preview_row, preview_swatch, 32, 32)
      preview_note = new_text_view(view.supports_alpha ? "Alpha-aware selection enabled" : "Solid color selection", 12.0_f32, material_color(:on_surface_variant), 0)
      LibAndroidBridge.android_view_set_padding(@env, preview_note, 12, 0, 0, 0)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, preview_row, preview_note, -2, -2)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, preview_row, -1, -2)

      palette = [
        {label: "Violet", color: UI::Color.new(r: 0.40, g: 0.31, b: 0.89)},
        {label: "Blue", color: UI::Color.new(r: 0.12, g: 0.47, b: 0.95)},
        {label: "Mint", color: UI::Color.new(r: 0.13, g: 0.69, b: 0.58)},
        {label: "Lime", color: UI::Color.new(r: 0.47, g: 0.74, b: 0.19)},
        {label: "Amber", color: UI::Color.new(r: 0.96, g: 0.69, b: 0.12)},
        {label: "Coral", color: UI::Color.new(r: 0.92, g: 0.39, b: 0.29)},
        {label: "Rose", color: UI::Color.new(r: 0.83, g: 0.28, b: 0.53)},
        {label: "Slate", color: UI::Color.new(r: 0.36, g: 0.39, b: 0.45)},
      ]

      global_card = LibAndroidBridge.android_new_global_ref(@env, card)
      handle = JNI.wrap_global(global_card, label: "MaterialCardView[color-picker]")
      native = NativeView.new(handle)
      selected_argb = color_to_argb(view.selected_color)
      color_change_handler = view.on_change

      palette.each_slice(4) do |slice|
        row = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
        LibAndroidBridge.android_linearlayout_set_orientation(@env, row, 0)
        LibAndroidBridge.android_view_set_padding(@env, row, 0, 0, 0, 12)
        slice.each do |entry|
          item = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
          LibAndroidBridge.android_linearlayout_set_orientation(@env, item, 1)
          LibAndroidBridge.android_linearlayout_set_gravity(@env, item, 1)
          LibAndroidBridge.android_view_set_padding(@env, item, 6, 0, 6, 0)

          swatch = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
          swatch_color = entry[:color]
          swatch_argb = color_to_argb(swatch_color)
          LibAndroidBridge.android_view_set_background_color(@env, swatch, swatch_argb)
          LibAndroidBridge.android_view_set_corner_radius(@env, swatch, 20.0_f32)
          LibAndroidBridge.android_view_set_clip_to_outline(@env, swatch, 1)
          if swatch_argb == selected_argb
            LibAndroidBridge.android_view_set_stroke(@env, swatch, 3.0_f32, material_color(:primary))
          else
            LibAndroidBridge.android_view_set_stroke(@env, swatch, 1.0_f32, material_color(:outline_variant))
          end
          description = swatch_argb == selected_argb ? "#{entry[:label]} selected" : entry[:label]
          LibAndroidBridge.android_view_set_content_description(@env, swatch, description.to_unsafe, description.bytesize)
          if captured_change_handler = color_change_handler
            callback_id = native.register_callback(Proc(Nil).new { captured_change_handler.call(swatch_color) })
            LibAndroidBridge.android_view_set_on_click_listener(@env, swatch, callback_id)
          end
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, item, swatch, 40, 40)

          label = new_text_view(entry[:label], 11.0_f32, material_color(:on_surface_variant), 0)
          LibAndroidBridge.android_view_set_padding(@env, label, 0, 8, 0, 0)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, item, label, -2, -2)
          LibAndroidBridge.android_linearlayout_add_view_weight(@env, row, item, 0, -2, 1.0_f32)
        end
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, row, -1, -2)
      end

      apply_common_properties(card, view)
      push_native(native, card)
    end

    # VideoPlayer: native VideoView mounted in a Material media surface.
    def visit(view : UI::VideoPlayer)
      container = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, container, 1)
      LibAndroidBridge.android_view_set_background_color(@env, container, material_color(:surface))
      LibAndroidBridge.android_view_set_corner_radius(@env, container, @material_theme.corner_radius_medium.to_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, container, 1)
      LibAndroidBridge.android_view_set_elevation(@env, container, 4.0_f32)
      LibAndroidBridge.android_view_set_padding(@env, container, 16, 16, 16, 16)

      heading = new_text_view("Video preview", 18.0_f32, material_color(:on_surface), 1)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, heading, -1, -2)

      details = new_text_view(
        view.url.empty? ? "No source assigned" : view.url,
        12.0_f32,
        material_color(:on_surface_variant),
        0
      )
      LibAndroidBridge.android_view_set_padding(@env, details, 0, 8, 0, 12)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, details, -1, -2)

      video = LibAndroidBridge.android_view_new(@env, "android/widget/VideoView", @context)
      LibAndroidBridge.android_view_set_background_color(@env, video, material_color(:inverse_surface))
      LibAndroidBridge.android_view_set_corner_radius(@env, video, 20.0_f32)
      LibAndroidBridge.android_view_set_clip_to_outline(@env, video, 1)
      unless view.url.empty?
        LibAndroidBridge.android_view_set_content_description(@env, video, view.url.to_unsafe, view.url.bytesize)
      end
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, video, -1, 220)

      control_row = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, control_row, 0)
      LibAndroidBridge.android_view_set_padding(@env, control_row, 0, 12, 0, 0)
      play_label = new_text_view(view.is_playing ? "Playing" : "Paused", 12.0_f32, material_color(:primary), 1)
      sound_label = new_text_view(view.muted ? "Muted" : "Audio on", 12.0_f32, material_color(:on_surface_variant), 0)
      controls_label = new_text_view(view.shows_controls ? "Controls visible" : "Controls hidden", 12.0_f32, material_color(:on_surface_variant), 0)
      LibAndroidBridge.android_view_set_padding(@env, play_label, 0, 0, 16, 0)
      LibAndroidBridge.android_view_set_padding(@env, sound_label, 0, 0, 16, 0)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, control_row, play_label, -2, -2)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, control_row, sound_label, -2, -2)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, control_row, controls_label, -2, -2)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, container, control_row, -1, -2)

      apply_common_properties(container, view)
      emit(container, "LinearLayout[video]")
    end

    # Tooltip: FrameLayout wrapping optional content with tooltip text stored
    # as content description (Android uses Tooltip API 26+ via setTooltipText).
    def visit(view : UI::Tooltip)
      # Use a FrameLayout so optional child content can be added
      container = LibAndroidBridge.android_view_new(
        @env, "android/widget/FrameLayout", @context)

      # Store tooltip text as content description
      unless view.text.empty?
        LibAndroidBridge.android_view_set_content_description(
          @env, container, view.text.to_unsafe, view.text.bytesize)
      end

      apply_common_properties(container, view)

      global_ptr = LibAndroidBridge.android_new_global_ref(@env, container)
      handle = JNI.wrap_global(global_ptr, label: "FrameLayout[tooltip]")
      native = NativeView.new(handle)

      if content = view.content
        push_stack(native, container, is_linear: false)
        content.accept(self)
        pop_stack
      end

      push_native(native, container)
    end

    # -----------------------------------------------------------------
    # Visit: ActivityView -> inline share-sheet preview plus chooser dispatch
    # -----------------------------------------------------------------
    def visit(view : UI::ActivityView)
      share_text = view.share_text || ""
      share_url = view.share_url || ""
      share_subject = view.share_subject || view.title
      has_share_payload = !share_text.empty? || !share_url.empty?

      if view.is_presented && has_share_payload
        LibAndroidBridge.android_context_start_share_chooser(
          @env,
          @context,
          view.title.to_unsafe,
          view.title.bytesize,
          share_text.to_unsafe,
          share_text.bytesize,
          share_url.to_unsafe,
          share_url.bytesize,
          share_subject.to_unsafe,
          share_subject.bytesize
        )
      end

      card = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
      content = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, content, 1)
      LibAndroidBridge.android_material_card_set_background_color(@env, card, material_color(:surface))
      LibAndroidBridge.android_material_card_set_radius(@env, card, @material_theme.corner_radius_large.to_f32)
      LibAndroidBridge.android_material_card_set_elevation(@env, card, 10.0_f32)
      LibAndroidBridge.android_material_card_set_stroke_color(@env, card, material_color(:outline_variant))
      LibAndroidBridge.android_material_card_set_stroke_width(@env, card, 1)
      LibAndroidBridge.android_view_set_padding(@env, content, 18, 18, 18, 18)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, card, content, -1, -2)

      global_card = LibAndroidBridge.android_new_global_ref(@env, card)
      handle = JNI.wrap_global(global_card, label: "MaterialCardView[activity-view]")
      native = NativeView.new(handle)

      header = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, header, 0)
      LibAndroidBridge.android_linearlayout_set_gravity(@env, header, 16)
      LibAndroidBridge.android_view_set_padding(@env, header, 0, 0, 0, 16)

      if thumbnail = view.thumbnail
        thumb = LibAndroidBridge.android_view_new(@env, "android/widget/FrameLayout", @context)
        LibAndroidBridge.android_view_set_background_color(@env, thumb, material_color(:secondary_container))
        LibAndroidBridge.android_view_set_corner_radius(@env, thumb, 16.0_f32)
        LibAndroidBridge.android_view_set_clip_to_outline(@env, thumb, 1)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, header, thumb, 56, 56)
        push_stack(native, thumb, is_linear: false)
        thumbnail.accept(self)
        pop_stack
      else
        avatar = LibAndroidBridge.android_view_new(@env, "android/view/View", @context)
        LibAndroidBridge.android_view_set_background_color(@env, avatar, material_color(:secondary_container))
        LibAndroidBridge.android_view_set_corner_radius(@env, avatar, 16.0_f32)
        LibAndroidBridge.android_view_set_clip_to_outline(@env, avatar, 1)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, header, avatar, 56, 56)
      end

      header_text = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, header_text, 1)
      LibAndroidBridge.android_view_set_padding(@env, header_text, 14, 0, 0, 0)
      title = new_text_view(view.title, 18.0_f32, material_color(:on_surface), 1)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, header_text, title, -1, -2)
      if subtitle = view.subtitle
        subtitle_view = new_text_view(subtitle, 13.0_f32, material_color(:on_surface_variant), 0)
        LibAndroidBridge.android_view_set_padding(@env, subtitle_view, 0, 4, 0, 0)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, header_text, subtitle_view, -1, -2)
      end
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, header, header_text, -1, -2)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, header, -1, -2)

      status = if view.is_presented && has_share_payload
                 "System Android chooser dispatched during presentation."
               elsif has_share_payload
                 "Share payload is ready for the Android chooser."
               else
                 "Previewing inline destinations and actions."
               end
      status_view = new_text_view(status, 12.0_f32, material_color(:on_surface_variant), 0)
      LibAndroidBridge.android_view_set_padding(@env, status_view, 0, 0, 0, 16)
      LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, status_view, -1, -2)

      unless view.destinations.empty?
        destinations_heading = new_text_view("Share targets", 13.0_f32, material_color(:on_surface_variant), 1)
        LibAndroidBridge.android_view_set_padding(@env, destinations_heading, 0, 0, 0, 10)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, destinations_heading, -1, -2)

        destination_row = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
        LibAndroidBridge.android_linearlayout_set_orientation(@env, destination_row, 0)
        LibAndroidBridge.android_view_set_padding(@env, destination_row, 0, 0, 0, 16)
        view.destinations.each do |destination|
          item = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
          inner = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
          LibAndroidBridge.android_linearlayout_set_orientation(@env, inner, 1)
          LibAndroidBridge.android_linearlayout_set_gravity(@env, inner, 1)
          LibAndroidBridge.android_material_card_set_background_color(@env, item, material_color(:secondary_container))
          LibAndroidBridge.android_material_card_set_radius(@env, item, 20.0_f32)
          LibAndroidBridge.android_material_card_set_elevation(@env, item, 0.0_f32)
          LibAndroidBridge.android_view_set_padding(@env, inner, 12, 12, 12, 12)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, item, inner, -1, -2)

          glyph_source = destination.label.empty? ? destination.icon_symbol : destination.label
          glyph = glyph_source.empty? ? "•" : glyph_source[0].upcase.to_s
          icon = new_text_view(glyph, 18.0_f32, material_color(:on_secondary_container), 1)
          label = new_text_view(destination.label, 11.0_f32, material_color(:on_secondary_container), 0)
          LibAndroidBridge.android_view_set_padding(@env, label, 0, 8, 0, 0)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, inner, icon, -2, -2)
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, inner, label, -2, -2)
          if callback = destination.on_select
            callback_id = native.register_callback(callback)
            LibAndroidBridge.android_view_set_on_click_listener(@env, item, callback_id)
          end
          LibAndroidBridge.android_linearlayout_add_view_weight(@env, destination_row, item, 0, -2, 1.0_f32)
        end
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, destination_row, -1, -2)
      end

      unless view.actions.empty?
        actions_heading = new_text_view("Quick actions", 13.0_f32, material_color(:on_surface_variant), 1)
        LibAndroidBridge.android_view_set_padding(@env, actions_heading, 0, 0, 0, 10)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, actions_heading, -1, -2)

        view.actions.each_slice(2) do |slice|
          row = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
          LibAndroidBridge.android_linearlayout_set_orientation(@env, row, 0)
          LibAndroidBridge.android_view_set_padding(@env, row, 0, 0, 0, 10)
          slice.each do |action|
            tile = LibAndroidBridge.android_view_new(@env, "com/google/android/material/card/MaterialCardView", @context)
            inner = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
            LibAndroidBridge.android_linearlayout_set_orientation(@env, inner, 1)
            LibAndroidBridge.android_material_card_set_background_color(@env, tile, material_color(:surface_variant))
            LibAndroidBridge.android_material_card_set_radius(@env, tile, @material_theme.corner_radius_medium.to_f32)
            LibAndroidBridge.android_material_card_set_elevation(@env, tile, 0.0_f32)
            LibAndroidBridge.android_material_card_set_stroke_color(@env, tile, material_color(:outline_variant))
            LibAndroidBridge.android_material_card_set_stroke_width(@env, tile, 1)
            LibAndroidBridge.android_view_set_padding(@env, inner, 14, 14, 14, 14)
            LibAndroidBridge.android_viewgroup_add_view_wh(@env, tile, inner, -1, -2)

            action_color = action.role == :destructive ? material_color(:error) : material_color(:on_surface)
            glyph_source = action.label.empty? ? action.icon_symbol : action.label
            glyph = glyph_source.empty? ? "•" : glyph_source[0].upcase.to_s
            icon = new_text_view(glyph, 17.0_f32, action_color, 1)
            label = new_text_view(action.label, 12.0_f32, action_color, 1)
            LibAndroidBridge.android_view_set_padding(@env, label, 0, 8, 0, 0)
            LibAndroidBridge.android_viewgroup_add_view_wh(@env, inner, icon, -2, -2)
            LibAndroidBridge.android_viewgroup_add_view_wh(@env, inner, label, -1, -2)
            if callback = action.on_select
              callback_id = native.register_callback(callback)
              LibAndroidBridge.android_view_set_on_click_listener(@env, tile, callback_id)
            end
            LibAndroidBridge.android_linearlayout_add_view_weight(@env, row, tile, 0, -2, 1.0_f32)
          end
          LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, row, -1, -2)
        end
      end

      if cancel_handler = view.on_cancel
        footer = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
        LibAndroidBridge.android_linearlayout_set_orientation(@env, footer, 0)
        LibAndroidBridge.android_view_set_padding(@env, footer, 0, 12, 0, 0)
        spacer = LibAndroidBridge.android_view_new(@env, "android/widget/Space", @context)
        LibAndroidBridge.android_linearlayout_add_view_weight(@env, footer, spacer, 0, -2, 1.0_f32)
        LibAndroidBridge.android_viewgroup_add_view_wh(@env, content, footer, -1, -2)
        push_stack(native, footer, is_linear: true)
        cancel_button = UI::Button.new("Cancel", role: :cancel, style: UI::ButtonStyle::Borderless)
        cancel_button.on_tap = cancel_handler
        cancel_button.accept(self)
        pop_stack
      end

      apply_common_properties(card, view)
      push_native(native, card)
    end

    # -----------------------------------------------------------------
    # Visit: DisclosureGroup -> LinearLayout (vertical) containing:
    #   (1) header row LinearLayout with chevron TextView + title TextView
    #   (2) optional content LinearLayout when expanded = true
    #
    # Android has no native disclosure-triangle widget. The closest is
    # an ExpandableListView; for validation purposes a LinearLayout with
    # a right/down arrow Unicode glyph is sufficient. In production,
    # wire the header row OnClickListener to toggle visibility of the
    # content LinearLayout.
    # -----------------------------------------------------------------
    def visit(view : UI::DisclosureGroup)
      outer = LibAndroidBridge.android_view_new(
        @env, "android/widget/LinearLayout", @context)
      # VERTICAL orientation = 1
      LibAndroidBridge.android_linearlayout_set_orientation(@env, outer, 1)

      # Header row LinearLayout (horizontal = 0)
      header_row = LibAndroidBridge.android_view_new(
        @env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, header_row, 0)

      # Chevron glyph TextView
      chevron_tv = LibAndroidBridge.android_view_new(
        @env, "android/widget/TextView", @context)
      chevron_char = view.expanded ? "\u25BC" : "\u25B6"
      LibAndroidBridge.android_textview_set_text(@env, chevron_tv, chevron_char.to_unsafe, chevron_char.bytesize)

      # Title TextView
      title_tv = LibAndroidBridge.android_view_new(
        @env, "android/widget/TextView", @context)
      LibAndroidBridge.android_textview_set_text(@env, title_tv, view.title.to_unsafe, view.title.bytesize)

      # Accessibility: content description on header row
      acc_text = view.accessibility_label || "#{view.title}, #{view.expanded ? "expanded" : "collapsed"}"
      LibAndroidBridge.android_view_set_content_description(@env, header_row, acc_text.to_unsafe, acc_text.bytesize)

      LibAndroidBridge.android_viewgroup_add_view(@env, header_row, chevron_tv)
      LibAndroidBridge.android_viewgroup_add_view(@env, header_row, title_tv)
      LibAndroidBridge.android_viewgroup_add_view(@env, outer, header_row)

      # Content block (visible when expanded)
      if view.expanded && !view.content.empty?
        content_ll = LibAndroidBridge.android_view_new(
          @env, "android/widget/LinearLayout", @context)
        LibAndroidBridge.android_linearlayout_set_orientation(@env, content_ll, 1)

        global_content = LibAndroidBridge.android_new_global_ref(@env, content_ll)
        content_handle = JNI.wrap_global(global_content, label: "LinearLayout[disclosure-content]")
        content_native = NativeView.new(content_handle)

        push_stack(content_native, content_ll, is_linear: true)
        view.content.each do |child|
          child.accept(self)
        end
        pop_stack

        LibAndroidBridge.android_viewgroup_add_view(@env, outer, content_ll)
      end

      apply_common_properties(outer, view)
      global_ptr = LibAndroidBridge.android_new_global_ref(@env, outer)
      handle = JNI.wrap_global(global_ptr, label: "LinearLayout[disclosure-group]")
      native = NativeView.new(handle)
      push_native(native, outer)
    end

    # Phase 4 — Tier 3. UI::ActionSheet is iOS-only via flag?(:ios) in
    # src/ui/views/action_sheet.cr, so there is no Android visitor — the
    # class itself does not exist on -Dandroid. Android applications use
    # UI::ActionSheetWithWebFallback (below), which synthesizes a
    # ConfirmationDialog and routes through the existing visitor.

    def visit(view : UI::PathControlWithWebFallback)
      # Android has no native NSPathControl analog; render a horizontal
      # LinearLayout of TextViews — the same shape the old PathControl
      # visitor produced before Phase 4 gating moved the class to macOS.
      ll = LibAndroidBridge.android_view_new(@env, "android/widget/LinearLayout", @context)
      LibAndroidBridge.android_linearlayout_set_orientation(@env, ll, 0)
      apply_common_properties(ll, view)

      global_ll = LibAndroidBridge.android_new_global_ref(@env, ll)
      handle = JNI.wrap_global(global_ll, label: "LinearLayout[path-control-fallback]")
      native = NativeView.new(handle)

      view.components.each_with_index do |component, index|
        tv = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)
        LibAndroidBridge.android_textview_set_text(@env, tv, component.name.to_unsafe, component.name.bytesize)
        LibAndroidBridge.android_textview_set_text_color(@env, tv, 0xFF111111_u32.to_i32)
        tv_global = LibAndroidBridge.android_new_global_ref(@env, tv)
        tv_handle = JNI.wrap_global(tv_global, label: "TextView[path-control-segment]")
        tv_native = NativeView.new(tv_handle)
        native.add_child(tv_native)
        LibAndroidBridge.android_viewgroup_add_view(@env, ll, tv)

        next if index == view.components.size - 1
        sep = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)
        glyph = "/"
        LibAndroidBridge.android_textview_set_text(@env, sep, glyph.to_unsafe, glyph.bytesize)
        LibAndroidBridge.android_textview_set_text_color(@env, sep, 0xFF8E8E93_u32.to_i32)
        sep_global = LibAndroidBridge.android_new_global_ref(@env, sep)
        sep_handle = JNI.wrap_global(sep_global, label: "TextView[path-control-sep]")
        sep_native = NativeView.new(sep_handle)
        native.add_child(sep_native)
        LibAndroidBridge.android_viewgroup_add_view(@env, ll, sep)
      end

      push_native(native, ll)
    end

    # Phase 6.10 — SwipeActionRow stub. Android proper integration is
    # deferred per the brief (Android cross-build remains
    # architect-precedent PASS); render the content view only.
    def visit(view : UI::SwipeActionRow)
      view.content.accept(self)
    end

    def visit(view : UI::ActionSheetWithWebFallback)
      # Android has a BottomSheetDialog widget but Phase 4 keeps fidelity
      # high by synthesizing a UI::ConfirmationDialog (confirm + cancel)
      # and routing through the existing visitor; Material 3 styling is
      # already wired there. Multi-action BottomSheet is a Phase 5 follow.
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

    # Pack a UI::Color (RGBA 0..1) into an Android ARGB packed int.
    # Android Color format: 0xAARRGGBB
    private def color_to_argb(color : UI::Color) : Int32
      a = (color.a * 255.0).round.to_i.clamp(0, 255)
      r = (color.r * 255.0).round.to_i.clamp(0, 255)
      g = (color.g * 255.0).round.to_i.clamp(0, 255)
      b = (color.b * 255.0).round.to_i.clamp(0, 255)
      ((a << 24) | (r << 16) | (g << 8) | b).to_i32
    end

    private def theme_color_to_argb(color : UI::ThemeColor) : Int32
      # Phase 6.12A — fail loud when a sentinel-derived ThemeColor reaches
      # the Android ARGB packer. The `css_override` field carries the
      # platform-resolved CSS token (e.g. "AccentColor") for sentinel
      # colours; the honest Android emission is `?attr/colorPrimary`, not
      # a numeric ARGB. The deferred Android XML / resource generator
      # must learn the resource-reference path before this raises in
      # production. Until then, the Android renderer is intentionally
      # incompatible with `Tokens.default` — consumers must apply
      # `Tokens.default.with_brand(...)` to materialise a concrete brand.
      if color.css_override
        raise UI::DesignTokens::AndroidRendererNotImplemented.new(
          "Cannot serialize a sentinel-derived ThemeColor (css_override=" \
          "#{color.css_override.inspect}) as Android ARGB. Apply " \
          "Tokens.default.with_brand(YourBrand.new) to materialise the " \
          "brand colour, or update the Android renderer to emit a " \
          "`?attr/colorPrimary` resource reference for sentinel roles."
        )
      end
      a = (color.a * 255.0).round.to_i.clamp(0, 255)
      r = (color.r * 255.0).round.to_i.clamp(0, 255)
      g = (color.g * 255.0).round.to_i.clamp(0, 255)
      b = (color.b * 255.0).round.to_i.clamp(0, 255)
      ((a << 24) | (r << 16) | (g << 8) | b).to_i32
    end

    private def hex_color(color : UI::Color) : String
      r = (color.r * 255.0).round.to_i.clamp(0, 255)
      g = (color.g * 255.0).round.to_i.clamp(0, 255)
      b = (color.b * 255.0).round.to_i.clamp(0, 255)
      if color.a < 1.0
        a = (color.a * 255.0).round.to_i.clamp(0, 255)
        "#%02X%02X%02X%02X" % {a, r, g, b}
      else
        "#%02X%02X%02X" % {r, g, b}
      end
    end

    private def material_color(role : Symbol) : Int32
      theme = @material_theme
      color = case role
              when :primary              then theme.primary
              when :on_primary           then theme.on_primary
              when :primary_container    then theme.primary_container
              when :on_primary_container then theme.on_primary_container
              when :secondary            then theme.secondary
              when :on_secondary         then theme.on_secondary
              when :secondary_container  then theme.secondary_container
              when :on_secondary_container then theme.on_secondary_container
              when :error                then theme.error
              when :on_error             then theme.on_error
              when :error_container      then theme.error_container
              when :on_error_container   then theme.on_error_container
              when :background           then theme.background
              when :on_background        then theme.on_background
              when :surface              then theme.surface
              when :on_surface           then theme.on_surface
              when :surface_variant      then theme.surface_variant
              when :on_surface_variant   then theme.on_surface_variant
              when :outline              then theme.outline
              when :outline_variant      then theme.outline_variant
              when :inverse_surface      then theme.inverse_surface
              when :inverse_on_surface   then theme.inverse_on_surface
              else
                theme.surface
              end
      theme_color_to_argb(color)
    end

    private def zero_padding?(insets : UI::EdgeInsets) : Bool
      insets.top == 0.0 &&
        insets.trailing == 0.0 &&
        insets.bottom == 0.0 &&
        insets.leading == 0.0
    end

    private def new_text_view(text : String,
                              size_sp : Float32 = 14.0_f32,
                              color : Int32 = material_color(:on_surface),
                              typeface_style : Int32 = 0) : Void*
      tv = LibAndroidBridge.android_view_new(@env, "android/widget/TextView", @context)
      LibAndroidBridge.android_textview_set_text(@env, tv, text.to_unsafe, text.bytesize)
      LibAndroidBridge.android_textview_set_text_size(@env, tv, size_sp)
      LibAndroidBridge.android_textview_set_text_color(@env, tv, color)
      LibAndroidBridge.android_textview_set_typeface(@env, tv, typeface_style)
      tv
    end

    private def new_material_view(class_name : String, style_field_name : String) : Void*
      LibAndroidBridge.android_view_new_themed(
        @env,
        class_name.to_unsafe,
        @context,
        style_field_name.to_unsafe
      )
    end

    # Map a UI::Font to an Android Typeface style integer.
    # Typeface.NORMAL=0, Typeface.BOLD=1, Typeface.ITALIC=2, Typeface.BOLD_ITALIC=3
    private def typeface_style_for(font : UI::Font) : Int32
      is_bold = (font.weight == :bold || font.weight == :semibold)
      is_italic = font.italic
      case {is_bold, is_italic}
      when {true, true}   then 3 # BOLD_ITALIC
      when {true, false}  then 1 # BOLD
      when {false, true}  then 2 # ITALIC
      else                     0 # NORMAL
      end
    end

    private def apply_common_non_surface_properties(v : Void*, view : UI::View) : Nil
      # Hidden: GONE removes from layout, INVISIBLE keeps space
      if view.hidden
        LibAndroidBridge.android_view_set_visibility(@env, v, 8) # GONE
      end

      # Opacity
      if view.opacity < 1.0
        LibAndroidBridge.android_view_set_alpha(@env, v, view.opacity.to_f32)
      end

      # Shadow: Android uses elevation for drop shadows (API 21+).
      # shadow_radius maps to elevation in DP (approximation).
      if view.shadow_radius > 0.0
        LibAndroidBridge.android_view_set_elevation(@env, v, view.shadow_radius.to_f32)
      end

      # Padding (convert from Float64 to Int32 dp -> px is handled in the C bridge)
      p = view.padding
      if p.top != 0.0 || p.trailing != 0.0 || p.bottom != 0.0 || p.leading != 0.0
        LibAndroidBridge.android_view_set_padding(
          @env, v,
          p.leading.round.to_i,  # left
          p.top.round.to_i,
          p.trailing.round.to_i, # right
          p.bottom.round.to_i)
      end

      # Accessibility label -> contentDescription
      if a11y = view.accessibility_label
        LibAndroidBridge.android_view_set_content_description(
          @env, v, a11y.to_unsafe, a11y.bytesize)
      end

      # Test identifier -> contentDescription (used as test tag on Android)
      # Only set if accessibility_label was not already set, to avoid overwriting it
      if tid = view.test_id
        unless view.accessibility_label
          LibAndroidBridge.android_view_set_content_description(
          @env, v, tid.to_unsafe, tid.bytesize)
        end
      end
    end

    # Apply common View base-class properties to an Android View local ref.
    #
    #   - hidden       -> setVisibility(GONE=8) or VISIBLE(0)
    #   - opacity      -> setAlpha(float)
    #   - background   -> setBackgroundColor(argb)
    #   - corner_radius -> setCornerRadius(dp) via outline provider
    #   - clip_to_bounds -> setClipToOutline(true)
    #   - shadow        -> setElevation(dp) -- Android uses elevation for shadow
    #   - border        -> setStroke(width, argb) via GradientDrawable
    #   - padding       -> setPadding(l, t, r, b) in pixels
    #   - accessibility -> setContentDescription
    private def apply_common_properties(v : Void*, view : UI::View) : Nil
      apply_common_non_surface_properties(v, view)

      # Background color
      if bg = view.background
        LibAndroidBridge.android_view_set_background_color(@env, v, color_to_argb(bg))
      end

      # Corner radius (requires setClipToOutline)
      if view.corner_radius > 0.0
        LibAndroidBridge.android_view_set_corner_radius(@env, v, view.corner_radius.to_f32)
        LibAndroidBridge.android_view_set_clip_to_outline(@env, v, 1)
      elsif view.clip_to_bounds
        LibAndroidBridge.android_view_set_clip_to_outline(@env, v, 1)
      end

      # Border via GradientDrawable stroke
      if view.border_width > 0.0
        bc = view.border_color || UI::Color.new(r: 0.0, g: 0.0, b: 0.0)
        LibAndroidBridge.android_view_set_stroke(@env, v, view.border_width.to_f32, color_to_argb(bc))
      end
    end

    # Current local ref for the stack top (the raw JNI pointer for addView calls).
    # We need this because NativeHandle stores the global ref, but addView needs
    # the local ref during construction.
    @stack_local_ptrs : Array(Void*)

    def initialize(@env : Void*, @context : Void*)
      @stack = [] of NativeView
      @stack_is_linear = [] of Bool
      @stack_local_ptrs = [] of Void*
      @material_theme = UI::Theme.material_baseline
    end

    # Push a container NativeView onto the nesting stack, with its local ptr.
    private def push_stack(native : NativeView, local_ptr : Void*, is_linear : Bool) : Nil
      @stack.push(native)
      @stack_is_linear.push(is_linear)
      @stack_local_ptrs.push(local_ptr)
    end

    # Pop the top container from the nesting stack.
    private def pop_stack : Nil
      @stack.pop
      @stack_is_linear.pop
      @stack_local_ptrs.pop
    end

    # Wrap a local ref in a global NativeHandle + NativeView and emit it.
    # Standard path for leaf views (Label, Image) with no callbacks.
    private def emit(local_ptr : Void*, label : String) : Nil
      global_ptr = LibAndroidBridge.android_new_global_ref(@env, local_ptr)
      handle = JNI.wrap_global(global_ptr, label: label)
      native = NativeView.new(handle)
      push_native(native, local_ptr)
    end

    # Emit a Spacer with flex weight in a LinearLayout parent.
    # The Space widget gets weight=1 so it expands to fill available space.
    private def emit_spacer(local_ptr : Void*, min_length : Float64) : Nil
      global_ptr = LibAndroidBridge.android_new_global_ref(@env, local_ptr)
      handle = JNI.wrap_global(global_ptr, label: "Space[spacer]")
      native = NativeView.new(handle)

      if parent = @stack.last?
        parent.add_child(native)
        if parent.handle.valid?
          parent_local = @stack_local_ptrs.last?
          unless parent_local.nil? || parent_local.null?
            # Use weight=1 so the Space expands in a LinearLayout
            # WRAP_CONTENT = -2, MATCH_PARENT = -1
            min_px = min_length.round.to_i
            LibAndroidBridge.android_linearlayout_add_view_weight(
              @env, parent_local, local_ptr,
              min_px > 0 ? min_px : -2, # width: min or WRAP_CONTENT
              min_px > 0 ? min_px : -2, # height: min or WRAP_CONTENT
              1.0_f32)                   # weight: 1 (flex expand)
          end
        end
      else
        @result = native
      end
    end

    # Register a NativeView with the current parent container, or set it
    # as the root result if there is no parent.
    #
    # `local_ptr` is the JNI local ref for the view being registered.
    # It is needed for the addView call; the NativeView itself holds the global ref.
    private def push_native(native : NativeView, local_ptr : Void*) : Nil
      if parent = @stack.last?
        parent.add_child(native)

        parent_local = @stack_local_ptrs.last?
        unless parent_local.nil? || parent_local.null?
          if @stack_is_linear.last?
            # LinearLayout: WRAP_CONTENT for both dimensions by default
            LibAndroidBridge.android_viewgroup_add_view(@env, parent_local, local_ptr)
          else
            # FrameLayout (ZStack) or ScrollView: MATCH_PARENT to fill parent
            LibAndroidBridge.android_viewgroup_add_view_wh(
              @env, parent_local, local_ptr, -1, -1) # MATCH_PARENT
          end
        end
      else
        @result = native
      end
    end
  end
end
{% end %}
