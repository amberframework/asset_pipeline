require "../spec_helper"

# Base component classes
require "../../src/components/base/component"
require "../../src/components/base/stateless_component"
require "../../src/components/base/stateful_component"

# Example components
require "../../src/components/examples/button_component"
require "../../src/components/examples/card_component"
require "../../src/components/examples/counter_component"

# Some element classes
require "../../src/components/elements/grouping/div"
require "../../src/components/elements/sections/main"
require "../../src/components/elements/sections/headings"

# Test component for nested components
class DashboardCard < Components::StatelessComponent
  def render_content : String
    Components::Elements::Div.new(class: "dashboard-card").build do |div|
      # Add a card component
      card = Components::Examples::CardComponent.new(
        title: @attributes["title"]?,
        subtitle: @attributes["subtitle"]?
      )
      
      # Card contains button components
      card << Components::Examples::ButtonComponent.new(
        label: "View Details",
        variant: "info",
        size: "small"
      ).render
      
      div << card.render
    end.render
  end
end

describe "Phase 2 Verification - Core Component System" do
  it "successfully implements component base classes" do
    # Components are built on top of elements
    button = Components::Examples::ButtonComponent.new(label: "Test")
    button.is_a?(Components::Component).should be_true
    button.is_a?(Components::StatelessComponent).should be_true
    
    counter = Components::Examples::CounterComponent.new
    counter.is_a?(Components::Component).should be_true
    counter.is_a?(Components::StatefulComponent).should be_true
  end
  
  it "demonstrates component composition" do
    # Build a page using components and elements together
    page = Components::Elements::Main.new.build do |main|
      # Add a heading element
      h1 = Components::Elements::H1.new
      h1 << "Welcome to Components"
      main << h1
      
      # Add a card component
      card = Components::Examples::CardComponent.new(
        title: "Feature Card",
        subtitle: "Reusable component"
      )
      card << "This card is a reusable component built from elements."
      main << card.render
      
      # Add multiple button components
      main << Components::Examples::ButtonComponent.new(
        label: "Primary Action",
        variant: "primary"
      ).render
      
      main << " "
      
      main << Components::Examples::ButtonComponent.new(
        label: "Secondary Action",
        variant: "secondary"
      ).render
    end
    
    rendered = page.render
    rendered.should contain("<main>")
    rendered.should contain("<h1>Welcome to Components</h1>")
    rendered.should contain("Feature Card")
    rendered.should contain("btn btn-primary")
    rendered.should contain("btn btn-secondary")
  end
  
  it "shows stateless components are pure functions" do
    # Same inputs produce same outputs
    btn1 = Components::Examples::ButtonComponent.new(label: "Click", variant: "success")
    btn2 = Components::Examples::ButtonComponent.new(label: "Click", variant: "success")
    
    btn1.render.should eq(btn2.render)
    btn1.cache_key.should eq(btn2.cache_key)
    btn1.cacheable?.should be_true
  end
  
  it "shows stateful components maintain state" do
    counter = Components::Examples::CounterComponent.new
    
    # Initial state
    counter.get_state("count").try(&.as_i?).should eq(0)
    counter.cacheable?.should be_false
    
    # State changes
    initial_render = counter.render
    counter.increment
    after_increment = counter.render
    
    initial_render.should_not eq(after_increment)
    counter.changed?.should be_true
  end
  
  it "components can be nested within components" do
    dashboard = DashboardCard.new(
      title: "Sales Report",
      subtitle: "Q4 2025"
    )
    
    rendered = dashboard.render
    rendered.should contain("dashboard-card")
    rendered.should contain("Sales Report")
    rendered.should contain("View Details")
    rendered.should contain("btn btn-info btn-small")
  end
  
  it "achieves the component system goals" do
    # 1. Components are reusable units
    btn1 = Components::Examples::ButtonComponent.new(label: "Save")
    btn2 = Components::Examples::ButtonComponent.new(label: "Save")
    btn1.render.should eq(btn2.render)
    
    # 2. Components are composable
    card = Components::Examples::CardComponent.new(title: "Nested")
    card << Components::Examples::ButtonComponent.new(label: "Action").render
    card.render.should contain("Action")
    
    # 3. Components use elements, not string templates
    counter = Components::Examples::CounterComponent.new
    # The render method builds HTML using element classes
    counter.render.should contain("<div class=\"counter-component\">")
    
    # 4. Ready for Phase 3: Caching
    Components::Examples::ButtonComponent.new(label: "test").responds_to?(:cache_key).should be_true
    Components::Examples::ButtonComponent.new(label: "test").responds_to?(:cacheable?).should be_true
    
    true.should be_true
  end
end