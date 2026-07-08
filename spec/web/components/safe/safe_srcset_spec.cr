require "../../spec_helper"
require "../../../../src/components/safe/safe_srcset"

describe Components::SafeSrcSet do
  describe "valid srcset lists" do
    it "parses a width-descriptor list" do
      Components::SafeSrcSet.parse!("small.jpg 480w, large.jpg 1080w").to_s
        .should eq("small.jpg 480w, large.jpg 1080w")
    end

    it "parses a pixel-density-descriptor list" do
      Components::SafeSrcSet.parse!("photo.jpg 1x, photo-2x.jpg 2x").to_s
        .should eq("photo.jpg 1x, photo-2x.jpg 2x")
    end

    it "parses a single candidate with no descriptor" do
      Components::SafeSrcSet.parse!("photo.jpg").to_s.should eq("photo.jpg")
    end
  end

  describe "adversarial: a URL list, not a single URL" do
    it "rejects the whole value if ANY candidate URL is unsafe (fail closed)" do
      expect_raises(ArgumentError) do
        Components::SafeSrcSet.parse!("safe.jpg 1x, javascript:alert(1) 2x")
      end
    end

    it ".parse returns nil instead of raising when a candidate is unsafe" do
      Components::SafeSrcSet.parse("safe.jpg 1x, javascript:alert(1) 2x").should be_nil
    end

    it "rejects a malformed descriptor" do
      expect_raises(ArgumentError, "invalid descriptor") do
        Components::SafeSrcSet.parse!("photo.jpg not-a-descriptor")
      end
    end

    it "rejects an empty srcset" do
      expect_raises(ArgumentError, "empty srcset") do
        Components::SafeSrcSet.parse!("")
      end
    end
  end
end
