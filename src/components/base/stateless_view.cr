require "ecr"
require "log"
require "../safe/safe_html"
require "../cache/cacheable"
require "../cache/stable_digest"

module Components
  # Keeps a `StatelessView` out of the start-up render.
  #
  # ```
  # @[Components::SkipStartupRender]
  # struct RenderedAtRequestTime < Components::StatelessView
  #   ECR.def_to_s "src/views/clock.ecr"
  # end
  # ```
  annotation SkipStartupRender
  end

  # A view with no runtime state: typed fields in, HTML out through `ECR.def_to_s`.
  #
  # It is a struct with no attribute hash, child list or generated id, so building one allocates
  # only what its own fields hold. A hit in a list of rows pays for nothing it does not use.
  #
  # A concrete view whose constructor can be called with no arguments is discovered at compile
  # time. `.warm_all`, called once at boot, renders each one and holds its bytes in memory for the
  # life of the process, outside the byte budget, so traffic cannot evict the layout.
  # A view that takes constructor arguments is dynamic and is left to the page cache.
  #
  # ```
  # struct SiteFooter < Components::StatelessView
  #   ECR.def_to_s "src/views/components/site_footer.ecr"
  # end
  #
  # Components::StatelessView.warm_all # once, before the server accepts traffic
  # SiteFooter.new.cached_html         # the bytes rendered at boot
  # ```
  #
  # A `private` view with a no-argument constructor needs `@[Components::SkipStartupRender]`,
  # because the warmer is generated outside the file that can name it.
  abstract struct StatelessView
    Log = ::Log.for("asset_pipeline.stateless_view")

    # Bytes rendered at boot, with the key they were rendered under. Each view type has its own.
    class HeldRender
      getter cache_key : String
      getter html : String

      def initialize(@cache_key : String, @html : String)
      end
    end

    # What one `.warm_all` did.
    record WarmReport,
      list_of_warmed_view_names : Array(String),
      list_of_failed_view_names : Array(String),
      held_bytes : Int64,
      elapsed : Time::Span

    @@held_render = Atomic(HeldRender?).new(nil)

    # Writes the view's HTML to the IO. `ECR.def_to_s` defines it, and names the parameter this way.
    abstract def to_s(__io__ : IO) : Nil

    # The key this view's output is stored under: its type name when it has no fields, otherwise
    # the type name and a stable digest of its fields.
    #
    # A view holding a record or a collection defines its own key, usually from the record id, so
    # a write can delete it exactly. Without one, calling this is a compile error, because the
    # text form of such a field is not stable across processes.
    def cache_key : String
      {% if @type.instance_vars.empty? %}
        self.class.name
      {% else %}
        {% for field in @type.instance_vars %}
          {% unless field.type.union_types.all? { |t| t == String || t <= Number || t == Bool || t == Char || t == Symbol || t == Nil || t == Time || t < Enum } %}
            {% raise "#{@type} must define cache_key, because the text form of @#{field.name} : #{field.type} is not stable across processes" %}
          {% end %}
        {% end %}
        Cache::StableDigest.cache_key_for(self.class.name, { {% for field in @type.instance_vars %} @{{field.name}}.inspect, {% end %} })
      {% end %}
    end

    # The bytes rendered at boot when there are some for this key, otherwise the store's copy.
    def cached_html : String
      return to_s unless Cache::Cacheable.cache_enabled
      key = cache_key
      held_render = self.class.held_render
      return held_render.html if held_render && held_render.cache_key == key
      cache_store = Cache::Cacheable.cache_store
      return to_s unless cache_store
      cache_store.fetch(key) { to_s }
    end

    # The rendered output as `SafeHTML`.
    #
    # ECR writes `<%= value %>` as given, so a view escapes untrusted text with `#escape_text`.
    def render : SafeHTML
      SafeHTML.unsafe(to_s, reason: "#{self.class.name} renders author-written ECR through Components::StatelessView")
    end

    # HTML-escapes *value*, for `<%= escape_text(user_supplied) %>` in a template.
    protected def escape_text(value) : SafeHTML
      SafeHTML.escape(value.to_s)
    end

    # :nodoc:
    def self.held_render : HeldRender?
      @@held_render.get
    end

    # :nodoc:
    protected def self.hold(cache_key : String, html : String) : Nil
      @@held_render.set(HeldRender.new(cache_key, html))
    end

    # Renders every discovered view once and holds its bytes for the life of the process.
    #
    # A view that fails to render is logged and rendered per request afterward, so one bad view
    # does not stop the application starting.
    def self.warm_all : WarmReport
      list_of_warmed_view_names = [] of String
      list_of_failed_view_names = [] of String
      held_bytes = 0_i64
      elapsed = Time.measure do
        {% for view in Components::StatelessView.all_subclasses %}
          {% unless view.abstract? || !view.type_vars.empty? || view.annotation(Components::SkipStartupRender) %}
            {% constructors = [] of Nil %}
            {% for ancestor in [view] + view.ancestors %}
              {% if constructors.empty? %}
                {% constructors = ancestor.methods.select { |method| method.name == "initialize" } %}
              {% end %}
            {% end %}
            {% if constructors.empty? || constructors.any? { |method| method.visibility != :private && method.args.all? { |arg| !arg.default_value.is_a?(Nop) } && method.splat_index == nil && method.double_splat.is_a?(Nop) && method.block_arg.is_a?(Nop) } %}
              begin
                %view = {{view}}.new
                %html = %view.to_s
                {{view}}.hold(%view.cache_key, %html)
                held_bytes += %html.bytesize
                list_of_warmed_view_names << {{view.name.stringify}}
              rescue %error : Exception
                list_of_failed_view_names << {{view.name.stringify}}
                Log.error(exception: %error) { "could not render #{ {{view.name.stringify}} } at start-up" }
              end
            {% end %}
          {% end %}
        {% end %}
      end
      Log.info { "rendered #{list_of_warmed_view_names.size} stateless views (#{held_bytes} bytes) in #{elapsed.total_milliseconds.round(2)} ms" }
      WarmReport.new(list_of_warmed_view_names, list_of_failed_view_names, held_bytes, elapsed)
    end
  end
end
