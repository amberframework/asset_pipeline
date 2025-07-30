require "../src/components"

# Register some CSS classes
registry = Components::CSS::ClassRegistry.instance
registry.register_class("bg-white")
registry.register_class("rounded-lg")
registry.register_class("shadow-md")
registry.register_class("p-6")
registry.register_class("text-xl")
registry.register_class("font-bold")
registry.register_class("text-gray-900")
registry.register_class("mb-4")

# Create CSS config and generator
config = Components::CSS::Config.new
css_asset = Components::Assets::CSS.create(config, :development)

# Generate the CSS
puts "=== Generated CSS ==="
puts css_asset.process
puts "\n=== Registry Stats ==="
puts Components::CSS::ClassRegistry.instance.export_usage