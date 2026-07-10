require "../../spec/spec_helper"
require "./component"

describe Components::DesignSystem::ExampleWidget do
  it "renders a labelled component region with design-system classes" do
    rendered = Components::DesignSystem::ExampleWidget.new("Example").render

    rendered.should contain(%(data-component="example-widget"))
    rendered.should contain(%(class="ap-example-widget"))
    rendered.should contain(%(aria-labelledby="example-widget-title"))
    rendered.should contain(%(<h2 id="example-widget-title">Example</h2>))
  end

  it "does not render forbidden canonical classes or inline handlers" do
    rendered = Components::DesignSystem::ExampleWidget.new("Example").render

    rendered.should_not contain("btn-primary")
    rendered.should_not contain("card-body")
    rendered.should_not contain("form-control")
    rendered.should_not contain("onclick=")
  end
end
