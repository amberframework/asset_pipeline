require "spec"
require "file_utils"
require "../../../src/asset_pipeline/static_assets"

private def with_static_asset_fixture(&)
  root = Path[Dir.tempdir].join("asset-pipeline-static-assets-#{Random::Secure.hex(8)}")
  source = root.join("app/assets")
  output = root.join("public/assets")
  Dir.mkdir_p(source.join("stylesheets/nested"))
  Dir.mkdir_p(source.join("stylesheets/images"))
  Dir.mkdir_p(source.join("javascript/modules"))
  Dir.mkdir_p(source.join("images/nested/a"))
  Dir.mkdir_p(source.join("images/nested/b"))
  Dir.mkdir_p(source.join("fonts"))
  Dir.mkdir_p(source.join("files"))

  File.write(source.join("images/logo.svg"), %(<svg xmlns="http://www.w3.org/2000/svg"><path d="M0 0h2v2z"/></svg>))
  File.write(source.join("images/photo.webp"), Bytes[0x52, 0x49, 0x46, 0x46])
  File.write(source.join("images/photo.avif"), Bytes[0x00, 0x00, 0x00, 0x18])
  File.write(source.join("images/nested/a/icon.svg"), %(<svg><title>A</title></svg>))
  File.write(source.join("images/nested/b/icon.svg"), %(<svg><title>B</title></svg>))
  File.write(source.join("images/space name.svg"), %(<svg><title>Space</title></svg>))
  File.write(source.join("stylesheets/images/local.png"), Bytes[0x89, 0x50, 0x4e, 0x47])
  File.write(source.join("fonts/inter.woff"), Bytes[0x77, 0x4f, 0x46, 0x46])
  File.write(source.join("fonts/inter.woff2"), Bytes[0x77, 0x4f, 0x46, 0x32])
  File.write(source.join("fonts/.gitkeep"), "")
  Dir.mkdir_p(source.join(".private"))
  File.write(source.join(".private/secret.txt"), "not public")
  File.write(source.join("files/terms.pdf"), Bytes[0x25, 0x50, 0x44, 0x46])
  File.write(source.join("site.webmanifest"), %({"name":"Amber"}))
  File.write(source.join("stylesheets/reset.css"), "body { margin: 0; }\n")
  File.write(source.join("stylesheets/nested/admin.css"), ".mark { background: url('../../images/nested/a/icon.svg#mark'); }\n")
  File.write(source.join("stylesheets/adversarial.css"), <<-CSS)
    /* url('../images/comment-missing.svg') */
    .copy::before { content: "url('../images/string-missing.svg')"; }
    CSS
  File.write(source.join("stylesheets/app.css"), <<-CSS)
    @import "reset.css";
    @font-face { font-family: Inter; src: url('../fonts/inter.woff2') format('woff2'); }
    .brand { background: url('../images/logo.svg?theme=amber#mark'); }
    .local { background: url('images/local.png'); }
    .external { background: url('https://example.test/remote.svg'); }
    .inline { background: url(data:image/svg+xml;base64,AAAA); }
    /* url('../images/comment-missing.svg') */
    .copy::before { content: "url('../images/string-missing.svg')"; }
    CSS
  File.write(source.join("javascript/modules/pet.js"), "export const pet = 'Amber';\n")
  File.write(source.join("javascript/adversarial.js"), <<-JS)
    const example = "import './missing-string.js'";
    // import "./missing-comment.js";
    /* export { missing } from "./missing-block.js"; */
    JS
  File.write(source.join("javascript/app.js.map"), %({"version":3,"sources":["app.js"]}))
  File.write(source.join("javascript/app.js"), <<-JS)
    import { pet } from "./modules/pet.js";
    import "lit";
    export { pet } from './modules/pet.js';
    const lazy = import("./modules/pet.js");
    const example = "import './missing-string.js'";
    // import "./missing-comment.js";
    /* export { missing } from "./missing-block.js"; */
    //# sourceMappingURL=app.js.map
    JS

  begin
    yield source, output, root
  ensure
    FileUtils.rm_rf(root)
  end
end

describe AssetPipeline::StaticAssets::Compiler do
  it "fingerprints every asset, preserves nested paths, records MIME/SRI, and writes deterministic gzip output" do
    with_static_asset_fixture do |source, output, _root|
      compiler = AssetPipeline::StaticAssets::Compiler.new(source_root: source, output_root: output)
      manifest = compiler.build

      manifest.assets.size.should eq(19)
      manifest.assets.has_key?("fonts/.gitkeep").should be_false
      manifest.assets.has_key?(".private/secret.txt").should be_false
      manifest.path("images/logo.svg").should match(%r{\A/assets/images/logo-[a-f0-9]{32}\.svg\z})
      manifest.path("images/nested/a/icon.svg").should_not eq(manifest.path("images/nested/b/icon.svg"))
      manifest.path("images/space name.svg").should contain("space%20name-")
      manifest.entry("images/photo.webp").content_type.should eq("image/webp")
      manifest.entry("images/photo.avif").content_type.should eq("image/avif")
      manifest.entry("fonts/inter.woff").content_type.should eq("font/woff")
      manifest.entry("fonts/inter.woff2").content_type.should eq("font/woff2")
      manifest.entry("site.webmanifest").content_type.should eq("application/manifest+json; charset=utf-8")
      webmanifest_path = output.join(URI.decode(manifest.path("site.webmanifest").sub("/assets/", "")))
      File.file?("#{webmanifest_path}.gz").should be_true
      manifest.integrity("images/logo.svg").should match(/\Asha256-[A-Za-z0-9+\/]+={0,2}\z/)
      manifest.entry("images/logo.svg").digest.size.should eq(64)

      css_disk_path = output.join(manifest.path("stylesheets/app.css").sub("/assets/", ""))
      File.exists?(css_disk_path).should be_true
      File.exists?("#{css_disk_path}.gz").should be_true
      File.read(css_disk_path).should contain(manifest.path("images/logo.svg") + "?theme=amber#mark")
      File.read(css_disk_path).should contain(manifest.path("fonts/inter.woff2"))
      File.read(css_disk_path).should contain(manifest.path("stylesheets/images/local.png"))
      File.read(css_disk_path).should contain("https://example.test/remote.svg")
      File.read(css_disk_path).should contain("data:image/svg+xml;base64,AAAA")
      File.read(css_disk_path).should contain(%(/* url('../images/comment-missing.svg') */))
      File.read(css_disk_path).should contain(%(content: "url('../images/string-missing.svg')"))

      js_disk_path = output.join(manifest.path("javascript/app.js").sub("/assets/", ""))
      File.read(js_disk_path).should contain(manifest.path("javascript/modules/pet.js"))
      File.read(js_disk_path).should contain(manifest.path("javascript/app.js.map"))
      File.read(js_disk_path).should contain(%(import "lit";))
      File.read(js_disk_path).should contain(%(const example = "import './missing-string.js'";))
      File.read(js_disk_path).should contain(%(// import "./missing-comment.js";))
      File.read(js_disk_path).should contain(%(/* export { missing } from "./missing-block.js"; */))

      ["stylesheets/adversarial.css", "javascript/adversarial.js"].each do |logical|
        emitted_path = output.join(URI.decode(manifest.path(logical).sub("/assets/", "")))
        File.read(emitted_path).should eq(File.read(source.join(logical)))
      end

      first_json = File.read(output.join("manifest.json"))
      first_gzip = File.read(css_disk_path.to_s + ".gz").to_slice.dup
      compiler.build
      File.read(output.join("manifest.json")).should eq(first_json)
      File.read(css_disk_path.to_s + ".gz").to_slice.should eq(first_gzip)
      compiler.check.path("images/logo.svg").should eq(manifest.path("images/logo.svg"))

      File.write(css_disk_path.to_s + ".gz", "corrupt gzip")
      expect_raises(AssetPipeline::StaticAssets::VerificationError, /Precompressed static asset is invalid/) do
        compiler.check
      end
    end
  end

  it "propagates dependency changes into CSS fingerprints and safely prunes only prior manifest-owned files" do
    with_static_asset_fixture do |source, output, _root|
      keep = output.join("keep-me.txt")
      Dir.mkdir_p(output)
      File.write(keep, "application-owned")

      compiler = AssetPipeline::StaticAssets::Compiler.new(source_root: source, output_root: output)
      first = compiler.build
      old_logo = first.path("images/logo.svg")
      old_css = first.path("stylesheets/app.css")

      File.write(source.join("images/logo.svg"), %(<svg><title>Changed</title></svg>))
      second = compiler.build

      second.path("images/logo.svg").should_not eq(old_logo)
      second.path("stylesheets/app.css").should_not eq(old_css)
      File.exists?(keep).should be_true
      File.exists?(output.join(old_logo.sub("/assets/", ""))).should be_false
      File.exists?(output.join(old_css.sub("/assets/", ""))).should be_false
    end
  end

  it "reloads the manifest and keeps lookups strict" do
    with_static_asset_fixture do |source, output, _root|
      built = AssetPipeline::StaticAssets::Compiler.new(source_root: source, output_root: output).build
      loaded = AssetPipeline::StaticAssets::Manifest.load(output.join("manifest.json"))

      loaded.path("images/logo.svg").should eq(built.path("images/logo.svg"))
      loaded.integrity("images/logo.svg").should eq(built.integrity("images/logo.svg"))
      expect_raises(AssetPipeline::StaticAssets::MissingAssetError, /not present in the compiled manifest/) do
        loaded.path("images/missing.svg")
      end

      emitted_logo = output.join(loaded.path("images/logo.svg").sub("/assets/", ""))
      File.write(emitted_logo, "tampered")
      expect_raises(AssetPipeline::StaticAssets::VerificationError, /byte count changed|digest changed/) do
        loaded.verify(output)
      end
    end
  end

  it "wraps manifest schema errors in the static-asset error contract" do
    with_static_asset_fixture do |_source, output, _root|
      Dir.mkdir_p(output)
      File.write(output.join("manifest.json"), %({"schema_version":"wrong","public_path":"/assets","assets":{}}))
      expect_raises(AssetPipeline::StaticAssets::ConfigurationError, /does not match schema/) do
        AssetPipeline::StaticAssets::Manifest.load(output.join("manifest.json"))
      end
    end
  end

  it "preserves the prior valid build when compilation fails" do
    with_static_asset_fixture do |source, output, _root|
      compiler = AssetPipeline::StaticAssets::Compiler.new(source_root: source, output_root: output)
      first = compiler.build
      manifest_json = File.read(output.join("manifest.json"))
      emitted_paths = first.assets.values.map do |entry|
        output.join(URI.decode(entry.path.sub("/assets/", "")))
      end

      File.write(source.join("stylesheets/app.css"), ".missing { background: url('missing.png'); }")
      expect_raises(AssetPipeline::StaticAssets::InvalidReferenceError) do
        compiler.build
      end

      File.read(output.join("manifest.json")).should eq(manifest_json)
      emitted_paths.each { |path| File.file?(path).should be_true }
      AssetPipeline::StaticAssets::Compiler.check(output_root: output).assets.should eq(first.assets)
    end
  end

  it "reports missing and out-of-root references with the referring asset" do
    with_static_asset_fixture do |source, output, _root|
      File.write(source.join("stylesheets/app.css"), ".bad { background: url('../images/missing.svg'); }")
      error = expect_raises(AssetPipeline::StaticAssets::InvalidReferenceError) do
        AssetPipeline::StaticAssets::Compiler.new(source_root: source, output_root: output).build
      end
      error.message.to_s.should contain("stylesheets/app.css")
      error.message.to_s.should contain("images/missing.svg")

      File.write(source.join("stylesheets/app.css"), ".bad { background: url('../../../outside.svg'); }")
      expect_raises(AssetPipeline::StaticAssets::InvalidReferenceError, /escapes source root/) do
        AssetPipeline::StaticAssets::Compiler.new(source_root: source, output_root: output).build
      end
    end
  end

  it "rejects output nested in source and symlinks that escape source root" do
    with_static_asset_fixture do |source, output, root|
      expect_raises(AssetPipeline::StaticAssets::ConfigurationError, /must not be inside source root/) do
        AssetPipeline::StaticAssets::Compiler.new(source_root: source, output_root: source.join("compiled"))
      end

      outside = root.join("outside.svg")
      File.write(outside, "outside")
      File.symlink(outside, source.join("images/escape.svg"))
      expect_raises(AssetPipeline::StaticAssets::ConfigurationError, /symlink escapes source root/) do
        AssetPipeline::StaticAssets::Compiler.new(source_root: source, output_root: output).build
      end
    end
  end

  it "is exposed by the top-level asset_pipeline require" do
    AssetPipeline::StaticAssets::MANIFEST_SCHEMA_VERSION.should eq(1)
  end
end
