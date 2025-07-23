require "../src/asset_pipeline"

# Phase 2 Enhanced Dependency Analysis Example
# This example demonstrates the advanced dependency detection and analysis capabilities
# introduced in Phase 2 of the implementation plan.

puts "=== AssetPipeline Phase 2: Enhanced Dependency Analysis ==="
puts

# Create a FrontLoader with some basic imports (but missing others intentionally)
front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  # Main application import map - intentionally missing some dependencies
  app_map = AssetPipeline::ImportMap.new("application")
  app_map.add_import("HelloController", "controllers/hello_controller.js")
  app_map.add_import("ExistingUtility", "utils/existing_utility.js")
  # Note: We're NOT adding jQuery, Chart.js, Moment.js to demonstrate dependency detection
  
  import_maps << app_map
end

puts "1. DEPENDENCY ANALYSIS: Automatic Detection of Missing Libraries"
puts "=" * 60

# JavaScript code that uses libraries not in the import map
problematic_js = <<-JS
// jQuery usage (missing from import map)
$(document).ready(function() {
  $('.modal').fadeIn();
  $('#app').on('click', '.button', function(e) {
    e.preventDefault();
  });
});

// Chart.js usage (missing from import map)
const chart = new Chart(document.getElementById('sales-chart'), {
  type: 'bar',
  data: {
    labels: ['Jan', 'Feb', 'Mar'],
    datasets: [{
      label: 'Sales',
      data: [12, 19, 3]
    }]
  }
});

// Moment.js usage (missing from import map)
const formattedDate = moment().format('YYYY-MM-DD');
console.log('Current date:', formattedDate);

// Local classes that might need imports
const validator = new FormValidator(document.getElementById('form'));
const helper = new MissingHelper();

// Existing utility (should not trigger warnings)
ExistingUtility.setup();
JS

# Analyze dependencies automatically
analysis = front_loader.analyze_javascript_dependencies(problematic_js)

puts "External dependencies detected: #{analysis[:external].join(", ")}"
puts "Local modules detected: #{analysis[:local].join(", ")}"
puts

puts "2. IMPORT SUGGESTIONS: Automatic CDN and Local Module Recommendations"
puts "=" * 70

suggestions = front_loader.get_dependency_suggestions(problematic_js)
puts "The dependency analyzer suggests:"
suggestions.each { |suggestion| puts "  ✓ #{suggestion}" }
puts

puts "3. ENHANCED SCRIPT RENDERING: Automatic Warnings in Development"
puts "=" * 65

enhanced_script = front_loader.render_initialization_script_with_analysis(problematic_js)
puts "Generated script with dependency warnings:"
puts enhanced_script
puts

puts "4. CODE COMPLEXITY ANALYSIS: Refactoring Suggestions"
puts "=" * 50

# Create a complex JavaScript block to demonstrate complexity analysis
complex_js = <<-JS
#{(1..60).map { |i| "console.log('Processing item #{i}');" }.join("\n")}

function setupApplication() {
  console.log('Setting up app');
}

function initializeModules() {
  console.log('Initializing modules');
}

function configureRoutes() {
  console.log('Configuring routes');
}

function setupEventListeners() {
  console.log('Setting up events');
}

function validateForms() {
  console.log('Validating forms');
}

function processData() {
  console.log('Processing data');
}

function renderComponents() {
  console.log('Rendering components');
}

// Many event listeners
document.addEventListener('DOMContentLoaded', setupApplication);
window.addEventListener('load', initializeModules);
document.addEventListener('click', handleClicks);
form.addEventListener('submit', handleSubmit);
input.addEventListener('change', handleChange);

// jQuery usage
$('.modal').on('show.bs.modal', function() {
  console.log('Modal shown');
});
JS

complexity = front_loader.analyze_code_complexity(complex_js)
puts "Code complexity metrics:"
puts "  - Lines of code: #{complexity[:lines]}"
puts "  - Functions: #{complexity[:functions]}"
puts "  - Classes: #{complexity[:classes]}"
puts "  - Event listeners: #{complexity[:event_listeners]}"
puts

if complexity[:suggestions].any?
  puts "Refactoring suggestions:"
  complexity[:suggestions].each { |suggestion| puts "  📝 #{suggestion}" }
else
  puts "✓ Code complexity is within acceptable limits"
end
puts

puts "5. DEVELOPMENT REPORT: Comprehensive Analysis for Debugging"
puts "=" * 60

report = front_loader.generate_dependency_report(problematic_js)
puts report
puts

puts "6. COMPARISON: Enhanced vs Basic Script Generation"
puts "=" * 50

# Fix the import map by adding missing dependencies
import_map = front_loader.get_import_map
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")
import_map.add_import("chartjs", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm")
import_map.add_import("moment", "https://cdn.jsdelivr.net/npm/moment@2.29.4/+esm")

simple_js = <<-JS
// Simple JavaScript that uses our newly added libraries
$('#app').fadeIn();
const chart = new Chart(ctx, { type: 'line' });
console.log(moment().format('dddd'));
JS

puts "BASIC script rendering:"
basic_script = front_loader.render_initialization_script(simple_js)
puts basic_script
puts

puts "ENHANCED script rendering (with analysis):"
enhanced_script_fixed = front_loader.render_initialization_script_with_analysis(simple_js)
puts enhanced_script_fixed
puts

puts "7. FRAMEWORK DETECTION: Module Syntax Analysis"
puts "=" * 45

modern_js = <<-JS
import { debounce } from './utils/debounce.js';
import ApiClient from './services/api_client.js';

export class ModernComponent {
  constructor() {
    this.api = new ApiClient();
  }
  
  async loadData() {
    const data = await this.api.get('/data');
    return data;
  }
}

export default ModernComponent;
JS

# Test module syntax detection
analyzer_modern = AssetPipeline::DependencyAnalyzer.new(modern_js)
puts "Uses modern module syntax: #{analyzer_modern.uses_module_syntax?}"

existing_imports = analyzer_modern.extract_existing_imports
puts "Existing imports found: #{existing_imports.join(", ")}"
puts

legacy_js = <<-JS
// Old-style JavaScript
function LegacyWidget() {
  this.initialized = false;
}

LegacyWidget.prototype.init = function() {
  this.initialized = true;
  console.log('Legacy widget initialized');
};

var widget = new LegacyWidget();
widget.init();
JS

analyzer_legacy = AssetPipeline::DependencyAnalyzer.new(legacy_js)
puts "Legacy code uses module syntax: #{analyzer_legacy.uses_module_syntax?}"
puts

puts "=== Phase 2 Implementation Complete! ==="
puts
puts "🎯 Key Features Demonstrated:"
puts "  ✅ Automatic external library detection (jQuery, Chart.js, Moment.js, etc.)"
puts "  ✅ Local module dependency detection"
puts "  ✅ CDN import suggestions with specific versions"
puts "  ✅ Code complexity analysis with refactoring suggestions"
puts "  ✅ Enhanced script rendering with development warnings"
puts "  ✅ Comprehensive development reports for debugging"
puts "  ✅ Module syntax detection (ES6 vs legacy)"
puts "  ✅ Backwards compatibility with existing functionality"
puts
puts "🔧 Practical Benefits:"
puts "  • Faster development with automatic dependency detection"
puts "  • Reduced errors from missing imports"
puts "  • Better code organization suggestions"
puts "  • Development-time warnings and guidance"
puts "  • Comprehensive analysis for debugging complex JavaScript"
puts
puts "This establishes the foundation for Phase 3: Enhanced Stimulus-Specific Implementation" 