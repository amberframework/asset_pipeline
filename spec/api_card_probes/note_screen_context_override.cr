require "./probe_support"

class APICardScreenContext < UI::ScreenContext
  getter params : Hash(String, String) = {} of String => String
  getter params_multi : Hash(String, Array(String)) = {} of String => Array(String)
  getter flash_data : Hash(String, String) = {} of String => String
  getter design_tokens : UI::DesignTokens::Tokens = UI::DesignTokens::Tokens.default
  getter csrf_token : String? = nil
end

context = APICardScreenContext.new
typeof(context.params).should eq(Hash(String, String))
