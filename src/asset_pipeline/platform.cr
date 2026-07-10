# Compile-time platform-gating helpers for the asset_pipeline cross-platform UI.
# Part of the asset_pipeline shard.

module AssetPipeline
  # Platform-gate helpers for application code.
  #
  # Library code (anything under `src/ui/views/`, `src/ui/renderers/`)
  # continues to use raw `{% if flag?(:ios) %}` blocks because it sits
  # below the abstraction surface. Application code should reach for
  # `AssetPipeline::Platform.requires(:ios) { ... }` so it does not have
  # to learn Crystal macro syntax to express "this block needs -Dios."
  module Platform
    # Compile-time platform gate. Use in app code to assert that a block
    # is only entered on a specific platform target. If the build does
    # not have the matching `-D` flag, the macro raises a compile error
    # naming the missing flag.
    #
    # Example:
    #   AssetPipeline::Platform.requires(:ios) do
    #     trigger_haptic
    #   end
    #
    # On non-iOS builds this raises:
    #   "AssetPipeline::Platform.requires(:ios) - this code path needs -Dios."
    macro requires(platform_flag, &block)
      {% if flag?(platform_flag.id) %}
        {{ yield }}
      {% else %}
        {% raise "AssetPipeline::Platform.requires(:#{platform_flag.id}) - this code path needs -D#{platform_flag.id}. Either build with that flag, or guard with `\\{% if flag?(:#{platform_flag.id}) %}` and provide an else-branch." %}
      {% end %}
    end

    # Compile-time platform predicate. Use in `{% if Platform.has?(:ios) %}`
    # contexts when the macro form above is more verbose than needed.
    macro has?(platform_flag)
      {% if flag?(platform_flag.id) %}
        true
      {% else %}
        false
      {% end %}
    end
  end
end
