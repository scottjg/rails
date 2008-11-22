module Rails
  module PluginManager
    class Base
      # Installs a plugin into the Rails application.
      def install(uri, name, options = {})
        raise NotImplementedError, "This plugin manager does not support installing plugins."
      end

      protected
      
        # The directory where plugins are installed.
        def relative_plugins_dir
          "vendor/plugins"
        end

        def plugins_dir
          "#{RAILS_ROOT}/#{relative_plugins_dir}"
        end
    end
  end
end
