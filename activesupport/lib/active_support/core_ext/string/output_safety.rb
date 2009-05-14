module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module String #:nodoc:
      module OutputSafety
        def self.included(base)
          base.class_eval do
            alias_method :add_without_safety, :+
            alias_method :+, :add_with_safety
          end
        end

        def html_safe?
          defined?(@_rails_html_safe) && @_rails_html_safe
        end

        def html_safe!
          @_rails_html_safe = true
          self
        end

        def add_with_safety(other)
          result = add_without_safety(other)
          if html_safe? && other.respond_to?(:html_safe?) && other.html_safe?
            result.html_safe!
          else
            result
          end
        end
      end
    end
  end
end