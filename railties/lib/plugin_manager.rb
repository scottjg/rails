
$:.unshift(File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__) + "/../../activesupport/lib")

require 'plugin_manager/commands'

module Rails::PluginManager
  extend Rails::PluginManager::Commands

  class << self
    def add_plugin_implementation(uri_scheme, implementation)
      implementations[uri_scheme.to_sym] = implementation
    end

    def find_plugin_implementation(uri)
      scheme = URI.parse(uri).scheme
      implementation = implementations[scheme.to_sym]
      if implementation.nil?
        raise ArgumentError, "No Plugin Manager installed for the URI scheme `#{scheme}`"
      end
      implementation
    end

    private

      def implementations
        @implementations ||= {}
      end
  end
end

require 'plugin_manager/plugin'
require 'plugin_manager/git_plugin'
