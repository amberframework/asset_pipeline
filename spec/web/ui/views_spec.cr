require "spec"
require "../../../src/ui"

# A test visitor that records which view types were visited, in order.
class TestVisitor < UI::PlatformVisitor
  getter visited : Array(String) = [] of String

  def visit(view : UI::Label)
    @visited << "Label(#{view.text})"
  end

  def visit(view : UI::Button)
    @visited << "Button(#{view.label})"
  end

  def visit(view : UI::VStack)
    @visited << "VStack(#{view.children.size})"
    view.children.each(&.accept(self))
  end

  def visit(view : UI::HStack)
    @visited << "HStack(#{view.children.size})"
    view.children.each(&.accept(self))
  end

  def visit(view : UI::ZStack)
    @visited << "ZStack(#{view.children.size})"
    view.children.each(&.accept(self))
  end

  def visit(view : UI::Image)
    @visited << "Image(#{view.source})"
  end

  def visit(view : UI::TextField)
    @visited << "TextField(#{view.placeholder})"
  end

  def visit(view : UI::ScrollView)
    @visited << "ScrollView"
    view.content.try(&.accept(self))
  end

  def visit(view : UI::Spacer)
    @visited << "Spacer(#{view.min_length})"
  end

  def visit(view : UI::Toggle)
    @visited << "Toggle(#{view.label})"
  end

  def visit(view : UI::Checkbox)
    @visited << "Checkbox(#{view.label})"
  end

  def visit(view : UI::RadioGroup)
    @visited << "RadioGroup(#{view.options.size})"
  end

  def visit(view : UI::Slider)
    @visited << "Slider(#{view.value})"
  end

  def visit(view : UI::NavigationStack)
    @visited << "NavigationStack(#{view.title || "untitled"})"
    view.current_view.accept(self)
  end

  def visit(view : UI::NavigationLink)
    @visited << "NavigationLink(#{view.label})"
  end

  def visit(view : UI::TabView)
    @visited << "TabView(#{view.tabs.size})"
  end

  def visit(view : UI::ProgressView)
    @visited << "ProgressView(#{view.style})"
  end

  def visit(view : UI::ActivityIndicator)
    @visited << "ActivityIndicator(#{view.is_animating})"
  end

  def visit(view : UI::Alert)
    @visited << "Alert(#{view.title})"
  end

  def visit(view : UI::Picker)
    @visited << "Picker(#{view.options.size})"
  end

  def visit(view : UI::IconButton)
    @visited << "IconButton(#{view.icon})"
  end

  def visit(view : UI::ListView)
    @visited << "ListView(#{view.item_count})"
  end

  def visit(view : UI::OutlineView)
    @visited << "OutlineView(#{view.node_count})"
  end

  def visit(view : UI::ColumnView)
    @visited << "ColumnView(#{view.column_count})"
  end

  def visit(view : UI::TokenField)
    @visited << "TokenField(#{view.token_count})"
  end

  def visit(view : UI::ImageWell)
    @visited << "ImageWell(#{view.has_image?})"
  end

  def visit(view : UI::Panel)
    @visited << "Panel(#{view.title}/#{view.action_count})"
  end

  def visit(view : UI::Gauge)
    @visited << "Gauge(#{view.value})"
  end

  def visit(view : UI::ActivityRing)
    @visited << "ActivityRing(#{view.value})"
  end

  def visit(view : UI::ActivityRings)
    @visited << "ActivityRings(#{view.move}/#{view.exercise}/#{view.stand})"
  end

  def visit(view : UI::SecureField)
    @visited << "SecureField(#{view.placeholder})"
  end

  def visit(view : UI::Stepper)
    @visited << "Stepper(#{view.value})"
  end

  def visit(view : UI::SegmentedControl)
    @visited << "SegmentedControl(#{view.segments.size})"
  end

  def visit(view : UI::DatePicker)
    @visited << "DatePicker(#{view.mode})"
  end

  def visit(view : UI::TimePicker)
    @visited << "TimePicker(#{view.shows_24_hour})"
  end

  def visit(view : UI::SearchField)
    @visited << "SearchField(#{view.placeholder})"
  end

  def visit(view : UI::TextArea)
    @visited << "TextArea(#{view.placeholder})"
  end

  def visit(view : UI::Grid)
    @visited << "Grid(#{view.row_count}x#{view.column_count})"
  end

  def visit(view : UI::Form)
    @visited << "Form(#{view.field_count})"
  end

  # Milestone F (Wave 2) visitor methods
  def visit(view : UI::NavigationSplitView)
    @visited << "NavigationSplitView(#{view.column_visibility})"
  end

  def visit(view : UI::Toolbar)
    @visited << "Toolbar(#{view.items.size})"
  end

  def visit(view : UI::Sheet)
    @visited << "Sheet(#{view.is_presented})"
  end

  def visit(view : UI::Popover)
    @visited << "Popover(#{view.arrow_edge})"
  end

  def visit(view : UI::ConfirmationDialog)
    @visited << "ConfirmationDialog(#{view.title})"
  end

  def visit(view : UI::Snackbar)
    @visited << "Snackbar(#{view.message})"
  end

  def visit(view : UI::Card)
    @visited << "Card(#{view.elevation})"
  end

  def visit(view : UI::Surface)
    @visited << "Surface(#{view.shape})"
  end

  def visit(view : UI::Divider)
    @visited << "Divider(#{view.orientation})"
  end

  def visit(view : UI::GlassBackground)
    @visited << "GlassBackground(#{view.material})"
  end

  # P2 Wave 3
  def visit(view : UI::AsyncImage)
    @visited << "AsyncImage(#{view.url})"
  end

  def visit(view : UI::RichText)
    @visited << "RichText(#{view.spans.size})"
  end

  def visit(view : UI::LinkButton)
    @visited << "LinkButton(#{view.label})"
  end

  def visit(view : UI::MenuButton)
    @visited << "MenuButton(#{view.label})"
  end

  {% if flag?(:macos) || flag?(:ios) %}
    def visit(view : UI::ContextMenu)
      @visited << "ContextMenu(#{view.items.size})"
    end
  {% end %}

  def visit(view : UI::ContextMenuWithWebFallback)
    @visited << "ContextMenuWithWebFallback(#{view.items.size})"
  end

  def visit(view : UI::ToggleButton)
    @visited << "ToggleButton(#{view.label})"
  end

  def visit(view : UI::TextEditor)
    @visited << "TextEditor(#{view.placeholder})"
  end

  # P3 Stubs
  def visit(view : UI::Circle)
    @visited << "Circle"
  end

  def visit(view : UI::Rectangle)
    @visited << "Rectangle"
  end

  def visit(view : UI::RoundedRectangle)
    @visited << "RoundedRectangle"
  end

  def visit(view : UI::Capsule)
    @visited << "Capsule"
  end

  def visit(view : UI::Canvas)
    @visited << "Canvas"
  end

  def visit(view : UI::PathView)
    @visited << "PathView"
  end

  {% if flag?(:macos) %}
    def visit(view : UI::PathControl)
      @visited << "PathControl(#{view.path_string})"
    end
  {% end %}

  def visit(view : UI::PathControlWithWebFallback)
    @visited << "PathControlWithWebFallback(#{view.path_string})"
  end

  def visit(view : UI::MapView)
    @visited << "MapView"
  end

  def visit(view : UI::ChartView)
    @visited << "ChartView"
  end

  def visit(view : UI::WebViewComponent)
    @visited << "WebViewComponent"
  end

  def visit(view : UI::ColorPicker)
    @visited << "ColorPicker"
  end

  def visit(view : UI::VideoPlayer)
    @visited << "VideoPlayer"
  end

  def visit(view : UI::Tooltip)
    @visited << "Tooltip"
  end

  def visit(view : UI::ActivityView)
    @visited << "ActivityView"
  end

  def visit(view : UI::DisclosureGroup)
    @visited << "DisclosureGroup(#{view.title})"
  end

  def visit(view : UI::PageControl)
    @visited << "PageControl(#{view.current}/#{view.total})"
  end

  def visit(view : UI::ComboBox)
    @visited << "ComboBox(#{view.value})"
  end

  def visit(view : UI::RatingIndicator)
    @visited << "RatingIndicator(#{view.value})"
  end

  {% if flag?(:ios) %}
    def visit(view : UI::ActionSheet)
      @visited << "ActionSheet(#{view.title})"
    end
  {% end %}

  def visit(view : UI::ActionSheetWithWebFallback)
    @visited << "ActionSheetWithWebFallback(#{view.title})"
  end

  def visit(view : UI::SwipeActionRow)
    @visited << "SwipeActionRow(trailing=#{view.trailing_actions.size},leading=#{view.leading_actions.size})"
  end
end

describe UI do
  describe "value types" do
    it "creates Color with defaults" do
      color = UI::Color.new(r: 1.0, g: 0.5, b: 0.0)
      color.r.should eq(1.0)
      color.g.should eq(0.5)
      color.b.should eq(0.0)
      color.a.should eq(1.0) # default alpha
    end

    it "creates Color with explicit alpha" do
      color = UI::Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.5)
      color.a.should eq(0.5)
    end

    it "creates Font with defaults" do
      font = UI::Font.new
      font.family.should eq("system")
      font.size.should eq(17.0)
      font.weight.should eq(:regular)
      font.italic.should be_false
    end

    it "creates Font with custom values" do
      font = UI::Font.new(family: "Helvetica", size: 24.0, weight: :bold, italic: true)
      font.family.should eq("Helvetica")
      font.size.should eq(24.0)
      font.weight.should eq(:bold)
      font.italic.should be_true
    end

    it "creates EdgeInsets with defaults" do
      insets = UI::EdgeInsets.new
      insets.top.should eq(0.0)
      insets.trailing.should eq(0.0)
      insets.bottom.should eq(0.0)
      insets.leading.should eq(0.0)
    end

    it "creates EdgeInsets with custom values" do
      insets = UI::EdgeInsets.new(top: 10.0, trailing: 20.0, bottom: 10.0, leading: 20.0)
      insets.top.should eq(10.0)
      insets.trailing.should eq(20.0)
    end
  end

  describe "view instantiation" do
    it "creates a Label" do
      label = UI::Label.new("Hello")
      label.text.should eq("Hello")
      label.font.family.should eq("system")
      label.number_of_lines.should eq(0)
      label.preferred_max_layout_width.should be_nil
    end

    it "creates a Button" do
      button = UI::Button.new("Tap me")
      button.label.should eq("Tap me")
      button.disabled.should be_false
      button.on_tap.should be_nil
    end

    it "creates a VStack" do
      stack = UI::VStack.new
      # Phase 6.10 Rem 1: default raised to 12pt (HIG form-row rhythm).
      stack.spacing.should eq(UI::VStack::DEFAULT_SPACING_PT)
      stack.spacing.should eq(12.0)
      stack.alignment.should eq(UI::Alignment::Center)
      stack.children.should be_empty
    end

    it "creates an HStack" do
      stack = UI::HStack.new(spacing: 12.0, alignment: UI::Alignment::Top)
      stack.spacing.should eq(12.0)
      stack.alignment.should eq(UI::Alignment::Top)
      stack.children.should be_empty
    end

    it "creates a ZStack" do
      stack = UI::ZStack.new(alignment: UI::Alignment::Leading)
      stack.alignment.should eq(UI::Alignment::Leading)
      stack.children.should be_empty
    end

    it "creates an Image" do
      image = UI::Image.new("icon_star")
      image.source.should eq("icon_star")
      image.content_mode.should eq(UI::ContentMode::Fit)
      image.tint_color.should be_nil
    end

    it "creates a TextField" do
      field = UI::TextField.new("Enter name")
      field.placeholder.should eq("Enter name")
      field.text.should eq("")
      field.secure_entry.should be_false
      field.keyboard_type.should eq(UI::KeyboardType::Default)
    end

    it "creates a ScrollView" do
      scroll = UI::ScrollView.new
      scroll.content.should be_nil
      scroll.scroll_horizontal.should be_false
      scroll.scroll_vertical.should be_true
      scroll.shows_indicators.should be_true
    end

    it "creates a Spacer" do
      spacer = UI::Spacer.new
      spacer.min_length.should eq(0.0)
    end

    it "creates a Spacer with min length" do
      spacer = UI::Spacer.new(min_length: 16.0)
      spacer.min_length.should eq(16.0)
    end
  end

  describe "view base properties" do
    it "sets and gets id" do
      label = UI::Label.new("Test")
      label.id.should be_nil
      label.id = "my-label"
      label.id.should eq("my-label")
    end

    it "sets and gets accessibility_label" do
      button = UI::Button.new("X")
      button.accessibility_label = "Close button"
      button.accessibility_label.should eq("Close button")
    end

    it "sets padding" do
      label = UI::Label.new("Padded")
      label.padding = UI::EdgeInsets.new(top: 8.0, trailing: 16.0, bottom: 8.0, leading: 16.0)
      label.padding.top.should eq(8.0)
      label.padding.leading.should eq(16.0)
    end

    it "sets background color" do
      label = UI::Label.new("Colored")
      label.background.should be_nil
      label.background = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
      label.background.not_nil!.r.should eq(1.0)
    end

    it "sets hidden" do
      label = UI::Label.new("Secret")
      label.hidden.should be_false
      label.hidden = true
      label.hidden.should be_true
    end

    it "sets opacity" do
      label = UI::Label.new("Faded")
      label.opacity.should eq(1.0)
      label.opacity = 0.5
      label.opacity.should eq(0.5)
    end

    it "has default modifier properties" do
      label = UI::Label.new("Test")
      label.corner_radius.should eq(0.0)
      label.clip_to_bounds.should be_false
      label.shadow_radius.should eq(0.0)
      label.shadow_color.should be_nil
      label.shadow_offset_x.should eq(0.0)
      label.shadow_offset_y.should eq(0.0)
      label.border_width.should eq(0.0)
      label.border_color.should be_nil
      label.blur_radius.should eq(0.0)
      label.minimum_width.should be_nil
      label.minimum_height.should be_nil
      label.maximum_width.should be_nil
      label.maximum_height.should be_nil
    end

    it "sets modifier properties" do
      label = UI::Label.new("Test")
      label.corner_radius = 8.0
      label.clip_to_bounds = true
      label.shadow_radius = 4.0
      label.shadow_color = UI::Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.5)
      label.shadow_offset_x = 2.0
      label.shadow_offset_y = 2.0
      label.border_width = 1.0
      label.border_color = UI::Color.new(r: 0.8, g: 0.8, b: 0.8)
      label.blur_radius = 5.0
      label.minimum_width = 100.0
      label.maximum_height = 200.0

      label.corner_radius.should eq(8.0)
      label.clip_to_bounds.should be_true
      label.shadow_radius.should eq(4.0)
      label.border_width.should eq(1.0)
      label.blur_radius.should eq(5.0)
      label.minimum_width.should eq(100.0)
      label.maximum_height.should eq(200.0)
    end
  end

  describe "enums" do
    it "has ToggleStyle enum" do
      UI::ToggleStyle::Switch.value.should eq(0)
      UI::ToggleStyle::Checkbox.value.should eq(1)
    end

    it "has PickerStyle enum" do
      UI::PickerStyle::Wheel.value.should eq(0)
      UI::PickerStyle::Menu.value.should eq(2)
    end

    it "has DatePickerMode enum" do
      UI::DatePickerMode::Date.value.should eq(0)
      UI::DatePickerMode::DateAndTime.value.should eq(2)
    end

    it "has ProgressStyle enum" do
      UI::ProgressStyle::Linear.value.should eq(0)
      UI::ProgressStyle::Circular.value.should eq(1)
    end

    it "has ListStyle enum" do
      UI::ListStyle::Plain.value.should eq(0)
      UI::ListStyle::Sidebar.value.should eq(4)
    end
  end

  describe "visitor pattern" do
    it "Label accepts visitor" do
      visitor = TestVisitor.new
      label = UI::Label.new("Hello")
      label.accept(visitor)
      visitor.visited.should eq(["Label(Hello)"])
    end

    it "Button accepts visitor" do
      visitor = TestVisitor.new
      button = UI::Button.new("OK")
      button.accept(visitor)
      visitor.visited.should eq(["Button(OK)"])
    end

    it "VStack accepts visitor and visits children" do
      visitor = TestVisitor.new
      stack = UI::VStack.new
      stack << UI::Label.new("First")
      stack << UI::Label.new("Second")
      stack.accept(visitor)
      visitor.visited.should eq(["VStack(2)", "Label(First)", "Label(Second)"])
    end

    it "HStack accepts visitor and visits children" do
      visitor = TestVisitor.new
      stack = UI::HStack.new
      stack << UI::Button.new("A")
      stack << UI::Spacer.new
      stack << UI::Button.new("B")
      stack.accept(visitor)
      visitor.visited.should eq(["HStack(3)", "Button(A)", "Spacer(0.0)", "Button(B)"])
    end

    it "ZStack accepts visitor and visits children" do
      visitor = TestVisitor.new
      stack = UI::ZStack.new
      stack << UI::Image.new("bg")
      stack << UI::Label.new("Overlay")
      stack.accept(visitor)
      visitor.visited.should eq(["ZStack(2)", "Image(bg)", "Label(Overlay)"])
    end

    it "Image accepts visitor" do
      visitor = TestVisitor.new
      image = UI::Image.new("photo")
      image.accept(visitor)
      visitor.visited.should eq(["Image(photo)"])
    end

    it "TextField accepts visitor" do
      visitor = TestVisitor.new
      field = UI::TextField.new("Search...")
      field.accept(visitor)
      visitor.visited.should eq(["TextField(Search...)"])
    end

    it "ScrollView accepts visitor and visits content" do
      visitor = TestVisitor.new
      content = UI::VStack.new
      content << UI::Label.new("Scrollable")
      scroll = UI::ScrollView.new(content)
      scroll.accept(visitor)
      visitor.visited.should eq(["ScrollView", "VStack(1)", "Label(Scrollable)"])
    end

    it "Spacer accepts visitor" do
      visitor = TestVisitor.new
      spacer = UI::Spacer.new(min_length: 20.0)
      spacer.accept(visitor)
      visitor.visited.should eq(["Spacer(20.0)"])
    end
  end

  describe "children arrays" do
    it "VStack children accepts mixed view types" do
      stack = UI::VStack.new
      stack << UI::Label.new("Title")
      stack << UI::Button.new("Action")
      stack << UI::Image.new("icon")
      stack << UI::Spacer.new

      stack.children.size.should eq(4)
      stack.children[0].should be_a(UI::Label)
      stack.children[1].should be_a(UI::Button)
      stack.children[2].should be_a(UI::Image)
      stack.children[3].should be_a(UI::Spacer)
    end

    it "HStack children accepts mixed view types" do
      stack = UI::HStack.new
      stack << UI::Label.new("Name:")
      stack << UI::TextField.new("Enter name")
      stack.children.size.should eq(2)
    end

    it "ZStack children accepts mixed view types" do
      stack = UI::ZStack.new
      stack << UI::Image.new("background")
      stack << UI::VStack.new
      stack.children.size.should eq(2)
    end

    it "<< returns self for chaining" do
      stack = UI::VStack.new
      result = stack << UI::Label.new("A")
      result.should be(stack)

      # Chaining
      stack << UI::Label.new("B") << UI::Label.new("C")
      # Note: the second << is on VStack (returned by first <<), not on Label
      stack.children.size.should eq(3)
    end
  end

  describe "Button on_tap callback" do
    it "stores and calls on_tap proc" do
      called = false
      button = UI::Button.new("Tap") { called = true; nil }
      button.on_tap.should_not be_nil
      button.on_tap.try(&.call)
      called.should be_true
    end

    it "allows setting on_tap after construction" do
      button = UI::Button.new("Later")
      button.on_tap.should be_nil

      counter = 0
      button.on_tap = ->{ counter += 1; nil }
      button.on_tap.try(&.call)
      button.on_tap.try(&.call)
      counter.should eq(2)
    end
  end

  describe "TextField on_change callback" do
    it "stores and calls on_change proc" do
      received = ""
      field = UI::TextField.new("Type here") { |text| received = text; nil }
      field.on_change.should_not be_nil
      field.on_change.try(&.call("hello"))
      received.should eq("hello")
    end

    it "allows setting on_change after construction" do
      field = UI::TextField.new
      values = [] of String
      field.on_change = ->(text : String) { values << text; nil }
      field.on_change.try(&.call("a"))
      field.on_change.try(&.call("ab"))
      values.should eq(["a", "ab"])
    end
  end

  describe "recursive view tree" do
    it "VStack containing HStack containing Labels" do
      root = UI::VStack.new(spacing: 16.0)

      header = UI::HStack.new(spacing: 4.0)
      header << UI::Image.new("avatar")
      header << UI::Label.new("Username")
      header << UI::Spacer.new

      body = UI::VStack.new(spacing: 4.0)
      body << UI::Label.new("Post content here")

      footer = UI::HStack.new(spacing: 12.0)
      footer << UI::Button.new("Like")
      footer << UI::Button.new("Reply")
      footer << UI::Spacer.new

      root << header
      root << body
      root << footer

      root.children.size.should eq(3)
      root.children[0].should be_a(UI::HStack)
      root.children[1].should be_a(UI::VStack)
      root.children[2].should be_a(UI::HStack)

      # Verify nested structure
      header_view = root.children[0].as(UI::HStack)
      header_view.children.size.should eq(3)
      header_view.children[0].should be_a(UI::Image)
      header_view.children[1].should be_a(UI::Label)
      header_view.children[2].should be_a(UI::Spacer)
    end

    it "traverses deep tree with visitor" do
      visitor = TestVisitor.new

      root = UI::VStack.new
      row = UI::HStack.new
      row << UI::Label.new("A")
      row << UI::Label.new("B")
      root << row
      root << UI::Label.new("C")

      root.accept(visitor)

      visitor.visited.should eq([
        "VStack(2)",
        "HStack(2)",
        "Label(A)",
        "Label(B)",
        "Label(C)",
      ])
    end

    it "ScrollView wrapping a complex tree" do
      visitor = TestVisitor.new

      content = UI::VStack.new
      content << UI::Label.new("Header")
      inner = UI::HStack.new
      inner << UI::Button.new("Go")
      content << inner
      content << UI::TextField.new("Search")

      scroll = UI::ScrollView.new(content)
      scroll.accept(visitor)

      visitor.visited.should eq([
        "ScrollView",
        "VStack(3)",
        "Label(Header)",
        "HStack(1)",
        "Button(Go)",
        "TextField(Search)",
      ])
    end
  end
end

describe UI::Toggle do
  it "creates with defaults" do
    toggle = UI::Toggle.new
    toggle.is_on.should be_false
    toggle.label.should eq("")
    toggle.style.should eq(UI::ToggleStyle::Switch)
    toggle.tint_color.should be_nil
    toggle.on_change.should be_nil
  end

  it "creates with label and initial state" do
    toggle = UI::Toggle.new("WiFi", true)
    toggle.label.should eq("WiFi")
    toggle.is_on.should be_true
  end

  it "creates with callback" do
    called_with = false
    toggle = UI::Toggle.new("Notifications") { |val| called_with = val; nil }
    toggle.on_change.try(&.call(true))
    called_with.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    toggle = UI::Toggle.new("Airplane")
    toggle.accept(v)
    v.visited.should eq(["Toggle(Airplane)"])
  end
end

describe UI::Checkbox do
  it "creates with defaults" do
    cb = UI::Checkbox.new
    cb.is_checked.should be_false
    cb.label.should eq("")
    cb.on_change.should be_nil
  end

  it "creates with label and state" do
    cb = UI::Checkbox.new("Accept Terms", true)
    cb.label.should eq("Accept Terms")
    cb.is_checked.should be_true
  end

  it "creates with callback" do
    called = false
    cb = UI::Checkbox.new("I agree") { |val| called = val; nil }
    cb.on_change.try(&.call(true))
    called.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    cb = UI::Checkbox.new("Check me")
    cb.accept(v)
    v.visited.should eq(["Checkbox(Check me)"])
  end
end

describe UI::RadioGroup do
  it "creates with defaults" do
    rg = UI::RadioGroup.new
    rg.options.should be_empty
    rg.selected_index.should eq(0)
    rg.on_change.should be_nil
  end

  it "creates with options" do
    rg = UI::RadioGroup.new(["Small", "Medium", "Large"], 1)
    rg.options.size.should eq(3)
    rg.selected_index.should eq(1)
  end

  it "creates with callback" do
    selected = -1
    rg = UI::RadioGroup.new(["A", "B", "C"]) { |idx| selected = idx; nil }
    rg.on_change.try(&.call(2))
    selected.should eq(2)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    rg = UI::RadioGroup.new(["X", "Y"])
    rg.accept(v)
    v.visited.should eq(["RadioGroup(2)"])
  end
end

describe UI::Slider do
  it "creates with defaults" do
    s = UI::Slider.new
    s.value.should eq(0.0)
    s.minimum.should eq(0.0)
    s.maximum.should eq(1.0)
    s.step.should eq(0.0)
    s.label.should eq("")
    s.on_change.should be_nil
  end

  it "creates with range" do
    s = UI::Slider.new(0.0, 100.0, 50.0)
    s.minimum.should eq(0.0)
    s.maximum.should eq(100.0)
    s.value.should eq(50.0)
  end

  it "creates with callback" do
    val = 0.0
    s = UI::Slider.new(0.0, 1.0) { |v| val = v; nil }
    s.on_change.try(&.call(0.5))
    val.should eq(0.5)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    s = UI::Slider.new(0.0, 1.0, 0.75)
    s.accept(v)
    v.visited.should eq(["Slider(0.75)"])
  end
end

describe UI::NavigationStack do
  it "creates with root view" do
    root = UI::Label.new("Home")
    nav = UI::NavigationStack.new(root, "My App")
    nav.root.should be(root)
    nav.title.should eq("My App")
    nav.large_title.should be_false
    nav.shows_navigation_bar.should be_true
    nav.stack.should be_empty
  end

  it "pushes and pops views" do
    root = UI::Label.new("Home")
    nav = UI::NavigationStack.new(root)

    detail = UI::Label.new("Detail")
    nav.push(detail)
    nav.stack.size.should eq(1)
    nav.current_view.should be(detail)

    popped = nav.pop
    popped.should be(detail)
    nav.current_view.should be(root)
  end

  it "pops to root" do
    root = UI::Label.new("Root")
    nav = UI::NavigationStack.new(root)
    nav.push(UI::Label.new("A"))
    nav.push(UI::Label.new("B"))
    nav.push(UI::Label.new("C"))
    nav.stack.size.should eq(3)

    nav.pop_to_root
    nav.stack.should be_empty
    nav.current_view.should be(root)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    root = UI::Label.new("Home")
    nav = UI::NavigationStack.new(root, "App")
    nav.accept(v)
    v.visited.should eq(["NavigationStack(App)", "Label(Home)"])
  end
end

describe UI::NavigationLink do
  it "creates with label and destination" do
    dest = UI::Label.new("Details")
    link = UI::NavigationLink.new("View Details", dest)
    link.label.should eq("View Details")
    link.destination.should be(dest)
    link.icon.should be_nil
    link.shows_disclosure.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    link = UI::NavigationLink.new("Go", UI::Label.new("There"))
    link.accept(v)
    v.visited.should eq(["NavigationLink(Go)"])
  end
end

describe UI::TabView do
  it "creates with tabs" do
    tabs = [
      UI::TabView::Tab.new(label: "Home", content: UI::Label.new("Home Content")),
      UI::TabView::Tab.new(label: "Settings", icon: "gear", content: UI::Label.new("Settings Content")),
    ]
    tv = UI::TabView.new(tabs, 0)
    tv.tabs.size.should eq(2)
    tv.selected_index.should eq(0)
    tv.on_change.should be_nil
  end

  it "returns current content" do
    home = UI::Label.new("Home")
    settings = UI::Label.new("Settings")
    tabs = [
      UI::TabView::Tab.new(label: "Home", content: home),
      UI::TabView::Tab.new(label: "Settings", content: settings),
    ]
    tv = UI::TabView.new(tabs, 1)
    tv.current_content.should be(settings)
  end

  it "creates with callback" do
    selected = -1
    tabs = [UI::TabView::Tab.new(label: "A"), UI::TabView::Tab.new(label: "B")]
    tv = UI::TabView.new(tabs) { |idx| selected = idx; nil }
    tv.on_change.try(&.call(1))
    selected.should eq(1)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    tv = UI::TabView.new([UI::TabView::Tab.new(label: "Tab1")])
    tv.accept(v)
    v.visited.should eq(["TabView(1)"])
  end
end

describe UI::ProgressView do
  it "creates with defaults" do
    pv = UI::ProgressView.new
    pv.value.should be_nil
    pv.style.should eq(UI::ProgressStyle::Linear)
    pv.tint_color.should be_nil
    pv.label.should eq("")
  end

  it "creates with value and style" do
    pv = UI::ProgressView.new(0.75, UI::ProgressStyle::Circular)
    pv.value.should eq(0.75)
    pv.style.should eq(UI::ProgressStyle::Circular)
  end

  it "allows nil value for indeterminate state" do
    pv = UI::ProgressView.new(nil, UI::ProgressStyle::Linear)
    pv.value.should be_nil
  end

  it "accepts visitor" do
    v = TestVisitor.new
    pv = UI::ProgressView.new(0.5, UI::ProgressStyle::Linear)
    pv.accept(v)
    v.visited.should eq(["ProgressView(Linear)"])
  end
end

describe UI::ActivityIndicator do
  it "creates with defaults" do
    ai = UI::ActivityIndicator.new
    ai.is_animating.should be_true
    ai.size.should eq(:medium)
    ai.color.should be_nil
  end

  it "creates with animating false and large size" do
    ai = UI::ActivityIndicator.new(false, :large)
    ai.is_animating.should be_false
    ai.size.should eq(:large)
  end

  it "sets color" do
    ai = UI::ActivityIndicator.new
    ai.color = UI::Color.new(r: 0.0, g: 0.5, b: 1.0)
    ai.color.should_not be_nil
    ai.color.not_nil!.g.should eq(0.5)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    ai = UI::ActivityIndicator.new(true)
    ai.accept(v)
    v.visited.should eq(["ActivityIndicator(true)"])
  end
end

describe UI::Alert do
  it "creates with title only" do
    alert = UI::Alert.new("Warning")
    alert.title.should eq("Warning")
    alert.message.should eq("")
    alert.buttons.should be_empty
    alert.is_presented.should be_false
  end

  it "creates with title and message" do
    alert = UI::Alert.new("Error", "Something went wrong.")
    alert.title.should eq("Error")
    alert.message.should eq("Something went wrong.")
  end

  it "adds buttons" do
    alert = UI::Alert.new("Confirm")
    alert.add_button("OK")
    alert.add_button("Cancel", :cancel)
    alert.buttons.size.should eq(2)
    alert.buttons[0].label.should eq("OK")
    alert.buttons[0].style.should eq(:default)
    alert.buttons[1].label.should eq("Cancel")
    alert.buttons[1].style.should eq(:cancel)
  end

  it "button action is called" do
    called = false
    alert = UI::Alert.new("Test")
    alert.add_button("Delete", :destructive) { called = true; nil }
    alert.buttons[0].action.try(&.call)
    called.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    alert = UI::Alert.new("Hello")
    alert.accept(v)
    v.visited.should eq(["Alert(Hello)"])
  end
end

describe UI::Picker do
  it "creates with defaults" do
    picker = UI::Picker.new
    picker.options.should be_empty
    picker.selected_index.should eq(0)
    picker.label.should eq("")
    picker.style.should eq(UI::PickerStyle::Menu)
    picker.on_change.should be_nil
  end

  it "creates with options and index" do
    picker = UI::Picker.new(["Small", "Medium", "Large"], 1)
    picker.options.size.should eq(3)
    picker.selected_index.should eq(1)
  end

  it "returns selected_option" do
    picker = UI::Picker.new(["Red", "Green", "Blue"], 2)
    picker.selected_option.should eq("Blue")
  end

  it "returns nil selected_option when empty" do
    picker = UI::Picker.new
    picker.selected_option.should be_nil
  end

  it "creates with callback" do
    received = -1
    picker = UI::Picker.new(["A", "B", "C"]) { |idx| received = idx; nil }
    picker.on_change.try(&.call(2))
    received.should eq(2)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    picker = UI::Picker.new(["X", "Y", "Z"], 0)
    picker.accept(v)
    v.visited.should eq(["Picker(3)"])
  end
end

describe UI::IconButton do
  it "creates with icon name" do
    btn = UI::IconButton.new("star.fill")
    btn.icon.should eq("star.fill")
    btn.label.should be_nil
    btn.icon_size.should eq(24.0)
    btn.disabled.should be_false
    btn.on_tap.should be_nil
  end

  it "creates with tap callback" do
    called = false
    btn = UI::IconButton.new("heart") { called = true; nil }
    btn.on_tap.should_not be_nil
    btn.on_tap.try(&.call)
    called.should be_true
  end

  it "sets label and icon_size" do
    btn = UI::IconButton.new("gear")
    btn.label = "Settings"
    btn.icon_size = 32.0
    btn.label.should eq("Settings")
    btn.icon_size.should eq(32.0)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    btn = UI::IconButton.new("trash")
    btn.accept(v)
    v.visited.should eq(["IconButton(trash)"])
  end
end

describe UI::ListView do
  it "creates with defaults" do
    lv = UI::ListView.new
    lv.sections.should be_empty
    lv.style.should eq(UI::ListStyle::Plain)
    lv.shows_separators.should be_true
    lv.on_item_tap.should be_nil
    lv.item_count.should eq(0)
  end

  it "creates flat list with factory method" do
    items = [UI::Label.new("A"), UI::Label.new("B"), UI::Label.new("C")] of UI::View
    lv = UI::ListView.flat(items)
    lv.sections.size.should eq(1)
    lv.item_count.should eq(3)
  end

  it "Section record holds header, items, footer" do
    items = [UI::Label.new("Item")] of UI::View
    section = UI::ListView::Section.new(header: "Section 1", items: items, footer: "End")
    section.header.should eq("Section 1")
    section.items.size.should eq(1)
    section.footer.should eq("End")
  end

  it "item_count sums across all sections" do
    s1_items = [UI::Label.new("A"), UI::Label.new("B")] of UI::View
    s2_items = [UI::Label.new("C")] of UI::View
    lv = UI::ListView.new([
      UI::ListView::Section.new(items: s1_items),
      UI::ListView::Section.new(items: s2_items),
    ])
    lv.item_count.should eq(3)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    items = [UI::Label.new("X"), UI::Label.new("Y")] of UI::View
    lv = UI::ListView.flat(items)
    lv.accept(v)
    v.visited.should eq(["ListView(2)"])
  end
end

describe UI::SecureField do
  it "creates with defaults" do
    sf = UI::SecureField.new
    sf.text.should eq("")
    sf.placeholder.should eq("")
    sf.font.family.should eq("system")
    sf.text_color.r.should eq(0.0)
    sf.on_change.should be_nil
  end

  it "creates with placeholder" do
    sf = UI::SecureField.new("Enter password")
    sf.placeholder.should eq("Enter password")
  end

  it "creates with callback" do
    received = ""
    sf = UI::SecureField.new("Password") { |val| received = val; nil }
    sf.on_change.should_not be_nil
    sf.on_change.try(&.call("secret"))
    received.should eq("secret")
  end

  it "accepts visitor" do
    v = TestVisitor.new
    sf = UI::SecureField.new("••••••")
    sf.accept(v)
    v.visited.should eq(["SecureField(••••••)"])
  end
end

describe UI::Stepper do
  it "creates with defaults" do
    s = UI::Stepper.new
    s.value.should eq(0.0)
    s.minimum.should eq(0.0)
    s.maximum.should eq(100.0)
    s.step_value.should eq(1.0)
    s.wraps.should be_false
  end

  it "creates with range" do
    s = UI::Stepper.new(0.0, 10.0, 5.0)
    s.minimum.should eq(0.0)
    s.maximum.should eq(10.0)
    s.value.should eq(5.0)
  end

  it "increments and decrements" do
    s = UI::Stepper.new(0.0, 10.0, 5.0)
    s.increment
    s.value.should eq(6.0)
    s.decrement
    s.value.should eq(5.0)
  end

  it "clamps at maximum" do
    s = UI::Stepper.new(0.0, 10.0, 10.0)
    s.increment
    s.value.should eq(10.0)
  end

  it "wraps around" do
    s = UI::Stepper.new(0.0, 10.0, 10.0)
    s.wraps = true
    s.increment
    s.value.should eq(0.0)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    s = UI::Stepper.new(0.0, 10.0, 3.0)
    s.accept(v)
    v.visited.should eq(["Stepper(3.0)"])
  end
end

describe UI::SegmentedControl do
  it "creates with defaults" do
    sc = UI::SegmentedControl.new
    sc.segments.should be_empty
    sc.selected_index.should eq(0)
    sc.on_change.should be_nil
  end

  it "creates with segments" do
    sc = UI::SegmentedControl.new(["Day", "Week", "Month"], 1)
    sc.segments.size.should eq(3)
    sc.selected_index.should eq(1)
  end

  it "returns selected_segment" do
    sc = UI::SegmentedControl.new(["A", "B", "C"], 2)
    sc.selected_segment.should eq("C")
  end

  it "creates with callback" do
    received = -1
    sc = UI::SegmentedControl.new(["X", "Y"]) { |idx| received = idx; nil }
    sc.on_change.try(&.call(1))
    received.should eq(1)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    sc = UI::SegmentedControl.new(["A", "B", "C"])
    sc.accept(v)
    v.visited.should eq(["SegmentedControl(3)"])
  end
end

describe UI::DatePicker do
  it "creates with defaults" do
    dp = UI::DatePicker.new
    dp.mode.should eq(UI::DatePickerMode::Date)
    dp.minimum_date.should be_nil
    dp.maximum_date.should be_nil
    dp.label.should eq("")
    dp.on_change.should be_nil
  end

  it "creates with mode" do
    dp = UI::DatePicker.new(UI::DatePickerMode::DateAndTime)
    dp.mode.should eq(UI::DatePickerMode::DateAndTime)
  end

  it "creates with callback" do
    called = false
    dp = UI::DatePicker.new { |_t| called = true; nil }
    dp.on_change.try(&.call(Time.utc))
    called.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    dp = UI::DatePicker.new
    dp.accept(v)
    v.visited.should eq(["DatePicker(Date)"])
  end
end

describe UI::TimePicker do
  it "creates with defaults" do
    tp = UI::TimePicker.new
    tp.shows_24_hour.should be_false
    tp.minute_interval.should eq(1)
    tp.label.should eq("")
    tp.on_change.should be_nil
  end

  it "creates with 24-hour mode" do
    tp = UI::TimePicker.new(true)
    tp.shows_24_hour.should be_true
  end

  it "creates with callback" do
    called = false
    tp = UI::TimePicker.new { |_t| called = true; nil }
    tp.on_change.try(&.call(Time.utc))
    called.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    tp = UI::TimePicker.new
    tp.accept(v)
    v.visited.should eq(["TimePicker(false)"])
  end
end

describe UI::SearchField do
  it "creates with defaults" do
    sf = UI::SearchField.new
    sf.text.should eq("")
    sf.placeholder.should eq("Search")
    sf.is_searching.should be_false
    sf.shows_cancel_button.should be_true
    sf.on_change.should be_nil
  end

  it "creates with placeholder" do
    sf = UI::SearchField.new("Find items...")
    sf.placeholder.should eq("Find items...")
  end

  it "creates with callback" do
    received = ""
    sf = UI::SearchField.new { |text| received = text; nil }
    sf.on_change.try(&.call("hello"))
    received.should eq("hello")
  end

  it "accepts visitor" do
    v = TestVisitor.new
    sf = UI::SearchField.new("Search")
    sf.accept(v)
    v.visited.should eq(["SearchField(Search)"])
  end
end

describe UI::TextArea do
  it "creates with defaults" do
    ta = UI::TextArea.new
    ta.text.should eq("")
    ta.placeholder.should eq("")
    ta.is_editable.should be_true
    ta.is_scrollable.should be_true
    ta.line_limit.should be_nil
  end

  it "creates with placeholder" do
    ta = UI::TextArea.new("Enter text...")
    ta.placeholder.should eq("Enter text...")
  end

  it "creates with callback" do
    received = ""
    ta = UI::TextArea.new { |text| received = text; nil }
    ta.on_change.try(&.call("hello world"))
    received.should eq("hello world")
  end

  it "accepts visitor" do
    v = TestVisitor.new
    ta = UI::TextArea.new("Notes")
    ta.accept(v)
    v.visited.should eq(["TextArea(Notes)"])
  end
end

describe UI::Grid do
  it "creates with defaults" do
    g = UI::Grid.new
    g.children.should be_empty
    g.row_spacing.should eq(8.0)
    g.column_spacing.should eq(8.0)
    g.row_count.should eq(0)
  end

  it "creates with columns" do
    cols = [UI::Grid::Column.new, UI::Grid::Column.new, UI::Grid::Column.new]
    g = UI::Grid.new(cols)
    g.column_count.should eq(3)
  end

  it "adds rows" do
    g = UI::Grid.new
    g.add_row([UI::Label.new("A"), UI::Label.new("B")] of UI::View)
    g.add_row([UI::Label.new("C"), UI::Label.new("D")] of UI::View)
    g.row_count.should eq(2)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    cols = [UI::Grid::Column.new, UI::Grid::Column.new]
    g = UI::Grid.new(cols)
    g.add_row([UI::Label.new("A"), UI::Label.new("B")] of UI::View)
    g.accept(v)
    v.visited.should eq(["Grid(1x2)"])
  end
end

describe UI::Form do
  it "creates with defaults" do
    f = UI::Form.new
    f.sections.should be_empty
    f.field_count.should eq(0)
  end

  it "adds sections" do
    f = UI::Form.new
    f.add_section("Account", "Your account info")
    f.sections.size.should eq(1)
    f.sections[0].header.should eq("Account")
    f.sections[0].footer.should eq("Your account info")
  end

  it "counts fields across sections" do
    f = UI::Form.new
    f.sections = [
      UI::Form::FormSection.new(fields: [
        UI::Form::Field.new(label: "Name", content: UI::TextField.new("Name")),
        UI::Form::Field.new(label: "Email", content: UI::TextField.new("Email")),
      ]),
      UI::Form::FormSection.new(fields: [
        UI::Form::Field.new(label: "Bio", content: UI::TextArea.new("Bio")),
      ]),
    ]
    f.field_count.should eq(3)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    f = UI::Form.new
    f.accept(v)
    v.visited.should eq(["Form(0)"])
  end
end

describe UI::NavigationSplitView do
  it "creates with defaults" do
    nsv = UI::NavigationSplitView.new
    nsv.sidebar.should be_nil
    nsv.content.should be_nil
    nsv.detail.should be_nil
    nsv.sidebar_width.should eq(250.0)
    nsv.shows_sidebar.should be_true
    nsv.column_visibility.should eq(:all)
  end

  it "creates with views" do
    sidebar = UI::Label.new("Sidebar")
    content = UI::Label.new("Content")
    nsv = UI::NavigationSplitView.new(sidebar, content)
    nsv.sidebar.should be(sidebar)
    nsv.content.should be(content)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    nsv = UI::NavigationSplitView.new
    nsv.accept(v)
    v.visited.should eq(["NavigationSplitView(all)"])
  end
end

describe UI::Toolbar do
  it "creates with defaults" do
    tb = UI::Toolbar.new
    tb.items.should be_empty
    tb.title.should be_nil
    tb.shows_title.should be_true
  end

  it "creates with title" do
    tb = UI::Toolbar.new("Editor")
    tb.title.should eq("Editor")
  end

  it "adds items" do
    tb = UI::Toolbar.new
    tb.add_item("bold", "Bold", "bold.icon")
    tb.add_item("italic", "Italic")
    tb.items.size.should eq(2)
    tb.items[0].label.should eq("Bold")
    tb.items[0].icon.should eq("bold.icon")
  end

  it "adds items with action" do
    called = false
    tb = UI::Toolbar.new
    tb.add_item("save", "Save") { called = true; nil }
    tb.items[0].action.try(&.call)
    called.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    tb = UI::Toolbar.new
    tb.add_item("a", "A")
    tb.accept(v)
    v.visited.should eq(["Toolbar(1)"])
  end
end

describe UI::Sheet do
  it "creates with defaults" do
    s = UI::Sheet.new
    s.content.should be_nil
    s.is_presented.should be_false
    s.shows_drag_indicator.should be_true
    s.detents.should eq([:medium, :large])
    s.selected_detent.should eq(:medium)
  end

  it "creates with content" do
    content = UI::Label.new("Sheet Content")
    s = UI::Sheet.new(content)
    s.content.should be(content)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    s = UI::Sheet.new
    s.accept(v)
    v.visited.should eq(["Sheet(false)"])
  end
end

describe UI::SheetPresenter do
  it "presents and dismisses" do
    sheet = UI::Sheet.new
    presenter = UI::SheetPresenter.new(sheet)
    presenter.is_presenting.should be_false

    presenter.present
    presenter.is_presenting.should be_true
    sheet.is_presented.should be_true

    presenter.dismiss
    presenter.is_presenting.should be_false
    sheet.is_presented.should be_false
  end

  it "calls on_dismiss callback" do
    called = false
    sheet = UI::Sheet.new
    sheet.on_dismiss = ->{ called = true; nil }
    presenter = UI::SheetPresenter.new(sheet)
    presenter.present
    presenter.dismiss
    called.should be_true
  end
end

describe UI::Popover do
  it "creates with defaults" do
    p = UI::Popover.new
    p.content.should be_nil
    p.is_presented.should be_false
    p.arrow_edge.should eq(:bottom)
    p.preferred_width.should be_nil
  end

  it "creates with content and arrow edge" do
    content = UI::Label.new("Info")
    p = UI::Popover.new(content, :top)
    p.content.should be(content)
    p.arrow_edge.should eq(:top)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    p = UI::Popover.new
    p.accept(v)
    v.visited.should eq(["Popover(bottom)"])
  end
end

describe UI::PopoverPresenter do
  it "presents and dismisses" do
    popover = UI::Popover.new
    anchor = UI::Button.new("Show")
    presenter = UI::PopoverPresenter.new(popover, anchor)
    presenter.is_presenting.should be_false

    presenter.present
    presenter.is_presenting.should be_true
    popover.is_presented.should be_true

    presenter.dismiss
    presenter.is_presenting.should be_false
    popover.is_presented.should be_false
  end
end

describe UI::ConfirmationDialog do
  it "creates with title" do
    cd = UI::ConfirmationDialog.new("Delete?")
    cd.title.should eq("Delete?")
    cd.message.should eq("")
    cd.confirm_label.should eq("Confirm")
    cd.cancel_label.should eq("Cancel")
    cd.confirm_style.should eq(:default)
  end

  it "creates with message" do
    cd = UI::ConfirmationDialog.new("Delete?", "This cannot be undone.")
    cd.message.should eq("This cannot be undone.")
  end

  it "has callbacks" do
    confirmed = false
    cancelled = false
    cd = UI::ConfirmationDialog.new("Confirm")
    cd.on_confirm = ->{ confirmed = true; nil }
    cd.on_cancel = ->{ cancelled = true; nil }
    cd.on_confirm.try(&.call)
    confirmed.should be_true
    cd.on_cancel.try(&.call)
    cancelled.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    cd = UI::ConfirmationDialog.new("Sure?")
    cd.accept(v)
    v.visited.should eq(["ConfirmationDialog(Sure?)"])
  end
end

describe UI::Snackbar do
  it "creates with message" do
    s = UI::Snackbar.new("Item deleted")
    s.message.should eq("Item deleted")
    s.action_label.should be_nil
    s.duration.should eq(4.0)
    s.is_presented.should be_false
  end

  it "creates with action" do
    s = UI::Snackbar.new("Deleted", "Undo")
    s.action_label.should eq("Undo")
  end

  it "accepts visitor" do
    v = TestVisitor.new
    s = UI::Snackbar.new("Done")
    s.accept(v)
    v.visited.should eq(["Snackbar(Done)"])
  end
end

describe UI::SnackbarPresenter do
  it "shows and dismisses" do
    snackbar = UI::Snackbar.new("Test")
    presenter = UI::SnackbarPresenter.new(snackbar)
    presenter.show
    presenter.is_presenting.should be_true
    snackbar.is_presented.should be_true

    presenter.dismiss
    presenter.is_presenting.should be_false
    snackbar.is_presented.should be_false
  end
end

describe UI::Card do
  it "creates with defaults" do
    c = UI::Card.new
    c.content.should be_nil
    c.elevation.should eq(1.0)
    c.is_outlined.should be_false
  end

  it "creates with content" do
    content = UI::Label.new("Card content")
    c = UI::Card.new(content)
    c.content.should be(content)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    c = UI::Card.new
    c.accept(v)
    v.visited.should eq(["Card(1.0)"])
  end
end

describe UI::Surface do
  it "creates with defaults" do
    s = UI::Surface.new
    s.content.should be_nil
    s.elevation.should eq(0.0)
    s.shape.should eq(:rectangle)
  end

  it "creates with content" do
    content = UI::Label.new("Surface")
    s = UI::Surface.new(content)
    s.content.should be(content)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    s = UI::Surface.new
    s.accept(v)
    v.visited.should eq(["Surface(rectangle)"])
  end
end

describe UI::Divider do
  it "creates with defaults" do
    d = UI::Divider.new
    d.orientation.should eq(:horizontal)
    d.thickness.should eq(1.0)
  end

  it "creates vertical" do
    d = UI::Divider.new(:vertical)
    d.orientation.should eq(:vertical)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    d = UI::Divider.new
    d.accept(v)
    v.visited.should eq(["Divider(horizontal)"])
  end
end

describe UI::GlassBackground do
  it "creates with defaults" do
    g = UI::GlassBackground.new
    g.content.should be_nil
    g.material.should eq(:regular)
    g.is_vibrant.should be_true
  end

  it "creates with content and material" do
    content = UI::Label.new("Glassy")
    g = UI::GlassBackground.new(content, :thin)
    g.content.should be(content)
    g.material.should eq(:thin)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    g = UI::GlassBackground.new
    g.accept(v)
    v.visited.should eq(["GlassBackground(regular)"])
  end
end

# ---------------------------------------------------------------
# P2 Wave 3 specs
# ---------------------------------------------------------------

describe UI::AsyncImage do
  it "creates with defaults" do
    ai = UI::AsyncImage.new
    ai.url.should eq("")
    ai.placeholder.should be_nil
    ai.content_mode.should eq(UI::ContentMode::Fit)
    ai.is_loading.should be_false
    ai.error_message.should be_nil
    ai.on_load.should be_nil
    ai.on_error.should be_nil
  end

  it "creates with url" do
    ai = UI::AsyncImage.new("https://example.com/photo.jpg")
    ai.url.should eq("https://example.com/photo.jpg")
  end

  it "sets properties" do
    ai = UI::AsyncImage.new("https://example.com/image.png")
    ai.content_mode = UI::ContentMode::Fill
    ai.is_loading = true
    ai.content_mode.should eq(UI::ContentMode::Fill)
    ai.is_loading.should be_true
  end

  it "stores on_load callback" do
    loaded = false
    ai = UI::AsyncImage.new("https://example.com/img.png")
    ai.on_load = ->{ loaded = true; nil }
    ai.on_load.try(&.call)
    loaded.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    ai = UI::AsyncImage.new("https://example.com/photo.jpg")
    ai.accept(v)
    v.visited.should eq(["AsyncImage(https://example.com/photo.jpg)"])
  end
end

describe UI::RichText do
  it "creates with defaults" do
    rt = UI::RichText.new
    rt.spans.should be_empty
    rt.text_alignment.should eq(UI::Alignment::Leading)
  end

  it "adds spans" do
    rt = UI::RichText.new
    rt.add_span("Hello", bold: true)
    rt.add_span(" World", italic: true)
    rt.spans.size.should eq(2)
    rt.spans[0].bold.should be_true
    rt.spans[1].italic.should be_true
  end

  it "returns plain_text" do
    rt = UI::RichText.new
    rt.add_span("Hello")
    rt.add_span(" World")
    rt.plain_text.should eq("Hello World")
  end

  it "spans support all formatting flags" do
    rt = UI::RichText.new
    color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
    rt.add_span("styled", bold: true, italic: true, color: color)
    span = rt.spans[0]
    span.bold.should be_true
    span.italic.should be_true
    span.color.r.should eq(1.0)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    rt = UI::RichText.new
    rt.add_span("Hello")
    rt.add_span(" World")
    rt.accept(v)
    v.visited.should eq(["RichText(2)"])
  end
end

describe UI::LinkButton do
  it "creates with label" do
    lb = UI::LinkButton.new("Click me")
    lb.label.should eq("Click me")
    lb.url.should eq("")
    lb.opens_in_browser.should be_true
    lb.on_tap.should be_nil
  end

  it "creates with label and url" do
    lb = UI::LinkButton.new("Visit", "https://example.com")
    lb.label.should eq("Visit")
    lb.url.should eq("https://example.com")
  end

  it "sets opens_in_browser" do
    lb = UI::LinkButton.new("Link")
    lb.opens_in_browser = false
    lb.opens_in_browser.should be_false
  end

  it "stores on_tap callback" do
    tapped = false
    lb = UI::LinkButton.new("Tap")
    lb.on_tap = ->{ tapped = true; nil }
    lb.on_tap.try(&.call)
    tapped.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    lb = UI::LinkButton.new("Docs", "https://docs.example.com")
    lb.accept(v)
    v.visited.should eq(["LinkButton(Docs)"])
  end
end

describe UI::MenuButton do
  it "creates with label" do
    mb = UI::MenuButton.new("Options")
    mb.label.should eq("Options")
    mb.icon.should be_nil
    mb.items.should be_empty
  end

  it "adds items without action" do
    mb = UI::MenuButton.new("Actions")
    mb.add_item("Edit")
    mb.add_item("Delete", is_destructive: true)
    mb.items.size.should eq(2)
    mb.items[0].label.should eq("Edit")
    mb.items[1].is_destructive.should be_true
  end

  it "adds items with action" do
    called = false
    mb = UI::MenuButton.new("Menu")
    mb.add_item("Save") { called = true; nil }
    mb.items[0].action.try(&.call)
    called.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    mb = UI::MenuButton.new("Share")
    mb.accept(v)
    v.visited.should eq(["MenuButton(Share)"])
  end
end

{% if flag?(:macos) || flag?(:ios) %}
  describe UI::ContextMenu do
    it "builds ordered menu items and separators" do
      menu = UI::ContextMenu.new
      menu.add_item("Duplicate", icon: "square.on.square")
      menu.add_separator
      menu.add_item("Delete", icon: "trash", is_destructive: true)

      menu.items.size.should eq(3)
      menu.items[0].should be_a(UI::ContextMenu::Item)
      menu.items[1].should be_a(UI::ContextMenu::Separator)
      destructive = menu.items[2].as(UI::ContextMenu::Item)
      destructive.label.should eq("Delete")
      destructive.is_destructive.should be_true
    end

    it "accepts visitor" do
      v = TestVisitor.new
      menu = UI::ContextMenu.new
      menu.add_item("Share", icon: "square.and.arrow.up")
      menu.add_separator
      menu.add_item("Delete", icon: "trash", is_destructive: true)
      menu.accept(v)
      v.visited.should eq(["ContextMenu(3)"])
    end
  end
{% end %}

describe UI::ToggleButton do
  it "creates with defaults" do
    tb = UI::ToggleButton.new("Bold")
    tb.label.should eq("Bold")
    tb.is_selected.should be_false
    tb.icon.should be_nil
    tb.on_toggle.should be_nil
  end

  it "creates with initial state" do
    tb = UI::ToggleButton.new("Italic", true)
    tb.is_selected.should be_true
  end

  it "toggles state" do
    tb = UI::ToggleButton.new("Toggle", false)
    tb.toggle
    tb.is_selected.should be_true
    tb.toggle
    tb.is_selected.should be_false
  end

  it "creates with callback" do
    received = false
    tb = UI::ToggleButton.new("Bold", false) { |val| received = val; nil }
    tb.on_toggle.try(&.call(true))
    received.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    tb = UI::ToggleButton.new("Underline")
    tb.accept(v)
    v.visited.should eq(["ToggleButton(Underline)"])
  end
end

describe UI::TextEditor do
  it "creates with defaults" do
    te = UI::TextEditor.new
    te.text.should eq("")
    te.placeholder.should eq("")
    te.is_editable.should be_true
    te.shows_line_numbers.should be_false
    te.syntax_highlighting.should be_nil
    te.on_change.should be_nil
  end

  it "creates with placeholder" do
    te = UI::TextEditor.new("Write code here...")
    te.placeholder.should eq("Write code here...")
  end

  it "sets text and properties" do
    te = UI::TextEditor.new("# Header")
    te.text = "puts \"hello\""
    te.shows_line_numbers = true
    te.syntax_highlighting = :crystal
    te.text.should eq("puts \"hello\"")
    te.shows_line_numbers.should be_true
    te.syntax_highlighting.should eq(:crystal)
  end

  it "creates with callback" do
    received = ""
    te = UI::TextEditor.new("") { |text| received = text; nil }
    te.on_change.try(&.call("hello world"))
    received.should eq("hello world")
  end

  it "accepts visitor" do
    v = TestVisitor.new
    te = UI::TextEditor.new("Enter code")
    te.accept(v)
    v.visited.should eq(["TextEditor(Enter code)"])
  end
end

# ---------------------------------------------------------------
# P3 Component specs
# ---------------------------------------------------------------

describe UI::Circle do
  it "creates with defaults" do
    c = UI::Circle.new
    c.fill_color.r.should eq(0.0)
    c.fill_color.g.should eq(0.0)
    c.fill_color.b.should eq(0.0)
    c.stroke_color.should be_nil
    c.stroke_width.should eq(0.0)
    c.size.should eq(50.0)
  end

  it "creates with custom size" do
    c = UI::Circle.new(100.0)
    c.size.should eq(100.0)
  end

  it "sets fill color" do
    c = UI::Circle.new
    c.fill_color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
    c.fill_color.r.should eq(1.0)
  end

  it "sets stroke color and width" do
    c = UI::Circle.new
    c.stroke_color = UI::Color.new(r: 0.0, g: 0.0, b: 1.0)
    c.stroke_width = 2.0
    c.stroke_color.not_nil!.b.should eq(1.0)
    c.stroke_width.should eq(2.0)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    c = UI::Circle.new
    c.accept(v)
    v.visited.should eq(["Circle"])
  end
end

describe UI::Rectangle do
  it "creates with defaults" do
    r = UI::Rectangle.new
    r.fill_color.r.should eq(0.0)
    r.stroke_color.should be_nil
    r.stroke_width.should eq(0.0)
    r.width.should eq(100.0)
    r.height.should eq(50.0)
  end

  it "creates with custom dimensions" do
    r = UI::Rectangle.new(200.0, 80.0)
    r.width.should eq(200.0)
    r.height.should eq(80.0)
  end

  it "sets fill color" do
    r = UI::Rectangle.new
    r.fill_color = UI::Color.new(r: 0.0, g: 1.0, b: 0.0)
    r.fill_color.g.should eq(1.0)
  end

  it "sets stroke properties" do
    r = UI::Rectangle.new
    r.stroke_color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
    r.stroke_width = 3.0
    r.stroke_width.should eq(3.0)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    r = UI::Rectangle.new
    r.accept(v)
    v.visited.should eq(["Rectangle"])
  end
end

describe UI::RoundedRectangle do
  it "creates with defaults" do
    rr = UI::RoundedRectangle.new
    rr.fill_color.r.should eq(0.0)
    rr.stroke_color.should be_nil
    rr.stroke_width.should eq(0.0)
    rr.corner_style.should eq(:continuous)
    rr.corner_radius.should eq(8.0)
    rr.width.should eq(100.0)
    rr.height.should eq(50.0)
  end

  it "creates with custom corner radius" do
    rr = UI::RoundedRectangle.new(16.0)
    rr.corner_radius.should eq(16.0)
  end

  it "creates with custom dimensions" do
    rr = UI::RoundedRectangle.new(8.0, 150.0, 60.0)
    rr.width.should eq(150.0)
    rr.height.should eq(60.0)
  end

  it "sets corner style" do
    rr = UI::RoundedRectangle.new
    rr.corner_style = :circular
    rr.corner_style.should eq(:circular)
  end

  it "sets stroke properties" do
    rr = UI::RoundedRectangle.new
    rr.stroke_color = UI::Color.new(r: 0.5, g: 0.5, b: 0.5)
    rr.stroke_width = 1.5
    rr.stroke_width.should eq(1.5)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    rr = UI::RoundedRectangle.new
    rr.accept(v)
    v.visited.should eq(["RoundedRectangle"])
  end
end

describe UI::Capsule do
  it "creates with defaults" do
    c = UI::Capsule.new
    c.fill_color.r.should eq(0.0)
    c.stroke_color.should be_nil
    c.stroke_width.should eq(0.0)
    c.width.should eq(100.0)
    c.height.should eq(40.0)
  end

  it "creates with custom dimensions" do
    c = UI::Capsule.new(160.0, 48.0)
    c.width.should eq(160.0)
    c.height.should eq(48.0)
  end

  it "sets fill color" do
    c = UI::Capsule.new
    c.fill_color = UI::Color.new(r: 0.2, g: 0.6, b: 1.0)
    c.fill_color.b.should eq(1.0)
  end

  it "sets stroke properties" do
    c = UI::Capsule.new
    c.stroke_color = UI::Color.new(r: 0.0, g: 0.0, b: 0.0)
    c.stroke_width = 2.0
    c.stroke_width.should eq(2.0)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    c = UI::Capsule.new
    c.accept(v)
    v.visited.should eq(["Capsule"])
  end
end

describe UI::Canvas do
  it "creates with defaults" do
    c = UI::Canvas.new
    c.width.should eq(300.0)
    c.height.should eq(150.0)
    c.operations.should be_empty
  end

  it "creates with custom dimensions" do
    c = UI::Canvas.new(640.0, 480.0)
    c.width.should eq(640.0)
    c.height.should eq(480.0)
  end

  it "records move_to and line_to operations" do
    c = UI::Canvas.new
    c.move_to(10.0, 20.0)
    c.line_to(100.0, 200.0)
    c.operations.size.should eq(2)
    c.operations[0].command.should eq(UI::DrawCommand::MoveTo)
    c.operations[0].x.should eq(10.0)
    c.operations[0].y.should eq(20.0)
    c.operations[1].command.should eq(UI::DrawCommand::LineTo)
  end

  it "records fill and stroke operations" do
    c = UI::Canvas.new
    red = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
    c.fill(red)
    c.stroke(red)
    ops = c.operations.map(&.command)
    ops.should contain(UI::DrawCommand::Fill)
    ops.should contain(UI::DrawCommand::Stroke)
  end

  it "records begin_path and close_path" do
    c = UI::Canvas.new
    c.begin_path
    c.close_path
    c.operations.size.should eq(2)
    c.operations[0].command.should eq(UI::DrawCommand::BeginPath)
    c.operations[1].command.should eq(UI::DrawCommand::ClosePath)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    c = UI::Canvas.new
    c.accept(v)
    v.visited.should eq(["Canvas"])
  end
end

describe UI::PathView do
  it "creates with defaults" do
    p = UI::PathView.new
    p.segments.should be_empty
    p.fill_color.should be_nil
    p.stroke_color.r.should eq(0.0)
    p.stroke_width.should eq(1.0)
    p.width.should eq(100.0)
    p.height.should eq(100.0)
  end

  it "creates with custom dimensions" do
    p = UI::PathView.new(200.0, 200.0)
    p.width.should eq(200.0)
    p.height.should eq(200.0)
  end

  it "records move_to and line_to segments" do
    p = UI::PathView.new
    p.move_to(0.0, 0.0)
    p.line_to(50.0, 50.0)
    p.segments.size.should eq(2)
    p.segments[0].command.should eq(UI::PathCommand::MoveTo)
    p.segments[1].command.should eq(UI::PathCommand::LineTo)
    p.segments[1].x.should eq(50.0)
    p.segments[1].y.should eq(50.0)
  end

  it "records curve_to segment" do
    p = UI::PathView.new
    p.move_to(0.0, 0.0)
    p.curve_to(100.0, 0.0, 0.0, 50.0, 100.0, 50.0)
    p.segments[1].command.should eq(UI::PathCommand::CurveTo)
  end

  it "records close segment" do
    p = UI::PathView.new
    p.move_to(0.0, 0.0)
    p.line_to(10.0, 10.0)
    p.close
    p.segments.last.command.should eq(UI::PathCommand::Close)
  end

  it "generates svg path string from to_svg_path" do
    p = UI::PathView.new
    p.move_to(0.0, 0.0)
    p.line_to(50.0, 50.0)
    p.close
    svg = p.to_svg_path
    svg.should contain("M")
    svg.should contain("L")
    svg.should contain("Z")
  end

  it "accepts visitor" do
    v = TestVisitor.new
    p = UI::PathView.new
    p.accept(v)
    v.visited.should eq(["PathView"])
  end
end

{% if flag?(:macos) %}
  describe UI::PathControl do
    it "builds a filesystem path string from components" do
      control = UI::PathControl.new
      control.add_component("Users", icon: "folder")
      control.add_component("amber", icon: "person")
      control.add_component("Drafts", icon: "doc")

      control.path_string.should eq("/Users/amber/Drafts")
      control.style.should eq(UI::PathControlStyle::Standard)
      control.is_editable.should be_false
    end

    it "supports popup style" do
      control = UI::PathControl.new(style: UI::PathControlStyle::PopUp)
      control.add_component("Assets", icon: "folder")
      control.style.should eq(UI::PathControlStyle::PopUp)
    end

    it "accepts visitor" do
      v = TestVisitor.new
      control = UI::PathControl.new
      control.add_component("Library", icon: "folder")
      control.add_component("Design", icon: "paintbrush")
      control.accept(v)
      v.visited.should eq(["PathControl(/Library/Design)"])
    end
  end
{% end %}

describe UI::OutlineView do
  it "stores hierarchical nodes" do
    inbox = UI::OutlineView::Node.new("Inbox")
    inbox.add_child(UI::OutlineView::Node.new("Today"))
    inbox.add_child(UI::OutlineView::Node.new("Scheduled"))

    projects = UI::OutlineView::Node.new("Projects", expanded: true)
    projects.add_child(UI::OutlineView::Node.new("Amber"))

    outline = UI::OutlineView.new([inbox, projects])

    outline.roots.size.should eq(2)
    outline.node_count.should eq(5)
    outline.roots[0].children.size.should eq(2)
  end

  it "builds a scrollable fallback tree" do
    root = UI::OutlineView::Node.new("Library", icon: "folder", expanded: true)
    root.add_child(UI::OutlineView::Node.new("Notes", icon: "note.text"))

    outline = UI::OutlineView.new([root])
    outline.minimum_width = 320.0
    outline.viewport_height = 280.0

    fallback = outline.fallback_view
    fallback.should be_a(UI::ScrollView)

    scroll = fallback.as(UI::ScrollView)
    scroll.frame_width.should eq(320.0)
    scroll.frame_height.should eq(280.0)
    scroll.content.should be_a(UI::VStack)
  end

  it "accepts visitor" do
    outline = UI::OutlineView.new
    outline.add_root(UI::OutlineView::Node.new("Inbox"))

    visitor = TestVisitor.new
    outline.accept(visitor)
    visitor.visited.should eq(["OutlineView(1)"])
  end
end

describe UI::ColumnView do
  it "stores nested drill-down items and widths" do
    library = UI::ColumnView::Item.new("Library")
    docs = UI::ColumnView::Item.new("Documents")
    docs.add_child(UI::ColumnView::Item.new("Design"))
    docs.add_child(UI::ColumnView::Item.new("Specs"))

    projects = UI::ColumnView::Item.new("Projects")
    projects.add_child(UI::ColumnView::Item.new("Amber"))

    view = UI::ColumnView.new([library, docs, projects])
    view.selected_indexes = [1, 0]
    view.column_widths = [240.0, 268.0]

    view.item_count.should eq(6)
    view.column_count.should eq(2)
    view.selected_path.should eq([1, 0])
    view.items[1].branch?.should be_true
  end

  it "builds a scrollable browser-like fallback surface" do
    root = UI::ColumnView::Item.new("Library", "folder")
    root.add_child(UI::ColumnView::Item.new("Design", "folder"))

    view = UI::ColumnView.new([root])
    view.selected_indexes = [0]
    view.minimum_width = 320.0
    view.viewport_height = 260.0

    fallback = view.fallback_view
    fallback.should be_a(UI::ScrollView)

    scroll = fallback.as(UI::ScrollView)
    scroll.scroll_horizontal.should be_true
    scroll.scroll_vertical.should be_false
    scroll.frame_width.should eq(320.0)
    scroll.frame_height.should eq(260.0)
    scroll.content.should be_a(UI::HStack)

    stack = scroll.content.as(UI::HStack)
    stack.children.size.should eq(2)
    stack.children.first.should be_a(UI::VStack)
  end

  it "accepts visitor" do
    view = UI::ColumnView.new([UI::ColumnView::Item.new("Library")])

    visitor = TestVisitor.new
    view.accept(visitor)
    visitor.visited.should eq(["ColumnView(1)"])
  end
end

describe UI::TokenField do
  it "stores tokens, placeholder, and selection state" do
    ada = UI::TokenField::Token.new("Ada", "person", "Lead")
    grace = UI::TokenField::Token.new("Grace", "person")

    view = UI::TokenField.new([ada, grace], "Add recipient", "Recipients", "Type a name or email")
    view.selected_indexes = [1]

    view.token_count.should eq(2)
    view.placeholder.should eq("Add recipient")
    view.label.should eq("Recipients")
    view.prompt.should eq("Type a name or email")
    view.selected_tokens.map(&.title).should eq(["Grace"])
    view.tokens[0].branch?.should be_false
  end

  it "builds a pill-entry fallback surface" do
    view = UI::TokenField.new(
      [UI::TokenField::Token.new("Ada", "person"), UI::TokenField::Token.new("Grace")],
      "Add person",
      "Recipients",
      "Type to search by name or email"
    )
    view.selected_indexes = [0]
    view.minimum_width = 360.0

    fallback = view.fallback_view
    fallback.should be_a(UI::Card)

    card = fallback.as(UI::Card)
    body = card.content.as(UI::VStack)
    body.children.size.should eq(3)
    body.children[0].should be_a(UI::Label)
    body.children[1].should be_a(UI::Label)

    tray = body.children[2].as(UI::HStack)
    tray.children.size.should eq(3)
    tray.children[0].should be_a(UI::HStack)
    tray.children[2].should be_a(UI::TextField)
  end

  it "accepts visitor" do
    view = UI::TokenField.new([UI::TokenField::Token.new("Ada")])

    visitor = TestVisitor.new
    view.accept(visitor)
    visitor.visited.should eq(["TokenField(1)"])
  end
end

describe UI::ImageWell do
  it "stores preview and text metadata" do
    well = UI::ImageWell.new(
      "portrait-amber",
      "Profile image",
      "Drag a new image here",
      "Square preview, 512px or larger",
      "PNG, JPEG, or HEIC works best"
    )
    well.placeholder_icon.should eq("photo")
    well.has_image?.should be_true
    well.label.should eq("Profile image")
    well.prompt.should eq("Drag a new image here")
    well.caption.should eq("Square preview, 512px or larger")
    well.help_text.should eq("PNG, JPEG, or HEIC works best")
  end

  it "builds a bordered fallback well surface" do
    well = UI::ImageWell.new(
      nil,
      "Cover image",
      "Drop a file or click to choose",
      "A square crop is recommended",
      "JPEG, PNG, or HEIC"
    )
    well.well_width = 264.0
    well.well_height = 196.0

    fallback = well.fallback_view
    fallback.should be_a(UI::Card)

    card = fallback.as(UI::Card)
    body = card.content.as(UI::VStack)
    body.children.size.should eq(5)
    body.children[0].should be_a(UI::Label)
    body.children[1].should be_a(UI::Label)
    body.children[2].should be_a(UI::VStack)

    preview = body.children[2].as(UI::VStack)
    preview.minimum_width.should eq(264.0)
    preview.maximum_height.should eq(196.0)
    preview.children.size.should eq(1)

    preview_stack = preview.children[0].as(UI::VStack)
    preview_stack.children.size.should eq(1)
    preview_stack.children[0].should be_a(UI::Image)
  end

  it "accepts visitor" do
    well = UI::ImageWell.new("portrait-amber")

    visitor = TestVisitor.new
    well.accept(visitor)
    visitor.visited.should eq(["ImageWell(true)"])
  end
end

describe UI::Panel do
  it "stores title, supporting copy, and footer actions" do
    body = UI::VStack.new
    body << UI::Toggle.new("Show line numbers", true).as(UI::View)

    footer = UI::Label.new("Panels should stay concise and task-focused.")
    panel = UI::Panel.new(
      "Inspector",
      body.as(UI::View),
      "Editing Markdown",
      "Changes apply to the selected document.",
      footer.as(UI::View),
      UI::PanelStyle::Inspector
    )
    panel.preferred_width = 304.0
    panel.add_action(UI::Button.new("Cancel", role: :cancel))
    panel.add_action(UI::Button.new("Apply", style: UI::ButtonStyle::Prominent))

    panel.title.should eq("Inspector")
    panel.subtitle.should eq("Editing Markdown")
    panel.auxiliary_text.should eq("Changes apply to the selected document.")
    panel.footer.should eq(footer)
    panel.action_count.should eq(2)
    panel.style.should eq(UI::PanelStyle::Inspector)
  end

  it "builds a composed fallback surface" do
    content = UI::VStack.new(spacing: 10.0, alignment: UI::Alignment::Fill)
    content << UI::TextField.new("Search tools").as(UI::View)

    footer = UI::Label.new("Shown while a selection is active.")
    panel = UI::Panel.new(
      "Selection",
      content.as(UI::View),
      "Quick actions",
      "A compact auxiliary surface.",
      footer.as(UI::View),
      UI::PanelStyle::Compact
    )
    panel.add_action(UI::Button.new("Done", style: UI::ButtonStyle::Prominent))
    panel.preferred_width = 280.0

    fallback = panel.fallback_view
    fallback.should be_a(UI::Card)

    card = fallback.as(UI::Card)
    card.minimum_width.should eq(280.0)
    card.maximum_width.should eq(280.0)

    body = card.content.as(UI::VStack)
    body.children.size.should eq(5)
    body.children[0].should be_a(UI::VStack)
    body.children[1].should be_a(UI::Divider)
    body.children[2].should eq(content)
    body.children[3].should be_a(UI::Divider)
    body.children[4].should be_a(UI::VStack)

    header = body.children[0].as(UI::VStack)
    header.children.size.should eq(3)
    header.children[0].as(UI::Label).text.should eq("Selection")

    footer_area = body.children[4].as(UI::VStack)
    footer_area.children.size.should eq(2)
    footer_area.children[0].should eq(footer)
    footer_area.children[1].should be_a(UI::HStack)
  end

  it "accepts visitor" do
    panel = UI::Panel.new("Inspector")
    panel.add_action(UI::Button.new("Done"))

    visitor = TestVisitor.new
    panel.accept(visitor)
    visitor.visited.should eq(["Panel(Inspector/1)"])
  end
end

describe UI::Gauge do
  it "stores range and label metadata" do
    gauge = UI::Gauge.new(72.0, 0.0, 100.0, "Disk usage", "Live capacity", "Keep under 80%", "Used capacity")
    gauge.units.should eq("%")
    gauge.value_precision.should eq(0)
    gauge.label.should eq("Disk usage")
    gauge.prompt.should eq("Live capacity")
    gauge.caption.should eq("Keep under 80%")
    gauge.help_text.should eq("Used capacity")
    gauge.normalized_value.should eq(72.0)
    gauge.progress_fraction.should eq(0.72)
    gauge.display_value.should eq("72%")
  end

  it "builds a canvas-driven fallback surface" do
    gauge = UI::Gauge.new(40.0, 0.0, 100.0, "CPU", "Current load", "Average across all cores", "Running")
    gauge.diameter = 192.0
    gauge.ring_thickness = 14.0

    fallback = gauge.fallback_view
    fallback.should be_a(UI::Card)

    card = fallback.as(UI::Card)
    body = card.content.as(UI::VStack)
    body.children.size.should eq(5)
    body.children[0].should be_a(UI::Label)
    body.children[1].should be_a(UI::Label)
    body.children[2].should be_a(UI::ZStack)
    body.children[3].should be_a(UI::Label)
    body.children[4].should be_a(UI::Label)

    stage = body.children[2].as(UI::ZStack)
    stage.children.size.should eq(2)

    canvas = stage.children[0].as(UI::Canvas)
    canvas.width.should eq(192.0)
    canvas.height.should eq(192.0)
    canvas.operations.map(&.command).should contain(UI::DrawCommand::Arc)
    canvas.operations.map(&.command).should contain(UI::DrawCommand::Stroke)

    overlay = stage.children[1].as(UI::VStack)
    overlay.children.size.should eq(1)
    overlay.children[0].as(UI::Label).text.should eq("40%")
  end

  it "accepts visitor" do
    gauge = UI::Gauge.new(55.0)

    visitor = TestVisitor.new
    gauge.accept(visitor)
    visitor.visited.should eq(["Gauge(55.0)"])
  end
end

describe UI::ActivityRing do
  it "stores range and label metadata" do
    ring = UI::ActivityRing.new(54.0, 0.0, 100.0, "Move", "Today", "Close the ring", "Progress ring")
    ring.units.should eq("%")
    ring.value_precision.should eq(0)
    ring.label.should eq("Move")
    ring.prompt.should eq("Today")
    ring.caption.should eq("Close the ring")
    ring.help_text.should eq("Progress ring")
    ring.normalized_value.should eq(54.0)
    ring.progress_fraction.should eq(0.54)
    ring.display_value.should eq("54%")
  end

  it "builds a canvas-driven fallback surface" do
    ring = UI::ActivityRing.new(88.0, 0.0, 100.0, "Activity", "Daily goal", "A friendly ring readout", "Finish the day strong")
    ring.diameter = 184.0
    ring.ring_thickness = 16.0

    fallback = ring.fallback_view
    fallback.should be_a(UI::Card)

    card = fallback.as(UI::Card)
    body = card.content.as(UI::VStack)
    body.children.size.should eq(5)
    body.children[0].should be_a(UI::Label)
    body.children[1].should be_a(UI::Label)
    body.children[2].should be_a(UI::ZStack)
    body.children[3].should be_a(UI::Label)
    body.children[4].should be_a(UI::Label)

    stage = body.children[2].as(UI::ZStack)
    stage.children.size.should eq(2)

    canvas = stage.children[0].as(UI::Canvas)
    canvas.width.should eq(184.0)
    canvas.height.should eq(184.0)
    canvas.operations.map(&.command).should contain(UI::DrawCommand::Arc)
    canvas.operations.map(&.command).should contain(UI::DrawCommand::Stroke)

    overlay = stage.children[1].as(UI::VStack)
    overlay.children.size.should eq(1)
    overlay.children[0].as(UI::Label).text.should eq("88%")
  end

  it "accepts visitor" do
    ring = UI::ActivityRing.new(42.0)

    visitor = TestVisitor.new
    ring.accept(visitor)
    visitor.visited.should eq(["ActivityRing(42.0)"])
  end
end

describe UI::ActivityRings do
  it "clamps ring fractions" do
    rings = UI::ActivityRings.new(-0.25, 1.25, 0.5)
    rings.move_fraction.should eq(0.0)
    rings.exercise_fraction.should eq(1.0)
    rings.stand_fraction.should eq(0.5)
  end

  it "builds a three-ring fallback surface" do
    rings = UI::ActivityRings.new(0.71, 0.48, 0.93)
    rings.size = 200.0
    rings.thickness = 15.0
    rings.gap = 5.0

    fallback = rings.fallback_view
    fallback.should be_a(UI::ZStack)

    stage = fallback.as(UI::ZStack)
    stage.children.size.should eq(4)
    stage.children[0].should be_a(UI::Circle)
    stage.children[1].should be_a(UI::Canvas)
    stage.children[2].should be_a(UI::Canvas)
    stage.children[3].should be_a(UI::Canvas)

    move_canvas = stage.children[1].as(UI::Canvas)
    move_canvas.operations.size.should eq(10)
    move_canvas.operations.map(&.command).should eq([
      UI::DrawCommand::BeginPath,
      UI::DrawCommand::Arc,
      UI::DrawCommand::SetStrokeColor,
      UI::DrawCommand::SetLineWidth,
      UI::DrawCommand::Stroke,
      UI::DrawCommand::BeginPath,
      UI::DrawCommand::Arc,
      UI::DrawCommand::SetStrokeColor,
      UI::DrawCommand::SetLineWidth,
      UI::DrawCommand::Stroke,
    ])
    move_canvas.operations[1].radius.should be > 0.0
    move_canvas.operations[6].end_angle.should be > move_canvas.operations[6].start_angle
  end

  it "accepts visitor" do
    rings = UI::ActivityRings.new(0.3, 0.5, 0.7)

    visitor = TestVisitor.new
    rings.accept(visitor)
    visitor.visited.should eq(["ActivityRings(0.3/0.5/0.7)"])
  end
end

describe UI::ActivityView do
  it "creates with share defaults" do
    view = UI::ActivityView.new("Shared note")
    view.is_presented.should be_false
    view.share_text.should be_nil
    view.share_url.should be_nil
    view.share_subject.should be_nil
    view.destinations.should be_empty
    view.actions.should be_empty
  end

  it "stores native share payload and callbacks" do
    canceled = false

    view = UI::ActivityView.new("Shared note", subtitle: "Draft")
    view.share_text = "Look at this"
    view.share_url = "https://amber.local/share/42"
    view.share_subject = "Amber share"
    view.on_cancel = -> { canceled = true }

    view.share_text.should eq("Look at this")
    view.share_url.should eq("https://amber.local/share/42")
    view.share_subject.should eq("Amber share")

    view.on_cancel.not_nil!.call
    canceled.should be_true
  end

  it "tracks presentation state with a presenter" do
    view = UI::ActivityView.new("Shared note")
    presenter = UI::ActivityViewPresenter.new(view)

    presenter.present
    presenter.is_presenting.should be_true
    view.is_presented.should be_true

    presenter.dismiss
    presenter.is_presenting.should be_false
    view.is_presented.should be_false
  end

  it "accepts visitor" do
    v = TestVisitor.new
    view = UI::ActivityView.new("Shared note")
    view.accept(v)
    v.visited.should eq(["ActivityView"])
  end
end

describe UI::MapView do
  it "creates with defaults" do
    m = UI::MapView.new
    m.latitude.should eq(0.0)
    m.longitude.should eq(0.0)
    m.zoom_level.should eq(10.0)
    m.map_type.should eq(:standard)
    m.shows_user_location.should be_false
    m.annotations.should be_empty
  end

  it "sets coordinates" do
    m = UI::MapView.new
    m.latitude = 37.7749
    m.longitude = -122.4194
    m.latitude.should be_close(37.7749, 0.0001)
    m.longitude.should be_close(-122.4194, 0.0001)
  end

  it "sets map type" do
    m = UI::MapView.new
    m.map_type = :satellite
    m.map_type.should eq(:satellite)
  end

  it "adds annotations" do
    m = UI::MapView.new
    ann = UI::MapAnnotation.new(
      latitude: 37.7749, longitude: -122.4194,
      title: "San Francisco")
    m.annotations << ann
    m.annotations.size.should eq(1)
    m.annotations[0].title.should eq("San Francisco")
  end

  it "sets shows_user_location" do
    m = UI::MapView.new
    m.shows_user_location = true
    m.shows_user_location.should be_true
  end

  it "accepts visitor" do
    v = TestVisitor.new
    m = UI::MapView.new
    m.accept(v)
    v.visited.should eq(["MapView"])
  end
end

describe UI::ChartView do
  it "creates with defaults" do
    c = UI::ChartView.new
    c.chart_type.should eq(:bar)
    c.title.should eq("")
    c.data_points.should be_empty
    c.show_legend.should be_true
    c.show_grid.should be_true
  end

  it "sets chart type" do
    c = UI::ChartView.new
    c.chart_type = :line
    c.chart_type.should eq(:line)
  end

  it "sets title" do
    c = UI::ChartView.new
    c.title = "Monthly Revenue"
    c.title.should eq("Monthly Revenue")
  end

  it "adds data points" do
    c = UI::ChartView.new
    dp = UI::ChartDataPoint.new(label: "Jan", value: 1200.0)
    c.data_points << dp
    c.data_points.size.should eq(1)
    c.data_points[0].label.should eq("Jan")
    c.data_points[0].value.should eq(1200.0)
  end

  it "sets show_legend and show_grid" do
    c = UI::ChartView.new
    c.show_legend = false
    c.show_grid = false
    c.show_legend.should be_false
    c.show_grid.should be_false
  end

  it "accepts visitor" do
    v = TestVisitor.new
    c = UI::ChartView.new
    c.accept(v)
    v.visited.should eq(["ChartView"])
  end
end

describe UI::WebViewComponent do
  it "creates with defaults" do
    w = UI::WebViewComponent.new
    w.url.should eq("")
    w.html.should be_nil
    w.base_url.should be_nil
    w.allows_navigation.should be_true
    w.allows_scripts.should be_true
    w.title.should be_nil
    w.on_navigation_request.should be_nil
    w.on_navigation_start.should be_nil
    w.on_navigation_finish.should be_nil
  end

  it "creates with url" do
    w = UI::WebViewComponent.new("https://example.com")
    w.url.should eq("https://example.com")
  end

  it "sets allows_navigation" do
    w = UI::WebViewComponent.new
    w.allows_navigation = false
    w.allows_navigation.should be_false
  end

  it "sets allows_scripts" do
    w = UI::WebViewComponent.new
    w.allows_scripts = false
    w.allows_scripts.should be_false
  end

  it "sets title" do
    w = UI::WebViewComponent.new
    w.title = "My Web View"
    w.title.should eq("My Web View")
  end

  it "supports embedded html and a base url" do
    w = UI::WebViewComponent.new
    w.html = "<html><body>Hello</body></html>"
    w.base_url = "https://example.com"
    w.html.should eq("<html><body>Hello</body></html>")
    w.base_url.should eq("https://example.com")
  end

  it "stores navigation callbacks" do
    requested = [] of String
    started = [] of String
    finished = [] of String

    w = UI::WebViewComponent.new
    w.on_navigation_request = ->(url : String) do
      requested << url
      !url.includes?("blocked")
    end
    w.on_navigation_start = ->(url : String) do
      started << url
      nil
    end
    w.on_navigation_finish = ->(url : String) do
      finished << url
      nil
    end

    w.on_navigation_request.not_nil!.call("https://amber.local/review").should be_true
    w.on_navigation_start.not_nil!.call("https://amber.local/review")
    w.on_navigation_finish.not_nil!.call("https://amber.local/review")

    requested.should eq(["https://amber.local/review"])
    started.should eq(["https://amber.local/review"])
    finished.should eq(["https://amber.local/review"])
  end

  it "accepts visitor" do
    v = TestVisitor.new
    w = UI::WebViewComponent.new
    w.accept(v)
    v.visited.should eq(["WebViewComponent"])
  end
end

describe UI::ColorPicker do
  it "creates with defaults" do
    cp = UI::ColorPicker.new
    cp.selected_color.r.should eq(0.0)
    cp.selected_color.g.should eq(0.0)
    cp.selected_color.b.should eq(0.0)
    cp.on_change.should be_nil
    cp.label.should eq("")
    cp.supports_alpha.should be_false
  end

  it "sets selected color" do
    cp = UI::ColorPicker.new
    cp.selected_color = UI::Color.new(r: 1.0, g: 0.5, b: 0.0)
    cp.selected_color.r.should eq(1.0)
    cp.selected_color.g.should eq(0.5)
  end

  it "sets label" do
    cp = UI::ColorPicker.new
    cp.label = "Background Color"
    cp.label.should eq("Background Color")
  end

  it "sets supports_alpha" do
    cp = UI::ColorPicker.new
    cp.supports_alpha = true
    cp.supports_alpha.should be_true
  end

  it "fires on_change callback" do
    cp = UI::ColorPicker.new
    received : UI::Color? = nil
    cp.on_change = ->(c : UI::Color) { received = c; nil }
    new_color = UI::Color.new(r: 0.0, g: 0.0, b: 1.0)
    cp.on_change.not_nil!.call(new_color)
    received.not_nil!.b.should eq(1.0)
  end

  it "accepts visitor" do
    v = TestVisitor.new
    cp = UI::ColorPicker.new
    cp.accept(v)
    v.visited.should eq(["ColorPicker"])
  end
end

describe UI::VideoPlayer do
  it "creates with defaults" do
    vp = UI::VideoPlayer.new
    vp.url.should eq("")
    vp.is_playing.should be_false
    vp.shows_controls.should be_true
    vp.auto_play.should be_false
    vp.muted.should be_false
    vp.loop.should be_false
    vp.poster_url.should be_nil
  end

  it "creates with url" do
    vp = UI::VideoPlayer.new("https://example.com/video.mp4")
    vp.url.should eq("https://example.com/video.mp4")
  end

  it "sets auto_play" do
    vp = UI::VideoPlayer.new
    vp.auto_play = true
    vp.auto_play.should be_true
  end

  it "sets muted" do
    vp = UI::VideoPlayer.new
    vp.muted = true
    vp.muted.should be_true
  end

  it "sets loop" do
    vp = UI::VideoPlayer.new
    vp.loop = true
    vp.loop.should be_true
  end

  it "sets poster_url" do
    vp = UI::VideoPlayer.new
    vp.poster_url = "https://example.com/poster.jpg"
    vp.poster_url.should eq("https://example.com/poster.jpg")
  end

  it "accepts visitor" do
    v = TestVisitor.new
    vp = UI::VideoPlayer.new
    vp.accept(v)
    v.visited.should eq(["VideoPlayer"])
  end
end

describe UI::Tooltip do
  it "creates with defaults" do
    t = UI::Tooltip.new
    t.text.should eq("")
    t.content.should be_nil
    t.position.should eq(:top)
    t.delay.should eq(0.5)
    t.is_visible.should be_false
  end

  it "creates with text" do
    t = UI::Tooltip.new("Helpful tip")
    t.text.should eq("Helpful tip")
  end

  it "sets position" do
    t = UI::Tooltip.new
    t.position = :bottom
    t.position.should eq(:bottom)
  end

  it "sets delay" do
    t = UI::Tooltip.new
    t.delay = 1.0
    t.delay.should eq(1.0)
  end

  it "sets is_visible" do
    t = UI::Tooltip.new
    t.is_visible = true
    t.is_visible.should be_true
  end

  it "sets content view" do
    t = UI::Tooltip.new("tip")
    label = UI::Label.new("content")
    t.content = label
    t.content.should_not be_nil
  end

  it "accepts visitor" do
    v = TestVisitor.new
    t = UI::Tooltip.new("Hello")
    t.accept(v)
    v.visited.should eq(["Tooltip"])
  end
end

# ---------------------------------------------------------------
# Theme specs
# ---------------------------------------------------------------

describe UI::Theme do
  it "creates with defaults" do
    theme = UI::Theme.new
    theme.primary.r.should be_close(0.0, 0.01)
    theme.font_family.should eq("system")
    theme.font_size_body.should eq(16.0)
    theme.corner_radius_medium.should eq(8.0)
  end

  it "creates apple_default" do
    theme = UI::Theme.apple_default
    theme.font_family.should eq("-apple-system")
    theme.font_size_body.should eq(17.0)
    theme.corner_radius_large.should eq(20.0)
  end

  it "creates material_baseline" do
    theme = UI::Theme.material_baseline
    theme.font_family.should eq("Roboto")
    theme.font_size_body.should eq(16.0)
    theme.corner_radius_large.should eq(28.0)
  end

  it "generates CSS custom properties" do
    theme = UI::Theme.apple_default
    css = theme.to_css_custom_properties
    css.should contain(":root")
    css.should contain("--md-sys-color-primary")
    css.should contain("--md-sys-typescale-body-font")
    css.should contain("--md-sys-shape-corner-medium")
  end

  it "CSS contains rgba color values" do
    theme = UI::Theme.new
    css = theme.to_css_custom_properties
    css.should contain("rgba(")
  end

  it "web renderer inject_theme_css uses the design-system default with no theme" do
    renderer = UI::Web::Renderer.new
    css = renderer.inject_theme_css
    css.should contain("<style>")
    css.should contain(":root")
  end

  it "web renderer inject_theme_css returns style block with theme" do
    renderer = UI::Web::Renderer.new
    renderer.theme = UI::Theme.apple_default
    css = renderer.inject_theme_css
    css.should contain("<style>")
    css.should contain(":root")
    css.should contain("--md-sys-color-primary")
  end
end

describe "test_id property" do
  it "defaults to nil" do
    label = UI::Label.new("Hello")
    label.test_id.should be_nil
  end

  it "can be set on a view" do
    label = UI::Label.new("Hello")
    label.test_id = "login_label"
    label.test_id.should eq("login_label")
  end

  it "can be set on any view type" do
    btn = UI::Button.new("Submit")
    btn.test_id = "submit_button"
    btn.test_id.should eq("submit_button")

    stack = UI::VStack.new
    stack.test_id = "main_container"
    stack.test_id.should eq("main_container")
  end

  it "web renderer emits data-testid attribute" do
    label = UI::Label.new("Hello")
    label.test_id = "greeting_label"
    renderer = UI::Web::Renderer.new
    html = renderer.render(label)
    html.should contain("data-testid=\"greeting_label\"")
  end

  it "web renderer omits data-testid when test_id is nil" do
    label = UI::Label.new("Hello")
    renderer = UI::Web::Renderer.new
    html = renderer.render(label)
    html.should_not contain("data-testid")
  end
end
