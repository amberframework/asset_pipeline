# Debug-only handle tracker that monitors NativeHandle lifetimes when
# `-Dui_debug` is set. Eliminated at compile time in release builds.

module UI
  # Debug-only handle tracker that monitors `NativeHandle` lifetimes.
  #
  # Compiled only when `-Dui_debug` is passed to the Crystal compiler.
  # In release builds, all tracker calls in `NativeHandle` are eliminated
  # at compile time via `{% if flag?(:ui_debug) %}` guards.
  #
  # ## Usage
  #
  # Build with debug tracking:
  # ```bash
  # crystal build my_app.cr -Dui_debug
  # ```
  #
  # Dump leaks at shutdown:
  # ```crystal
  # at_exit do
  #   UI::NativeHandleTracker.dump_leaks
  # end
  # ```
  #
  # ## How It Works
  #
  # - `NativeHandle#initialize` calls `register` to record the handle.
  # - `NativeHandle#release!` calls `unregister` to remove the handle.
  # - At shutdown, `dump_leaks` reports any handles that were never released.
  # - The tracker uses the pointer address as the key (cast to UInt64).
  module NativeHandleTracker
    {% if flag?(:ui_debug) %}
      @@handles = Hash(UInt64, String?).new

      # Record a newly created handle.
      def self.register(handle : NativeHandle) : Nil
        key = handle.ptr.address
        @@handles[key] = handle.label
      end

      # Remove a handle that has been released.
      def self.unregister(handle : NativeHandle) : Nil
        key = handle.ptr.address
        @@handles.delete(key)
      end

      # Returns the number of handles that are currently live (not released).
      def self.live_count : Int32
        @@handles.size
      end

      # Print all unreleased handles to the given IO.
      #
      # Each line shows the pointer address and the optional label.
      # If no leaks are found, prints a summary line.
      def self.dump_leaks(io : IO = STDERR) : Nil
        if @@handles.empty?
          io.puts "[NativeHandleTracker] No leaks detected. All handles released."
          return
        end

        io.puts "[NativeHandleTracker] WARNING: #{@@handles.size} unreleased handle(s):"
        @@handles.each do |address, label|
          label_str = label || "(unlabeled)"
          io.puts "  0x#{address.to_s(16)} - #{label_str}"
        end
      end

      # Clear all tracked handles. For test cleanup only.
      def self.clear : Nil
        @@handles.clear
      end
    {% else %}
      # No-op stubs for non-debug builds.
      # These exist so code that references the tracker unconditionally
      # (e.g., in tests) still compiles without -Dui_debug.

      def self.register(handle : NativeHandle) : Nil
      end

      def self.unregister(handle : NativeHandle) : Nil
      end

      def self.live_count : Int32
        0
      end

      def self.dump_leaks(io : IO = STDERR) : Nil
      end

      def self.clear : Nil
      end
    {% end %}
  end
end
