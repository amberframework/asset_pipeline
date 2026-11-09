require "../../spec_helper"
require "log/spec"
require "../../../../src/components/base/stateless_component"
require "../../../../src/components/base/stateless_view"
require "../../../../src/components/cache/memory_cache_store"

module StatelessViewFixtures
  struct SiteFooter < Components::StatelessView
    ECR.def_to_s "spec/web/fixtures/stateless_views/site_footer.ecr"
  end

  struct Banner < Components::StatelessView
    def initialize(@label : String = "default banner")
    end

    ECR.def_to_s "spec/web/fixtures/stateless_views/labeled.ecr"
  end

  @[Components::SkipStartupRender]
  struct RenderedPerRequest < Components::StatelessView
    def to_s(__io__ : IO) : Nil
      __io__ << "per request"
    end
  end

  struct PetRow < Components::StatelessView
    def initialize(@label : String)
    end

    ECR.def_to_s "spec/web/fixtures/stateless_views/labeled.ecr"
  end

  struct ProfileRow < Components::StatelessView
    def initialize(@record_id : Int64, @record : Hash(String, String))
    end

    def cache_key : String
      "row:profile:#{@record_id}"
    end

    def to_s(__io__ : IO) : Nil
      __io__ << @record["name"]
    end
  end

  abstract struct WithSharedLayout < Components::StatelessView
  end

  struct FooterInSharedLayout < WithSharedLayout
    ECR.def_to_s "spec/web/fixtures/stateless_views/site_footer.ecr"
  end

  struct Generic(T) < Components::StatelessView
    def to_s(__io__ : IO) : Nil
      __io__ << T.name
    end
  end

  struct FailsAtStartup < Components::StatelessView
    def to_s(__io__ : IO) : Nil
      raise "cannot render at start-up"
    end
  end

  class ClassRow < Components::StatelessComponent
    def initialize(@row_id : Int64)
      super()
    end

    def cache_key : String
      "row:#{@row_id}"
    end

    def render_content : String
      "row"
    end
  end

  struct StructRow < Components::StatelessView
    def initialize(@row_id : Int64)
    end

    def cache_key : String
      "row:#{@row_id}"
    end

    def to_s(__io__ : IO) : Nil
      __io__ << "row"
    end
  end
end

private def warmed_names : Array(String)
  Components::StatelessView.warm_all.list_of_warmed_view_names
end

describe Components::StatelessView do
  before_each do
    Components::Cache::Cacheable.cache_store = Components::Cache::MemoryCacheStore.new
    Components::Cache::Cacheable.cache_enabled = true
  end

  describe "rendering" do
    it "renders through ECR" do
      StatelessViewFixtures::PetRow.new("Rex").to_s.should eq("<p>Rex</p>\n")
    end

    it "gives safe HTML from #render" do
      StatelessViewFixtures::SiteFooter.new.render.should be_a(Components::SafeHTML)
    end
  end

  describe ".warm_all" do
    it "renders concrete views with a no-argument constructor" do
      names = warmed_names
      names.should contain("StatelessViewFixtures::SiteFooter")
      names.should contain("StatelessViewFixtures::Banner")
      names.should contain("StatelessViewFixtures::FooterInSharedLayout")
    end

    it "leaves out a view opted out by annotation" do
      warmed_names.should_not contain("StatelessViewFixtures::RenderedPerRequest")
      StatelessViewFixtures::RenderedPerRequest.held_render.should be_nil
    end

    it "leaves out a view that takes constructor arguments" do
      warmed_names.should_not contain("StatelessViewFixtures::PetRow")
      warmed_names.should_not contain("StatelessViewFixtures::ProfileRow")
      StatelessViewFixtures::PetRow.held_render.should be_nil
    end

    it "leaves out abstract and generic views" do
      warmed_names.should_not contain("StatelessViewFixtures::WithSharedLayout")
      warmed_names.any?(&.includes?("Generic")).should be_false
    end

    it "reports a view that cannot render and keeps warming the rest" do
      report = Components::StatelessView.warm_all
      report.list_of_failed_view_names.should contain("StatelessViewFixtures::FailsAtStartup")
      report.list_of_warmed_view_names.should contain("StatelessViewFixtures::SiteFooter")
      report.held_bytes.should be > 0
    end

    it "reports through Log" do
      Log.capture("asset_pipeline.stateless_view") do |logs|
        Components::StatelessView.warm_all
        logs.check(:error, /cannot render|could not render/)
        logs.next(:info, /rendered \d+ stateless views/)
      end
    end

    it "holds the bytes outside the byte budget for the life of the process" do
      Components::StatelessView.warm_all
      Components::Cache::Cacheable.cache_store = Components::Cache::MemoryCacheStore.new(0_i64)
      StatelessViewFixtures::SiteFooter.new.cached_html.should eq("<footer>Site footer</footer>\n")
      StatelessViewFixtures::SiteFooter.new.cached_html.should be(StatelessViewFixtures::SiteFooter.held_render.not_nil!.html)
    end

    it "does not hand held bytes to an instance built with other field values" do
      Components::StatelessView.warm_all
      StatelessViewFixtures::Banner.new.cached_html.should eq("<p>default banner</p>\n")
      StatelessViewFixtures::Banner.new("other").cached_html.should eq("<p>other</p>\n")
    end
  end

  describe "#cache_key" do
    it "is the type name for a view with no fields" do
      StatelessViewFixtures::SiteFooter.new.cache_key.should eq("StatelessViewFixtures::SiteFooter")
    end

    it "digests the fields of a view that has them" do
      first = StatelessViewFixtures::PetRow.new("Rex").cache_key
      first.should eq(StatelessViewFixtures::PetRow.new("Rex").cache_key)
      first.should_not eq(StatelessViewFixtures::PetRow.new("Fido").cache_key)
      first.should start_with("StatelessViewFixtures::PetRow:")
    end

    it "lets a view holding a record define its own key" do
      view = StatelessViewFixtures::ProfileRow.new(7_i64, {"name" => "Rex"})
      view.cache_key.should eq("row:profile:7")
      view.cached_html.should eq("Rex")
    end
  end

  describe "#cached_html" do
    it "renders straight through when caching is off" do
      Components::Cache::Cacheable.cache_enabled = false
      StatelessViewFixtures::PetRow.new("Rex").cached_html.should eq("<p>Rex</p>\n")
    end

    it "stores a dynamic view's output in the store" do
      store = Components::Cache::MemoryCacheStore.new
      Components::Cache::Cacheable.cache_store = store
      view = StatelessViewFixtures::PetRow.new("Rex")
      view.cached_html
      store.exists?(view.cache_key).should be_true
    end
  end

  describe "allocation" do
    it "allocates less than the class path on a hit" do
      iterations = 20_000
      sink = 0_i64

      before_class = GC.stats.total_bytes
      iterations.times { |index| sink += StatelessViewFixtures::ClassRow.new(index.to_i64).cache_key.bytesize }
      class_bytes = GC.stats.total_bytes - before_class

      before_struct = GC.stats.total_bytes
      iterations.times { |index| sink += StatelessViewFixtures::StructRow.new(index.to_i64).cache_key.bytesize }
      struct_bytes = GC.stats.total_bytes - before_struct

      sink.should be > 0
      struct_bytes.should be < class_bytes
    end
  end
end
