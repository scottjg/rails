
$:.unshift(File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__) + "/../../activesupport/lib")

module Rails::PluginManager
  class << self
    def install(uri, options = {})
      manager = find_plugin_manager(uri)
      name = options[:name] || manager.extract_name(uri)
      manager.install(uri, name, options)
    end

    def find_plugin_manager(uri)
      scheme = URI.parse(uri).scheme
      manager = @managers[scheme.to_sym]
      if manager.nil?
        raise ArgumentError, "No Plugin Manager installed for the URI scheme `#{scheme}`"
      end
      manager.new
    end

    def add_plugin_manager(uri_scheme, manager)
      @managers ||= {}
      @managers[uri_scheme.to_sym] = manager
    end
  end
end

require 'plugin_manager/base'
require 'plugin_manager/managers/git_plugin_manager'
