# Asset Pipeline

Asset Pipeline is a shard written to handle 3 types of assets:
- Javascript, by using ESM modules and import maps  (Done! v0.34)
- CSS/SASS, by utilizing Node SASS from an import map (TBD)
- Images (TBD)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     asset_pipeline:
       github: amberframework/asset_pipeline
       version: 0.36.0
   ```

2. Run `shards install`

## Usage

View the full documentation for the [current version here](https://amberframework.github.io/asset_pipeline/AssetPipeline/FrontLoader.html)

For the fullest examples, please view the docs for `AssetPipeline::FrontLoader`.

The `FrontLoader` class is the primary class to use for handling all of your assets with the AssetPipeline, including the `ImportMaps`.

## Features

### Automatic Cache Clearing

As of version 0.36.0, the Asset Pipeline includes automatic cache clearing to help manage cached files during development and deployment.

**Problem:** Previously, cached JavaScript files would accumulate in the output directory without being automatically cleaned up, requiring manual intervention.

**Solution:** Automatic cache clearing is now **enabled by default**! Just initialize your `FrontLoader` normally:

```crystal
# Automatic cache clearing is enabled by default
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"], 
  js_output_path: Path["public/javascript"]
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])
  import_map.add_import("@hotwired/stimulus", "https://unpkg.com/@hotwired/stimulus/dist/stimulus.js")
  import_maps << import_map
end
```

**To disable cache clearing (for troubleshooting):**
```crystal
# Explicitly disable cache clearing if needed
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"], 
  js_output_path: Path["public/javascript"],
  clear_cache_upon_change: false  # Disable automatic cache clearing
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])
  import_maps << import_map
end
```

**Before (Manual Cache Clearing):**
```crystal
JS_OUTPUT_PATH = Path["public/javascript"]

front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"], 
  js_output_path: JS_OUTPUT_PATH
) do |import_maps|
  import_map = AssetPipeline::ImportMap.new("application", Path["/javascript"])
  import_maps << import_map
  
  # Manual cache clearing required
  FileUtils.rm_rf(JS_OUTPUT_PATH)
end
```

**Benefits:**
- ✅ Eliminates the need for manual `FileUtils.rm_rf` calls
- ✅ Cache is cleared only once per `FrontLoader` instance
- ✅ Prevents accumulation of old cached files
- ✅ Enabled by default for better developer experience

**When automatic cache clearing is ideal (default behavior):**
- During development when files change frequently
- In CI/CD pipelines to ensure fresh builds
- When you want to prevent cache bloat
- General usage for cleaner asset management

**When to disable `clear_cache_upon_change: false`:**
- When troubleshooting cache-related issues
- In specific production scenarios where you manage cache clearing elsewhere
- When you need to preserve existing cached files for debugging

## Development

Thank you for your interest in contributing! Please join the Amber (discord)[https://discord.gg/JKCczAEh4D] to get the most up to date information.

If you're interested in contributing, please check out the open github issues and then ask about them in the discord group to see if anyone has made any attempts or has additional information about the issue.

## Contributing

1. Fork it (<https://github.com/your-github-user/asset_pipeline/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Seth Tucker](https://github.com/crimson-knight) - creator and maintainer
