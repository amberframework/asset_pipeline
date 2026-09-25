require "spec"
require "./support/surface_craft_ax_support"

{% if flag?(:macos) %}
  SURFACE_CRAFT_AX_READINESS = begin
    if File.exists?(SurfaceCraftAX::SAMPLE_BINARY)
      ready = false
      SurfaceCraftAX.with_sample do |app|
        ready = !SurfaceCraftAX.window(app).nil?
      end
      ready ? "" : SurfaceCraftAX::NO_WINDOW
    else
      "Surface craft sample is not built; run make -C samples/surface-craft build CRYSTAL=crystal-alpha."
    end
  rescue exception : Exception
    "Surface craft AX host could not register a queryable window: #{exception.message}"
  end

  describe "surface-craft macOS layout through AX" do
    if SURFACE_CRAFT_AX_READINESS.empty?
      it "sizes rounded and notched tabs to their full titles, icons, and insets" do
        SurfaceCraftAX.with_sample do |app|
          window = SurfaceCraftAX.window(app)
          raise SurfaceCraftAX::NO_WINDOW unless window

          {
            {"surface-craft-tab-1", "Controls"},
            {"surface-craft-tab-2", "Keycaps"},
          }.each do |identifier, expected_title|
            tab = SurfaceCraftAX.find_required(window, identifier)
            SurfaceCraftAX.display_text(tab).should contain(expected_title)

            size = tab.size
            raise "#{expected_title} tab has no AX size" unless size
            # At 12pt semibold, each title, 14pt folder glyph, 7pt gap, and
            # 26pt horizontal insets require at least 100pt.
            size[:width].should be >= 100.0
          end
        end
      end

      it "keeps three surface-craft fields in separate ordered row views" do
        SurfaceCraftAX.with_sample do |app|
          window = SurfaceCraftAX.window(app)
          raise SurfaceCraftAX::NO_WINDOW unless window

          rows = (0...3).map do |index|
            SurfaceCraftAX.find_required(window, "surface-craft-form-row-1-#{index}")
          end
          frames = rows.map do |row|
            frame = row.frame
            raise "Surface craft row has no AX frame" unless frame
            frame
          end

          frames.each_cons(2) do |pair|
            upper = pair[0]
            lower = pair[1]
            (upper[:y] + upper[:height]).should be <= (lower[:y] + 1.0)
          end
        end
      end

      it "fires Slide toggle callbacks for both user-driven transitions" do
        SurfaceCraftAX.with_sample do |app|
          window = SurfaceCraftAX.window(app)
          raise SurfaceCraftAX::NO_WINDOW unless window

          result = SurfaceCraftAX.find_required(window, "surface-craft-slide-result")
          SurfaceCraftAX.display_text(result).should eq("Slide value: false")

          toggle = SurfaceCraftAX.find_required(window, "surface-craft-slide-toggle")
          toggle.focus!.should be_true
          UI::AXTest::Keys.space!
          sleep(0.35.seconds)
          window = SurfaceCraftAX.window(app)
          raise SurfaceCraftAX::NO_WINDOW unless window
          result = SurfaceCraftAX.find_required(window, "surface-craft-slide-result")
          first_transition = SurfaceCraftAX.display_text(result)
          unless first_transition == "Slide value: true"
            raise "Space on the focused Slide control did not flip it: role=#{toggle.role}, label=#{toggle.label}, actions=#{toggle.action_names}, value=#{toggle.value}, result=#{first_transition}"
          end

          toggle = SurfaceCraftAX.find_required(window, "surface-craft-slide-toggle")
          toggle.focus!.should be_true
          UI::AXTest::Keys.space!
          sleep(0.35.seconds)
          window = SurfaceCraftAX.window(app)
          raise SurfaceCraftAX::NO_WINDOW unless window
          result = SurfaceCraftAX.find_required(window, "surface-craft-slide-result")
          SurfaceCraftAX.display_text(result).should eq("Slide value: false")
        end
      end

      it "fires BezelLamp selection and exposes the selected color value" do
        SurfaceCraftAX.with_sample do |app|
          window = SurfaceCraftAX.window(app)
          raise SurfaceCraftAX::NO_WINDOW unless window

          bezel = SurfaceCraftAX.find_required(window, "surface-craft-bezel-picker")
          size = bezel.size
          raise "BezelLamp button has no AX size" unless size
          size[:width].should be >= 36.0
          size[:height].should be >= 36.0
          bezel.click
          sleep(0.3.seconds)
          menu_item = SurfaceCraftAX.find_required_in_windows(app, "surface-craft-menu-option-0")
          menu_item.click
          sleep(0.4.seconds)

          window = SurfaceCraftAX.window(app)
          raise SurfaceCraftAX::NO_WINDOW unless window
          bezel_result = SurfaceCraftAX.find_required(window, "surface-craft-bezel-result")
          SurfaceCraftAX.display_text(bezel_result).should eq("Bezel selection: 0: Ocean")
          menu_label = SurfaceCraftAX.find_text_containing_in_windows(app, "Choose color, Ocean")
          raise "BezelLamp did not expose its selected color label" unless menu_label
          (menu_label.label || "").should contain("Ocean")
          menu_label.value.should eq("rgba(31.0,107.0,184.0,1.0)")
        end
      end

      it "fires SwatchRow selection and marks the newly selected color" do
        SurfaceCraftAX.with_sample do |app|
          window = SurfaceCraftAX.window(app)
          raise SurfaceCraftAX::NO_WINDOW unless window

          swatch = SurfaceCraftAX.find_required(window, "surface-craft-swatch-row-0")
          swatch.click
          sleep(0.4.seconds)

          window = SurfaceCraftAX.window(app)
          raise SurfaceCraftAX::NO_WINDOW unless window
          row_result = SurfaceCraftAX.find_required(window, "surface-craft-row-result")
          SurfaceCraftAX.display_text(row_result).should eq("Swatch row selection: 0: Ocean")
          selected_swatch = SurfaceCraftAX.find_required(window, "surface-craft-swatch-row-0")
          selected_swatch.value.should eq("rgba(31.0,107.0,184.0,1.0)")
        end
      end
    else
      pending SURFACE_CRAFT_AX_READINESS
    end
  end
{% end %}
