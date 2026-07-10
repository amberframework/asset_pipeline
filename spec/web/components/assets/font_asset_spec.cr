require "../../spec_helper"
require "../../../../src/components/assets/font_asset"

describe Components::Assets::FontAsset do
  it "emits CDN stylesheet links" do
    font = Components::Assets::FontAsset.cdn("Inter", "https://fonts.example/inter.css")

    font.link_tags.should contain(%(<link rel="preconnect" href="https://fonts.example" crossorigin>))
    font.link_tags.should contain(%(<link rel="stylesheet" href="https://fonts.example/inter.css">))
    font.font_face_css.should eq("")
  end

  it "emits self-hosted preload links and font-face CSS" do
    font = Components::Assets::FontAsset.self_hosted(
      "Inter",
      "/assets/fonts/inter-var.woff2",
      weight: "100 900",
      display: "swap",
    )

    font.link_tags.should contain(%(rel="preload"))
    font.link_tags.should contain(%(as="font"))
    font.font_face_css.should contain("@font-face")
    font.font_face_css.should contain("font-family: \"Inter\"")
    font.font_face_css.should contain("font-display: swap")
  end
end

describe Components::Assets::FontManifest do
  it "combines CDN and self-hosted strategies" do
    manifest = Components::Assets::FontManifest.new
    manifest << Components::Assets::FontAsset.cdn("Newsreader", "https://fonts.example/newsreader.css")
    manifest << Components::Assets::FontAsset.self_hosted("Inter", "/assets/inter.woff2")

    manifest.link_tags.should contain("newsreader.css")
    manifest.link_tags.should contain("/assets/inter.woff2")
    manifest.font_face_css.should contain("Inter")
    manifest.font_face_css.should_not contain("Newsreader")
  end
end
