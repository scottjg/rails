module ActionView
  # NOTE: The template that this mixin is being included into is frozen
  # so you cannot set or modify any instance variables
  module RenderablePartial #:nodoc:
    extend ActiveSupport::Memoizable

    def variable_name
      name.sub(/\A_/, '').to_sym
    end
    memoize :variable_name

    def counter_name
      "#{variable_name}_counter".to_sym
    end
    memoize :counter_name

    def render(context, local_assigns = {}, &block)
      if defined? ActionController
        ActionController::Base.benchmark("Rendered #{path_without_format_and_extension}", Logger::DEBUG, false) do
          super
        end
      else
        super
      end
    end
  end
end
