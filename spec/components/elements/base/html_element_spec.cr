require "../../../spec_helper"
require "../../../../src/components/elements/base/html_element"
require "../../../../src/components/elements/base/void_element"
require "../../../../src/components/elements/base/container_element"

# Test implementations
class TestVoidElement < Components::Elements::VoidElement
  def initialize(**attrs)
    super("test-void", **attrs)
  end
end

class TestContainerElement < Components::Elements::ContainerElement
  def initialize(**attrs)
    super("test-container", **attrs)
  end
end

describe Components::Elements::HTMLElement do
  describe "attribute management" do
    it "sets attributes during initialization" do
      element = TestContainerElement.new(id: "test", class: "foo bar")
      element["id"].should eq("test")
      element["class"].should eq("foo bar")
    end
    
    it "sets and gets attributes" do
      element = TestContainerElement.new
      element.set_attribute("data-test", "value")
      element["data-test"].should eq("value")
    end
    
    it "removes attributes" do
      element = TestContainerElement.new(id: "test")
      element.remove_attribute("id")
      element["id"].should be_nil
    end
    
    it "validates ID attributes" do
      element = TestContainerElement.new
      
      expect_raises(ArgumentError, "ID cannot be empty") do
        element.set_attribute("id", "")
      end
      
      expect_raises(ArgumentError, "ID cannot contain spaces") do
        element.set_attribute("id", "test id")
      end
    end
    
    it "validates tabindex attributes" do
      element = TestContainerElement.new
      
      element.set_attribute("tabindex", "0")
      element["tabindex"].should eq("0")
      
      element.set_attribute("tabindex", "-1")
      element["tabindex"].should eq("-1")
      
      expect_raises(ArgumentError, "tabindex must be an integer") do
        element.set_attribute("tabindex", "abc")
      end
    end
  end
  
  describe "class management" do
    it "adds classes" do
      element = TestContainerElement.new
      element.add_class("foo bar")
      element["class"].should eq("foo bar")
      
      element.add_class("baz")
      element["class"].should eq("foo bar baz")
    end
    
    it "prevents duplicate classes" do
      element = TestContainerElement.new
      element.add_class("foo bar")
      element.add_class("foo baz")
      element["class"].should eq("foo bar baz")
    end
    
    it "removes classes" do
      element = TestContainerElement.new(class: "foo bar baz")
      element.remove_class("bar")
      element["class"].should eq("foo baz")
      
      element.remove_class("foo baz")
      element["class"].should be_nil
    end
    
    it "checks for specific classes" do
      element = TestContainerElement.new(class: "foo bar")
      element.has_class?("foo").should be_true
      element.has_class?("bar").should be_true
      element.has_class?("baz").should be_false
    end
  end
  
  describe "style management" do
    it "adds styles" do
      element = TestContainerElement.new
      element.add_style("color: red")
      element["style"].should eq("color: red")
      
      element.add_style("font-size: 14px")
      element["style"].should eq("color: red; font-size: 14px")
    end
  end
  
  describe "rendering" do
    it "escapes attribute values" do
      element = TestContainerElement.new(title: "Test \"Quote\" & <Tag>")
      element.render.should contain("title=\"Test &quot;Quote&quot; &amp; &lt;Tag&gt;\"")
    end
    
    it "escapes HTML content" do
      element = TestContainerElement.new
      element << "<script>alert('XSS')</script>"
      element.render.should contain("&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;")
    end
  end
end

describe Components::Elements::VoidElement do
  it "renders as self-closing tag" do
    element = TestVoidElement.new(id: "test")
    element.render.should eq("<test-void id=\"test\">")
  end
  
  it "cannot have children" do
    element = TestVoidElement.new
    
    expect_raises(ArgumentError, "Void element <test-void> cannot have children") do
      element << "content"
    end
    
    expect_raises(ArgumentError, "Void element <test-void> cannot have children") do
      element.add_child("content")
    end
  end
  
  it "reports as void element" do
    element = TestVoidElement.new
    element.void_element?.should be_true
    element.can_have_children?.should be_false
  end
end

describe Components::Elements::ContainerElement do
  it "renders with opening and closing tags" do
    element = TestContainerElement.new(id: "test")
    element.render.should eq("<test-container id=\"test\"></test-container>")
  end
  
  it "adds and renders children" do
    element = TestContainerElement.new
    element << "Hello"
    element << TestContainerElement.new(class: "nested")
    
    rendered = element.render
    rendered.should contain("Hello")
    rendered.should contain("<test-container class=\"nested\">")
  end
  
  it "supports method chaining" do
    element = TestContainerElement.new
      .set_attribute("id", "test")
      .add_class("foo")
      .add_style("color: red")
    element << "Content"
    
    element["id"].should eq("test")
    element["class"].should eq("foo")
    element["style"].should eq("color: red")
    element.children_count.should eq(1)
  end
  
  it "builds content with blocks" do
    element = TestContainerElement.new.build do |e|
      e << "Line 1"
      e << TestContainerElement.new(class: "nested")
      e << "Line 2"
    end
    
    element.children_count.should eq(3)
  end
  
  it "can be initialized and have content added" do
    element = TestContainerElement.new(id: "test")
    element << "Hello World"
    element.children_count.should eq(1)
    element.render.should eq("<test-container id=\"test\">Hello World</test-container>")
  end
  
  it "clears children" do
    element = TestContainerElement.new
    element << "One" << "Two" << "Three"
    element.children_count.should eq(3)
    
    element.clear
    element.children_count.should eq(0)
    element.empty?.should be_true
  end
  
  it "reports as container element" do
    element = TestContainerElement.new
    element.void_element?.should be_false
    element.can_have_children?.should be_true
  end
end