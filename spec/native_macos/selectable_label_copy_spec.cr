{% if flag?(:macos) %}
  require "spec"
  require "../../src/ui"
  require "../../src/ui/ax_test"

  # Proves a selectable Label copies its text the way a person does it:
  # triple-click the text to select it, then Edit > Copy. Selection is
  # observed through the accessibility tree (AXSelectedTextRange and
  # AXSelectedText on the Label's AXStaticText) and the outcome through the
  # general pasteboard, whose prior contents are restored afterwards.
  #
  # SwiftUI's `.textSelection(.enabled)` on macOS reports
  # AXSelectedTextRange as not settable and ignores writes to it, so the
  # selection cannot be made through AX; it is made with the pointer, as a
  # sighted user makes it, and read back through AX.
  lib AppKitSelectableLabelCopyBridge
    fun ap_spec_create_label_window(content_view_ptr : Void*) : Void*
    fun ap_spec_pump_label_run_loop : Void
    fun ap_spec_application_is_active : Int32
    fun ap_spec_window_is_key(window_ptr : Void*) : Int32
    fun ap_spec_ax_point_hits_selectable_text(window_ptr : Void*, ax_x : Float64, ax_y : Float64) : Int32
    fun ap_spec_triple_click_at_ax_point(window_ptr : Void*, ax_x : Float64, ax_y : Float64) : Int32
    fun ap_spec_copy_from_first_responder(window_ptr : Void*) : Int32
    fun ap_spec_pasteboard_snapshot : Void*
    fun ap_spec_pasteboard_restore(snapshot_ptr : Void*) : Void
    fun ap_spec_pasteboard_write_string(text : UInt8*) : Void
    fun ap_spec_pasteboard_copy_string : UInt8*
    fun ap_spec_close_label_window(window_ptr : Void*) : Void
  end

  private SELECTABLE_LABEL_TEXT     = "/tmp/asset-pipeline-selection-proof.txt"
  private NON_SELECTABLE_LABEL_TEXT = "/tmp/asset-pipeline-static-label.txt"
  private PASTEBOARD_SENTINEL       = "asset-pipeline copy proof sentinel"
  private READINESS_TIMEOUT         = 5.seconds

  private alias AXPoint = NamedTuple(x: Float64, y: Float64)

  # Everything the proof needs from one rendered window: the two Labels'
  # accessibility elements and where a pointer would press each of them.
  private record LabelCopyFixture,
    window_ptr : Void*,
    selectable_element : UI::AXTest::Element,
    selectable_point : AXPoint,
    non_selectable_element : UI::AXTest::Element,
    non_selectable_point : AXPoint

  private def find_static_text_with_value(element : UI::AXTest::Element, text : String, depth : Int32 = 0) : UI::AXTest::Element?
    return nil if depth > 16

    element.children.each do |child|
      return child if child.role == "AXStaticText" && child.value == text
      if found = find_static_text_with_value(child, text, depth + 1)
        return found
      end
    end
    nil
  end

  private def center_of(element : UI::AXTest::Element) : AXPoint?
    frame = element.frame
    return nil unless frame
    return nil if frame[:width] <= 0 || frame[:height] <= 0

    {x: frame[:x] + frame[:width] / 2, y: frame[:y] + frame[:height] / 2}
  end

  # Pumps the main run loop until both Labels are in the accessibility tree
  # with a laid-out frame and SwiftUI has installed the selectable Label's
  # text-selection view under its center. Both Labels share the window, so
  # by then the plain Label has been through the same update passes.
  private def wait_for_label_copy_fixture(window_ptr : Void*) : LabelCopyFixture
    app = UI::AXTest::App.connect(Process.pid.to_i32)
    deadline = Time.instant + READINESS_TIMEOUT
    loop do
      AppKitSelectableLabelCopyBridge.ap_spec_pump_label_run_loop
      selectable = find_static_text_with_value(app.root, SELECTABLE_LABEL_TEXT)
      non_selectable = find_static_text_with_value(app.root, NON_SELECTABLE_LABEL_TEXT)
      selectable_point = selectable ? center_of(selectable) : nil
      non_selectable_point = non_selectable ? center_of(non_selectable) : nil

      if selectable && non_selectable && selectable_point && non_selectable_point
        hits_selection_view = AppKitSelectableLabelCopyBridge.ap_spec_ax_point_hits_selectable_text(
          window_ptr, selectable_point[:x], selectable_point[:y],
        ) == 1
        if hits_selection_view
          return LabelCopyFixture.new(window_ptr, selectable, selectable_point, non_selectable, non_selectable_point)
        end
      end

      if Time.instant >= deadline
        raise "Labels were not ready within #{READINESS_TIMEOUT}: " \
              "selectable=#{!selectable.nil?} point=#{selectable_point.inspect}, " \
              "non-selectable=#{!non_selectable.nil?} point=#{non_selectable_point.inspect}"
      end
    end
  end

  private def with_label_copy_fixture(&block : LabelCopyFixture ->) : Nil
    stack = UI::VStack.new
    selectable_label = UI::Label.new(SELECTABLE_LABEL_TEXT)
    selectable_label.selectable = true
    stack << selectable_label
    stack << UI::Label.new(NON_SELECTABLE_LABEL_TEXT)

    native = UI::AppKit::Renderer.new.render(stack)
    window_ptr = Pointer(Void).null
    pasteboard_snapshot = AppKitSelectableLabelCopyBridge.ap_spec_pasteboard_snapshot
    begin
      window_ptr = AppKitSelectableLabelCopyBridge.ap_spec_create_label_window(native.handle.ptr!)
      raise "AppKit test window could not be created" if window_ptr.null?

      AppKitSelectableLabelCopyBridge.ap_spec_pasteboard_write_string(PASTEBOARD_SENTINEL)
      yield wait_for_label_copy_fixture(window_ptr)
    ensure
      AppKitSelectableLabelCopyBridge.ap_spec_pasteboard_restore(pasteboard_snapshot)
      AppKitSelectableLabelCopyBridge.ap_spec_close_label_window(window_ptr) unless window_ptr.null?
      native.teardown!
    end
  end

  private def triple_click(fixture : LabelCopyFixture, point : AXPoint) : Nil
    delivered = AppKitSelectableLabelCopyBridge.ap_spec_triple_click_at_ax_point(fixture.window_ptr, point[:x], point[:y])
    raise "No view was hit at #{point.inspect}" unless delivered == 1

    AppKitSelectableLabelCopyBridge.ap_spec_pump_label_run_loop
  end

  private def copy_selection(fixture : LabelCopyFixture) : Bool
    AppKitSelectableLabelCopyBridge.ap_spec_copy_from_first_responder(fixture.window_ptr) == 1
  end

  private def pasteboard_text : String?
    text_ptr = AppKitSelectableLabelCopyBridge.ap_spec_pasteboard_copy_string
    return nil if text_ptr.null?

    text = String.new(text_ptr)
    LibC.free(text_ptr.as(Void*))
    text
  end

  private def assert_machine_left_undisturbed(fixture : LabelCopyFixture) : Nil
    AppKitSelectableLabelCopyBridge.ap_spec_application_is_active.should eq(0)
    AppKitSelectableLabelCopyBridge.ap_spec_window_is_key(fixture.window_ptr).should eq(0)
  end

  describe "UI::Label selectable text behavior on macOS" do
    it "copies the exact Label text after a person selects it" do
      with_label_copy_fixture do |fixture|
        label = fixture.selectable_element
        label.selected_text_range.should eq({location: 0_i64, length: 0_i64})

        triple_click(fixture, fixture.selectable_point)

        label.selected_text_range.should eq({location: 0_i64, length: SELECTABLE_LABEL_TEXT.size.to_i64})
        label.selected_text.should eq(SELECTABLE_LABEL_TEXT)
        copy_selection(fixture).should be_true
        pasteboard_text.should eq(SELECTABLE_LABEL_TEXT)
        assert_machine_left_undisturbed(fixture)
      end
    end

    it "neither selects nor copies a Label that is not selectable" do
      with_label_copy_fixture do |fixture|
        label = fixture.non_selectable_element
        label.selected_text_range.should be_nil

        triple_click(fixture, fixture.non_selectable_point)

        label.selected_text_range.should be_nil
        label.selected_text.should be_nil
        copy_selection(fixture).should be_false
        pasteboard_text.should eq(PASTEBOARD_SENTINEL)
        assert_machine_left_undisturbed(fixture)
      end
    end
  end
{% end %}
