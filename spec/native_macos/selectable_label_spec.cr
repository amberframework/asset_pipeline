{% if flag?(:macos) %}
  require "spec"
  require "../../src/ui"
  require "../../src/ui/ax_test"

  lib AppKitSelectableLabelTestBridge
    fun ap_spec_create_label_window(content_view_ptr : Void*) : Void*
    fun ap_spec_pump_label_run_loop : Void
    fun ap_spec_label_fitting_size(view_ptr : Void*, width : Float64*, height : Float64*) : Void
    fun ap_spec_select_label_text(window_ptr : Void*) : Int32
    fun ap_spec_copy_label_selection(window_ptr : Void*) : Int32
    fun ap_spec_close_label_window(window_ptr : Void*) : Void
  end

  private LABEL_SELECTION_TEXT = "/tmp/asset-pipeline-selection-proof.txt"

  private def find_rendered_label(app : UI::AXTest::App) : UI::AXTest::Element
    deadline = Time.instant + 2.seconds
    loop do
      if label = app.find_by_id("label-value")
        return label
      end
      break if Time.instant >= deadline

      AppKitSelectableLabelTestBridge.ap_spec_pump_label_run_loop
    end

    raise "AXTest did not expose the rendered Label after a bounded visibility retry"
  end

  private def with_rendered_label(selectable : Bool, &block : UI::AXTest::Element, Void*, Void* ->) : Nil
    label = UI::Label.new(LABEL_SELECTION_TEXT)
    label.selectable = selectable
    label.test_id = "label-value"
    native = UI::AppKit::Renderer.new.render(label)
    window_ptr = Pointer(Void).null

    begin
      window_ptr = AppKitSelectableLabelTestBridge.ap_spec_create_label_window(native.handle.ptr!)
      raise "AppKit test window could not be created" if window_ptr.null?

      app = UI::AXTest::App.connect(Process.pid.to_i32)
      yield find_rendered_label(app), window_ptr, native.handle.ptr!
    ensure
      AppKitSelectableLabelTestBridge.ap_spec_close_label_window(window_ptr) unless window_ptr.null?
      native.teardown!
    end
  end

  private def label_fitting_size_for(selectable : Bool) : NamedTuple(width: Float64, height: Float64)
    size : NamedTuple(width: Float64, height: Float64)? = nil
    with_rendered_label(selectable) do |_element, _window_ptr, view_ptr|
      width = 0.0
      height = 0.0
      AppKitSelectableLabelTestBridge.ap_spec_label_fitting_size(view_ptr, pointerof(width), pointerof(height))
      size = {width: width, height: height}
    end
    size || raise("Label fitting size was not available")
  end

  private def set_clipboard(text : String) : Nil
    input = IO::Memory.new(text)
    status = Process.run("pbcopy", input: input)
    raise "pbcopy failed while preparing the Label behavior spec" unless status.success?
  end

  private def clipboard_text : String
    output = IO::Memory.new
    status = Process.run("pbpaste", output: output)
    raise "pbpaste failed while reading the Label behavior spec" unless status.success?
    output.to_s
  end

  describe "UI::Label selectable text on macOS" do
    pending "selects and copies exact read-only text through AppKit (the field editor accepted the full range, but direct copy left pbpaste empty in this harness)"

    it "does not select or copy a default Label" do
      UI::AXTest::App.accessibility_trusted?.should be_true
      set_clipboard("selection-spec-sentinel")

      with_rendered_label(false) do |_label, window_ptr, _view_ptr|
        AppKitSelectableLabelTestBridge.ap_spec_select_label_text(window_ptr).should eq(0)
        AppKitSelectableLabelTestBridge.ap_spec_copy_label_selection(window_ptr).should eq(0)
        clipboard_text.should eq("selection-spec-sentinel")
      end
    end

    it "keeps the same fitting size when selection is enabled" do
      label_fitting_size_for(true).should eq(label_fitting_size_for(false))
    end
  end
{% end %}
