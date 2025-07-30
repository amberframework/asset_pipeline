# Crystal Component System - CSS & Asset Pipeline Plan

## Overview

This plan outlines the implementation of a comprehensive CSS system and asset pipeline for the Crystal Component System. The goal is to create a utility-first CSS framework similar to Tailwind v4, along with complete static asset management.

## Phase 1: Asset Pipeline Foundation

### 1.1 Core Asset Classes
- `Asset` - Base class for all assets
- `CSSAsset` - CSS file handling
- `JSAsset` - JavaScript file handling  
- `ImageAsset` - Image optimization and handling
- `MediaAsset` - Video/audio file handling
- `FontAsset` - Web font handling
- `StaticAsset` - Generic static file handling

### 1.2 Asset Manager
- Asset discovery and registration
- Dependency resolution
- Build pipeline coordination
- File watching for development
- Manifest generation

### 1.3 Asset Processing
- Fingerprinting for cache busting
- Compression (gzip, brotli)
- Source maps
- Development vs production modes

## Phase 2: Utility-First CSS System

### 2.1 Core CSS Engine
- CSS parser and generator
- Utility class generation
- Custom property (CSS variable) support
- Media query system
- Container query support

### 2.2 Utility Classes (Tailwind-like)
- **Layout**: flex, grid, container, columns
- **Spacing**: margin, padding (m-*, p-*)
- **Sizing**: width, height, min/max variants
- **Typography**: font families, sizes, weights, line heights
- **Colors**: text, background, border colors with opacity
- **Borders**: width, style, radius, divide
- **Effects**: shadows, opacity, transforms, transitions
- **Filters**: blur, brightness, contrast, etc.
- **Interactivity**: hover, focus, active states
- **Responsive**: breakpoint prefixes (sm:, md:, lg:, xl:, 2xl:)
- **Dark mode**: dark: prefix support
- **Arbitrary values**: Support for [arbitrary-value] syntax

### 2.3 Configuration System
```crystal
module Components
  class CSSConfig
    property colors : Hash(String, String | Hash(String, String))
    property spacing : Hash(String, String)
    property fonts : Hash(String, String)
    property screens : Hash(String, String)
    property extend : Hash(String, Hash(String, String))
    
    def self.default
      new(
        colors: {
          "primary" => {"50" => "#eff6ff", "500" => "#3b82f6", "900" => "#1e3a8a"},
          "gray" => {"50" => "#f9fafb", "500" => "#6b7280", "900" => "#111827"}
        },
        spacing: {
          "px" => "1px",
          "0" => "0",
          "1" => "0.25rem",
          "2" => "0.5rem",
          # ... up to 96
        },
        screens: {
          "sm" => "640px",
          "md" => "768px",
          "lg" => "1024px",
          "xl" => "1280px",
          "2xl" => "1536px"
        }
      )
    end
  end
end
```

### 2.4 CSS Generation Strategy
- Just-In-Time (JIT) compilation - only generate used classes
- Scan Crystal source files for class names
- Tree-shaking unused styles
- Layer system (@layer base, components, utilities)

## Phase 3: Component Integration

### 3.1 Utility Class Usage in Components
```crystal
Components::Elements::Button.new(
  class: "px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 
          focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2
          disabled:opacity-50 disabled:cursor-not-allowed
          dark:bg-blue-600 dark:hover:bg-blue-700"
)
```

### 3.2 Component Styles API
```crystal
class ButtonComponent < Components::StatelessComponent
  # Define component-specific styles
  register_styles do
    # Base component styles
    component ".btn" do
      apply "inline-flex items-center justify-center font-medium 
             rounded-md transition-colors focus:outline-none"
    end
    
    # Variants
    variant ".btn-primary" do
      apply "bg-blue-500 text-white hover:bg-blue-600"
    end
    
    # Sizes
    size :sm, "px-3 py-1.5 text-sm"
    size :md, "px-4 py-2 text-base"
    size :lg, "px-6 py-3 text-lg"
  end
end
```

### 3.3 CSS-in-Crystal
```crystal
class StyledComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Div.new(
      class: css {
        base "rounded-lg shadow-md p-4"
        
        # Conditional classes
        add "bg-red-50 border-red-200" if error?
        add "bg-green-50 border-green-200" if success?
        
        # Responsive
        responsive do
          sm "p-6"
          md "p-8"
          lg "flex items-center"
        end
        
        # States
        hover "shadow-lg transform -translate-y-1"
        dark "bg-gray-800 text-gray-100"
      }
    )
  end
end
```

## Phase 4: Asset Serving & Optimization

### 4.1 Development Server
- Hot module replacement for CSS
- Live reload
- Source maps
- Error overlay

### 4.2 Production Build
- CSS minification
- PurgeCSS integration
- Critical CSS extraction
- Compression
- CDN-ready output

### 4.3 Image Optimization
- Automatic format conversion (WebP, AVIF)
- Responsive image generation
- Lazy loading support
- Blur placeholders

## Phase 5: Advanced Features

### 5.1 CSS Features
- CSS Grid utilities
- Custom animations
- Scroll snap utilities
- Aspect ratio utilities
- Backdrop utilities
- CSS logical properties

### 5.2 Performance
- CSS splitting by route
- Async CSS loading
- Resource hints (preload, prefetch)
- Service worker integration

### 5.3 Developer Experience
- VS Code extension for class name autocomplete
- Build performance metrics
- Bundle size analyzer
- Unused CSS reporter

## Implementation Order

1. **Week 1-2**: Asset Pipeline Foundation
   - Basic asset classes
   - File watching
   - Simple bundling

2. **Week 3-4**: CSS Engine Core
   - CSS parser
   - Utility generator
   - Configuration system

3. **Week 5-6**: Utility Classes
   - Implement all utility categories
   - Responsive system
   - Dark mode support

4. **Week 7-8**: Component Integration
   - Component styles API
   - CSS-in-Crystal helpers
   - Documentation

5. **Week 9-10**: Optimization & Polish
   - Production optimizations
   - Performance tuning
   - Testing & documentation

## Technical Decisions

1. **CSS Architecture**: Atomic CSS with utility-first approach
2. **Build Tool**: Native Crystal implementation (no Node.js dependency)
3. **File Format**: Support both .css files and Crystal-defined styles
4. **Caching**: Aggressive caching with content-based hashes
5. **Compatibility**: Modern browsers with CSS custom properties

## Success Criteria

1. Generate <50KB of CSS for typical application
2. Sub-second rebuild times in development
3. Zero runtime CSS generation overhead
4. 100% type-safe class name usage
5. Seamless integration with existing component system

## Next Steps

1. Create `src/components/assets/` directory structure
2. Implement basic Asset and AssetManager classes
3. Create CSS parser and generator
4. Build utility class system
5. Integrate with component system