$:.unshift File.dirname(__FILE__) + "/../lib"

module Rails
  module PluginManager
    class MercurialPlugin < Plugin
      def install
      end

      def remove(options = {})
      end

      def extract_name
      end

      def self.supported_uri_schemes
      end
    end

    PluginManager.add_plugin_implementation(MercurialPlugin)
  end
end

