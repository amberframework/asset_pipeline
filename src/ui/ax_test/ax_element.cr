# Crystal wrapper around an AXUIElementRef. Reads accessibility attributes
# (role, label, value, children) and performs actions (press, click, focus).

{% if flag?(:macos) %}

require "./ax_ffi"

module UI::AXTest
  # Wraps an AXUIElementRef with a Crystal-friendly API for querying
  # accessibility attributes and performing actions.
  #
  # Example:
  #   element = Element.new(ax_ref)
  #   puts element.role       # => "AXButton"
  #   puts element.label      # => "Browse for audio save location"
  #   element.click           # performs AXPress action
  class Element
    getter ref : LibAX::AXUIElementRef

    def initialize(@ref : LibAX::AXUIElementRef)
    end

    # --- Attribute Readers ---

    # The accessibility role (e.g., "AXButton", "AXTextField", "AXWindow")
    def role : String
      read_string_attribute("AXRole") || "unknown"
    end

    # The element's title (window title, button title, etc.)
    def title : String?
      read_string_attribute("AXTitle")
    end

    # The element's current value
    def value : String?
      read_string_attribute("AXValue")
    end

    # The accessibility label (set via setAccessibilityLabel: in AppKit)
    def label : String?
      read_string_attribute("AXDescription")
    end

    # The accessibility help text
    def help : String?
      read_string_attribute("AXHelp")
    end

    # The subrole (e.g., "AXCloseButton", "AXZoomButton")
    def subrole : String?
      read_string_attribute("AXSubrole")
    end

    # The accessibility identifier (set via setAccessibilityIdentifier: in AppKit
    # / UI::View#test_id in this framework). Stable across locales.
    def identifier : String?
      read_string_attribute("AXIdentifier")
    end

    # Whether the element is enabled
    def enabled? : Bool
      read_bool_attribute("AXEnabled") != false
    end

    # Whether the element has keyboard focus
    def focused? : Bool
      read_bool_attribute("AXFocused") == true
    end

    # --- Geometry (A2) ---

    # The element's top-left position in screen coordinates (CGPoint).
    # Reads kAXPositionAttribute and unboxes the AXValueRef.
    # Returns nil if the attribute is unsupported or empty.
    def position : NamedTuple(x: Float64, y: Float64)?
      pt = read_cgpoint_attribute("AXPosition")
      return nil unless pt
      {x: pt.x, y: pt.y}
    end

    # The element's size in screen points (CGSize).
    # Reads kAXSizeAttribute and unboxes the AXValueRef.
    # Returns nil if the attribute is unsupported or empty.
    def size : NamedTuple(width: Float64, height: Float64)?
      sz = read_cgsize_attribute("AXSize")
      return nil unless sz
      {width: sz.width, height: sz.height}
    end

    # The element's screen-space rectangle, composed from position + size.
    # Returns nil if either component is unavailable.
    def frame : NamedTuple(x: Float64, y: Float64, width: Float64, height: Float64)?
      pos = position
      sz = size
      return nil unless pos && sz
      {x: pos[:x], y: pos[:y], width: sz[:width], height: sz[:height]}
    end

    # Alias for `#frame` documenting that AX position/size are already
    # in screen coordinates on macOS. Used by the screenshot cropper.
    # (A7)
    def bounds_in_screen : NamedTuple(x: Float64, y: Float64, width: Float64, height: Float64)?
      frame
    end

    # --- Children & Windows ---

    # All child elements
    def children : Array(Element)
      read_element_array_attribute("AXChildren")
    end

    # All windows (only meaningful on application-level elements)
    def windows : Array(Element)
      read_element_array_attribute("AXWindows")
    end

    # --- Value Writers (A3) ---

    # Write `kAXValueAttribute` on this element. The Crystal value is
    # boxed into the right CoreFoundation / CoreGraphics type based on
    # its Crystal runtime type:
    #
    #   * Float32/Float64 → CFNumber (Float64)
    #   * Int32/Int64/Int  → CFNumber (SInt64)
    #   * String           → CFString
    #   * Bool             → kCFBooleanTrue / kCFBooleanFalse
    #
    # Used to drive sliders (numeric values), text fields (string), and
    # checkboxes (bool). Returns true on AXError.success, false otherwise.
    #
    # Requires the target process to have an accessible UIElement that
    # advertises a settable kAXValueAttribute (`isAttributeSettable`).
    def set_value(value : Float64 | Float32 | Int32 | Int64 | Int | String | Bool) : Bool
      set_attribute("AXValue", value)
    end

    # Write an arbitrary AX attribute. Internal escape hatch used by
    # set_value, focus!, and the App-level resize helper.
    def set_attribute(attr_name : String, value : Float64 | Float32 | Int32 | Int64 | Int | String | Bool) : Bool
      attr_cf = cfstring(attr_name)
      cf_value = box_value(value)
      err = LibAX.AXUIElementSetAttributeValue(@ref, attr_cf, cf_value)
      LibCF.CFRelease(attr_cf)
      # CFString / CFNumber boxes we created must be released; CFBoolean
      # constants are global singletons — releasing them is a no-op but
      # not harmful (CFRelease is reference-counted).
      LibCF.CFRelease(cf_value) unless cf_value.null? || value.is_a?(Bool)
      err == LibAX::AXErrorSuccess
    end

    # Box a Crystal value into a CFTypeRef appropriate for
    # AXUIElementSetAttributeValue. Caller owns the returned ref except
    # for booleans (global singletons, do not release).
    private def box_value(value) : Void*
      case value
      when Bool
        value ? LibCF.kCFBooleanTrue : LibCF.kCFBooleanFalse
      when Float64
        v = value.to_f64
        LibCF.CFNumberCreate(Pointer(Void).null, LibCF::CFNumberFloat64Type, pointerof(v).as(Void*))
      when Float32
        v = value.to_f32
        LibCF.CFNumberCreate(Pointer(Void).null, LibCF::CFNumberFloat32Type, pointerof(v).as(Void*))
      when Int64
        v = value.to_i64
        LibCF.CFNumberCreate(Pointer(Void).null, LibCF::CFNumberSInt64Type, pointerof(v).as(Void*))
      when Int32, Int
        v = value.to_i32
        LibCF.CFNumberCreate(Pointer(Void).null, LibCF::CFNumberSInt32Type, pointerof(v).as(Void*))
      when String
        cfstring(value)
      else
        Pointer(Void).null
      end
    end

    # Box a CGSize into an AXValueRef. Caller must CFRelease.
    private def box_cgsize(width : Float64, height : Float64) : Void*
      sz = CGSize.new(width, height)
      LibAX.AXValueCreate(LibAX::AXValueCGSizeType, pointerof(sz).as(Void*))
    end

    # Box a CGPoint into an AXValueRef. Caller must CFRelease.
    private def box_cgpoint(x : Float64, y : Float64) : Void*
      pt = CGPoint.new(x, y)
      LibAX.AXValueCreate(LibAX::AXValueCGPointType, pointerof(pt).as(Void*))
    end

    # Set `kAXSizeAttribute` to a new CGSize. Used by App#resize_window.
    def set_size(width : Float64, height : Float64) : Bool
      attr_cf = cfstring("AXSize")
      sz_ref = box_cgsize(width, height)
      err = LibAX.AXUIElementSetAttributeValue(@ref, attr_cf, sz_ref)
      LibCF.CFRelease(attr_cf)
      LibCF.CFRelease(sz_ref)
      err == LibAX::AXErrorSuccess
    end

    # Set `kAXPositionAttribute` to a new CGPoint.
    def set_position(x : Float64, y : Float64) : Bool
      attr_cf = cfstring("AXPosition")
      pt_ref = box_cgpoint(x, y)
      err = LibAX.AXUIElementSetAttributeValue(@ref, attr_cf, pt_ref)
      LibCF.CFRelease(attr_cf)
      LibCF.CFRelease(pt_ref)
      err == LibAX::AXErrorSuccess
    end

    # --- Focus (A4) ---

    # Set `kAXFocusedAttribute` to true on this element. Useful for
    # driving keyboard-only navigation tests without simulating clicks.
    # Returns true on AXError.success.
    def focus! : Bool
      attr_cf = cfstring("AXFocused")
      err = LibAX.AXUIElementSetAttributeValue(@ref, attr_cf, LibCF.kCFBooleanTrue)
      LibCF.CFRelease(attr_cf)
      err == LibAX::AXErrorSuccess
    end

    # --- Actions ---

    # Click/press the element
    def click
      action_str = cfstring("AXPress")
      LibAX.AXUIElementPerformAction(@ref, action_str)
      LibCF.CFRelease(action_str)
    end

    # List available action names
    def action_names : Array(String)
      names_ref = Pointer(Void).null
      err = LibAX.AXUIElementCopyActionNames(@ref, pointerof(names_ref))
      return [] of String unless err == LibAX::AXErrorSuccess && !names_ref.null?

      result = cfarray_to_strings(names_ref)
      LibCF.CFRelease(names_ref)
      result
    end

    # --- Search ---

    # Find the first descendant matching the given criteria.
    # Searches breadth-first through the accessibility tree.
    def find(role : String? = nil, label : String? = nil, title : String? = nil, identifier : String? = nil, max_depth : Int32 = 10) : Element?
      return nil if max_depth <= 0
      children.each do |child|
        matches = true
        matches = false if role && child.role != role
        matches = false if label && child.label != label
        matches = false if title && child.title != title
        matches = false if identifier && child.identifier != identifier
        return child if matches

        if found = child.find(role: role, label: label, title: title, identifier: identifier, max_depth: max_depth - 1)
          return found
        end
      end
      nil
    end

    # Find a descendant by accessibility identifier (AXIdentifier).
    # Returns nil if no match is found. Convenience wrapper around
    # `find(identifier: ...)` for the common test_id lookup case.
    def find_by_id(identifier : String, max_depth : Int32 = 10) : Element?
      find(identifier: identifier, max_depth: max_depth)
    end

    # Find a descendant by accessibility identifier, raising if not found.
    def find_by_id!(identifier : String, max_depth : Int32 = 10) : Element
      el = find_by_id(identifier, max_depth: max_depth)
      raise "AXTest: no element with AXIdentifier=#{identifier.inspect} found within depth #{max_depth}" unless el
      el
    end

    # Find ALL descendants matching the given criteria.
    def find_all(role : String? = nil, label : String? = nil, title : String? = nil, identifier : String? = nil, max_depth : Int32 = 10) : Array(Element)
      return [] of Element if max_depth <= 0
      results = [] of Element
      children.each do |child|
        matches = true
        matches = false if role && child.role != role
        matches = false if label && child.label != label
        matches = false if title && child.title != title
        matches = false if identifier && child.identifier != identifier
        results << child if matches

        results.concat(child.find_all(role: role, label: label, title: title, identifier: identifier, max_depth: max_depth - 1))
      end
      results
    end

    # --- Debugging ---

    # Print the accessibility tree rooted at this element (for debugging)
    def dump(indent : Int32 = 0)
      prefix = "  " * indent
      r = role
      t = title
      l = label
      v = value
      parts = [r]
      parts << "title=#{t}" if t
      parts << "label=#{l}" if l
      parts << "value=#{v}" if v
      puts "#{prefix}#{parts.join(" | ")}"
      children.each { |c| c.dump(indent + 1) }
    end

    # --- Private Helpers ---

    private def read_string_attribute(attr_name : String) : String?
      attr_cf = cfstring(attr_name)
      value_ref = Pointer(Void).null
      err = LibAX.AXUIElementCopyAttributeValue(@ref, attr_cf, pointerof(value_ref))
      LibCF.CFRelease(attr_cf)

      return nil unless err == LibAX::AXErrorSuccess && !value_ref.null?

      # Check if it's a CFString
      if LibCF.CFGetTypeID(value_ref) == LibCF.CFStringGetTypeID
        result = cfstring_to_crystal(value_ref)
        LibCF.CFRelease(value_ref)
        result
      else
        LibCF.CFRelease(value_ref)
        nil
      end
    end

    private def read_bool_attribute(attr_name : String) : Bool?
      attr_cf = cfstring(attr_name)
      value_ref = Pointer(Void).null
      err = LibAX.AXUIElementCopyAttributeValue(@ref, attr_cf, pointerof(value_ref))
      LibCF.CFRelease(attr_cf)

      return nil unless err == LibAX::AXErrorSuccess && !value_ref.null?

      if LibCF.CFGetTypeID(value_ref) == LibCF.CFBooleanGetTypeID
        result = LibCF.CFBooleanGetValue(value_ref) != 0
        LibCF.CFRelease(value_ref)
        result
      else
        LibCF.CFRelease(value_ref)
        nil
      end
    end

    # Read a kAX*-typed attribute that wraps a CGPoint via AXValueRef.
    private def read_cgpoint_attribute(attr_name : String) : CGPoint?
      attr_cf = cfstring(attr_name)
      value_ref = Pointer(Void).null
      err = LibAX.AXUIElementCopyAttributeValue(@ref, attr_cf, pointerof(value_ref))
      LibCF.CFRelease(attr_cf)
      return nil unless err == LibAX::AXErrorSuccess && !value_ref.null?

      pt = CGPoint.new
      ok = LibAX.AXValueGetValue(value_ref, LibAX::AXValueCGPointType, pointerof(pt).as(Void*))
      LibCF.CFRelease(value_ref)
      ok != 0 ? pt : nil
    end

    # Read a kAX*-typed attribute that wraps a CGSize via AXValueRef.
    private def read_cgsize_attribute(attr_name : String) : CGSize?
      attr_cf = cfstring(attr_name)
      value_ref = Pointer(Void).null
      err = LibAX.AXUIElementCopyAttributeValue(@ref, attr_cf, pointerof(value_ref))
      LibCF.CFRelease(attr_cf)
      return nil unless err == LibAX::AXErrorSuccess && !value_ref.null?

      sz = CGSize.new
      ok = LibAX.AXValueGetValue(value_ref, LibAX::AXValueCGSizeType, pointerof(sz).as(Void*))
      LibCF.CFRelease(value_ref)
      ok != 0 ? sz : nil
    end

    private def read_element_array_attribute(attr_name : String) : Array(Element)
      attr_cf = cfstring(attr_name)
      value_ref = Pointer(Void).null
      err = LibAX.AXUIElementCopyAttributeValue(@ref, attr_cf, pointerof(value_ref))
      LibCF.CFRelease(attr_cf)

      return [] of Element unless err == LibAX::AXErrorSuccess && !value_ref.null?

      if LibCF.CFGetTypeID(value_ref) == LibCF.CFArrayGetTypeID
        count = LibCF.CFArrayGetCount(value_ref)
        result = Array(Element).new(count.to_i32)
        count.times do |i|
          child_ref = LibCF.CFArrayGetValueAtIndex(value_ref, i)
          unless child_ref.null?
            # Retain the child ref since the array will be released
            LibCF.CFRetain(child_ref)
            result << Element.new(child_ref.as(LibAX::AXUIElementRef))
          end
        end
        LibCF.CFRelease(value_ref)
        result
      else
        LibCF.CFRelease(value_ref)
        [] of Element
      end
    end

    # Create a CFString from a Crystal String
    private def cfstring(str : String) : Void*
      LibCF.CFStringCreateWithCString(Pointer(Void).null, str.to_unsafe, LibCF::CFStringEncodingUTF8)
    end

    # Convert a CFString to a Crystal String
    private def cfstring_to_crystal(cf_str : Void*) : String?
      # Try the fast path first (direct pointer)
      cstr = LibCF.CFStringGetCStringPtr(cf_str, LibCF::CFStringEncodingUTF8)
      if !cstr.null?
        return String.new(cstr)
      end

      # Slow path: copy to buffer
      length = LibCF.CFStringGetLength(cf_str)
      buffer_size = length * 4 + 1 # UTF-8 can be up to 4 bytes per char
      buffer = Bytes.new(buffer_size.to_i32, 0_u8)
      success = LibCF.CFStringGetCString(cf_str, buffer.to_unsafe, buffer_size, LibCF::CFStringEncodingUTF8)
      if success != 0
        String.new(buffer.to_unsafe)
      else
        nil
      end
    end

    private def cfarray_to_strings(cf_array : Void*) : Array(String)
      count = LibCF.CFArrayGetCount(cf_array)
      result = Array(String).new(count.to_i32)
      count.times do |i|
        item = LibCF.CFArrayGetValueAtIndex(cf_array, i)
        unless item.null?
          if str = cfstring_to_crystal(item)
            result << str
          end
        end
      end
      result
    end
  end
end

{% end %}
