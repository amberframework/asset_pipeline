require "./component"
require "../cache/cacheable"
require "../cache/stable_digest"

module Components
  # Base class for stateless components
  # These components are pure functions of their inputs with no internal state
  abstract class StatelessComponent < Component
    include Cache::Cacheable

    # Stateless components can be cached based on their attributes
    def cache_key : String
      Cache::StableDigest.cache_key_for(self.class.name, @attributes)
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
