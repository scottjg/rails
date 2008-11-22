module Rails
  module PluginManager
    class Base
      # Installs a plugin into the Rails application.
      def install(uri, name, options = {})
        raise NotImplementedError, "This plugin manager does not support installing plugins."
      end

      protected
      
        # The directory where plugins are installed.
        def plugins_dir
          "#{RAILS_ROOT}/vendor/plugins"
        end
    end
  end
end
