require "../src/asset_pipeline"

# Enhanced Import Map Script Generation Example
# This example demonstrates the new automatic script generation capabilities
# introduced in Phase 1 of the implementation plan.

puts "=== Enhanced AssetPipeline Script Generation Example ==="
puts

# Create a FrontLoader with some JavaScript imports
front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  # Main application import map
  app_map = AssetPipeline::ImportMap.new("application")
  app_map.add_import("HelloController", "controllers/hello_controller.js")
  app_map.add_import("ModalController", "controllers/modal_controller.js")
  app_map.add_import("ToggleController", "controllers/toggle_controller.js")
  app_map.add_import("jQuery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")
  app_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
  
  import_maps << app_map
  
  # Admin area import map
  admin_map = AssetPipeline::ImportMap.new("admin")
  admin_map.add_import("AdminController", "admin/admin_controller.js")
  admin_map.add_import("DataTableController", "admin/data_table_controller.js")
  admin_map.add_import("chartjs", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm")
  
  import_maps << admin_map
end

puts "1. Traditional Import Map Generation (existing functionality):"
puts front_loader.render_import_map_tag
puts

puts "2. General JavaScript Initialization Script:"
custom_js = <<-JS
// Initialize jQuery when DOM is ready
jQuery(document).ready(function($) {
  console.log('jQuery loaded and ready!');
  
  // Initialize any non-Stimulus functionality
  initializeUtilities();
});

function initializeUtilities() {
  console.log('Utilities initialized');
}
JS

general_script = front_loader.render_initialization_script(custom_js)
puts general_script
puts

puts "3. Stimulus-Specific Initialization Script (auto-detects controllers):"
stimulus_custom_js = <<-JS
// Custom Stimulus setup
console.log('Setting up Stimulus application...');

// Custom controller-specific initialization
HelloController.setupDefaults();

// Global event listeners that work with Stimulus
document.addEventListener('stimulus:connect', function(event) {
  console.log('Controller connected:', event.detail.identifier);
});
JS

stimulus_script = front_loader.render_stimulus_initialization_script(stimulus_custom_js)
puts stimulus_script
puts

puts "4. Admin Area Stimulus Script (using named import map):"
admin_custom_js = <<-JS
// Admin-specific initialization
console.log('Admin area Stimulus setup');

// Configure admin-specific behavior
AdminController.setPermissions(['admin', 'manager']);
JS

admin_script = front_loader.render_stimulus_initialization_script(admin_custom_js, "admin")
puts admin_script
puts

puts "5. Demonstration of automatic controller detection and registration:"
puts "   - HelloController -> application.register('hello', HelloController)"
puts "   - ModalController -> application.register('modal', ModalController)"
puts "   - ToggleController -> application.register('toggle', ToggleController)"
puts "   - AdminController -> application.register('admin', AdminController)"
puts "   - DataTableController -> application.register('data-table', DataTableController)"
puts

puts "6. Framework separation demonstration:"
puts "   - General script renderer: handles any JavaScript libraries (jQuery, lodash, etc.)"
puts "   - Stimulus renderer: specifically handles Stimulus controllers and application setup"
puts "   - Both maintain clean separation while sharing the same import map infrastructure"
puts

puts "=== Example Complete ==="
puts "This demonstrates Phase 1 implementation of the enhanced import map script generation."
puts "Features implemented:"
puts "- ✅ General ScriptRenderer class for framework-agnostic JavaScript"
puts "- ✅ AssetPipeline::Stimulus::StimulusRenderer for Stimulus-specific functionality"  
puts "- ✅ Integration with FrontLoader via render_initialization_script() and render_stimulus_initialization_script()"
puts "- ✅ Automatic controller detection and registration"
puts "- ✅ Smart import statement generation (default vs bare imports)"
puts "- ✅ Duplicate code filtering in custom JavaScript blocks"
puts "- ✅ Support for multiple named import maps"
puts "- ✅ Full backwards compatibility with existing functionality" 