require 'rack/session/abstract/id'

module ActionDispatch
  class Request < Rack::Request
    Session = Rack::Session::Abstract::SessionHash # :nodoc:

    Session::ENV_SESSION_KEY         = Rack::Session::Abstract::ENV_SESSION_KEY # :nodoc:
    Session::ENV_SESSION_OPTIONS_KEY = Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY # :nodoc:
  end
end
