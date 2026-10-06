require "./probe_support"

iframe = Components::Elements::Iframe.new
typeof(iframe).should eq(Components::Elements::Iframe)
typeof(iframe.tag_name).should eq(String)
