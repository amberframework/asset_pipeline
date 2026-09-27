require "spec"
require "../../../src/ui"

{% if flag?(:macos) %}
  lib TextFieldAlignmentSpecBridge
    fun ap_spec_text_field_window_new(width : Float64, height : Float64) : Void*
    fun ap_spec_text_field_window_attach(window : Void*, view : Void*) : Void
    fun ap_spec_find_editable_text_field(view : Void*) : Void*
    fun ap_spec_focus_text_field(window : Void*, field : Void*) : Int32
    fun ap_spec_text_field_glyph_metrics(field : Void*, metrics : Float64*) : Int32
    fun ap_spec_type_into_text_field(window : Void*, field : Void*, text : UInt8*) : Void
    fun ap_spec_text_field_editor_equals(field : Void*, text : UInt8*) : Int32
    fun ap_spec_text_field_window_close(window : Void*) : Void
  end

  private def make_alignment_form(field : UI::TextField) : UI::Form
    form = UI::Form.new
    section = form.add_section("Details")
    section.fields << UI::Form::Field.new(label: "Project", content: field)
    form
  end

  private def native_text_field(view : UI::View) : Tuple(Void*, Void*, UI::NativeView)
    renderer = UI::AppKit::Renderer.new
    native = renderer.render(view)
    window = TextFieldAlignmentSpecBridge.ap_spec_text_field_window_new(520.0, 220.0)
    TextFieldAlignmentSpecBridge.ap_spec_text_field_window_attach(window, native.handle.ptr!)
    field = TextFieldAlignmentSpecBridge.ap_spec_find_editable_text_field(native.handle.ptr!)
    raise "The rendered SwiftUI tree has no editable AppKit text field" if field.null?
    focused = TextFieldAlignmentSpecBridge.ap_spec_focus_text_field(window, field)
    raise "The rendered text field did not enter editing" if focused == 0
    {window, field, native}
  end

  private def native_field_metrics(field : Void*) : Array(Float64)
    metrics = Array(Float64).new(4, 0.0)
    has_glyphs = TextFieldAlignmentSpecBridge.ap_spec_text_field_glyph_metrics(field, metrics.to_unsafe)
    raise "The field editor did not lay out text glyphs" if has_glyphs == 0
    metrics
  end

  private def native_field_geometry(view : UI::View) : Tuple(Void*, Void*, Array(Float64), UI::NativeView)
    window, field, native = native_text_field(view)
    metrics = native_field_metrics(field)
    {window, field, metrics, native}
  end

  private def close_alignment_window(window : Void*, native : UI::NativeView) : Nil
    TextFieldAlignmentSpecBridge.ap_spec_text_field_window_close(window)
    native.teardown!
  end

  private def glyphs_match_alignment?(metrics : Array(Float64), alignment : UI::Alignment) : Bool
    field_leading = metrics[0]
    field_trailing = metrics[1]
    glyph_leading = metrics[2]
    glyph_trailing = metrics[3]
    case alignment
    when UI::Alignment::Leading
      (glyph_leading - field_leading).abs <= 6.0
    when UI::Alignment::Center
      glyph_center = (glyph_leading + glyph_trailing) / 2.0
      field_center = (field_leading + field_trailing) / 2.0
      (glyph_center - field_center).abs <= 6.0
    when UI::Alignment::Trailing
      (field_trailing - glyph_trailing).abs <= 6.0
    else
      false
    end
  end

  private def make_alignment_field(alignment : UI::Alignment) : UI::TextField
    field = UI::TextField.new(placeholder: "Project", text: "Cedar")
    field.text_alignment = alignment
    field
  end

  private def assert_rendered_alignment(view : UI::View, alignment : UI::Alignment) : Nil
    window, _, metrics, native = native_field_geometry(view)
    begin
      glyphs_match_alignment?(metrics, alignment).should be_true
    ensure
      close_alignment_window(window, native)
    end
  end

  describe "TextField alignment (AppKit field editor)" do
    it "places standalone glyphs at the leading edge" do
      assert_rendered_alignment(make_alignment_field(UI::Alignment::Leading), UI::Alignment::Leading)
    end

    it "places standalone glyphs at the center" do
      assert_rendered_alignment(make_alignment_field(UI::Alignment::Center), UI::Alignment::Center)
    end

    it "places standalone glyphs at the trailing edge" do
      assert_rendered_alignment(make_alignment_field(UI::Alignment::Trailing), UI::Alignment::Trailing)
    end

    it "places labeled Form glyphs at the leading edge of the value field" do
      field = make_alignment_field(UI::Alignment::Leading)
      assert_rendered_alignment(make_alignment_form(field), UI::Alignment::Leading)
    end

    it "places labeled Form glyphs at the center of the value field" do
      field = make_alignment_field(UI::Alignment::Center)
      assert_rendered_alignment(make_alignment_form(field), UI::Alignment::Center)
    end

    it "places labeled Form glyphs at the trailing edge of the value field" do
      field = make_alignment_field(UI::Alignment::Trailing)
      assert_rendered_alignment(make_alignment_form(field), UI::Alignment::Trailing)
    end

    it "keeps secure-entry TextField glyphs at the requested edge" do
      field = make_alignment_field(UI::Alignment::Trailing)
      field.secure_entry = true
      assert_rendered_alignment(field, UI::Alignment::Trailing)
    end

    it "keeps SecureField glyphs at the requested edge" do
      field = UI::SecureField.new(placeholder: "Password", text: "Cedar")
      field.text_alignment = UI::Alignment::Trailing
      assert_rendered_alignment(field, UI::Alignment::Trailing)
    end

    it "keeps text at the leading edge while the real field editor receives typing" do
      field = UI::TextField.new(placeholder: "Project")
      field.text_alignment = UI::Alignment::Leading
      window, field_ptr, native = native_text_field(make_alignment_form(field))
      begin
        TextFieldAlignmentSpecBridge.ap_spec_type_into_text_field(window, field_ptr, "typed".to_unsafe)
        TextFieldAlignmentSpecBridge.ap_spec_text_field_editor_equals(field_ptr, "typed".to_unsafe).should eq(1)
        glyphs_match_alignment?(native_field_metrics(field_ptr), UI::Alignment::Leading).should be_true
      ensure
        close_alignment_window(window, native)
      end
    end
  end
{% end %}
