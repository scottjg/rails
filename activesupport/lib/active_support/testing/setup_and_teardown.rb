require 'active_support/callbacks'

module ActiveSupport
  module Testing
    module SetupAndTeardown
      def self.included(base)
        base.class_eval do
          include ActiveSupport::Callbacks
          define_callbacks :setup, :teardown

          include SetupMethods
        end
      end

      module SetupMethods
        def before_setup
          run_callbacks :setup
          super
        end

        def after_teardown
          super
          run_callbacks :teardown
        end
      end

    end
  end
end
