
$:.unshift(File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__) + "/../../activesupport/lib")

require 'plugin_manager/commands'

module Rails::PluginManager
  extend Rails::PluginManager::Commands
end
