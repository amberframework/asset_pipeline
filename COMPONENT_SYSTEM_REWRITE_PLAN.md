# Component System Complete Rewrite Plan

## Overview
Since the existing component system was only an alpha implementation, we will completely remove it and build the new system from scratch according to the specifications.

## Files to Delete

### Component Files
```
src/asset_pipeline/components/
  base/
    component.cr                    # DELETE - Generic approach
    stateful_component.cr          # DELETE - Wrong architecture
    stateless_component.cr         # DELETE - Wrong architecture
  
  html/
    html_element.cr               # DELETE - Generic element class
    html_helpers.cr               # DELETE - Helper methods approach
  
  cache/
    cache_config.cr               # DELETE - Will reimplement
    cache_store.cr                # DELETE - Will reimplement
    cacheable.cr                  # DELETE - Will reimplement
    component_cache_manager.cr    # DELETE - Will reimplement
    test_cache_store.cr           # DELETE - Will reimplement
  
  javascript/
    component_manager.js          # DELETE - Not reactive
    component_registry.js         # DELETE - Not reactive
    component_system.js           # DELETE - Not reactive
    stateful_component_js.js      # DELETE - Not reactive
    dom_utilities.js              # DELETE - Not reactive
    examples/                     # DELETE ALL - Wrong approach
  
  examples/
    button.cr                     # DELETE - Will reimplement
    counter.cr                    # DELETE - Will reimplement
  
  css_registry.cr                 # DELETE - Will reimplement if needed
  
  asset_pipeline/
    component_asset_generator.cr  # DELETE - Wrong approach
    component_asset_handler.cr    # DELETE - Wrong approach
    css_optimizer.cr              # DELETE - May reimplement differently
    front_loader_extensions.cr    # DELETE - Wrong approach
```

### Integration Files
```
src/asset_pipeline/
  components.cr                   # DELETE - Main component module
  stimulus/
    stimulus_renderer.cr          # KEEP - May be useful for Stimulus integration
```

## New File Structure

```
src/
  components/
    # Phase 1: HTML Elements (MUST BE FIRST)
    elements/
      base/
        html_element.cr          # Abstract base for all elements
        void_element.cr          # Base for self-closing elements
        container_element.cr     # Base for container elements
        
      document/
        html.cr                  # Html class
        head.cr                  # Head class
        body.cr                  # Body class
        title.cr                 # Title class
        meta.cr                  # Meta class
        link.cr                  # Link class
        style.cr                 # Style class
        script.cr                # Script class
        
      sections/
        header.cr                # Header class
        footer.cr                # Footer class
        nav.cr                   # Nav class
        main.cr                  # Main class
        section.cr               # Section class
        article.cr               # Article class
        aside.cr                 # Aside class
        h1.cr through h6.cr      # Heading classes
        
      grouping/
        div.cr                   # Div class
        p.cr                     # P class
        span.cr                  # Span class
        pre.cr                   # Pre class
        blockquote.cr            # Blockquote class
        ol.cr                    # Ol class
        ul.cr                    # Ul class
        li.cr                    # Li class
        dl.cr                    # Dl class
        dt.cr                    # Dt class
        dd.cr                    # Dd class
        
      text/
        a.cr                     # A class
        em.cr                    # Em class
        strong.cr                # Strong class
        small.cr                 # Small class
        cite.cr                  # Cite class
        code.cr                  # Code class
        kbd.cr                   # Kbd class
        var.cr                   # Var class
        samp.cr                  # Samp class
        sub.cr                   # Sub class
        sup.cr                   # Sup class
        
      embedded/
        img.cr                   # Img class
        iframe.cr                # Iframe class
        embed.cr                 # Embed class
        object.cr                # Object class
        video.cr                 # Video class
        audio.cr                 # Audio class
        canvas.cr                # Canvas class
        svg.cr                   # Svg class
        
      tables/
        table.cr                 # Table class
        thead.cr                 # Thead class
        tbody.cr                 # Tbody class
        tfoot.cr                 # Tfoot class
        tr.cr                    # Tr class
        th.cr                    # Th class
        td.cr                    # Td class
        caption.cr               # Caption class
        
      forms/
        form.cr                  # Form class
        input.cr                 # Input class
        textarea.cr              # Textarea class
        select.cr                # Select class
        option.cr                # Option class
        button.cr                # Button class
        label.cr                 # Label class
        fieldset.cr              # Fieldset class
        legend.cr                # Legend class
        
      interactive/
        details.cr               # Details class
        summary.cr               # Summary class
        dialog.cr                # Dialog class
        menu.cr                  # Menu class
        
      void/
        br.cr                    # Br class
        hr.cr                    # Hr class
        area.cr                  # Area class
        base.cr                  # Base class
        col.cr                   # Col class
        source.cr                # Source class
        track.cr                 # Track class
        wbr.cr                   # Wbr class
        param.cr                 # Param class
        
    # Phase 2: Component System
    base/
      component.cr               # NEW - Base component class
      stateless_component.cr     # NEW - Stateless components
      stateful_component.cr      # NEW - Stateful components
      
    # Phase 3: Caching
    cache/
      cache_store.cr             # NEW - Abstract cache store
      memory_cache_store.cr      # NEW - Memory implementation
      redis_cache_store.cr       # NEW - Redis implementation
      cacheable.cr               # NEW - Cacheable module
      cache_config.cr            # NEW - Cache configuration
      cache_warmer.cr            # NEW - Cache warming
      
    # Phase 4 & 5: Reactive System
    reactive/
      reactive_socket.cr         # NEW - WebSocket handler
      reactive_session.cr        # NEW - Session management
      reactive_component.cr      # NEW - Reactive component base
      update_strategies.cr       # NEW - Update strategies
      message_types.cr           # NEW - Message definitions
      
public/
  js/
    amber-reactive.js            # NEW - Reactive client
    amber-reactive.min.js        # NEW - Minified version
```

## Implementation Order

### Step 1: Clean Slate
1. Delete all existing component files
2. Create new directory structure
3. Set up proper namespacing

### Step 2: Phase 1 - HTML Elements (2-3 days)
1. Implement base element classes
2. Implement ALL 100+ HTML element classes
3. Add attribute validation for each
4. Create comprehensive tests

### Step 3: Phase 2 - Components (2-3 days)
1. Build new component base classes
2. Ensure components use element classes
3. Create example components

### Step 4: Phase 3 - Caching (2 days)
1. Implement cache stores
2. Add Russian doll caching
3. Performance testing

### Step 5: Phase 4 & 5 - Reactive System (6 days)
1. Build amber-reactive.js client
2. Implement WebSocket server
3. Create reactive components
4. Integration testing

## Key Differences from Old System

### Old Approach (DELETE)
```crystal
# Generic element with string tag
HTMLElement.container("div", content, class: "card")

# Helper methods
def div(content, **attrs)
  HTMLElement.container("div", content, attrs)
end

# Components using string templates
def render_content
  tag("div", class: "card") do
    tag("h1", @title)
  end
end
```

### New Approach (IMPLEMENT)
```crystal
# Specific element classes
Div.new(class: "card") << content

# Components using element objects
def render_content
  Div.new(class: "card").build do |card|
    card << H1.new(@title)
    card << P.new(@description)
  end.render
end
```

## Benefits of Complete Rewrite

1. **Clean Architecture**: No legacy code to work around
2. **Proper Foundation**: Element classes from the start
3. **Type Safety**: Full compile-time checking
4. **Performance**: Optimized from ground up
5. **Maintainability**: Clear, consistent codebase

## Testing Strategy

1. **Element Tests**: Every element class thoroughly tested
2. **Component Tests**: Test composition and rendering
3. **Cache Tests**: Performance and correctness
4. **Reactive Tests**: WebSocket and DOM updates
5. **Integration Tests**: Full system behavior

## Success Metrics

- Zero string-based HTML generation
- 100% type-safe HTML construction
- All HTML5 elements implemented
- Reactive updates working smoothly
- Performance better than templates

## Next Steps

1. **Confirm deletion list** with project team
2. **Begin deletion** of old component system
3. **Start Phase 1** implementation immediately
4. **No shortcuts** - implement all elements first