require "spec"
require "../../../../src/ui"
require "../../../../src/ui/renderers/web_renderer"

private def render(view : UI::View) : String
  renderer = UI::Web::Renderer.new
  view.accept(renderer)
  renderer.output
end

# Every interactive widget should emit a 44 x 44 CSS-pixel floor on its
# tappable element. Renderer reads this from
# `design_tokens.touch_target_minimum_px` (Phase 1).
describe UI::Web::Renderer do
  describe "touch-target enforcement (WCAG 2.5.5 / Apple HIG)" do
    it "Button" do
      html = render(UI::Button.new("Save"))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "IconButton" do
      html = render(UI::IconButton.new("star"))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "TextField" do
      html = render(UI::TextField.new("Name"))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "SecureField" do
      html = render(UI::SecureField.new)
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "Toggle" do
      html = render(UI::Toggle.new("Enable"))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "Checkbox" do
      html = render(UI::Checkbox.new("Agree"))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "Slider" do
      html = render(UI::Slider.new)
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "Stepper" do
      html = render(UI::Stepper.new)
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "SegmentedControl" do
      html = render(UI::SegmentedControl.new(["A", "B", "C"]))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "DatePicker" do
      html = render(UI::DatePicker.new)
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "TimePicker" do
      html = render(UI::TimePicker.new)
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "SearchField" do
      html = render(UI::SearchField.new)
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "ColorPicker" do
      html = render(UI::ColorPicker.new)
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "TextArea" do
      html = render(UI::TextArea.new)
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "NavigationLink" do
      html = render(UI::NavigationLink.new("Settings", UI::Label.new("Detail")))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "LinkButton" do
      html = render(UI::LinkButton.new("Go", "/x"))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "MenuButton" do
      html = render(UI::MenuButton.new("Menu"))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "ToggleButton" do
      html = render(UI::ToggleButton.new("On"))
      html.should match(/min-width:\s*44(?:\.0)?px/)
      html.should match(/min-height:\s*44(?:\.0)?px/)
    end

    it "ConfirmationDialog buttons" do
      html = render(UI::ConfirmationDialog.new("Sure?"))
      html.scan(/min-width:\s*44(?:\.0)?px/).size.should be >= 2
      html.scan(/min-height:\s*44(?:\.0)?px/).size.should be >= 2
    end
  end

  describe "touch-target reads from design tokens" do
    it "default touch_target_minimum_px is 44.0" do
      # The value comes from the active tokens model rather than a literal
      # in the renderer; brand overrides therefore cascade through.
      renderer = UI::Web::Renderer.new
      renderer.design_tokens.touch_target_minimum_px.should eq(44.0)
    end
  end
end
