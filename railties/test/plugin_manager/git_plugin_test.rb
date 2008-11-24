$:.unshift File.dirname(__FILE__) + "/../../lib"

require 'test/unit'
require 'plugin_manager'

include Rails::PluginManager

module PluginManager
  class GitPluginTest < Test::Unit::TestCase
    def setup
      @plugin = GitPlugin.new(:uri => "git://example.com/acts_as_awesome.git")
    end

    def test_git_plugin_name_should_exclude_git_suffix
      assert_equal "acts_as_awesome", @plugin.name
    end

    def test_supported_uri_schemes
      assert GitPlugin.can_handle_uri?("git://foobar.org/acts_as_awesome")
    end
  end
end

