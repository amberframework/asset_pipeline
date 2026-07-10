# fixture_for: family_1/screen_class_naming,family_1/screen_file_suffix
# expected: pass
# synthetic_path: src/screens/sign_in_screen.cr
#
# A well-named UI::Screen subclass in a file with the matching
# snake_case basename. Both naming rules must pass.

class SignInScreen < UI::Screen
  def build(ctx)
  end
end
