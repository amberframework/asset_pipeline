module Components
  module CSS
    module Scanner
      # Scans Crystal source files for CSS class usage
      class ClassScanner
        @paths : Array(String)
        @ignore_patterns : Array(Regex)
        
        def initialize(@paths : Array(String) = ["./src"])
          @ignore_patterns = [
            /node_modules/,
            /\.git/,
            /build/,
            /dist/,
            /output/,
          ]
        end
        
        # Scan all files and register found classes
        def scan : Set(String)
          found_classes = Set(String).new
          
          @paths.each do |path|
            if File.directory?(path)
              scan_directory(path, found_classes)
            elsif File.exists?(path)
              scan_file(path, found_classes)
            end
          end
          
          # Register all found classes
          registry = ClassRegistry.instance
          found_classes.each do |class_name|
            registry.register_class(class_name)
          end
          
          found_classes
        end
        
        # Scan a directory recursively
        private def scan_directory(dir : String, found_classes : Set(String))
          Dir.glob("#{dir}/**/*.cr") do |file|
            next if should_ignore?(file)
            scan_file(file, found_classes)
          end
        end
        
        # Scan a single file for class names
        private def scan_file(file : String, found_classes : Set(String))
          content = File.read(file)
          
          # Find class names in various contexts
          patterns = [
            # String literals with common class methods
            /\.add_class\s*\(\s*"([^"]+)"\s*\)/,
            /\.add_class\s*\(\s*'([^']+)'\s*\)/,
            /class:\s*"([^"]+)"/,
            /class:\s*'([^']+)'/,
            /"class"\s*=>\s*"([^"]+)"/,
            /'class'\s*=>\s*'([^']+)'/,
            
            # CSS DSL usage
            /\.base\s*\(\s*"([^"]+)"\s*\)/,
            /\.add\s*\(\s*"([^"]+)"\s*[,)]/,
            /\.hover\s*\(\s*"([^"]+)"\s*\)/,
            /\.focus\s*\(\s*"([^"]+)"\s*\)/,
            /\.dark\s*\(\s*"([^"]+)"\s*\)/,
            
            # Responsive utilities
            /\.sm\s*\(\s*"([^"]+)"\s*\)/,
            /\.md\s*\(\s*"([^"]+)"\s*\)/,
            /\.lg\s*\(\s*"([^"]+)"\s*\)/,
            /\.xl\s*\(\s*"([^"]+)"\s*\)/,
            
            # Class builder methods
            /class_names\s*\([^)]*"([^"]+)"/,
            /merge_classes\s*\([^)]*"([^"]+)"/,
            /variant_classes\s*\([^)]*"([^"]+)"/,
          ]
          
          patterns.each do |pattern|
            content.scan(pattern) do |match|
              if class_string = match[1]?
                # Split multiple classes
                class_string.split(/\s+/).each do |class_name|
                  next if class_name.empty?
                  found_classes << class_name
                end
              end
            end
          end
        end
        
        # Check if a file should be ignored
        private def should_ignore?(file : String) : Bool
          @ignore_patterns.any? { |pattern| file.match(pattern) }
        end
        
        # Add paths to scan
        def add_path(path : String)
          @paths << path unless @paths.includes?(path)
        end
        
        # Add ignore pattern
        def add_ignore_pattern(pattern : Regex)
          @ignore_patterns << pattern
        end
      end
      
      # Convenience method to scan the project
      def self.scan_project(paths : Array(String) = ["./src"]) : Set(String)
        scanner = ClassScanner.new(paths)
        scanner.scan
      end
    end
  end
end