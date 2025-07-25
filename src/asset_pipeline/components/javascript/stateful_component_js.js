/**
 * StatefulComponentJS - Base class for all stateful JavaScript components
 * 
 * This class provides:
 * - Standard component lifecycle (constructor, mount, unmount)
 * - Event binding utilities
 * - State persistence to DOM
 * - Update triggering system
 * - CSS selector helpers
 */
class StatefulComponentJS {
  /**
   * Constructor for stateful component
   * @param {HTMLElement} element - The DOM element this component is bound to
   */
  constructor(element) {
    if (!element) {
      throw new Error('[StatefulComponentJS] Element is required');
    }

    this.element = element;
    this.componentName = element.dataset.component;
    this.isDestroyed = false;
    this.boundEvents = new Map();
    this.eventDelegate = new EventDelegate(element);
    this.state = this.getInitialState();
    
    // Bind lifecycle methods to maintain context
    this.mount = this.mount.bind(this);
    this.unmount = this.unmount.bind(this);
    this.destroy = this.destroy.bind(this);
    this.handleError = this.handleError.bind(this);
    
    // Set up error handling
    this.setupErrorHandling();
    
    // Initialize the component
    this.initialize();
  }

  /**
   * Get initial state from DOM data attributes
   * Override this method to provide custom initial state logic
   * @returns {Object} Initial state object
   */
  getInitialState() {
    const state = {};
    
    // Extract state from data attributes
    Object.entries(this.element.dataset).forEach(([key, value]) => {
      // Skip component name
      if (key === 'component') return;
      
      // Try to parse JSON values
      try {
        state[key] = JSON.parse(value);
      } catch {
        state[key] = value;
      }
    });
    
    return state;
  }

  /**
   * Initialize component - called during construction
   * Override this method for component-specific initialization
   */
  initialize() {
    // Default implementation does nothing
    // Override in subclasses for component-specific initialization
  }

  /**
   * Mount the component - called when component is added to DOM
   * Override this method to set up event listeners and initial behavior
   */
  mount() {
    if (this.isDestroyed) {
      console.warn(`[${this.componentName}] Cannot mount destroyed component`);
      return;
    }

    // Add mounted class for CSS styling
    DOMUtils.addClass(this.element, 'component-mounted');
    
    // Bind events if not already bound
    if (this.boundEvents.size === 0) {
      this.bindEvents();
    }
    
    // Call component-specific mount logic
    this.onMount();
    
    // Trigger mounted event
    this.triggerEvent('component:mounted');
  }

  /**
   * Unmount the component - called when component is removed from DOM
   * Override this method to clean up event listeners and state
   */
  unmount() {
    if (this.isDestroyed) return;

    // Call component-specific unmount logic
    this.onUnmount();
    
    // Remove mounted class
    DOMUtils.removeClass(this.element, 'component-mounted');
    
    // Clean up events
    this.unbindEvents();
    
    // Trigger unmounted event
    this.triggerEvent('component:unmounted');
  }

  /**
   * Completely destroy the component
   */
  destroy() {
    if (this.isDestroyed) return;

    this.unmount();
    this.isDestroyed = true;
    this.eventDelegate.destroy();
    this.state = null;
    
    // Trigger destroyed event
    this.triggerEvent('component:destroyed');
  }

  /**
   * Component-specific mount logic - override in subclasses
   */
  onMount() {
    // Override in subclasses
  }

  /**
   * Component-specific unmount logic - override in subclasses
   */
  onUnmount() {
    // Override in subclasses
  }

  /**
   * Bind event listeners - override in subclasses
   */
  bindEvents() {
    // Override in subclasses to set up event listeners
  }

  /**
   * Unbind event listeners
   */
  unbindEvents() {
    // Remove all bound events
    this.boundEvents.forEach((cleanup, eventKey) => {
      if (typeof cleanup === 'function') {
        cleanup();
      }
    });
    this.boundEvents.clear();
  }

  /**
   * Add event listener with automatic cleanup
   * @param {string} eventType - Event type
   * @param {string|HTMLElement} target - Target selector or element
   * @param {Function} handler - Event handler
   * @param {Object} options - Event options
   */
  addEventListener(eventType, target, handler, options = {}) {
    const eventKey = `${eventType}-${typeof target === 'string' ? target : 'element'}`;
    
    if (typeof target === 'string') {
      // Use event delegation for selector-based events
      this.eventDelegate.on(eventType, target, handler, options);
      
      // Store cleanup function
      this.boundEvents.set(eventKey, () => {
        this.eventDelegate.off(eventType, target, handler);
      });
    } else {
      // Direct event listener on element
      const boundHandler = handler.bind(this);
      target.addEventListener(eventType, boundHandler, options);
      
      // Store cleanup function
      this.boundEvents.set(eventKey, () => {
        target.removeEventListener(eventType, boundHandler, options);
      });
    }
  }

  /**
   * Get state value
   * @param {string} key - State key
   * @returns {*} State value
   */
  getState(key) {
    return key ? this.state[key] : { ...this.state };
  }

  /**
   * Set state value and trigger update
   * @param {string|Object} key - State key or state object
   * @param {*} value - State value (if key is string)
   * @param {boolean} silent - Don't trigger update if true
   */
  setState(key, value, silent = false) {
    if (this.isDestroyed) return;

    const prevState = { ...this.state };
    
    if (typeof key === 'object') {
      // Merge state object
      this.state = { ...this.state, ...key };
      silent = value; // Second parameter becomes silent flag
    } else {
      // Set individual key
      this.state[key] = value;
    }
    
    // Persist state to DOM
    this.persistState();
    
    // Trigger update unless silent
    if (!silent) {
      this.onStateChange(prevState, this.state);
      this.triggerEvent('component:statechange', { 
        prevState, 
        currentState: this.state 
      });
    }
  }

  /**
   * Persist state to DOM data attributes
   */
  persistState() {
    Object.entries(this.state).forEach(([key, value]) => {
      try {
        this.element.dataset[key] = typeof value === 'object' 
          ? JSON.stringify(value) 
          : String(value);
      } catch (error) {
        console.warn(`[${this.componentName}] Failed to persist state key '${key}':`, error);
      }
    });
  }

  /**
   * Called when state changes - override in subclasses
   * @param {Object} prevState - Previous state
   * @param {Object} currentState - Current state
   */
  onStateChange(prevState, currentState) {
    // Override in subclasses
  }

  /**
   * Find element within component
   * @param {string} selector - CSS selector
   * @returns {HTMLElement|null} Found element
   */
  find(selector) {
    return this.element.querySelector(selector);
  }

  /**
   * Find all elements within component
   * @param {string} selector - CSS selector
   * @returns {Array} Array of elements
   */
  findAll(selector) {
    return Array.from(this.element.querySelectorAll(selector));
  }

  /**
   * Trigger custom event on component element
   * @param {string} eventName - Event name
   * @param {*} detail - Event detail data
   * @param {Object} options - Event options
   */
  triggerEvent(eventName, detail = null, options = {}) {
    const event = new CustomEvent(eventName, {
      detail,
      bubbles: options.bubbles !== false,
      cancelable: options.cancelable !== false,
      ...options
    });
    
    this.element.dispatchEvent(event);
  }

  /**
   * Handle component errors
   * @param {Error} error - Error object
   * @param {string} context - Error context
   */
  handleError(error, context = 'unknown') {
    console.error(`[${this.componentName}] Error in ${context}:`, error);
    
    // Mark error for component manager
    error.componentError = true;
    error.componentName = this.componentName;
    error.componentElement = this.element;
    
    // Trigger error event
    this.triggerEvent('component:error', { error, context });
    
    // Re-throw for global error handling
    throw error;
  }

  /**
   * Setup error handling for the component
   * @private
   */
  setupErrorHandling() {
    // Wrap lifecycle methods with error handling
    const originalMethods = ['mount', 'unmount', 'onMount', 'onUnmount', 'bindEvents', 'onStateChange'];
    
    originalMethods.forEach(methodName => {
      const originalMethod = this[methodName];
      if (typeof originalMethod === 'function') {
        this[methodName] = (...args) => {
          try {
            return originalMethod.apply(this, args);
          } catch (error) {
            this.handleError(error, methodName);
          }
        };
      }
    });
  }

  /**
   * Get debug information about the component
   * @returns {Object} Debug information
   */
  getDebugInfo() {
    return {
      componentName: this.componentName,
      element: this.element,
      state: { ...this.state },
      isDestroyed: this.isDestroyed,
      boundEvents: Array.from(this.boundEvents.keys()),
      classList: Array.from(this.element.classList),
      dataAttributes: { ...this.element.dataset }
    };
  }

  /**
   * Check if component is in viewport
   * @param {number} threshold - Visibility threshold (0-1)
   * @returns {boolean} True if component is visible
   */
  isInViewport(threshold = 0) {
    return DOMUtils.isInViewport(this.element, threshold);
  }

  /**
   * Animate the component element
   * @param {Object} properties - CSS properties to animate
   * @param {number} duration - Animation duration in ms
   * @param {string} easing - CSS easing function
   * @returns {Promise} Animation promise
   */
  animate(properties, duration = 300, easing = 'ease') {
    return DOMUtils.animate(this.element, properties, duration, easing);
  }

  /**
   * Update component display
   * Override this method to implement component-specific update logic
   */
  update() {
    // Override in subclasses for component-specific update logic
  }

  /**
   * Refresh component from current state
   */
  refresh() {
    if (this.isDestroyed) return;
    
    this.update();
    this.triggerEvent('component:refresh');
  }
}

// Export for both module and global usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = StatefulComponentJS;
} else if (typeof window !== 'undefined') {
  window.StatefulComponentJS = StatefulComponentJS;
} 