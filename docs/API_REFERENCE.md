# AssetPipeline API Reference

This document provides comprehensive API reference for the AssetPipeline library, covering all functionality from basic import map management to advanced Stimulus framework integration.

## Table of Contents

- [Core Classes](#core-classes)
  - [FrontLoader](#frontloader)
  - [ImportMap](#importmap)
  - [ScriptRenderer](#scriptrenderer)
  - [StimulusRenderer](#stimulusrenderer)
  - [DependencyAnalyzer](#dependencyanalyzer)
  - [FrameworkRegistry](#frameworkregistry)
- [Quick Start](#quick-start)
- [Usage Examples](#usage-examples)
- [Migration Guide](#migration-guide)

---

## Core Classes

### FrontLoader

The main entry point for AssetPipeline functionality. Manages import maps and provides high-level script rendering methods.

#### Constructor

```crystal
AssetPipeline::FrontLoader.new(
  js_source_path: Path = Path["app/javascript"],
  js_output_path: Path = Path["public/assets"],
  clear_cache_upon_change: Bool = true
)
```

**Parameters:**
- `js_source_path`: Directory containing JavaScript source files
- `js_output_path`: Directory for compiled JavaScript output
- `clear_cache_upon_change`: Whether to clear old files when content changes

#### Block Constructor

```crystal
AssetPipeline::FrontLoader.new do |import_maps|
  import_maps << AssetPipeline::ImportMap.new("application")
  import_maps << AssetPipeline::ImportMap.new("admin")
end
```

Allows configuration of multiple import maps during initialization.

#### Core Methods

##### `#get_import_map(name : String = "application") : ImportMap`

Retrieves an import map by name.

```crystal
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map # Gets "application" import map
admin_map = front_loader.get_import_map("admin") # Gets "admin" import map
```

**Raises:** `Exception` if import map doesn't exist

##### `#render_import_map_tag(import_map_name : String = "application") : String`

Renders the import map as an HTML `<script type="importmap">` tag.

```crystal
front_loader.render_import_map_tag
# Returns: <script type="importmap">{"imports": {...}}</script>
```

##### `#render_import_map_as_file(import_map_name : String = "application") : String`

Renders the import map as a reference to an external JSON file.

```crystal
front_loader.render_import_map_as_file
# Returns: <script type="importmap" src="/application-[hash].json"></script>
```

#### Script Rendering Methods (New in Phases 1-5)

##### `#render_initialization_script(custom_js_block : String = "", import_map_name : String = "application") : String`

**Phase 2 Enhancement:** Renders general JavaScript initialization script with automatic import generation.

```crystal
custom_js = "console.log('App started'); $('.modal').fadeIn();"
result = front_loader.render_initialization_script(custom_js)
```

**Features:**
- Automatically generates import statements for libraries in import map
- Detects capitalized names as default imports (`import ClassName from "ClassName"`)
- Detects lowercase names as bare imports (`import "library"`)
- Returns empty string if no imports or custom JavaScript

**Example Output:**
```html
<script type="module">
import $ from "jquery";
import "lodash";

console.log('App started');
$('.modal').fadeIn();
</script>
```

##### `#render_stimulus_initialization_script(custom_js_block : String = "", import_map_name : String = "application", app_name : String = "application") : String`

**Phase 3 Implementation:** Renders Stimulus-specific initialization script with automatic controller detection and registration.

```crystal
custom_js = "console.log('Stimulus ready!');"
result = front_loader.render_stimulus_initialization_script(custom_js)
```

**Features:**
- Automatically detects controllers from import map (entries ending in "Controller")
- Generates Stimulus application setup (`Application.start()`)
- Converts PascalCase controller names to kebab-case identifiers
- Removes duplicate import/registration statements from custom JavaScript
- Supports custom application names

**Example Output:**
```html
<script type="module">
import { Application } from "@hotwired/stimulus";

import HelloController from "HelloController";
import ModalController from "ModalController";

const application = Application.start();

console.log('Stimulus ready!');

application.register("hello", HelloController);
application.register("modal", ModalController);
</script>
```

##### `#render_initialization_script_with_analysis(custom_js_block : String = "", import_map_name : String = "application") : String`

**Phase 4 Enhancement:** Renders initialization script with dependency analysis and warnings for missing dependencies.

```crystal
js_with_missing_deps = "import { debounce } from 'lodash'; $('.app').show();"
result = front_loader.render_initialization_script_with_analysis(js_with_missing_deps)
```

**Features:**
- Analyzes custom JavaScript for external dependencies
- Provides warnings for libraries not in import map
- Suggests specific `import_map.add_import()` calls
- Filters out dependencies already present in import map

**Example Output:**
```html
<script type="module">
// WARNING: Add to import map: import_map.add_import("lodash", "...")

import $ from "jquery";

import { debounce } from 'lodash';
$('.app').show();
</script>
```

#### Framework Support Methods (New in Phase 4)

##### `#framework_capabilities : Hash`

Returns information about supported frameworks and registry details.

```crystal
caps = front_loader.framework_capabilities
# Returns: {"supported_frameworks" => ["stimulus"], "registry_summary" => {...}}
```

---

### ImportMap

Manages JavaScript import maps with enhanced metadata support.

#### Constructor

```crystal
AssetPipeline::ImportMap.new(
  name: String = "application",
  public_asset_base_path: Path = Path["/"]
)
```

#### Core Methods

##### `#add_import(import_name : String, import_path : String, preload : Bool = false)`

Adds a basic import to the import map.

```crystal
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
import_map.add_import("HelloController", "hello_controller.js", preload: true)
```

##### `#add_import_with_metadata(import_name : String, import_path : String, preload : Bool = false, type : String? = nil, framework : String? = nil)`

**Phase 4 Enhancement:** Adds import with metadata for categorization.

```crystal
import_map.add_import_with_metadata(
  "HelloController", 
  "hello_controller.js", 
  preload: true,
  type: "controller",
  framework: "stimulus"
)
```

##### `#add_scope(scope_path : String, import_name : String, import_path : String)`

Adds scoped imports for path-specific module resolution.

```crystal
import_map.add_scope("/admin", "AdminController", "admin_controller.js")
```

#### Metadata Query Methods (New in Phase 4)

##### `#imports_by_type(type : String) : Array`

Returns imports filtered by type metadata.

```crystal
controllers = import_map.imports_by_type("controller")
libraries = import_map.imports_by_type("library")
```

##### `#imports_by_framework(framework : String) : Array`

Returns imports filtered by framework metadata.

```crystal
stimulus_imports = import_map.imports_by_framework("stimulus")
```

##### `#stimulus_controller_imports : Array`

Convenience method to get all Stimulus controller imports.

```crystal
controllers = import_map.stimulus_controller_imports
```

---

### ScriptRenderer

**Phase 2 Implementation:** Handles general JavaScript script generation with dependency analysis.

#### Constructor

```crystal
AssetPipeline::ScriptRenderer.new(
  import_map : ImportMap,
  custom_js_block : String = "",
  enable_dependency_analysis : Bool = false
)
```

#### Core Methods

##### `#render_initialization_script : String`

Renders the complete script with HTML tags.

##### `#generate_script_content : String`

Generates script content without HTML wrapper.

##### `#analyze_dependencies : Hash`

**Phase 2 Feature:** Analyzes custom JavaScript for dependencies.

```crystal
renderer = ScriptRenderer.new(import_map, custom_js, enable_dependency_analysis: true)
analysis = renderer.analyze_dependencies
# Returns: {external: ["lodash", "dayjs"], local: ["CustomClass"]}
```

##### `#get_import_suggestions : Array(String)`

**Phase 4 Enhancement:** Returns filtered import suggestions for missing dependencies.

```crystal
suggestions = renderer.get_import_suggestions
# Returns: ["// WARNING: Add to import map: import_map.add_import(\"lodash\", \"...\")"]
```

---

### StimulusRenderer

**Phase 3 Implementation:** Specialized renderer for Stimulus framework integration.

#### Constructor

```crystal
AssetPipeline::Stimulus::StimulusRenderer.new(
  import_map : ImportMap,
  custom_js_block : String = "",
  app_name : String = "application"
)
```

#### Core Methods

##### `#render_stimulus_initialization_script : String`

Renders complete Stimulus script with automatic controller detection.

##### `#generate_stimulus_script_content : String`

Generates Stimulus script content without HTML wrapper.

#### Controller Detection

- Automatically detects imports ending in "Controller"
- Converts PascalCase to kebab-case: `HelloController` → `"hello"`
- Removes duplicate registrations from custom JavaScript

---

### DependencyAnalyzer

**Phase 2 Implementation:** Analyzes JavaScript code for external dependencies.

#### Class Methods

##### `DependencyAnalyzer.analyze(javascript_code : String) : Hash`

Analyzes JavaScript code and categorizes dependencies.

```crystal
analysis = DependencyAnalyzer.analyze("import { debounce } from 'lodash';")
# Returns: {external: ["lodash"], local: []}
```

**Returns:**
- `external`: External library dependencies (npm packages, CDN libraries)
- `local`: Local module references (capitalized names, file paths)

---

### FrameworkRegistry

**Phase 4 Implementation:** Extensible registry for framework-specific renderers.

#### Class Methods

##### `FrameworkRegistry.supported_frameworks : Array(String)`

Returns list of supported framework names.

##### `FrameworkRegistry.register_framework(name, renderer_class_name, ...)`

Registers a new framework renderer (for future extensions).

---

## Quick Start

### Basic Setup

```crystal
require "asset_pipeline"

# Initialize with default settings
front_loader = AssetPipeline::FrontLoader.new

# Get the default import map
import_map = front_loader.get_import_map

# Add your JavaScript dependencies
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")

# Render in your HTML template
puts front_loader.render_import_map_tag
puts front_loader.render_initialization_script("$('#app').fadeIn();")
```

### Stimulus Setup

```crystal
# Add Stimulus framework and controllers
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("HelloController", "hello_controller.js")
import_map.add_import("ModalController", "modal_controller.js")

# Render Stimulus initialization
custom_js = "console.log('Stimulus app ready!');"
puts front_loader.render_stimulus_initialization_script(custom_js)
```

---

## Error Handling

### Common Exceptions

- **Import map not found**: Thrown when requesting non-existent import map
- **Invalid scope path**: Thrown when scope doesn't start with `/`, `./`, or `../`

### Graceful Degradation

- Empty import maps render empty scripts
- Malformed JavaScript is passed through (not validated)
- Missing dependencies generate warnings, not errors

---

## Performance Considerations

- Import maps are cached after first generation
- File fingerprinting uses SHA256 hashing
- Dependency analysis is optional (disabled by default)
- Controller detection happens during initialization

---

## Version Compatibility

**Current Version**: 0.36.0

### Breaking Changes
None - all new functionality is additive and backwards compatible.

### Deprecated Features
None - all existing APIs remain supported.

---

## See Also

- [Usage Examples](USAGE_EXAMPLES.md)
- [Migration Guide](MIGRATION_GUIDE.md)
- [Framework-Specific Documentation](FRAMEWORK_DOCS.md) 