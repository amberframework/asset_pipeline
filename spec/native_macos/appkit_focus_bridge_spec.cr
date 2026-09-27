require "spec"
require "../../src/ui"

{% if flag?(:macos) %}
  lib AppKitFocusTestBridge
    fun ap_spec_create_focus_target : Void*
    fun ap_spec_create_focus_window : Void*
    fun ap_spec_attach_focus_target(window : Void*, target : Void*) : Void
    fun ap_spec_window_has_first_responder(window : Void*, target : Void*) : Bool
    fun ap_spec_focus_window_is_key(window : Void*) : Int32
    fun ap_spec_release_focus_objects(window : Void*, target : Void*) : Void
  end

  describe "AppKit first-responder requests" do
    it "defers until window attachment and reports the final result" do
      target = UI::ObjC.autoreleasepool do
        AppKitFocusTestBridge.ap_spec_create_focus_target
      end

      request_accepted = UI::AppKit::LibObjCBridge.ap_view_become_first_responder(target)
      raise "detached first-responder request was not accepted" unless request_accepted
      raise "focus result was available before attachment" if UI::AppKit::LibObjCBridge.ap_view_focus_request_succeeded(target)

      window = UI::ObjC.autoreleasepool do
        AppKitFocusTestBridge.ap_spec_create_focus_window
      end

      begin
        UI::ObjC.autoreleasepool do
          AppKitFocusTestBridge.ap_spec_attach_focus_target(window, target)
        end

        focus_request_succeeded = UI::AppKit::LibObjCBridge.ap_view_focus_request_succeeded(target)
        has_first_responder = UI::ObjC.autoreleasepool do
          AppKitFocusTestBridge.ap_spec_window_has_first_responder(window, target)
        end
        unless focus_request_succeeded && has_first_responder
          raise "deferred focus result=#{focus_request_succeeded}, first responder=#{has_first_responder}"
        end

        # The probe window stays offscreen and non-key, so the spec never
        # takes keyboard focus from whoever is using the machine.
        AppKitFocusTestBridge.ap_spec_focus_window_is_key(window).should eq(0)
      ensure
        UI::ObjC.autoreleasepool do
          AppKitFocusTestBridge.ap_spec_release_focus_objects(window, target)
        end
      end
    end
  end
{% end %}
