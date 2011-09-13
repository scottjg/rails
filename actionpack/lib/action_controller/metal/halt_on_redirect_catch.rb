module ActionController
  # This is the last module to implement the send_action, so
  # it swallows the exception thrown by the halt-on-redirect behavior
  module HaltOnRedirectCatch
    extend ActiveSupport::Concern

    def send_action(*args)
      begin
        result = super
      rescue ActionController::RedirectOccuredException 
        # This exception is thrown to enable halt-on-redirect behavior. Do nothing.        
      end
      result
    end
  end
end
