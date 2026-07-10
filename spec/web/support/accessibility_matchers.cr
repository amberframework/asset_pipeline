module SpecSupport
  module AccessibilityMatchers
    FORBIDDEN_BOOTSTRAP_SHAPED_CLASSES = %w[
      alert alert-danger alert-info alert-success alert-warning
      badge badge-danger badge-info badge-success badge-warning
      btn btn-danger btn-info btn-primary btn-secondary btn-success btn-warning
      card card-body card-title container container-fluid
      list-group placeholder progress progress-bar row spinner-border toast
    ]

    def expect_no_bootstrap_shaped_classes(html : String)
      html.scan(/class="([^"]*)"/).each do |match|
        match[1].split(/\s+/).each do |klass|
          FORBIDDEN_BOOTSTRAP_SHAPED_CLASSES.includes?(klass).should eq(false)
        end
      end
    end

    def expect_no_duplicate_ids(html : String)
      ids = html.scan(/\sid="([^"]+)"/).map { |match| match[1] }
      duplicates = ids.select { |id| ids.count(id) > 1 }.uniq

      duplicates.should eq([] of String)
    end

    def expect_accessible_control(html : String, id : String)
      element = find_start_tag_by_id(html, id)
      element.nil?.should eq(false)
      return unless element

      attrs = element[:attrs]
      has_label = html.scan(/<label\b([^>]*)>/).any? { |match| html_attr(match[1], "for") == id }
      has_wrapping_label = !!html.match(/<label\b[^>]*>.*\sid="#{Regex.escape(id)}".*<\/label>/m)
      has_aria_name = attr_present?(attrs, "aria-label") || attr_present?(attrs, "aria-labelledby")
      has_visible_text = %w[button a].includes?(element[:name]) && !element_text_by_id(html, id).empty?

      (has_label || has_wrapping_label || has_aria_name || has_visible_text).should eq(true)
    end

    def expect_error_wiring(html : String, control_id : String, error_id : String)
      element = find_start_tag_by_id(html, control_id)
      element.nil?.should eq(false)
      return unless element

      attrs = element[:attrs]
      html_attr(attrs, "aria-invalid").should eq("true")
      described_by = html_attr(attrs, "aria-describedby")
      described_by.nil?.should eq(false)
      return unless described_by

      described_by.split(/\s+/).includes?(error_id).should eq(true)
      id_exists?(html, error_id).should eq(true)
      element_text_by_id(html, error_id).empty?.should eq(false)
    end

    def expect_live_region(html : String, id : String? = nil, politeness : String? = nil)
      if id
        element = find_start_tag_by_id(html, id)
        element.nil?.should eq(false)
        return unless element

        live_region_attrs?(element[:attrs], politeness).should eq(true)
      else
        has_live_region = html.scan(/<([a-zA-Z][\w:-]*)\b([^>]*)>/).any? do |match|
          live_region_attrs?(match[2], politeness)
        end

        has_live_region.should eq(true)
      end
    end

    def expect_relationship_targets_exist(html : String, attrs = %w[aria-describedby aria-labelledby aria-controls])
      missing = [] of String
      empty = [] of String

      attrs.each do |attr_name|
        html.scan(/\s#{Regex.escape(attr_name)}="([^"]+)"/).each do |match|
          match[1].split(/\s+/).each do |target_id|
            unless id_exists?(html, target_id)
              missing << "#{attr_name}=#{target_id}"
              next
            end

            next if attr_name == "aria-controls"
            empty << "#{attr_name}=#{target_id}" if element_text_by_id(html, target_id).empty?
          end
        end
      end

      missing.uniq.should eq([] of String)
      empty.uniq.should eq([] of String)
    end

    def expect_describedby_targets_exist(html : String)
      expect_relationship_targets_exist(html, %w[aria-describedby])
    end

    def expect_behavior_hook_pair(html : String, neutral : String, legacy : String, value : String? = nil)
      neutral_values = attr_values(html, neutral)
      legacy_values = attr_values(html, legacy)

      neutral_values.empty?.should eq(false)
      legacy_values.empty?.should eq(false)

      if value
        neutral_values.includes?(value).should eq(true)
        legacy_values.includes?(value).should eq(true)
      end
    end

    def expect_fieldset_legend(html : String, text : String, hidden : Bool = true)
      class_check = hidden ? %( class="am-visually-hidden") : ""
      html.should contain(%(<legend#{class_check}>#{text}</legend>))
    end

    def expect_source_data_table(html : String, caption_id : String, headers : Array(String))
      html.should contain("<table")
      html.should contain(%(<caption id="#{caption_id}"))
      headers.each do |header|
        html.should contain(%(<th scope="col">#{header}</th>))
      end
    end

    def expect_no_inline_event_handlers(html : String)
      html.match(/\son[a-zA-Z]+\s*=/).nil?.should eq(true)
    end

    def expect_no_positive_tabindex(html : String)
      invalid = [] of String
      positive = [] of String

      html.scan(/\stabindex="([^"]+)"/).each do |match|
        value = match[1]
        numeric = value.to_i?
        if numeric.nil?
          invalid << value
        elsif numeric > 0
          positive << value
        end
      end

      invalid.should eq([] of String)
      positive.should eq([] of String)
    end

    private def find_start_tag_by_id(html : String, id : String) : NamedTuple(name: String, attrs: String)?
      html.scan(/<([a-zA-Z][\w:-]*)\b([^>]*)>/).each do |match|
        attrs = match[2]
        return {name: match[1], attrs: attrs} if html_attr(attrs, "id") == id
      end

      nil
    end

    private def html_attr(attrs : String, name : String) : String?
      escaped = Regex.escape(name)
      if match = attrs.match(/(?:^|\s)#{escaped}=(?:"([^"]*)"|'([^']*)')/)
        match[1]? || match[2]?
      elsif attrs.match(/(?:^|\s)#{escaped}(?:\s|$)/)
        ""
      end
    end

    private def attr_present?(attrs : String, name : String) : Bool
      value = html_attr(attrs, name)
      !value.nil? && !value.empty?
    end

    private def attr_values(html : String, name : String) : Array(String)
      html.scan(/(?:^|[\s<])#{Regex.escape(name)}(?:=(?:"([^"]*)"|'([^']*)'))?(?=[\s>])/).map do |match|
        match[1]? || match[2]? || ""
      end
    end

    private def id_exists?(html : String, id : String) : Bool
      !!html.match(/\sid="#{Regex.escape(id)}"/)
    end

    private def element_text_by_id(html : String, id : String) : String
      if match = html.match(/<([a-zA-Z][\w:-]*)\b[^>]*\sid="#{Regex.escape(id)}"[^>]*>(.*?)<\/\1>/m)
        match[2].gsub(/<[^>]+>/, "").strip
      else
        ""
      end
    end

    private def live_region_attrs?(attrs : String, politeness : String? = nil) : Bool
      role = html_attr(attrs, "role")
      live = html_attr(attrs, "aria-live")
      allowed_live = %w[polite assertive]

      if politeness
        live == politeness || (politeness == "polite" && role == "status") || (politeness == "assertive" && role == "alert")
      else
        role == "status" || role == "alert" || (!!live && allowed_live.includes?(live))
      end
    end
  end
end
