module Rails
  module PluginManager
    module Helpers
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
