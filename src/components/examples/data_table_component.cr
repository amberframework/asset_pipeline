require "../base/stateless_component"
require "../elements/base/raw_html"
require "../elements/grouping/div"
require "../elements/grouping/span"
require "../elements/text/text_semantics"
require "../elements/tables/table_elements"

module Components
  module Examples
    class DataTableComponent < StatelessComponent
      record Row,
        id : String,
        title : String,
        owner : String,
        status : String,
        state : String,
        amount : String

      component_css <<-CSS
      .am-table-wrap {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-raised);
        max-width: 100%;
        overflow: hidden;
      }

      .am-table {
        border-collapse: separate;
        border-spacing: 0;
        min-width: 0;
        table-layout: fixed;
        width: 100%;
      }

      .am-table caption {
        color: var(--ap-color-text-secondary);
        font-size: 0.875rem;
        padding: 1rem;
        text-align: left;
      }

      .am-table th {
        background: var(--ap-color-surface-sunken);
        border-bottom: 1px solid var(--ap-color-border-subtle);
        color: var(--ap-color-text-muted);
        font-size: 0.75rem;
        font-weight: 760;
        letter-spacing: 0;
        padding: 0.75rem 1rem;
        text-align: left;
        text-transform: uppercase;
        white-space: nowrap;
      }

      .am-table th,
      .am-table td {
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .am-table th:nth-child(1),
      .am-table td:nth-child(1) { width: 18%; }
      .am-table th:nth-child(2),
      .am-table td:nth-child(2) { width: 28%; }
      .am-table th:nth-child(3),
      .am-table td:nth-child(3) { width: 18%; }
      .am-table th:nth-child(4),
      .am-table td:nth-child(4) { width: 20%; }
      .am-table th:nth-child(5),
      .am-table td:nth-child(5) { width: 16%; text-align: right; }

      .am-table td {
        border-bottom: 1px solid var(--ap-color-border-subtle);
        color: var(--ap-color-text-secondary);
        padding: 0.875rem 1rem;
        transition: background-color var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          color var(--ap-motion-duration-fast) var(--ap-motion-ease-standard);
      }

      .am-table tr {
        position: relative;
      }

      .am-table tbody tr:hover td {
        background: var(--ap-color-state-hover);
        color: var(--ap-color-text-primary);
      }

      .am-table tbody tr[data-state] td:first-child {
        box-shadow: inset 0.25rem 0 0 var(--row-indicator, transparent);
        padding-left: 1.25rem;
      }

      .am-table tbody tr[data-state="success"] {
        --row-bg: var(--ap-color-success-bg);
        --row-bg-hover: var(--ap-color-success-bg-hover);
        --row-indicator: var(--ap-color-success-indicator);
        --row-text: var(--ap-color-success-text);
      }

      .am-table tbody tr[data-state="warning"] {
        --row-bg: var(--ap-color-warning-bg);
        --row-bg-hover: var(--ap-color-warning-bg-hover);
        --row-indicator: var(--ap-color-warning-indicator);
        --row-text: var(--ap-color-warning-text);
      }

      .am-table tbody tr[data-state="danger"],
      .am-table tbody tr[data-state="error"] {
        --row-bg: var(--ap-color-danger-bg);
        --row-bg-hover: var(--ap-color-danger-bg-hover);
        --row-indicator: var(--ap-color-danger-indicator);
        --row-text: var(--ap-color-danger-text);
      }

      .am-table tbody tr[data-state="info"],
      .am-table tbody tr[data-state="selected"] {
        --row-bg: var(--ap-color-info-bg);
        --row-bg-hover: var(--ap-color-info-bg-hover);
        --row-indicator: var(--ap-color-info-indicator);
        --row-text: var(--ap-color-info-text);
      }

      .am-table tbody tr[data-state] td {
        background: var(--row-bg);
        color: var(--ap-color-text-primary);
      }

      .am-table tbody tr[data-state]:hover td {
        background: var(--row-bg-hover);
      }

      .am-table__status {
        align-items: center;
        border-radius: var(--ap-radius-pill);
        color: var(--row-text, var(--ap-color-text-secondary));
        display: inline-flex;
        font-size: 0.8125rem;
        font-weight: 680;
        gap: 0.35rem;
        line-height: 1;
        min-height: 1.75rem;
        padding: 0 0.625rem;
      }

      @media (max-width: 640px) {
        .am-table th,
        .am-table td {
          padding: 0.75rem 0.7rem;
        }

        .am-table th:nth-child(3),
        .am-table td:nth-child(3),
        .am-table th:nth-child(5),
        .am-table td:nth-child(5) {
          display: none;
        }

        .am-table th:nth-child(1),
        .am-table td:nth-child(1) { width: 28%; }
        .am-table th:nth-child(2),
        .am-table td:nth-child(2) { width: 44%; }
        .am-table th:nth-child(4),
        .am-table td:nth-child(4) { width: 28%; }
      }

      .am-empty-state {
        align-items: center;
        background: var(--ap-color-surface-elevated);
        color: var(--ap-color-text-secondary);
        display: grid;
        gap: 0.5rem;
        justify-items: center;
        padding: 2rem;
        text-align: center;
      }

      @media (prefers-reduced-motion: no-preference) {
        .am-table [data-motion="row"] {
          animation: amber-row-enter var(--ap-motion-duration-base) var(--ap-motion-ease-emphasized) both;
        }
      }
      CSS

      @rows : Array(Row)

      def initialize(@rows : Array(Row) = self.class.default_rows, **attrs)
        super(**attrs)
      end

      def self.default_rows : Array(Row)
        [
          Row.new("INV-1048", "Starter kit renewal", "Mina Park", "Paid", "success", "$4,800"),
          Row.new("INV-1049", "Interface review", "Theo Grant", "Needs review", "warning", "$2,150"),
          Row.new("INV-1050", "Failed card update", "Ana Ruiz", "Payment error", "danger", "$890"),
          Row.new("INV-1051", "Design-system rollout", "Seth Tucker", "Selected", "selected", "$8,400"),
        ]
      end

      # SafeHTML v1 exemplar migration (docs/SAFE_HTML_V1.md) — this used to
      # be a `String.build` + nine hand-placed `escape_html(...)` calls (one
      # per interpolated sink: id, caption, each row's id/title/owner/status/
      # amount, and the aria-label). Every one of those was a place a future
      # edit could add a tenth field and forget the wrap — the exact failure
      # class the hardening proposal documents (Stage-5 stored XSS: a single
      # missed sink). Built via the `Elements` DSL instead: every text child
      # and attribute value below is escaped by construction
      # (`ContainerElement#render_children` / `HTMLElement#render_attributes`),
      # not by author discipline — there is no sink left to miss.
      def render_safe_content : SafeHTML
        caption = @attributes["caption"]? || "Amber invoices with clear status styling"
        return empty_state(caption) if @rows.empty?

        wrap = Elements::Div.new
        wrap.set_attribute("id", @attributes["id"]?) if @attributes["id"]?
        wrap.add_class("am-table-wrap")
        wrap.set_attribute("data-component", "table")

        table = Elements::Table.new(class: "am-table")

        table_caption = Elements::Caption.new
        table_caption << caption
        table << table_caption

        thead = Elements::Thead.new
        header_row = Elements::Tr.new
        {"Record", "Work", "Owner", "Status", "Amount"}.each do |heading|
          th = Elements::Th.new(scope: "col")
          th << heading
          header_row << th
        end
        thead << header_row
        table << thead

        tbody = Elements::Tbody.new
        @rows.each { |row| tbody << render_row(row) }
        table << tbody

        wrap << table

        SafeHTML.unsafe(
          wrap.render,
          reason: "built entirely via the Elements DSL (Div/Table/Caption/Thead/Tr/Th/Tbody/Td/Strong/Span) — text children and attribute values are escaped by construction, not hand-interpolated"
        )
      end

      private def render_row(row : Row) : Elements::Tr
        state = normalize_state(row.state)
        label = "#{row.title}: #{row.status}"

        tr = Elements::Tr.new(
          "data-state": state,
          "data-motion": "row"
        )
        tr.set_attribute("aria-selected", "true") if state == "selected"
        tr.set_attribute("aria-invalid", "true") if state == "danger"
        tr.set_attribute("aria-label", label)

        id_cell = Elements::Td.new
        id_strong = Elements::Strong.new
        id_strong << row.id
        id_cell << id_strong
        tr << id_cell

        title_cell = Elements::Td.new
        title_cell << row.title
        tr << title_cell

        owner_cell = Elements::Td.new
        owner_cell << row.owner
        tr << owner_cell

        status_cell = Elements::Td.new
        status_span = Elements::Span.new(class: "am-table__status")
        status_span << row.status
        status_cell << status_span
        tr << status_cell

        amount_cell = Elements::Td.new
        amount_cell << row.amount
        tr << amount_cell

        tr
      end

      private def empty_state(caption : String) : SafeHTML
        empty = Elements::Div.new(
          class: "am-empty-state",
          "data-state": "empty",
          role: "status"
        )

        caption_strong = Elements::Strong.new
        caption_strong << caption
        empty << caption_strong

        note = Elements::Span.new
        note << "No matching records. Adjust filters or create the first item."
        empty << note

        SafeHTML.unsafe(
          empty.render,
          reason: "built entirely via the Elements DSL — text children escaped by construction"
        )
      end

      private def normalize_state(value : String) : String
        value == "error" ? "danger" : value
      end

      # Legacy abstract-contract satisfier (docs/SAFE_HTML_V1.md): the real
      # implementation lives in `render_safe_content` above. Kept as a thin
      # delegation so `Component#render_content : String` (still required by
      # the base class for un-migrated components) stays satisfied.
      def render_content : String
        render_safe_content.to_s
      end
    end
  end
end
