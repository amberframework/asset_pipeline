require "../../spec_helper"
require "../../../../src/components/base/stateless_component"
require "../../../../src/components/cache/cacheable"
require "../../../../src/components/cache/memory_cache_store"

module DependencyClearingFixtures
  class Row < Components::StatelessComponent
    def initialize(@label : String)
      super()
    end

    def cache_key : String
      "row:#{@label}"
    end

    def render_content : String
      @label
    end

    def full_key_with(deps : Array(Row)) : String
      cache_with_dependencies(deps) { @label }
      "#{cache_key}:deps:#{deps.map(&.cache_key).join(":")}"
    end
  end

  class FragmentUser < Components::StatelessComponent
    def render_content : String
      cache_fragment("fragment:shared") do
        io << "fragment"
      end
    end
  end
end

private def new_store : Components::Cache::MemoryCacheStore
  store = Components::Cache::MemoryCacheStore.new
  Components::Cache::Cacheable.cache_store = store
  Components::Cache::Cacheable.cache_enabled = true
  store
end

describe Components::Cache::Cacheable do
  describe "#invalidate_dependent_caches" do
    it "removes exactly the entries that depend on the changed record" do
      store = new_store
      leaf = DependencyClearingFixtures::Row.new("leaf")
      other_leaf = DependencyClearingFixtures::Row.new("other_leaf")
      dependent = DependencyClearingFixtures::Row.new("dependent")
      bystander = DependencyClearingFixtures::Row.new("bystander")
      dependent_key = dependent.full_key_with([leaf])
      bystander_key = bystander.full_key_with([other_leaf])
      leaf.cache { "leaf html" }

      leaf.invalidate_dependent_caches

      store.exists?(dependent_key).should be_false
      store.exists?(bystander_key).should be_true
      store.exists?(leaf.cache_key).should be_true
    end

    it "clears up through nested dependents" do
      store = new_store
      leaf = DependencyClearingFixtures::Row.new("leaf")
      section = DependencyClearingFixtures::Row.new("section")
      page = DependencyClearingFixtures::Row.new("page")
      section_key = section.full_key_with([leaf])
      page_key = page.full_key_with([section])

      leaf.invalidate_dependent_caches

      store.exists?(section_key).should be_false
      store.exists?(page_key).should be_false
    end

    it "clears its own dependency-based variants through #invalidate_cache" do
      store = new_store
      leaf = DependencyClearingFixtures::Row.new("leaf")
      owner = DependencyClearingFixtures::Row.new("owner")
      owner_variant = owner.full_key_with([leaf])
      owner.invalidate_cache
      store.exists?(owner_variant).should be_false
    end
  end

  describe "#cache_with_dependency_keys" do
    it "clears when a record that is not a component changes" do
      store = new_store
      row = DependencyClearingFixtures::Row.new("list")
      row.cache_with_dependency_keys(["pet:1"]) { "html" }
      store.stats["entries"].should eq(1)
      store.delete_dependents("pet:1")
      store.stats["entries"].should eq(0)
    end
  end

  describe "cache_fragment" do
    it "resolves the store through the full constant path" do
      store = new_store
      DependencyClearingFixtures::FragmentUser.new.render_content.should eq("fragment")
      store.read("fragment:shared").should eq("fragment")
    end
  end

  describe "defaults" do
    it "has a default store with no setup and no time limit" do
      Components::Cache::MemoryCacheStore.new.maximum_bytes.should eq(32_i64 * 1024 * 1024)
      store = new_store
      store.should be(Components::Cache::Cacheable.cache_store)
      Components::Cache::Cacheable.default_expires_in.should be_nil
    end
  end
end
