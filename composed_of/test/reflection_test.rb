require 'test_helper'
require 'models/customer'

class ReflectionTest < ActiveSupport::TestCase
  include ActiveRecord::Reflection

  fixtures :customers

  def test_aggregation_reflection
    reflection_for_address = AggregateReflection.new(
      :composed_of, :address, { :mapping => [ %w(address_street street), %w(address_city city), %w(address_country country) ] }, Customer
    )

    reflection_for_balance = AggregateReflection.new(
      :composed_of, :balance, { :class_name => "Money", :mapping => %w(balance amount) }, Customer
    )

    reflection_for_gps_location = AggregateReflection.new(
      :composed_of, :gps_location, { }, Customer
    )

    assert Customer.reflect_on_all_aggregations.include?(reflection_for_gps_location)
    assert Customer.reflect_on_all_aggregations.include?(reflection_for_balance)
    assert Customer.reflect_on_all_aggregations.include?(reflection_for_address)

    assert_equal reflection_for_address, Customer.reflect_on_aggregation(:address)

    assert_equal Address, Customer.reflect_on_aggregation(:address).klass

    assert_equal Money, Customer.reflect_on_aggregation(:balance).klass
  end
end
