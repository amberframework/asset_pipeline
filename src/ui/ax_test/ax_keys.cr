# Synthesizes keyboard events via CGEvent for AXTest harnesses. Posts clean
# key-down/key-up pairs to the frontmost app; requires Accessibility permission.

{% if flag?(:macos) %}

require "./ax_ffi"

module UI::AXTest
  # Synthesize keyboard events via CGEvent. Each helper posts a clean
  # key-down + key-up pair to the HID event tap, delivering it to the
  # frontmost application (the one with the keyboard focus).
  #
  # ## Permission requirement
  #
  # Posting CGEvents requires the process running `crystal spec` (your
  # Terminal, iTerm, IDE, etc.) to have **Accessibility** permission
  # granted in System Settings → Privacy & Security → Accessibility.
  # This is the same permission the AX query side already requires —
  # see `App.accessibility_trusted?` to check it at runtime.
  #
  # Without permission, calls do not raise — the event is silently
  # dropped by the OS. Integration tests that depend on key delivery
  # should check `App.accessibility_trusted?` and pending! if false.
  #
  # ## Key codes
  #
  # Codes are US-layout virtual key codes (Apple's `HIToolbox/Events.h`
  # constants). Non-US layouts are not yet supported.
  module Keys
    extend self

    # Common virtual key codes (US layout, Carbon/HIToolbox values).
    ESCAPE      = 53_u16
    TAB         = 48_u16
    RETURN      = 36_u16
    SPACE       = 49_u16
    DELETE      = 51_u16
    ARROW_LEFT  = 123_u16
    ARROW_RIGHT = 124_u16
    ARROW_DOWN  = 125_u16
    ARROW_UP    = 126_u16

    # Post a single key-down + key-up pair for `keycode`. Optional
    # modifier flags (bitwise OR of LibCGEvent::CGEventFlag*) apply to
    # the key-down event only.
    def press(keycode : UInt16, modifiers : UInt64 = 0_u64)
      down = LibCGEvent.CGEventCreateKeyboardEvent(Pointer(Void).null, keycode, 1_u8)
      LibCGEvent.CGEventSetFlags(down, modifiers) if modifiers != 0
      LibCGEvent.CGEventPost(LibCGEvent::CGHIDEventTap, down)
      LibCF.CFRelease(down)

      up = LibCGEvent.CGEventCreateKeyboardEvent(Pointer(Void).null, keycode, 0_u8)
      LibCGEvent.CGEventPost(LibCGEvent::CGHIDEventTap, up)
      LibCF.CFRelease(up)
    end

    # Escape key (dismiss menu, sheet, popover).
    def escape!
      press(ESCAPE)
    end

    # Tab key (advance focus).
    def tab!
      press(TAB)
    end

    # Shift+Tab (retreat focus).
    def shift_tab!
      press(TAB, LibCGEvent::CGEventFlagShift)
    end

    # Return / Enter key (commit, default-button activation).
    def return!
      press(RETURN)
    end

    def arrow_up!
      press(ARROW_UP)
    end

    def arrow_down!
      press(ARROW_DOWN)
    end

    def arrow_left!
      press(ARROW_LEFT)
    end

    def arrow_right!
      press(ARROW_RIGHT)
    end

    def space!
      press(SPACE)
    end

    def delete!
      press(DELETE)
    end

    # Type a string by posting CGEvents with each character set as the
    # event's Unicode string. This bypasses keycode-to-character
    # translation entirely — works for any printable Unicode character
    # regardless of the active keyboard layout.
    def type(string : String)
      string.each_char do |ch|
        # Create a key event with an arbitrary keycode (0); we overwrite
        # the string via CGEventKeyboardSetUnicodeString.
        down = LibCGEvent.CGEventCreateKeyboardEvent(Pointer(Void).null, 0_u16, 1_u8)
        utf16 = ch.to_s.to_utf16
        LibCGEvent.CGEventKeyboardSetUnicodeString(down, utf16.size.to_i64, utf16.to_unsafe)
        LibCGEvent.CGEventPost(LibCGEvent::CGHIDEventTap, down)
        LibCF.CFRelease(down)

        up = LibCGEvent.CGEventCreateKeyboardEvent(Pointer(Void).null, 0_u16, 0_u8)
        LibCGEvent.CGEventKeyboardSetUnicodeString(up, utf16.size.to_i64, utf16.to_unsafe)
        LibCGEvent.CGEventPost(LibCGEvent::CGHIDEventTap, up)
        LibCF.CFRelease(up)
      end
    end
  end
end

{% end %}
