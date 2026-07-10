require "../spec_helper"
require "../../../src/asset_pipeline/action_result"

describe UI::ActionResult::Navigate do
  it "carries the target route id and an empty params hash by default" do
    result = UI::ActionResult::Navigate.new(:todos)
    result.route_id.should eq(:todos)
    result.params.should be_empty
  end

  it "preserves explicit params" do
    result = UI::ActionResult::Navigate.new(:detail, {:id => "42"})
    result.params[:id].should eq("42")
  end
end

describe UI::ActionResult::Pop do
  it "instantiates with no payload" do
    UI::ActionResult::Pop.new.should be_a(UI::ActionResult)
  end
end

describe UI::ActionResult::Rerender do
  it "instantiates with no payload" do
    UI::ActionResult::Rerender.new.should be_a(UI::ActionResult)
  end
end

describe UI::ActionResult::ReplaceRoot do
  it "carries route id and params" do
    result = UI::ActionResult::ReplaceRoot.new(:home, {:section => "todos"})
    result.route_id.should eq(:home)
    result.params[:section].should eq("todos")
  end
end

describe UI::ActionResult::RenderInline do
  it "carries the view to render" do
    label = UI::Label.new("inline")
    result = UI::ActionResult::RenderInline.new(label)
    result.view.should eq(label)
  end
end
