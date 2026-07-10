# fixture_for: family_1/screen_class_naming
# expected: fail
# synthetic_path: src/screens/sign_in.cr
#
# A UI::Screen subclass whose name does NOT end in "Screen" — must
# trip the screen_class_naming rule.

class SignIn < UI::Screen
  def build(ctx)
  end
end
