# Prints cache keys for the two-process stability spec, one per line.
require "../../../src/components/elements/base/html_element"
require "../../../src/components/base/stateless_component"
require "../../../src/components/base/stateless_view"

struct StableKeyView < Components::StatelessView
  def initialize(@label : String, @count : Int32)
  end

  def to_s(__io__ : IO) : Nil
    __io__ << @label
  end
end

class StableKeyComponent < Components::StatelessComponent
  def render_content : String
    "stable"
  end
end

puts StableKeyComponent.new(color: "red", size: "2").cache_key
puts StableKeyView.new("label", 3).cache_key
