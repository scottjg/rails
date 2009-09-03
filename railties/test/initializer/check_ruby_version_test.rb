require "initializer/test_helper"

module InitializerTests
  class PathsTest < Test::Unit::TestCase
    include ActiveSupport::Testing::Isolation

    def setup
      Rails.boot!
    end

    1.upto(6) do |i|
      test "rails does not initialize with ruby version 1.8.#{i}" do
        assert_rails_does_not_boot "1.8.#{i}"
      end
    end

    test "rails initializes with ruby version 1.8.7" do
      assert_rails_boots "1.8.7"
    end

    def set_ruby_version(version)
      $-w = nil
      Object.const_set(:RUBY_VERSION, version.freeze)
    end

    def assert_rails_boots(version)
      set_ruby_version(version)
      assert_nothing_raised "It appears that rails does not boot" do
        Rails::Initializer.run { |c| c.frameworks = [] }
      end
    end

    def assert_rails_does_not_boot(version)
      set_ruby_version(version)
      $stderr = File.open("/dev/null", "w")
      assert_raises(SystemExit) do
        Rails::Initializer.run { |c| c.frameworks = [] }
      end
    end
  end
end
