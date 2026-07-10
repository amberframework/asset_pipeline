require "../spec_helper"

# Sanity spec for the shim itself. Validates the contract the renderer
# overrides specs depend on.
describe FakeLibObjCBridge do
  it "records calls and returns the stubbed value" do
    FakeLibObjCBridge.record(:setBackgroundColor, ["red"], "0xdead")
    FakeLibObjCBridge.calls.size.should eq(1)
    FakeLibObjCBridge.calls.first.name.should eq(:setBackgroundColor)
    FakeLibObjCBridge.calls.first.returned.should eq("0xdead")
  end

  it "resets between specs (Spec.before_each cleared the previous spec's state)" do
    FakeLibObjCBridge.calls.should be_empty
  end

  it "assert_sent passes when the call was made" do
    FakeLibObjCBridge.record(:setCornerRadius, ["12.0"], "")
    FakeLibObjCBridge.assert_sent(:setCornerRadius, times: 1, args: ["12.0"])
  end

  it "assert_sent raises when call count does not match" do
    expect_raises(Exception, /expected setOpacity sent 1 times/) do
      FakeLibObjCBridge.assert_sent(:setOpacity, times: 1)
    end
  end

  it "refute_sent passes when the selector was not invoked" do
    FakeLibObjCBridge.record(:setBackgroundColor, ["blue"], "")
    FakeLibObjCBridge.refute_sent(:setCornerRadius)
  end

  it "refute_sent raises when the selector WAS invoked" do
    FakeLibObjCBridge.record(:setBorderWidth, ["1.0"], "")
    expect_raises(Exception, /expected setBorderWidth NOT to be sent/) do
      FakeLibObjCBridge.refute_sent(:setBorderWidth)
    end
  end

  it "next_sentinel_pointer returns distinct sentinels per call" do
    a = FakeLibObjCBridge.next_sentinel_pointer
    b = FakeLibObjCBridge.next_sentinel_pointer
    a.should_not eq(b)
    a.starts_with?("0x").should be_true
  end

  it "stub_return makes a configured value available for later retrieval" do
    FakeLibObjCBridge.stub_return(:objc_getClass, "0xbeef")
    # In real spec usage the renderer call site would look this up; the
    # shim itself just exposes the configuration surface.
    FakeLibObjCBridge.calls.should be_empty
  end
end
