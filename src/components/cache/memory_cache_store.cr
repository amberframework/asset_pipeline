require "./cache_store"

module Components
  module Cache
    # In-memory cache store implementation
    class MemoryCacheStore < CacheStore
      # Cache entry with value and expiration time
      struct CacheEntry
        property value : String
        property expires_at : Time?
        
        def initialize(@value, expires_in : Time::Span? = nil)
          @expires_at = expires_in ? Time.utc + expires_in : nil
        end
        
        def expired? : Bool
          return false unless expires_at = @expires_at
          Time.utc > expires_at
        end
      end
      
      # Thread-safe cache storage
      @cache : Hash(String, CacheEntry)
      @mutex : Mutex
      
      def initialize
        @cache = {} of String => CacheEntry
        @mutex = Mutex.new
      end
      
      def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
        # Try to read from cache first
        if cached = read(key)
          return cached
        end
        
        # Compute the value
        value = yield
        
        # Store in cache
        write(key, value, expires_in)
        
        value
      end
      
      def read(key : String) : String?
        @mutex.synchronize do
          if entry = @cache[key]?
            if entry.expired?
              @cache.delete(key)
              nil
            else
              entry.value
            end
          else
            nil
          end
        end
      end
      
      def write(key : String, value : String, expires_in : Time::Span? = nil) : Nil
        @mutex.synchronize do
          @cache[key] = CacheEntry.new(value, expires_in)
        end
      end
      
      def delete(key : String) : Nil
        @mutex.synchronize do
          @cache.delete(key)
        end
      end
      
      def clear : Nil
        @mutex.synchronize do
          @cache.clear
        end
      end
      
      def exists?(key : String) : Bool
        @mutex.synchronize do
          if entry = @cache[key]?
            if entry.expired?
              @cache.delete(key)
              false
            else
              true
            end
          else
            false
          end
        end
      end
      
      def stats : Hash(String, Int32 | Int64)
        @mutex.synchronize do
          # Clean up expired entries
          @cache.delete_if { |_, entry| entry.expired? }
          
          {
            "entries" => @cache.size,
            "size" => @cache.values.sum { |entry| entry.value.bytesize }.to_i64
          }
        end
      end
      
      # Clean up expired entries periodically
      def cleanup : Nil
        @mutex.synchronize do
          @cache.delete_if { |_, entry| entry.expired? }
        end
      end
    end
  end
end