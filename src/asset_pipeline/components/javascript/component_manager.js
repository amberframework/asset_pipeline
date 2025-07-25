/**
 * ComponentManager - Main API for managing the component system
 * 
 * This class provides:
 * - Centralized component system management
 * - Initialization and cleanup utilities
 * - Global component access and debugging
 * - Integration with ComponentRegistry
 */
class ComponentManager {
  constructor() {
    this.registry = new ComponentRegistry();
    this.isInitialized = false;
    this.config = {
      autoStart: true,
      debugMode: false,
      rootElement: null // null means document.body
    };
  }

  /**
   * Initialize the component system
   * @param {Object} options - Configuration options
   * @param {boolean} options.autoStart - Automatically start component scanning
   * @param {boolean} options.debugMode - Enable debug logging
   * @param {HTMLElement} options.rootElement - Root element to scan (default: document.body)
   */
  initialize(options = {}) {
    if (this.isInitialized) {
      console.warn('[ComponentManager] Already initialized');
      return this;
    }

    // Merge configuration
    this.config = { ...this.config, ...options };

    // Configure registry
    if (this.config.debugMode) {
      this.registry.enableDebug();
    }

    // Set up global error handling for components
    this.setupErrorHandling();

    // Auto-start if enabled
    if (this.config.autoStart) {
      this.start();
    }

    this.isInitialized = true;
    
    if (this.config.debugMode) {
      console.log('[ComponentManager] Initialized with config:', this.config);
    }

    return this;
  }

  /**
   * Start the component system (begin scanning and mounting)
   */
  start() {
    if (!this.isInitialized) {
      throw new Error('[ComponentManager] Must call initialize() before start()');
    }

    this.registry.startScanning();
    
    if (this.config.debugMode) {
      console.log('[ComponentManager] Started component system');
    }

    return this;
  }

  /**
   * Stop the component system (stop scanning, unmount all components)
   */
  stop() {
    this.registry.stopScanning();
    this.registry.unmountAll();
    
    if (this.config.debugMode) {
      console.log('[ComponentManager] Stopped component system');
    }

    return this;
  }

  /**
   * Restart the component system
   */
  restart() {
    this.stop();
    this.start();
    
    if (this.config.debugMode) {
      console.log('[ComponentManager] Restarted component system');
    }

    return this;
  }

  /**
   * Register a component class
   * @param {string} name - Component name
   * @param {class} ComponentClass - Component class constructor
   */
  register(name, ComponentClass) {
    this.registry.register(name, ComponentClass);
    return this;
  }

  /**
   * Unregister a component class
   * @param {string} name - Component name
   */
  unregister(name) {
    this.registry.unregister(name);
    return this;
  }

  /**
   * Register multiple components at once
   * @param {Object} components - Object with name:ComponentClass pairs
   */
  registerComponents(components) {
    Object.entries(components).forEach(([name, ComponentClass]) => {
      this.register(name, ComponentClass);
    });
    return this;
  }

  /**
   * Get component instance for a specific element
   * @param {HTMLElement} element - Element to get instance for
   * @returns {Object|null} Component instance or null
   */
  getInstance(element) {
    return this.registry.getInstance(element);
  }

  /**
   * Get all instances of a specific component type
   * @param {string} componentName - Component type name
   * @returns {Array} Array of component instances
   */
  getInstancesOfType(componentName) {
    return this.registry.getInstancesOfType(componentName);
  }

  /**
   * Find component elements by selector
   * @param {string} selector - CSS selector
   * @returns {Array} Array of {element, instance} objects
   */
  findComponents(selector) {
    const elements = document.querySelectorAll(selector);
    const results = [];

    elements.forEach(element => {
      const instance = this.registry.getInstance(element);
      if (instance) {
        results.push({ element, instance });
      }
    });

    return results;
  }

  /**
   * Mount components in a specific container
   * @param {HTMLElement} container - Container element to scan
   */
  mountContainer(container) {
    const elements = container.querySelectorAll('[data-component]');
    elements.forEach(element => this.registry.mountElement(element));
    return this;
  }

  /**
   * Unmount components in a specific container
   * @param {HTMLElement} container - Container element to unmount from
   */
  unmountContainer(container) {
    const elements = container.querySelectorAll('[data-component]');
    elements.forEach(element => this.registry.unmountElement(element));
    return this;
  }

  /**
   * Get system statistics
   * @returns {Object} Component system statistics
   */
  getStats() {
    const registryStats = this.registry.getStats();
    
    return {
      ...registryStats,
      isInitialized: this.isInitialized,
      config: { ...this.config }
    };
  }

  /**
   * Enable debug mode
   */
  enableDebug() {
    this.config.debugMode = true;
    this.registry.enableDebug();
    console.log('[ComponentManager] Debug mode enabled');
    return this;
  }

  /**
   * Disable debug mode
   */
  disableDebug() {
    this.config.debugMode = false;
    this.registry.disableDebug();
    return this;
  }

  /**
   * Reset the entire component system
   */
  reset() {
    this.stop();
    this.isInitialized = false;
    this.config = {
      autoStart: true,
      debugMode: false,
      rootElement: null
    };
    return this;
  }

  /**
   * Setup global error handling for component errors
   * @private
   */
  setupErrorHandling() {
    // Handle unhandled promise rejections from components
    window.addEventListener('unhandledrejection', (event) => {
      if (event.reason && event.reason.componentError) {
        console.error('[ComponentManager] Unhandled component error:', event.reason);
        
        if (this.config.debugMode) {
          // In debug mode, prevent the error from bubbling
          event.preventDefault();
        }
      }
    });

    // Handle general errors that might come from components
    window.addEventListener('error', (event) => {
      if (event.error && event.error.componentError) {
        console.error('[ComponentManager] Component error:', event.error);
      }
    });
  }

  /**
   * Create a development inspector for debugging components
   * @returns {Object} Inspector object with debugging methods
   */
  createInspector() {
    return {
      // List all registered component types
      listRegistered: () => {
        const stats = this.getStats();
        console.table(stats.componentTypes);
        return stats;
      },

      // Inspect a specific element's component
      inspect: (element) => {
        const instance = this.getInstance(element);
        if (instance) {
          console.group(`[Inspector] Component on element:`);
          console.log('Element:', element);
          console.log('Instance:', instance);
          console.log('Component Type:', element.dataset.component);
          console.log('Data Attributes:', element.dataset);
          console.groupEnd();
          return instance;
        } else {
          console.warn('[Inspector] No component found on element:', element);
          return null;
        }
      },

      // Find components by type
      findByType: (componentName) => {
        const instances = this.getInstancesOfType(componentName);
        console.log(`[Inspector] Found ${instances.length} instances of ${componentName}:`, instances);
        return instances;
      },

      // Highlight all component elements on the page
      highlightComponents: () => {
        const elements = document.querySelectorAll('[data-component]');
        const originalStyles = new Map();

        elements.forEach(element => {
          originalStyles.set(element, {
            outline: element.style.outline,
            backgroundColor: element.style.backgroundColor
          });
          
          element.style.outline = '2px solid #ff6b6b';
          element.style.backgroundColor = 'rgba(255, 107, 107, 0.1)';
          
          // Add component name tooltip
          const componentName = element.dataset.component;
          element.title = `Component: ${componentName}`;
        });

        console.log(`[Inspector] Highlighted ${elements.length} component elements`);
        
        // Return function to remove highlighting
        return () => {
          elements.forEach(element => {
            const original = originalStyles.get(element);
            if (original) {
              element.style.outline = original.outline;
              element.style.backgroundColor = original.backgroundColor;
              element.removeAttribute('title');
            }
          });
          console.log('[Inspector] Removed component highlighting');
        };
      },

      // Get performance metrics
      getPerformanceMetrics: () => {
        const stats = this.getStats();
        const metrics = {
          ...stats,
          memoryUsage: this.registry.instances.size * 1024, // Rough estimate
          averageComponentsPerType: Object.keys(stats.componentTypes).length > 0 
            ? stats.mountedInstances / Object.keys(stats.componentTypes).length 
            : 0
        };
        
        console.table(metrics);
        return metrics;
      }
    };
  }
}

// Create global instance
const componentManager = new ComponentManager();

// Make it globally available
if (typeof window !== 'undefined') {
  window.ComponentManager = ComponentManager;
  window.componentManager = componentManager;
  
  // Add convenient global methods
  window.registerComponent = (name, ComponentClass) => componentManager.register(name, ComponentClass);
  window.initializeComponents = (options) => componentManager.initialize(options);
  
  // Development helpers (only in debug mode)
  window.debugComponents = () => {
    if (!componentManager.config.debugMode) {
      console.warn('Enable debug mode first: componentManager.enableDebug()');
      return null;
    }
    return componentManager.createInspector();
  };
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { ComponentManager, componentManager };
} 