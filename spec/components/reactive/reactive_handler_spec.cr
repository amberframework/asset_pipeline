require "../../spec_helper"
require "../../../src/components/reactive/reactive_handler"
require "../../../src/components/reactive/reactive_component"
require "../../../src/components/elements/grouping/div"

# Test reactive component
class TestReactiveComponent < Components::Reactive::ReactiveComponent
  def initialize(**attrs)
    super
  end
  
  protected def initialize_state
    set_state("count", 0)
  end
  
  def render_content : String
    Components::Elements::Div.new(class: "test-component").build do |div|
      div << "Count: #{get_state("count").try(&.as_i?) || 0}"
    end.render
  end
  
  def increment(event : JSON::Any)
    count = get_state("count").try(&.as_i?) || 0
    set_state("count", JSON::Any.new(count + 1))
  end
end

describe Components::Reactive::ReactiveHandler do
  it "implements HTTP::Handler interface" do
    handler = Components::Reactive::ReactiveHandler.new
    handler.is_a?(HTTP::Handler).should be_true
  end
  
  it "can be configured with custom paths" do
    handler = Components::Reactive::ReactiveHandler.new(
      websocket_path: "/custom/ws",
      action_path_prefix: "/custom/action",
      enable_http_fallback: false
    )
    
    handler.websocket_path.should eq("/custom/ws")
    handler.action_path_prefix.should eq("/custom/action")
    handler.enable_http_fallback.should be_false
  end
  
  it "passes through non-matching requests" do
    handler = Components::Reactive::ReactiveHandler.new
    
    # Create a simple next handler
    next_called = false
    handler.next = HTTP::Handler::HandlerProc.new do |context|
      next_called = true
      context.response.print("passed through")
    end
    
    # Test with non-matching request
    io = IO::Memory.new
    request = HTTP::Request.new("GET", "/other/path")
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)
    
    handler.call(context)
    
    next_called.should be_true
  end
  
  it "handles HTTP fallback for component actions" do
    handler = Components::Reactive::ReactiveHandler.new
    
    # Register a test component
    component = TestReactiveComponent.new
    Components::Reactive::ReactiveHandler.register_component(component)
    
    # Create POST request to action endpoint
    body = {
      componentId: component.component_id,
      method: "increment",
      event: {} of String => JSON::Any
    }.to_json
    
    io = IO::Memory.new
    request = HTTP::Request.new(
      "POST", 
      "/components/action/#{component.component_id}",
      HTTP::Headers{"Content-Type" => "application/json"},
      body
    )
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)
    
    handler.call(context)
    response.close
    
    # Check response
    response.status.should eq(HTTP::Status::OK)
    
    result = JSON.parse(io.to_s)
    result["success"].as_bool.should be_true
    result["componentId"].as_s.should eq(component.component_id)
    result["html"].as_s.should contain("Count: 1")
  end
  
  it "returns error for unknown components" do
    handler = Components::Reactive::ReactiveHandler.new
    
    # Create POST request for non-existent component
    body = {
      componentId: "unknown-component",
      method: "someMethod",
      event: {} of String => JSON::Any
    }.to_json
    
    io = IO::Memory.new
    request = HTTP::Request.new(
      "POST", 
      "/components/action/unknown",
      HTTP::Headers{"Content-Type" => "application/json"},
      body
    )
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)
    
    handler.call(context)
    response.close
    
    # Check error response
    response.status.should eq(HTTP::Status::NOT_FOUND)
    
    result = JSON.parse(io.to_s)
    result["success"].as_bool.should be_false
    result["error"].as_s.should eq("Component not found")
  end
  
  it "manages component registration" do
    # Clear any existing components
    initial_count = Components::Reactive::ReactiveHandler.registered_components
    
    component1 = TestReactiveComponent.new
    component2 = TestReactiveComponent.new
    
    # Register components
    Components::Reactive::ReactiveHandler.register_component(component1)
    Components::Reactive::ReactiveHandler.register_component(component2)
    
    Components::Reactive::ReactiveHandler.registered_components.should eq(initial_count + 2)
    
    # Unregister one
    Components::Reactive::ReactiveHandler.unregister_component(component1.component_id)
    
    Components::Reactive::ReactiveHandler.registered_components.should eq(initial_count + 1)
  end
end