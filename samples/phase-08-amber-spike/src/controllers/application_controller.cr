# Phase 8 spike — base controller. All controllers extend this so they
# inherit Amber's full surface + the UI::ScreenHelpers mixin.
class ApplicationController < Amber::Controller::Base
  include UI::ScreenHelpers

  LAYOUT = "application.ecr"
end
