require "spec"
require "json"
require "../../../src/asset_pipeline/sha256_digest"

# The copy of Beryl under src/asset_pipeline/vendor is pinned: each file must
# hold the bytes scripts/vendor_into.rb (in the Beryl repository) wrote for
# the commit named in BERYL_VENDORED.json.
struct PinnedFileOfVendoredBeryl
  include JSON::Serializable

  getter path : String = ""
  getter sha256 : String = ""
end

struct ManifestOfVendoredBeryl
  include JSON::Serializable

  getter source : String = ""
  getter commit : String = ""
  getter namespace : String = ""
  getter list_of_files : Array(PinnedFileOfVendoredBeryl) = [] of PinnedFileOfVendoredBeryl
end

private VENDOR_ROOT = Path[__DIR__].parent.parent.parent / "src" / "asset_pipeline" / "vendor"

describe AssetPipeline::SHA256Digest do
  it "computes SHA-256 (FIPS 180-4 example for \"abc\"), with or without OpenSSL" do
    AssetPipeline::SHA256Digest.hexdigest("abc").should eq("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
  end

  it "gives the same digest in one call, in parts and from a file" do
    in_parts = AssetPipeline::SHA256Digest.new
    in_parts << "a"
    in_parts << "bc"
    in_parts.hexfinal.should eq(AssetPipeline::SHA256Digest.hexdigest("abc"))

    path = File.tempname("sha256-digest", ".txt")
    File.write(path, "abc")
    begin
      AssetPipeline::SHA256Digest.new.file(path).hexfinal.should eq(AssetPipeline::SHA256Digest.hexdigest("abc"))
    ensure
      File.delete(path)
    end
  end
end

describe "the vendored copy of Beryl" do
  manifest = ManifestOfVendoredBeryl.from_json(File.read(VENDOR_ROOT / "BERYL_VENDORED.json"))

  it "names its source, a full commit and the AssetPipeline::Beryl namespace" do
    manifest.source.should eq("https://github.com/amberframework/beryl")
    manifest.commit.size.should eq(40)
    manifest.commit.each_char.all? { |character| character.ascii_number? || ('a'..'f').includes?(character) }.should be_true
    manifest.namespace.should eq("AssetPipeline::Beryl")
    manifest.list_of_files.empty?.should be_false
  end

  it "holds every pinned file with its pinned sha256" do
    manifest.list_of_files.each do |vendored_file|
      observed_sha256 = AssetPipeline::SHA256Digest.hexdigest(File.read(VENDOR_ROOT / vendored_file.path))
      fail "src/asset_pipeline/vendor/#{vendored_file.path} does not match its pin" unless observed_sha256 == vendored_file.sha256
    end
  end

  it "holds no file without a pin" do
    list_of_present = Dir.glob((VENDOR_ROOT / "beryl" / "**" / "*.cr").to_s).map { |path| Path[path].relative_to(VENDOR_ROOT).to_s }
    list_of_present << "beryl.cr"
    (list_of_present - manifest.list_of_files.map(&.path)).empty?.should be_true
  end
end
