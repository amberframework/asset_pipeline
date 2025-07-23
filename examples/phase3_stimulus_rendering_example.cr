require "../src/asset_pipeline"

# Phase 3: Stimulus-Specific Implementation Example
# This example demonstrates the complete Stimulus rendering functionality

# Create a front loader with import map containing Stimulus controllers
front_loader = AssetPipeline::FrontLoader.new

# Get the default import map and add Stimulus controllers
import_map = front_loader.get_import_map

# Add Stimulus framework
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Add some Stimulus controllers to the import map
import_map.add_import("HelloController", "hello_controller.js")
import_map.add_import("ModalController", "modal_controller.js") 
import_map.add_import("ToggleController", "toggle_controller.js")
import_map.add_import("FormValidationController", "form_validation_controller.js")

# Add some non-controller imports (these should be ignored by StimulusRenderer)
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
import_map.add_import("utils", "utils.js")

puts "=== Phase 3: Stimulus Rendering Example ==="
puts

# Example 1: Basic Stimulus script with automatic controller detection
puts "1. Basic Stimulus initialization with automatic controller detection:"
puts "   Controllers will be auto-detected from import map entries ending in 'Controller'"
puts

basic_stimulus_script = front_loader.render_stimulus_initialization_script
puts basic_stimulus_script
puts
puts "-" * 80
puts

# Example 2: Stimulus script with custom JavaScript initialization block
puts "2. Stimulus initialization with custom JavaScript block:"
puts "   Custom code is preserved while automatic imports/registrations are added"
puts

custom_js_block = <<-JS
// Custom application configuration
console.log('Initializing Stimulus application...');

// Custom event listeners
document.addEventListener('DOMContentLoaded', () => {
  console.log('DOM loaded, Stimulus controllers registered');
});

// Custom utility functions
window.AppUtils = {
  showNotification: (message) => {
    console.log('Notification:', message);
  }
};
JS

stimulus_with_custom_js = front_loader.render_stimulus_initialization_script(custom_js_block)
puts stimulus_with_custom_js
puts
puts "-" * 80
puts

# Example 3: Demonstrate duplicate filtering - custom JS with redundant imports/registrations
puts "3. Smart filtering - removes duplicates from custom JavaScript:"
puts "   StimulusRenderer automatically filters out redundant imports and registrations"
puts

redundant_custom_js = <<-JS
import HelloController from "hello_controller";
import ModalController from "modal_controller";
import { Application } from "@hotwired/stimulus";

const app = Application.start();
Stimulus.register("hello", HelloController);
Stimulus.register("modal", ModalController);

// This custom code will be preserved
console.log('Custom initialization logic');
document.body.setAttribute('data-stimulus-loaded', 'true');
JS

filtered_script = front_loader.render_stimulus_initialization_script(redundant_custom_js)
puts filtered_script
puts
puts "-" * 80
puts

# Example 4: Custom application name
puts "4. Custom Stimulus application name:"
puts "   Using a custom application name instead of the default 'application'"
puts

# Create a new StimulusRenderer directly to demonstrate custom application name
stimulus_renderer = AssetPipeline::Stimulus::StimulusRenderer.new(
  import_map, 
  "console.log('MyApp Stimulus initialized');", 
  "MyApp"
)

custom_app_script = stimulus_renderer.render_stimulus_initialization_script
puts custom_app_script
puts
puts "-" * 80
puts

# Example 5: Advanced controller detection from custom JavaScript
puts "5. Advanced controller detection from custom JavaScript patterns:"
puts "   Detects controllers from Stimulus.register() calls and import statements"
puts

advanced_custom_js = <<-JS
// These controllers will be detected and auto-registered
import CustomController from "custom_controller";
import AnotherController from "another_controller";

// This registration pattern will be detected
Stimulus.register("special", SpecialController);

// Custom initialization logic
console.log('Advanced controller setup complete');

// Custom controller extensions
CustomController.prototype.customMethod = function() {
  console.log('Custom method called');
};
JS

advanced_renderer = AssetPipeline::Stimulus::StimulusRenderer.new(import_map, advanced_custom_js)
advanced_script = advanced_renderer.render_stimulus_initialization_script
puts advanced_script
puts
puts "-" * 80
puts

# Example 6: Demonstrate controller name conversion
puts "6. Controller name conversion examples:"
puts "   Shows how PascalCase controller names become kebab-case Stimulus identifiers"
puts

# Add controllers with various naming patterns
conversion_import_map = AssetPipeline::ImportMap.new
conversion_import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm")
conversion_import_map.add_import("HelloController", "hello_controller.js")
conversion_import_map.add_import("MySpecialController", "my_special_controller.js") 
conversion_import_map.add_import("HTMLElementController", "html_element_controller.js")
conversion_import_map.add_import("ModalController", "modal_controller.js")

conversion_renderer = AssetPipeline::Stimulus::StimulusRenderer.new(conversion_import_map)
conversion_script = conversion_renderer.render_stimulus_initialization_script
puts conversion_script

puts
puts "=== Controller Name Conversion Table ==="
puts "HelloController        → 'hello'"
puts "MySpecialController    → 'my-special'" 
puts "HTMLElementController  → 'h-t-m-l-element'"
puts "ModalController        → 'modal'"
puts
puts "-" * 80
puts

puts "=== Phase 3 Implementation Complete! ==="
puts
puts "The StimulusRenderer provides:"
puts "✅ Automatic controller detection from import map entries"
puts "✅ Smart filtering of duplicate imports and registrations"
puts "✅ PascalCase to kebab-case controller name conversion"
puts "✅ Custom application name support"
puts "✅ Integration of custom JavaScript blocks"
puts "✅ Complete Stimulus application setup and initialization"
puts "✅ Framework-agnostic separation (extends ScriptRenderer)"
puts
puts "Next up: Phase 4 - Integration and API Enhancement" 