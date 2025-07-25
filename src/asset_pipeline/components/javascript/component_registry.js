/**
 * ComponentRegistry - Manages registration and discovery of stateful components
 * 
 * This class provides:
 * - Component class registration system
 * - Automatic component discovery via DOM scanning
 * - Component lifecycle management (mount, unmount)
 * - Component instance tracking
 */
class ComponentRegistry {
  constructor() {
    this.components = new Map(); // Map<string, ComponentClass>
    this.instances = new Map();  // Map<element, ComponentInstance>
    this.isScanning = false;
    this.mutationObserver = null;
    this.debugMode = false;
  }

  /**
   * Register a component class with the registry
   * @param {string} name - Component name (must match data-component attribute)
   * @param {class} ComponentClass - The component class constructor
   */
  register(name, ComponentClass) {
    if (this.debugMode) {
      console.log(`[ComponentRegistry] Registering component: ${name}`);
    }
    
    this.components.set(name, ComponentClass);
    
    // If we're already scanning, look for instances of this new component
    if (this.isScanning) {
      this.scanForComponent(name);
    }
  }

  /**
   * Unregister a component class
   * @param {string} name - Component name to unregister
   */
  unregister(name) {
    if (this.debugMode) {
      console.log(`[ComponentRegistry] Unregistering component: ${name}`);
    }
    
    // Unmount all instances of this component
    this.unmountAllInstancesOfType(name);
    this.components.delete(name);
  }

  /**
   * Start automatic component discovery and mounting
   * This will scan the DOM for data-component attributes and mount components
   */
  startScanning() {
    if (this.isScanning) {
      console.warn('[ComponentRegistry] Already scanning');
      return;
    }

    if (this.debugMode) {
      console.log('[ComponentRegistry] Starting component scanning');
    }

    this.isScanning = true;
    this.scanAll();
    this.setupMutationObserver();
  }

  /**
   * Stop automatic component discovery
   */
  stopScanning() {
    if (!this.isScanning) {
      return;
    }

    if (this.debugMode) {
      console.log('[ComponentRegistry] Stopping component scanning');
    }

    this.isScanning = false;
    if (this.mutationObserver) {
      this.mutationObserver.disconnect();
      this.mutationObserver = null;
    }
  }

  /**
   * Scan the entire document for components and mount them
   */
  scanAll() {
    const elements = document.querySelectorAll('[data-component]');
    
    if (this.debugMode) {
      console.log(`[ComponentRegistry] Found ${elements.length} component elements`);
    }

    elements.forEach(element => this.mountElement(element));
  }

  /**
   * Scan for instances of a specific component type
   * @param {string} componentName - Name of component to scan for
   */
  scanForComponent(componentName) {
    const elements = document.querySelectorAll(`[data-component="${componentName}"]`);
    
    if (this.debugMode) {
      console.log(`[ComponentRegistry] Found ${elements.length} ${componentName} elements`);
    }

    elements.forEach(element => this.mountElement(element));
  }

  /**
   * Mount a component on a specific element
   * @param {HTMLElement} element - Element to mount component on
   */
  mountElement(element) {
    // Skip if already mounted
    if (this.instances.has(element)) {
      return;
    }

    const componentName = element.dataset.component;
    if (!componentName) {
      console.warn('[ComponentRegistry] Element missing data-component attribute', element);
      return;
    }

    const ComponentClass = this.components.get(componentName);
    if (!ComponentClass) {
      if (this.debugMode) {
        console.warn(`[ComponentRegistry] Component '${componentName}' not registered`);
      }
      return;
    }

    try {
      const instance = new ComponentClass(element);
      this.instances.set(element, instance);
      
      // Call mount lifecycle method if it exists
      if (typeof instance.mount === 'function') {
        instance.mount();
      }

      if (this.debugMode) {
        console.log(`[ComponentRegistry] Mounted ${componentName}`, element);
      }
    } catch (error) {
      console.error(`[ComponentRegistry] Failed to mount ${componentName}:`, error);
    }
  }

  /**
   * Unmount a component from a specific element
   * @param {HTMLElement} element - Element to unmount component from
   */
  unmountElement(element) {
    const instance = this.instances.get(element);
    if (!instance) {
      return;
    }

    try {
      // Call unmount lifecycle method if it exists
      if (typeof instance.unmount === 'function') {
        instance.unmount();
      }

      this.instances.delete(element);

      if (this.debugMode) {
        console.log('[ComponentRegistry] Unmounted component', element);
      }
    } catch (error) {
      console.error('[ComponentRegistry] Failed to unmount component:', error);
    }
  }

  /**
   * Unmount all instances of a specific component type
   * @param {string} componentName - Name of component type to unmount
   */
  unmountAllInstancesOfType(componentName) {
    const elementsToUnmount = [];
    
    this.instances.forEach((instance, element) => {
      if (element.dataset.component === componentName) {
        elementsToUnmount.push(element);
      }
    });

    elementsToUnmount.forEach(element => this.unmountElement(element));
  }

  /**
   * Unmount all component instances
   */
  unmountAll() {
    const elementsToUnmount = Array.from(this.instances.keys());
    elementsToUnmount.forEach(element => this.unmountElement(element));
  }

  /**
   * Get component instance for a specific element
   * @param {HTMLElement} element - Element to get instance for
   * @returns {Object|null} Component instance or null
   */
  getInstance(element) {
    return this.instances.get(element) || null;
  }

  /**
   * Get all instances of a specific component type
   * @param {string} componentName - Name of component type
   * @returns {Array} Array of component instances
   */
  getInstancesOfType(componentName) {
    const instances = [];
    
    this.instances.forEach((instance, element) => {
      if (element.dataset.component === componentName) {
        instances.push(instance);
      }
    });

    return instances;
  }

  /**
   * Get registry statistics
   * @returns {Object} Statistics about registered components and instances
   */
  getStats() {
    const stats = {
      registeredComponents: this.components.size,
      mountedInstances: this.instances.size,
      componentTypes: {},
      isScanning: this.isScanning
    };

    // Count instances by type
    this.instances.forEach((instance, element) => {
      const type = element.dataset.component;
      stats.componentTypes[type] = (stats.componentTypes[type] || 0) + 1;
    });

    return stats;
  }

  /**
   * Enable debug mode for verbose logging
   */
  enableDebug() {
    this.debugMode = true;
    console.log('[ComponentRegistry] Debug mode enabled');
  }

  /**
   * Disable debug mode
   */
  disableDebug() {
    this.debugMode = false;
  }

  /**
   * Setup mutation observer to watch for new components
   * @private
   */
  setupMutationObserver() {
    this.mutationObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        // Handle added nodes
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            // Check if the node itself is a component
            if (node.dataset && node.dataset.component) {
              this.mountElement(node);
            }
            
            // Check for component descendants
            const componentElements = node.querySelectorAll('[data-component]');
            componentElements.forEach(element => this.mountElement(element));
          }
        });

        // Handle removed nodes
        mutation.removedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            // Check if the node itself was a component
            if (this.instances.has(node)) {
              this.unmountElement(node);
            }
            
            // Check for component descendants that were removed
            const componentElements = node.querySelectorAll('[data-component]');
            componentElements.forEach(element => {
              if (this.instances.has(element)) {
                this.unmountElement(element);
              }
            });
          }
        });
      });
    });

    this.mutationObserver.observe(document.body, {
      childList: true,
      subtree: true
    });
  }
}

// Export for both module and global usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = ComponentRegistry;
} else if (typeof window !== 'undefined') {
  window.ComponentRegistry = ComponentRegistry;
} 