# UI::Probes — Crystal-side singletons backing Phase 3 behavior probes.
#
# Group BX of the Phase 3 validation rubric drives a small set of end-to-end
# probes that prove the SwiftKit bridge actually fires Crystal procs at
# runtime. Each probe slug renders a focal control whose action mutates a
# probe singleton, and an adjacent label mirrors that mutation. The XCUITest
# / AXTest harnesses read the label to assert the round-trip worked.
#
# These singletons are isolated to the sample-host process; they are not
# part of the public UI::View surface. They exist so the rubric can drive
# behavior assertions without freelancing app-specific state.

require "./probes/probe_store"
require "./probes/tap_probe"
require "./probes/toggle_probe"
require "./probes/slider_probe"
require "./probes/dismiss_probe"
require "./probes/form_row_probe"
require "./probes/runtime_override_probe"
