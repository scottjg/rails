require 'action_controller/cgi_ext/stdinput'
require 'action_controller/cgi_ext/query_extension'
require 'action_controller/cgi_ext/cookie'

class CGI #:nodoc:
  include ActionController::CgiExt::Stdinput

  class << self
    alias :escapeHTML_fail_on_nil :escapeHTML

    def escapeHTML(string)
      if string.nil?
        nil
      else
        escapeHTML_fail_on_nil(string)
      end
    end
  end
end
