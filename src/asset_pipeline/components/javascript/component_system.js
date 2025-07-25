/**
 * Component System - Main JavaScript bundle for the Asset Pipeline Component System
 * 
 * This file provides:
 * - Component system initialization
 * - Automatic component discovery and mounting
 * - Global component management
 * - Development utilities
 */

// Import core classes (when using module bundler)
// import { ComponentRegistry } from './component_registry.js';
// import { ComponentManager } from './component_manager.js';
// import { EventDelegate, DOMUtils } from './dom_utilities.js';
// import StatefulComponentJS from './stateful_component_js.js';

// Import component examples
// import Counter from './examples/counter.js';
// import Toggle from './examples/toggle.js';
// import Dropdown from './examples/dropdown.js';

/**
 * Component system initialization and auto-discovery
 */
class ComponentSystem {
  constructor() {
    this.initialized = false;
    this.autoStart = true;
    this.debugMode = false;
    this.components = new Map();
  }

  /**
   * Initialize the component system
   * @param {Object} options - Configuration options
   */
  initialize(options = {}) {
    if (this.initialized) {
      console.warn('[ComponentSystem] Already initialized');
      return this;
    }

    // Apply configuration
    this.autoStart = options.autoStart !== false;
    this.debugMode = options.debugMode === true;
    
    // Initialize component manager
    if (typeof window !== 'undefined' && window.componentManager) {
      window.componentManager.initialize({
        autoStart: this.autoStart,
        debugMode: this.debugMode,
        ...options
      });
    }

    // Register built-in components
    this.registerBuiltInComponents();

    // Set up automatic initialization on DOM ready
    if (this.autoStart) {
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => this.start());
      } else {
        // DOM already ready
        setTimeout(() => this.start(), 0);
      }
    }

    this.initialized = true;
    
    if (this.debugMode) {
      console.log('[ComponentSystem] Initialized', {
        autoStart: this.autoStart,
        debugMode: this.debugMode
      });
    }

    return this;
  }

  /**
   * Start component scanning and mounting
   */
  start() {
    if (typeof window !== 'undefined' && window.componentManager) {
      window.componentManager.start();
      
      if (this.debugMode) {
        const stats = window.componentManager.getStats();
        console.log('[ComponentSystem] Started with stats:', stats);
      }
    }
    return this;
  }

  /**
   * Stop component system
   */
  stop() {
    if (typeof window !== 'undefined' && window.componentManager) {
      window.componentManager.stop();
    }
    return this;
  }

  /**
   * Register built-in components
   * @private
   */
  registerBuiltInComponents() {
    const builtInComponents = {};

    // Add components if they exist globally
    if (typeof window !== 'undefined') {
      if (window.Counter) builtInComponents.counter = window.Counter;
      if (window.Toggle) builtInComponents.toggle = window.Toggle;
      if (window.Dropdown) builtInComponents.dropdown = window.Dropdown;
    }

    // Register with component manager
    if (typeof window !== 'undefined' && window.componentManager) {
      window.componentManager.registerComponents(builtInComponents);
    }

    this.components = new Map(Object.entries(builtInComponents));
    
    if (this.debugMode) {
      console.log('[ComponentSystem] Registered components:', Object.keys(builtInComponents));
    }
  }

  /**
   * Register a custom component
   * @param {string} name - Component name
   * @param {class} ComponentClass - Component class
   */
  register(name, ComponentClass) {
    this.components.set(name, ComponentClass);
    
    if (typeof window !== 'undefined' && window.componentManager) {
      window.componentManager.register(name, ComponentClass);
    }
    
    if (this.debugMode) {
      console.log(`[ComponentSystem] Registered custom component: ${name}`);
    }
    
    return this;
  }

  /**
   * Get component statistics
   * @returns {Object} Component system statistics
   */
  getStats() {
    if (typeof window !== 'undefined' && window.componentManager) {
      return window.componentManager.getStats();
    }
    
    return {
      initialized: this.initialized,
      registeredComponents: this.components.size,
      componentTypes: Object.fromEntries(this.components)
    };
  }

  /**
   * Enable debug mode
   */
  enableDebug() {
    this.debugMode = true;
    
    if (typeof window !== 'undefined' && window.componentManager) {
      window.componentManager.enableDebug();
    }
    
    console.log('[ComponentSystem] Debug mode enabled');
    return this;
  }

  /**
   * Disable debug mode
   */
  disableDebug() {
    this.debugMode = false;
    
    if (typeof window !== 'undefined' && window.componentManager) {
      window.componentManager.disableDebug();
    }
    
    return this;
  }

  /**
   * Get development inspector
   * @returns {Object} Development inspector
   */
  getInspector() {
    if (typeof window !== 'undefined' && window.componentManager) {
      return window.componentManager.createInspector();
    }
    
    return null;
  }
}

// Create global component system instance
const componentSystem = new ComponentSystem();

// Make it globally available
if (typeof window !== 'undefined') {
  window.ComponentSystem = ComponentSystem;
  window.componentSystem = componentSystem;
  
  // Convenient global methods
  window.initializeComponents = (options) => componentSystem.initialize(options);
  window.startComponents = () => componentSystem.start();
  window.stopComponents = () => componentSystem.stop();
  
  // Auto-initialize with default settings
  // Users can call window.initializeComponents(options) to override
  if (!window.DISABLE_AUTO_COMPONENT_INIT) {
    componentSystem.initialize();
  }
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { ComponentSystem, componentSystem };
} 