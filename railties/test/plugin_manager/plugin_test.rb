$:.unshift File.dirname(__FILE__) + "/../../lib"

require 'test/unit'
require 'plugin_manager/plugin'

include Rails::PluginManager

module PluginManager
  class PluginTest < Test::Unit::TestCase
    def setup
      @plugin = Plugin.new(:uri => "http://example.com/acts_as_awesome")
    end

    def test_plugin_should_have_an_uri
      assert_equal "http://example.com/acts_as_awesome", @plugin.uri
    end

    def test_plugin_should_infer_a_name
      assert_equal "acts_as_awesome", @plugin.name
    end
  end
end
