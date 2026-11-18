# Linkage probe: everything `require "asset_pipeline"` loads, exercised end to end.
# scripts/check_default_require_linkage.rb builds this program and checks that
# the binary links no libpcre2.

require "../../../src/asset_pipeline"

front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  import_map = AssetPipeline::ImportMap.new
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("HelloController", "hello_controller.js")
  import_map.add_scope("/admin/", "admin", "./admin.js")
  import_map.auto_categorize_imports!
  import_maps << import_map
end

custom_javascript = <<-JS
  import NavController from "./nav_controller.js";
  Stimulus.register("nav", NavController);
  const chart = new Chart(document.body, {});
  $(".menu").show();
  JS

print front_loader.render_import_map_tag
print front_loader.render_stimulus_initialization_script(custom_javascript)
print front_loader.render_initialization_script_with_analysis(custom_javascript)
print front_loader.generate_dependency_report(custom_javascript)
print front_loader.analyze_code_complexity(custom_javascript)
print AssetPipeline::FrameworkRegistry.detect_framework("HelloController")

# Static assets: fingerprint a stylesheet and a script with a source map
# comment, then verify the manifest against the files on disk.
probe_root = Path[Dir.tempdir].join("asset_pipeline_linkage_probe_#{Process.pid}")
source_root = probe_root.join("source")
Dir.mkdir_p(source_root)
File.write(source_root.join("app.css"), %(body { background: url("logo.svg?v=1#mark"); } .remote { background: url("https://example.test/a.svg"); }))
File.write(source_root.join("logo.svg"), %(<svg xmlns="http://www.w3.org/2000/svg"></svg>))
File.write(source_root.join("app.js"), %(import "./util.js";\n//# sourceMappingURL=app.js.map\n))
File.write(source_root.join("util.js"), %(export const ready = true;\n))
File.write(source_root.join("app.js.map"), %({"version":3,"sources":[],"mappings":""}))
begin
  compiler = AssetPipeline::StaticAssets::Compiler.new(source_root: source_root, output_root: probe_root.join("public"), public_path: "/assets//")
  manifest = compiler.build
  manifest.verify(probe_root.join("public"))
  print manifest.path("app.js")
ensure
  FileUtils.rm_rf(probe_root)
end
