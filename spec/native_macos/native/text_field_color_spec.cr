require "spec"
require "../../../src/ui"

{% if flag?(:macos) %}
  # Proves `UI::TextField#text_color`, `#placeholder_color`, and
  # `UI::SecureField#text_color` reach the pixels the AppKit renderer draws.
  # Each field is drawn offscreen into an sRGB bitmap in light and dark
  # appearance; the glyph-core pixel (the pixel farthest from the field's
  # background, so antialiased edges never count) must match the requested
  # color within 2 per channel.
  lib TextFieldColorSpecBridge
    fun ap_spec_color_window_new(view : Void*, width : Float64, height : Float64, dark : Int32) : Void*
    fun ap_spec_color_capture_field(window : Void*, out_rgba : UInt8*, capacity : Int64, out_size : Int32*) : Int32
    fun ap_spec_color_edit_field(window : Void*, text : UInt8*) : Int32
    fun ap_spec_color_application_is_active : Int32
    fun ap_spec_color_window_close(window : Void*) : Void
  end

  private CAPTURE_CAPACITY  = 4_i64 * 2048 * 2048
  private CHANNEL_TOLERANCE = 2
  # Pixels this close to the field's edge belong to the bezel, not the text.
  private BEZEL_INSET_PIXELS = 6

  private TEXT_COLOR        = UI::Color.new(r: 0x23 / 255.0, g: 0x29 / 255.0, b: 0x3A / 255.0)
  private PLACEHOLDER_COLOR = UI::Color.new(r: 0x7A / 255.0, g: 0x2E / 255.0, b: 0x1F / 255.0)
  private LARGE_BOLD_FONT   = UI::Font.new(size: 34.0, weight: :bold)

  # One opaque sRGB pixel, 0-255 per channel.
  private record SrgbPixel, red : Int32, green : Int32, blue : Int32 do
    def self.from(color : UI::Color) : SrgbPixel
      new((color.r * 255).round.to_i, (color.g * 255).round.to_i, (color.b * 255).round.to_i)
    end

    def distance_to(other : SrgbPixel) : Int32
      (red - other.red).abs + (green - other.green).abs + (blue - other.blue).abs
    end

    def largest_channel_difference(other : SrgbPixel) : Int32
      {(red - other.red).abs, (green - other.green).abs, (blue - other.blue).abs}.max
    end

    def to_s(io : IO) : Nil
      io << '#'
      {red, green, blue}.each { |channel| io << channel.to_s(16).rjust(2, '0').upcase }
    end
  end

  # What one capture measured: the field's dominant background color and the
  # glyph-core color that sits farthest from it.
  private record GlyphMeasurement, background : SrgbPixel, glyph_core : SrgbPixel

  private def measure_glyph_core(pixels : Bytes, width : Int32, height : Int32) : GlyphMeasurement
    list_of_interior_pixels = [] of SrgbPixel
    (BEZEL_INSET_PIXELS...(height - BEZEL_INSET_PIXELS)).each do |row|
      (BEZEL_INSET_PIXELS...(width - BEZEL_INSET_PIXELS)).each do |column|
        offset = (row * width + column) * 4
        next if pixels[offset + 3] < 250
        list_of_interior_pixels << SrgbPixel.new(pixels[offset].to_i, pixels[offset + 1].to_i, pixels[offset + 2].to_i)
      end
    end
    raise "The captured field has no opaque interior pixels (#{width}x#{height})" if list_of_interior_pixels.empty?

    background = list_of_interior_pixels.tally.max_by { |_, count| count }[0]
    glyph_core = list_of_interior_pixels.max_by(&.distance_to(background))
    GlyphMeasurement.new(background, glyph_core)
  end

  # Renders `view` offscreen and measures its first editable field. With
  # `typed_text`, the field is put into editing and the text is inserted
  # through its field editor first, so the capture shows the live editor.
  private def capture_glyph_core(view : UI::View, *, dark : Bool, typed_text : String? = nil) : GlyphMeasurement
    native = UI::AppKit::Renderer.new.render(view)
    window = TextFieldColorSpecBridge.ap_spec_color_window_new(native.handle.ptr!, 520.0, 200.0, dark ? 1 : 0)
    begin
      if typed_text
        edited = TextFieldColorSpecBridge.ap_spec_color_edit_field(window, typed_text)
        raise "The field editor did not accept typed text" if edited == 0
      end
      pixels = Bytes.new(CAPTURE_CAPACITY)
      size = StaticArray(Int32, 2).new(0)
      captured = TextFieldColorSpecBridge.ap_spec_color_capture_field(window, pixels.to_unsafe, CAPTURE_CAPACITY, size.to_unsafe)
      raise "The rendered tree has no editable AppKit text field to capture" if captured == 0
      measure_glyph_core(pixels, size[0], size[1])
    ensure
      TextFieldColorSpecBridge.ap_spec_color_window_close(window)
      native.teardown!
    end
  end

  # Measures the field in light and then dark appearance and fails with both
  # readings, so a failure always records the numbers for each appearance.
  private def assert_glyph_color_in_both_appearances(expected : UI::Color, & : -> UI::View) : Nil
    expected_pixel = SrgbPixel.from(expected)
    list_of_readings = [false, true].map do |dark|
      measurement = capture_glyph_core(yield, dark: dark)
      difference = measurement.glyph_core.largest_channel_difference(expected_pixel)
      {dark ? "dark" : "light", measurement, difference}
    end
    report = list_of_readings.join("; ") do |appearance, measurement, difference|
      "#{appearance}: glyph core #{measurement.glyph_core} on background #{measurement.background}, " \
      "largest channel difference #{difference}"
    end
    all_within_tolerance = list_of_readings.all? { |_, _, difference| difference <= CHANNEL_TOLERANCE }
    all_within_tolerance.should be_true, "expected #{expected_pixel}: #{report}"
  end

  private def colored_text_field : UI::TextField
    field = UI::TextField.new(placeholder: "Project", text: "Cedar")
    field.font = LARGE_BOLD_FONT
    field.text_color = TEXT_COLOR
    field
  end

  private def labeled_form_row(content : UI::View) : UI::Form
    form = UI::Form.new
    section = form.add_section("Details")
    section.fields << UI::Form::Field.new(label: "Project", content: content)
    form
  end

  describe "TextField text color on macOS" do
    it "draws the value in text_color in light and dark appearance" do
      assert_glyph_color_in_both_appearances(TEXT_COLOR) { colored_text_field }
    end

    it "draws the value in text_color inside a labeled Form row" do
      assert_glyph_color_in_both_appearances(TEXT_COLOR) { labeled_form_row(colored_text_field) }
    end

    it "draws the placeholder in placeholder_color" do
      field = UI::TextField.new(placeholder: "Project")
      field.font = LARGE_BOLD_FONT
      field.placeholder_color = PLACEHOLDER_COLOR
      assert_glyph_color_in_both_appearances(PLACEHOLDER_COLOR) { field }
    end

    it "keeps text_color while the user types into the field" do
      list_of_changes = [] of String
      field = UI::TextField.new(placeholder: "Project") { |value| list_of_changes << value }
      field.font = LARGE_BOLD_FONT
      field.text_color = TEXT_COLOR
      expected_pixel = SrgbPixel.from(TEXT_COLOR)
      [false, true].each do |dark|
        measurement = capture_glyph_core(field, dark: dark, typed_text: "Cedar")
        difference = measurement.glyph_core.largest_channel_difference(expected_pixel)
        (difference <= CHANNEL_TOLERANCE).should be_true,
          "#{dark ? "dark" : "light"} while editing: glyph core #{measurement.glyph_core} on " \
          "#{measurement.background}, expected #{expected_pixel}"
      end
      list_of_changes.last?.should eq("Cedar")
    end

    it "keeps the appearance-tracking label color when text_color is never set" do
      field = UI::TextField.new(placeholder: "Project", text: "Cedar")
      field.font = LARGE_BOLD_FONT
      measurement = capture_glyph_core(field, dark: true)
      core = measurement.glyph_core
      ({core.red, core.green, core.blue}.min >= 180).should be_true,
        "dark: an unset text_color should draw light text, got #{core} on #{measurement.background}"
    end

    it "never activates the app while capturing" do
      capture_glyph_core(colored_text_field, dark: false)
      TextFieldColorSpecBridge.ap_spec_color_application_is_active.should eq(0)
    end
  end

  describe "SecureField text color on macOS" do
    it "draws the masked value in text_color in light and dark appearance" do
      field = UI::SecureField.new(placeholder: "Password", text: "hunter2")
      field.font = LARGE_BOLD_FONT
      field.text_color = TEXT_COLOR
      assert_glyph_color_in_both_appearances(TEXT_COLOR) { field }
    end

    it "draws the placeholder in placeholder_color" do
      field = UI::SecureField.new(placeholder: "Password")
      field.font = LARGE_BOLD_FONT
      field.placeholder_color = PLACEHOLDER_COLOR
      assert_glyph_color_in_both_appearances(PLACEHOLDER_COLOR) { field }
    end

    it "draws the masked value in text_color inside a labeled Form row" do
      field = UI::SecureField.new(placeholder: "Password", text: "hunter2")
      field.font = LARGE_BOLD_FONT
      field.text_color = TEXT_COLOR
      assert_glyph_color_in_both_appearances(TEXT_COLOR) { labeled_form_row(field) }
    end
  end
{% end %}
