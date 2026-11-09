require "../../spec_helper"
require "../../../../src/components/cache/redis_cache_store"

describe Components::Cache::RedisCacheStore do
  describe "#clear" do
    it "removes every entry under its prefix" do
      store = Components::Cache::RedisCacheStore.new("one:")
      store.write("first", "stored")
      store.write("second", "stored")

      store.clear

      store.read("first").should be_nil
      store.read("second").should be_nil
    end
  end
end
