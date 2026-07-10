# Raw FFI bindings for macOS Accessibility (AXUIElement) and CoreFoundation
# helpers. Used by the AXTest harness to read the running app's a11y tree.

{% if flag?(:macos) %}

# Raw FFI bindings for the macOS Accessibility API (AXUIElement) and
# CoreFoundation helpers needed to read accessibility tree attributes.
#
# These bindings wrap the C API from HIServices.framework (part of
# ApplicationServices) and CoreFoundation.framework.
#
# Link flags: -framework ApplicationServices -framework CoreFoundation

@[Link(framework: "ApplicationServices")]
@[Link(framework: "CoreFoundation")]
lib LibAX
  # --- AXUIElement Types ---
  type AXUIElementRef = Void*
  alias AXError = Int32

  # AXError constants
  AXErrorSuccess                = 0
  AXErrorFailure                = -25200
  AXErrorIllegalArgument        = -25201
  AXErrorInvalidUIElement       = -25202
  AXErrorInvalidUIElementObserver = -25203
  AXErrorCannotComplete         = -25204
  AXErrorAttributeUnsupported   = -25205
  AXErrorActionUnsupported      = -25206
  AXErrorNotificationUnsupported = -25207
  AXErrorNotImplemented         = -25208
  AXErrorNotificationAlreadyRegistered = -25209
  AXErrorNotificationNotRegistered = -25210
  AXErrorAPIDisabled            = -25211
  AXErrorNoValue                = -25212
  AXErrorParameterizedAttributeUnsupported = -25213
  AXErrorNotEnoughPrecision     = -25214

  # --- AXUIElement Creation ---
  fun AXUIElementCreateApplication(pid : Int32) : AXUIElementRef
  fun AXUIElementCreateSystemWide : AXUIElementRef
  fun AXUIElementGetPid(element : AXUIElementRef, pid : Int32*) : AXError

  # --- Attribute Reading ---
  fun AXUIElementCopyAttributeNames(element : AXUIElementRef, names : Void**) : AXError
  fun AXUIElementCopyAttributeValue(element : AXUIElementRef, attribute : Void*, value : Void**) : AXError
  fun AXUIElementGetAttributeValueCount(element : AXUIElementRef, attribute : Void*, count : LibC::Long*) : AXError
  fun AXUIElementCopyAttributeValues(element : AXUIElementRef, attribute : Void*, index : LibC::Long, max_values : LibC::Long, values : Void**) : AXError
  fun AXUIElementIsAttributeSettable(element : AXUIElementRef, attribute : Void*, settable : UInt8*) : AXError

  # --- Attribute Writing ---
  fun AXUIElementSetAttributeValue(element : AXUIElementRef, attribute : Void*, value : Void*) : AXError

  # --- Actions ---
  fun AXUIElementCopyActionNames(element : AXUIElementRef, names : Void**) : AXError
  fun AXUIElementPerformAction(element : AXUIElementRef, action : Void*) : AXError

  # --- Element Discovery ---
  fun AXUIElementCopyElementAtPosition(app : AXUIElementRef, x : Float32, y : Float32, element : Void**) : AXError

  # --- Configuration ---
  fun AXUIElementSetMessagingTimeout(element : AXUIElementRef, timeout : Float32) : AXError

  # --- Global Accessibility Check ---
  fun AXIsProcessTrusted : UInt8

  # --- AXValue (boxed CGPoint / CGSize / CGRect / CFRange) ---
  alias AXValueType = Int32
  AXValueCGPointType = 1
  AXValueCGSizeType  = 2
  AXValueCGRectType  = 3
  AXValueCFRangeType = 4

  # Returns the underlying CG primitive in `value_ptr` (caller-allocated).
  # Returns non-zero (true) on success.
  fun AXValueGetValue(value : Void*, type : AXValueType, value_ptr : Void*) : UInt8

  # Returns the type tag of a boxed AXValueRef.
  fun AXValueGetType(value : Void*) : AXValueType

  # Box a CG primitive into an AXValueRef. Caller owns the returned ref.
  fun AXValueCreate(type : AXValueType, value_ptr : Void*) : Void*
end

# CoreGraphics primitive structs (used by AXValue boxing/unboxing).
# CGFloat is 64-bit on Apple silicon and Intel 64-bit Macs.
@[Extern]
struct CGPoint
  property x : Float64
  property y : Float64

  def initialize(@x : Float64 = 0.0, @y : Float64 = 0.0)
  end
end

@[Extern]
struct CGSize
  property width : Float64
  property height : Float64

  def initialize(@width : Float64 = 0.0, @height : Float64 = 0.0)
  end
end

@[Extern]
struct CGRect
  property origin : CGPoint
  property size : CGSize

  def initialize(@origin : CGPoint = CGPoint.new, @size : CGSize = CGSize.new)
  end
end

# CoreFoundation bindings for string/array manipulation needed by AXUIElement
@[Link(framework: "CoreFoundation")]
lib LibCF
  alias CFIndex = LibC::Long

  # CFString encoding constants
  CFStringEncodingUTF8 = 0x08000100_u32

  # --- CFString ---
  fun CFStringCreateWithCString(alloc : Void*, cstr : UInt8*, encoding : UInt32) : Void*
  fun CFStringGetLength(str : Void*) : CFIndex
  fun CFStringGetCString(str : Void*, buffer : UInt8*, buffer_size : CFIndex, encoding : UInt32) : UInt8
  fun CFStringGetCStringPtr(str : Void*, encoding : UInt32) : UInt8*

  # --- CFArray ---
  fun CFArrayGetCount(array : Void*) : CFIndex
  fun CFArrayGetValueAtIndex(array : Void*, index : CFIndex) : Void*

  # --- CFBoolean ---
  fun CFBooleanGetValue(boolean : Void*) : UInt8

  # --- CFNumber ---
  fun CFNumberGetValue(number : Void*, type : Int32, value_ptr : Void*) : UInt8
  fun CFNumberCreate(allocator : Void*, type : Int32, value_ptr : Void*) : Void*

  # CFNumber type tags
  CFNumberSInt8Type    =  1
  CFNumberSInt16Type   =  2
  CFNumberSInt32Type   =  3
  CFNumberSInt64Type   =  4
  CFNumberFloat32Type  =  5
  CFNumberFloat64Type  =  6
  CFNumberCharType     =  7
  CFNumberShortType    =  8
  CFNumberIntType      =  9
  CFNumberLongType     = 10
  CFNumberLongLongType = 11
  CFNumberFloatType    = 12
  CFNumberDoubleType   = 13
  CFNumberCFIndexType  = 14

  # --- CFBoolean constants (exported globals from CoreFoundation) ---
  $kCFBooleanTrue  : Void*
  $kCFBooleanFalse : Void*

  # --- CFType ---
  fun CFGetTypeID(cf : Void*) : LibC::ULong
  fun CFStringGetTypeID : LibC::ULong
  fun CFArrayGetTypeID : LibC::ULong
  fun CFBooleanGetTypeID : LibC::ULong
  fun CFNumberGetTypeID : LibC::ULong

  # --- Memory ---
  fun CFRelease(cf : Void*) : Void
  fun CFRetain(cf : Void*) : Void*
end

# CoreGraphics event tap bindings for synthesizing keyboard events.
# Posting CGEvents to the HID event tap requires the running process
# (typically Terminal / iTerm / IDE running `crystal spec`) to have
# Accessibility permission in System Settings → Privacy & Security →
# Accessibility. This is the same permission AX queries require.
@[Link(framework: "ApplicationServices")]
lib LibCGEvent
  alias CGEventRef = Void*
  alias CGEventSourceRef = Void*

  # CGEventTapLocation values
  CGHIDEventTap         = 0
  CGSessionEventTap     = 1
  CGAnnotatedSessionEventTap = 2

  # CGEventFlags (bitmask of modifier keys)
  CGEventFlagShift   = 0x00020000_u64
  CGEventFlagControl = 0x00040000_u64
  CGEventFlagOption  = 0x00080000_u64
  CGEventFlagCommand = 0x00100000_u64

  fun CGEventCreateKeyboardEvent(src : CGEventSourceRef, keycode : UInt16, key_down : UInt8) : CGEventRef
  fun CGEventPost(tap : Int32, evt : CGEventRef) : Void
  fun CGEventSetFlags(evt : CGEventRef, flags : UInt64) : Void
  fun CGEventKeyboardSetUnicodeString(evt : CGEventRef, length : LibC::Long, str : UInt16*) : Void
end

{% end %}
