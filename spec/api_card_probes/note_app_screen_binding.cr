require "./probe_support"

class APICardNativeController < UI::Controller
end

class APICardNativeScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("Home")
  end
end

class APICardWebController
end

class APICardNativeApp < UI::App
  initial_route :home
  screen :home, APICardNativeController
  screen :empty, APICardNativeController
end

class APICardWebApp < UI::App
  screen :foo, web_controller: APICardWebController, web_path: "/foo"
  screen :api, web_controller: APICardWebController,
    web_actions: [{verb: :post, action: :create, path: "/api"}]
end

APICardNativeApp.bootstrap!
APICardWebApp.bootstrap!
