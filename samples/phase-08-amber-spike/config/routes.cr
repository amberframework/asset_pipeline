Amber::Server.configure do
  pipeline :web do
    plug Amber::Pipe::Error.new
    plug Amber::Pipe::Logger.new
    plug Amber::Pipe::Session.new
    plug Amber::Pipe::Flash.new
    plug Amber::Pipe::CSRF.new
  end

  # Phase 8C — Amber router contribution from the unified `UI::App`
  # declaration (see config/application.cr's `SpikeApp`). The
  # `routes_for` macro expands at compile time to a sequence of
  # `get`/`post` calls — one per `web_actions` entry on every screen
  # registered by SpikeApp that declared web metadata.
  #
  # Manual `get`/`post` lines could still be added alongside the
  # `routes_for` call if the app needs hand-rolled routes; the spike
  # has none.
  routes :web do
    UI::AmberIntegration.routes_for(SpikeApp)
  end
end
