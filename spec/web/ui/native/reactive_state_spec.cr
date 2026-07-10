require "spec"
require "../../../../src/ui"

# Phase 3 Remediation 4 — Crystal-side coverage for the reactive bridge
# surface that does NOT depend on the SwiftKit dylib being linked.
#
# The mutators on UI::Label / UI::Button / UI::Toggle / UI::Slider must:
#   1. Always update the Crystal property unconditionally.
#   2. Skip the SwiftKit `apsk_*_set_*` dispatch when `swiftkit_state_handle`
#      is nil (i.e. the renderer hasn't emitted a hosting view yet, OR the
#      view was rendered through a non-SwiftKit renderer like Web).
#
# These specs run under plain `crystal spec` (no -Dmacos / -Dios) so the
# macro-conditional bodies that dispatch through LibSwiftKitBridge are
# entirely absent from the binary. We only verify the property-assignment
# half of the contract here; the bridge-dispatch half is covered by the
# Swift XCTest suite (ReactiveStateTests.swift).

describe "UI::View#swiftkit_state_handle" do
  it "defaults to nil on every View subclass" do
    UI::Label.new("hi").swiftkit_state_handle.should be_nil
    UI::Button.new("hi").swiftkit_state_handle.should be_nil
    UI::Toggle.new("hi").swiftkit_state_handle.should be_nil
    UI::Slider.new(0.0, 1.0, 0.5).swiftkit_state_handle.should be_nil
  end

  it "can be set to an opaque pointer" do
    label = UI::Label.new("hi")
    sentinel = Pointer(Void).new(0xBADCAFE_u64)
    label.swiftkit_state_handle = sentinel
    label.swiftkit_state_handle.should eq(sentinel)
  end
end

describe "UI::Label#text= reactive mutator" do
  it "updates the property even when state_handle is nil" do
    label = UI::Label.new("initial")
    label.text = "updated"
    label.text.should eq("updated")
  end

  it "does not raise when state_handle is nil (no bridge dispatch on spec build)" do
    label = UI::Label.new("hi")
    label.swiftkit_state_handle.should be_nil
    # Must be a no-op on the bridge side; only the Crystal property updates.
    label.text = "next"
    label.text.should eq("next")
  end
end

describe "UI::Button reactive mutators" do
  it "background= updates the property and tolerates nil state_handle" do
    button = UI::Button.new("Save")
    color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
    button.background = color
    button.background.should eq(color)

    button.background = nil
    button.background.should be_nil
  end

  it "foreground_color= updates the property" do
    button = UI::Button.new("Save")
    color = UI::Color.new(r: 0.0, g: 1.0, b: 0.0)
    button.foreground_color = color
    button.foreground_color.should eq(color)
  end

  it "corner_radius= updates the property" do
    button = UI::Button.new("Save")
    button.corner_radius = 12.0
    button.corner_radius.should eq(12.0)
    button.corner_radius = 0.0
    button.corner_radius.should eq(0.0)
  end
end

describe "UI::Toggle#is_on= reactive mutator" do
  it "updates the property and tolerates nil state_handle" do
    toggle = UI::Toggle.new("Notify", false)
    toggle.is_on.should be_false
    toggle.is_on = true
    toggle.is_on.should be_true
  end
end

describe "UI::Slider#value= reactive mutator" do
  it "updates the property and tolerates nil state_handle" do
    slider = UI::Slider.new(0.0, 1.0, 0.0)
    slider.value.should eq(0.0)
    slider.value = 0.5
    slider.value.should eq(0.5)
  end
end
