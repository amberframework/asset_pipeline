require "../../spec_helper"
require "../../../src/components/elements/base/container_element"
require "../../../src/components/elements/grouping/div"

describe "Simple Element Test" do
  it "can create and render a div" do
    div = Components::Elements::Div.new(class: "test")
    div << "Hello World"
    div.render.should eq("<div class=\"test\">Hello World</div>")
  end
end