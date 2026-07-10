require "../spec_helper"
require "file_utils"
require "json"

private SCRIPT       = File.expand_path("../../../scripts/validate_design_system_manifest.cr", __DIR__)
private FIXTURE_ROOT = File.expand_path("../test_output/manifest_validator", __DIR__)

private def run_manifest_validator(manifest_path : String) : {Process::Status, String, String}
  output = IO::Memory.new
  error = IO::Memory.new
  status = Process.run("crystal", ["run", SCRIPT, "--", manifest_path], output: output, error: error)
  {status, output.to_s, error.to_s}
end

private def write_valid_page(path : String, body = "") : Nil
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, <<-HTML)
  <!doctype html>
  <html lang="en">
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Fixture</title>
  </head>
  <body>
    <main id="main">
      <h1>Fixture</h1>
      #{body}
    </main>
  </body>
  </html>
  HTML
end

describe "validate_design_system_manifest.cr" do
  before_each do
    FileUtils.rm_rf(FIXTURE_ROOT)
    FileUtils.mkdir_p(FIXTURE_ROOT)
  end

  after_each do
    FileUtils.rm_rf(FIXTURE_ROOT)
  end

  it "validates a consuming-app manifest relative to the manifest file" do
    app = File.join(FIXTURE_ROOT, "app")
    write_valid_page(File.join(app, "output/index.html"), <<-HTML)
    <label for='email'>Email</label>
    <input id='email' type='email' aria-describedby='email-help'>
    <p id='email-help'>Use a work email.</p>
    <section data-component='field' data-ap-validate></section>
    HTML
    FileUtils.mkdir_p(File.join(app, "public/js"))
    File.write(File.join(app, "public/js/design-system.js"), "window.App = {};")
    manifest = File.join(app, "design-system.routes.yml")
    File.write(manifest, <<-YAML)
    site:
      root: output
      artifacts: results
      runtime_files:
        - public/js/design-system.js
    forbidden:
      classes:
        - btn
      runtime_terms:
        - "@hotwired/stimulus"
      inline_handlers: true
    pages:
      - name: home
        path: index.html
        title: Fixture
        required_components:
          - field
        required_hooks:
          - data-ap-validate
    YAML

    status, output, error = run_manifest_validator(manifest)

    status.success?.should eq(true), error
    output.should contain("Design-system manifest static audit passed")
    result = JSON.parse(File.read(File.join(app, "results/static-manifest-audit.json")))
    result["passed"].as_bool.should eq(true)
    result["root"].as_s.should eq(File.join(app, "output"))
  end

  it "honors explicit false for static checks and inline handler checks" do
    app = File.join(FIXTURE_ROOT, "false-options")
    FileUtils.mkdir_p(File.join(app, "output"))
    File.write(File.join(app, "output/index.html"), %(<button onclick="save()">Save</button>))
    manifest = File.join(app, "design-system.routes.yml")
    File.write(manifest, <<-YAML)
    site:
      root: output
      artifacts: results
    defaults:
      checks:
        static: false
    forbidden:
      inline_handlers: false
    pages:
      - name: loose
        path: index.html
    YAML

    status, _, error = run_manifest_validator(manifest)

    status.success?.should eq(true), error
  end

  it "fails cleanly when pages are missing" do
    app = File.join(FIXTURE_ROOT, "missing-pages")
    FileUtils.mkdir_p(app)
    manifest = File.join(app, "design-system.routes.yml")
    File.write(manifest, <<-YAML)
    site:
      root: output
      artifacts: results
    YAML

    status, _, error = run_manifest_validator(manifest)

    status.success?.should eq(false)
    error.should contain("pages must contain at least one page")
  end

  it "fails cleanly when a page path is missing" do
    app = File.join(FIXTURE_ROOT, "missing-path")
    FileUtils.mkdir_p(app)
    manifest = File.join(app, "design-system.routes.yml")
    File.write(manifest, <<-YAML)
    site:
      root: output
      artifacts: results
    pages:
      - name: broken
    YAML

    status, _, error = run_manifest_validator(manifest)

    status.success?.should eq(false)
    error.should contain("broken page path is required")
  end

  it "fails when forbidden terms appear in runtime files" do
    app = File.join(FIXTURE_ROOT, "runtime-term")
    write_valid_page(File.join(app, "output/index.html"))
    FileUtils.mkdir_p(File.join(app, "public/js"))
    File.write(File.join(app, "public/js/design-system.js"), "import '@hotwired/stimulus';")
    manifest = File.join(app, "design-system.routes.yml")
    File.write(manifest, <<-YAML)
    site:
      root: output
      artifacts: results
      runtime_files:
        - public/js/design-system.js
    forbidden:
      runtime_terms:
        - "@hotwired/stimulus"
    pages:
      - name: home
        path: index.html
    YAML

    status, _, error = run_manifest_validator(manifest)

    status.success?.should eq(false)
    error.should contain(%(home does not include forbidden runtime term "@hotwired/stimulus"))
  end
end
