/**
 * Toggle - JavaScript implementation for toggle/switch components
 * 
 * This component manages:
 * - Boolean on/off state
 * - Toggle action via click or keyboard
 * - Visual state updates
 * - Accessibility features
 */
class Toggle extends StatefulComponentJS {
  /**
   * Initialize the toggle component
   */
  initialize() {
    // Find toggle elements
    this.toggleButton = this.find('.toggle-button') || this.element;
    this.toggleLabel = this.find('.toggle-label');
    
    // Set initial state
    if (!this.state.hasOwnProperty('enabled')) {
      const initialState = this.element.dataset.enabled === 'true' || 
                          this.element.hasAttribute('data-enabled') ||
                          this.toggleButton.classList.contains('toggle-on') ||
                          this.toggleButton.getAttribute('aria-pressed') === 'true';
      this.setState('enabled', initialState, true);
    }
    
    // Update display to reflect initial state
    this.updateDisplay();
  }

  /**
   * Bind event listeners
   */
  bindEvents() {
    // Click to toggle
    this.addEventListener('click', this.toggleButton, this.handleToggle);
    
    // Keyboard support
    this.addEventListener('keydown', this.toggleButton, this.handleKeydown);
    
    // Ensure button is focusable
    if (!this.toggleButton.hasAttribute('tabindex')) {
      this.toggleButton.setAttribute('tabindex', '0');
    }
  }

  /**
   * Handle toggle click
   * @param {Event} event - Click event
   */
  handleToggle = (event) => {
    event.preventDefault();
    this.toggle();
  }

  /**
   * Handle keyboard interaction
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleKeydown = (event) => {
    switch (event.key) {
      case ' ':
      case 'Enter':
        event.preventDefault();
        this.toggle();
        break;
    }
  }

  /**
   * Toggle the state
   */
  toggle() {
    const currentState = this.getState('enabled');
    this.setEnabled(!currentState);
  }

  /**
   * Set enabled state
   * @param {boolean} enabled - New enabled state
   */
  setEnabled(enabled) {
    const oldState = this.getState('enabled');
    this.setState('enabled', !!enabled);
    
    // Trigger toggle event
    this.triggerEvent('toggle:change', {
      enabled: !!enabled,
      previousState: oldState
    });
    
    if (enabled && !oldState) {
      this.triggerEvent('toggle:on');
    } else if (!enabled && oldState) {
      this.triggerEvent('toggle:off');
    }
  }

  /**
   * Check if toggle is enabled
   * @returns {boolean} True if enabled
   */
  isEnabled() {
    return this.getState('enabled');
  }

  /**
   * Enable the toggle
   */
  enable() {
    this.setEnabled(true);
  }

  /**
   * Disable the toggle
   */
  disable() {
    this.setEnabled(false);
  }

  /**
   * Update display when state changes
   * @param {Object} prevState - Previous state
   * @param {Object} currentState - Current state
   */
  onStateChange(prevState, currentState) {
    if (prevState.enabled !== currentState.enabled) {
      this.updateDisplay();
    }
  }

  /**
   * Update visual state
   */
  updateDisplay() {
    const enabled = this.getState('enabled');
    
    // Update button classes
    this.toggleButton.classList.toggle('toggle-on', enabled);
    this.toggleButton.classList.toggle('toggle-off', !enabled);
    
    // Update ARIA attributes
    this.toggleButton.setAttribute('aria-pressed', enabled.toString());
    
    // Update label if present
    if (this.toggleLabel) {
      const onText = this.element.dataset.onText || 'On';
      const offText = this.element.dataset.offText || 'Off';
      this.toggleLabel.textContent = enabled ? onText : offText;
    }
    
    // Update component data attribute
    this.element.dataset.enabled = enabled.toString();
  }

  /**
   * Component-specific mount logic
   */
  onMount() {
    // Set up ARIA attributes
    if (!this.toggleButton.hasAttribute('role')) {
      this.toggleButton.setAttribute('role', 'switch');
    }
    
    if (!this.toggleButton.hasAttribute('aria-label')) {
      const label = this.element.dataset.label || 'Toggle';
      this.toggleButton.setAttribute('aria-label', label);
    }
    
    // Add interactive class
    this.element.classList.add('toggle-interactive');
  }

  /**
   * Component-specific unmount logic
   */
  onUnmount() {
    // Clean up ARIA attributes
    this.toggleButton.removeAttribute('aria-pressed');
    this.toggleButton.removeAttribute('tabindex');
    
    // Remove interactive class
    this.element.classList.remove('toggle-interactive');
  }

  /**
   * Update component display
   */
  update() {
    this.updateDisplay();
  }

  /**
   * Get debug information
   * @returns {Object} Debug information
   */
  getDebugInfo() {
    return {
      ...super.getDebugInfo(),
      enabled: this.isEnabled(),
      elements: {
        toggleButton: !!this.toggleButton,
        toggleLabel: !!this.toggleLabel
      }
    };
  }
}

// Register the component
if (typeof window !== 'undefined' && window.componentManager) {
  window.componentManager.register('toggle', Toggle);
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = Toggle;
} else if (typeof window !== 'undefined') {
  window.Toggle = Toggle;
} 