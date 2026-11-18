# Control probe for scripts/check_default_require_linkage.rb: the same require
# plus one direct Regex match, so the linkage check is shown to detect PCRE2.

require "../../../src/asset_pipeline"

print AssetPipeline::ImportMap.new.name
print "HelloController".matches?(/Controller\z/)
