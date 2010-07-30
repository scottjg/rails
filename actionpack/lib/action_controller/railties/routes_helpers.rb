module ActionController
  module Railties
    module RoutesHelpers
      def self.with(routes)
        Module.new do
          define_method(:inherited) do |klass|
            super(klass)
            namespace = ::Rails::Application.extract_namespace(klass)
            if namespace && namespace.respond_to?(:engine) && !namespace.engine.config.shared?
              routes = namespace.engine.routes
            end
            klass.send(:include, routes.url_helpers)
            klass.send(:include, routes.mounted_helpers(:app))
          end
        end
      end
    end
  end
end
