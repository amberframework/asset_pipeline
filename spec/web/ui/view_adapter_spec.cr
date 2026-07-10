require "spec"
require "../../../src/ui"
require "../../../src/ui/view_adapter"

describe UI::ViewAdapter do
  describe "inheritance" do
    it "inherits from Components::StatefulComponent" do
      adapter = UI::ViewAdapter.new { UI::Label.new("test").as(UI::View) }
      adapter.is_a?(Components::StatefulComponent).should be_true
    end

    it "inherits from Components::Component" do
      adapter = UI::ViewAdapter.new { UI::Label.new("test").as(UI::View) }
      adapter.is_a?(Components::Component).should be_true
    end

    it "has a component_id" do
      adapter = UI::ViewAdapter.new { UI::Label.new("test").as(UI::View) }
      adapter.component_id.should_not be_empty
    end
  end

  describe "rendering a simple Label" do
    it "produces HTML containing a <span> with the label text" do
      adapter = UI::ViewAdapter.new do
        UI::Label.new("Hello ViewAdapter").as(UI::View)
      end

      html = adapter.render
      html.should contain("<span")
      html.should contain("Hello ViewAdapter")
      html.should contain("</span>")
    end
  end

  describe "rendering a complex tree" do
    it "renders a VStack with multiple children to HTML" do
      adapter = UI::ViewAdapter.new do
        stack = UI::VStack.new(spacing: 12.0)
        stack << UI::Label.new("Title")
        stack << UI::Button.new("Action")
        stack << UI::Label.new("Footer")
        stack.as(UI::View)
      end

      html = adapter.render
      html.should contain("flex-direction: column")
      html.should contain("gap: 12.0px")
      html.should contain("Title")
      html.should contain("Action")
      html.should contain("Footer")
      html.should contain("<span")
      html.should contain("<button")
    end

    it "renders nested VStack and HStack" do
      adapter = UI::ViewAdapter.new do
        root = UI::VStack.new
        row = UI::HStack.new(spacing: 8.0)
        row << UI::Label.new("Left")
        row << UI::Spacer.new
        row << UI::Label.new("Right")
        root << row
        root << UI::Button.new("Submit")
        root.as(UI::View)
      end

      html = adapter.render
      html.should contain("flex-direction: column")
      html.should contain("flex-direction: row")
      html.should contain("Left")
      html.should contain("Right")
      html.should contain("Submit")
      html.should contain("flex: 1 1 0%") # Spacer
    end
  end

  describe "re-rendering with fresh view from builder" do
    it "calls the builder block each time render is called" do
      call_count = 0

      adapter = UI::ViewAdapter.new do
        call_count += 1
        UI::Label.new("Render ##{call_count}").as(UI::View)
      end

      html1 = adapter.render
      html1.should contain("Render #1")

      html2 = adapter.render
      html2.should contain("Render #2")

      call_count.should eq(2)
    end
  end

  describe "state-driven output changes" do
    it "produces different HTML when external state changes between renders" do
      counter = UI::State(Int32).new(0)

      adapter = UI::ViewAdapter.new do
        UI::Label.new("Count: #{counter.value}").as(UI::View)
      end

      html1 = adapter.render
      html1.should contain("Count: 0")

      counter.value = 42

      html2 = adapter.render
      html2.should contain("Count: 42")
    end

    it "reflects boolean state changes in view structure" do
      show_detail = UI::State(Bool).new(false)

      adapter = UI::ViewAdapter.new do
        stack = UI::VStack.new
        stack << UI::Label.new("Header")
        if show_detail.value
          stack << UI::Label.new("Detail content")
        end
        stack.as(UI::View)
      end

      html1 = adapter.render
      html1.should contain("Header")
      html1.should_not contain("Detail content")

      show_detail.value = true

      html2 = adapter.render
      html2.should contain("Header")
      html2.should contain("Detail content")
    end

    it "reflects string state changes in label text" do
      name = UI::State(String).new("World")

      adapter = UI::ViewAdapter.new do
        UI::Label.new("Hello, #{name.value}!").as(UI::View)
      end

      html1 = adapter.render
      html1.should contain("Hello, World!")

      name.value = "Crystal"

      html2 = adapter.render
      html2.should contain("Hello, Crystal!")
    end
  end

  describe "#invalidate!" do
    it "marks the component as changed and returns fresh HTML" do
      counter = UI::State(Int32).new(0)

      adapter = UI::ViewAdapter.new do
        UI::Label.new("Value: #{counter.value}").as(UI::View)
      end

      adapter.changed?.should be_false

      counter.value = 5
      html = adapter.invalidate!

      adapter.changed?.should be_true
      html.should contain("Value: 5")
    end
  end

  describe "#render_content" do
    it "returns the HTML string directly (without wrapper div)" do
      adapter = UI::ViewAdapter.new do
        UI::Label.new("Direct").as(UI::View)
      end

      content = adapter.render_content
      content.should contain("Direct")
      content.should contain("<span")
    end
  end
end
