require "spec"
require "json"
require "compress/gzip"
require "../../../src/asset_pipeline/gzip_coding"
require "../../../src/asset_pipeline/sha256_digest"

# The copy of Mica under src/asset_pipeline/vendor is pinned: each file must
# hold the bytes scripts/vendor_into.rb (in the Mica repository) wrote for
# the commit named in MICA_VENDORED.json.
struct PinnedFileOfVendoredMica
  include JSON::Serializable

  getter path : String = ""
  getter sha256 : String = ""
end

struct ManifestOfVendoredMica
  include JSON::Serializable

  getter source : String = ""
  getter commit : String = ""
  getter component : String = ""
  getter namespace : String = ""
  getter list_of_files : Array(PinnedFileOfVendoredMica) = [] of PinnedFileOfVendoredMica
end

private VENDOR_ROOT = Path[__DIR__].parent.parent.parent / "src" / "asset_pipeline" / "vendor"

private STYLESHEET = (".card { margin: 0 auto; padding: 16px; color: #223344 }\n" * 200).to_slice

# "precompressed" as `gzip -6 -n` writes it.
private STREAM_WRITTEN_BY_GZIP = "1f8b08000000000000032b284a4dcecf2d284a2d2e4e4d01007f3cae280d000000".hexbytes

describe AssetPipeline::GzipCoding do
  describe ".encode" do
    it "writes one gzip member with no modification time, the same bytes every time" do
      compressed = AssetPipeline::GzipCoding.encode(STYLESHEET)

      compressed[0, 4].should eq(Bytes[0x1f, 0x8b, 0x08, 0x00])
      compressed[4, 4].should eq(Bytes[0, 0, 0, 0])
      compressed.size.should be < STYLESHEET.size // 10
      AssetPipeline::GzipCoding.encode(STYLESHEET).should eq(compressed)
    end

    it "writes a stream the standard library's gzip reader expands" do
      compressed = AssetPipeline::GzipCoding.encode(STYLESHEET)

      Compress::Gzip::Reader.open(IO::Memory.new(compressed), &.getb_to_end).should eq(STYLESHEET)
    end

    it "round-trips empty input, one byte and bytes that do not compress" do
      [Bytes.empty, Bytes[0x41], Random.new(11).random_bytes(70_000)].each do |bytes|
        AssetPipeline::GzipCoding.decode(AssetPipeline::GzipCoding.encode(bytes)).should eq(bytes)
      end
    end
  end

  describe ".decode" do
    it "expands a stream the gzip program wrote" do
      String.new(AssetPipeline::GzipCoding.decode(STREAM_WRITTEN_BY_GZIP)).should eq("precompressed")
    end

    it "raises InvalidStreamError for a stream that is cut short, damaged or not gzip" do
      compressed = AssetPipeline::GzipCoding.encode(STYLESHEET)
      damaged = compressed.dup
      damaged[damaged.size - 6] ^= 0xff_u8

      [compressed[0, compressed.size - 9], damaged, "not gzip at all".to_slice].each do |bytes|
        expect_raises(AssetPipeline::GzipCoding::InvalidStreamError) { AssetPipeline::GzipCoding.decode(bytes) }
      end
    end
  end
end

describe "the vendored copy of Mica" do
  manifest = ManifestOfVendoredMica.from_json(File.read(VENDOR_ROOT / "MICA_VENDORED.json"))

  it "names its source, a full commit, the deflate component and the AssetPipeline::Mica namespace" do
    manifest.source.should eq("https://github.com/amberframework/mica")
    manifest.commit.size.should eq(40)
    manifest.commit.each_char.all? { |character| character.ascii_number? || ('a'..'f').includes?(character) }.should be_true
    manifest.component.should eq("deflate")
    manifest.namespace.should eq("AssetPipeline::Mica")
    manifest.list_of_files.empty?.should be_false
  end

  it "holds every pinned file with its pinned sha256" do
    manifest.list_of_files.each do |vendored_file|
      observed_sha256 = AssetPipeline::SHA256Digest.hexdigest(File.read(VENDOR_ROOT / vendored_file.path))
      fail "src/asset_pipeline/vendor/#{vendored_file.path} does not match its pin" unless observed_sha256 == vendored_file.sha256
    end
  end

  it "holds no file without a pin" do
    list_of_present = Dir.glob((VENDOR_ROOT / "mica" / "**" / "*.cr").to_s).map { |path| Path[path].relative_to(VENDOR_ROOT).to_s }
    (list_of_present - manifest.list_of_files.map(&.path)).empty?.should be_true
  end
end
