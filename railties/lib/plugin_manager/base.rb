module Rails
  module PluginManager
    class Base
      # Installs a plugin into the Rails application.
      def install(uri, name, options = {})
        raise NotImplementedError, "This plugin manager does not support installing plugins."
      end

      def remove(name, options = {})
        raise NotImplementedError, "This plugin manager does not support removing plugins."
      end

      def self.has_installed?(name)
        false
      end

      protected
        include Helpers
        extend Helpers
    end
  end
end
