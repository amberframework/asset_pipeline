require "../../spec_helper"

describe "UI::ActionSheet (compile-time gate)" do
  it "raises a useful compile error when used without -Dios" do
    snippet = <<-CR
      require "../../src/ui"
      sheet = UI::ActionSheet.new("Title", "Message")
    CR
    status, output = Phase04CompileCheck.run(snippet)
    status.success?.should be_false
    output.should contain("UI::ActionSheet is iOS-only")
    output.should contain("-Dios")
    output.should contain("UI::ActionSheetWithWebFallback")
    output.should contain("{% if flag?(:ios) %}")
  end

  it "compiles cleanly when built with -Dios" do
    snippet = <<-CR
      require "../../src/ui"
      sheet = UI::ActionSheet.new("Title", "Message")
    CR
    status, output = Phase04CompileCheck.run(snippet, flags: ["-Dios"])
    if !status.success?
      fail("Expected success with -Dios, got:\n#{output}")
    end
  end
end
