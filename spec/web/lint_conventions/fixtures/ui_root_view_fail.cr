# fixture_for: family_1/view_subclass_under_views_dir
# expected: fail
# synthetic_path: src/ui/fake_marker.cr
#
# A `< UI::View` subclass declared under src/ui/ (NOT src/ui/views/)
# must fire the rule. Library + production code may not stash view
# subclasses outside the approved roots.

module UI
  class FakeMarker < View
    def initialize
    end
  end
end
