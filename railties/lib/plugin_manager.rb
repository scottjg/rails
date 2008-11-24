
$:.unshift(File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__) + "/../../activesupport/lib")

require 'plugin_manager/commands'

module Rails::PluginManager
  extend Rails::PluginManager::Commands

  class << self
    def add_plugin_implementation(implementation)
      implementations << implementation
    end

    def find_plugin_implementation(uri)
      candidates = implementations.select { |impl| impl.can_handle_uri?(uri) }

      case candidates.length
      when 0
        raise ArgumentError, "No Plugin Manager can install the plugin at `#{uri}.`"
      when 1
        candidates.first
      else
        # TODO: Use heuristics to determine which implementation to use.
      end
    end

    private

      def implementations
        @implementations ||= []
      end
  end
end

require 'plugin_manager/plugin'
require 'plugin_manager/git_plugin'
require 'plugin_manager/mercurial_plugin'
