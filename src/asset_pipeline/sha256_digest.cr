# Beryl's SHA-256 is written in Crystal and needs Crystal 1.21 or newer; on
# those compilers it is the default, so fingerprints, Subresource Integrity
# values and page-cache keys link no OpenSSL. Older compilers keep
# Crystal's `Digest::SHA256`, which calls OpenSSL.
{% if flag?(:without_openssl) || compare_versions(Crystal::VERSION, "1.21.0") >= 0 %}
  require "./vendor/beryl/crypto"
{% else %}
  require "digest/sha256"
{% end %}

module AssetPipeline
  # The SHA-256 that fingerprints assets, computes Subresource Integrity
  # values and keys the page cache. Both choices are `::Digest` subclasses
  # and give the same bytes.
  #
  # On Crystal 1.21 or newer (and with `-Dwithout_openssl`) it is the pinned
  # copy of Beryl under `src/asset_pipeline/vendor`, so an app links no
  # OpenSSL for it. On older compilers it is Crystal's `Digest::SHA256`.
  {% if flag?(:without_openssl) || compare_versions(Crystal::VERSION, "1.21.0") >= 0 %}
    alias SHA256Digest = AssetPipeline::Beryl::Crypto::V1::SHA256
  {% else %}
    alias SHA256Digest = ::Digest::SHA256
  {% end %}
end
