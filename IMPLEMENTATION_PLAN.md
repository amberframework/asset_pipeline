# Enhanced Import Map Script Generation - Implementation Plan

## Project Overview
Improve AssetPipeline import map usage by adding automatic script generation capabilities with separate modules for general JavaScript and Stimulus-specific functionality.

## Goals
1. Automatically generate import statements for local controllers/modules
2. Parse custom JavaScript blocks to detect dependencies
3. Separate general JavaScript support from Stimulus-specific functionality
4. Provide complete rendered script tags with proper initialization
5. Maintain backwards compatibility with existing FrontLoader functionality

---

## Phase 1: Analysis and Design Foundation
**Status**: ✅ Completed  
**Goal**: Establish separate modules for general script rendering and Stimulus-specific functionality

### Tasks:
- [x] 1.1 Create general `ScriptRenderer` class in `AssetPipeline` module
  - [x] Basic JavaScript initialization block handling
  - [x] General import statement generation  
  - [x] Framework-agnostic script rendering
- [x] 1.2 Create dedicated `AssetPipeline::Stimulus` module
  - [x] `StimulusRenderer` class structure
  - [x] Stimulus controller detection patterns
  - [x] Stimulus-specific import and registration generation
- [x] 1.3 Add framework-agnostic script rendering to `FrontLoader`
  - [x] General `render_initialization_script` method
  - [x] Stimulus-specific `render_stimulus_initialization_script` method
  - [x] Maintain clear separation between general and framework-specific functionality

---

## Phase 2: General Script Generation Engine  
**Status**: ✅ Completed  
**Goal**: Build the framework-agnostic script generation functionality

### Tasks:
- [x] 2.1 Implement general `ScriptRenderer` class
  - [x] Handle custom JavaScript initialization blocks
  - [x] Generate basic import statements for detected dependencies
  - [x] Provide foundation for framework-specific renderers
- [x] 2.2 Create automatic import detection
  - [x] Local JavaScript files referenced in import maps
  - [x] External library dependencies
  - [x] Framework-agnostic patterns
- [x] 2.3 Build base script template system
  - [x] Wrap content in `<script type="module">` tags
  - [x] Handle basic import/initialization structure
  - [x] Provide extension points for framework-specific logic

---

## Phase 3: Stimulus-Specific Implementation
**Status**: ✅ Completed  
**Goal**: Build dedicated Stimulus support as a separate module

### Tasks:
- [x] 3.1 Implement `AssetPipeline::Stimulus::StimulusRenderer`
  - [x] Detect `Stimulus.register("name", ControllerClass)` patterns
  - [x] Identify `import ControllerName from "controller_name"` patterns
  - [x] Handle `Application.start()` initialization
- [x] 3.2 Create Stimulus-specific parsing logic
  - [x] Controller class references in initialization blocks
  - [x] Stimulus-specific import patterns
  - [x] Application setup and configuration
- [x] 3.3 Build Stimulus script template
  - [x] Include proper Stimulus imports (`@hotwired/stimulus`)
  - [x] Generate controller imports automatically
  - [x] Handle Stimulus application startup
  - [x] Integrate custom initialization code

---

## Phase 4: Integration and API Enhancement
**Status**: ✅ Completed  
**Goal**: Integrate both general and Stimulus-specific functionality into `FrontLoader`

### Tasks:
- [x] 4.1 Extend `FrontLoader` with framework-aware methods
  - [x] `render_initialization_script(custom_js_block, import_map_name)` method
  - [x] `render_stimulus_initialization_script(custom_js_block, import_map_name)` method
  - [x] `render_initialization_script_with_analysis` method with dependency warnings
  - [x] Proper method signatures and parameter handling
- [x] 4.2 Enhance import map integration
  - [x] Add metadata support to distinguish controller files from general JavaScript
  - [x] Create helper methods to categorize imports by type and framework
  - [x] Support framework-specific filtering (`imports_by_framework`, `stimulus_controller_imports`)
  - [x] Auto-categorization based on naming patterns
- [x] 4.3 Implement extensible architecture
  - [x] FrameworkRegistry for future framework modules (Alpine.js, Vue, etc.)
  - [x] Factory pattern for creating framework-specific renderers
  - [x] Clean separation of concerns with base FrameworkRenderer class
  - [x] Consistent APIs across framework modules

---

## Phase 5: Testing and Validation
**Status**: ✅ Completed  
**Goal**: Test both general and Stimulus-specific functionality

### Tasks:
- [x] 5.1 Create comprehensive test suites
  - [x] ✅ General `ScriptRenderer` functionality tests (183 lines in script_renderer_spec.cr + 295 lines in enhanced_script_renderer_spec.cr)
  - [x] ✅ Stimulus-specific `StimulusRenderer` functionality tests (294 lines with 18 passing tests in stimulus_renderer_spec.cr)
  - [x] ✅ Integration with existing import map system tests (214 lines in front_loader_script_integration_spec.cr + 352 lines in enhanced_front_loader_spec.cr)
  - [x] ✅ Edge cases and error handling tests (comprehensive coverage including malformed JS, empty imports, invalid scopes, cache behaviors)
- [x] 5.2 Add framework-specific examples
  - [x] ✅ General JavaScript initialization examples (phase5_general_javascript_initialization_example.cr)
  - [x] ✅ Stimulus controller auto-detection and setup examples (phase5_stimulus_controller_examples.cr)
  - [x] ✅ Mixed scenarios with both general and Stimulus code (phase5_mixed_scenarios_example.cr)
  - [x] ✅ Update existing examples to demonstrate new functionality (enhanced script_generation_example.cr)
- [x] 5.3 Validate backwards compatibility
  - [x] ✅ Ensure existing `FrontLoader` functionality remains unchanged (backwards_compatibility_validation.cr - 0 compatibility issues)
  - [x] ✅ Verify current import map behavior is preserved (import_map_behavior_verification.cr - 100% compatibility)
  - [x] ✅ Test migration scenarios from manual script blocks (migration_scenarios.cr - 5 comprehensive scenarios)

---

## Phase 6: Documentation and Polish
**Status**: 🔲 Not Started  
**Goal**: Provide clear documentation and usage examples

### Tasks:
- [ ] 6.1 Update documentation
  - [ ] API reference for new methods
  - [ ] Usage examples and common patterns
  - [ ] Migration guide from manual script blocks
  - [ ] Framework-specific documentation sections
- [ ] 6.2 Create practical examples
  - [ ] Simple single-controller setups
  - [ ] Complex multi-controller applications
  - [ ] Integration with different view templates
  - [ ] Real-world usage scenarios
- [ ] 6.3 Performance optimization
  - [ ] Caching of controller detection results
  - [ ] Efficient script generation
  - [ ] Minimal overhead for existing functionality
  - [ ] Benchmark performance impact

---

## Technical Architecture

### New File Structure:
```
src/asset_pipeline/
├── script_renderer.cr          # General JavaScript script rendering
└── stimulus/
    └── stimulus_renderer.cr    # Stimulus-specific functionality
```

### Key Classes:
- `AssetPipeline::ScriptRenderer` - General script rendering
- `AssetPipeline::Stimulus::StimulusRenderer` - Stimulus-specific rendering
- Enhanced `AssetPipeline::FrontLoader` - Integration point

### API Surface:
```crystal
# General JavaScript support
front_loader.render_initialization_script(custom_js_block, import_map_name)

# Stimulus-specific support  
front_loader.render_stimulus_initialization_script(custom_js_block, import_map_name)
```

---

## Progress Legend:
- 🔲 Not Started
- 🔄 In Progress  
- ✅ Completed
- ❌ Blocked
- ⚠️ Needs Review

## Notes:
- Maintain backwards compatibility throughout all phases
- Test each phase thoroughly before proceeding to the next
- Keep general and Stimulus functionality clearly separated
- Ensure extensible architecture for future framework additions 