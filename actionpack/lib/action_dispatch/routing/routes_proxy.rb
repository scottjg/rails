module ActionDispatch
  module Routing
    class RoutesProxy #:nodoc:
      include ActionDispatch::Routing::UrlFor

      class_attribute :helpers
      self.helpers = {}

      attr_reader :scope, :routes, :app, :helpers_proxy
      alias :_routes :routes

      def initialize(routes, scope, app)
        @routes, @scope, @app = routes, scope, app

        self.class.helpers[app] ||= prepare_helpers_proxy
        @helpers_proxy = self.class.helpers[app]
      end

      def prepare_helpers_proxy
        helpers = Module.new

        paths = if app.config.respond_to?(:helpers_paths)
          app.config.helpers_paths
        else
          app.paths["app/helpers"].existent
        end

        all = ActionController::Base.send(:all_helpers_from_path, paths)
        ActionController::Base.send(:modules_for_helpers, all).each do |mod|
          helpers.send(:include, mod)
        end
        ActionView::Base.new.extend(helpers)
      end

      def url_options
        scope.send(:_with_routes, routes) do
          scope.url_options
        end
      end

      def method_missing(method, *args)
        if helpers_proxy.respond_to?(method)
          self.class.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{method}(*args)
              helpers_proxy.send("#{method}", *args)
            end
          RUBY
          send(method, *args)
        elsif routes.url_helpers.respond_to?(method)
          self.class.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{method}(*args)
              options = args.extract_options!
              args << url_options.merge((options || {}).symbolize_keys)
              routes.url_helpers.#{method}(*args)
            end
          RUBY
          send(method, *args)
        else
          super
        end
      end
    end
  end
end
