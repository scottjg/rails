require "action_dispatch"
require "rails"

module ActionDispatch
  class Railtie < Rails::Railtie
    config.action_dispatch = ActiveSupport::OrderedOptions.new
    config.action_dispatch.x_sendfile_header = ""
    config.action_dispatch.ip_spoofing_check = true
    config.action_dispatch.show_exceptions = true
    config.action_dispatch.best_standards_support = true
    config.action_dispatch.dump_session_on_error = true
    config.action_dispatch.dump_environment_on_error = false
  end
end
