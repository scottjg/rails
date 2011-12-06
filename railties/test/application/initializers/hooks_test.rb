require "isolation/abstract_unit"

module ApplicationTests
  class InitializersTest < Test::Unit::TestCase
    include ActiveSupport::Testing::Isolation

    def setup
      build_app
      boot_rails
      FileUtils.rm_rf "#{app_path}/config/environments"
    end

    def teardown
      teardown_app
    end

    test "load initializers" do
      app_file "config/initializers/foo.rb", "$foo = true"
      require "#{app_path}/config/environment"
      assert $foo
    end

    test "hooks block works correctly without cache classes (before_eager_load is not called)" do
      add_to_config <<-RUBY
        $initialization_callbacks = []
        config.root = "#{app_path}"
        config.cache_classes = false
        config.before_configuration { $initialization_callbacks << 1 }
        config.before_initialize    { $initialization_callbacks << 2 }
        config.before_initializers  { $initialization_callbacks << 3 }
        config.after_initializers   { $initialization_callbacks << 4 }
        config.before_eager_load    { Boom }
        config.after_initialize     { $initialization_callbacks << 5 }
      RUBY

      require "#{app_path}/config/environment"
      assert_equal [1,2,3,4,5], $initialization_callbacks
    end

    test "hooks block works correctly with cache classes" do
      add_to_config <<-RUBY
        $initialization_callbacks = []
        config.root = "#{app_path}"
        config.cache_classes = true
        config.before_configuration { $initialization_callbacks << 1 }
        config.before_initialize    { $initialization_callbacks << 2 }
        config.before_initializers  { $initialization_callbacks << 3 }
        config.after_initializers   { $initialization_callbacks << 4 }
        config.before_eager_load    { $initialization_callbacks << 5 }
        config.after_initialize     { $initialization_callbacks << 6 }
      RUBY

      require "#{app_path}/config/environment"
      assert_equal [1,2,3,4,5,6], $initialization_callbacks
    end

    test "hooks relation with autoload paths" do
      add_to_config <<-RUBY
        $autoload_paths = ActiveSupport::Dependencies.autoload_paths.dup

        def assert_no_change
          raise "Load paths changed" if $autoload_paths != ActiveSupport::Dependencies.autoload_paths
        end

        def assert_change
          raise "Load paths did not change" if $autoload_paths == ActiveSupport::Dependencies.autoload_paths
        end

        initializer "assert" do
          assert_no_change
        end

        config.root = "#{app_path}"
        config.cache_classes = true
        config.before_initialize    { assert_no_change }
        config.before_initializers  { assert_change }
      RUBY

      require "#{app_path}/config/environment"
    end

    test "after_initialize runs after frameworks have been initialized" do
      $activerecord_configurations = nil
      add_to_config <<-RUBY
        config.after_initialize { $activerecord_configurations = ActiveRecord::Base.configurations }
      RUBY

      require "#{app_path}/config/environment"
      assert $activerecord_configurations
      assert $activerecord_configurations['development']
    end

    test "after_initialize happens after to_prepare in development" do
      $order = []
      add_to_config <<-RUBY
        config.cache_classes = false
        config.after_initialize { $order << :after_initialize }
        config.to_prepare { $order << :to_prepare }
      RUBY

      require "#{app_path}/config/environment"
      assert_equal [:to_prepare, :after_initialize], $order
    end

    test "after_initialize happens after to_prepare in production" do
      $order = []
      add_to_config <<-RUBY
        config.cache_classes = true
        config.after_initialize { $order << :after_initialize }
        config.to_prepare { $order << :to_prepare }
      RUBY

      require "#{app_path}/config/application"
      Rails.env.replace "production"
      require "#{app_path}/config/environment"
      assert_equal [:to_prepare, :after_initialize], $order
    end
  end
end
