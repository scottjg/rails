require 'minitest/unit'
require 'active_support/testing/setup_and_teardown'
require 'active_support/testing/assertions'
require 'active_support/testing/deprecation'
require 'active_support/testing/declarative'

begin
  gem 'mocha', ">= 0.13.1"
  require 'mocha/setup'
rescue LoadError
  # Fake Mocha::ExpectationError so we can rescue it in #run. Bleh.
  Object.const_set :Mocha, Module.new
  Mocha.const_set :ExpectationError, Class.new(StandardError)
end

module ActiveSupport
  class TestCase < ::MiniTest::Unit::TestCase

    # Use AS::TestCase for the base class when describing a model
    #register_spec_type(self) do |desc|
    #  Class === desc && desc < ActiveRecord::Base
    #end

    Assertion = MiniTest::Assertion
    alias_method :method_name, :__name__


    include ActiveSupport::Testing::SetupAndTeardown
    include ActiveSupport::Testing::Assertions
    include ActiveSupport::Testing::Deprecation
    extend ActiveSupport::Testing::Declarative

  end
end
