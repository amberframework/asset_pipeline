# fixture_for: (runner-level exclusion — see family_1_naming_spec.cr)
# expected: skipped_by_runner
# synthetic_path: lib/some_vendored_shard/fake_view.cr
#
# This fixture documents that vendored dependencies under lib/ are
# out-of-scope for the runner's file walk. The rule itself, when
# called directly, would fire on this content — but the runner's
# `discover_files` excludes any path under `/lib/` before rules run.
# Tested explicitly in family_1_naming_spec.cr.

module SomeVendoredShard
  class FakeView < UI::View
    def initialize
    end
  end
end
