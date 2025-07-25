/**
 * Counter - JavaScript implementation for the Counter stateful component
 * 
 * This component manages:
 * - Counter value state
 * - Increment/decrement actions
 * - Min/max value constraints
 * - Display updates
 * - State persistence
 */
class Counter extends StatefulComponentJS {
  /**
   * Initialize the counter component
   */
  initialize() {
    // Parse min/max values from data attributes
    this.minValue = parseInt(this.element.dataset.minValue) || null;
    this.maxValue = parseInt(this.element.dataset.maxValue) || null;
    
    // Find child elements using CSS selectors
    this.countDisplay = this.find('.count-display');
    this.incrementButton = this.find('[data-action="increment"]');
    this.decrementButton = this.find('[data-action="decrement"]');
    
    if (!this.countDisplay) {
      console.warn('[Counter] Count display element not found');
    }
    
    // Set initial count from state or default to 0
    if (!this.state.hasOwnProperty('count')) {
      this.setState('count', parseInt(this.element.dataset.count) || 0, true);
    }
    
    // Update display to reflect initial state
    this.updateDisplay();
  }

  /**
   * Bind event listeners when component mounts
   */
  bindEvents() {
    // Use event delegation for increment/decrement buttons
    this.addEventListener('click', '[data-action="increment"]', this.handleIncrement);
    this.addEventListener('click', '[data-action="decrement"]', this.handleDecrement);
    
    // Listen for keyboard events on the component
    this.addEventListener('keydown', this.element, this.handleKeydown);
    
    // Add focus capability for keyboard interaction
    if (!this.element.hasAttribute('tabindex')) {
      this.element.setAttribute('tabindex', '0');
    }
  }

  /**
   * Handle increment button click
   * @param {Event} event - Click event
   */
  handleIncrement = (event) => {
    event.preventDefault();
    this.increment();
  }

  /**
   * Handle decrement button click
   * @param {Event} event - Click event
   */
  handleDecrement = (event) => {
    event.preventDefault();
    this.decrement();
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleKeydown = (event) => {
    switch (event.key) {
      case 'ArrowUp':
      case '+':
        event.preventDefault();
        this.increment();
        break;
      case 'ArrowDown':
      case '-':
        event.preventDefault();
        this.decrement();
        break;
      case 'Home':
        event.preventDefault();
        this.setCount(this.minValue || 0);
        break;
      case 'End':
        event.preventDefault();
        if (this.maxValue !== null) {
          this.setCount(this.maxValue);
        }
        break;
    }
  }

  /**
   * Increment the counter value
   */
  increment() {
    const currentCount = this.getState('count');
    const newCount = currentCount + 1;
    
    if (this.maxValue === null || newCount <= this.maxValue) {
      this.setCount(newCount);
      
      // Trigger increment event
      this.triggerEvent('counter:increment', {
        oldValue: currentCount,
        newValue: newCount
      });
    } else {
      // Trigger max reached event
      this.triggerEvent('counter:maxreached', {
        value: currentCount,
        maxValue: this.maxValue
      });
    }
  }

  /**
   * Decrement the counter value
   */
  decrement() {
    const currentCount = this.getState('count');
    const newCount = currentCount - 1;
    
    if (this.minValue === null || newCount >= this.minValue) {
      this.setCount(newCount);
      
      // Trigger decrement event
      this.triggerEvent('counter:decrement', {
        oldValue: currentCount,
        newValue: newCount
      });
    } else {
      // Trigger min reached event
      this.triggerEvent('counter:minreached', {
        value: currentCount,
        minValue: this.minValue
      });
    }
  }

  /**
   * Set counter to specific value
   * @param {number} value - New counter value
   */
  setCount(value) {
    const numValue = parseInt(value);
    if (isNaN(numValue)) return;
    
    // Check constraints
    if (this.minValue !== null && numValue < this.minValue) {
      value = this.minValue;
    }
    if (this.maxValue !== null && numValue > this.maxValue) {
      value = this.maxValue;
    }
    
    const oldValue = this.getState('count');
    this.setState('count', value);
    
    // Trigger value change event
    this.triggerEvent('counter:change', {
      oldValue,
      newValue: value
    });
  }

  /**
   * Reset counter to initial value or 0
   */
  reset() {
    const initialValue = parseInt(this.element.dataset.count) || 0;
    this.setCount(initialValue);
    
    this.triggerEvent('counter:reset', {
      value: initialValue
    });
  }

  /**
   * Update the display when state changes
   * @param {Object} prevState - Previous state
   * @param {Object} currentState - Current state
   */
  onStateChange(prevState, currentState) {
    if (prevState.count !== currentState.count) {
      this.updateDisplay();
      this.updateButtonStates();
    }
  }

  /**
   * Update the count display element
   */
  updateDisplay() {
    if (this.countDisplay) {
      const count = this.getState('count');
      this.countDisplay.textContent = count.toString();
      
      // Add CSS classes for styling based on value
      this.countDisplay.classList.toggle('count-zero', count === 0);
      this.countDisplay.classList.toggle('count-positive', count > 0);
      this.countDisplay.classList.toggle('count-negative', count < 0);
    }
  }

  /**
   * Update button states based on current value and constraints
   */
  updateButtonStates() {
    const count = this.getState('count');
    
    // Update increment button
    if (this.incrementButton) {
      const canIncrement = this.maxValue === null || count < this.maxValue;
      this.incrementButton.disabled = !canIncrement;
      this.incrementButton.classList.toggle('disabled', !canIncrement);
      this.incrementButton.setAttribute('aria-disabled', (!canIncrement).toString());
    }
    
    // Update decrement button
    if (this.decrementButton) {
      const canDecrement = this.minValue === null || count > this.minValue;
      this.decrementButton.disabled = !canDecrement;
      this.decrementButton.classList.toggle('disabled', !canDecrement);
      this.decrementButton.setAttribute('aria-disabled', (!canDecrement).toString());
    }
    
    // Update component aria attributes
    this.element.setAttribute('aria-valuenow', count.toString());
    if (this.minValue !== null) {
      this.element.setAttribute('aria-valuemin', this.minValue.toString());
    }
    if (this.maxValue !== null) {
      this.element.setAttribute('aria-valuemax', this.maxValue.toString());
    }
  }

  /**
   * Component-specific mount logic
   */
  onMount() {
    // Set up ARIA attributes for accessibility
    this.element.setAttribute('role', 'spinbutton');
    this.element.setAttribute('aria-label', 'Counter');
    
    // Ensure button states are correct on mount
    this.updateButtonStates();
    
    // Add keyboard focus styling
    this.element.classList.add('counter-interactive');
  }

  /**
   * Component-specific unmount logic
   */
  onUnmount() {
    // Remove ARIA attributes
    this.element.removeAttribute('role');
    this.element.removeAttribute('aria-label');
    this.element.removeAttribute('aria-valuenow');
    this.element.removeAttribute('aria-valuemin');
    this.element.removeAttribute('aria-valuemax');
    this.element.removeAttribute('tabindex');
    
    // Remove styling classes
    this.element.classList.remove('counter-interactive');
  }

  /**
   * Get current counter value
   * @returns {number} Current count
   */
  getValue() {
    return this.getState('count');
  }

  /**
   * Check if counter is at minimum value
   * @returns {boolean} True if at minimum
   */
  isAtMin() {
    return this.minValue !== null && this.getState('count') <= this.minValue;
  }

  /**
   * Check if counter is at maximum value
   * @returns {boolean} True if at maximum
   */
  isAtMax() {
    return this.maxValue !== null && this.getState('count') >= this.maxValue;
  }

  /**
   * Set minimum value constraint
   * @param {number|null} min - Minimum value or null for no minimum
   */
  setMinValue(min) {
    this.minValue = min;
    this.element.dataset.minValue = min !== null ? min.toString() : '';
    this.updateButtonStates();
  }

  /**
   * Set maximum value constraint
   * @param {number|null} max - Maximum value or null for no maximum
   */
  setMaxValue(max) {
    this.maxValue = max;
    this.element.dataset.maxValue = max !== null ? max.toString() : '';
    this.updateButtonStates();
  }

  /**
   * Update component display
   */
  update() {
    this.updateDisplay();
    this.updateButtonStates();
  }

  /**
   * Get debug information
   * @returns {Object} Debug information
   */
  getDebugInfo() {
    return {
      ...super.getDebugInfo(),
      value: this.getValue(),
      minValue: this.minValue,
      maxValue: this.maxValue,
      canIncrement: !this.isAtMax(),
      canDecrement: !this.isAtMin(),
      elements: {
        countDisplay: !!this.countDisplay,
        incrementButton: !!this.incrementButton,
        decrementButton: !!this.decrementButton
      }
    };
  }
}

// Register the component
if (typeof window !== 'undefined' && window.componentManager) {
  window.componentManager.register('counter', Counter);
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = Counter;
} else if (typeof window !== 'undefined') {
  window.Counter = Counter;
} 