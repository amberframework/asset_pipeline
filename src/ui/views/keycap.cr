# Keyboard-key label with an explicit tactile surface style.

require "./label"

module UI
  # A semantic keyboard key. It remains a plain label on platforms that do
  # not implement the surface-craft renderer.
  class Keycap < Label
    property style : KeycapStyle = KeycapStyle::Sculpted

    def initialize(text : String, @style : KeycapStyle = KeycapStyle::Sculpted)
      super(text)
      self.font = Font.new(family: "monospace", size: 13.0, weight: :medium)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self.as(Label))
    end
  end
end
