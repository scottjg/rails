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

      def has_installed?(name)
        false
      end

      protected
      
        # The directory where plugins are installed.
        def relative_plugins_dir
          "vendor/plugins"
        end

        def plugins_dir
          "#{RAILS_ROOT}/#{relative_plugins_dir}"
        end

        def install_path(name)
          "#{relative_plugins_dir}/#{name}"
        end
    end
  end
end
