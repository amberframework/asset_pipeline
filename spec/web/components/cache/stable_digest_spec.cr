require "../../spec_helper"
require "../../../../src/components/cache/stable_digest"
require "../../../../src/components/base/stateless_component"

class StableDigestSpecComponent < Components::StatelessComponent
  def render_content : String
    "x"
  end
end

describe Components::Cache::StableDigest do
  describe ".hex_of" do
    it "frames parts, so moving bytes between parts changes the digest" do
      first = Components::Cache::StableDigest.hex_of(["ab", "c"])
      first.should_not eq(Components::Cache::StableDigest.hex_of(["a", "bc"]))
      first.size.should eq(Components::Cache::StableDigest::HEX_LENGTH)
    end
  end

  describe ".fnv1a_128_hex" do
    it "matches the published test vectors" do
      Components::Cache::StableDigest.fnv1a_128_hex(Bytes.empty).should eq("6c62272e07bb014262b821756295c58d")
      Components::Cache::StableDigest.fnv1a_128_hex("a".to_slice).should eq("d228cb696f1a8caf78912b704e4a8964")
    end
  end

  describe ".cache_key_for" do
    it "does not depend on attribute order" do
      first = Components::Cache::StableDigest.cache_key_for("X", {"a" => "1", "b" => "2"})
      first.should eq(Components::Cache::StableDigest.cache_key_for("X", {"b" => "2", "a" => "1"}))
    end
  end

  it "gives a stateless component the same key for the same attributes" do
    StableDigestSpecComponent.new(a: "1", b: "2").cache_key.should eq(StableDigestSpecComponent.new(b: "2", a: "1").cache_key)
    StableDigestSpecComponent.new(a: "1").cache_key.should_not eq(StableDigestSpecComponent.new(a: "2").cache_key)
  end

  it "keeps keys the same across two processes" do
    compiler = ENV["CRYSTAL"]? || "crystal"
    binary_path = File.tempname("stable_cache_keys")
    begin
      status = Process.run(compiler, ["build", "--no-debug", "-o", binary_path, "spec/web/support/print_stable_cache_keys.cr"], output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      status.success?.should be_true
      first_run = IO::Memory.new
      second_run = IO::Memory.new
      Process.run(binary_path, output: first_run).success?.should be_true
      Process.run(binary_path, output: second_run).success?.should be_true
      first_run.to_s.lines.size.should eq(2)
      first_run.to_s.should eq(second_run.to_s)
    ensure
      File.delete?(binary_path)
    end
  end
end
