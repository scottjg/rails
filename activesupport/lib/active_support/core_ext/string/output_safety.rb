module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module String #:nodoc:
      module OutputSafety
        def html_safe?
          defined?(@_rails_html_safe) && @_rails_html_safe
        end

        def html_safe!
          @_rails_html_safe = true
          self
        end
      end
    end
  end
end