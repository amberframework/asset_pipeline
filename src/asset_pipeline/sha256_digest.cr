{% if flag?(:without_openssl) %}
  require "./vendor/beryl/crypto"
{% else %}
  require "digest/sha256"
{% end %}

module AssetPipeline
  # The SHA-256 that fingerprints assets, computes Subresource Integrity
  # values and keys the page cache. Both choices are `::Digest` subclasses
  # and give the same bytes.
  #
  # Crystal's `Digest::SHA256` calls OpenSSL. An app built with
  # `-Dwithout_openssl` uses the pinned copy of Beryl under
  # `src/asset_pipeline/vendor` instead (SHA-256 written in Crystal, which
  # needs Crystal 1.21 or newer), so that the app links no OpenSSL.
  {% if flag?(:without_openssl) %}
    alias SHA256Digest = AssetPipeline::Beryl::Crypto::V1::SHA256
  {% else %}
    alias SHA256Digest = ::Digest::SHA256
  {% end %}
end
