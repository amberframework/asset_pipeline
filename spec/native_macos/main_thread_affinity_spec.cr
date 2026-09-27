require "spec"

# AppKit must only be used from the main thread. Every native macOS spec runs
# AppKit calls on the main fiber, so the main fiber has to stay on the main
# thread for the whole run.
#
# Under the execution-context runtime (the default since Crystal 1.21), the
# monitor thread moves a scheduler to another thread whenever its 10 ms tick
# lands while that scheduler is inside `Fiber.syscall` (`File.open`,
# `getaddrinfo`, ...). The main fiber then resumes on a pool thread, the next
# `NSWindow` initializer raises `NSInternalInconsistencyException`, and that
# exception cannot unwind through Crystal frames, so the spec binary dies with
# SIGTRAP ("Process hit a breakpoint"). `make test-macos` builds with
# `-Dwithout_mt`, which keeps the main fiber on the main thread.
{% if flag?(:macos) %}
  {% if !flag?(:without_mt) && !flag?(:preview_mt) || flag?(:execution_context) %}
    {% raise "The native macOS specs call AppKit from the main fiber and must be built with -Dwithout_mt " \
             "(see the test-macos target in the Makefile). Under execution contexts the main fiber can " \
             "move off the main thread after any blocking syscall." %}
  {% end %}

  lib LibC
    fun pthread_main_np : Int
  end

  # Opening a file enters `Fiber.syscall`; with execution contexts active, a
  # few monitor ticks' worth of opens reliably moves the main fiber.
  SYSCALL_WINDOW_FOR_MAIN_THREAD_AFFINITY = 100.milliseconds

  describe "Main-thread affinity of the main fiber" do
    it "keeps the main fiber on the main thread across blocking syscalls" do
      LibC.pthread_main_np.should eq(1)

      deadline = Time.instant + SYSCALL_WINDOW_FOR_MAIN_THREAD_AFFINITY
      count_of_opens = 0
      while Time.instant < deadline
        File.open(__FILE__) { }
        count_of_opens += 1
        break unless LibC.pthread_main_np == 1
      end

      count_of_opens.should be > 0
      LibC.pthread_main_np.should eq(1)
    end
  end
{% end %}
