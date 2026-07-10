require "../../spec_helper"

# Phase04CompileCheck is loaded via spec/support/phase04_compile_check.cr
# (autoloaded by spec_helper).

describe "UI::PathControl (compile-time gate)" do
  it "raises a useful compile error on a non-macOS build (default)" do
    snippet = <<-CR
      require "../../src/ui"
      ctrl = UI::PathControl.new
    CR
    status, output = Phase04CompileCheck.run(snippet)
    status.success?.should be_false
    output.should contain("UI::PathControl is macOS-only")
    output.should contain("-Dmacos")
    output.should contain("UI::PathControlWithWebFallback")
    output.should contain("{% if flag?(:macos) %}")
  end

  it "raises a useful compile error on -Dios" do
    snippet = <<-CR
      require "../../src/ui"
      ctrl = UI::PathControl.new
    CR
    status, output = Phase04CompileCheck.run(snippet, flags: ["-Dios"])
    status.success?.should be_false
    output.should contain("UI::PathControl is macOS-only")
  end

  it "compiles cleanly when built with -Dmacos" do
    snippet = <<-CR
      require "../../src/ui"
      ctrl = UI::PathControl.new
    CR
    status, output = Phase04CompileCheck.run(snippet, flags: ["-Dmacos"])
    if !status.success?
      fail("Expected success with -Dmacos, got:\n#{output}")
    end
  end
end
