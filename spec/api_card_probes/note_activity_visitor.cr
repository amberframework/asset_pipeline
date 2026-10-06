require "./probe_support"

visitor = APICardProbeVisitor.new
activity_view = UI::ActivityView.new("Share")
activity_view.accept(visitor)
typeof(visitor.visit(activity_view)).should eq(Nil)
