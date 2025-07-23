require "../src/asset_pipeline"

# Phase 5: Stimulus Controller Auto-Detection and Setup Examples
# This example demonstrates the advanced Stimulus functionality including auto-detection,
# smart filtering, and comprehensive controller setup

puts "=== Phase 5: Stimulus Controller Auto-Detection and Setup Examples ==="
puts

# Example 1: Auto-detection of Stimulus controllers from custom JavaScript
puts "1. Auto-detection of Stimulus controllers from custom JavaScript"
puts "   Demonstrating automatic controller detection and import generation"
puts

front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Add Stimulus framework
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Custom JavaScript with various Stimulus patterns
custom_js = <<-JS
  // Various Stimulus controller patterns that should be auto-detected
  import HelloController from "hello_controller.js"
  import ModalController from "./controllers/modal_controller.js"
  import { DropdownController } from "dropdown_controller"
  
  // Register controllers manually (should be detected and not duplicated)
  application.register("hello", HelloController)
  application.register("modal", ModalController)
  
  // Use controllers in HTML-like references (should be detected)
  document.querySelector('[data-controller="toggle"]')
  document.querySelector('[data-controller="search-form"]')
  
  // Initialize the application
  application.start()
  
  console.log("Stimulus application started with controllers")
JS

puts "Custom JavaScript block:"
puts custom_js
puts

result = front_loader.render_stimulus_initialization_script(custom_js)
puts "Generated Stimulus script with auto-detection:"
puts result
puts

# Example 2: Smart filtering - avoiding duplicate imports and registrations
puts "2. Smart filtering - avoiding duplicate imports and registrations"
puts "   Controllers already in import map should not generate warnings"
puts

# Add controllers to import map first
import_map.add_import("HelloController", "hello_controller.js")
import_map.add_import("ModalController", "modal_controller.js")
import_map.add_import("ToggleController", "toggle_controller.js")

# Same custom JS, but now should not generate duplicate warnings
result_with_existing = front_loader.render_stimulus_initialization_script(custom_js)
puts "Generated script with existing controllers (no duplicates):"
puts result_with_existing
puts

# Example 3: PascalCase to kebab-case controller name conversion
puts "3. PascalCase to kebab-case controller name conversion"
puts "   Demonstrating automatic naming convention handling"
puts

advanced_js = <<-JS
  // Controllers with various naming patterns
  import SearchFormController from "search_form_controller.js"
  import UserProfileController from "user_profile_controller.js"
  import NavBarController from "nav_bar_controller.js"
  
  // These should be auto-registered with correct kebab-case names:
  // search-form, user-profile, nav-bar
JS

puts "Advanced controller naming JavaScript:"
puts advanced_js
puts

result_naming = front_loader.render_stimulus_initialization_script(advanced_js)
puts "Generated script with proper naming conversions:"
puts result_naming
puts

# Example 4: Custom application name support
puts "4. Custom application name support"
puts "   Using a custom Stimulus application name instead of default 'application'"
puts

import_map_custom = AssetPipeline::ImportMap.new("customApp")
import_map_custom.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

renderer_custom = AssetPipeline::Stimulus::StimulusRenderer.new(import_map_custom, advanced_js, "myCustomApp")
result_custom = renderer_custom.render_stimulus_initialization_script

puts "Generated script with custom application name 'myCustomApp':"
puts result_custom
puts

# Example 5: Framework-agnostic separation demonstration
puts "5. Framework-agnostic separation demonstration"
puts "   StimulusRenderer extends ScriptRenderer - can handle general JavaScript too"
puts

mixed_js = <<-JS
  // Stimulus controllers
  import HelloController from "hello_controller.js"
  
  // General JavaScript libraries
  import { debounce } from "lodash"
  import dayjs from "dayjs"
  
  // Mixed functionality
  const debouncedSearch = debounce((query) => {
    console.log("Searching for:", query)
  }, 300)
  
  application.register("hello", HelloController)
  application.start()
  
  console.log("Current time:", dayjs().format())
JS

puts "Mixed JavaScript (Stimulus + general libraries):"
puts mixed_js
puts

result_mixed = front_loader.render_stimulus_initialization_script(mixed_js)
puts "Generated script handling both Stimulus and general JavaScript:"
puts result_mixed
puts

# Example 6: Integration with dependency analysis
puts "6. Integration with dependency analysis"
puts "   Using render_initialization_script_with_analysis for comprehensive warnings"
puts

# Remove some imports to generate warnings
front_loader_clean = AssetPipeline::FrontLoader.new
clean_import_map = front_loader_clean.get_import_map
clean_import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

result_with_analysis = front_loader_clean.render_initialization_script_with_analysis(mixed_js)
puts "Generated script with dependency analysis warnings:"
puts result_with_analysis
puts

puts "=== All Stimulus Controller Examples Completed Successfully ===" 