require "spec"
require "../../src/asset_pipeline"
require "../api_card_probes/probe_support"

describe "asset_pipeline public API return types" do
  {% if flag?(:macos) || flag?(:ios) %}
    it "declares stable returns for the Apple UI mutators and sender" do
      context_menu = UI::ContextMenu.new
      typeof(context_menu.add_item("Open")).should eq(Array(UI::ContextMenu::Entry))
      typeof(context_menu.add_separator).should eq(Array(UI::ContextMenu::Entry))
      typeof(APICardProbeSender.new.set_color("target", :setColor, nil)).should eq(Nil)
    end
  {% end %}

  it "keeps the concrete visitor return available for ActivityView" do
    visitor = APICardProbeVisitor.new
    typeof(visitor.visit(UI::ActivityView.new("Share"))).should eq(Nil)
  end
end
