module AssetPipeline
  # The `DependencyAnalyzer` analyzes JavaScript code to detect dependencies that should be imported.
  # It can identify references to external libraries, local modules, and common JavaScript patterns
  # that indicate missing imports.
  #
  # Performance optimizations:
  # - Caches dependency analysis results based on JavaScript content hash
  # - Memoizes expensive regex operations
  # - Caches import suggestions to avoid regeneration
  class DependencyAnalyzer
    # Common external library patterns and their typical import names
    EXTERNAL_LIBRARY_PATTERNS = {
      # jQuery patterns
      /\$\s*\(/ => "jquery",
      /jQuery[\.\s]*[\(\w]/ => "jQuery",
      
      # Lodash patterns  
      /_\.(map|filter|forEach|reduce|find|includes|isEmpty|isArray|get|set|has|clone)/ => "lodash",
      /lodash\.(map|filter|forEach|reduce|find|includes|isEmpty|isArray|get|set|has|clone)/ => "lodash",
      
      # Moment.js patterns
      /moment\s*\(/ => "moment",
      /moment\.(now|utc|unix)/ => "moment",
      
      # Chart.js patterns
      /new\s+Chart\s*\(/ => "chartjs",
      /Chart\.(register|defaults)/ => "chartjs",
      
      # Alpine.js patterns
      /Alpine\.(start|data|store)/ => "alpinejs",
      /x-data\s*=/ => "alpinejs",
      
      # Vue.js patterns
      /Vue\.(createApp|ref|reactive|computed)/ => "vue",
      /createApp\s*\(/ => "vue",
      
      # React patterns
      /React\.(useState|useEffect|createElement)/ => "react",
      /ReactDOM\.render/ => "react-dom",
      
      # Common utility patterns
      /axios\.(get|post|put|delete)/ => "axios",
      /fetch\s*\(/ => "unfetch", # Common polyfill
    }
    
    # Patterns that indicate local module references
    LOCAL_MODULE_PATTERNS = [
      # Function calls that look like class constructors
      /new\s+([A-Z][a-zA-Z0-9_]*)\s*\(/,
      # Method calls on capitalized objects
      /([A-Z][a-zA-Z0-9_]*)\.[a-zA-Z_][a-zA-Z0-9_]*\s*\(/,
      # Static method references
      /([A-Z][a-zA-Z0-9_]*)\.[A-Z_][A-Z0-9_]*\s*[=\(]/,
    ]

    @javascript_content : String
    @content_hash : UInt64
    
    # Performance caches - class level to share across instances
    @@dependency_cache : Hash(UInt64, Hash(Symbol, Array(String))) = {} of UInt64 => Hash(Symbol, Array(String))
    @@external_deps_cache : Hash(UInt64, Array(String)) = {} of UInt64 => Array(String)
    @@local_deps_cache : Hash(UInt64, Array(String)) = {} of UInt64 => Array(String)
    @@imports_cache : Hash(UInt64, Array(String)) = {} of UInt64 => Array(String)
    @@complexity_cache : Hash(UInt64, Hash(String, String)) = {} of UInt64 => Hash(String, String)
    
    def initialize(@javascript_content : String)
      @content_hash = @javascript_content.hash.to_u64
    end

    # Analyzes the JavaScript content and returns detected dependencies
    #
    # Returns a hash with:
    # - :external - Array of external library names detected
    # - :local - Array of local module names detected
    # - :suggestions - Array of import suggestions
    def analyze_dependencies : Hash(Symbol, Array(String))
      # Check cache first
      if cached_result = @@dependency_cache[@content_hash]?
        return cached_result
      end
      
      external_deps = detect_external_dependencies
      local_deps = detect_local_dependencies
      suggestions = generate_import_suggestions(external_deps, local_deps)
      
      result = Hash(Symbol, Array(String)).new.tap do |hash|
        hash[:external] = external_deps
        hash[:local] = local_deps
        hash[:suggestions] = suggestions
      end
      
      # Cache the result
      @@dependency_cache[@content_hash] = result
      
      # Limit cache size to prevent memory growth
      limit_cache_size(@@dependency_cache, 100)
      
      result
    end

    # Detects external library dependencies from common usage patterns
    def detect_external_dependencies : Array(String)
      # Check cache first
      if cached_deps = @@external_deps_cache[@content_hash]?
        return cached_deps
      end
      
      detected = Set(String).new
      
      EXTERNAL_LIBRARY_PATTERNS.each do |pattern, library_name|
        if @javascript_content.match(pattern)
          detected.add(library_name)
        end
      end
      
      result = detected.to_a
      
      # Cache the result
      @@external_deps_cache[@content_hash] = result
      limit_cache_size(@@external_deps_cache, 200)
      
      result
    end

    # Detects local module dependencies from usage patterns
    def detect_local_dependencies : Array(String)
      # Check cache first
      if cached_deps = @@local_deps_cache[@content_hash]?
        return cached_deps
      end
      
      detected = Set(String).new
      
      LOCAL_MODULE_PATTERNS.each do |pattern|
        @javascript_content.scan(pattern) do |match|
          class_name = match[1]? || match[0]
          detected.add(class_name) if class_name && looks_like_importable_class?(class_name)
        end
      end
      
      result = detected.to_a
      
      # Cache the result
      @@local_deps_cache[@content_hash] = result
      limit_cache_size(@@local_deps_cache, 200)
      
      result
    end

    # Generates import statement suggestions based on detected dependencies
    def generate_import_suggestions(external_deps : Array(String), local_deps : Array(String)) : Array(String)
      suggestions = [] of String
      
      external_deps.each do |dep|
        case dep
        when "jquery", "jQuery"
          suggestions << "Add to import map: import_map.add_import(\"#{dep}\", \"https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js\")"
        when "lodash"
          suggestions << "Add to import map: import_map.add_import(\"lodash\", \"https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm\")"
        when "moment"
          suggestions << "Add to import map: import_map.add_import(\"moment\", \"https://cdn.jsdelivr.net/npm/moment@2.29.4/+esm\")"
        when "chartjs"
          suggestions << "Add to import map: import_map.add_import(\"chartjs\", \"https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm\")"
        when "alpinejs"
          suggestions << "Add to import map: import_map.add_import(\"alpinejs\", \"https://cdn.jsdelivr.net/npm/alpinejs@3.13.2/dist/module.esm.js\")"
        when "vue"
          suggestions << "Add to import map: import_map.add_import(\"vue\", \"https://cdn.jsdelivr.net/npm/vue@3.3.4/dist/vue.esm-browser.js\")"
        when "react"
          suggestions << "Add to import map: import_map.add_import(\"react\", \"https://cdn.jsdelivr.net/npm/react@18.2.0/+esm\")"
        when "axios"
          suggestions << "Add to import map: import_map.add_import(\"axios\", \"https://cdn.jsdelivr.net/npm/axios@1.5.0/+esm\")"
        else
          suggestions << "Consider adding '#{dep}' to your import map"
        end
      end
      
      local_deps.each do |dep|
        suggestions << "Consider adding local module: import_map.add_import(\"#{dep}\", \"path/to/#{dep.downcase}.js\")"
      end
      
      suggestions
    end

    # Checks if a class name looks like it should be importable
    private def looks_like_importable_class?(class_name : String) : Bool
      # Must start with capital letter and contain only valid identifier characters
      return false unless class_name.match(/^[A-Z][a-zA-Z0-9_]*$/)
      
      # Exclude built-in browser APIs and common globals
      excluded_globals = %w[
        Object Array String Number Boolean Date RegExp Error
        Promise Window Document Element Event Node 
        XMLHttpRequest FormData Blob File FileReader
        Map Set WeakMap WeakSet Symbol Proxy Reflect
        JSON Math console localStorage sessionStorage
        setTimeout setInterval clearTimeout clearInterval
        fetch Response Request Headers URL URLSearchParams
        CustomEvent KeyboardEvent MouseEvent TouchEvent
        Audio Video Image Canvas WebSocket Worker
      ]
      
      !excluded_globals.includes?(class_name)
    end

    # Analyzes import statements that are already present in the code
    def extract_existing_imports : Array(String)
      # Check cache first
      if cached_imports = @@imports_cache[@content_hash]?
        return cached_imports
      end
      
      imports = [] of String
      
      # Match import statements
      @javascript_content.scan(/import\s+(?:(?:\{[^}]+\}|\*\s+as\s+\w+|\w+)(?:\s*,\s*(?:\{[^}]+\}|\*\s+as\s+\w+|\w+))*\s+from\s+)?["']([^"']+)["']/) do |match|
        imports << match[1]
      end
      
      # Match dynamic imports
      @javascript_content.scan(/import\s*\(\s*["']([^"']+)["']\s*\)/) do |match|
        imports << match[1]
      end
      
      result = imports.uniq
      
      # Cache the result
      @@imports_cache[@content_hash] = result
      limit_cache_size(@@imports_cache, 200)
      
      result
    end

    # Checks if the code uses any module syntax
    def uses_module_syntax? : Bool
      @javascript_content.includes?("import ") || 
      @javascript_content.includes?("export ") ||
      @javascript_content.includes?("import(")
    end

    # Analyzes the code complexity to determine if it needs modularization
    def analyze_code_complexity
      # Check cache first
      if cached_complexity = @@complexity_cache[@content_hash]?
        return cached_complexity
      end
      
      lines = @javascript_content.split('\n').reject(&.strip.empty?)
      # Count function declarations, arrow functions, and class methods
      function_declarations = @javascript_content.scan(/function\s+\w+/).size
      arrow_functions = @javascript_content.scan(/(?:const|let|var)\s+\w+\s*=\s*(?:function|\()/).size
      class_methods = @javascript_content.scan(/^\s*(?:constructor|[a-zA-Z_][a-zA-Z0-9_]*)\s*\(/m).size
      
      functions = function_declarations + arrow_functions + class_methods
      classes = @javascript_content.scan(/class\s+\w+/).size
      event_listeners = @javascript_content.scan(/addEventListener|on\w+\s*=/).size
      
      suggestions = [] of String
      
      if lines.size > 50
        suggestions << "Consider splitting large JavaScript blocks into separate modules"
      end
      
      if functions > 5
        suggestions << "Consider organizing functions into classes or modules"
      end
      
      if event_listeners > 3
        suggestions << "Consider using a framework like Stimulus for event handling"
      end
      
      result = {
        "lines" => lines.size.to_s,
        "functions" => functions.to_s,
        "classes" => classes.to_s,
        "event_listeners" => event_listeners.to_s,
        "suggestions" => suggestions.join(", ")
      }
      
      # Cache the result
      @@complexity_cache[@content_hash] = result
      limit_cache_size(@@complexity_cache, 100)
      
      result
    end

    # Performance monitoring and cache management methods
    
    # Returns cache statistics for monitoring performance
    def self.cache_stats : Hash(String, Int32)
      {
        "dependency_cache_size" => @@dependency_cache.size,
        "external_deps_cache_size" => @@external_deps_cache.size,
        "local_deps_cache_size" => @@local_deps_cache.size,
        "imports_cache_size" => @@imports_cache.size,
        "complexity_cache_size" => @@complexity_cache.size
      }
    end

    # Clears all performance caches (useful for testing or memory management)
    def self.clear_caches
      @@dependency_cache.clear
      @@external_deps_cache.clear
      @@local_deps_cache.clear
      @@imports_cache.clear
      @@complexity_cache.clear
    end

    # Limits cache size using FIFO eviction
    private def limit_cache_size(cache, max_size)
      if cache.size > max_size
        # Remove oldest entries (simple FIFO eviction)
        keys_to_remove = cache.keys.first((cache.size - max_size) + 1)
        keys_to_remove.each { |key| cache.delete(key) }
      end
    end

    # Bulk analysis for multiple JavaScript blocks (optimized for performance)
    def self.bulk_analyze(javascript_blocks : Array(String)) : Array(Hash(Symbol, Array(String)))
      results = [] of Hash(Symbol, Array(String))
      
      javascript_blocks.each do |js_content|
        analyzer = new(js_content)
        results << analyzer.analyze_dependencies
      end
      
      results
    end

    # Pre-warm cache with common patterns (useful for production deployments)
    def self.warm_cache(common_patterns : Array(String))
      common_patterns.each do |pattern|
        analyzer = new(pattern)
        analyzer.analyze_dependencies
      end
    end
  end
end 