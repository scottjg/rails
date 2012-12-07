require 'minitest/unit'
require 'active_support/testing/setup_and_teardown'
require 'active_support/testing/assertions'
require 'active_support/testing/deprecation'
require 'active_support/testing/declarative'

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

    # Backport from test/unit
    def build_message(message, template = nil, *args)
      template = template.gsub('<?>', '<%s>')
      message || sprintf(template, *args)
    end
  end
end
