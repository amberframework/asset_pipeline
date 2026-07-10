require "../spec_helper"

# Phase04CompileCheck is loaded via spec/support/phase04_compile_check.cr
# (autoloaded by spec_helper).

describe AssetPipeline::Platform do
  it "has? evaluates to true for a matching flag" do
    {% if flag?(:macos) %}
      AssetPipeline::Platform.has?(:macos).should be_true
    {% elsif flag?(:ios) %}
      AssetPipeline::Platform.has?(:ios).should be_true
    {% else %}
      # On a default web build no -D flags are present; we still want
      # has? to evaluate without error.
      AssetPipeline::Platform.has?(:ios).should be_false
      AssetPipeline::Platform.has?(:macos).should be_false
      AssetPipeline::Platform.has?(:android).should be_false
    {% end %}
  end

  it "requires(:matching_flag) executes the block" do
    sentinel = "not-set"
    {% if flag?(:macos) %}
      AssetPipeline::Platform.requires(:macos) do
        sentinel = "macos"
      end
      sentinel.should eq("macos")
    {% elsif flag?(:ios) %}
      AssetPipeline::Platform.requires(:ios) do
        sentinel = "ios"
      end
      sentinel.should eq("ios")
    {% else %}
      # Default web build — requires(:ios) would be a compile error, so
      # cover the negative path via the compile-error test below.
      sentinel.should eq("not-set")
    {% end %}
  end

  it "raises a compile-time error when the required flag is absent" do
    snippet = <<-CR
      require "../../src/asset_pipeline"
      AssetPipeline::Platform.requires(:ios) do
        puts "iOS only"
      end
    CR
    status, output = Phase04CompileCheck.run(snippet)
    status.success?.should be_false
    output.should contain("AssetPipeline::Platform.requires(:ios)")
    output.should contain("-Dios")
  end
end
