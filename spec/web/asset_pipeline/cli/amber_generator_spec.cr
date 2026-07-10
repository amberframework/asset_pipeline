require "../../spec_helper"
require "../../../../src/asset_pipeline/cli/amber_generator"
require "file_utils"

describe AssetPipeline::CLI::AmberGenerator do
  it "creates a shim ECR for a controller/action pair" do
    tmp = File.tempname("ap_amber_gen", "")
    Dir.mkdir_p(tmp)
    begin
      io = IO::Memory.new
      err = IO::Memory.new
      code = AssetPipeline::CLI::AmberGenerator.run(
        ["generate", "sign_in", "index"],
        views_root: tmp,
        io: io,
        err: err,
      )
      code.should eq(0)
      shim = File.join(tmp, "sign_in", "index.ecr")
      File.exists?(shim).should be_true
      File.read(shim).should eq("<%= @screen_html %>\n")
    ensure
      FileUtils.rm_rf(tmp)
    end
  end

  it "refuses to overwrite an existing file" do
    tmp = File.tempname("ap_amber_gen", "")
    Dir.mkdir_p(tmp)
    begin
      Dir.mkdir_p(File.join(tmp, "sign_in"))
      File.write(File.join(tmp, "sign_in", "index.ecr"), "PREEXISTING\n")
      io = IO::Memory.new
      err = IO::Memory.new
      code = AssetPipeline::CLI::AmberGenerator.run(
        ["generate", "sign_in", "index"],
        views_root: tmp,
        io: io,
        err: err,
      )
      code.should_not eq(0)
      File.read(File.join(tmp, "sign_in", "index.ecr")).should eq("PREEXISTING\n")
    ensure
      FileUtils.rm_rf(tmp)
    end
  end

  it "rejects non snake_case identifiers" do
    tmp = File.tempname("ap_amber_gen", "")
    Dir.mkdir_p(tmp)
    begin
      io = IO::Memory.new
      err = IO::Memory.new
      code = AssetPipeline::CLI::AmberGenerator.run(
        ["generate", "Sign-In", "index"],
        views_root: tmp,
        io: io,
        err: err,
      )
      code.should_not eq(0)
      Dir.exists?(File.join(tmp, "Sign-In")).should be_false
    ensure
      FileUtils.rm_rf(tmp)
    end
  end

  it "prints usage with --help and returns 0" do
    io = IO::Memory.new
    err = IO::Memory.new
    code = AssetPipeline::CLI::AmberGenerator.run(["--help"], io: io, err: err)
    code.should eq(0)
    err.to_s.should contain("asset_pipeline_amber")
  end

  it "rejects unknown commands" do
    io = IO::Memory.new
    err = IO::Memory.new
    code = AssetPipeline::CLI::AmberGenerator.run(["nope"], io: io, err: err)
    code.should_not eq(0)
  end
end
