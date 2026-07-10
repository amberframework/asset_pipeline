require "spec"
require "../../../src/ui"

describe UI::Fluid do
  describe "#to_css" do
    it "renders a clamp() expression with all three anchors" do
      fluid = UI::Fluid.new(min: "20rem", ideal: "60vw", max: "48rem")
      fluid.to_css.should eq("clamp(20rem, 60vw, 48rem)")
    end

    it "passes raw strings through unchanged" do
      fluid = UI::Fluid.new(min: "260px", ideal: "min(80vw, 480px)", max: "480px")
      fluid.to_css.should eq("clamp(260px, min(80vw, 480px), 480px)")
    end
  end

  describe ".px" do
    it "constructs from numeric pixel values" do
      fluid = UI::Fluid.px(min: 200, ideal: 300, max: 600)
      fluid.min.should eq("200px")
      fluid.ideal.should eq("300px")
      fluid.max.should eq("600px")
      fluid.to_css.should eq("clamp(200px, 300px, 600px)")
    end
  end

  describe ".vw" do
    it "constructs a viewport-tracking fluid with px floor/ceiling" do
      fluid = UI::Fluid.vw(min_px: 280, ideal_vw: 90, max_px: 480)
      fluid.min.should eq("280px")
      fluid.ideal.should eq("90vw")
      fluid.max.should eq("480px")
      fluid.to_css.should eq("clamp(280px, 90vw, 480px)")
    end
  end
end

describe UI::View do
  describe "#fluid_width" do
    it "stores a Fluid record built from numeric pixel values" do
      view = UI::Label.new("hello")
      view.fluid_width(min: 200, ideal: 400, max: 600)
      fluid = view.fluid_width
      fluid.should_not be_nil
      fluid.not_nil!.to_css.should eq("clamp(200px, 400px, 600px)")
    end

    it "accepts mixed string and numeric arguments" do
      view = UI::Label.new("hello")
      view.fluid_width(min: 280, ideal: "90vw", max: 480)
      view.fluid_width.not_nil!.to_css.should eq("clamp(280px, 90vw, 480px)")
    end

    it "is chainable (returns self)" do
      view = UI::Label.new("hello")
      result = view.fluid_width(min: 100, ideal: 200, max: 300)
      result.should be(view)
    end
  end

  describe "#fluid_height" do
    it "stores a Fluid record on the height channel" do
      view = UI::Label.new("hello")
      view.fluid_height(min: "2rem", ideal: "8vh", max: "6rem")
      view.fluid_height.not_nil!.to_css.should eq("clamp(2rem, 8vh, 6rem)")
    end
  end

  describe "#container_query" do
    it "marks the view as a container-query root" do
      view = UI::Label.new("hello")
      view.container_query("card")
      view.container_query_name.should eq("card")
    end

    it "is chainable" do
      view = UI::Label.new("hello")
      result = view.container_query("card")
      result.should be(view)
    end
  end
end
