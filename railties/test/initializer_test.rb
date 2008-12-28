require 'abstract_unit'
require 'initializer'

class ConfigurationMock < Rails::Configuration
  attr_reader :environment_path

  def initialize(envpath)
    super()
    @environment_path = envpath
  end
end

class Initializer_load_environment_Test < Test::Unit::TestCase
  def test_load_environment_with_constant
    config = ConfigurationMock.new("#{File.dirname(__FILE__)}/fixtures/environment_with_constant.rb")
    assert_nil $initialize_test_set_from_env
    Rails::Initializer.run(:load_environment, config)
    assert_equal "success", $initialize_test_set_from_env
  ensure
    $initialize_test_set_from_env = nil
  end

end

class Initializer_eager_loading_Test < Test::Unit::TestCase
  def setup
    @config = ConfigurationMock.new("")
    @config.cache_classes = true
    @config.load_paths = [File.expand_path(File.dirname(__FILE__) + "/fixtures/eager")]
    @config.eager_load_paths = [File.expand_path(File.dirname(__FILE__) + "/fixtures/eager")]
    Rails::Initializer.run(:set_load_path, @config)
    Rails::Initializer.run(:set_autoload_paths, @config)
  end

  def test_eager_loading_loads_parent_classes_before_children
    assert_nothing_raised do
      Rails::Initializer.run(:load_application_classes, @config)
    end
  end
end

uses_mocha 'Initializer after_initialize' do
  class Initializer_after_initialize_with_blocks_environment_Test < Test::Unit::TestCase
    def setup
      config = ConfigurationMock.new("")
      config.after_initialize do
        $test_after_initialize_block1 = "success"
      end
      config.after_initialize do
        $test_after_initialize_block2 = "congratulations"
      end
      assert_nil $test_after_initialize_block1
      assert_nil $test_after_initialize_block2
      
      config.expects(:gems_dependencies_loaded).returns(true)
      Rails::Initializer.run(:after_initialize, config)
    end

    def teardown
      $test_after_initialize_block1 = nil
      $test_after_initialize_block2 = nil
    end

    def test_should_have_called_the_first_after_initialize_block
      assert_equal "success", $test_after_initialize_block1
    end

    def test_should_have_called_the_second_after_initialize_block
      assert_equal "congratulations", $test_after_initialize_block2
    end
  end

  class Initializer_after_initialize_with_no_block_environment_Test < Test::Unit::TestCase
    def setup
      config = ConfigurationMock.new("")
      config.after_initialize do
        $test_after_initialize_block1 = "success"
      end
      config.after_initialize # don't pass a block, this is what we're testing!
      config.after_initialize do
        $test_after_initialize_block2 = "congratulations"
      end
      assert_nil $test_after_initialize_block1

      config.expects(:gems_dependencies_loaded).returns(true)
      Rails::Initializer.run(:after_initialize, config)
    end

    def teardown
      $test_after_initialize_block1 = nil
      $test_after_initialize_block2 = nil
    end

    def test_should_have_called_the_first_after_initialize_block
      assert_equal "success", $test_after_initialize_block1, "should still get set"
    end

    def test_should_have_called_the_second_after_initialize_block
      assert_equal "congratulations", $test_after_initialize_block2
    end
  end
end

uses_mocha 'framework paths' do
  class ConfigurationFrameworkPathsTests < Test::Unit::TestCase
    def setup
      @config = Rails::Configuration.new
      @config.frameworks.clear

      File.stubs(:directory?).returns(true)
      @config.stubs(:framework_root_path).returns('')
    end

    def test_minimal
      expected = %w(
        /railties
        /railties/lib
        /activesupport/lib
      )
      assert_equal expected, @config.framework_paths
    end

    def test_actioncontroller_or_actionview_add_actionpack
      @config.frameworks << :action_controller
      assert_framework_path '/actionpack/lib'

      @config.frameworks = [:action_view]
      assert_framework_path '/actionpack/lib'
    end

    def test_paths_for_ar_ares_and_mailer
      [:active_record, :action_mailer, :active_resource, :action_web_service].each do |framework|
        @config.frameworks = [framework]
        assert_framework_path "/#{framework.to_s.gsub('_', '')}/lib"
      end
    end

    def test_unknown_framework_raises_error
      @config.frameworks << :action_foo
      assert_raise RuntimeError do
        Rails::Initializer.run(:require_frameworks, @config)
      end
    end

    def test_action_mailer_load_paths_set_only_if_action_mailer_in_use
      @config.frameworks = [:action_controller]
      Rails::Initializer.run(:require_frameworks, @config)

      assert_nothing_raised NameError do
        Rails::Initializer.run(:load_view_paths, @config)
      end
    end

    def test_action_controller_load_paths_set_only_if_action_controller_in_use
      @config.frameworks = []
      Rails::Initializer.run(:require_frameworks, @config)
      Rails::Initializer.run(:initialize_framework_views, @config)

      assert_nothing_raised NameError do
        Rails::Initializer.run(:load_view_paths, @config)
      end
    end

    protected
      def assert_framework_path(path)
        assert @config.framework_paths.include?(path),
          "<#{path.inspect}> not found among <#{@config.framework_paths.inspect}>"
      end
  end
end

uses_mocha "Initializer plugin loading tests" do
  require File.dirname(__FILE__) + '/plugin_test_helper'

  class InitializerPluginLoadingTests < Test::Unit::TestCase
    def setup
      @configuration     = Rails::Configuration.new
      @configuration.plugin_paths << plugin_fixture_root_path
      @valid_plugin_path = plugin_fixture_path('default/stubby')
      @empty_plugin_path = plugin_fixture_path('default/empty')
    end

    def test_no_plugins_are_loaded_if_the_configuration_has_an_empty_plugin_list
      @configuration.plugins = []
      Rails::Initializer.run(:load_plugins, @configuration)
      assert_equal [], @configuration.loaded_plugins
    end

    def test_only_the_specified_plugins_are_located_in_the_order_listed
      plugin_names = [:plugin_with_no_lib_dir, :acts_as_chunky_bacon]
      @configuration.plugins = plugin_names
      load_plugins!
      assert_plugins plugin_names, Rails.configuration.loaded_plugins
    end

    def test_all_plugins_are_loaded_when_registered_plugin_list_is_untouched
      failure_tip = "It's likely someone has added a new plugin fixture without updating this list"
      load_plugins!
      assert_plugins [:a, :acts_as_chunky_bacon, :engine, :gemlike, :plugin_with_no_lib_dir, :stubby], Rails.configuration.loaded_plugins, failure_tip
    end

    def test_all_plugins_loaded_when_all_is_used
      plugin_names = [:stubby, :acts_as_chunky_bacon, :all]
      @configuration.plugins = plugin_names
      load_plugins!
      failure_tip = "It's likely someone has added a new plugin fixture without updating this list"
      assert_plugins [:stubby, :acts_as_chunky_bacon, :a, :engine, :gemlike, :plugin_with_no_lib_dir], Rails.configuration.loaded_plugins, failure_tip
    end

    def test_all_plugins_loaded_after_all
      plugin_names = [:stubby, :all, :acts_as_chunky_bacon]
      @configuration.plugins =  plugin_names
      load_plugins!
      failure_tip = "It's likely someone has added a new plugin fixture without updating this list"
      assert_plugins [:stubby, :a, :engine, :gemlike, :plugin_with_no_lib_dir, :acts_as_chunky_bacon], Rails.configuration.loaded_plugins, failure_tip
    end

    def test_plugin_names_may_be_strings
      plugin_names = ['stubby', 'acts_as_chunky_bacon', :a, :plugin_with_no_lib_dir]
      @configuration.plugins =  plugin_names
      load_plugins!
      failure_tip = "It's likely someone has added a new plugin fixture without updating this list"
      assert_plugins plugin_names, Rails.configuration.loaded_plugins, failure_tip
    end

    def test_registering_a_plugin_name_that_does_not_exist_raises_a_load_error
      @configuration.plugins = [:stubby, :acts_as_a_non_existant_plugin]
      assert_raises(LoadError) do
        load_plugins!
      end
    end

    def test_should_ensure_all_loaded_plugins_load_paths_are_added_to_the_load_path
      @configuration.plugins = [:stubby, :acts_as_chunky_bacon]

      Rails::Initializer.run(:add_plugin_load_paths, @configuration)

      assert $LOAD_PATH.include?(File.join(plugin_fixture_path('default/stubby'), 'lib'))
      assert $LOAD_PATH.include?(File.join(plugin_fixture_path('default/acts/acts_as_chunky_bacon'), 'lib'))
    end


    private

      def load_plugins!
        Rails::Initializer.run(:add_plugin_load_paths, @configuration)
        Rails::Initializer.run(:load_plugins, @configuration)
      end
  end
end

uses_mocha 'i18n settings' do
  class InitializerSetupI18nTests < Test::Unit::TestCase
    def test_no_config_locales_dir_present_should_return_empty_load_path
      File.stubs(:exist?).returns(false)
      assert_equal [], Rails::Configuration.new.i18n.load_path
    end

    def test_config_locales_dir_present_should_be_added_to_load_path
      File.stubs(:exist?).returns(true)
      Dir.stubs(:[]).returns([ "my/test/locale.yml" ])
      assert_equal [ "my/test/locale.yml" ], Rails::Configuration.new.i18n.load_path
    end
    
    def test_config_defaults_should_be_added_with_config_settings
      File.stubs(:exist?).returns(true)
      Dir.stubs(:[]).returns([ "my/test/locale.yml" ])

      config = Rails::Configuration.new
      config.i18n.load_path << "my/other/locale.yml"

      assert_equal [ "my/test/locale.yml", "my/other/locale.yml" ], config.i18n.load_path
    end
    
    def test_config_defaults_and_settings_should_be_added_to_i18n_defaults
      File.stubs(:exist?).returns(true)
      Dir.stubs(:[]).returns([ "my/test/locale.yml" ])

      config = Rails::Configuration.new
      config.i18n.load_path << "my/other/locale.yml"

      # To bring in AV's i18n load path.
      require 'action_view'

      Rails::Initializer.run(:initialize_i18n, config)
      assert_equal [ 
       File.expand_path("./test/../../activesupport/lib/active_support/locale/en.yml"),
       File.expand_path("./test/../../actionpack/lib/action_view/locale/en.yml"),
       "my/test/locale.yml",
       "my/other/locale.yml" ], I18n.load_path.collect { |path| path =~ /^\./ ? File.expand_path(path) : path }
    end
    
    def test_setting_another_default_locale
      config = Rails::Configuration.new
      config.i18n.default_locale = :de
      Rails::Initializer.run(:initialize_i18n, config)
      assert_equal :de, I18n.default_locale
    end
  end
end

class RailsRootTest < Test::Unit::TestCase
  def test_rails_dot_root_equals_rails_root
    assert_equal RAILS_ROOT, Rails.root.to_s
  end

  def test_rails_dot_root_should_be_a_pathname
    assert_equal File.join(RAILS_ROOT, 'app', 'controllers'), Rails.root.join('app', 'controllers').to_s
  end
end