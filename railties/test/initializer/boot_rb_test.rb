require "initializer/test_helper"

module InitializerTests
  class BootRbTest < Test::Unit::TestCase
    include ActiveSupport::Testing::Isolation

    test "requires bundler's environment.rb if it is present" do
      # Nothing here yet
    end

    test "user has an old boot.rb" do
      # "Figure out how to detect old boot.rb"
    end
  end
end