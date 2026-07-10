# AXTest harness entry point: launches a macOS .app bundle and exposes its
# accessibility tree (windows, elements, screenshots) for end-to-end UI tests.

{% if flag?(:macos) %}

require "./ax_element"

module UI::AXTest
  # Launches a macOS .app bundle and provides access to its accessibility tree.
  #
  # Example:
  #   app = App.launch("/Applications/Scribe.app")
  #   prefs = app.window("Scribe Preferences")
  #   prefs.find(role: "AXButton", label: "Browse").should_not be_nil
  #   app.screenshot("/tmp/test.png")
  #   app.terminate
  class App
    getter pid : Int32
    getter root : Element

    def initialize(@pid : Int32)
      ref = LibAX.AXUIElementCreateApplication(@pid)
      @root = Element.new(ref)
      LibAX.AXUIElementSetMessagingTimeout(ref, 10.0_f32)
    end

    # Launch an app from its .app bundle path and wait for it to initialize.
    def self.launch(path : String, wait_seconds : Float64 = 3.0) : App
      # Use 'open' command to launch the .app bundle
      process = Process.new("open", ["-a", path], output: Process::Redirect::Close, error: Process::Redirect::Close)
      process.wait

      # Wait for the app to initialize
      sleep(wait_seconds)

      # Find the PID by app name
      app_name = File.basename(path, ".app")
      output = IO::Memory.new
      Process.run("pgrep", ["-x", app_name.downcase], output: output) rescue nil
      pid_str = output.to_s.strip.lines.first?

      unless pid_str
        # Try case-insensitive match
        output2 = IO::Memory.new
        Process.run("pgrep", ["-i", app_name], output: output2) rescue nil
        pid_str = output2.to_s.strip.lines.first?
      end

      raise "Could not find PID for #{app_name}" unless pid_str
      pid = pid_str.to_i32

      new(pid)
    end

    # Connect to an already-running app by PID
    def self.connect(pid : Int32) : App
      new(pid)
    end

    # --- Window Access ---

    # Find a window by its title
    def window(title : String, timeout : Float64 = 5.0) : Element?
      deadline = Time.monotonic + timeout.seconds
      loop do
        @root.windows.each do |win|
          return win if win.title == title
        end
        break if Time.monotonic >= deadline
        sleep(0.5)
      end
      nil
    end

    # All windows
    def windows : Array(Element)
      @root.windows
    end

    # --- Convenience Queries (search entire app tree) ---

    def find(role : String? = nil, label : String? = nil, title : String? = nil, identifier : String? = nil) : Element?
      @root.find(role: role, label: label, title: title, identifier: identifier)
    end

    def find_all(role : String? = nil, label : String? = nil, title : String? = nil, identifier : String? = nil) : Array(Element)
      @root.find_all(role: role, label: label, title: title, identifier: identifier)
    end

    # Find a descendant of the app's root by accessibility identifier.
    def find_by_id(identifier : String) : Element?
      @root.find_by_id(identifier)
    end

    # Find a descendant of the app's root by accessibility identifier, raising if not found.
    def find_by_id!(identifier : String) : Element
      @root.find_by_id!(identifier)
    end

    # --- Focus (A4) ---

    # The currently focused UI element within this app, as reported by
    # the AXFocusedUIElement attribute on the application root.
    # Returns nil if no element claims focus or the app does not expose it.
    def focused_element : Element?
      attr_cf = LibCF.CFStringCreateWithCString(Pointer(Void).null, "AXFocusedUIElement".to_unsafe, LibCF::CFStringEncodingUTF8)
      value_ref = Pointer(Void).null
      err = LibAX.AXUIElementCopyAttributeValue(@root.ref, attr_cf, pointerof(value_ref))
      LibCF.CFRelease(attr_cf)
      return nil unless err == LibAX::AXErrorSuccess && !value_ref.null?
      Element.new(value_ref.as(LibAX::AXUIElementRef))
    end

    # The system-wide focused UI element (across all apps). Reads
    # `kAXFocusedUIElement` on the system-wide AXUIElement.
    def self.system_focused_element : Element?
      sys = LibAX.AXUIElementCreateSystemWide
      return nil if sys.null?
      attr_cf = LibCF.CFStringCreateWithCString(Pointer(Void).null, "AXFocusedUIElement".to_unsafe, LibCF::CFStringEncodingUTF8)
      value_ref = Pointer(Void).null
      err = LibAX.AXUIElementCopyAttributeValue(sys, attr_cf, pointerof(value_ref))
      LibCF.CFRelease(attr_cf)
      LibCF.CFRelease(sys.as(Void*))
      return nil unless err == LibAX::AXErrorSuccess && !value_ref.null?
      Element.new(value_ref.as(LibAX::AXUIElementRef))
    end

    # --- Window Resize (A5) ---

    # Resize a window of this app, identified by title, to the given
    # width and height (in screen points). Sets kAXSizeAttribute on the
    # window's AXUIElement — no AppleScript fallback. Returns true on
    # success, false if the window was not found or the AX write failed.
    #
    # The target app must advertise kAXSizeAttribute as settable on its
    # windows (most AppKit windows do, unless explicitly fixed-size).
    def resize_window(title : String, width : Int32, height : Int32, timeout : Float64 = 5.0) : Bool
      win = window(title, timeout: timeout)
      return false unless win
      win.set_size(width.to_f64, height.to_f64)
    end

    # --- Screenshot ---

    # Capture a screenshot to the given file path (PNG format).
    #
    # If `window_title` is provided, the screenshot is cropped to that
    # window's bounds using `screencapture -R`. The window bounds are
    # looked up through System Events' accessibility inspector. Falls
    # back to a full-screen capture if the window cannot be located.
    def screenshot(path : String, window_title : String? = nil)
      dir = File.dirname(path)
      Dir.mkdir_p(dir) unless Dir.exists?(dir)

      if window_title && (rect = window_rect_via_system_events(window_title))
        x, y, w, h = rect
        Process.run("/usr/sbin/screencapture", ["-x", "-R", "#{x},#{y},#{w},#{h}", path])
      else
        Process.run("/usr/sbin/screencapture", ["-x", path])
      end
    end

    # Screenshot just the rectangular bounds of `element` to `path` (PNG).
    # Uses `screencapture -R x,y,w,h` to crop directly — no full-screen
    # capture, no in-process image compositing.
    #
    # Returns true on success, false if the element has no readable
    # bounds (no AXPosition/AXSize) or screencapture exits non-zero.
    def screenshot_element(element : Element, path : String) : Bool
      bounds = element.bounds_in_screen
      return false unless bounds

      dir = File.dirname(path)
      Dir.mkdir_p(dir) unless Dir.exists?(dir)

      x = bounds[:x].to_i32
      y = bounds[:y].to_i32
      w = bounds[:width].to_i32
      h = bounds[:height].to_i32

      # Width/height must be > 0 for screencapture.
      return false if w <= 0 || h <= 0

      status = Process.run("/usr/sbin/screencapture", ["-x", "-R", "#{x},#{y},#{w},#{h}", path])
      status.success?
    end

    # Query System Events via osascript for the position/size of a window
    # in this app by title. Returns {x, y, w, h} in screen points or nil.
    private def window_rect_via_system_events(title : String) : Tuple(Int32, Int32, Int32, Int32)?
      app_name = process_name
      return nil unless app_name

      script = <<-APPLESCRIPT
        tell application "System Events" to tell process "#{app_name}"
          set w to first window whose title is "#{title}"
          set p to position of w
          set s to size of w
          return (item 1 of p as text) & "," & (item 2 of p as text) & "," & (item 1 of s as text) & "," & (item 2 of s as text)
        end tell
      APPLESCRIPT

      output = IO::Memory.new
      err = IO::Memory.new
      status = Process.run("/usr/bin/osascript", ["-e", script], output: output, error: err)
      return nil unless status.success?

      parts = output.to_s.strip.split(",")
      return nil unless parts.size == 4
      {parts[0].to_i32, parts[1].to_i32, parts[2].to_i32, parts[3].to_i32}
    rescue
      nil
    end

    # Best-effort lookup of the process name for the app's PID via `ps`.
    private def process_name : String?
      output = IO::Memory.new
      status = Process.run("/bin/ps", ["-p", @pid.to_s, "-o", "comm="], output: output)
      return nil unless status.success?
      name = output.to_s.strip
      return nil if name.empty?
      # comm= returns full path for non-bundle execs; take basename.
      File.basename(name)
    rescue
      nil
    end

    # --- App Lifecycle ---

    # Terminate the app gracefully
    def terminate
      Process.run("kill", [@pid.to_s]) rescue nil
    end

    # Force-kill the app
    def force_terminate
      Process.run("kill", ["-9", @pid.to_s]) rescue nil
    end

    # Check if the app is still running
    def running? : Bool
      LibC.kill(@pid, 0) == 0
    end

    # --- Accessibility Check ---

    # Check if the current process has Accessibility permission
    def self.accessibility_trusted? : Bool
      LibAX.AXIsProcessTrusted != 0
    end

    # --- Debugging ---

    # Print the full accessibility tree of the app
    def dump
      puts "=== App PID #{@pid} ==="
      @root.dump
    end
  end
end

{% end %}
