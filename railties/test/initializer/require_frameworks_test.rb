require "initializer/test_helper"

module InitializerTests
  class RequireFrameworksTest < Test::Unit::TestCase
    include ActiveSupport::Testing::Isolation

    def setup
      Rails.boot!
    end

    test "initializing rails requires all the default frameworks" do
      Rails::Initializer.run { |c| }
      assert defined?(ActiveRecord)
      assert defined?(ActionController)
      assert defined?(ActionView)
      assert defined?(ActionMailer)
      assert defined?(ActiveResource)
      assert defined?(ActiveSupport)
    end


    { :active_record => "ActiveRecord", :action_mailer => "ActionMailer",
      :active_resource => "ActiveResource"}.each do |name, const|
        test "does not require #{name} when removed from list" do
          Rails::Initializer.run { |c| c.frameworks -= [name] }
          assert !Object.const_defined?(const)
        end
      end

    test "does not require action_controller when none of the dependencies are required" do
      Rails::Initializer.run { |c| c.frameworks -= [:action_controller, :action_mailer] }
      assert !Object.const_defined?("ActionController")
    end

    test "does not require action_view when none of the dependencies are required" do
      Rails::Initializer.run { |c| c.frameworks -= [:action_controller, :action_mailer, :action_view] }
      assert !Object.const_defined?("ActionController")
    end

    test "does not require active_support/all if removed from the list of frameworks" do
      Rails::Initializer.run { |c| c.frameworks -= [:active_support] }
      assert !Process.respond_to?(:daemon)
    end

  end
end