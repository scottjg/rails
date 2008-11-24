$:.unshift File.dirname(__FILE__) + "/../../lib"

require 'test/unit'
require 'plugin_manager/git_plugin'

include Rails::PluginManager

module PluginManager
  class GitPluginTest < Test::Unit::TestCase
    def setup
      @plugin = GitPlugin.new(:uri => "git://example.com/acts_as_awesome.git")
    end

    def test_git_plugin_name_should_exclude_git_suffix
      assert_equal "acts_as_awesome", @plugin.name
    end
  end
end

