{% if flag?(:macos) %}
  require "spec"
  require "../../src/ui"
  require "../../src/ui/ax_test"

  lib AppKitSelectableLabelTestBridge
    fun ap_spec_create_label_window(content_view_ptr : Void*) : Void*
    fun ap_spec_label_frame(view_ptr : Void*, x : Float64*, y : Float64*, width : Float64*, height : Float64*) : Void
    fun ap_spec_label_fitting_size(view_ptr : Void*, width : Float64*, height : Float64*) : Void
    fun ap_spec_close_label_window(window_ptr : Void*) : Void
  end

  private LABEL_LAYOUT_TEXT = "A selectable label keeps the same layout."

  private def find_rendered_label(app : UI::AXTest::App) : UI::AXTest::Element
    deadline = Time.instant + 2.seconds
    loop do
      if label = app.find_by_id("label-value")
        return label
      end
      break if Time.instant >= deadline

      sleep(50.milliseconds)
    end

    raise "AXTest did not expose the rendered Label after a bounded visibility retry"
  end

  private def with_rendered_label(selectable : Bool, &block : UI::AXTest::Element, Void* ->) : Nil
    label = UI::Label.new(LABEL_LAYOUT_TEXT)
    label.selectable = selectable
    label.test_id = "label-value"
    native = UI::AppKit::Renderer.new.render(label)
    window_ptr = Pointer(Void).null

    begin
      window_ptr = AppKitSelectableLabelTestBridge.ap_spec_create_label_window(native.handle.ptr!)
      raise "AppKit test window could not be created" if window_ptr.null?

      app = UI::AXTest::App.connect(Process.pid.to_i32)
      yield find_rendered_label(app), native.handle.ptr!
    ensure
      AppKitSelectableLabelTestBridge.ap_spec_close_label_window(window_ptr) unless window_ptr.null?
      native.teardown!
    end
  end

  private def label_frame_for(selectable : Bool) : NamedTuple(x: Float64, y: Float64, width: Float64, height: Float64)
    frame : NamedTuple(x: Float64, y: Float64, width: Float64, height: Float64)? = nil
    with_rendered_label(selectable) do |_element, view_ptr|
      x = 0.0
      y = 0.0
      width = 0.0
      height = 0.0
      AppKitSelectableLabelTestBridge.ap_spec_label_frame(
        view_ptr, pointerof(x), pointerof(y), pointerof(width), pointerof(height),
      )
      frame = {x: x, y: y, width: width, height: height}
    end
    frame || raise("Label frame was not available")
  end

  private def label_fitting_size_for(selectable : Bool) : NamedTuple(width: Float64, height: Float64)
    size : NamedTuple(width: Float64, height: Float64)? = nil
    with_rendered_label(selectable) do |_element, view_ptr|
      width = 0.0
      height = 0.0
      AppKitSelectableLabelTestBridge.ap_spec_label_fitting_size(view_ptr, pointerof(width), pointerof(height))
      size = {width: width, height: height}
    end
    size || raise("Label fitting size was not available")
  end

  describe "UI::Label layout with selectable text on macOS" do
    it "keeps the same frame and fitting size when selection is enabled" do
      label_frame_for(true).should eq(label_frame_for(false))
      label_fitting_size_for(true).should eq(label_fitting_size_for(false))
    end
  end
{% end %}
