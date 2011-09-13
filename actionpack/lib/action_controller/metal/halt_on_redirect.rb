module ActionController
  class RedirectOccuredException < Exception; end
  # Implements Halt-On-Redirect behavior. If the halt_on_redirect setting is enabled
  # then AbstractController::RedirectOccuredException is raised, which will be caught 
  # elsewhere.
  module HaltOnRedirect
    extend ActiveSupport::Concern


    def redirect_to(*args)
      result = super
      raise ActionController::RedirectOccuredException if halt_on_redirect
      result
    end

    def halt_on_redirect
      request.env["action_dispatch.halt_on_redirect"]
    end

  end

end
