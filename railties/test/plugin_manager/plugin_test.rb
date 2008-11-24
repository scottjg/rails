$:.unshift File.dirname(__FILE__) + "/../../lib"

require 'test/unit'
require 'plugin_manager/plugin'

include Rails::PluginManager

module PluginManager
  class PluginTest < Test::Unit::TestCase
    def test_plugin_should_have_an_uri
      assert_equal "http://example.com/acts_as_awesome", plugin.uri
    end

    def test_plugin_should_infer_a_name
      assert_equal "acts_as_awesome", plugin.name
    end

    def test_plugin_should_not_infer_name_if_provided_manually
      assert_equal "acts_as_lame", plugin(:name => "acts_as_lame").name
    end

    def test_plugin_should_have_a_correct_path
      assert_equal "vendor/plugins/acts_as_awesome", plugin.path
    end

    protected

      def plugin(options = {})
        Plugin.new(options.merge(:uri => "http://example.com/acts_as_awesome"))
      end
  end
end
