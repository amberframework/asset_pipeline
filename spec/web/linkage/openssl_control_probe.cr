# Control probe for scripts/check_default_require_linkage.rb: the same require
# plus Crystal's OpenSSL-backed SHA-256, so the linkage check is shown to
# detect OpenSSL.

require "digest/sha256"
require "../../../src/asset_pipeline"

print AssetPipeline::ImportMap.new.name
print Digest::SHA256.hexdigest("control")
