$:.unshift File.dirname(__FILE__) + "/../lib"

require 'plugin_manager/plugin'

module Rails
  module PluginManager
    class GitPlugin < Plugin
      def extract_name
        super.gsub(/\.git$/, '')
      end
    end
  end
end
