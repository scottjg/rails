
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
      uri_scheme = URI.parse(uri).scheme.to_sym

      supported_schemes = Hash.new { |h, k| h[k] = [] }
      implementations.each do |impl|
        impl.supported_uri_schemes.each { |scheme| supported_schemes[scheme] << impl }
      end

      candidates = supported_schemes[uri_scheme]
      case candidates.length
      when 0
        raise ArgumentError, "No Plugin Manager installed for the URI scheme `#{scheme}`"
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
