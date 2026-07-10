# Phase 10A.0a — Minimal doc-scaffold sweep (iter 4 expanded).
#
# Idempotently adds a 1-2 sentence file header AND a 1-2 sentence
# summary above every public top-level/single-nest type declaration
# (class / abstract class / module / struct) across the ~90 public
# surface files listed in scoping-10 v3 §"10A.0". NO per-method docs
# (deferred to 10A.final).
#
# Idempotency:
# - A file is treated as having a header if its first non-blank line
#   starts with `#`.
# - A type-declaration line is treated as already-summarized when the
#   immediately-preceding non-blank line starts with `#`.
# - The scaffolder also replaces any leftover
#   `# TODO: Write documentation for X` placeholder with a real
#   summary drawn from the description map.

require "file_utils"

# PascalCase -> snake_case helper.
def snake_case_of(class_name : String) : String
  s = class_name.gsub(/([A-Z]+)([A-Z][a-z])/) { "#{$1}_#{$2}" }
  s = s.gsub(/([a-z\d])([A-Z])/) { "#{$1}_#{$2}" }
  s.downcase
end

# Per-view descriptive blurbs.
VIEW_DESCRIPTIONS = {
  "action_sheet"                    => "Modal sheet of choices presented at the bottom of the screen on iOS.",
  "action_sheet_with_web_fallback"  => "Tier-3 action sheet with a web-compatible fallback rendering on non-iOS targets.",
  "activity_indicator"              => "Indeterminate spinner indicating that work is in progress.",
  "activity_ring"                   => "Single circular progress ring rendered in the Activity Rings idiom.",
  "activity_rings"                  => "Composition of activity rings rendered as a stack of progress indicators.",
  "activity_view"                   => "Native share / activity sheet for exporting content to other apps.",
  "alert"                           => "Modal alert dialog used to confirm critical information or destructive actions.",
  "async_image"                     => "Image view that loads its content asynchronously from a URL.",
  "button"                          => "Tappable button with HIG-conformant styling for primary, secondary, and tinted roles.",
  "canvas"                          => "Low-level drawing surface backed by the native platform 2D drawing API.",
  "capsule"                         => "Pill-shaped geometric primitive used for badges and chip backgrounds.",
  "card"                            => "Boxed surface that groups related content with optional title and elevation.",
  "chart_view"                      => "Native chart view wrapping Swift Charts on Apple platforms and the equivalent on other targets.",
  "checkbox"                        => "Two-state checkbox control with a leading label.",
  "circle"                          => "Filled or stroked circular geometric primitive.",
  "color_picker"                    => "Color selection control bridging to the native color picker on each platform.",
  "column_view"                     => "Multi-column information list view (macOS NSTableView column layout).",
  "combo_box"                       => "Text field with an associated drop-down list of suggestions.",
  "confirmation_dialog"             => "Action-confirmation prompt with platform-idiomatic destructive/cancel buttons.",
  "context_menu"                    => "Long-press / right-click contextual menu attached to a host view.",
  "context_menu_with_web_fallback"  => "Tier-3 context menu with a web-compatible fallback rendering on non-native targets.",
  "date_picker"                     => "Calendar-based date selection control.",
  "disclosure_group"                => "Collapsible disclosure section grouping related content under a toggle header.",
  "divider"                         => "Thin horizontal or vertical separator line between content.",
  "form"                            => "Container that groups input controls into sections with HIG-conformant spacing.",
  "gauge"                           => "Bounded value indicator showing progress along a fixed range.",
  "glass_background"                => "Apple glass / translucency background using NSVisualEffectView / UIVisualEffectView.",
  "grid"                            => "Two-dimensional layout that arranges children in rows and columns.",
  "hstack"                          => "Horizontal stack that arranges children leading-to-trailing with configurable spacing.",
  "icon_button"                     => "Compact icon-only button used for toolbar and inline actions.",
  "image"                           => "Static image view loading from an asset or local URL.",
  "image_well"                      => "Drop-target image well control for accepting an image via drag-and-drop or click.",
  "label"                           => "Static text label with semantic typography and accessibility metadata.",
  "link_button"                     => "Button styled as a hyperlink that opens or dispatches a navigation action.",
  "list_view"                       => "Scrolling vertical list of rows with native idiomatic chrome.",
  "live_text_view"                  => "Text view that recognizes live elements (URLs, addresses, phone numbers).",
  "map_view"                        => "Native map view bridging to MapKit on Apple platforms.",
  "menu_button"                     => "Button that reveals a drop-down menu of actions.",
  "modal_view"                      => "Modal presentation container hosting another view tree.",
  "navigation_link"                 => "Navigation affordance that pushes a destination onto the navigation stack.",
  "navigation_split_view"           => "Multi-column navigation container (sidebar + content + detail) for iPad and macOS.",
  "navigation_stack"                => "Push/pop navigation container hosting a sequence of screens.",
  "outline_view"                    => "Hierarchical disclosure view backed by NSOutlineView / UITableView with indents.",
  "page_control"                    => "Horizontal page-indicator dots commonly used under paged scroll views.",
  "path_control"                    => "macOS path control showing a filesystem-style breadcrumb.",
  "path_control_with_web_fallback"  => "Tier-3 path control with a web-compatible fallback rendering on non-macOS targets.",
  "path_view"                       => "Vector path primitive driven by an explicit drawing command sequence.",
  "picker"                          => "Single-selection picker with platform-idiomatic wheel / inline / menu styles.",
  "popover"                         => "Lightweight transient overlay anchored to a host view.",
  "progress_view"                   => "Determinate progress bar / circle for known-duration work.",
  "radio_group"                     => "Group of mutually exclusive radio buttons with a shared selection.",
  "rectangle"                       => "Filled or stroked rectangular geometric primitive.",
  "rich_text"                       => "Read-only rich-text view supporting attributed runs and inline images.",
  "rounded_rectangle"               => "Rectangular primitive with configurable corner radius.",
  "scroll_view"                     => "Single-axis or two-axis scrolling viewport wrapping a content view.",
  "search_field"                    => "Single-line search input with platform-idiomatic clear and scope affordances.",
  "secure_field"                    => "Single-line text input that masks its contents (used for passwords).",
  "segmented_control"               => "Horizontal segmented selector for picking one option from a small set.",
  "sheet"                           => "Modal sheet that slides up from the bottom (iOS) or appears as a dialog (macOS).",
  "slider"                          => "Continuous-value slider control with configurable range and step.",
  "snackbar"                        => "Transient toast / snackbar notification anchored to the bottom of the screen.",
  "spacer"                          => "Layout-only view that expands to fill remaining space along a stack's axis.",
  "stepper"                         => "Increment / decrement stepper for adjusting a discrete numeric value.",
  "surface"                         => "Generic themed surface used as a background for other content.",
  "swipe_action_row"                => "List row with edge-swipe revealed actions (leading / trailing).",
  "tab_view"                        => "Tab-bar container that hosts multiple sibling routes.",
  "table_view"                      => "Multi-column data table with native row chrome and selection.",
  "text_area"                       => "Multi-line plain-text input field.",
  "text_editor"                     => "Rich multi-line text editor with attributed string support.",
  "text_field"                      => "Single-line plain-text input field.",
  "time_picker"                     => "Time-of-day selection control.",
  "token_field"                     => "Multi-value tokenized text field (e.g. recipient field in a mail app).",
  "toggle"                          => "On / off toggle switch with optional label.",
  "toggle_button"                   => "Pressed-state button used as a toggle (e.g. bold / italic toolbar buttons).",
  "toolbar"                         => "Top-of-screen toolbar container hosting buttons and other tools.",
  "tooltip"                         => "Hover / focus-driven tooltip overlay attached to a host view.",
  "video_player"                    => "Native video playback view bridging to AVPlayerViewController on Apple platforms.",
  "vstack"                          => "Vertical stack that arranges children top-to-bottom with configurable spacing.",
  "web_view"                        => "Embedded web content view backed by WKWebView / WebView2.",
  "web_view_component"              => "Embedded web content view backed by WKWebView / WebView2.",
  "zstack"                          => "Overlay container that layers children along the z-axis.",
} of String => String

ASSET_PIPELINE_DESCRIPTIONS = {
  "dependency_analyzer.cr" => "Dependency analyzer for the asset pipeline JS / CSS graph.",
  "design_system.cr"       => "Design-system entry point: token-driven theming for the asset pipeline.",
  "framework_registry.cr"  => "Registry of integration adapters for host frameworks (Amber, Lucky, etc.).",
  "platform.cr"            => "Compile-time platform-gating helpers for the asset_pipeline cross-platform UI.",
  "script_renderer.cr"     => "Renders `<script>` tags and import-map JSON for the FrontLoader.",
} of String => String

UI_TOPLEVEL_DESCRIPTIONS = {
  "design_tokens.cr" => "Tier-1 brand-token contract: semantic colors, spacing, typography, and motion scales.",
  "form_state.cr"    => "Controlled-input state container threaded through screen renders.",
} of String => String

# Per-class summaries for non-view public types (asset_pipeline/* +
# views/* extras + ui/* top-level). Keys are exact class / module
# identifiers. Anything not in this map falls through to a generic
# summary drawn from the file's description.
TYPE_DESCRIPTIONS = {
  # src/asset_pipeline.cr
  "AssetPipeline"         => "Top-level shard namespace housing FrontLoader, import maps, framework registry, and the cross-platform UI surface.",
  "FrontLoader"           => "Coordinates JavaScript import maps and renders the <script> / importmap tags used by the asset pipeline.",
  # asset_pipeline/*.cr
  "UI"                    => "Top-level namespace for the asset_pipeline cross-platform UI system.",
  "DependencyAnalyzer"    => "Scans custom JavaScript blocks and reports external libraries + local modules referenced by the code.",
  "ActionDispatcher"      => "Per-app coordinator that translates UI actions into navigation operations or inline view renders.",
  "ActionResult"          => "Abstract base for the ActionResult type hierarchy returned from UI::Controller action methods.",
  "Navigate"              => "ActionResult subtype that pushes a destination onto the navigation stack.",
  "Pop"                   => "ActionResult subtype that pops the top destination off the navigation stack.",
  "Rerender"              => "ActionResult subtype that rerenders the current screen with updated controller state.",
  "ReplaceRoot"           => "ActionResult subtype that replaces the navigation root with a new screen.",
  "RenderInline"          => "ActionResult subtype that emits an inline view update without navigation.",
  "ScreenContext"         => "Shared per-screen context (route, params, session, flash) threaded through `build(ctx)`.",
  "AmberConfig"           => "Configuration namespace for the Amber framework integration.",
  "Screen"                => "Abstract base for screen authoring — every concrete screen subclasses this and implements `build(ctx)`.",
  "AmberIntegration"      => "Module exposing `routes_for(App)` to wire a UI::App into an Amber web target.",
  "ScreenHelpers"         => "View helpers mixed into Amber controllers and screens.",
  "Session"               => "Abstract per-app key/value session store; targets override with web / native implementations.",
  "Flash"                 => "Abstract per-request flash-message bag; targets override with web / native implementations.",
  "FrameworkRegistry"     => "Registry of framework renderer classes keyed by name (e.g. \"stimulus\", \"alpine\").",
  "FrameworkRenderer"     => "Abstract base for framework-specific script renderers plugged into the registry.",
  "Controller"            => "Abstract base class for native-target controllers that turn user actions into ActionResult values.",
  "Platform"              => "Compile-time platform-gating helpers — `Platform.requires(:ios) do ... end` and friends.",
  "App"                   => "Abstract base class for the declarative app + route registry; subclasses use the `screen` macro.",
  "WebOnlyScreenError"    => "Raised by the dispatcher when a native build accidentally drives into a screen registered as web-only.",
  "ScriptRenderer"        => "Renders <script> and importmap tags for one or more import maps.",
  # ui/form_state.cr + ui/design_tokens.cr
  "FormState"             => "Controlled-input state container threaded through screen renders to preserve text values across rerenders.",
  "FormStateRendererHook" => "Renderer mixin that snapshots FormState into the rendered view tree.",
  "DesignTokens"          => "Tier-1 brand-token contract: semantic colors, spacing, typography, shadows, motion, breakpoints.",
  # views/* extras (non-`< View` public types)
  "SwipeAction"           => "Single edge-swipe action descriptor (label, role, icon, on_tap) attached to a SwipeActionRow.",
  "SnackbarPresenter"     => "Presentation state for a Snackbar (is_presenting flag + the underlying view).",
  "SheetPresenter"        => "Presentation state for a Sheet (is_presenting flag + the underlying view).",
  "PopoverPresenter"      => "Presentation state for a Popover (is_presenting flag + the underlying view).",
  "ActivityViewPresenter" => "Presentation state for an ActivityView share sheet.",
  "ActivityDestination"   => "Activity-sheet destination metadata (target app, icon, identifier).",
  "ActivityAction"        => "Activity-sheet action descriptor (label, role, on_tap).",
  "ContextMenu"           => "Long-press / right-click contextual menu attached to a host view (Apple-family only).",
  "PathControl"           => "macOS path control showing a filesystem-style breadcrumb (macOS only).",
  "ActionSheet"           => "Modal sheet of choices presented at the bottom of the screen on iOS (iOS only).",
} of String => String

# Files in scope for this scaffold sweep. Glob expressions joined.
def in_scope_files : Array(String)
  files = [] of String
  files << "src/asset_pipeline.cr"
  Dir.glob("src/asset_pipeline/*.cr") { |p| files << p }
  Dir.glob("src/ui/views/*.cr") { |p| files << p }
  Dir.glob("src/ui/views/_gate_stubs/*.cr") { |p| files << p }
  files << "src/ui/form_state.cr" if File.exists?("src/ui/form_state.cr")
  files << "src/ui/design_tokens.cr" if File.exists?("src/ui/design_tokens.cr")
  files.uniq.sort
end

def already_has_header?(content : String) : Bool
  content.each_line do |line|
    stripped = line.strip
    next if stripped.empty?
    return stripped.starts_with?("#")
  end
  false
end

def file_description_for(path : String) : String
  basename = File.basename(path)
  if path == "src/asset_pipeline.cr"
    return "Top-level entry point of the asset_pipeline shard: FrontLoader + namespace setup."
  end
  if path.starts_with?("src/asset_pipeline/")
    desc = ASSET_PIPELINE_DESCRIPTIONS[basename]?
    return desc if desc
    return "Internal module of the asset_pipeline shard."
  end
  if path.starts_with?("src/ui/views/_gate_stubs/")
    stem = basename.sub(/\.cr$/, "")
    return "Compile-time gate stub for `UI::#{snake_to_pascal(stem)}` on non-target platforms."
  end
  if path.starts_with?("src/ui/views/")
    stem = basename.sub(/\.cr$/, "")
    desc = VIEW_DESCRIPTIONS[stem]?
    return desc if desc
    return "Tier-1/2 UI::View for the asset_pipeline cross-platform component system."
  end
  if path.starts_with?("src/ui/")
    desc = UI_TOPLEVEL_DESCRIPTIONS[basename]?
    return desc if desc
  end
  "Public surface file of the asset_pipeline shard."
end

def snake_to_pascal(s : String) : String
  s.split('_').map(&.capitalize).join
end

def part_of_line_for(path : String) : String
  if path.starts_with?("src/ui/views/")
    "Part of the asset_pipeline cross-platform UI::View catalog."
  elsif path.starts_with?("src/ui/")
    "Part of the asset_pipeline cross-platform UI surface."
  else
    "Part of the asset_pipeline shard."
  end
end

# Prepend `header` to `content` if the file is missing a top-of-file
# comment header. Returns the (possibly-modified) content.
def ensure_file_header(content : String, header_lines : Array(String)) : String
  return content if already_has_header?(content)
  prefix = header_lines.map { |line| "# #{line}".rstrip }.join("\n") + "\n\n"
  prefix + content
end

# Replace `# TODO: Write documentation for X` placeholders with the
# resolved summary from `TYPE_DESCRIPTIONS` (or a generic fallback).
def replace_todo_doc_placeholders(content : String, fallback_summary : String) : String
  content.gsub(/^(\s*)#\s*TODO:\s*Write documentation for\s+`?([A-Za-z_][A-Za-z0-9_:]*)`?\s*$/m) do
    indent = $1
    name = $2.split("::").last
    summary = TYPE_DESCRIPTIONS[name]? || fallback_summary
    "#{indent}# #{summary}"
  end
end

# Matches a public type declaration. Captures:
#   $1 indent  $2 keyword (class|module|struct, possibly "abstract class")
#   $3 type name
TYPE_PATTERN = /^(\s*)(?:(abstract\s+)?(class|module|struct))\s+([A-Z][A-Za-z0-9_]*)(?:\s*\([^)]*\))?(?:\s*<\s*[^#\n]+)?\s*(?:#.*)?$/

# Insert a 1-2 sentence summary above every `class / module / struct`
# declaration that lacks a `#` comment on the prior non-blank line.
# Restricts depth to ≤ single nesting (indent ≤ 2 spaces) so we don't
# annotate inner private helper types.
def ensure_type_summaries(content : String, file_path : String) : String
  fallback = file_description_for(file_path)
  lines = content.lines(chomp: false)
  result = [] of String
  lines.each_with_index do |line, idx|
    if m = TYPE_PATTERN.match(line)
      indent = m[1]
      type_name = m[4]
      # Restrict to outer or single-nest declarations (≤ 2 space indent).
      if indent.size <= 2
        # Find the prior non-blank line.
        prev_idx = idx - 1
        while prev_idx >= 0 && lines[prev_idx].strip.empty?
          prev_idx -= 1
        end
        prev_line = prev_idx >= 0 ? lines[prev_idx] : nil
        # If no `#` comment immediately above, insert a summary.
        if prev_line.nil? || !prev_line.strip.starts_with?("#")
          summary = TYPE_DESCRIPTIONS[type_name]? || fallback
          result << "#{indent}# #{summary}\n"
        end
      end
    end
    result << line
  end
  result.join
end

modified_files = [] of String
files_with_header = 0
files_with_at_least_one_summary = 0
files_with_both = 0
total_files = 0

in_scope_files.each do |path|
  next unless File.file?(path)
  total_files += 1
  content = File.read(path)
  original = content

  # 1. Ensure file header.
  header_lines = [file_description_for(path), part_of_line_for(path)]
  content = ensure_file_header(content, header_lines)

  # 2. Replace TODO placeholders.
  content = replace_todo_doc_placeholders(content, file_description_for(path))

  # 3. Insert per-type summaries.
  content = ensure_type_summaries(content, path)

  if content != original
    File.write(path, content)
    modified_files << path
  end

  # Recompute coverage from the FINAL on-disk content.
  final = File.read(path)
  has_header = already_has_header?(final)
  has_summary = false
  final.lines.each_with_index do |line, i|
    if (m = TYPE_PATTERN.match(line)) && m[1].size <= 2
      # Check for a `#` comment immediately above.
      prev_idx = i - 1
      while prev_idx >= 0 && final.lines[prev_idx].strip.empty?
        prev_idx -= 1
      end
      prev = prev_idx >= 0 ? final.lines[prev_idx] : nil
      if prev && prev.strip.starts_with?("#")
        has_summary = true
        break
      end
    end
  end
  files_with_header += 1 if has_header
  files_with_at_least_one_summary += 1 if has_summary
  files_with_both += 1 if has_header && has_summary
end

puts "Scaffolded #{modified_files.size} files (modified) of #{total_files} in scope."
modified_files.each { |p| puts "  + #{p}" }
puts ""
puts "Coverage on the #{total_files} in-scope files:"
puts "  files with file header             : #{files_with_header} / #{total_files}"
puts "  files with ≥1 public-type summary  : #{files_with_at_least_one_summary} / #{total_files}"
puts "  files with BOTH                    : #{files_with_both} / #{total_files}"
