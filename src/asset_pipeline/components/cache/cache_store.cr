module AssetPipeline
  module Components
    module Cache
      # Abstract base class for component caching implementations
      # Users implement this interface with their preferred caching backend
      abstract class CacheStore
        # Fetch a value from cache, yielding block if not found
        # The block result will be cached for future requests
        abstract def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
        
        # Read a value from cache, returns nil if not found or expired
        abstract def read(key : String) : String?
        
        # Write a value to cache with optional expiration
        abstract def write(key : String, value : String, expires_in : Time::Span? = nil) : Bool
        
        # Delete a specific key from cache
        abstract def delete(key : String) : Bool
        
        # Clear all cache entries
        abstract def clear : Bool
        
        # Check if a key exists in cache (and is not expired)
        abstract def exists?(key : String) : Bool
        
        # Get statistics about cache usage (optional, for monitoring)
        def stats : Hash(String, Int32 | String)
          {
            "implementation" => self.class.name.as(Int32 | String),
            "supported_operations" => "basic".as(Int32 | String)
          }
        end
        
        # Delete multiple keys matching a pattern (optional optimization)
        def delete_matched(pattern : Regex) : Int32
          # Default implementation - subclasses can optimize this
          deleted_count = 0
          all_keys.each do |key|
            if key.matches?(pattern)
              delete(key)
              deleted_count += 1
            end
          end
          deleted_count
        end
        
        # Get all keys in cache (for pattern matching, optional)
        def all_keys : Array(String)
          # Default empty implementation - subclasses should override if supported
          Array(String).new
        end
        
        # Increment a numeric value in cache (atomic operation if supported)
        def increment(key : String, amount : Int32 = 1, expires_in : Time::Span? = nil) : Int32
          current_value = read(key).try(&.to_i?) || 0
          new_value = current_value + amount
          write(key, new_value.to_s, expires_in)
          new_value
        end
        
        # Decrement a numeric value in cache (atomic operation if supported)
        def decrement(key : String, amount : Int32 = 1, expires_in : Time::Span? = nil) : Int32
          increment(key, -amount, expires_in)
        end
        
        # Multi-read operation for efficiency (optional optimization)
        def read_multi(keys : Array(String)) : Hash(String, String?)
          result = Hash(String, String?).new
          keys.each do |key|
            result[key] = read(key)
          end
          result
        end
        
        # Multi-write operation for efficiency (optional optimization)
        def write_multi(entries : Hash(String, String), expires_in : Time::Span? = nil) : Bool
          success = true
          entries.each do |key, value|
            success &&= write(key, value, expires_in)
          end
          success
        end
        
        # Touch a key to extend its expiration without changing the value
        def touch(key : String, expires_in : Time::Span) : Bool
          if value = read(key)
            write(key, value, expires_in)
          else
            false
          end
        end
        
        # Get the size/count of entries in cache (optional)
        def size : Int32
          all_keys.size
        end
        
        # Check if cache store is available/connected
        def connected? : Bool
          true # Default implementation assumes always connected
        end
        
        # Reset statistics (optional, empty default implementation)
        def reset_stats
          # Default empty implementation - subclasses can override
        end
        
        # Namespace support for multi-tenant scenarios
        def with_namespace(namespace : String) : CacheStore
          NamespacedCacheStore.new(self, namespace)
        end
      end
      
      # Wrapper class to add namespace support to any cache store
      class NamespacedCacheStore < CacheStore
        def initialize(@store : CacheStore, @namespace : String)
        end
        
        private def namespaced_key(key : String) : String
          "#{@namespace}:#{key}"
        end
        
        def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
          @store.fetch(namespaced_key(key), expires_in, &block)
        end
        
        def read(key : String) : String?
          @store.read(namespaced_key(key))
        end
        
        def write(key : String, value : String, expires_in : Time::Span? = nil) : Bool
          @store.write(namespaced_key(key), value, expires_in)
        end
        
        def delete(key : String) : Bool
          @store.delete(namespaced_key(key))
        end
        
        def clear : Bool
          # For namespaced stores, we can only clear by pattern
          pattern = /^#{Regex.escape(@namespace)}:/
          @store.delete_matched(pattern) > 0
        end
        
        def exists?(key : String) : Bool
          @store.exists?(namespaced_key(key))
        end
        
        def all_keys : Array(String)
          prefix = "#{@namespace}:"
          @store.all_keys
            .select(&.starts_with?(prefix))
            .map(&.[prefix.size..])
        end
        
        def stats : Hash(String, Int32 | String)
          base_stats = @store.stats
          base_stats["namespace"] = @namespace
          base_stats
        end
      end
    end
  end
end 