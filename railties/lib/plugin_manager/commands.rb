
module Rails
  module PluginManager
    module Commands
      def install(uri, options = {})
        plugin = find_plugin_implementation(uri).new(:uri => uri, :name => options.delete(:name))
        plugin.install(options)
      end
    end
  end
end
