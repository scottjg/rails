module ActionView
  class TestCase < ActiveSupport::TestCase
    include ActionController::TestCase::Assertions

    class_inheritable_accessor :helper_class
    @@helper_class = nil

    class << self
      def tests(helper_class)
        self.helper_class = helper_class
      end

      def helper_class
        if current_helper_class = read_inheritable_attribute(:helper_class)
          current_helper_class
        else
          self.helper_class = determine_default_helper_class(name)
        end
      end

      def determine_default_helper_class(name)
        name.sub(/Test$/, '').constantize
      rescue NameError
        nil
      end
    end

    include ActionView::Helpers
    include ActionController::PolymorphicRoutes
    include ActionController::RecordIdentifier

    setup :setup_with_helper_class

    def setup_with_helper_class
      if helper_class && !self.class.ancestors.include?(helper_class)
        self.class.send(:include, helper_class)
      end

      self.output_buffer = ''
    end

    class TestController < ActionController::Base
      attr_accessor :request, :response

      def initialize
        @request = ActionController::TestRequest.new
        @response = ActionController::TestResponse.new
      end
    end

    protected
      attr_accessor :output_buffer

    private
      def method_missing(selector, *args)
        @controller ||= TestController.new
        if @controller.class.installed_route_set.named_routes.helpers.include?(selector.to_sym)
          @controller.send(:assign_shortcuts, ActionController::TestRequest.new, ActionController::TestResponse.new)
          @controller.send(:initialize_current_url)
          @controller.__send__(selector, *args)
        else
          super
        end
      end
  end
end
