module Rails
  module PluginManager
    class Base
      class << self

        # Installs a plugin into the Rails application.
        def install(uri, name, options = {})
          raise NotImplementedError, "This plugin manager does not support installing plugins."
        end

        def remove(name, options = {})
          raise NotImplementedError, "This plugin manager does not support removing plugins."
        end

        def has_installed?(name)
          false
        end

        include Helpers
      end
    end
  end
end
