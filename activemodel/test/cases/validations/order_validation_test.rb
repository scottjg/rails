# encoding: utf-8
require 'cases/helper'
require 'cases/tests_database'

require 'models/topic'

class OrderValidationTest < ActiveModel::TestCase
  include ActiveModel::TestsDatabase
  include ActiveModel::ValidationsRepairHelper

  @@model = Topic
  @@lattr = :written_on
  @@rattr = :last_read

  repair_validations(@@model)

  def test_validates_order_with_nil_or_blank_allowed
    @@model.validates_order_of  @@lattr,
                                :equal_to => @@rattr,
                                :allow_nil => true

    {:nil => nil, :blank => ''}.each do |name, value|
      assert @@model.new(@@lattr => value, @@rattr => 1).valid?,
        "When #{name} is allowed and the value is #{name} it should be valid"
    end
  end

  def test_validates_order_with_values_that_do_not_support_the_comparison_operation
    [:greater_than, :greater_than_or_equal_to, :less_than, :less_than_or_equal_to].each do |op|
      @@model.validates_order_of  @@lattr,
                                  op => @@rattr

      assert @@model.new(@@lattr => nil, @@rattr => nil).valid?,
        "When the value or the compared value do not support '#{op}' it should be valid"
    end
  end

  { :greater_than             => [1,0],
    :greater_than_or_equal_to => [1,0],
    :less_than                => [0,1],
    :less_than_or_equal_to    => [0,1]  }.each do
    |option, values|
    define_method "test_validates_order_with_#{option}" do
      @@model.validates_order_of  @@lattr,
                                  option => @@rattr

      option_text = option.to_s.gsub('_', ' ').downcase

      assert @@model.new(@@lattr => nil, @@rattr => 1).valid?,
        "When the value does not respond to '#{option_text}' it should be valid"

      assert @@model.new(@@lattr => 1, @@rattr => nil).valid?,
        "When the compared value does not respond to '#{option_text}' it should be valid"

      assert @@model.new(@@lattr => values.first, @@rattr => values.last).valid?,
        "When the value (#{values.first}) is #{option_text} the compared value (#{values.last}) it should be valid"

      if option_text.include?('or equal to')
        assert @@model.new(@@lattr => values.first, @@rattr => values.first).valid?,
          "When the value (#{values.first}) is #{option_text} the compared value (#{values.last}) it should be valid"
      end

      values.reverse!
      assert !(o=@@model.new(@@lattr => values.first, @@rattr => values.last)).valid?,
        "When the value (#{values.first}) is not #{option_text} the compared value (#{values.last}) it should not be valid"
    end
  end

  def test_validates_order_with_equal_to
    @@model.validates_order_of  @@lattr,
                                :equal_to => @@rattr

    assert @@model.new(@@lattr => 0, @@rattr => 0).valid?,
      "When the value is equal to the compared value it should be valid"

    assert !@@model.new(@@lattr => 1, @@rattr => 0).valid?,
      "When the value is not equal to the compared value it should not be valid"
  end
end
