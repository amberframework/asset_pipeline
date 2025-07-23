require "../src/asset_pipeline"

# Example demonstrating the clear_cache_upon_change feature
# This shows how automatic cache clearing works by default and how to opt out

# Previously, you had to manually clear the cache like this:
puts "=== OLD WAY (Manual Cache Clearing) ==="
JS_OUTPUT_PATH = Path["public/javascript"]

FRONT_LOADER_OLD_WAY = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"], 
  js_output_path: JS_OUTPUT_PATH
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])
  
  import_map.add_import("@hotwired/stimulus", "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js")
  import_map.add_import("login_controller", "src/javascript/login_controller.js")
  
  import_maps << import_map

  # Manual cache clearing - you had to do this yourself
  FileUtils.rm_rf(JS_OUTPUT_PATH) if Dir.exists?(JS_OUTPUT_PATH.to_s)
end

puts "Old way: Manual cache clearing with FileUtils.rm_rf"

# NOW WITH THE NEW FEATURE - AUTOMATIC BY DEFAULT:
puts "\n=== NEW WAY (Automatic Cache Clearing - DEFAULT BEHAVIOR) ==="

FRONT_LOADER_NEW_WAY = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"], 
  js_output_path: Path["public/javascript"]
  # clear_cache_upon_change defaults to TRUE now!
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])
  
  import_map.add_import("@hotwired/stimulus", "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js")
  import_map.add_import("login_controller", "src/javascript/login_controller.js")
  
  import_maps << import_map

  # No manual cache clearing needed! The shard handles it automatically by default
end

puts "New way: Automatic cache clearing is enabled by default!"

# OPT OUT FOR TROUBLESHOOTING:
puts "\n=== TROUBLESHOOTING MODE (Disable Cache Clearing) ==="

FRONT_LOADER_TROUBLESHOOT = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"], 
  js_output_path: Path["public/javascript"],
  clear_cache_upon_change: false  # Explicitly disable for troubleshooting
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])
  
  import_map.add_import("@hotwired/stimulus", "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js")
  import_map.add_import("login_controller", "src/javascript/login_controller.js")
  
  import_maps << import_map
end

puts "Troubleshooting mode: Cache clearing disabled for debugging"

# UNDERSTANDING CACHE CLEARING WITH FINGERPRINTING:
puts "\n=== UNDERSTANDING CACHE CLEARING WITH FINGERPRINTING ==="

puts "\nWhat happens with cache clearing ENABLED (default):"
puts "🔄 Old fingerprinted files are removed (e.g., login_controller-abc123.js)"
puts "✨ New fingerprinted files are generated (e.g., login_controller-xyz789.js if content changed)"
puts "♻️  Unchanged files may reuse same fingerprints (same content = same fingerprint)"
puts "📁 Result: Clean output directory with only current file versions"

puts "\nWhat happens with cache clearing DISABLED:"
puts "📦 Old fingerprinted files are preserved (e.g., login_controller-abc123.js stays)"
puts "➕ New fingerprinted files are added (e.g., login_controller-xyz789.js if content changed)"
puts "📚 Unchanged files are not duplicated (same content = same fingerprint = same file)"
puts "📁 Result: Output directory accumulates multiple versions of changed files"

puts "\nExample scenario:"
puts "1. Generate: login_controller-abc123.js, stimulus_controller-def456.js"
puts "2. Modify only login_controller.js content"
puts "3. Regenerate with cache clearing ON:"
puts "   → login_controller-xyz789.js (new), stimulus_controller-def456.js (reused)"
puts "4. Regenerate with cache clearing OFF:"
puts "   → login_controller-abc123.js (old), login_controller-xyz789.js (new), stimulus_controller-def456.js (unchanged)"

# Usage examples:
puts "\n=== USAGE EXAMPLES ==="

puts "Default behavior (recommended for most users):"
puts "FrontLoader.new(...) # Cache clearing enabled automatically"

puts "\nFor troubleshooting:"
puts "FrontLoader.new(..., clear_cache_upon_change: false) # Disable cache clearing"

puts "\nBenefits of the new default behavior:"
puts "✅ No need to manually call FileUtils.rm_rf"
puts "✅ Cache is only cleared once per FrontLoader instance"
puts "✅ Ensures old cached files don't accumulate"
puts "✅ Cleaner, more maintainable configuration code"
puts "✅ Better developer experience out of the box"

puts "\nWhen cache clearing is ideal (default behavior):"
puts "📈 During development when files change frequently"
puts "📈 In CI/CD pipelines to ensure fresh builds"
puts "📈 When you want to prevent cache bloat"
puts "📈 General usage for cleaner asset management"

puts "\nWhen to disable cache clearing (clear_cache_upon_change: false):"
puts "🔧 When troubleshooting cache-related issues"
puts "🔧 In specific production scenarios where you manage cache clearing elsewhere"
puts "🔧 When you need to preserve existing cached files for debugging" 