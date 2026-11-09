require "./cache_store"

module Components
  module Cache
    # An in-process store, least recently used first, held inside a byte budget.
    #
    # The budget counts every key, payload and dependency it stores, plus a fixed charge per entry
    # for the bookkeeping around them. A page, its sections and its rows each charge the same
    # budget, so nesting cannot grow past it. A *maximum_bytes* of zero stores nothing.
    class MemoryCacheStore < CacheStore
      DEFAULT_MAXIMUM_BYTES = 33_554_432_i64 # 32 MiB

      # The charge for an entry's hash slot, entry record and two string headers.
      ENTRY_OVERHEAD_BYTES = 160_i64

      # The charge for one dependency edge beyond the key text it names.
      DEPENDENCY_OVERHEAD_BYTES = 64_i64

      # How many cleared keys are remembered for renders that began before the clear.
      FORGOTTEN_KEY_LIMIT = 4096

      # How many cleared key prefixes are remembered. A prefix clear is rare and each one costs a
      # comparison on every guarded store.
      FORGOTTEN_PREFIX_LIMIT = 256

      alias Payload = String | Bytes

      # One stored value with its expiry and what it depends on.
      struct CacheEntry
        getter value : Payload
        getter byte_count : Int64
        getter expires_at : Time?
        getter list_of_dependency_keys : Array(String)?
        getter owner_key : String?

        def initialize(@value : Payload, @byte_count : Int64, @expires_at : Time?, @list_of_dependency_keys : Array(String)? = nil, @owner_key : String? = nil)
        end

        def expired? : Bool
          expiry = @expires_at
          return false unless expiry
          Time.utc > expiry
        end
      end

      getter maximum_bytes : Int64

      def initialize(@maximum_bytes : Int64 = DEFAULT_MAXIMUM_BYTES)
        @cache = {} of String => CacheEntry
        @mutex = Mutex.new(:unchecked)
        @stored_bytes = 0_i64
        @dependent_keys_by_dependency = {} of String => Set(String)
        @generation = 0_i64
        @oldest_remembered_generation = 0_i64
        @forgotten_generation_by_key = {} of String => Int64
        @list_of_forgotten_keys = Deque(Tuple(String, Int64)).new
        @forgotten_generation_by_prefix = {} of String => Int64
      end

      # Every byte the budget currently counts.
      def stored_bytes : Int64
        @mutex.synchronize { @stored_bytes }
      end

      # A render that began before a clear does not store what it read, or the old HTML would
      # outlive the write that cleared it.
      def fetch(key : String, expires_in : Time::Span? = nil, &block : -> String) : String
        if cached = read(key)
          return cached
        end

        generation = current_generation
        value = yield
        write_unless_cleared(key, value, generation, expires_in)
        value
      end

      def fetch_with_dependencies(key : String, list_of_dependency_keys : Array(String), owner_key : String? = nil, expires_in : Time::Span? = nil, & : -> String) : String
        if cached = read(key)
          return cached
        end

        generation = current_generation
        value = yield
        store(key, value, expires_in, generation, list_of_dependency_keys, owner_key)
        value
      end

      def read(key : String) : String?
        payload = read_payload(key)
        return payload if payload.nil? || payload.is_a?(String)
        String.new(payload)
      end

      def read_bytes(key : String) : Bytes?
        payload = read_payload(key)
        return payload if payload.nil? || payload.is_a?(Bytes)
        payload.to_slice
      end

      def write(key : String, value : String, expires_in : Time::Span? = nil) : Nil
        store(key, value, expires_in, nil)
      end

      def write_bytes(key : String, value : Bytes, expires_in : Time::Span? = nil) : Nil
        store(key, owned_copy_of(value), expires_in, nil)
      end

      def current_generation : Int64
        @mutex.synchronize { @generation }
      end

      def write_unless_cleared(key : String, value : String, generation : Int64, expires_in : Time::Span? = nil) : Bool
        store(key, value, expires_in, generation)
      end

      def write_bytes_unless_cleared(key : String, value : Bytes, generation : Int64, expires_in : Time::Span? = nil) : Bool
        store(key, owned_copy_of(value), expires_in, generation)
      end

      def replace_bytes_unless_cleared(key : String, value : Bytes, generation : Int64) : Bool
        replacement = owned_copy_of(value)
        @mutex.synchronize do
          entry = @cache[key]?
          next false unless entry
          next false if forgotten_since?(key, generation)
          byte_count = entry.byte_count - entry.value.bytesize + replacement.bytesize
          if byte_count > @maximum_bytes
            remove_entry(key)
            next false
          end
          @cache[key] = CacheEntry.new(replacement, byte_count, entry.expires_at, entry.list_of_dependency_keys, entry.owner_key)
          @stored_bytes += byte_count - entry.byte_count
          evict_until_within_budget
          true
        end
      end

      def delete(key : String) : Nil
        delete_all([key])
      end

      def delete_all(list_of_keys : Array(String)) : Array(String)
        @mutex.synchronize do
          list_of_removed_keys = [] of String
          list_of_keys.each do |key|
            list_of_removed_keys << key if remove_entry(key)
            remember_forgotten_key(key)
          end
          list_of_removed_keys
        end
      end

      def delete_dependents(dependency_key : String) : Array(String)
        @mutex.synchronize do
          list_of_removed_keys = [] of String
          list_of_pending_keys = [dependency_key]
          visited_keys = Set{dependency_key}
          until list_of_pending_keys.empty?
            pending_key = list_of_pending_keys.pop
            remember_forgotten_key(pending_key)
            dependent_keys = @dependent_keys_by_dependency[pending_key]?
            next unless dependent_keys
            dependent_keys.to_a.each do |dependent_key|
              owner_key = @cache[dependent_key]?.try(&.owner_key)
              list_of_removed_keys << dependent_key if remove_entry(dependent_key)
              list_of_pending_keys << dependent_key if visited_keys.add?(dependent_key)
              list_of_pending_keys << owner_key if owner_key && visited_keys.add?(owner_key)
            end
          end
          list_of_removed_keys
        end
      end

      def delete_numbered_from(prefix : String, first_number : Int32) : Array(String)
        @mutex.synchronize do
          remember_forgotten_prefix(prefix)
          list_of_removed_keys = @cache.keys.select do |key|
            next false unless key.starts_with?(prefix)
            page_number = key[prefix.size..].partition(':').first.to_i?
            page_number.nil? || page_number >= first_number
          end
          list_of_removed_keys.each { |key| remove_entry(key) }
          list_of_removed_keys
        end
      end

      def clear : Nil
        @mutex.synchronize do
          @generation += 1
          @oldest_remembered_generation = @generation
          @cache.clear
          @stored_bytes = 0_i64
          @dependent_keys_by_dependency.clear
          @forgotten_generation_by_key.clear
          @list_of_forgotten_keys.clear
          @forgotten_generation_by_prefix.clear
        end
      end

      def exists?(key : String) : Bool
        @mutex.synchronize { !live_entry(key).nil? }
      end

      # `"size"` is the payload bytes; `"stored_bytes"` is what the budget counts.
      def stats : Hash(String, Int32 | Int64)
        @mutex.synchronize do
          remove_expired_entries
          {
            "entries"      => @cache.size,
            "size"         => @cache.sum(0_i64) { |_, entry| entry.value.bytesize.to_i64 },
            "stored_bytes" => @stored_bytes,
          } of String => Int32 | Int64
        end
      end

      # Clean up expired entries periodically
      def cleanup : Nil
        @mutex.synchronize { remove_expired_entries }
      end

      private def owned_copy_of(value : Bytes) : Bytes
        copy = value.dup
        Bytes.new(copy.to_unsafe, copy.size, read_only: true)
      end

      private def read_payload(key : String) : Payload?
        return nil if @maximum_bytes.zero?
        @mutex.synchronize do
          entry = live_entry(key)
          next nil unless entry
          touch(key, entry)
          entry.value
        end
      end

      private def store(key : String, value : Payload, expires_in : Time::Span?, generation : Int64?, list_of_dependency_keys : Array(String)? = nil, owner_key : String? = nil) : Bool
        return false if @maximum_bytes.zero?
        byte_count = key.bytesize.to_i64 + value.bytesize + ENTRY_OVERHEAD_BYTES + dependency_byte_count(list_of_dependency_keys, owner_key)
        expires_at = expires_in ? Time.utc + expires_in : nil
        @mutex.synchronize do
          next false if generation && any_cleared_since?(key, list_of_dependency_keys, owner_key, generation)
          remove_entry(key)
          next false if byte_count > @maximum_bytes
          @cache[key] = CacheEntry.new(value, byte_count, expires_at, list_of_dependency_keys, owner_key)
          @stored_bytes += byte_count
          index_dependencies(key, list_of_dependency_keys)
          evict_until_within_budget
          true
        end
      end

      private def dependency_byte_count(list_of_dependency_keys : Array(String)?, owner_key : String?) : Int64
        total = owner_key ? owner_key.bytesize.to_i64 : 0_i64
        return total unless list_of_dependency_keys
        list_of_dependency_keys.sum(total) { |dependency_key| dependency_key.bytesize.to_i64 + DEPENDENCY_OVERHEAD_BYTES }
      end

      private def index_dependencies(key : String, list_of_dependency_keys : Array(String)?) : Nil
        return unless list_of_dependency_keys
        list_of_dependency_keys.each do |dependency_key|
          dependent_keys = @dependent_keys_by_dependency[dependency_key]? || (@dependent_keys_by_dependency[dependency_key] = Set(String).new)
          dependent_keys << key
        end
      end

      private def unindex_dependencies(key : String, entry : CacheEntry) : Nil
        list_of_dependency_keys = entry.list_of_dependency_keys
        return unless list_of_dependency_keys
        list_of_dependency_keys.each do |dependency_key|
          dependent_keys = @dependent_keys_by_dependency[dependency_key]?
          next unless dependent_keys
          dependent_keys.delete(key)
          @dependent_keys_by_dependency.delete(dependency_key) if dependent_keys.empty?
        end
      end

      private def live_entry(key : String) : CacheEntry?
        entry = @cache[key]?
        return nil unless entry
        return entry unless entry.expired?
        remove_entry(key)
        nil
      end

      # The most recently used entry moves to the end, so the first key is always the oldest.
      private def touch(key : String, entry : CacheEntry) : Nil
        @cache.delete(key)
        @cache[key] = entry
      end

      private def remove_entry(key : String) : Bool
        entry = @cache.delete(key)
        return false unless entry
        @stored_bytes -= entry.byte_count
        unindex_dependencies(key, entry)
        true
      end

      private def remove_expired_entries : Nil
        @cache.keys.each { |key| live_entry(key) }
      end

      private def evict_until_within_budget : Nil
        while @stored_bytes > @maximum_bytes
          oldest_key = @cache.first_key?
          break unless oldest_key
          remove_entry(oldest_key)
        end
      end

      private def any_cleared_since?(key : String, list_of_dependency_keys : Array(String)?, owner_key : String?, generation : Int64) : Bool
        return true if forgotten_since?(key, generation)
        return true if owner_key && forgotten_since?(owner_key, generation)
        return false unless list_of_dependency_keys
        list_of_dependency_keys.any? { |dependency_key| forgotten_since?(dependency_key, generation) }
      end

      private def remember_forgotten_key(key : String) : Nil
        @generation += 1
        @forgotten_generation_by_key[key] = @generation
        @list_of_forgotten_keys << {key, @generation}
        return if @list_of_forgotten_keys.size <= FORGOTTEN_KEY_LIMIT
        oldest_key, oldest_generation = @list_of_forgotten_keys.shift
        @oldest_remembered_generation = oldest_generation if oldest_generation > @oldest_remembered_generation
        # A key forgotten again later keeps its newer record.
        @forgotten_generation_by_key.delete(oldest_key) if @forgotten_generation_by_key[oldest_key]? == oldest_generation
      end

      private def remember_forgotten_prefix(prefix : String) : Nil
        @generation += 1
        @forgotten_generation_by_prefix.delete(prefix)
        @forgotten_generation_by_prefix[prefix] = @generation
        return if @forgotten_generation_by_prefix.size <= FORGOTTEN_PREFIX_LIMIT
        oldest_prefix = @forgotten_generation_by_prefix.first_key
        oldest_generation = @forgotten_generation_by_prefix[oldest_prefix]
        @forgotten_generation_by_prefix.delete(oldest_prefix)
        # A render older than a dropped record can no longer be checked, so it is refused.
        @oldest_remembered_generation = oldest_generation if oldest_generation > @oldest_remembered_generation
      end

      private def forgotten_since?(key : String, generation : Int64) : Bool
        return true if generation < @oldest_remembered_generation
        forgotten_at = @forgotten_generation_by_key[key]?
        return true if forgotten_at && forgotten_at > generation
        @forgotten_generation_by_prefix.any? do |prefix, prefix_forgotten_at|
          prefix_forgotten_at > generation && key.starts_with?(prefix)
        end
      end
    end
  end
end
