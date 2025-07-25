require "./cache_store"

module AssetPipeline
  module Components
    module Cache
      # In-memory cache store implementation for testing and development
      # Thread-safe implementation using Mutex
      # Supports expiration via timestamps
      class TestCacheStore < CacheStore
        # Internal structure for cache entries
        private struct CacheEntry
          property value : String
          property expires_at : Time?
          
          def initialize(@value : String, @expires_at : Time? = nil)
          end
          
          def expired? : Bool
            if expires_at = @expires_at
              Time.utc > expires_at
            else
              false
            end
          end
        end
        
        @store : Hash(String, CacheEntry)
        @mutex : Mutex
        @stats : Hash(String, Int32)
        
        def initialize
          @store = Hash(String, CacheEntry).new
          @mutex = Mutex.new
          @stats = {
            "hits" => 0,
            "misses" => 0,
            "writes" => 0,
            "deletes" => 0,
            "clears" => 0,
            "evictions" => 0
          }
        end
        
        def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
          @mutex.synchronize do
            if entry = @store[key]?
              if entry.expired?
                @store.delete(key)
                @stats["evictions"] += 1
              else
                @stats["hits"] += 1
                return entry.value
              end
            end
            
            @stats["misses"] += 1
            value = yield
            write_unsafe(key, value, expires_in)
            value
          end
        end
        
        def read(key : String) : String?
          @mutex.synchronize do
            entry = @store[key]?
            unless entry
              @stats["misses"] += 1
              return nil
            end
            
            if entry.expired?
              @store.delete(key)
              @stats["evictions"] += 1
              @stats["misses"] += 1
              nil
            else
              @stats["hits"] += 1
              entry.value
            end
          end
        end
        
        def write(key : String, value : String, expires_in : Time::Span? = nil) : Bool
          @mutex.synchronize do
            write_unsafe(key, value, expires_in)
            true
          end
        end
        
        def delete(key : String) : Bool
          @mutex.synchronize do
            if @store.delete(key)
              @stats["deletes"] += 1
              true
            else
              false
            end
          end
        end
        
        def clear : Bool
          @mutex.synchronize do
            @store.clear
            @stats["clears"] += 1
            true
          end
        end
        
        def exists?(key : String) : Bool
          @mutex.synchronize do
            entry = @store[key]?
            return false unless entry
            
            if entry.expired?
              @store.delete(key)
              @stats["evictions"] += 1
              false
            else
              true
            end
          end
        end
        
        def all_keys : Array(String)
          @mutex.synchronize do
            # Clean up expired entries while we're at it
            expired_keys = @store.select { |_, entry| entry.expired? }.keys
            expired_keys.each do |key|
              @store.delete(key)
              @stats["evictions"] += 1
            end
            
            @store.keys
          end
        end
        
        def delete_matched(pattern : Regex) : Int32
          @mutex.synchronize do
            deleted_count = 0
            keys_to_delete = @store.keys.select { |key| key.matches?(pattern) }
            
            keys_to_delete.each do |key|
              @store.delete(key)
              deleted_count += 1
            end
            
            @stats["deletes"] += deleted_count
            deleted_count
          end
        end
        
        def increment(key : String, amount : Int32 = 1, expires_in : Time::Span? = nil) : Int32
          @mutex.synchronize do
            current_value = 0
            
            if entry = @store[key]?
              if entry.expired?
                @store.delete(key)
                @stats["evictions"] += 1
              else
                current_value = entry.value.to_i? || 0
              end
            end
            
            new_value = current_value + amount
            write_unsafe(key, new_value.to_s, expires_in)
            new_value
          end
        end
        
        def read_multi(keys : Array(String)) : Hash(String, String?)
          @mutex.synchronize do
            result = Hash(String, String?).new
            
            keys.each do |key|
              entry = @store[key]?
              if entry
                if entry.expired?
                  @store.delete(key)
                  @stats["evictions"] += 1
                  @stats["misses"] += 1
                  result[key] = nil
                else
                  @stats["hits"] += 1
                  result[key] = entry.value
                end
              else
                @stats["misses"] += 1
                result[key] = nil
              end
            end
            
            result
          end
        end
        
        def write_multi(entries : Hash(String, String), expires_in : Time::Span? = nil) : Bool
          @mutex.synchronize do
            entries.each do |key, value|
              write_unsafe(key, value, expires_in)
            end
            true
          end
        end
        
        def size : Int32
          @mutex.synchronize do
            # Clean up expired entries
            expired_keys = @store.select { |_, entry| entry.expired? }.keys
            expired_keys.each do |key|
              @store.delete(key)
              @stats["evictions"] += 1
            end
            
            @store.size
          end
        end
        
        def stats : Hash(String, Int32 | String)
          @mutex.synchronize do
            base_stats = super
            cache_stats = @stats.transform_values { |v| v.as(Int32 | String) }
            cache_stats["size"] = @store.size.as(Int32 | String)
            cache_stats["implementation"] = "TestCacheStore"
            cache_stats["thread_safe"] = "true"
            base_stats.merge(cache_stats)
          end
        end
        
        # Additional methods for testing and debugging
        
        # Reset all statistics (useful for testing)
        def reset_stats
          @mutex.synchronize do
            @stats.each_key { |key| @stats[key] = 0 }
          end
        end
        
        # Get cache hit ratio as percentage
        def hit_ratio : Float64
          @mutex.synchronize do
            total_requests = @stats["hits"] + @stats["misses"]
            return 0.0 if total_requests == 0
            (@stats["hits"].to_f / total_requests.to_f) * 100.0
          end
        end
        
        # Manually trigger cleanup of expired entries
        def cleanup_expired
          @mutex.synchronize do
            expired_keys = @store.select { |_, entry| entry.expired? }.keys
            expired_keys.each do |key|
              @store.delete(key)
              @stats["evictions"] += 1
            end
            expired_keys.size
          end
        end
        
        # Get all entries with their expiration status (for debugging)
        def debug_entries : Hash(String, {value: String, expires_at: Time?, expired: Bool})
          @mutex.synchronize do
            result = Hash(String, {value: String, expires_at: Time?, expired: Bool}).new
            @store.each do |key, entry|
              result[key] = {
                value: entry.value,
                expires_at: entry.expires_at,
                expired: entry.expired?
              }
            end
            result
          end
        end
        
        # Check if cache store is properly configured
        def connected? : Bool
          true # Always connected for in-memory store
        end
        
        private def write_unsafe(key : String, value : String, expires_in : Time::Span?)
          expires_at = expires_in ? Time.utc + expires_in : nil
          @store[key] = CacheEntry.new(value, expires_at)
          @stats["writes"] += 1
        end
      end
    end
  end
end 