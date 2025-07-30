module Components
  module CSS
    # DSL for building CSS class strings with automatic tracking
    class ClassBuilder
      @classes : Array(String)
      @conditions : Array({String, Bool})
      
      def initialize
        @classes = [] of String
        @conditions = [] of {String, Bool}
      end
      
      # Add base classes
      def base(*classes : String) : self
        @classes.concat(classes)
        self
      end
      
      # Add classes conditionally
      def add(classes : String, condition : Bool = true) : self
        @conditions << {classes, condition}
        self
      end
      
      # Add classes only if condition is true
      def when(condition : Bool, classes : String) : self
        add(classes, condition)
      end
      
      # Add classes only if condition is false
      def unless(condition : Bool, classes : String) : self
        add(classes, !condition)
      end
      
      # Responsive classes
      def responsive(&block : ResponsiveBuilder -> Nil) : self
        builder = ResponsiveBuilder.new
        yield builder
        @classes.concat(builder.build)
        self
      end
      
      # State variants (hover, focus, etc.)
      def hover(classes : String) : self
        @classes << classes.split(/\s+/).map { |c| "hover:#{c}" }.join(" ")
        self
      end
      
      def focus(classes : String) : self
        @classes << classes.split(/\s+/).map { |c| "focus:#{c}" }.join(" ")
        self
      end
      
      def active(classes : String) : self
        @classes << classes.split(/\s+/).map { |c| "active:#{c}" }.join(" ")
        self
      end
      
      def disabled(classes : String) : self
        @classes << classes.split(/\s+/).map { |c| "disabled:#{c}" }.join(" ")
        self
      end
      
      def dark(classes : String) : self
        @classes << classes.split(/\s+/).map { |c| "dark:#{c}" }.join(" ")
        self
      end
      
      # Build the final class string
      def build : String
        all_classes = @classes.dup
        
        # Add conditional classes
        @conditions.each do |classes, condition|
          all_classes << classes if condition
        end
        
        # Join and deduplicate
        result = all_classes.join(" ").split(/\s+/).uniq.join(" ")
        
        # Register with the class registry
        Components::CSS::ClassRegistry.instance.register_class(result)
        
        result
      end
      
      # Responsive builder for nested responsive classes
      class ResponsiveBuilder
        @classes : Array(String)
        
        def initialize
          @classes = [] of String
        end
        
        def sm(classes : String) : self
          @classes << classes.split(/\s+/).map { |c| "sm:#{c}" }.join(" ")
          self
        end
        
        def md(classes : String) : self
          @classes << classes.split(/\s+/).map { |c| "md:#{c}" }.join(" ")
          self
        end
        
        def lg(classes : String) : self
          @classes << classes.split(/\s+/).map { |c| "lg:#{c}" }.join(" ")
          self
        end
        
        def xl(classes : String) : self
          @classes << classes.split(/\s+/).map { |c| "xl:#{c}" }.join(" ")
          self
        end
        
        def xxl(classes : String) : self
          @classes << classes.split(/\s+/).map { |c| "2xl:#{c}" }.join(" ")
          self
        end
        
        def build : Array(String)
          @classes
        end
      end
    end
    
    # Helper method for components
    def css(&block : ClassBuilder -> Nil) : String
      builder = ClassBuilder.new
      yield builder
      builder.build
    end
  end
end