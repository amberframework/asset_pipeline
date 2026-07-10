# Asset Pipeline — Amber-integration CLI generator.
#
# Generates the per-controller-action ECR shim template that the
# Amber integration requires (see `src/asset_pipeline/amber_integration.cr`
# for the full rationale: Amber's render macro expands to
# `Kilt.render("path/template")` at compile time and we cannot
# reliably emit templates from Crystal macros — they must exist on
# disk before compilation).
#
# Usage from a consuming app:
#
#   bin/asset_pipeline_amber generate sign_in index
#
# Writes `src/views/sign_in/index.ecr` containing the single line:
#
#   <%= @screen_html %>
#
# Existing files are NOT overwritten; the generator exits with a
# warning if the target already exists.

module AssetPipeline
  module CLI
    module AmberGenerator
      SHIM_TEMPLATE = "<%= @screen_html %>\n"

      # Entry point. `args` is typically `ARGV` from `bin/asset_pipeline_amber`.
      # Returns the process exit code (0 on success, non-zero on usage
      # error or filesystem failure).
      def self.run(args : Array(String), views_root : String = "src/views", io : IO = STDOUT, err : IO = STDERR) : Int32
        if args.size < 1 || args[0] == "--help" || args[0] == "-h"
          print_usage(err)
          return args.size < 1 ? 1 : 0
        end

        case args[0]
        when "generate"
          generate_command(args[1..], views_root, io, err)
        else
          err.puts "Unknown command: #{args[0]}"
          print_usage(err)
          1
        end
      end

      private def self.generate_command(args : Array(String), views_root : String, io : IO, err : IO) : Int32
        if args.size != 2
          err.puts "generate requires exactly 2 args: <controller> <action>"
          err.puts "  e.g. bin/asset_pipeline_amber generate sign_in index"
          return 1
        end

        controller = args[0].strip
        action = args[1].strip

        if !valid_identifier?(controller) || !valid_identifier?(action)
          err.puts "controller and action must be snake_case identifiers (a-z 0-9 _)"
          return 1
        end

        dir = File.join(views_root, controller)
        path = File.join(dir, "#{action}.ecr")

        if File.exists?(path)
          err.puts "Refusing to overwrite existing file: #{path}"
          return 1
        end

        begin
          Dir.mkdir_p(dir)
          File.write(path, SHIM_TEMPLATE)
        rescue ex : Exception
          err.puts "Failed to write #{path}: #{ex.message}"
          return 1
        end

        io.puts "Created shim template: #{path}"
        0
      end

      private def self.valid_identifier?(s : String) : Bool
        !s.empty? && s.matches?(/\A[a-z][a-z0-9_]*\z/)
      end

      private def self.print_usage(io : IO) : Nil
        io.puts <<-USAGE
        asset_pipeline_amber — Amber integration helper

        Commands:
          generate <controller> <action>
              Creates src/views/<controller>/<action>.ecr containing the
              one-line shim `<%= @screen_html %>`. This is the template
              that the `UI::ScreenHelpers#compute_screen_html` path
              renders into — Amber's `render` macro requires a template
              on disk; the controller stashes the rendered HTML in
              `@screen_html` and the shim echoes it.

        Examples:
          bin/asset_pipeline_amber generate sign_in index
          bin/asset_pipeline_amber generate sign_in submit
        USAGE
      end
    end
  end
end
