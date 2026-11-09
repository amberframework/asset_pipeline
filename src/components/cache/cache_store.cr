module Components
  module Cache
    # Base error for the component cache.
    class Error < Exception
    end

    # Raised by a store asked for an operation its backend cannot perform.
    class UnsupportedOperationError < Error
    end

    # Abstract base class for cache stores.
    #
    # The abstract methods are all a store must supply. The other methods have defaults, so a store
    # written against the original interface keeps compiling; each says what it gives up.
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

      # Reads a byte payload. The slice is read-only and shares the stored memory.
      #
      # The default reads a string entry, which holds arbitrary bytes.
      def read_bytes(key : String) : Bytes?
        value = read(key)
        value ? value.to_slice : nil
      end

      # Writes a byte payload. The store keeps its own copy of *value*.
      def write_bytes(key : String, value : Bytes, expires_in : Time::Span? = nil) : Nil
        write(key, String.new(value), expires_in)
      end

      # A number that moves forward whenever an entry is cleared. Read it before reading the data
      # a value is built from, then pass it to `#write_unless_cleared`.
      def current_generation : Int64
        0_i64
      end

      # Writes *value* unless *key* was cleared after *generation*, and says whether it was written.
      #
      # The default has no record of clears, so it always writes.
      def write_unless_cleared(key : String, value : String, generation : Int64, expires_in : Time::Span? = nil) : Bool
        write(key, value, expires_in)
        true
      end

      # The byte-payload form of `#write_unless_cleared`.
      def write_bytes_unless_cleared(key : String, value : Bytes, generation : Int64, expires_in : Time::Span? = nil) : Bool
        write_bytes(key, value, expires_in)
        true
      end

      # Replaces the bytes of an entry that is still present and was not cleared after *generation*,
      # keeping its expiry and dependencies. Says whether it replaced anything.
      def replace_bytes_unless_cleared(key : String, value : Bytes, generation : Int64) : Bool
        return false unless exists?(key)
        write_bytes(key, value)
        true
      end

      # Like `#fetch`, and records that the entry depends on each of *list_of_dependency_keys*, so
      # `#delete_dependents` can find it. *owner_key* names the logical view the entry belongs to:
      # clearing a dependency also clears whatever depends on that view.
      #
      # The default records nothing, so its entries clear only by expiry.
      def fetch_with_dependencies(key : String, list_of_dependency_keys : Array(String), owner_key : String? = nil, expires_in : Time::Span? = nil, & : -> String) : String
        fetch(key, expires_in) { yield }
      end

      # Removes every entry recorded as depending on *dependency_key*, directly or through other
      # entries, and returns the removed keys. The default records nothing, so it removes nothing.
      def delete_dependents(dependency_key : String) : Array(String)
        [] of String
      end

      # Removes *list_of_keys* and returns the keys that were present.
      def delete_all(list_of_keys : Array(String)) : Array(String)
        list_of_removed_keys = list_of_keys.select { |key| exists?(key) }
        list_of_keys.each { |key| delete(key) }
        list_of_removed_keys
      end

      # Removes the entries under *prefix* whose number after the prefix is at least *first_number*,
      # and returns the removed keys. Offset pagination needs this: one new row moves every later page.
      def delete_numbered_from(prefix : String, first_number : Int32) : Array(String)
        raise UnsupportedOperationError.new("#{self.class} cannot delete entries by key prefix")
      end
    end
  end
end
