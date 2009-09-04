require "initializer/test_helper"

module InitializerTests
  class SetLoadPathTest < Test::Unit::TestCase
    include ActiveSupport::Testing::Isolation

    def assert_in_load_path(root, *paths)
      paths.flatten.each do |path|
        path = File.expand_path(File.join(root, path))
        assert $LOAD_PATH.include?(path), "#{path.inspect} should be in load path, but was: #{$LOAD_PATH.inspect}"
      end
    end

    def assert_not_in_load_path(root, *paths)
      paths.flatten.each do |path|
        path = File.join(root, path)
        assert !$LOAD_PATH.include?(path), "#{path.inspect} should not be in load path, but it was."
      end
    end

    def setup
      @root = File.join(File.dirname(__FILE__), 'root')
      Rails.boot!
    end

    test "adds relevant application structure to the load path" do
      assert_in_load_path @root, %w(app app/metal app/models app/controllers
        app/helpers lib vendor)
    end

    test "doesn't add things to the load path if they do not exist" do
      assert_not_in_load_path @root, "app/services"
    end

  end
end