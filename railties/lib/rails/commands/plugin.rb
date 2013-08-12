if ARGV.first != "new"
  ARGV[0] = "--help"
else
  ARGV.shift
end

require_relative '../generators'
require_relative '../generators/rails/plugin/plugin_generator'
Rails::Generators::PluginGenerator.start
