require "./probe_support"

root = UI::NavigationCoordinator::Route.new(:notes)
navigation = UI::NavigationCoordinator.new(root)
typeof(navigation.current).should eq(UI::NavigationCoordinator::Route)
typeof(navigation.push(UI::NavigationCoordinator::Route.new(:detail, {:id => "42"} of Symbol => String))).should eq(Nil)
