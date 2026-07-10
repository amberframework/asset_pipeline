require "../spec_helper"

module OptargConcatenationFeature
  class Model < Optarg::Model
    bool "-a"
    bool "-b"
  end

  it name do
    result = Model.parse(%w(-ab))
    result.a?.should be_true
    result.b?.should be_true
  end
end
