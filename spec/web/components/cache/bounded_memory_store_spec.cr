require "../../spec_helper"
require "../../../../src/components/cache/memory_cache_store"

private OVERHEAD = Components::Cache::MemoryCacheStore::ENTRY_OVERHEAD_BYTES

private def store_of(maximum_bytes : Int64) : Components::Cache::MemoryCacheStore
  Components::Cache::MemoryCacheStore.new(maximum_bytes)
end

describe Components::Cache::MemoryCacheStore do
  it "defaults to a 32 MiB budget" do
    Components::Cache::MemoryCacheStore.new.maximum_bytes.should eq(32 * 1024 * 1024)
  end

  describe "the byte budget" do
    it "counts every key, payload and entry charge" do
      store = store_of(10_000_i64)
      store.write("key", "value")
      store.write_bytes("bin", "12345".to_slice)
      store.stored_bytes.should eq(3 + 5 + OVERHEAD + 3 + 5 + OVERHEAD)
    end

    it "counts each nested layer in the one budget" do
      store = store_of(10_000_i64)
      store.write("page:1", "p" * 1000)
      store.write("section:1", "s" * 400)
      store.write("row:1", "r" * 100)
      store.stored_bytes.should eq(1000 + 400 + 100 + "page:1".bytesize + "section:1".bytesize + "row:1".bytesize + 3 * OVERHEAD)
    end

    it "evicts the least recently used entry of any layer past the limit" do
      store = store_of(1000_i64)
      store.write("row:1", "r" * 200)
      store.write("section:1", "s" * 200)
      store.read("row:1")
      store.write("page:1", "p" * 400)
      store.exists?("section:1").should be_false
      store.exists?("row:1").should be_true
      store.exists?("page:1").should be_true
      store.stored_bytes.should be <= 1000
    end

    it "keeps the count right when an entry is replaced or deleted" do
      store = store_of(10_000_i64)
      store.write("key", "short")
      store.write("key", "a much longer value")
      store.stored_bytes.should eq(3 + "a much longer value".bytesize + OVERHEAD)
      store.delete("key")
      store.stored_bytes.should eq(0)
    end

    it "refuses an entry larger than the whole budget and drops the old value" do
      store = store_of(500_i64)
      store.write("key", "small")
      store.write("key", "x" * 1000)
      store.exists?("key").should be_false
      store.stored_bytes.should eq(0)
    end

    it "stores nothing when the budget is zero" do
      store = store_of(0_i64)
      store.fetch("key") { "value" }.should eq("value")
      store.exists?("key").should be_false
    end

    it "drops an expired entry from the count" do
      store = store_of(10_000_i64)
      store.write("key", "value", 1.millisecond)
      sleep 5.milliseconds
      store.exists?("key").should be_false
      store.stored_bytes.should eq(0)
    end
  end

  describe "byte payloads" do
    it "round-trips binary bytes without interpreting them" do
      store = store_of(10_000_i64)
      payload = Bytes[0xff, 0x00, 0xc3, 0x28]
      store.write_bytes("bin", payload)
      store.read_bytes("bin").should eq(payload)
    end

    it "keeps its own copy" do
      store = store_of(10_000_i64)
      payload = Bytes[1, 2, 3]
      store.write_bytes("bin", payload)
      payload[0] = 9_u8
      store.read_bytes("bin").should eq(Bytes[1, 2, 3])
    end

    it "reads a string entry as bytes and a byte entry as a string" do
      store = store_of(10_000_i64)
      store.write("text", "hello")
      store.read_bytes("text").should eq("hello".to_slice)
      store.write_bytes("bin", "world".to_slice)
      store.read("bin").should eq("world")
    end
  end

  describe "the stale-write guard" do
    it "does not store what a render saw before a write cleared the key" do
      store = store_of(10_000_i64)
      value = store.fetch("key") do
        store.delete("key")
        "stale"
      end
      value.should eq("stale")
      store.exists?("key").should be_false
    end

    it "does not store after a numbered delete covered the key" do
      store = store_of(10_000_i64)
      store.fetch("page:index:3") do
        store.delete_numbered_from("page:index:", 1)
        "stale"
      end
      store.exists?("page:index:3").should be_false
    end

    it "does not store after the whole store was cleared" do
      store = store_of(10_000_i64)
      store.fetch("key") do
        store.clear
        "stale"
      end
      store.exists?("key").should be_false
    end

    it "still stores when a different key was cleared" do
      store = store_of(10_000_i64)
      store.fetch("key") do
        store.delete("other")
        "fresh"
      end
      store.read("key").should eq("fresh")
    end

    it "refuses a byte replacement for a key cleared since the generation" do
      store = store_of(10_000_i64)
      store.write_bytes("key", "plain".to_slice)
      generation = store.current_generation
      store.delete("key")
      store.write_bytes("key", "rebuilt".to_slice)
      store.replace_bytes_unless_cleared("key", "old upgrade".to_slice, generation).should be_false
      store.read_bytes("key").should eq("rebuilt".to_slice)
    end

    it "replaces when nothing cleared the key" do
      store = store_of(10_000_i64)
      store.write_bytes("key", "plain".to_slice)
      generation = store.current_generation
      store.replace_bytes_unless_cleared("key", "upgraded".to_slice, generation).should be_true
      store.read_bytes("key").should eq("upgraded".to_slice)
    end
  end

  describe "#delete_numbered_from" do
    it "keeps pages before the first number and removes the rest" do
      store = store_of(10_000_i64)
      (1..3).each { |number| store.write("page:index:#{number}", "x") }
      store.write("page:other:9", "x")
      store.delete_numbered_from("page:index:", 2).sort.should eq(["page:index:2", "page:index:3"])
      store.exists?("page:index:1").should be_true
      store.exists?("page:other:9").should be_true
    end
  end

  describe "#delete_dependents" do
    it "removes exactly the entries recorded as depending on the key" do
      store = store_of(10_000_i64)
      store.fetch_with_dependencies("parent:deps:1", ["pet:1"]) { "parent" }
      store.fetch_with_dependencies("other:deps:2", ["pet:2"]) { "other" }
      store.write("pet:1", "leaf")
      store.delete_dependents("pet:1").should eq(["parent:deps:1"])
      store.exists?("parent:deps:1").should be_false
      store.exists?("other:deps:2").should be_true
      store.exists?("pet:1").should be_true
    end

    it "does not match a key that merely starts with the dependency" do
      store = store_of(10_000_i64)
      store.fetch_with_dependencies("a", ["pet:10"]) { "a" }
      store.delete_dependents("pet:1").should be_empty
      store.exists?("a").should be_true
    end

    it "clears through the owner of a removed entry" do
      store = store_of(10_000_i64)
      store.fetch_with_dependencies("section:deps:x", ["row:1"], owner_key: "section") { "s" }
      store.fetch_with_dependencies("page:deps:y", ["section"]) { "p" }
      store.delete_dependents("row:1").sort.should eq(["page:deps:y", "section:deps:x"])
    end

    it "drops an evicted entry from the index and counts its dependency bytes" do
      store = store_of(10_000_i64)
      store.fetch_with_dependencies("a", ["dep"]) { "v" }
      store.stored_bytes.should eq(1 + 1 + OVERHEAD + 3 + Components::Cache::MemoryCacheStore::DEPENDENCY_OVERHEAD_BYTES)
      store.delete("a")
      store.delete_dependents("dep").should be_empty
    end

    it "does not store a dependent whose dependency was cleared while rendering" do
      store = store_of(10_000_i64)
      store.fetch_with_dependencies("a", ["dep"]) do
        store.delete_dependents("dep")
        "stale"
      end
      store.exists?("a").should be_false
    end
  end
end
