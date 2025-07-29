require "../../spec_helper"
require "../../../src/components/examples/button_component"
require "../../../src/components/examples/card_component"
require "../../../src/components/examples/counter_component"
require "../../../src/components/examples/form_component"

describe "Example Components" do
  describe Components::Examples::ButtonComponent do
    it "renders a basic button" do
      button = Components::Examples::ButtonComponent.new(label: "Click Me")
      rendered = button.render
      
      rendered.should contain("<button")
      rendered.should contain("Click Me")
      rendered.should contain("btn btn-primary btn-medium")
    end
    
    it "supports different variants and sizes" do
      button = Components::Examples::ButtonComponent.new(
        label: "Danger",
        variant: "danger",
        size: "large"
      )
      
      button.render.should contain("btn btn-danger btn-large")
    end
    
    it "can be disabled" do
      button = Components::Examples::ButtonComponent.new(
        label: "Disabled",
        disabled: "true"
      )
      
      rendered = button.render
      rendered.should contain("disabled=\"true\"")
      rendered.should contain("class=\"btn btn-primary btn-medium disabled\"")
    end
    
    it "supports icons" do
      button = Components::Examples::ButtonComponent.new(
        label: "Save",
        icon: "💾"
      )
      
      rendered = button.render
      rendered.should contain("<span class=\"btn-icon\">💾</span>")
      rendered.should contain("Save")
    end
  end
  
  describe Components::Examples::CardComponent do
    it "renders a basic card" do
      card = Components::Examples::CardComponent.new(
        title: "Card Title",
        subtitle: "Card Subtitle"
      )
      card << "Card content goes here"
      
      rendered = card.render
      rendered.should contain("<div class=\"card\">")
      rendered.should contain("<h5 class=\"card-title\">Card Title</h5>")
      rendered.should contain("<h6 class=\"card-subtitle mb-2 text-muted\">Card Subtitle</h6>")
      rendered.should contain("Card content goes here")
    end
    
    it "renders with an image" do
      card = Components::Examples::CardComponent.new(
        title: "Image Card",
        image_url: "/image.jpg",
        image_alt: "Test Image"
      )
      
      rendered = card.render
      rendered.should contain("<img src=\"/image.jpg\" alt=\"Test Image\" class=\"card-img-top\">")
    end
    
    it "renders without optional fields" do
      card = Components::Examples::CardComponent.new
      card << "Just content"
      
      rendered = card.render
      rendered.should contain("<div class=\"card\">")
      rendered.should contain("Just content")
      rendered.should_not contain("card-title")
      rendered.should_not contain("card-subtitle")
    end
  end
  
  describe Components::Examples::CounterComponent do
    it "renders with initial count" do
      counter = Components::Examples::CounterComponent.new
      rendered = counter.render
      
      rendered.should contain("<span class=\"counter-value\">0</span>")
      rendered.should contain("<button")
      rendered.should contain("data-action=\"click-&gt;increment\"")
      rendered.should contain("data-action=\"click-&gt;decrement\"")
      rendered.should contain("data-action=\"click-&gt;reset\"")
    end
    
    it "increments count" do
      counter = Components::Examples::CounterComponent.new
      counter.increment
      
      counter.get_state("count").try(&.as_i?).should eq(1)
      counter.render.should contain("<span class=\"counter-value\">1</span>")
    end
    
    it "decrements count" do
      counter = Components::Examples::CounterComponent.new
      counter.set_state("count", 5)
      counter.decrement
      
      counter.get_state("count").try(&.as_i?).should eq(4)
      counter.render.should contain("<span class=\"counter-value\">4</span>")
    end
    
    it "resets count" do
      counter = Components::Examples::CounterComponent.new
      counter.set_state("count", 10)
      counter.reset
      
      counter.get_state("count").try(&.as_i?).should eq(0)
      counter.render.should contain("<span class=\"counter-value\">0</span>")
    end
  end
  
  describe Components::Examples::FormComponent do
    it "renders a form with fields" do
      form = Components::Examples::FormComponent.new
      rendered = form.render
      
      rendered.should contain("<form")
      rendered.should contain("data-action=\"submit-&gt;submit\"")
      rendered.should contain("<label for=\"name\">Name")
      rendered.should contain("<input type=\"text\" name=\"name\"")
      rendered.should contain("<label for=\"email\">Email")
      rendered.should contain("<input type=\"email\" name=\"email\"")
      rendered.should contain("<label for=\"message\">Message")
      rendered.should contain("<textarea name=\"message\"")
      rendered.should contain("<button type=\"submit\"")
    end
    
    it "validates required fields" do
      form = Components::Examples::FormComponent.new
      form.submit
      
      errors = form.get_state("errors").try(&.as_h?)
      errors.should_not be_nil
      errors.not_nil!["name"]?.should_not be_nil
      errors.not_nil!["email"]?.should_not be_nil
      errors.not_nil!["message"]?.should_not be_nil
    end
    
    it "validates email format" do
      form = Components::Examples::FormComponent.new
      
      # Set invalid email
      form.field_changed(JSON.parse(%{{"field": "email", "value": "invalid"}}))
      
      errors = form.get_state("errors").try(&.as_h?)
      errors.not_nil!["email"]?.try(&.as_s?).should eq("Please enter a valid email address")
      
      # Set valid email
      form.field_changed(JSON.parse(%{{"field": "email", "value": "test@example.com"}}))
      
      errors = form.get_state("errors").try(&.as_h?)
      errors.not_nil!["email"]?.should be_nil
    end
    
    it "shows success message on valid submission" do
      form = Components::Examples::FormComponent.new
      
      # Fill out form
      form.field_changed(JSON.parse(%{{"field": "name", "value": "John Doe"}}))
      form.field_changed(JSON.parse(%{{"field": "email", "value": "john@example.com"}}))
      form.field_changed(JSON.parse(%{{"field": "message", "value": "Hello"}}))
      
      # Submit
      form.submit
      
      form.get_state("submitted").try(&.as_bool?).should be_true
      form.render.should contain("Form submitted successfully!")
    end
  end
end