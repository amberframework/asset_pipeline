require "../src/components/**"

# Contact Form Component
class ContactFormComponent < Components::StatefulComponent
  protected def initialize_state
    set_state("name", "")
    set_state("email", "")
    set_state("message", "")
    set_state("submitted", false)
    set_state("errors", {} of String => JSON::Any)
  end
  
  def render_content : String
    if get_state("submitted").try(&.as_bool?)
      render_success_message
    else
      render_form
    end
  end
  
  private def render_form : String
    Components::Elements::Form.new(
      class: "contact-form",
      method: "post",
      action: "/contact"
    ).build do |form|
      # Name field
      form << render_field("name", "text", "Your Name", "Enter your full name")
      
      # Email field
      form << render_field("email", "email", "Email Address", "your@email.com")
      
      # Message field
      message_group = Components::Elements::Div.new(class: "form-group")
      
      label = Components::Elements::Label.new(for: "message")
      label << "Message"
      message_group << label
      
      textarea = Components::Elements::Textarea.new(
        name: "message",
        id: "message",
        rows: "5",
        class: "form-control",
        placeholder: "Your message here...",
        required: "required"
      )
      textarea << (get_state("message").try(&.as_s?) || "")
      message_group << textarea
      
      errors = get_state("errors").try(&.as_h?)
      if errors && (error = errors["message"]?)
        error_span = Components::Elements::Span.new(class: "error")
        error_span << error.as_s
        message_group << error_span
      end
      
      form << message_group
      
      # Submit button
      submit_div = Components::Elements::Div.new(class: "form-actions")
      submit_btn = Components::Elements::Button.new(
        type: "submit",
        class: "btn btn-primary"
      )
      submit_btn << "Send Message"
      submit_div << submit_btn
      
      form << submit_div
    end.render
  end
  
  private def render_field(name : String, type : String, label_text : String, placeholder : String) : String
    Components::Elements::Div.new(class: "form-group").build do |group|
      label = Components::Elements::Label.new(for: name)
      label << label_text
      group << label
      
      input = Components::Elements::Input.new(
        type: type,
        name: name,
        id: name,
        class: "form-control",
        placeholder: placeholder,
        value: get_state(name).try(&.as_s?) || "",
        required: "required"
      )
      group << input
      
      errors = get_state("errors").try(&.as_h?)
      if errors && (error = errors[name]?)
        error_span = Components::Elements::Span.new(class: "error")
        error_span << error.as_s
        group << error_span
      end
    end.render
  end
  
  private def render_success_message : String
    Components::Elements::Div.new(class: "alert alert-success").build do |alert|
      h3 = Components::Elements::H3.new
      h3 << "Thank You!"
      alert << h3
      
      p = Components::Elements::P.new
      p << "Your message has been sent successfully. We'll get back to you soon."
      alert << p
      
      button = Components::Elements::Button.new(
        class: "btn btn-secondary",
        onclick: "location.reload()"
      )
      button << "Send Another Message"
      alert << button
    end.render
  end
end

# Product Card Component (for e-commerce example)
class ProductCardComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Div.new(class: "product-card").build do |card|
      # Product image
      if image_url = @attributes["image"]?
        img_wrapper = Components::Elements::Div.new(class: "product-image")
        img = Components::Elements::Img.new(
          src: image_url,
          alt: @attributes["name"]? || "Product",
          loading: "lazy"
        )
        img_wrapper << img
        card << img_wrapper
      end
      
      # Product info
      info = Components::Elements::Div.new(class: "product-info")
      
      # Name
      name = Components::Elements::H3.new(class: "product-name")
      name << (@attributes["name"]? || "Product")
      info << name
      
      # Price
      price = Components::Elements::Div.new(class: "product-price")
      price << "$#{@attributes["price"]? || "0.00"}"
      info << price
      
      # Description
      if desc = @attributes["description"]?
        desc_p = Components::Elements::P.new(class: "product-description")
        desc_p << desc
        info << desc_p
      end
      
      # Add to cart button
      button = Components::Elements::Button.new(
        class: "btn btn-primary add-to-cart",
        "data-product-id": @attributes["id"]? || "0",
        "data-action": "click->addToCart"
      )
      button << "Add to Cart"
      info << button
      
      card << info
    end.render
  end
end

# Shopping Cart Component (Reactive)
class ShoppingCartComponent < Components::Reactive::ReactiveComponent
  protected def initialize_state
    set_state("items", [] of JSON::Any)
    set_state("total", 0.0)
    set_state("is_open", false)
  end
  
  def render_content : String
    Components::Elements::Div.new(class: "shopping-cart").build do |cart|
      # Cart header
      header = Components::Elements::Div.new(class: "cart-header")
      
      title = Components::Elements::H3.new
      title << "Shopping Cart"
      header << title
      
      items = get_state("items").try(&.as_a?) || [] of JSON::Any
      
      badge = Components::Elements::Span.new(class: "cart-count")
      badge << items.size.to_s
      header << badge
      
      toggle_btn = Components::Elements::Button.new(
        class: "cart-toggle",
        "data-action": "click->toggleCart"
      )
      toggle_btn << (get_state("is_open").try(&.as_bool?) ? "Close" : "Open")
      header << toggle_btn
      
      cart << header
      
      # Cart contents (shown when open)
      if get_state("is_open").try(&.as_bool?)
        contents = Components::Elements::Div.new(class: "cart-contents")
        
        if items.empty?
          empty_msg = Components::Elements::P.new(class: "empty-cart")
          empty_msg << "Your cart is empty"
          contents << empty_msg
        else
          # Items list
          items_list = Components::Elements::Div.new(class: "cart-items")
          
          items.each do |item|
            item_div = Components::Elements::Div.new(class: "cart-item")
            
            # Item name
            name_span = Components::Elements::Span.new(class: "item-name")
            name_span << (item["name"]?.try(&.as_s?) || "Item")
            item_div << name_span
            
            # Quantity
            qty_span = Components::Elements::Span.new(class: "item-quantity")
            qty_span << "x#{item["quantity"]?.try(&.as_i?) || 1}"
            item_div << qty_span
            
            # Price
            price_span = Components::Elements::Span.new(class: "item-price")
            price_span << "$#{item["price"]?.try(&.as_f?) || 0.0}"
            item_div << price_span
            
            # Remove button
            remove_btn = Components::Elements::Button.new(
              class: "btn-remove",
              "data-action": "click->removeItem",
              "data-item-id": item["id"]?.try(&.as_s?) || ""
            )
            remove_btn << "×"
            item_div << remove_btn
            
            items_list << item_div
          end
          
          contents << items_list
          
          # Total
          total_div = Components::Elements::Div.new(class: "cart-total")
          total_label = Components::Elements::Span.new
          total_label << "Total:"
          total_div << total_label
          
          total_amount = Components::Elements::Span.new(class: "total-amount")
          total_amount << "$#{"%.2f" % (get_state("total").try(&.as_f?) || 0.0)}"
          total_div << total_amount
          
          contents << total_div
          
          # Checkout button
          checkout_btn = Components::Elements::Button.new(
            class: "btn btn-primary btn-checkout"
          )
          checkout_btn << "Checkout"
          contents << checkout_btn
        end
        
        cart << contents
      end
    end.render
  end
  
  # Action handlers
  def toggle_cart(data : JSON::Any)
    is_open = get_state("is_open").try(&.as_bool?) || false
    set_state("is_open", !is_open)
  end
  
  def add_item(product : Hash(String, JSON::Any))
    items = get_state("items").try(&.as_a?) || [] of JSON::Any
    
    # Check if item already exists
    existing_index = items.index { |item| 
      item["id"]?.try(&.as_s?) == product["id"]?.try(&.as_s?)
    }
    
    if existing_index
      # Update quantity
      item = items[existing_index].as_h
      current_qty = item["quantity"]?.try(&.as_i?) || 1
      item["quantity"] = JSON::Any.new(current_qty + 1)
      items[existing_index] = JSON::Any.new(item)
    else
      # Add new item
      items << JSON::Any.new(product)
    end
    
    set_state("items", items)
    calculate_total
  end
  
  def remove_item(data : JSON::Any)
    item_id = data["item-id"]?.try(&.as_s?)
    return unless item_id
    
    items = get_state("items").try(&.as_a?) || [] of JSON::Any
    items.reject! { |item| item["id"]?.try(&.as_s?) == item_id }
    
    set_state("items", items)
    calculate_total
  end
  
  private def calculate_total
    items = get_state("items").try(&.as_a?) || [] of JSON::Any
    total = items.sum do |item|
      price = item["price"]?.try(&.as_f?) || 0.0
      quantity = item["quantity"]?.try(&.as_i?) || 1
      price * quantity
    end
    
    set_state("total", total)
  end
end

# Full E-commerce Page
class EcommercePage
  def self.generate
    Components::Elements::Html.new(lang: "en").build do |html|
      # Head
      head = Components::Elements::Head.new
      
      # Meta tags
      head << Components::Elements::Meta.new(charset: "UTF-8")
      head << Components::Elements::Meta.new(
        name: "viewport",
        content: "width=device-width, initial-scale=1.0"
      )
      
      # Title
      title = Components::Elements::Title.new
      title << "Crystal Shop - Type-Safe E-commerce"
      head << title
      
      # Styles
      style = Components::Elements::Style.new
      style << css_content
      head << style
      
      html << head
      
      # Body
      body = Components::Elements::Body.new("data-amber-reactive": "true")
      
      # Header
      header = Components::Elements::Header.new(class: "site-header")
      
      container = Components::Elements::Div.new(class: "container")
      
      # Logo
      logo = Components::Elements::H1.new(class: "logo")
      logo << "Crystal Shop"
      container << logo
      
      # Shopping cart
      cart = ShoppingCartComponent.new
      cart.register  # Register for reactive updates
      container << cart.render
      
      header << container
      body << header
      
      # Main content
      main = Components::Elements::Main.new(class: "main-content")
      main_container = Components::Elements::Div.new(class: "container")
      
      # Hero section
      hero = Components::Elements::Section.new(class: "hero")
      hero_h2 = Components::Elements::H2.new
      hero_h2 << "Welcome to Crystal Shop"
      hero << hero_h2
      
      hero_p = Components::Elements::P.new
      hero_p << "Discover amazing products built with type-safe components"
      hero << hero_p
      main_container << hero
      
      # Products grid
      products_section = Components::Elements::Section.new(class: "products")
      products_h2 = Components::Elements::H2.new
      products_h2 << "Featured Products"
      products_section << products_h2
      
      products_grid = Components::Elements::Div.new(class: "products-grid")
      
      # Sample products
      products = [
        {
          id: "1",
          name: "Crystal Shard",
          price: "29.99",
          description: "A beautiful crystal shard for your collection",
          image: "/images/crystal1.jpg"
        },
        {
          id: "2", 
          name: "Ruby Gem",
          price: "49.99",
          description: "Premium ruby gem with perfect clarity",
          image: "/images/ruby1.jpg"
        },
        {
          id: "3",
          name: "Amethyst Cluster", 
          price: "79.99",
          description: "Natural amethyst cluster from Brazil",
          image: "/images/amethyst1.jpg"
        },
        {
          id: "4",
          name: "Quartz Point",
          price: "19.99",
          description: "Clear quartz point for energy work",
          image: "/images/quartz1.jpg"
        }
      ]
      
      products.each do |product|
        product_card = ProductCardComponent.new(**product)
        products_grid << product_card.render
      end
      
      products_section << products_grid
      main_container << products_section
      
      # Contact form section
      contact_section = Components::Elements::Section.new(class: "contact")
      contact_h2 = Components::Elements::H2.new
      contact_h2 << "Get in Touch"
      contact_section << contact_h2
      
      contact_form = ContactFormComponent.new
      contact_section << contact_form.render
      
      main_container << contact_section
      
      main << main_container
      body << main
      
      # Footer
      footer = Components::Elements::Footer.new(class: "site-footer")
      footer_container = Components::Elements::Div.new(class: "container")
      
      footer_p = Components::Elements::P.new
      footer_p << "© 2023 Crystal Shop. Built with Crystal Components."
      footer_container << footer_p
      
      footer << footer_container
      body << footer
      
      # Add reactive JavaScript
      body << Components::Integration.reactive_script_tag(debug: true)
      
      html << body
    end.render
  end
  
  private def self.css_content : String
    <<-CSS
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #333;
      background-color: #f5f5f5;
    }
    
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 20px;
    }
    
    /* Header */
    .site-header {
      background-color: #fff;
      box-shadow: 0 2px 5px rgba(0,0,0,0.1);
      position: sticky;
      top: 0;
      z-index: 100;
    }
    
    .site-header .container {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 1rem 20px;
    }
    
    .logo {
      color: #6c5ce7;
      font-size: 1.5rem;
    }
    
    /* Shopping Cart */
    .shopping-cart {
      position: relative;
    }
    
    .cart-header {
      display: flex;
      align-items: center;
      gap: 1rem;
    }
    
    .cart-count {
      background-color: #e74c3c;
      color: white;
      border-radius: 50%;
      width: 24px;
      height: 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 0.8rem;
      font-weight: bold;
    }
    
    .cart-contents {
      position: absolute;
      right: 0;
      top: 100%;
      background: white;
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 1rem;
      min-width: 300px;
      box-shadow: 0 5px 20px rgba(0,0,0,0.1);
      margin-top: 0.5rem;
    }
    
    .cart-item {
      display: grid;
      grid-template-columns: 1fr auto auto auto;
      gap: 1rem;
      padding: 0.5rem 0;
      border-bottom: 1px solid #eee;
    }
    
    .cart-total {
      display: flex;
      justify-content: space-between;
      font-weight: bold;
      margin-top: 1rem;
      padding-top: 1rem;
      border-top: 2px solid #eee;
    }
    
    /* Hero */
    .hero {
      text-align: center;
      padding: 4rem 0;
      background-color: #6c5ce7;
      color: white;
      margin-bottom: 3rem;
      border-radius: 8px;
    }
    
    .hero h2 {
      font-size: 2.5rem;
      margin-bottom: 1rem;
    }
    
    /* Products */
    .products {
      margin-bottom: 4rem;
    }
    
    .products h2 {
      text-align: center;
      margin-bottom: 2rem;
      color: #2c3e50;
    }
    
    .products-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
      gap: 2rem;
    }
    
    .product-card {
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
      transition: transform 0.3s;
    }
    
    .product-card:hover {
      transform: translateY(-5px);
    }
    
    .product-image {
      height: 200px;
      background-color: #f0f0f0;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .product-image img {
      max-width: 100%;
      height: 100%;
      object-fit: cover;
    }
    
    .product-info {
      padding: 1rem;
    }
    
    .product-name {
      margin-bottom: 0.5rem;
      color: #2c3e50;
    }
    
    .product-price {
      font-size: 1.5rem;
      color: #6c5ce7;
      font-weight: bold;
      margin-bottom: 0.5rem;
    }
    
    .product-description {
      color: #666;
      font-size: 0.9rem;
      margin-bottom: 1rem;
    }
    
    /* Forms */
    .contact {
      max-width: 600px;
      margin: 0 auto 4rem;
    }
    
    .contact h2 {
      text-align: center;
      margin-bottom: 2rem;
      color: #2c3e50;
    }
    
    .contact-form {
      background: white;
      padding: 2rem;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    
    .form-group {
      margin-bottom: 1.5rem;
    }
    
    .form-group label {
      display: block;
      margin-bottom: 0.5rem;
      color: #555;
      font-weight: 500;
    }
    
    .form-control {
      width: 100%;
      padding: 0.75rem;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 1rem;
      transition: border-color 0.3s;
    }
    
    .form-control:focus {
      outline: none;
      border-color: #6c5ce7;
    }
    
    textarea.form-control {
      resize: vertical;
      min-height: 120px;
    }
    
    .error {
      color: #e74c3c;
      font-size: 0.875rem;
      margin-top: 0.25rem;
      display: block;
    }
    
    /* Buttons */
    .btn {
      padding: 0.75rem 1.5rem;
      border: none;
      border-radius: 4px;
      font-size: 1rem;
      cursor: pointer;
      transition: all 0.3s;
      text-decoration: none;
      display: inline-block;
    }
    
    .btn-primary {
      background-color: #6c5ce7;
      color: white;
    }
    
    .btn-primary:hover {
      background-color: #5f4dd8;
    }
    
    .btn-secondary {
      background-color: #95a5a6;
      color: white;
    }
    
    .btn-secondary:hover {
      background-color: #7f8c8d;
    }
    
    .add-to-cart {
      width: 100%;
    }
    
    .btn-checkout {
      width: 100%;
      margin-top: 1rem;
    }
    
    /* Alerts */
    .alert {
      padding: 1.5rem;
      border-radius: 4px;
      margin-bottom: 1rem;
    }
    
    .alert-success {
      background-color: #d4edda;
      color: #155724;
      border: 1px solid #c3e6cb;
    }
    
    .alert h3 {
      margin-bottom: 0.5rem;
    }
    
    /* Footer */
    .site-footer {
      background-color: #2c3e50;
      color: white;
      text-align: center;
      padding: 2rem 0;
      margin-top: 4rem;
    }
    CSS
  end
end

# Generate the e-commerce page
def generate_ecommerce_site
  Dir.mkdir_p("output")
  
  content = EcommercePage.generate
  File.write("output/shop.html", content)
  
  puts "Generated: output/shop.html (#{content.bytesize} bytes)"
  puts "\nE-commerce page generated successfully!"
  puts "This page demonstrates:"
  puts "- Reactive shopping cart component"
  puts "- Product catalog with cards"
  puts "- Contact form with validation"
  puts "- Responsive grid layout"
  puts "- Interactive UI elements"
end

# Run the generator
generate_ecommerce_site