module Components
  module Cache
    # Abstract base class for cache stores
    abstract class CacheStore
      # Fetch a value from cache, or compute and store it if not present
      abstract def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
      
      # Read a value from cache
      abstract def read(key : String) : String?
      
      # Write a value to cache
      abstract def write(key : String, value : String, expires_in : Time::Span? = nil) : Nil
      
      # Delete a value from cache
      abstract def delete(key : String) : Nil
      
      # Clear all cached values
      abstract def clear : Nil
      
      # Check if a key exists
      abstract def exists?(key : String) : Bool
      
      # Get statistics about the cache
      def stats : Hash(String, Int32 | Int64)
        {"entries" => 0, "size" => 0}
      end
    end
  end
end