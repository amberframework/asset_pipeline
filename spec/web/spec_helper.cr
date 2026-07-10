require "spec"
require "../../src/asset_pipeline"
require "./support/accessibility_matchers"
require "./support/fake_lib_objc_bridge"
require "./support/phase04_compile_check"

include SpecSupport::AccessibilityMatchers

# Reset the SwiftKit bridge call recorder between specs so each `it`
# block starts from a clean state. Specs that do not touch the bridge
# pay zero cost.
Spec.before_each { FakeLibObjCBridge.reset }
