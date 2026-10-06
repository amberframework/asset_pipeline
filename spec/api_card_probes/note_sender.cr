require "./probe_support"

sender = APICardProbeSender.new
typeof(sender.set_color("target", :setColor, nil)).should eq(Nil)
