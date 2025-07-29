require "./component"
require "../cache/cacheable"

module Components
  # Base class for stateless components
  # These components are pure functions of their inputs with no internal state
  abstract class StatelessComponent < Component
    include Cache::Cacheable
    # Stateless components can be cached based on their attributes
    def cache_key : String
      String.build do |str|
        str << self.class.name
        str << ":"
        str << @attributes.hash
      end
    end
    
    # Check if this component is cacheable
    def cacheable? : Bool
      true
    end
    
    # Two stateless components are equal if they have the same class and attributes
    def ==(other : self) : Bool
      self.class == other.class && @attributes == other.attributes
    end
  end
end