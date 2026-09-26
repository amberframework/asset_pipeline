{% if flag?(:macos) %}
  require "../../../src/ui/ax_test"

  module SurfaceCraftAX
    extend self

    SAMPLE_BINARY = File.expand_path("../../../samples/surface-craft/bin/surface-craft-study-spec", __DIR__)
    NO_WINDOW     = "Surface craft AX checks need a live, on-screen window registered with macOS Accessibility."

    def with_sample(&)
      process = Process.new(
        SAMPLE_BINARY,
        env: {
          "HIG_INTERACTIVE"          => "1",
          "SURFACE_CRAFT_APPEARANCE" => "light",
          "SURFACE_CRAFT_AX_TEST"    => "1",
        },
        output: Process::Redirect::Inherit,
        error: Process::Redirect::Inherit,
      )

      begin
        sleep(2.seconds)
        yield UI::AXTest::App.connect(process.pid.to_i32)
      ensure
        process.terminate
        process.wait
      end
    end

    def window(app : UI::AXTest::App) : UI::AXTest::Element?
      app.windows.find { |candidate| candidate.role == "AXWindow" }
    end

    def find_in(root : UI::AXTest::Element, identifier : String, max_depth : Int32 = 12) : UI::AXTest::Element?
      return nil if max_depth <= 0

      root.children.each do |child|
        return child if child.identifier == identifier

        if found = find_in(child, identifier, max_depth - 1)
          return found
        end
      end

      nil
    end

    def find_named(root : UI::AXTest::Element, text : String, role : String? = nil, max_depth : Int32 = 12) : UI::AXTest::Element?
      return nil if max_depth <= 0

      root.children.each do |child|
        matches_role = role.nil? || child.role == role
        matches_text = child.title == text || child.label == text || child.value == text
        return child if matches_role && matches_text

        if found = find_named(child, text, role, max_depth - 1)
          return found
        end
      end

      nil
    end

    def find_named_in_windows(app : UI::AXTest::App, text : String, role : String? = nil) : UI::AXTest::Element?
      app.windows.each do |candidate_window|
        if found = find_named(candidate_window, text, role)
          return found
        end
      end

      nil
    end

    def find_text_containing(root : UI::AXTest::Element, text : String, max_depth : Int32 = 12) : UI::AXTest::Element?
      return nil if max_depth <= 0

      root.children.each do |child|
        candidates = [child.title, child.label, child.value]
        return child if candidates.any? { |candidate| candidate && candidate.includes?(text) }

        if found = find_text_containing(child, text, max_depth - 1)
          return found
        end
      end

      nil
    end

    def find_text_containing_in_windows(app : UI::AXTest::App, text : String) : UI::AXTest::Element?
      app.windows.each do |candidate_window|
        if found = find_text_containing(candidate_window, text)
          return found
        end
      end

      nil
    end

    def find_required(root : UI::AXTest::Element, identifier : String) : UI::AXTest::Element
      if found = find_in(root, identifier)
        return found
      end

      raise "Surface craft AX element '#{identifier}' was not found"
    end

    def find_required_in_windows(app : UI::AXTest::App, identifier : String) : UI::AXTest::Element
      app.windows.each do |candidate_window|
        if found = find_in(candidate_window, identifier)
          return found
        end
      end

      raise "Surface craft AX element '#{identifier}' was not found in any window"
    end

    def display_text(element : UI::AXTest::Element) : String
      value = element.value
      return value if value && !value.empty?

      label = element.label
      return label if label && !label.empty?

      element.title || ""
    end
  end
{% end %}
