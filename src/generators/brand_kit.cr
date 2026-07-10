require "../components"
require "../components/css/component_css_registry"

# Brand Kit Generator
# Generates a single static HTML file showcasing all design tokens,
# utility classes, components, and WCAG 2.2 AA accessibility features.
#
# Usage: crystal run src/generators/brand_kit.cr
# Output: output/brand-kit.html

module BrandKit
  # Register all utility classes that will appear in the showcase
  def self.register_utility_classes
    registry = Components::CSS::ClassRegistry.instance
    registry.clear
    Components::CSS::ComponentCSSRegistry.instance.clear

    # Layout
    %w[block inline-block flex inline-flex grid hidden relative absolute fixed sticky].each { |c| registry.register_class(c) }
    %w[flex-row flex-col flex-wrap items-center items-start items-end justify-center justify-between justify-start justify-end].each { |c| registry.register_class(c) }
    %w[gap-1 gap-2 gap-3 gap-4 gap-6 gap-8].each { |c| registry.register_class(c) }

    # Spacing
    %w[m-0 m-1 m-2 m-4 m-8 mx-auto mx-4 my-2 my-4 mt-2 mt-4 mb-2 mb-4 ml-2 mr-2].each { |c| registry.register_class(c) }
    %w[p-0 p-1 p-2 p-3 p-4 p-6 p-8 px-2 px-4 px-6 py-1 py-2 py-3 py-4 pt-2 pb-2].each { |c| registry.register_class(c) }

    # Sizing
    %w[w-full w-auto h-full h-auto min-w-0 min-w-full max-w-full].each { |c| registry.register_class(c) }

    # Typography
    %w[text-xs text-sm text-base text-lg text-xl text-2xl text-3xl].each { |c| registry.register_class(c) }
    %w[font-thin font-light font-normal font-medium font-semibold font-bold font-extrabold font-black].each { |c| registry.register_class(c) }
    %w[text-left text-center text-right text-justify].each { |c| registry.register_class(c) }
    %w[leading-none leading-tight leading-normal leading-relaxed leading-loose].each { |c| registry.register_class(c) }
    %w[tracking-tighter tracking-tight tracking-normal tracking-wide tracking-wider tracking-widest].each { |c| registry.register_class(c) }

    # Colors
    %w[text-black text-white text-gray-500 text-gray-700 text-gray-900].each { |c| registry.register_class(c) }
    %w[text-red-500 text-red-700 text-blue-500 text-blue-700 text-green-500 text-green-700].each { |c| registry.register_class(c) }
    %w[text-yellow-500 text-purple-500 text-pink-500 text-indigo-500].each { |c| registry.register_class(c) }

    %w[bg-white bg-black bg-gray-50 bg-gray-100 bg-gray-200 bg-gray-800 bg-gray-900].each { |c| registry.register_class(c) }
    %w[bg-red-50 bg-red-500 bg-red-700 bg-blue-50 bg-blue-500 bg-blue-700].each { |c| registry.register_class(c) }
    %w[bg-green-50 bg-green-500 bg-green-700 bg-yellow-50 bg-yellow-500].each { |c| registry.register_class(c) }
    %w[bg-purple-500 bg-pink-500 bg-indigo-500].each { |c| registry.register_class(c) }

    # Borders
    %w[border rounded rounded-sm rounded-md rounded-lg rounded-xl rounded-full].each { |c| registry.register_class(c) }
    %w[border-gray-200 border-gray-300 border-red-500 border-blue-500 border-green-500].each { |c| registry.register_class(c) }

    # Shadows
    %w[shadow-sm shadow shadow-md shadow-lg shadow-xl].each { |c| registry.register_class(c) }

    # Opacity
    %w[opacity-0 opacity-25 opacity-50 opacity-75 opacity-100].each { |c| registry.register_class(c) }

    # Transitions
    %w[transition transition-colors transition-transform].each { |c| registry.register_class(c) }

    # Cursor
    %w[cursor-pointer cursor-default cursor-not-allowed].each { |c| registry.register_class(c) }

    # Overflow
    %w[overflow-hidden overflow-auto overflow-scroll].each { |c| registry.register_class(c) }

    # Z-index
    %w[z-0 z-10 z-20 z-50].each { |c| registry.register_class(c) }

    # WCAG: Screen reader
    %w[sr-only not-sr-only].each { |c| registry.register_class(c) }

    # WCAG: Focus rings
    %w[ring ring-0 ring-1 ring-2 ring-4 outline-none outline-2].each { |c| registry.register_class(c) }

    # Modifiers: hover, focus, dark, responsive
    %w[hover:bg-blue-700 hover:bg-gray-100 hover:text-white hover:shadow-lg].each { |c| registry.register_class(c) }
    %w[focus:ring-2 focus-visible:ring-2 focus-visible:outline-2].each { |c| registry.register_class(c) }
    %w[dark:bg-gray-900 dark:text-white dark:bg-gray-800 dark:border-gray-700].each { |c| registry.register_class(c) }
    %w[sm:flex sm:grid sm:text-lg md:text-xl lg:text-2xl].each { |c| registry.register_class(c) }

    # Modifiers: ARIA & form states
    %w[aria-expanded:bg-blue-50 aria-selected:bg-blue-500 aria-disabled:opacity-50].each { |c| registry.register_class(c) }
    %w[invalid:border-red-500 valid:border-green-500 required:ring-1].each { |c| registry.register_class(c) }
    %w[disabled:opacity-50 disabled:cursor-not-allowed].each { |c| registry.register_class(c) }

    # Modifiers: motion
    %w[motion-reduce:transition motion-safe:transition-transform].each { |c| registry.register_class(c) }

    # Container queries
    %w[container].each { |c| registry.register_class(c) }

    # Logical properties
    %w[ms-2 me-2 ps-4 pe-4].each { |c| registry.register_class(c) }

    # Touch / select
    %w[touch-manipulation select-none select-text].each { |c| registry.register_class(c) }
  end

  # Register component CSS for the showcase
  def self.register_component_css
    Components::CSS::ComponentCSSRegistry.instance.register(
      "BrandKit::Button",
      <<-CSS
      .btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        padding: 0.625rem 1.25rem;
        font-weight: 500;
        font-size: 0.875rem;
        line-height: 1.25rem;
        border-radius: 0.375rem;
        border: 1px solid transparent;
        cursor: pointer;
        transition: all 150ms cubic-bezier(0.4, 0, 0.2, 1);
        text-decoration: none;

        &:focus-visible {
          outline: 2px solid var(--color-blue-500);
          outline-offset: 2px;
        }

        &:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
      }

      .btn-primary {
        background-color: var(--color-blue-500);
        color: var(--color-white);

        &:hover:not(:disabled) {
          background-color: var(--color-blue-700);
        }
      }

      .btn-secondary {
        background-color: light-dark(var(--color-gray-100), var(--color-gray-700));
        color: light-dark(var(--color-gray-900), var(--color-gray-100));
        border-color: light-dark(var(--color-gray-300), var(--color-gray-600));

        &:hover:not(:disabled) {
          background-color: light-dark(var(--color-gray-200), var(--color-gray-600));
        }
      }

      .btn-danger {
        background-color: var(--color-red-500);
        color: var(--color-white);

        &:hover:not(:disabled) {
          background-color: var(--color-red-700);
        }
      }

      .btn-success {
        background-color: var(--color-green-500);
        color: var(--color-white);

        &:hover:not(:disabled) {
          background-color: var(--color-green-700);
        }
      }

      .btn-sm {
        padding: 0.375rem 0.75rem;
        font-size: 0.75rem;
      }

      .btn-lg {
        padding: 0.75rem 1.5rem;
        font-size: 1rem;
      }
      CSS
    )

    Components::CSS::ComponentCSSRegistry.instance.register(
      "BrandKit::Card",
      <<-CSS
      .card {
        background-color: light-dark(var(--color-white), var(--color-gray-800));
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.5rem;
        overflow: hidden;
        transition: box-shadow 150ms cubic-bezier(0.4, 0, 0.2, 1);

        &:hover {
          box-shadow: 0 4px 6px -1px oklch(0 0 0 / 0.1), 0 2px 4px -2px oklch(0 0 0 / 0.1);
        }
      }

      .card-body {
        padding: 1.5rem;
      }

      .card-title {
        font-size: 1.125rem;
        font-weight: 600;
        margin-bottom: 0.5rem;
        color: light-dark(var(--color-gray-900), var(--color-white));
      }

      .card-text {
        color: light-dark(var(--color-gray-600), var(--color-gray-300));
        font-size: 0.875rem;
        line-height: 1.5;
      }
      CSS
    )

    Components::CSS::ComponentCSSRegistry.instance.register(
      "BrandKit::Form",
      <<-CSS
      .form-group {
        margin-bottom: 1rem;
      }

      .form-label {
        display: block;
        font-size: 0.875rem;
        font-weight: 500;
        margin-bottom: 0.375rem;
        color: light-dark(var(--color-gray-700), var(--color-gray-200));
      }

      .form-control {
        display: block;
        width: 100%;
        padding: 0.5rem 0.75rem;
        font-size: 0.875rem;
        line-height: 1.5;
        color: light-dark(var(--color-gray-900), var(--color-white));
        background-color: light-dark(var(--color-white), var(--color-gray-800));
        border: 1px solid light-dark(var(--color-gray-300), var(--color-gray-600));
        border-radius: 0.375rem;
        transition: border-color 150ms, box-shadow 150ms;

        &:focus {
          border-color: var(--color-blue-500);
          box-shadow: 0 0 0 3px oklch(0.623 0.214 259.815 / 0.25);
          outline: none;
        }

        &:invalid {
          border-color: var(--color-red-500);
        }

        &::placeholder {
          color: light-dark(var(--color-gray-400), var(--color-gray-500));
        }
      }

      .form-hint {
        font-size: 0.75rem;
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        margin-top: 0.25rem;
      }

      .form-error {
        font-size: 0.75rem;
        color: var(--color-red-500);
        margin-top: 0.25rem;
      }
      CSS
    )

    Components::CSS::ComponentCSSRegistry.instance.register(
      "BrandKit::Alert",
      <<-CSS
      .alert {
        padding: 1rem 1.25rem;
        border-radius: 0.375rem;
        font-size: 0.875rem;
        line-height: 1.5;
        border: 1px solid transparent;
      }

      .alert-info {
        background-color: light-dark(var(--color-blue-50), var(--color-blue-900));
        color: light-dark(var(--color-blue-700), var(--color-blue-200));
        border-color: light-dark(var(--color-blue-200), var(--color-blue-700));
      }

      .alert-success {
        background-color: light-dark(var(--color-green-50), var(--color-green-900));
        color: light-dark(var(--color-green-700), var(--color-green-200));
        border-color: light-dark(var(--color-green-200), var(--color-green-700));
      }

      .alert-warning {
        background-color: light-dark(var(--color-yellow-50), var(--color-yellow-900));
        color: light-dark(var(--color-yellow-700), var(--color-yellow-200));
        border-color: light-dark(var(--color-yellow-200), var(--color-yellow-700));
      }

      .alert-danger {
        background-color: light-dark(var(--color-red-50), var(--color-red-900));
        color: light-dark(var(--color-red-700), var(--color-red-200));
        border-color: light-dark(var(--color-red-200), var(--color-red-700));
      }
      CSS
    )

    Components::CSS::ComponentCSSRegistry.instance.register(
      "BrandKit::Badge",
      <<-CSS
      .badge {
        display: inline-flex;
        align-items: center;
        padding: 0.125rem 0.625rem;
        font-size: 0.75rem;
        font-weight: 500;
        border-radius: 9999px;
      }

      .badge-blue {
        background-color: light-dark(var(--color-blue-50), var(--color-blue-900));
        color: light-dark(var(--color-blue-700), var(--color-blue-200));
      }

      .badge-green {
        background-color: light-dark(var(--color-green-50), var(--color-green-900));
        color: light-dark(var(--color-green-700), var(--color-green-200));
      }

      .badge-red {
        background-color: light-dark(var(--color-red-50), var(--color-red-900));
        color: light-dark(var(--color-red-700), var(--color-red-200));
      }

      .badge-gray {
        background-color: light-dark(var(--color-gray-100), var(--color-gray-800));
        color: light-dark(var(--color-gray-700), var(--color-gray-300));
      }
      CSS
    )
  end

  # Generate CSS from engine
  def self.generate_css : String
    config = Components::CSS::Config.new
    generator = Components::CSS::Engine::Generator.new(config)
    generator.generate
  end

  # Build the full HTML page
  def self.generate_html : String
    register_utility_classes
    register_component_css
    css = generate_css

    String.build do |html|
      html << <<-HEAD
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Asset Pipeline Design System — Brand Kit &amp; Accessibility Showcase</title>
        <style>
      #{css}

      /* Brand kit page layout — uses light-dark() for automatic dark mode */
      body {
        background-color: light-dark(var(--color-white), var(--color-gray-900));
        color: light-dark(var(--color-gray-900), var(--color-gray-100));
      }
      .brand-kit { max-width: 80rem; margin: 0 auto; padding: 2rem; }
      .section { margin-bottom: 3rem; }
      .section-title {
        font-size: 1.5rem; font-weight: 700; margin-bottom: 0.25rem;
        padding-bottom: 0.75rem;
        border-bottom: 2px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        color: light-dark(var(--color-gray-900), var(--color-white));
      }
      .section-desc {
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        font-size: 0.875rem; margin-bottom: 1.5rem;
      }
      .swatch-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(5rem, 1fr)); gap: 0.5rem; }
      .swatch {
        border-radius: 0.375rem; aspect-ratio: 1; display: flex; align-items: flex-end; padding: 0.25rem;
        border: 1px solid light-dark(oklch(0 0 0 / 0.08), oklch(1 0 0 / 0.12));
      }
      .swatch span {
        font-size: 0.625rem; font-weight: 500;
        background: oklch(1 0 0 / 0.8); color: oklch(0 0 0);
        border-radius: 0.125rem; padding: 0 0.25rem;
      }
      .type-row { margin-bottom: 0.75rem; }
      .sample-row { display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: center; margin-bottom: 1rem; }
      .demo-box {
        padding: 1rem; border-radius: 0.375rem;
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
      }
      .spacing-bar { background: var(--color-blue-500); height: 1.5rem; border-radius: 0.25rem; }
      .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
      .code {
        font-family: var(--font-mono); font-size: 0.75rem;
        background: light-dark(var(--color-gray-100), var(--color-gray-800));
        color: light-dark(var(--color-gray-800), var(--color-gray-200));
        padding: 0.125rem 0.375rem; border-radius: 0.25rem;
      }
      .a11y-demo {
        padding: 1.5rem;
        border: 2px dashed light-dark(var(--color-gray-300), var(--color-gray-600));
        border-radius: 0.5rem; margin-bottom: 1rem;
      }
      .a11y-label {
        font-size: 0.75rem; font-weight: 600; text-transform: uppercase;
        letter-spacing: 0.05em;
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        margin-bottom: 0.5rem;
      }
      /* Demo surface for shadow/ring boxes that need a visible background */
      .demo-surface {
        background: light-dark(var(--color-white), var(--color-gray-800));
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
      }
      /* Light-only showcase panel — forces light background for demos where
         the effect (shadows, elevation) is only visible against a light surface */
      .showcase-panel {
        background: var(--color-gray-50);
        border-radius: 0.5rem;
        padding: 1.5rem;
        border: 1px solid var(--color-gray-200);
      }
      .showcase-panel .code {
        background: var(--color-gray-200);
        color: var(--color-gray-700);
      }
      .showcase-panel .demo-surface {
        background: var(--color-white);
        border-color: var(--color-gray-200);
      }
      h3 { color: light-dark(var(--color-gray-800), var(--color-gray-200)); }
      a { color: light-dark(var(--color-blue-500), var(--color-blue-300)); }
      strong { color: inherit; }
      code { color: light-dark(var(--color-gray-700), var(--color-gray-300)); }
      @media (max-width: 768px) { .grid-2 { grid-template-columns: 1fr; } }

      /* Color scheme toggle */
      .scheme-toggle {
        display: inline-flex;
        border-radius: 0.375rem;
        border: 1px solid light-dark(var(--color-gray-300), var(--color-gray-600));
        overflow: hidden;
        font-size: 0.75rem;
        font-weight: 500;
      }
      .scheme-toggle button {
        padding: 0.375rem 0.75rem;
        border: none;
        background: transparent;
        color: light-dark(var(--color-gray-600), var(--color-gray-400));
        cursor: pointer;
        transition: background-color 150ms, color 150ms;
      }
      .scheme-toggle button:not(:last-child) {
        border-right: 1px solid light-dark(var(--color-gray-300), var(--color-gray-600));
      }
      .scheme-toggle button[aria-pressed="true"] {
        background: light-dark(var(--color-gray-900), var(--color-white));
        color: light-dark(var(--color-white), var(--color-gray-900));
      }
      .scheme-toggle button:focus-visible {
        outline: 2px solid var(--color-blue-500);
        outline-offset: -2px;
      }

      /* Modern form controls */
      .toggle-switch {
        position: relative;
        display: inline-block;
        width: 2.75rem;
        height: 1.5rem;
      }
      .toggle-switch input {
        opacity: 0;
        width: 0;
        height: 0;
        position: absolute;
      }
      .toggle-track {
        position: absolute;
        inset: 0;
        background: light-dark(var(--color-gray-300), var(--color-gray-600));
        border-radius: 9999px;
        transition: background-color 200ms;
        cursor: pointer;
      }
      .toggle-track::before {
        content: "";
        position: absolute;
        height: 1.125rem;
        width: 1.125rem;
        left: 0.1875rem;
        bottom: 0.1875rem;
        background: white;
        border-radius: 9999px;
        transition: transform 200ms;
      }
      .toggle-switch input:checked + .toggle-track {
        background: var(--color-blue-500);
      }
      .toggle-switch input:checked + .toggle-track::before {
        transform: translateX(1.25rem);
      }
      .toggle-switch input:focus-visible + .toggle-track {
        outline: 2px solid var(--color-blue-500);
        outline-offset: 2px;
      }

      /* Custom select (appearance: base-select) */
      .custom-select {
        appearance: base-select;
        background: light-dark(var(--color-white), var(--color-gray-800));
        color: light-dark(var(--color-gray-900), var(--color-white));
        border: 1px solid light-dark(var(--color-gray-300), var(--color-gray-600));
        border-radius: 0.375rem;
        padding: 0.5rem 0.75rem;
        font-size: 0.875rem;
        min-width: 14rem;
        cursor: pointer;
      }
      .custom-select:focus-visible {
        outline: 2px solid var(--color-blue-500);
        outline-offset: 2px;
      }
      .custom-select::picker-icon {
        color: light-dark(var(--color-gray-400), var(--color-gray-500));
      }
      .custom-select option {
        padding: 0.5rem 0.75rem;
      }

      /* Dialog */
      .demo-dialog {
        border: none;
        border-radius: 0.75rem;
        padding: 2rem;
        max-width: 28rem;
        width: 90%;
        background: light-dark(var(--color-white), var(--color-gray-800));
        color: light-dark(var(--color-gray-900), var(--color-white));
        box-shadow: 0 25px 50px -12px oklch(0 0 0 / 0.25);
      }
      .demo-dialog::backdrop {
        background: oklch(0 0 0 / 0.5);
        backdrop-filter: blur(4px);
      }
      .demo-dialog h3 {
        margin: 0 0 0.75rem;
        font-size: 1.125rem;
        font-weight: 600;
      }
      .demo-dialog p {
        font-size: 0.875rem;
        color: light-dark(var(--color-gray-600), var(--color-gray-300));
        margin: 0 0 1.25rem;
        line-height: 1.5;
      }

      /* Popover — CSS anchor positioning (Chrome 125+) */
      .popover-demo, .popover-menu {
        position: fixed;
        inset: unset;
        margin: 0.5rem 0 0 0;
        position-area: bottom span-right;
        position-try-fallbacks: flip-block, flip-inline;
      }
      .popover-demo {
        background: light-dark(var(--color-white), var(--color-gray-800));
        color: light-dark(var(--color-gray-900), var(--color-white));
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.5rem;
        padding: 1rem 1.25rem;
        box-shadow: 0 10px 15px -3px oklch(0 0 0 / 0.1), 0 4px 6px -4px oklch(0 0 0 / 0.1);
        font-size: 0.875rem;
        max-width: 20rem;
      }
      .popover-demo.tooltip-style {
        padding: 0.5rem 0.75rem;
        font-size: 0.75rem;
        max-width: 16rem;
      }
      .popover-menu {
        background: light-dark(var(--color-white), var(--color-gray-800));
        color: light-dark(var(--color-gray-900), var(--color-white));
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.5rem;
        padding: 0.25rem;
        box-shadow: 0 10px 15px -3px oklch(0 0 0 / 0.1);
        font-size: 0.875rem;
        min-width: 10rem;
      }
      .popover-menu-item {
        display: block;
        width: 100%;
        padding: 0.5rem 0.75rem;
        border: none;
        background: transparent;
        color: inherit;
        text-align: left;
        border-radius: 0.375rem;
        cursor: pointer;
        font-size: 0.875rem;
      }
      .popover-menu-item:hover {
        background: light-dark(var(--color-gray-100), var(--color-gray-700));
      }

      /* Details/Summary accordion */
      .details-styled {
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.5rem;
        margin-bottom: 0.5rem;
        overflow: hidden;
      }
      .details-styled summary {
        padding: 0.75rem 1rem;
        font-weight: 500;
        font-size: 0.875rem;
        cursor: pointer;
        background: light-dark(var(--color-gray-50), var(--color-gray-800));
        list-style: none;
        display: flex;
        align-items: center;
        justify-content: space-between;
      }
      .details-styled summary::-webkit-details-marker { display: none; }
      .details-styled summary::after {
        content: "+";
        font-weight: 600;
        font-size: 1rem;
        color: light-dark(var(--color-gray-400), var(--color-gray-500));
        transition: transform 200ms;
      }
      .details-styled[open] summary::after {
        content: "−";
      }
      .details-styled .details-body {
        padding: 1rem;
        font-size: 0.875rem;
        color: light-dark(var(--color-gray-600), var(--color-gray-300));
        line-height: 1.6;
      }

      /* Container query demo */
      .container-demo {
        container-type: inline-size;
        container-name: card-container;
        resize: horizontal;
        overflow: auto;
        border: 2px dashed light-dark(var(--color-gray-300), var(--color-gray-600));
        border-radius: 0.5rem;
        padding: 1rem;
        min-width: 12rem;
      }
      .cq-card {
        display: grid;
        gap: 0.75rem;
        padding: 1rem;
        background: light-dark(var(--color-white), var(--color-gray-800));
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.375rem;
      }
      @container card-container (min-width: 24rem) {
        .cq-card {
          grid-template-columns: auto 1fr;
          align-items: center;
        }
      }

      /* Starting-style fade-in */
      .fade-in-demo {
        opacity: 1;
        transform: translateY(0);
        transition: opacity 600ms ease, transform 600ms ease;
      }
      @starting-style {
        .fade-in-demo {
          opacity: 0;
          transform: translateY(1rem);
        }
      }

      /* Expand/collapse with interpolate-size */
      .expand-demo {
        interpolate-size: allow-keywords;
      }
      .expand-content {
        height: 0;
        overflow: hidden;
        transition: height 300ms ease;
      }
      .expand-trigger:checked ~ .expand-content {
        height: auto;
      }

      /* Transition utility demos */
      .hover-grow {
        transition: transform 200ms ease;
      }
      .hover-grow:hover {
        transform: scale(1.05);
      }
      .hover-lift {
        transition: transform 200ms ease, box-shadow 200ms ease;
      }
      .hover-lift:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 6px -1px oklch(0 0 0 / 0.1);
      }
      .hover-color {
        transition: background-color 200ms ease, color 200ms ease;
        padding: 0.625rem 1.25rem;
        border-radius: 0.375rem;
        background: light-dark(var(--color-gray-100), var(--color-gray-800));
        cursor: pointer;
      }
      .hover-color:hover {
        background: var(--color-blue-500);
        color: var(--color-white);
      }

      /* Scroll-driven progress bar */
      .scroll-progress {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        height: 3px;
        z-index: 50;
        background: var(--color-blue-500);
        transform-origin: left;
        scale: 0 1;
        animation: scroll-fill linear forwards;
        animation-timeline: scroll();
      }
      @keyframes scroll-fill { to { scale: 1 1; } }

      /* Hero header gradient accent */
      @property --hero-angle {
        syntax: "<angle>";
        initial-value: 0deg;
        inherits: false;
      }
      .hero-accent {
        height: 3px;
        margin-top: 1rem;
        border-radius: 2px;
        background: linear-gradient(var(--hero-angle), var(--color-blue-500), var(--color-green-500), var(--color-blue-500));
        animation: hero-gradient 4s linear infinite;
      }
      @keyframes hero-gradient { to { --hero-angle: 360deg; } }

      .hero-features {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        margin-top: 0.75rem;
      }
      .hero-feature-tag {
        font-size: 0.6875rem;
        font-weight: 500;
        padding: 0.25rem 0.625rem;
        border-radius: 9999px;
        background: light-dark(var(--color-gray-100), var(--color-gray-800));
        color: light-dark(var(--color-gray-600), var(--color-gray-400));
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
      }

      /* Code snippet callout — light mode uses light bg + dark text, dark mode uses dark bg + light text */
      .code-callout {
        background: light-dark(var(--color-gray-50), oklch(0.13 0 0));
        color: light-dark(var(--color-gray-800), oklch(0.85 0 0));
        border-radius: 0.5rem;
        padding: 1.25rem;
        font-family: var(--font-mono);
        font-size: 0.8125rem;
        line-height: 1.6;
        overflow-x: auto;
        margin-top: 1rem;
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
      }
      .code-callout .comment { color: light-dark(var(--color-gray-400), oklch(0.55 0 0)); }
      .code-callout .keyword { color: light-dark(oklch(0.45 0.2 300), oklch(0.7 0.15 300)); }
      .code-callout .string { color: light-dark(oklch(0.4 0.2 150), oklch(0.7 0.15 150)); }
      .code-callout .type { color: light-dark(oklch(0.45 0.15 60), oklch(0.75 0.15 60)); }
      .code-callout .method { color: light-dark(oklch(0.4 0.2 230), oklch(0.75 0.15 230)); }

      /* === Tabs compound component === */
      .tabs-container {
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.75rem;
        overflow: hidden;
        background: light-dark(var(--color-white), var(--color-gray-800));
      }
      .tab-bar {
        display: flex;
        border-bottom: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        background: light-dark(var(--color-gray-50), var(--color-gray-900));
      }
      .tab-radio { position: absolute; opacity: 0; pointer-events: none; }
      .tab-label {
        flex: 1;
        padding: 0.75rem 1.25rem;
        font-size: 0.875rem;
        font-weight: 500;
        text-align: center;
        cursor: pointer;
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        border-bottom: 2px solid transparent;
        margin-bottom: -1px;
        transition: color 150ms, border-color 150ms;
      }
      .tab-radio:checked + .tab-label {
        color: var(--color-blue-500);
        border-bottom-color: var(--color-blue-500);
      }
      .tab-radio:focus-visible + .tab-label {
        outline: 2px solid var(--color-blue-500);
        outline-offset: -2px;
      }
      .tab-panel { display: none; padding: 1.5rem; }
      /* Show panel via :has() — checks which radio is checked in the container */
      .tabs-container:has(#tab-features:checked) > #panel-features,
      .tabs-container:has(#tab-pricing:checked) > #panel-pricing,
      .tabs-container:has(#tab-code:checked) > #panel-code { display: block; }

      /* Carousel */
      .carousel {
        display: flex;
        gap: 1rem;
        overflow-x: auto;
        scroll-snap-type: x mandatory;
        scroll-padding: 0 1rem;
        padding-bottom: 0.5rem;
        -webkit-overflow-scrolling: touch;
      }
      .carousel::-webkit-scrollbar { height: 4px; }
      .carousel::-webkit-scrollbar-track { background: light-dark(var(--color-gray-100), var(--color-gray-800)); border-radius: 2px; }
      .carousel::-webkit-scrollbar-thumb { background: var(--color-gray-300); border-radius: 2px; }
      .carousel-item {
        flex: 0 0 16rem;
        scroll-snap-align: start;
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.5rem;
        overflow: hidden;
        background: light-dark(var(--color-white), var(--color-gray-800));
        transition: transform 200ms ease, box-shadow 200ms ease;
      }
      .carousel-item:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 6px -1px oklch(0 0 0 / 0.1);
      }
      .carousel-item-icon {
        height: 5rem;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
      }
      .carousel-item-body { padding: 1rem; }
      .carousel-item-body h4 {
        font-weight: 600;
        font-size: 0.9375rem;
        margin-bottom: 0.375rem;
        color: light-dark(var(--color-gray-900), var(--color-white));
      }
      .carousel-item-body p {
        font-size: 0.8125rem;
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        line-height: 1.5;
      }

      /* Pricing cards */
      .pricing-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 1rem;
      }
      @media (max-width: 640px) { .pricing-grid { grid-template-columns: 1fr; } }
      .pricing-card {
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.5rem;
        padding: 1.5rem;
        text-align: center;
        background: light-dark(var(--color-white), var(--color-gray-800));
      }
      .pricing-popular {
        border-color: var(--color-blue-500);
        border-width: 2px;
        position: relative;
      }
      .pricing-popular::before {
        content: "Popular";
        position: absolute;
        top: -0.75rem;
        left: 50%;
        transform: translateX(-50%);
        background: var(--color-blue-500);
        color: var(--color-white);
        font-size: 0.6875rem;
        font-weight: 600;
        padding: 0.125rem 0.75rem;
        border-radius: 9999px;
      }
      .pricing-card h4 {
        font-size: 1rem;
        font-weight: 600;
        margin-bottom: 0.5rem;
        color: light-dark(var(--color-gray-900), var(--color-white));
      }
      .pricing-price {
        font-size: 2rem;
        font-weight: 800;
        margin-bottom: 0.25rem;
        color: light-dark(var(--color-gray-900), var(--color-white));
      }
      .pricing-period {
        font-size: 0.75rem;
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        margin-bottom: 1rem;
      }
      .pricing-features {
        list-style: none;
        padding: 0;
        font-size: 0.8125rem;
        color: light-dark(var(--color-gray-600), var(--color-gray-300));
        text-align: left;
        margin-bottom: 1.25rem;
      }
      .pricing-features li {
        padding: 0.375rem 0;
        border-bottom: 1px solid light-dark(var(--color-gray-100), var(--color-gray-700));
      }
      .pricing-features li::before { content: "\\2713\\0020"; color: var(--color-green-500); font-weight: 600; }

      /* === Application Dashboard === */
      .dashboard {
        display: grid;
        grid-template-columns: 11rem 1fr;
        grid-template-rows: auto 1fr;
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.75rem;
        overflow: hidden;
        min-height: 28rem;
        background: light-dark(var(--color-white), var(--color-gray-800));
        container-type: inline-size;
        container-name: dashboard;
      }
      @container dashboard (max-width: 36rem) {
        .dashboard { grid-template-columns: 1fr; }
        .dashboard-sidebar { display: none; }
      }
      .dashboard-header {
        grid-column: 1 / -1;
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 0.75rem 1.25rem;
        border-bottom: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        background: light-dark(var(--color-gray-50), var(--color-gray-900));
      }
      .dashboard-search {
        flex: 1;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        background: light-dark(var(--color-white), var(--color-gray-800));
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.375rem;
        padding: 0.375rem 0.75rem;
        font-size: 0.8125rem;
        max-width: 20rem;
      }
      .dashboard-search input {
        border: none;
        background: transparent;
        outline: none;
        font-size: 0.8125rem;
        color: inherit;
        width: 100%;
      }
      .dashboard-search input::placeholder { color: light-dark(var(--color-gray-400), var(--color-gray-500)); }
      .dashboard-sidebar {
        border-right: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        padding: 0.75rem 0;
        background: light-dark(var(--color-gray-50), var(--color-gray-900));
      }
      .dashboard-sidebar .nav-item {
        display: flex;
        align-items: center;
        gap: 0.625rem;
        padding: 0.5rem 1rem;
        font-size: 0.8125rem;
        color: light-dark(var(--color-gray-600), var(--color-gray-400));
        cursor: pointer;
        transition: background-color 100ms, color 100ms;
      }
      .dashboard-sidebar .nav-item:hover {
        background: light-dark(var(--color-gray-100), var(--color-gray-800));
      }
      /* :has() active sidebar state — zero JavaScript */
      .dashboard-sidebar .nav-radio { position: absolute; opacity: 0; pointer-events: none; }
      .dashboard-sidebar label:has(.nav-radio:checked) .nav-item {
        background: light-dark(var(--color-blue-50), oklch(0.3 0.05 260));
        color: var(--color-blue-500);
        font-weight: 500;
      }
      .dashboard-sidebar label:has(.nav-radio:focus-visible) .nav-item {
        outline: 2px solid var(--color-blue-500);
        outline-offset: -2px;
      }
      .dashboard-main { padding: 1.25rem; overflow: auto; }
      .stats-row {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 0.75rem;
        margin-bottom: 1.25rem;
      }
      @container dashboard (max-width: 36rem) {
        .stats-row { grid-template-columns: repeat(2, 1fr); }
      }
      .stat-card {
        padding: 1rem;
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.5rem;
        background: light-dark(var(--color-white), var(--color-gray-800));
      }
      .stat-card .stat-label {
        font-size: 0.6875rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        margin-bottom: 0.25rem;
      }
      .stat-card .stat-value {
        font-size: 1.5rem;
        font-weight: 700;
        color: light-dark(var(--color-gray-900), var(--color-white));
      }
      .stat-card .stat-trend {
        font-size: 0.6875rem;
        margin-top: 0.25rem;
      }
      .stat-trend-up { color: var(--color-green-500); }
      .stat-trend-down { color: var(--color-red-500); }
      .data-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 0.8125rem;
      }
      .data-table th {
        text-align: left;
        padding: 0.625rem 0.75rem;
        font-weight: 600;
        font-size: 0.6875rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        border-bottom: 2px solid light-dark(var(--color-gray-200), var(--color-gray-700));
      }
      .data-table td {
        padding: 0.625rem 0.75rem;
        border-bottom: 1px solid light-dark(var(--color-gray-100), var(--color-gray-700));
        color: light-dark(var(--color-gray-700), var(--color-gray-300));
      }
      .data-table tr:hover td {
        background: light-dark(var(--color-gray-50), var(--color-gray-900));
      }
      /* Notification popover — anchored to bell button */
      .notif-popover {
        position: fixed;
        inset: unset;
        margin: 0.5rem 0 0 0;
        position-area: bottom span-left;
        position-try-fallbacks: flip-block, flip-inline;
        background: light-dark(var(--color-white), var(--color-gray-800));
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.5rem;
        padding: 0.75rem;
        box-shadow: 0 10px 15px -3px oklch(0 0 0 / 0.1);
        min-width: 16rem;
        font-size: 0.8125rem;
      }
      .notif-item {
        padding: 0.5rem;
        border-radius: 0.375rem;
        display: flex;
        gap: 0.5rem;
        align-items: flex-start;
      }
      .notif-item:hover { background: light-dark(var(--color-gray-50), var(--color-gray-700)); }
      .notif-dot {
        width: 0.5rem;
        height: 0.5rem;
        border-radius: 9999px;
        background: var(--color-blue-500);
        flex-shrink: 0;
        margin-top: 0.375rem;
      }

      /* === Scroll-driven animations === */
      .scroll-reveal {
        opacity: 0;
        transform: translateY(2rem) scale(0.95);
        animation: fade-in-view linear forwards;
        animation-timeline: view();
        animation-range: cover 0% cover 40%;
      }
      @keyframes fade-in-view {
        to { opacity: 1; transform: translateY(0) scale(1); }
      }
      .scroll-card-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr));
        gap: 1rem;
      }
      .scroll-card {
        padding: 1.25rem;
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.5rem;
        background: light-dark(var(--color-white), var(--color-gray-800));
      }
      .scroll-card h4 {
        font-weight: 600;
        font-size: 0.9375rem;
        margin-bottom: 0.375rem;
        color: light-dark(var(--color-gray-900), var(--color-white));
      }
      .scroll-card p {
        font-size: 0.8125rem;
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        line-height: 1.5;
      }
      .parallax-band {
        height: 4rem;
        background: linear-gradient(135deg, var(--color-blue-500), var(--color-green-500));
        margin: 2rem -2rem;
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--color-white);
        font-weight: 600;
        font-size: 0.875rem;
        letter-spacing: 0.05em;
      }

      /* === Token reference (collapsed details) === */
      .token-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 0.75rem;
        font-family: var(--font-mono);
      }
      .token-table th {
        text-align: left;
        padding: 0.375rem 0.5rem;
        font-weight: 600;
        font-size: 0.6875rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: light-dark(var(--color-gray-500), var(--color-gray-400));
        border-bottom: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
      }
      .token-table td {
        padding: 0.375rem 0.5rem;
        border-bottom: 1px solid light-dark(var(--color-gray-100), var(--color-gray-700));
        color: light-dark(var(--color-gray-600), var(--color-gray-400));
      }

      /* === Consolidated settings form === */
      .settings-form {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1.5rem;
        padding: 1.5rem;
        border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700));
        border-radius: 0.75rem;
        background: light-dark(var(--color-white), var(--color-gray-800));
        margin-bottom: 1.5rem;
      }
      @media (max-width: 640px) { .settings-form { grid-template-columns: 1fr; } }
      .settings-section h4 {
        font-weight: 600;
        font-size: 0.875rem;
        margin-bottom: 0.75rem;
        color: light-dark(var(--color-gray-900), var(--color-white));
      }
        </style>
      </head>
      <body>
        <div class="brand-kit">
      HEAD

      # Scroll progress bar
      html << %(<div class="scroll-progress" aria-hidden="true"></div>\n)

      # Header with color scheme toggle
      html << <<-HEADER
          <header style="margin-bottom: 3rem;">
            <div style="display: flex; align-items: flex-start; justify-content: space-between; flex-wrap: wrap; gap: 1rem;">
              <div>
                <h1 style="font-size: 2rem; font-weight: 800; margin-bottom: 0.25rem;">Asset Pipeline Design System Brand Kit</h1>
                <p style="color: light-dark(var(--color-gray-500), var(--color-gray-400)); font-size: 1rem;">
                  Design tokens, component library, and WCAG 2.2 AA accessibility showcase.<br>
                  Generated from the CSS engine — this file <em>is</em> the source of truth.
                </p>
                <div class="hero-accent"></div>
                <div class="hero-features">
                  <span class="hero-feature-tag">CSS Anchor Positioning</span>
                  <span class="hero-feature-tag">Scroll-Driven Animations</span>
                  <span class="hero-feature-tag">light-dark()</span>
                  <span class="hero-feature-tag">@property</span>
                  <span class="hero-feature-tag">Container Queries</span>
                  <span class="hero-feature-tag">:has() Selector</span>
                  <span class="hero-feature-tag">Popover API</span>
                  <span class="hero-feature-tag">scroll-snap</span>
                </div>
              </div>
              <div class="scheme-toggle" role="group" aria-label="Color scheme">
                <button type="button" aria-pressed="false" onclick="setScheme('light')">Light</button>
                <button type="button" aria-pressed="true" onclick="setScheme('auto')">Auto</button>
                <button type="button" aria-pressed="false" onclick="setScheme('dark')">Dark</button>
              </div>
            </div>
            <script>
              function setScheme(mode) {
                const html = document.documentElement;
                const buttons = document.querySelectorAll('.scheme-toggle button');
                buttons.forEach(b => b.setAttribute('aria-pressed', 'false'));
                if (mode === 'light') { html.style.colorScheme = 'light'; buttons[0].setAttribute('aria-pressed', 'true'); }
                else if (mode === 'dark') { html.style.colorScheme = 'dark'; buttons[2].setAttribute('aria-pressed', 'true'); }
                else { html.style.colorScheme = ''; buttons[1].setAttribute('aria-pressed', 'true'); }
              }
            </script>
          </header>
      HEADER

      # Table of contents
      html << <<-TOC
          <nav class="section" aria-label="Table of contents">
            <p class="section-title">Contents</p>
            <ol style="column-count: 2; column-gap: 2rem; font-size: 0.875rem; padding-left: 1.5rem;">
              <li><a href="#colors">Color Palette</a></li>
              <li><a href="#typography">Typography</a></li>
              <li><a href="#modern-layout">Modern Typography &amp; Layout</a></li>
              <li><a href="#spacing">Spacing Scale</a></li>
              <li><a href="#buttons">Buttons</a></li>
              <li><a href="#cards">Cards</a></li>
              <li><a href="#tabs-carousel">Tabs &amp; Carousel</a></li>
              <li><a href="#forms">Forms</a></li>
              <li><a href="#alerts">Alerts &amp; Badges</a></li>
              <li><a href="#dashboard">Application Dashboard</a></li>
              <li><a href="#dialog-popover">Dialog &amp; Popover</a></li>
              <li><a href="#shadows">Shadows &amp; Borders</a></li>
              <li><a href="#scroll-animations">Scroll-Driven Animations</a></li>
              <li><a href="#transitions">Transitions &amp; Animation</a></li>
              <li><a href="#accessibility">Accessibility</a></li>
              <li><a href="#token-reference">Design Token Reference</a></li>
            </ol>
          </nav>
      TOC

      # --- Colors ---
      html << color_section

      # --- Typography ---
      html << typography_section

      # --- Modern Typography & Layout ---
      html << modern_layout_section

      # --- Spacing ---
      html << spacing_section

      # --- Buttons ---
      html << buttons_section

      # --- Cards ---
      html << cards_section

      # --- Tabs & Carousel ---
      html << tabs_carousel_section

      # --- Forms (merged basic + modern) ---
      html << forms_section

      # --- Alerts & Badges ---
      html << alerts_section

      # --- Application Dashboard ---
      html << dashboard_section

      # --- Dialog & Popover ---
      html << dialog_popover_section

      # --- Shadows & Borders ---
      html << shadows_section

      # --- Scroll-Driven Animations ---
      html << scroll_animations_section

      # --- Transitions & Animation ---
      html << transitions_section

      # --- Accessibility (consolidated) ---
      html << accessibility_section

      # --- Design Token Reference ---
      html << token_reference_section

      # Footer
      html << <<-FOOTER
          <footer style="margin-top: 4rem; padding-top: 2rem; border-top: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700)); font-size: 0.75rem; color: light-dark(var(--color-gray-400), var(--color-gray-500));">
            <p>Generated by the Asset Pipeline CSS engine. All styles above are produced by the engine — no external CSS.</p>
          </footer>
        </div>
      </body>
      </html>
      FOOTER
    end
  end

  # === Section builders ===

  def self.color_section : String
    config = Components::CSS::Config.new
    String.build do |s|
      s << %(<section class="section" id="colors">\n)
      s << %(<p class="section-title">Color Palette</p>\n)
      s << %(<p class="section-desc">oklch color space for perceptually uniform lightness. All colors available as utilities and custom properties.</p>\n)

      config.colors.each do |name, value|
        case value
        when Hash
          s << %(<h3 style="font-size: 0.875rem; font-weight: 600; text-transform: capitalize; margin: 1rem 0 0.5rem;">#{name}</h3>\n)
          s << %(<div class="swatch-grid">\n)
          value.each do |shade, color|
            s << %(<div class="swatch" style="background-color: #{color};"><span>#{shade}</span></div>\n)
          end
          s << %(</div>\n)
        when String
          next if name == "transparent" || name == "current"
          # Single-value colors shown inline
        end
      end

      # Special values
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.5rem;">Special Values</h3>\n)
      s << %(<div class="sample-row">\n)
      s << %(<div style="width: 5rem; height: 3rem; background: oklch(0 0 0); border-radius: 0.375rem; border: 1px solid light-dark(var(--color-gray-300), var(--color-gray-600));"></div>\n)
      s << %(<span class="code">black</span>\n)
      s << %(<div style="width: 5rem; height: 3rem; background: oklch(1 0 0); border-radius: 0.375rem; border: 1px solid light-dark(var(--color-gray-300), var(--color-gray-600));"></div>\n)
      s << %(<span class="code">white</span>\n)
      s << %(</div>\n)

      s << %(</section>\n)
    end
  end

  def self.typography_section : String
    String.build do |s|
      s << %(<section class="section" id="typography">\n)
      s << %(<p class="section-title">Typography</p>\n)
      s << %(<p class="section-desc">Font sizes, weights, and line heights. All available as utility classes.</p>\n)

      # Font sizes
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 1rem;">Scale</h3>\n)
      [{"text-xs", "0.75rem"}, {"text-sm", "0.875rem"}, {"text-base", "1rem"},
       {"text-lg", "1.125rem"}, {"text-xl", "1.25rem"}, {"text-2xl", "1.5rem"},
       {"text-3xl", "1.875rem"}].each do |name, size|
        s << %(<div class="type-row" style="display: flex; align-items: baseline; gap: 1rem;">\n)
        s << %(<span class="code" style="width: 6rem; flex-shrink: 0;">#{name}</span>\n)
        s << %(<span style="font-size: #{size};">The quick brown fox jumps over the lazy dog</span>\n)
        s << %(</div>\n)
      end

      # Font weights
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 1rem;">Weights</h3>\n)
      [{"font-thin", "100"}, {"font-light", "300"}, {"font-normal", "400"},
       {"font-medium", "500"}, {"font-semibold", "600"}, {"font-bold", "700"},
       {"font-extrabold", "800"}, {"font-black", "900"}].each do |name, weight|
        s << %(<div class="type-row" style="display: flex; align-items: baseline; gap: 1rem;">\n)
        s << %(<span class="code" style="width: 8rem; flex-shrink: 0;">#{name}</span>\n)
        s << %(<span style="font-weight: #{weight};">Asset Pipeline Design System</span>\n)
        s << %(</div>\n)
      end

      s << %(</section>\n)
    end
  end

  def self.spacing_section : String
    config = Components::CSS::Config.new
    String.build do |s|
      s << %(<section class="section" id="spacing">\n)
      s << %(<p class="section-title">Spacing Scale</p>\n)
      s << %(<p class="section-desc">Consistent spacing used for margin (m-*) and padding (p-*) utilities.</p>\n)

      %w[0 1 2 3 4 5 6 8 10 12 16 20 24 32 40 48 64].each do |key|
        if value = config.spacing[key]?
          s << %(<div style="display: flex; align-items: center; gap: 1rem; margin-bottom: 0.375rem;">\n)
          s << %(<span class="code" style="width: 3rem; text-align: right;">#{key}</span>\n)
          s << %(<span style="font-size: 0.75rem; width: 4rem; color: light-dark(var(--color-gray-500), var(--color-gray-400));">#{value}</span>\n)
          s << %(<div class="spacing-bar" style="width: #{value};"></div>\n)
          s << %(</div>\n)
        end
      end

      s << %(</section>\n)
    end
  end

  def self.buttons_section : String
    String.build do |s|
      s << %(<section class="section" id="buttons">\n)
      s << %(<p class="section-title">Buttons</p>\n)
      s << %(<p class="section-desc">Component-layer button styles. Tab through to test focus rings (WCAG 2.4.7).</p>\n)

      # Variants
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">Variants</h3>\n)
      s << %(<div class="sample-row">\n)
      s << %(<button class="btn btn-primary">Primary</button>\n)
      s << %(<button class="btn btn-secondary">Secondary</button>\n)
      s << %(<button class="btn btn-danger">Danger</button>\n)
      s << %(<button class="btn btn-success">Success</button>\n)
      s << %(</div>\n)

      # Sizes
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">Sizes</h3>\n)
      s << %(<div class="sample-row">\n)
      s << %(<button class="btn btn-primary btn-sm">Small</button>\n)
      s << %(<button class="btn btn-primary">Default</button>\n)
      s << %(<button class="btn btn-primary btn-lg">Large</button>\n)
      s << %(</div>\n)

      # States
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">States</h3>\n)
      s << %(<div class="sample-row">\n)
      s << %(<button class="btn btn-primary">Normal</button>\n)
      s << %(<button class="btn btn-primary" disabled>Disabled</button>\n)
      s << %(<button class="btn btn-secondary">Normal</button>\n)
      s << %(<button class="btn btn-secondary" disabled>Disabled</button>\n)
      s << %(</div>\n)

      s << %(</section>\n)
    end
  end

  def self.cards_section : String
    String.build do |s|
      s << %(<section class="section" id="cards">\n)
      s << %(<p class="section-title">Cards</p>\n)
      s << %(<p class="section-desc">Component-layer card styles using light-dark() for automatic dark mode.</p>\n)

      s << %(<div class="grid-2">\n)
      3.times do |i|
        s << %(<div class="card">\n)
        s << %(<div class="card-body">\n)
        s << %(<p class="card-title">Card Title #{i + 1}</p>\n)
        s << %(<p class="card-text">This card uses light-dark() for its background and border colors. Toggle your OS dark mode to see it adapt automatically.</p>\n)
        s << %(<button class="btn btn-primary btn-sm" style="margin-top: 0.75rem;">Action</button>\n)
        s << %(</div>\n)
        s << %(</div>\n)
      end
      s << %(</div>\n)

      s << %(</section>\n)
    end
  end

  def self.tabs_carousel_section : String
    String.build do |s|
      s << %(<section class="section" id="tabs-carousel">\n)
      s << %(<p class="section-title">Tabs &amp; Carousel</p>\n)
      s << %(<p class="section-desc">CSS-only tabbed interface using radio inputs + <code>:checked</code> sibling selectors. Carousel uses <code>scroll-snap-type: x mandatory</code>. Maps to <code>Elements::Input.radio()</code>, <code>Elements::Label</code>, and <code>CardComponent</code>.</p>\n)

      # Tabbed container — uses radio buttons for CSS-only tab switching
      s << %(<div class="tabs-container">\n)

      # Tab bar with radio inputs + labels
      s << %(<div class="tab-bar">\n)
      s << %(<input type="radio" name="showcase-tab" id="tab-features" class="tab-radio" checked>\n)
      s << %(<label for="tab-features" class="tab-label">Features</label>\n)
      s << %(<input type="radio" name="showcase-tab" id="tab-pricing" class="tab-radio">\n)
      s << %(<label for="tab-pricing" class="tab-label">Pricing</label>\n)
      s << %(<input type="radio" name="showcase-tab" id="tab-code" class="tab-radio">\n)
      s << %(<label for="tab-code" class="tab-label">Code</label>\n)
      s << %(</div>\n)

      # Tab 1: Features — horizontal scroll-snap carousel
      s << %(<div class="tab-panel" id="panel-features">\n)
      s << %(<div class="carousel">\n)

      features = [
        {"ClassBuilder DSL", "Build variant-aware class lists with a fluent API. Supports hover, focus, responsive, and ARIA states.", "linear-gradient(135deg, var(--color-blue-500), var(--color-blue-700))", "badge-blue", "Core"},
        {"Styleable Mixin", "Add CSS class management to any component with .css(), .class_names(), and .variant_classes().", "linear-gradient(135deg, var(--color-green-500), var(--color-green-700))", "badge-green", "Mixin"},
        {"37 Element Classes", "Type-safe HTML elements with factory methods, validation, and semantic attributes built in.", "linear-gradient(135deg, var(--color-red-500), var(--color-red-700))", "badge-red", "Elements"},
        {"Reactive Components", "StatefulComponent and ReactiveComponent patterns for interactive UI without JS framework overhead.", "linear-gradient(135deg, var(--color-gray-500), var(--color-gray-700))", "badge-gray", "Patterns"},
        {"CSS Engine", "Generate utility classes, design tokens, and component styles from Crystal configuration objects.", "linear-gradient(135deg, var(--color-blue-700), var(--color-green-500))", "badge-blue", "Engine"},
      ]

      features.each do |title, desc, gradient, badge_class, badge_text|
        s << %(<div class="carousel-item">\n)
        s << %(<div class="carousel-item-icon" style="background: #{gradient}; color: var(--color-white);">)
        s << %(#{title.chars.first}</div>\n)
        s << %(<div class="carousel-item-body">\n)
        s << %(<div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.375rem;">\n)
        s << %(<h4>#{title}</h4>\n)
        s << %(<span class="badge #{badge_class}">#{badge_text}</span>\n)
        s << %(</div>\n)
        s << %(<p>#{desc}</p>\n)
        s << %(</div>\n)
        s << %(</div>\n)
      end

      s << %(</div>\n)
      s << %(</div>\n)

      # Tab 2: Pricing — 3-tier grid
      s << %(<div class="tab-panel" id="panel-pricing">\n)
      s << %(<div class="pricing-grid">\n)

      # Free tier
      s << %(<div class="pricing-card">\n)
      s << %(<h4>Starter</h4>\n)
      s << %(<div class="pricing-price">Free</div>\n)
      s << %(<div class="pricing-period">Open source, forever</div>\n)
      s << %(<ul class="pricing-features">\n)
      s << %(<li>Full framework core</li>\n)
      s << %(<li>Memory adapters</li>\n)
      s << %(<li>ECR templates</li>\n)
      s << %(<li>Background jobs</li>\n)
      s << %(</ul>\n)
      s << %(<button class="btn btn-secondary" style="width: 100%;">Get Started</button>\n)
      s << %(</div>\n)

      # Pro tier (popular)
      s << %(<div class="pricing-card pricing-popular">\n)
      s << %(<h4>Pro</h4>\n)
      s << %(<div class="pricing-price">$29</div>\n)
      s << %(<div class="pricing-period">per month</div>\n)
      s << %(<ul class="pricing-features">\n)
      s << %(<li>Everything in Starter</li>\n)
      s << %(<li>Redis adapters</li>\n)
      s << %(<li>Priority support</li>\n)
      s << %(<li>Component library</li>\n)
      s << %(<li>Asset pipeline</li>\n)
      s << %(</ul>\n)
      s << %(<button class="btn btn-primary" style="width: 100%;">Subscribe</button>\n)
      s << %(</div>\n)

      # Enterprise tier
      s << %(<div class="pricing-card">\n)
      s << %(<h4>Enterprise</h4>\n)
      s << %(<div class="pricing-price">Custom</div>\n)
      s << %(<div class="pricing-period">tailored to your team</div>\n)
      s << %(<ul class="pricing-features">\n)
      s << %(<li>Everything in Pro</li>\n)
      s << %(<li>Dedicated support</li>\n)
      s << %(<li>Custom adapters</li>\n)
      s << %(<li>SLA guarantee</li>\n)
      s << %(<li>Training sessions</li>\n)
      s << %(</ul>\n)
      s << %(<button class="btn btn-secondary" style="width: 100%;">Contact Sales</button>\n)
      s << %(</div>\n)

      s << %(</div>\n)
      s << %(</div>\n)

      # Tab 3: Code — Crystal code snippet
      s << %(<div class="tab-panel" id="panel-code">\n)
      s << %(<p style="font-size: 0.875rem; margin-bottom: 0.75rem; color: light-dark(var(--color-gray-600), var(--color-gray-300));">The component system uses <code>ClassBuilder</code> for variant-aware class lists and <code>Styleable</code> for CSS integration. Here is how you compose components with the Crystal API:</p>\n)
      s << %(<pre class="code-callout"><code>)
      s << %(<span class="comment"># Build a button with the ClassBuilder DSL</span>\n)
      s << %(<span class="type">button</span> = <span class="type">Elements::Button</span>.<span class="method">new</span>(<span class="string">"Get Started"</span>, type: <span class="string">"button"</span>)\n)
      s << %(<span class="type">button</span>.add_class(css { |c|\n)
      s << %(  c.<span class="method">base</span>(<span class="string">"btn"</span>, <span class="string">"btn-primary"</span>)\n)
      s << %(  c.<span class="method">hover</span>(<span class="string">"shadow-lg"</span>)\n)
      s << %(  c.<span class="method">focus_visible</span>(<span class="string">"ring-2"</span>)\n)
      s << %(  c.<span class="method">responsive</span> { |r| r.<span class="method">lg</span>(<span class="string">"btn-lg"</span>) }\n)
      s << %(})\n)
      s << %(\n)
      s << %(<span class="comment"># Create a card with Styleable</span>\n)
      s << %(<span class="keyword">class</span> <span class="type">FeatureCard</span> &lt; <span class="type">StatelessComponent</span>\n)
      s << %(  <span class="keyword">include</span> <span class="type">Styleable</span>\n)
      s << %(\n)
      s << %(  <span class="keyword">def</span> <span class="method">template</span>\n)
      s << %(    <span class="type">Elements::Article</span>.<span class="method">new</span>(\n)
      s << %(      class: variant_classes(<span class="string">"card"</span>, size: <span class="string">"lg"</span>)\n)
      s << %(    )\n)
      s << %(  <span class="keyword">end</span>\n)
      s << "<span class=\"keyword\">end</span></code></pre>\n"
      s << %(</div>\n)

      s << %(</div>\n) # close tabs-container

      s << %(</section>\n)
    end
  end

  def self.forms_section : String
    String.build do |s|
      s << %(<section class="section" id="forms">\n)
      s << %(<p class="section-title">Forms</p>\n)
      s << %(<p class="section-desc">From basic controls to modern CSS features. Maps to <code>FormComponent</code>, <code>Elements::Input</code> factory methods (<code>.text</code>, <code>.email</code>, <code>.radio</code>, <code>.checkbox</code>, <code>.range</code>, <code>.color</code>), <code>Elements::Select</code>, <code>Elements::Textarea</code>, and <code>Elements::Label</code>.</p>\n)

      # Compound demo: Settings page
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">Compound Demo: Settings Page</h3>\n)
      s << %(<div class="settings-form">\n)

      # Profile section
      s << %(<div class="settings-section">\n)
      s << %(<h4>Profile</h4>\n)
      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="settings-name">Display Name</label>\n)
      s << %(<input class="form-control" type="text" id="settings-name" value="Seth Tucker">\n)
      s << %(</div>\n)
      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="settings-email">Email</label>\n)
      s << %(<input class="form-control" type="email" id="settings-email" value="seth@example.com">\n)
      s << %(</div>\n)
      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="settings-bio">Bio</label>\n)
      s << %(<textarea class="form-control" id="settings-bio" style="field-sizing: content; min-height: 2.5rem; resize: vertical;" placeholder="Tell us about yourself..."></textarea>\n)
      s << %(<p class="form-hint">Uses <code>field-sizing: content</code> — auto-expands as you type.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # Notifications section (toggle switches)
      s << %(<div class="settings-section">\n)
      s << %(<h4>Notifications</h4>\n)
      s << %(<div style="display: flex; flex-direction: column; gap: 0.75rem;">\n)
      [{"settings-notif-email", "Email notifications", true},
       {"settings-notif-push", "Push notifications", false},
       {"settings-notif-weekly", "Weekly digest", true}].each do |id, label, checked|
        s << %(<div style="display: flex; align-items: center; gap: 0.75rem;">\n)
        s << %(<label class="toggle-switch">\n)
        s << %(<input type="checkbox" id="#{id}"#{checked ? " checked" : ""}>\n)
        s << %(<span class="toggle-track"></span>\n)
        s << %(</label>\n)
        s << %(<label for="#{id}" style="font-size: 0.875rem; cursor: pointer;">#{label}</label>\n)
        s << %(</div>\n)
      end
      s << %(</div>\n)

      s << %(<h4 style="margin-top: 1.25rem;">Preferences</h4>\n)
      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="settings-theme">Theme</label>\n)
      s << %(<select class="custom-select" id="settings-theme">\n)
      s << %(<option value="auto">System Default</option>\n)
      s << %(<option value="light">Light</option>\n)
      s << %(<option value="dark">Dark</option>\n)
      s << %(</select>\n)
      s << %(</div>\n)
      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="settings-lang">Language</label>\n)
      s << %(<select class="custom-select" id="settings-lang">\n)
      s << %(<option value="en">English</option>\n)
      s << %(<option value="es">Espa&ntilde;ol</option>\n)
      s << %(<option value="de">Deutsch</option>\n)
      s << %(</select>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      s << %(</div>\n) # close .settings-form

      # Basic controls
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">Basic Controls</h3>\n)
      s << %(<div style="max-width: 32rem;">\n)

      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="demo-name">Name</label>\n)
      s << %(<input class="form-control" type="text" id="demo-name" placeholder="Enter your name">\n)
      s << %(<p class="form-hint">Maps to <code>Elements::Input.text("name")</code></p>\n)
      s << %(</div>\n)

      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="demo-email">Email <span style="color: var(--color-red-500);">*</span></label>\n)
      s << %(<input class="form-control" type="email" id="demo-email" placeholder="you@example.com" required>\n)
      s << %(<p class="form-hint">Type an invalid email to see <code>:invalid</code> styling. Maps to <code>Elements::Input.email("email")</code></p>\n)
      s << %(</div>\n)

      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="demo-msg">Message</label>\n)
      s << %(<textarea class="form-control" id="demo-msg" rows="3" placeholder="Your message..."></textarea>\n)
      s << %(</div>\n)

      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="demo-err">With Error</label>\n)
      s << %(<input class="form-control" type="text" id="demo-err" value="bad" aria-invalid="true" style="border-color: var(--color-red-500);">\n)
      s << %(<p class="form-error">This field has an error message.</p>\n)
      s << %(</div>\n)

      s << %(<div class="form-group">\n)
      s << %(<label class="form-label" for="demo-dis">Disabled</label>\n)
      s << %(<input class="form-control" type="text" id="demo-dis" value="Cannot edit" disabled style="opacity: 0.5;">\n)
      s << %(</div>\n)

      s << %(<button class="btn btn-primary">Submit</button>\n)
      s << %(</div>\n)

      # Modern features
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">accent-color</h3>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400)); margin-bottom: 0.75rem;">Native form controls inherit their accent color from CSS design tokens.</p>\n)
      s << %(<div class="grid-2">\n)
      s << %(<div class="demo-box">\n)
      s << %(<p class="a11y-label">Range slider</p>\n)
      s << %(<input type="range" min="0" max="100" value="65" style="accent-color: var(--color-blue-500); width: 100%;">\n)
      s << %(<div style="display: flex; gap: 0.5rem; margin-top: 0.5rem;">\n)
      s << %(<input type="range" min="0" max="100" value="40" style="accent-color: var(--color-green-500); width: 100%;">\n)
      s << %(<input type="range" min="0" max="100" value="80" style="accent-color: var(--color-red-500); width: 100%;">\n)
      s << %(</div>\n)
      s << %(</div>\n)
      s << %(<div class="demo-box">\n)
      s << %(<p class="a11y-label">Checkboxes, radios &amp; progress</p>\n)
      s << %(<div style="display: flex; flex-wrap: wrap; gap: 1rem; align-items: center; margin-bottom: 0.75rem;">\n)
      s << %(<label style="display: flex; align-items: center; gap: 0.375rem; font-size: 0.875rem;"><input type="checkbox" checked style="accent-color: var(--color-blue-500); width: 1.125rem; height: 1.125rem;"> Blue</label>\n)
      s << %(<label style="display: flex; align-items: center; gap: 0.375rem; font-size: 0.875rem;"><input type="checkbox" checked style="accent-color: var(--color-green-500); width: 1.125rem; height: 1.125rem;"> Green</label>\n)
      s << %(<label style="display: flex; align-items: center; gap: 0.375rem; font-size: 0.875rem;"><input type="checkbox" checked style="accent-color: var(--color-red-500); width: 1.125rem; height: 1.125rem;"> Red</label>\n)
      s << %(</div>\n)
      s << %(<div style="display: flex; flex-wrap: wrap; gap: 1rem; align-items: center; margin-bottom: 0.75rem;">\n)
      s << %(<label style="display: flex; align-items: center; gap: 0.375rem; font-size: 0.875rem;"><input type="radio" name="accent-demo" checked style="accent-color: var(--color-blue-500); width: 1.125rem; height: 1.125rem;"> Option A</label>\n)
      s << %(<label style="display: flex; align-items: center; gap: 0.375rem; font-size: 0.875rem;"><input type="radio" name="accent-demo" style="accent-color: var(--color-blue-500); width: 1.125rem; height: 1.125rem;"> Option B</label>\n)
      s << %(</div>\n)
      s << %(<progress value="70" max="100" style="accent-color: var(--color-blue-500); width: 100%; height: 0.5rem;"></progress>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # Color picker
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">Color Picker</h3>\n)
      s << %(<div class="sample-row">\n)
      s << %(<div style="display: flex; align-items: center; gap: 0.75rem;">\n)
      s << %(<label for="color-primary" class="form-label" style="margin: 0;">Primary</label>\n)
      s << %(<input type="color" id="color-primary" value="#3B82F6" style="width: 3rem; height: 2rem; border: 1px solid light-dark(var(--color-gray-300), var(--color-gray-600)); border-radius: 0.375rem; cursor: pointer;">\n)
      s << %(</div>\n)
      s << %(<div style="display: flex; align-items: center; gap: 0.75rem;">\n)
      s << %(<label for="color-accent" class="form-label" style="margin: 0;">Accent</label>\n)
      s << %(<input type="color" id="color-accent" value="#10B981" style="width: 3rem; height: 2rem; border: 1px solid light-dark(var(--color-gray-300), var(--color-gray-600)); border-radius: 0.375rem; cursor: pointer;">\n)
      s << %(</div>\n)
      s << %(<div style="display: flex; align-items: center; gap: 0.75rem;">\n)
      s << %(<label for="color-danger" class="form-label" style="margin: 0;">Danger</label>\n)
      s << %(<input type="color" id="color-danger" value="#EF4444" style="width: 3rem; height: 2rem; border: 1px solid light-dark(var(--color-gray-300), var(--color-gray-600)); border-radius: 0.375rem; cursor: pointer;">\n)
      s << %(</div>\n)
      s << %(</div>\n)

      s << %(</section>\n)
    end
  end

  def self.alerts_section : String
    String.build do |s|
      s << %(<section class="section" id="alerts">\n)
      s << %(<p class="section-title">Alerts &amp; Badges</p>\n)
      s << %(<p class="section-desc">Feedback components for status communication.</p>\n)

      # Alerts
      s << %(<div class="alert alert-info" role="alert" style="margin-bottom: 0.75rem;">)
      s << %(<strong>Info:</strong> This is an informational message.</div>\n)
      s << %(<div class="alert alert-success" role="alert" style="margin-bottom: 0.75rem;">)
      s << %(<strong>Success:</strong> Operation completed.</div>\n)
      s << %(<div class="alert alert-warning" role="alert" style="margin-bottom: 0.75rem;">)
      s << %(<strong>Warning:</strong> Please review before continuing.</div>\n)
      s << %(<div class="alert alert-danger" role="alert" style="margin-bottom: 0.75rem;">)
      s << %(<strong>Error:</strong> Something went wrong.</div>\n)

      # Badges
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">Badges</h3>\n)
      s << %(<div class="sample-row">\n)
      s << %(<span class="badge badge-blue">New</span>\n)
      s << %(<span class="badge badge-green">Active</span>\n)
      s << %(<span class="badge badge-red">Removed</span>\n)
      s << %(<span class="badge badge-gray">Draft</span>\n)
      s << %(</div>\n)

      s << %(</section>\n)
    end
  end

  def self.dashboard_section : String
    String.build do |s|
      s << %(<section class="section" id="dashboard">\n)
      s << %(<p class="section-title">Application Dashboard</p>\n)
      s << %(<p class="section-desc">A realistic mini-SaaS dashboard composing 8+ element types. Sidebar navigation uses <code>:has(:checked)</code> for active state — zero JavaScript. Notification popover uses CSS anchor positioning. Maps to <code>Elements::Nav</code>, <code>Elements::Table</code>, <code>Elements::Input.search()</code>, <code>StatelessComponent</code>, and <code>LiveSearchComponent</code>.</p>\n)

      s << %(<div class="dashboard">\n)

      # Dashboard header with search + notification bell
      s << %(<div class="dashboard-header">\n)
      s << %(<div class="dashboard-search">\n)
      s << %(<span style="color: light-dark(var(--color-gray-400), var(--color-gray-500));">&#128269;</span>\n)
      s << %(<input type="search" placeholder="Search users, tasks..." aria-label="Search dashboard">\n)
      s << %(</div>\n)
      s << %(<div style="margin-left: auto; display: flex; align-items: center; gap: 0.5rem;">\n)
      s << %(<button class="btn btn-secondary btn-sm" popovertarget="notif-pop" style="position: relative; padding: 0.375rem 0.5rem;">&#128276;\n)
      s << %(<span style="position: absolute; top: -2px; right: -2px; width: 0.5rem; height: 0.5rem; background: var(--color-red-500); border-radius: 9999px;"></span>\n)
      s << %(</button>\n)
      s << %(<div id="notif-pop" popover class="notif-popover">\n)
      s << %(<p style="font-weight: 600; margin-bottom: 0.5rem;">Notifications</p>\n)
      s << %(<div class="notif-item"><span class="notif-dot"></span><div><strong>New user registered</strong><br><span style="color: light-dark(var(--color-gray-500), var(--color-gray-400)); font-size: 0.75rem;">2 minutes ago</span></div></div>\n)
      s << %(<div class="notif-item"><span class="notif-dot"></span><div><strong>Task completed</strong><br><span style="color: light-dark(var(--color-gray-500), var(--color-gray-400)); font-size: 0.75rem;">15 minutes ago</span></div></div>\n)
      s << %(<div class="notif-item"><span class="notif-dot" style="background: var(--color-gray-300);"></span><div><strong>Server backup done</strong><br><span style="color: light-dark(var(--color-gray-500), var(--color-gray-400)); font-size: 0.75rem;">1 hour ago</span></div></div>\n)
      s << %(</div>\n)
      s << %(<div style="width: 2rem; height: 2rem; border-radius: 9999px; background: var(--color-blue-500); color: var(--color-white); display: flex; align-items: center; justify-content: center; font-size: 0.75rem; font-weight: 600;">ST</div>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # Sidebar navigation with :has() active state
      s << %(<nav class="dashboard-sidebar" aria-label="Dashboard navigation">\n)
      nav_items = [
        {"dashboard-nav-home", "&#127968;", "Home", true},
        {"dashboard-nav-users", "&#128100;", "Users", false},
        {"dashboard-nav-tasks", "&#9745;", "Tasks", false},
        {"dashboard-nav-messages", "&#128172;", "Messages", false},
        {"dashboard-nav-settings", "&#9881;", "Settings", false},
      ]
      nav_items.each do |id, icon, label, checked|
        s << %(<label>\n)
        s << %(<input type="radio" name="dashboard-nav" id="#{id}" class="nav-radio"#{checked ? " checked" : ""}>\n)
        s << %(<span class="nav-item">#{icon} #{label}</span>\n)
        s << %(</label>\n)
      end
      s << %(</nav>\n)

      # Main content area
      s << %(<main class="dashboard-main">\n)

      # Stats row
      s << %(<div class="stats-row">\n)
      stats = [
        {"Users", "1,247", "+12%", true},
        {"Tasks", "342", "+5%", true},
        {"Uptime", "99.8%", "-0.1%", false},
        {"Revenue", "$12.4K", "+18%", true},
      ]
      stats.each do |label, value, trend, is_up|
        s << %(<div class="stat-card">\n)
        s << %(<div class="stat-label">#{label}</div>\n)
        s << %(<div class="stat-value">#{value}</div>\n)
        s << %(<div class="stat-trend #{is_up ? "stat-trend-up" : "stat-trend-down"}">#{trend} vs last month</div>\n)
        s << %(</div>\n)
      end
      s << %(</div>\n)

      # Data table
      s << %(<table class="data-table">\n)
      s << %(<thead><tr>\n)
      s << %(<th scope="col">Name</th>\n)
      s << %(<th scope="col">Status</th>\n)
      s << %(<th scope="col">Role</th>\n)
      s << %(<th scope="col">Date</th>\n)
      s << %(</tr></thead>\n)
      s << %(<tbody>\n)
      rows = [
        {"Alice Johnson", "Active", "badge-green", "Admin", "Today"},
        {"Bob Smith", "Pending", "badge-blue", "User", "Yesterday"},
        {"Carol Davis", "Active", "badge-green", "Editor", "2 days ago"},
        {"Dan Wilson", "Inactive", "badge-gray", "User", "1 week ago"},
        {"Eve Martinez", "Active", "badge-green", "Admin", "Today"},
      ]
      rows.each do |name, status, status_class, role, date|
        s << %(<tr>\n)
        s << %(<td style="font-weight: 500; color: light-dark(var(--color-gray-900), var(--color-white));">#{name}</td>\n)
        s << %(<td><span class="badge #{status_class}">#{status}</span></td>\n)
        s << %(<td>#{role}</td>\n)
        s << %(<td>#{date}</td>\n)
        s << %(</tr>\n)
      end
      s << %(</tbody>\n)
      s << %(</table>\n)

      s << %(</main>\n)
      s << %(</div>\n) # close .dashboard

      # Code callout
      s << %(<pre class="code-callout"><code>)
      s << %(<span class="comment"># This dashboard composes 8 element types:</span>\n)
      s << %(<span class="comment"># Nav, Aside, Main, Header, Table, Input.search,</span>\n)
      s << %(<span class="comment"># Button (popover trigger), Dialog</span>\n)
      s << %(<span class="comment"># Active sidebar state uses :has() — zero JavaScript</span>\n)
      s << %(\n)
      s << %(<span class="type">sidebar</span> = <span class="type">Elements::Nav</span>.<span class="method">new</span>(aria_label: <span class="string">"Dashboard"</span>)\n)
      s << %(<span class="type">table</span> = <span class="type">Elements::Table</span>.<span class="method">new</span> <span class="keyword">do</span> |t|\n)
      s << %(  t.<span class="method">thead</span> { [<span class="string">"Name"</span>, <span class="string">"Status"</span>, <span class="string">"Role"</span>].map { |h| <span class="type">Th</span>.<span class="method">scope</span>(<span class="string">"col"</span>, h) } }\n)
      s << %(  t.<span class="method">tbody</span> { users.map { |u| <span class="type">Tr</span>.<span class="method">new</span>(u.to_cells) } }\n)
      s << "<span class=\"keyword\">end</span></code></pre>\n"

      s << %(</section>\n)
    end
  end

  def self.shadows_section : String
    String.build do |s|
      s << %(<section class="section" id="shadows">\n)
      s << %(<p class="section-title">Shadows &amp; Borders</p>\n)
      s << %(<p class="section-desc">Elevation and border radius utility classes.</p>\n)

      # Shadows — shown on a light panel so the shadow effects are visible in both modes
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">Shadows</h3>\n)
      s << %(<div class="showcase-panel">\n)
      s << %(<div class="sample-row" style="margin-bottom: 0;">\n)
      %w[shadow-sm shadow shadow-md shadow-lg shadow-xl].each do |shadow|
        s << %(<div class="#{shadow} demo-surface" style="width: 6rem; height: 4rem; border-radius: 0.375rem; display: flex; align-items: center; justify-content: center;">\n)
        s << %(<span class="code">#{shadow}</span>\n)
        s << %(</div>\n)
      end
      s << %(</div>\n)
      s << %(</div>\n)

      # Border radius
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">Border Radius</h3>\n)
      s << %(<div class="sample-row">\n)
      [{"rounded-sm", "0.125rem"}, {"rounded", "0.25rem"}, {"rounded-md", "0.375rem"},
       {"rounded-lg", "0.5rem"}, {"rounded-xl", "0.75rem"}, {"rounded-full", "9999px"}].each do |name, val|
        s << %(<div style="width: 4rem; height: 4rem; background: var(--color-blue-500); border-radius: #{val}; display: flex; align-items: center; justify-content: center;">\n)
        s << %(<span style="font-size: 0.625rem; color: white;">#{name}</span>\n)
        s << %(</div>\n)
      end
      s << %(</div>\n)

      s << %(</section>\n)
    end
  end

  def self.accessibility_section : String
    String.build do |s|
      s << %(<section class="section" id="accessibility">\n)
      s << %(<p class="section-title">Accessibility</p>\n)
      s << %(<p class="section-desc">Every component above meets WCAG 2.2 AA. Here are the building blocks. Maps to <code>ClassBuilder.focus_visible()</code>, <code>ClassBuilder.aria_expanded()</code>, <code>ClassBuilder.motion_safe()</code>, and <code>sr-only</code> utility class.</p>\n)

      # --- Focus & Keyboard ---
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">Focus &amp; Keyboard Navigation</h3>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400)); margin-bottom: 0.75rem;">WCAG 2.4.7 — Focus Visible. Tab through these elements to verify focus rings.</p>\n)

      s << %(<div class="a11y-demo">\n)
      s << %(<p class="a11y-label">Interactive elements — press Tab to navigate</p>\n)
      s << %(<div style="display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: center;">\n)
      s << %(<button class="btn btn-primary">Button 1</button>\n)
      s << %(<button class="btn btn-secondary">Button 2</button>\n)
      s << %(<a href="#accessibility" style="text-decoration: underline;">A link</a>\n)
      s << %(<input class="form-control" style="width: 12rem;" type="text" placeholder="Text input">\n)
      s << %(<select class="form-control" style="width: 10rem;"><option>Select option</option></select>\n)
      s << %(<input type="checkbox" id="focus-check" style="width: 1.25rem; height: 1.25rem;"> <label for="focus-check">Checkbox</label>\n)
      s << %(</div>\n)
      s << %(<p style="margin-top: 0.75rem; font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400));">All elements show a visible focus ring on keyboard navigation via <code>:focus-visible</code>.</p>\n)
      s << %(</div>\n)

      s << %(<h4 style="font-size: 0.8125rem; font-weight: 600; margin-bottom: 0.5rem;">Ring Utilities</h4>\n)
      s << %(<div class="showcase-panel">\n)
      s << %(<div class="sample-row" style="margin-bottom: 0;">\n)
      %w[ring-0 ring-1 ring-2 ring ring-4].each do |ring|
        s << %(<div class="#{ring} demo-surface" style="width: 5rem; height: 3rem; border-radius: 0.375rem; display: flex; align-items: center; justify-content: center;">\n)
        s << %(<span class="code">#{ring}</span>\n)
        s << %(</div>\n)
      end
      s << %(</div>\n)
      s << %(</div>\n)

      # --- ARIA States ---
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">ARIA States</h3>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400)); margin-bottom: 0.75rem;">WCAG 1.3.1 — Info and Relationships. ARIA attribute selectors applied via variant prefixes.</p>\n)

      s << %(<div class="a11y-demo">\n)
      s << %(<p class="a11y-label">aria-expanded accordion demo</p>\n)
      s << %(<div style="margin-bottom: 0.5rem;">\n)
      s << %(<button class="btn btn-secondary" style="width: 100%; text-align: left;" aria-expanded="true" aria-controls="panel-1" onclick="this.setAttribute('aria-expanded', this.getAttribute('aria-expanded') === 'true' ? 'false' : 'true'); document.getElementById('panel-1').hidden = this.getAttribute('aria-expanded') === 'false';">\n)
      s << %(Section 1 <span style="float: right;">&#9660;</span></button>\n)
      s << %(<div id="panel-1" role="region" style="padding: 1rem; border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700)); border-top: 0; border-radius: 0 0 0.375rem 0.375rem;">\n)
      s << %(<p style="font-size: 0.875rem;">Panel content. The button uses <code>aria-expanded</code> to communicate state.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)
      s << %(<div>\n)
      s << %(<button class="btn btn-secondary" style="width: 100%; text-align: left;" aria-expanded="false" aria-controls="panel-2" onclick="this.setAttribute('aria-expanded', this.getAttribute('aria-expanded') === 'true' ? 'false' : 'true'); document.getElementById('panel-2').hidden = this.getAttribute('aria-expanded') === 'false';">\n)
      s << %(Section 2 <span style="float: right;">&#9660;</span></button>\n)
      s << %(<div id="panel-2" role="region" hidden style="padding: 1rem; border: 1px solid light-dark(var(--color-gray-200), var(--color-gray-700)); border-top: 0; border-radius: 0 0 0.375rem 0.375rem;">\n)
      s << %(<p style="font-size: 0.875rem;">Hidden panel — click Section 2 to reveal.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      s << %(<div class="a11y-demo">\n)
      s << %(<p class="a11y-label">aria-disabled demo</p>\n)
      s << %(<div class="sample-row">\n)
      s << %(<button class="btn btn-primary" aria-disabled="false">Enabled</button>\n)
      s << %(<button class="btn btn-primary" aria-disabled="true" style="opacity: 0.5; cursor: not-allowed;">Disabled (aria)</button>\n)
      s << %(</div>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400));">Using <code>aria-disabled="true"</code> keeps the button focusable for screen readers.</p>\n)
      s << %(</div>\n)

      # --- Reduced Motion ---
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">Reduced Motion</h3>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400)); margin-bottom: 0.75rem;">WCAG 2.2.2 / 2.3.1 — Global <code>prefers-reduced-motion: reduce</code> override in the base layer.</p>\n)

      s << %(<div class="a11y-demo">\n)
      s << %(<p class="a11y-label">Animation test</p>\n)
      s << %(<style>\n)
      s << %(@keyframes brand-kit-bounce { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-1rem); } }\n)
      s << %(.motion-demo { animation: brand-kit-bounce 1s infinite; width: 3rem; height: 3rem; background: var(--color-blue-500); border-radius: 9999px; }\n)
      s << %(</style>\n)
      s << %(<div class="motion-demo"></div>\n)
      s << %(<p style="margin-top: 0.75rem; font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400));">This circle bounces. Enable "Reduce motion" in your OS settings — the animation stops immediately.</p>\n)
      s << %(</div>\n)

      # --- Screen Reader ---
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">Screen Reader Utilities</h3>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400)); margin-bottom: 0.75rem;">WCAG 1.1.1 — The <code>sr-only</code> class visually hides content while keeping it accessible.</p>\n)

      s << %(<div class="a11y-demo">\n)
      s << %(<p class="a11y-label">sr-only demo</p>\n)
      s << %(<div class="sample-row">\n)
      s << %(<button class="btn btn-primary">\n)
      s << %(<span aria-hidden="true">&#10006;</span>\n)
      s << %(<span class="sr-only">Close dialog</span>\n)
      s << %(</button>\n)
      s << %(<button class="btn btn-secondary">\n)
      s << %(<span aria-hidden="true">&#9776;</span>\n)
      s << %(<span class="sr-only">Open menu</span>\n)
      s << %(</button>\n)
      s << %(<button class="btn btn-danger">\n)
      s << %(<span aria-hidden="true">&#128465;</span>\n)
      s << %(<span class="sr-only">Delete item</span>\n)
      s << %(</button>\n)
      s << %(</div>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400));">Icon-only buttons — screen readers announce "Close dialog", "Open menu", "Delete item".</p>\n)
      s << %(</div>\n)

      s << %(</section>\n)
    end
  end
  def self.modern_layout_section : String
    String.build do |s|
      s << %(<section class="section" id="modern-layout">\n)
      s << %(<p class="section-title">Modern Typography &amp; Layout</p>\n)
      s << %(<p class="section-desc">Native CSS features for balanced text, container queries, and logical properties — no JavaScript needed.</p>\n)

      # text-wrap: balance
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">text-wrap: balance</h3>\n)
      s << %(<div class="grid-2">\n)
      s << %(<div class="demo-box">\n)
      s << %(<p class="a11y-label">Default wrapping</p>\n)
      s << %(<h2 style="font-size: 1.5rem; font-weight: 700; line-height: 1.3;">This is a longer heading that demonstrates how default text wrapping can leave short orphan lines at the end</h2>\n)
      s << %(</div>\n)
      s << %(<div class="demo-box">\n)
      s << %(<p class="a11y-label">text-wrap: balance</p>\n)
      s << %(<h2 style="font-size: 1.5rem; font-weight: 700; line-height: 1.3; text-wrap: balance;">This is a longer heading that demonstrates how text-wrap balance distributes text evenly across lines</h2>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # text-wrap: pretty
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">text-wrap: pretty</h3>\n)
      s << %(<div class="grid-2">\n)
      s << %(<div class="demo-box">\n)
      s << %(<p class="a11y-label">Default paragraph</p>\n)
      s << %(<p style="font-size: 0.875rem; line-height: 1.6;">Asset Pipeline uses modern CSS features to create elegant, accessible web applications. The design system leverages native browser capabilities to reduce JavaScript complexity while maintaining a rich user experience across devices.</p>\n)
      s << %(</div>\n)
      s << %(<div class="demo-box">\n)
      s << %(<p class="a11y-label">text-wrap: pretty</p>\n)
      s << %(<p style="font-size: 0.875rem; line-height: 1.6; text-wrap: pretty;">Asset Pipeline uses modern CSS features to create elegant, accessible web applications. The design system leverages native browser capabilities to reduce JavaScript complexity while maintaining a rich user experience across devices.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # Container queries
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">Container Queries</h3>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400)); margin-bottom: 0.75rem;">Drag the right edge to resize. The card layout changes based on container width, not viewport width.</p>\n)
      s << %(<div class="container-demo">\n)
      s << %(<div class="cq-card">\n)
      s << %(<div style="width: 3rem; height: 3rem; border-radius: 9999px; background: var(--color-blue-500); flex-shrink: 0;"></div>\n)
      s << %(<div>\n)
      s << %(<p style="font-weight: 600; margin-bottom: 0.25rem;">Container-Aware Card</p>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400));">This card uses <code>@container</code> to switch from stacked to horizontal layout at 24rem. Resize the dashed container to see the change.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # Logical properties
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">Logical Properties</h3>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400)); margin-bottom: 0.75rem;">Spacing and alignment that adapts to writing direction (LTR/RTL).</p>\n)
      s << %(<div class="grid-2">\n)
      s << %(<div class="demo-box" dir="ltr">\n)
      s << %(<p class="a11y-label">LTR (dir="ltr")</p>\n)
      s << %(<div style="margin-inline-start: 2rem; padding-inline-start: 1rem; border-inline-start: 3px solid var(--color-blue-500);">\n)
      s << %(<p style="font-size: 0.875rem;">This text uses <code>margin-inline-start</code>, <code>padding-inline-start</code>, and <code>border-inline-start</code>. In LTR, "start" means left.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)
      s << %(<div class="demo-box" dir="rtl">\n)
      s << %(<p class="a11y-label">RTL (dir="rtl")</p>\n)
      s << %(<div style="margin-inline-start: 2rem; padding-inline-start: 1rem; border-inline-start: 3px solid var(--color-blue-500);">\n)
      s << %(<p style="font-size: 0.875rem;">Same properties — but in RTL, "start" flips to the right side automatically. No separate stylesheets needed.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      s << %(</section>\n)
    end
  end

  def self.dialog_popover_section : String
    String.build do |s|
      s << %(<section class="section" id="dialog-popover">\n)
      s << %(<p class="section-title">Dialog &amp; Popover</p>\n)
      s << %(<p class="section-desc">Native HTML elements for modals, popovers, and accordions — minimal or zero JavaScript required.</p>\n)

      # Dialog modal
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">&lt;dialog&gt; Modal</h3>\n)
      s << %(<div class="sample-row">\n)
      s << %(<button class="btn btn-primary" onclick="document.getElementById('demo-dialog').showModal()">Open Modal</button>\n)
      s << %(<button class="btn btn-secondary" onclick="document.getElementById('demo-dialog-sm').showModal()">Open Small Dialog</button>\n)
      s << %(</div>\n)
      s << %(<dialog id="demo-dialog" class="demo-dialog">\n)
      s << %(<h3>Modal Dialog</h3>\n)
      s << %(<p>This is a native <code>&lt;dialog&gt;</code> element opened with <code>showModal()</code>. It traps focus automatically, dims the page with <code>::backdrop</code>, and closes on Escape.</p>\n)
      s << %(<div style="display: flex; gap: 0.5rem; justify-content: flex-end;">\n)
      s << %(<button class="btn btn-secondary" onclick="this.closest('dialog').close()">Cancel</button>\n)
      s << %(<button class="btn btn-primary" onclick="this.closest('dialog').close()">Confirm</button>\n)
      s << %(</div>\n)
      s << %(</dialog>\n)
      s << %(<dialog id="demo-dialog-sm" class="demo-dialog" style="max-width: 20rem; padding: 1.5rem;">\n)
      s << %(<h3 style="font-size: 1rem;">Confirmation</h3>\n)
      s << %(<p>Are you sure you want to proceed?</p>\n)
      s << %(<div style="display: flex; gap: 0.5rem; justify-content: flex-end;">\n)
      s << %(<button class="btn btn-secondary btn-sm" onclick="this.closest('dialog').close()">No</button>\n)
      s << %(<button class="btn btn-danger btn-sm" onclick="this.closest('dialog').close()">Yes, Delete</button>\n)
      s << %(</div>\n)
      s << %(</dialog>\n)

      # Popover API
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">Popover API</h3>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400)); margin-bottom: 0.75rem;">Uses <code>popovertarget</code> — no JavaScript event listeners needed. Click outside or press Escape to dismiss.</p>\n)
      s << %(<div class="sample-row">\n)
      # Tooltip-style popover
      s << %(<button class="btn btn-secondary" popovertarget="tooltip-pop">Show Tooltip</button>\n)
      s << %(<div id="tooltip-pop" popover class="popover-demo tooltip-style">This is a tooltip-style popover. It appears on click and dismisses on outside click or Escape.</div>\n)
      # Menu-style popover
      s << %(<button class="btn btn-secondary" popovertarget="menu-pop">Show Menu</button>\n)
      s << %(<div id="menu-pop" popover class="popover-menu">\n)
      s << %(<button class="popover-menu-item" onclick="this.closest('[popover]').hidePopover()">&#x270F;&#xFE0F; Edit</button>\n)
      s << %(<button class="popover-menu-item" onclick="this.closest('[popover]').hidePopover()">&#x1F4CB; Duplicate</button>\n)
      s << %(<button class="popover-menu-item" onclick="this.closest('[popover]').hidePopover()">&#x1F4E6; Archive</button>\n)
      s << %(<button class="popover-menu-item" style="color: var(--color-red-500);" onclick="this.closest('[popover]').hidePopover()">&#x1F5D1;&#xFE0F; Delete</button>\n)
      s << %(</div>\n)
      # Info popover
      s << %(<button class="btn btn-primary" popovertarget="info-pop">Info Panel</button>\n)
      s << %(<div id="info-pop" popover class="popover-demo">\n)
      s << %(<p style="font-weight: 600; margin-bottom: 0.5rem;">About Popovers</p>\n)
      s << %(<p style="color: light-dark(var(--color-gray-600), var(--color-gray-300)); line-height: 1.5;">The Popover API provides a declarative way to create floating UI elements. Unlike tooltips built with CSS <code>:hover</code>, popovers are accessible and work with keyboard navigation.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # Details/Summary accordion
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">&lt;details&gt; / &lt;summary&gt; Accordion</h3>\n)
      [{"What is this brand kit?", "This brand kit is a generated showcase for Asset Pipeline design tokens, CSS output, component styling, and WCAG 2.2 AA-oriented accessibility conventions."},
       {"Why no JavaScript frameworks?", "The design-system direction uses native HTML/CSS features and focused vanilla JavaScript helpers instead of heavy JavaScript frameworks. Features like <code>&lt;dialog&gt;</code>, the Popover API, and <code>&lt;details&gt;</code> provide rich interactivity natively."},
       {"How does the adapter pattern work?", "Sessions, pub/sub, background jobs, and the mailer all use an adapter pattern. This means you can swap backends (e.g., memory vs Redis) without changing application code. Memory adapters are included by default."}].each do |title, content|
        s << %(<details class="details-styled">\n)
        s << %(<summary>#{title}</summary>\n)
        s << %(<div class="details-body">#{content}</div>\n)
        s << %(</details>\n)
      end

      s << %(</section>\n)
    end
  end

  def self.transitions_section : String
    String.build do |s|
      s << %(<section class="section" id="transitions">\n)
      s << %(<p class="section-title">Transitions &amp; Animation</p>\n)
      s << %(<p class="section-desc">Modern CSS transitions including <code>@starting-style</code>, <code>interpolate-size</code>, and hover utilities.</p>\n)

      # @starting-style
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin-bottom: 0.75rem;">@starting-style (Entry Animation)</h3>\n)
      s << %(<div class="demo-box">\n)
      s << %(<div class="fade-in-demo" style="padding: 1rem; background: light-dark(var(--color-blue-50), var(--color-blue-900)); border-radius: 0.375rem; border: 1px solid light-dark(var(--color-blue-200), var(--color-blue-700));">\n)
      s << %(<p style="font-weight: 500; color: light-dark(var(--color-blue-700), var(--color-blue-200));">This element faded in on page load</p>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-blue-500), var(--color-blue-300)); margin-top: 0.25rem;">Uses <code>@starting-style</code> — the browser transitions from the starting values (opacity: 0, translateY) to the final state. No keyframe animation needed.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # interpolate-size: allow-keywords
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">interpolate-size: allow-keywords (Height Auto Animation)</h3>\n)
      s << %(<div class="demo-box expand-demo">\n)
      s << %(<input type="checkbox" id="expand-check" class="expand-trigger" style="width: 1.125rem; height: 1.125rem; accent-color: var(--color-blue-500);">\n)
      s << %(<label for="expand-check" style="display: inline-flex; align-items: center; gap: 0.5rem; cursor: pointer; font-size: 0.875rem; font-weight: 500; margin-bottom: 0.75rem; vertical-align: middle; margin-left: 0.5rem;">\n)
      s << %(Toggle content\n)
      s << %(</label>\n)
      s << %(<div class="expand-content">\n)
      s << %(<div style="padding: 1rem; background: light-dark(var(--color-green-50), var(--color-green-900)); border-radius: 0.375rem; border: 1px solid light-dark(var(--color-green-200), var(--color-green-700));">\n)
      s << %(<p style="font-weight: 500; color: light-dark(var(--color-green-700), var(--color-green-200));">Smoothly animated height</p>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-green-500), var(--color-green-300)); margin-top: 0.25rem;">This section transitions from <code>height: 0</code> to <code>height: auto</code> using <code>interpolate-size: allow-keywords</code>. Previously this required JavaScript to measure and set explicit pixel heights.</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # prefers-reduced-motion
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">prefers-reduced-motion</h3>\n)
      s << %(<div class="demo-box">\n)
      s << %(<p style="font-size: 0.875rem; margin-bottom: 0.75rem;">The CSS engine's base layer includes a global <code>prefers-reduced-motion: reduce</code> override that removes all animations and transitions for users who prefer reduced motion. The utility classes <code>motion-reduce:*</code> and <code>motion-safe:*</code> provide fine-grained control.</p>\n)
      s << %(<div style="display: flex; flex-wrap: wrap; gap: 0.5rem;">\n)
      s << %(<span class="code">motion-reduce:transition</span>\n)
      s << %(<span class="code">motion-safe:transition-transform</span>\n)
      s << %(<span class="code">@media (prefers-reduced-motion: reduce)</span>\n)
      s << %(</div>\n)
      s << %(</div>\n)

      # Transition hover utilities
      s << %(<h3 style="font-size: 0.875rem; font-weight: 600; margin: 1.5rem 0 0.75rem;">Hover Transition Utilities</h3>\n)
      s << %(<div class="sample-row">\n)
      s << %(<div class="hover-grow demo-surface" style="padding: 1rem 1.5rem; border-radius: 0.375rem; text-align: center; cursor: pointer;">\n)
      s << %(<p style="font-weight: 500;">Scale</p>\n)
      s << %(<p style="font-size: 0.75rem;" class="code">hover → scale(1.05)</p>\n)
      s << %(</div>\n)
      s << %(<div class="hover-lift demo-surface" style="padding: 1rem 1.5rem; border-radius: 0.375rem; text-align: center; cursor: pointer;">\n)
      s << %(<p style="font-weight: 500;">Lift</p>\n)
      s << %(<p style="font-size: 0.75rem;" class="code">hover → translateY(-2px)</p>\n)
      s << %(</div>\n)
      s << %(<div class="hover-color" style="text-align: center;">\n)
      s << %(<p style="font-weight: 500;">Color</p>\n)
      s << %(<p style="font-size: 0.75rem;">hover → bg-blue-500</p>\n)
      s << %(</div>\n)
      s << %(</div>\n)
      s << %(<p style="font-size: 0.75rem; color: light-dark(var(--color-gray-500), var(--color-gray-400));">All transitions use <code>transition</code>, <code>transition-colors</code>, or <code>transition-transform</code> utility classes from the engine. They automatically respect <code>prefers-reduced-motion</code>.</p>\n)

      s << %(</section>\n)
    end
  end

  def self.scroll_animations_section : String
    String.build do |s|
      s << %(<section class="section" id="scroll-animations">\n)
      s << %(<p class="section-title">Scroll-Driven Animations</p>\n)
      s << %(<p class="section-desc">Cards fade in as they scroll into view using <code>animation-timeline: view()</code>. No JavaScript intersection observers needed. Uses <code>@keyframes</code> with <code>animation-range: entry</code>.</p>\n)

      s << %(<div class="parallax-band" aria-hidden="true">Scroll to reveal</div>\n)

      s << %(<div class="scroll-card-grid">\n)
      cards = [
        {"View Timeline", "Elements animate relative to their position in the scrollport. The browser handles all timing."},
        {"Scroll Timeline", "The progress bar at the top uses <code>animation-timeline: scroll()</code> to track page scroll position."},
        {"Entry Range", "The <code>animation-range: entry</code> shorthand triggers animation as elements enter the viewport."},
        {"Zero JavaScript", "No IntersectionObserver, no scroll event listeners, no requestAnimationFrame. Pure CSS."},
      ]
      cards.each do |title, desc|
        s << %(<div class="scroll-card scroll-reveal">\n)
        s << %(<h4>#{title}</h4>\n)
        s << %(<p>#{desc}</p>\n)
        s << %(</div>\n)
      end
      s << %(</div>\n)

      s << %(<pre class="code-callout scroll-reveal" style="margin-top: 1.25rem;"><code>)
      s << %(<span class="comment">/* Scroll-driven fade-in — no JS needed */</span>\n)
      s << %(<span class="keyword">.scroll-reveal</span> {\n)
      s << %(  opacity: <span class="string">0</span>;\n)
      s << %(  transform: <span class="method">translateY</span>(<span class="string">2rem</span>) <span class="method">scale</span>(<span class="string">0.95</span>);\n)
      s << %(  animation: fade-in-view linear forwards;\n)
      s << %(  animation-timeline: <span class="method">view</span>();\n)
      s << %(  animation-range: cover <span class="string">0%</span> cover <span class="string">40%</span>;\n)
      s << "}</code></pre>\n"

      s << %(</section>\n)
    end
  end

  def self.token_reference_section : String
    config = Components::CSS::Config.new
    String.build do |s|
      s << %(<section class="section" id="token-reference">\n)
      s << %(<p class="section-title">Design Token Reference</p>\n)
      s << %(<p class="section-desc">Raw design token values from the CSS engine configuration. Collapsed by default — expand to inspect.</p>\n)

      # Spacing scale
      s << %(<details class="details-styled">\n)
      s << %(<summary>Spacing Scale</summary>\n)
      s << %(<div class="details-body">\n)
      s << %(<table class="token-table">\n)
      s << %(<thead><tr><th>Token</th><th>Value</th><th>CSS Variable</th></tr></thead>\n)
      s << %(<tbody>\n)
      %w[0 1 2 3 4 5 6 8 10 12 16 20 24 32 40 48 64].each do |key|
        if value = config.spacing[key]?
          s << %(<tr><td>#{key}</td><td>#{value}</td><td>--spacing-#{key}</td></tr>\n)
        end
      end
      s << %(</tbody></table>\n)
      s << %(</div>\n)
      s << %(</details>\n)

      # Color tokens
      s << %(<details class="details-styled">\n)
      s << %(<summary>Color Tokens</summary>\n)
      s << %(<div class="details-body">\n)
      s << %(<table class="token-table">\n)
      s << %(<thead><tr><th>Swatch</th><th>Token</th><th>Value</th><th>CSS Variable</th></tr></thead>\n)
      s << %(<tbody>\n)
      config.colors.each do |name, value|
        case value
        when Hash
          value.each do |shade, color|
            s << %(<tr><td><div style="width: 1.5rem; height: 1rem; border-radius: 0.125rem; background: #{color}; border: 1px solid oklch(0 0 0 / 0.1);"></div></td><td>#{name}-#{shade}</td><td style="font-size: 0.6875rem;">#{color}</td><td>--color-#{name}-#{shade}</td></tr>\n)
          end
        when String
          next if name == "transparent" || name == "current"
          s << %(<tr><td><div style="width: 1.5rem; height: 1rem; border-radius: 0.125rem; background: #{value}; border: 1px solid oklch(0 0 0 / 0.1);"></div></td><td>#{name}</td><td>#{value}</td><td>--color-#{name}</td></tr>\n)
        end
      end
      s << %(</tbody></table>\n)
      s << %(</div>\n)
      s << %(</details>\n)

      # Shadow tokens
      s << %(<details class="details-styled">\n)
      s << %(<summary>Shadow Values</summary>\n)
      s << %(<div class="details-body">\n)
      s << %(<table class="token-table">\n)
      s << %(<thead><tr><th>Utility</th><th>Value</th></tr></thead>\n)
      s << %(<tbody>\n)
      config.shadows.each do |name, value|
        s << %(<tr><td>shadow-#{name}</td><td style="font-size: 0.6875rem;">#{value}</td></tr>\n)
      end
      s << %(</tbody></table>\n)
      s << %(</div>\n)
      s << %(</details>\n)

      s << %(</section>\n)
    end
  end

end

# === Main ===
output = BrandKit.generate_html
output_path = File.join(Dir.current, "output", "brand-kit.html")

# Ensure output directory exists
Dir.mkdir_p(File.dirname(output_path))

File.write(output_path, output)
puts "Brand kit generated: #{output_path}"
puts "Open in browser to validate styling and accessibility."
