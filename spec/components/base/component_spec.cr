require "../../spec_helper"
require "../../../src/components/base/component"
require "../../../src/components/base/stateless_component"
require "../../../src/components/base/stateful_component"
require "../../../src/components/elements/grouping/div"
require "../../../src/components/elements/grouping/p"

# Test component implementations
class TestStatelessComponent < Components::StatelessComponent
  def render_content : String
    title = @attributes["title"]? || "Default"
    
    div = Components::Elements::Div.new(class: "test-component")
    div << title
    
    # Add children if any
    @children.each do |child|
      case child
      when Components::Component
        div << child.render
      when Components::Elements::HTMLElement
        div << child
      when String
        div << child
      end
    end
    
    div.render
  end
end

class TestStatefulComponent < Components::StatefulComponent
  protected def initialize_state
    set_state("clicks", 0)
  end
  
  def click
    count = get_state("clicks").try(&.as_i?) || 0
    set_state("clicks", count + 1)
  end
  
  def render_content : String
    clicks = get_state("clicks").try(&.as_i?) || 0
    
    div = Components::Elements::Div.new(class: "stateful-test")
    div << "Clicked #{clicks} times"
    div.render
  end
end

describe Components::Component do
  describe "StatelessComponent" do
    it "renders content based on attributes" do
      component = TestStatelessComponent.new(title: "Hello World")
      component.render.should eq("<div class=\"test-component\">Hello World</div>")
    end
    
    it "can have children" do
      component = TestStatelessComponent.new(title: "Parent")
      component << " - "
      
      p = Components::Elements::P.new
      p << "Child content"
      component << p
      
      rendered = component.render
      rendered.should contain("Parent")
      rendered.should contain("<p>Child content</p>")
    end
    
    it "generates cache keys based on attributes" do
      comp1 = TestStatelessComponent.new(title: "Test")
      comp2 = TestStatelessComponent.new(title: "Test")
      comp3 = TestStatelessComponent.new(title: "Different")
      
      comp1.cache_key.should eq(comp2.cache_key)
      comp1.cache_key.should_not eq(comp3.cache_key)
    end
    
    it "is cacheable by default" do
      component = TestStatelessComponent.new
      component.cacheable?.should be_true
    end
    
    it "supports equality comparison" do
      comp1 = TestStatelessComponent.new(title: "Test", id: "123")
      comp2 = TestStatelessComponent.new(title: "Test", id: "123")
      comp3 = TestStatelessComponent.new(title: "Test", id: "456")
      
      comp1.should eq(comp2)
      comp1.should_not eq(comp3)
    end
  end
  
  describe "StatefulComponent" do
    it "maintains internal state" do
      component = TestStatefulComponent.new
      component.get_state("clicks").try(&.as_i?).should eq(0)
      
      component.click
      component.get_state("clicks").try(&.as_i?).should eq(1)
      
      component.click
      component.get_state("clicks").try(&.as_i?).should eq(2)
    end
    
    it "tracks changes" do
      component = TestStatefulComponent.new
      component.changed?.should be_false
      
      component.click
      component.changed?.should be_true
      
      component.reset_changed!
      component.changed?.should be_false
    end
    
    it "renders based on state" do
      component = TestStatefulComponent.new
      component.render.should eq("<div class=\"stateful-test\">Clicked 0 times</div>")
      
      component.click
      component.render.should eq("<div class=\"stateful-test\">Clicked 1 times</div>")
    end
    
    it "is not cacheable by default" do
      component = TestStatefulComponent.new
      component.cacheable?.should be_false
    end
    
    it "supports various state value types" do
      component = TestStatefulComponent.new
      
      component.set_state("string", "value")
      component.get_state("string").try(&.as_s?).should eq("value")
      
      component.set_state("int", 42)
      component.get_state("int").try(&.as_i?).should eq(42)
      
      component.set_state("float", 3.14)
      component.get_state("float").try(&.as_f?).should eq(3.14)
      
      component.set_state("bool", true)
      component.get_state("bool").try(&.as_bool?).should eq(true)
      
      array = [JSON::Any.new("a"), JSON::Any.new("b")]
      component.set_state("array", array)
      component.get_state("array").try(&.as_a?).should eq(array)
      
      hash = {"key" => JSON::Any.new("value")}
      component.set_state("hash", hash)
      component.get_state("hash").try(&.as_h?).should eq(hash)
    end
  end
  
  describe "Component composition" do
    it "allows components to contain other components" do
      parent = TestStatelessComponent.new(title: "Parent")
      child1 = TestStatelessComponent.new(title: "Child 1")
      child2 = TestStatelessComponent.new(title: "Child 2")
      
      parent << child1
      parent << child2
      
      rendered = parent.render
      rendered.should contain("Parent")
      rendered.should contain("Child 1")
      rendered.should contain("Child 2")
    end
    
    it "allows mixing components and elements" do
      component = TestStatelessComponent.new(title: "Mixed")
      
      # Add a component
      component << TestStatelessComponent.new(title: "Sub-component")
      
      # Add an element
      p = Components::Elements::P.new
      p << "Paragraph"
      component << p
      
      # Add raw text
      component << " Raw text"
      
      rendered = component.render
      rendered.should contain("Mixed")
      rendered.should contain("Sub-component")
      rendered.should contain("<p>Paragraph</p>")
      rendered.should contain("Raw text")
    end
  end
end