require "./cache_store"
# NOTE: Redis shard needs to be added to shard.yml
# require "redis"

module Components
  module Cache
    # Redis-backed cache store implementation
    # NOTE: This is a placeholder implementation until Redis shard is added
    class RedisCacheStore < CacheStore
      # @redis : Redis
      @prefix : String
      @data : Hash(String, String)
      
      def initialize(@prefix : String = "amber:components:")
        @data = {} of String => String
        # In production: def initialize(@redis : Redis, @prefix : String = "amber:components:")
      end
      
      def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
        full_key = "#{@prefix}#{key}"
        
        # Try to read from cache first
        if cached = @data[full_key]?
          return cached
        end
        
        # Compute the value
        value = yield
        
        # Store in cache
        write(key, value, expires_in)
        
        value
      end
      
      def read(key : String) : String?
        full_key = "#{@prefix}#{key}"
        @data[full_key]?
      end
      
      def write(key : String, value : String, expires_in : Time::Span? = nil) : Nil
        full_key = "#{@prefix}#{key}"
        # NOTE: In production, handle expiration with Redis
        @data[full_key] = value
      end
      
      def delete(key : String) : Nil
        full_key = "#{@prefix}#{key}"
        @data.delete(full_key)
      end
      
      def clear : Nil
        # Get all keys with our prefix
        @data.delete_if { |key, _| key.starts_with?(@prefix) }
      end
      
      def exists?(key : String) : Bool
        full_key = "#{@prefix}#{key}"
        @data.has_key?(full_key)
      end
      
      def stats : Hash(String, Int32 | Int64)
        # Get all keys with our prefix to count entries
        count = @data.keys.count { |key| key.starts_with?(@prefix) }
        size = @data.select { |key, _| key.starts_with?(@prefix) }.values.sum(&.bytesize)
        
        {
          "entries" => count,
          "size" => size.to_i64
        }
      end
    end
  end
end