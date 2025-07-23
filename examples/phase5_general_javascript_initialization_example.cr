require "../src/asset_pipeline"

# Phase 5: General JavaScript Initialization Examples
# This example demonstrates the framework-agnostic JavaScript functionality

puts "=== Phase 5: General JavaScript Initialization Examples ==="
puts

# Example 1: Basic JavaScript initialization with popular libraries
puts "1. Basic JavaScript initialization with popular libraries"
puts "   Demonstrating automatic dependency detection and import generation"
puts

front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Add some popular JavaScript libraries to the import map
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm", preload: true)
import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm", preload: true)
import_map.add_import("axios", "https://cdn.jsdelivr.net/npm/axios@1.6.0/+esm")

# Custom JavaScript block with various library usage
custom_js_basic = <<-JS
  // Initialize the application
  console.log('Initializing application...');
  
  // Use Lodash for data manipulation
  const users = _.uniqBy([
    { id: 1, name: 'John' },
    { id: 2, name: 'Jane' },
    { id: 1, name: 'John' }
  ], 'id');
  
  // Use Day.js for date formatting
  const currentDate = dayjs().format('YYYY-MM-DD');
  console.log('Current date:', currentDate);
  
  // Use Axios for API calls
  axios.get('/api/users')
    .then(response => console.log('Users loaded:', response.data))
    .catch(error => console.error('Error loading users:', error));
  
  console.log('Application initialized successfully');
JS

script_result = front_loader.render_initialization_script(custom_js_basic)
puts script_result
puts

# Example 2: Advanced initialization with dependency analysis
puts "2. Advanced initialization with dependency analysis warnings"
puts "   Shows missing dependencies and suggests import map additions"
puts

advanced_js = <<-JS
  // This example uses libraries not in the import map
  $('#app').fadeIn(); // jQuery - not in import map
  
  // Chart.js usage - not in import map
  const ctx = document.getElementById('myChart').getContext('2d');
  const myChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['Red', 'Blue', 'Yellow'],
      datasets: [{
        label: '# of Votes',
        data: [12, 19, 3]
      }]
    }
  });
  
  // Custom class usage - potential local module
  const modal = new CustomModal('#modal');
  modal.show();
  
  // Existing library usage (no warning expected)
  const result = _.map(users, 'name');
  console.log('User names:', result);
JS

analysis_result = front_loader.render_initialization_script_with_analysis(advanced_js)
puts analysis_result
puts

# Example 3: Complex application setup
puts "3. Complex application setup with multiple modules"
puts "   Demonstrates import map organization and modular initialization"
puts

# Create a more complex import map setup
complex_front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  # Main application import map
  main_map = AssetPipeline::ImportMap.new("application")
  main_map.add_import("AppCore", "core/app.js")
  main_map.add_import("Router", "core/router.js")
  main_map.add_import("EventBus", "core/event-bus.js")
  main_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm", preload: true)
  
  # Admin area import map
  admin_map = AssetPipeline::ImportMap.new("admin")
  admin_map.add_import("AdminPanel", "admin/panel.js")
  admin_map.add_import("UserManager", "admin/user-manager.js")
  admin_map.add_import("DataTable", "admin/data-table.js")
  admin_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm")
  
  import_maps << main_map
  import_maps << admin_map
end

# Main application initialization
main_init_js = <<-JS
  // Initialize core application
  const app = new AppCore({
    debug: true,
    apiBaseUrl: '/api'
  });
  
  // Setup routing
  const router = new Router();
  router.addRoute('/', () => console.log('Home page'));
  router.addRoute('/about', () => console.log('About page'));
  router.start();
  
  // Setup event bus for component communication
  const eventBus = new EventBus();
  eventBus.on('user:login', (user) => {
    console.log('User logged in:', user);
  });
  
  // Use utility library
  const config = _.defaults(app.getConfig(), {
    theme: 'light',
    language: 'en'
  });
  
  console.log('Main application initialized with config:', config);
JS

main_script = complex_front_loader.render_initialization_script(main_init_js, "application")
puts "Main application script:"
puts main_script
puts

# Admin area initialization
admin_init_js = <<-JS
  // Initialize admin panel
  const adminPanel = new AdminPanel('#admin-container');
  
  // Setup user management
  const userManager = new UserManager();
  userManager.loadUsers().then(users => {
    console.log('Loaded users for admin:', users);
  });
  
  // Initialize data table with Chart.js integration
  const dataTable = new DataTable('#users-table', {
    enableCharting: true,
    chartLibrary: Chart // Chart.js from CDN
  });
  
  // Setup admin-specific event handlers
  document.addEventListener('DOMContentLoaded', () => {
    adminPanel.render();
    dataTable.initialize();
    console.log('Admin interface ready');
  });
JS

admin_script = complex_front_loader.render_initialization_script(admin_init_js, "admin")
puts "Admin area script:"
puts admin_script
puts

# Example 4: Performance and development insights
puts "4. Performance and development insights"
puts "   Shows code complexity analysis and optimization suggestions"
puts

complex_performance_js = <<-JS
  // Complex initialization with performance considerations
  class ApplicationManager {
    constructor() {
      this.modules = new Map();
      this.eventListeners = [];
      this.timers = [];
    }
    
    async initialize() {
      await this.loadConfiguration();
      await this.setupModules();
      this.bindEvents();
      this.startBackgroundTasks();
      console.log('Application fully initialized');
    }
    
    async loadConfiguration() {
      const config = await fetch('/api/config').then(r => r.json());
      this.config = _.merge(this.getDefaultConfig(), config);
    }
    
    getDefaultConfig() {
      return {
        theme: 'light',
        language: 'en',
        debugging: false,
        performance: {
          enableMetrics: true,
          enableProfiling: false
        }
      };
    }
    
    async setupModules() {
      const moduleList = ['router', 'auth', 'ui', 'api'];
      for (const moduleName of moduleList) {
        try {
          const module = await import(`./modules/${moduleName}.js`);
          this.modules.set(moduleName, new module.default(this.config));
        } catch (error) {
          console.error(`Failed to load module ${moduleName}:`, error);
        }
      }
    }
    
    bindEvents() {
      // Performance-sensitive event binding
      const throttledResize = _.throttle(() => {
        this.handleResize();
      }, 100);
      
      const debouncedSearch = _.debounce((query) => {
        this.performSearch(query);
      }, 300);
      
      window.addEventListener('resize', throttledResize);
      document.getElementById('search').addEventListener('input', 
        (e) => debouncedSearch(e.target.value)
      );
    }
    
    handleResize() {
      this.modules.get('ui')?.handleResize();
    }
    
    performSearch(query) {
      if (query.length > 2) {
        this.modules.get('api')?.search(query);
      }
    }
    
    startBackgroundTasks() {
      // Cleanup timer - runs every 5 minutes
      this.timers.push(setInterval(() => {
        this.cleanup();
      }, 5 * 60 * 1000));
    }
    
    cleanup() {
      // Perform memory cleanup
      console.log('Performing scheduled cleanup...');
    }
  }
  
  // Initialize the application
  const appManager = new ApplicationManager();
  appManager.initialize().catch(error => {
    console.error('Application initialization failed:', error);
  });
JS

# Get analysis and suggestions
analyzer_result = complex_front_loader.analyze_javascript_dependencies(complex_performance_js)
complexity_analysis = complex_front_loader.analyze_code_complexity(complex_performance_js)

puts "Dependency analysis:"
puts analyzer_result.inspect
puts

puts "Code complexity analysis:"
puts complexity_analysis.inspect
puts

puts "=== Phase 5 Examples Complete ==="
puts "✅ Basic library integration with automatic imports"
puts "✅ Dependency analysis with missing library detection"  
puts "✅ Complex multi-map application organization"
puts "✅ Performance-oriented code with complexity analysis"
puts "✅ Framework-agnostic JavaScript patterns" 