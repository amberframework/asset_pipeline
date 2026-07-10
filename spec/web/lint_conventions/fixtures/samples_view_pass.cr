# fixture_for: family_1/view_subclass_under_views_dir
# expected: pass
# synthetic_path: samples/initiative-cross-platform-ui-voyager/fake_inline_view.cr
#
# A `< UI::View` subclass declared inside the samples/ tree must pass
# because the configurable allowlist permits samples/ by default.

module Samples
  class FakeInlineView < UI::View
    def initialize
    end
  end
end
