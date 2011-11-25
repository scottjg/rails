require 'isolation/abstract_unit'

module ApplicationTests
  class PluginTest < Test::Unit::TestCase

    def setup
      build_app
    end

    def teardown
      teardown_app
    end

    def test_truth
      # puts Dir.chdir(app_path) { `bundle exec rails plugin install http://example.com/my_svn_plugin` }
    end
  end
end
