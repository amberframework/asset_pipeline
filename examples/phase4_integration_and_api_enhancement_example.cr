require "../src/asset_pipeline"

# Phase 4: Integration and API Enhancement Example
# This example demonstrates the enhanced import map integration and extensible architecture

puts "=== Phase 4: Integration and API Enhancement Example ==="
puts

# Create a front loader with enhanced import map capabilities
front_loader = AssetPipeline::FrontLoader.new

# Get the default import map
import_map = front_loader.get_import_map

puts "1. Enhanced Import Map with Metadata Support"
puts "   Adding imports with type and framework metadata"
puts

# Add imports using the new metadata-aware methods
import_map.add_import_with_metadata("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", 
                                    preload: true, type: "framework", framework: "stimulus")

import_map.add_import_with_metadata("HelloController", "hello_controller.js", 
                                    type: "controller", framework: "stimulus")
import_map.add_import_with_metadata("ModalController", "modal_controller.js", 
                                    type: "controller", framework: "stimulus")
import_map.add_import_with_metadata("ToggleController", "toggle_controller.js", 
                                    type: "controller", framework: "stimulus")

import_map.add_import_with_metadata("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm", 
                                    type: "library")
import_map.add_import_with_metadata("utils", "utils.js", 
                                    type: "utility")

# Add some imports without metadata (to demonstrate auto-categorization)
import_map.add_import("FormValidationController", "form_validation_controller.js")
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.6.0/+esm")

puts "2. Import Categorization and Filtering"
puts "   Demonstrating import filtering by type and framework"
puts

# Demonstrate filtering capabilities
stimulus_controllers = import_map.stimulus_controller_imports
puts "Stimulus Controllers: #{stimulus_controllers.size} found"
stimulus_controllers.each do |controller|
  puts "  - #{controller.first_key} (#{controller["type"]?}/#{controller["framework"]?})"
end
puts

framework_imports = import_map.imports_by_framework("stimulus")
puts "All Stimulus-related imports: #{framework_imports.size} found"
framework_imports.each do |import_entry|
  puts "  - #{import_entry.first_key} → #{import_entry.first_value}"
end
puts

library_imports = import_map.imports_by_type("library")
puts "Library imports: #{library_imports.size} found"
library_imports.each do |import_entry|
  puts "  - #{import_entry.first_key} → #{import_entry.first_value}"
end
puts

puts "3. Auto-categorization of Imports"
puts "   Automatically categorizing imports based on naming patterns"
puts

# Demonstrate auto-categorization
puts "Before auto-categorization:"
all_imports = import_map.imports
all_imports.each do |import_entry|
  type = import_entry["type"]? || "uncategorized"
  framework = import_entry["framework"]? || "none"
  puts "  - #{import_entry.first_key}: type=#{type}, framework=#{framework}"
end
puts

# Auto-categorize the uncategorized imports
import_map.auto_categorize_imports!

puts "After auto-categorization:"
all_imports.each do |import_entry|
  type = import_entry["type"]? || "uncategorized"
  framework = import_entry["framework"]? || "none"
  puts "  - #{import_entry.first_key}: type=#{type}, framework=#{framework}"
end
puts

puts "4. Import Map Summary and Analytics"
puts "   Comprehensive overview of import types and frameworks"
puts

summary = import_map.import_summary
puts "Import Summary:"
puts "  Types: #{summary["types"]}"
puts "  Frameworks: #{summary["frameworks"]}"
puts

puts "5. Framework Registry and Extensible Architecture"
puts "   Demonstrating the framework registry capabilities"
puts

# Demonstrate framework registry
capabilities = front_loader.framework_capabilities
puts "Supported Frameworks: #{capabilities["supported_frameworks"]}"
puts

registry_summary = capabilities["registry_summary"].as(Hash)
puts "Framework Registry Details:"
registry_summary.each do |key, value|
  puts "  #{key}: #{value}"
end
puts

puts "6. Generic Framework Script Rendering"
puts "   Using the generic render_framework_script method"
puts

# Demonstrate generic framework rendering
custom_js = <<-JS
// Custom Stimulus initialization
console.log('Framework-agnostic initialization');
document.addEventListener('DOMContentLoaded', () => {
  console.log('DOM loaded via framework registry');
});
JS

stimulus_via_registry = front_loader.render_framework_script("stimulus", custom_js)
puts "Stimulus script via framework registry:"
puts stimulus_via_registry
puts
puts "-" * 80
puts

puts "7. Enhanced Dependency Analysis"
puts "   Advanced dependency detection with detailed warnings"
puts

complex_js = <<-JS
// Complex JavaScript with various dependencies
import { customUtil } from './utils/custom.js';

// External library usage
$('#app').fadeIn();
moment().format('YYYY-MM-DD');
_.isEmpty(data);

// Local module usage
MyCustomClass.initialize();
AppHelpers.showNotification('Hello');

// Custom logic
console.log('Application starting...');
JS

analysis_script = front_loader.render_initialization_script_with_analysis(complex_js)
puts "Script with dependency analysis:"
puts analysis_script
puts
puts "-" * 80
puts

puts "8. Import Map Metadata Querying"
puts "   Advanced querying and filtering capabilities"
puts

# Demonstrate advanced querying
framework_agnostic = import_map.framework_agnostic_imports
puts "Framework-agnostic imports: #{framework_agnostic.size} found"
framework_agnostic.each do |import_entry|
  puts "  - #{import_entry.first_key}"
end
puts

# Demonstrate detection capabilities
test_names = ["MyController", "HelloController", "utils", "@hotwired/stimulus", "lodash"]
puts "Framework detection for various import names:"
test_names.each do |name|
  detected_framework = AssetPipeline::FrameworkRegistry.detect_framework(name)
  puts "  - '#{name}' → #{detected_framework || "none"}"
end
puts

puts "9. Future Framework Support Pattern"
puts "   Demonstrating how new frameworks could be added"
puts

# Show how the architecture supports future frameworks
puts "Current framework registry state:"
AssetPipeline::FrameworkRegistry.supported_frameworks.each do |framework|
  metadata = AssetPipeline::FrameworkRegistry.get_framework_metadata(framework)
  core_import = AssetPipeline::FrameworkRegistry.get_core_import(framework)
  puts "  - #{framework}: core='#{core_import}', description='#{metadata && metadata["description"]}'"
end
puts

puts "Example of how Alpine.js could be added:"
puts <<-EXAMPLE
# AssetPipeline::FrameworkRegistry.register_framework(
#   "alpine",
#   AssetPipeline::Alpine::AlpineRenderer,
#   patterns: [/x-data/, /Alpine/],
#   core_import: "alpinejs",
#   description: "Alpine.js lightweight framework"
# )
EXAMPLE
puts

puts "=== Phase 4 Implementation Complete! ==="
puts
puts "Enhanced features delivered:"
puts "✅ Import map metadata support for categorization"
puts "✅ Advanced filtering by type and framework"
puts "✅ Auto-categorization based on naming patterns"
puts "✅ Comprehensive import analytics and summaries"
puts "✅ Framework registry for extensible architecture"
puts "✅ Generic framework script rendering"
puts "✅ Enhanced dependency analysis with warnings"
puts "✅ Future-proof architecture for additional frameworks"
puts
puts "API enhancements:"
puts "  • add_import_with_metadata() - Enhanced import method"
puts "  • imports_by_type() / imports_by_framework() - Filtering"
puts "  • auto_categorize_imports!() - Automatic categorization"
puts "  • import_summary() - Analytics overview"
puts "  • render_framework_script() - Generic framework rendering"
puts "  • framework_capabilities() - Registry introspection"
puts
puts "Ready for Phase 5: Testing and Validation" 