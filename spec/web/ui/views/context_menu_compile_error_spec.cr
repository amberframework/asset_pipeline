require "../../spec_helper"

# Phase04CompileCheck is loaded via spec/support/phase04_compile_check.cr
# (autoloaded by spec_helper).

describe "UI::ContextMenu (compile-time gate)" do
  it "raises a useful compile error on a non-Apple build" do
    snippet = <<-CR
      require "../../src/ui"
      menu = UI::ContextMenu.new
    CR
    status, output = Phase04CompileCheck.run(snippet)
    status.success?.should be_false
    output.should contain("UI::ContextMenu is Apple-family only")
    output.should contain("-Dmacos")
    output.should contain("-Dios")
    output.should contain("UI::ContextMenuWithWebFallback")
    output.should contain("{% if flag?(:macos) || flag?(:ios) %}")
  end

  it "compiles cleanly when built with -Dmacos" do
    snippet = <<-CR
      require "../../src/ui"
      menu = UI::ContextMenu.new
    CR
    status, output = Phase04CompileCheck.run(snippet, flags: ["-Dmacos"])
    if !status.success?
      fail("Expected success with -Dmacos, got:\n#{output}")
    end
  end

  it "compiles cleanly when built with -Dios" do
    snippet = <<-CR
      require "../../src/ui"
      menu = UI::ContextMenu.new
    CR
    status, output = Phase04CompileCheck.run(snippet, flags: ["-Dios"])
    if !status.success?
      fail("Expected success with -Dios, got:\n#{output}")
    end
  end
end
