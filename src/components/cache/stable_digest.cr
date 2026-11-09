{% unless flag?(:ios) || flag?(:android) %}
  require "digest/sha256"
{% end %}

module Components
  module Cache
    # Digests values into cache keys that stay the same across processes and restarts.
    #
    # `Object#hash` is seeded per process, so a key built from it changes on every boot. Each part
    # is framed with its byte length, so `["ab", "c"]` and `["a", "bc"]` digest differently.
    #
    # Server builds use SHA-256. iOS and Android builds link no OpenSSL, so they use FNV-1a 128,
    # which is enough for a store that lives inside one device's process.
    module StableDigest
      HEX_LENGTH = 32

      # The key of *type_name* rendered with *attributes*, in any attribute order.
      #
      # ```
      # StableDigest.cache_key_for("Badge", {"color" => "red", "size" => "2"})
      # # => "Badge:5f3a..."
      # ```
      def self.cache_key_for(type_name : String, attributes : Hash(String, String)) : String
        list_of_parts = [] of String
        attributes.keys.sort!.each do |attribute_name|
          list_of_parts << attribute_name << attributes[attribute_name]
        end
        "#{type_name}:#{hex_of(list_of_parts)}"
      end

      # The key of *type_name* rendered with *list_of_parts*, in the given order.
      def self.cache_key_for(type_name : String, list_of_parts : Enumerable(String)) : String
        "#{type_name}:#{hex_of(list_of_parts)}"
      end

      # A fixed-length lowercase hexadecimal digest of *list_of_parts*.
      def self.hex_of(list_of_parts : Enumerable(String)) : String
        framed_parts = String.build do |framed|
          list_of_parts.each do |part|
            framed << part.bytesize << ':' << part
          end
        end
        {% if flag?(:ios) || flag?(:android) %}
          fnv1a_128_hex(framed_parts.to_slice)
        {% else %}
          Digest::SHA256.hexdigest(framed_parts)[0, HEX_LENGTH]
        {% end %}
      end

      # FNV-1a 128 of *input*, as 32 hexadecimal digits.
      def self.fnv1a_128_hex(input : Bytes) : String
        prime = (1_u128 << 88) + (1_u128 << 8) + 0x3b_u128
        digest = (0x6c62272e07bb0142_u128 << 64) | 0x62b821756295c58d_u128
        input.each do |byte|
          digest ^= byte.to_u128
          digest = digest &* prime
        end
        digest.to_s(16).rjust(HEX_LENGTH, '0')
      end
    end
  end
end
