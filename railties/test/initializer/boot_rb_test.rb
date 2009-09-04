require "initializer/test_helper"

module InitializerTests
  class BootRbTest < Test::Unit::TestCase
    include ActiveSupport::Testing::Isolation

    test "requires bundler's environment.rb if it is present" do
      # Nothing here yet
    end

    test "activates all needed gems / sets load path" do
      # Rails::Initializer.run { }
      # # railties
      # %w(railties activesupport actionpack activerecord actionmailer activeresource).each do |framework|
      #   assert $LOAD_PATH.grep(%r'#{framework}/lib').first, "has #{framework} in load path"
      # end
    end

    test "user has an old boot.rb" do
      # "Figure out how to detect old boot.rb"
    end
  end
end