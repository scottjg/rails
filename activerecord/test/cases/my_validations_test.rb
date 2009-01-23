# encoding: utf-8
require "cases/helper"
require 'models/topic'
require 'models/reply'
require 'models/person'
require 'models/developer'
require 'models/warehouse_thing'
require 'models/guid'
require 'models/owner'
require 'models/pet'
require 'models/precision_math'
require 'ruby-debug'
# The following methods in Topic are used in test_conditional_validation_*
class Topic
  has_many :unique_replies, :dependent => :destroy, :foreign_key => "parent_id"
  has_many :silly_unique_replies, :dependent => :destroy, :foreign_key => "parent_id"

  def condition_is_true
    true
  end

  def condition_is_true_but_its_not
    false
  end
end

class ProtectedPerson < ActiveRecord::Base
  set_table_name 'people'
  attr_accessor :addon
  attr_protected :first_name
end

class UniqueReply < Reply
  validates_uniqueness_of :content, :scope => 'parent_id'
end

class SillyUniqueReply < UniqueReply
end

class Wizard < ActiveRecord::Base
  self.abstract_class = true

  validates_uniqueness_of :name
end

class IneptWizard < Wizard
  validates_uniqueness_of :city
end

class Conjurer < IneptWizard
end

class Thaumaturgist < IneptWizard
end

class UniqueFloat < PrecisionMath
  validates_uniqueness_of :lat
end

class UniqueDecimal < PrecisionMath
  validates_uniqueness_of :dec_lat
end

class DefineDelthaUniqueFloat < PrecisionMath
  Floats_Deltha = 0.01
  validates_uniqueness_of :lat
end

class MyValidationsTest < ActiveRecord::TestCase
  fixtures :topics, :developers, 'warehouse-things'

  # Most of the tests mess with the validations of Topic, so lets repair it all the time.
  # Other classes we mess with will be dealt with in the specific tests
  repair_validations(Topic)

#   def test_validate_case_sensitive_uniqueness
#     Topic.validates_uniqueness_of(:title, :case_sensitive => true, :allow_nil => true)

#     t = Topic.new("title" => "unique!")
#     assert t.save, "Should save t as unique"

#     t.content = "Remaining unique"
#     assert t.save, "Should still save t as unique"
#     t2 = Topic.new("title" => "UNIQUE!")

#     assert t2.valid?, "Should be valid"
#     assert t2.save, "Should save t2 as unique"
#     assert !t2.errors.on(:title)
#     assert !t2.errors.on(:parent_id)
#     assert_not_equal "has already been taken", t2.errors.on(:title)

#     t3 = Topic.new("title" => "I'M uNiQUe!")
#     assert t3.valid?, "Should be valid"
#     assert t3.save, "Should save t2 as unique"
#     assert !t3.errors.on(:title)
#     assert !t3.errors.on(:parent_id)
#     assert_not_equal "has already been taken", t3.errors.on(:title)
#   end

#   def test_validates_uniqueness_of_floats
#     # repair_validations(Topic)
#     UniqueFloat.validates_uniqueness_of :lat
#     UniqueFloat.create! :lat => 1.2345

#     repeated_lng = UniqueFloat.new :lat => 1.2345

#     assert !repeated_lng.valid?
#   end

#   def test_validates_uniqueness_of_floats_scoped_with_float
#     UniqueFloat.validates_uniqueness_of :lat, :scope => :lng
#     UniqueFloat.create! :lat => 1.2345, :lng => 9.8765

#     repeated_lat_lng = UniqueFloat.new :lat => 1.2345, :lng => 9.8765

#     assert !repeated_lat_lng.valid?
#   end

#   def test_validates_uniqueness_of_decimals
#     UniqueDecimal.validates_uniqueness_of :dec_lat
#     UniqueDecimal.create! :dec_lat => 1.2345

#     repeated_dec_lng = UniqueDecimal.new :dec_lat => 1.2345

#     assert !repeated_dec_lng.valid?
#   end

  def test_validates_uniqueness_of_decimals_scoped_with_decimal
    UniqueDecimal.validates_uniqueness_of :dec_lat, :scope => :dec_lng
    UniqueDecimal.create! :dec_lat => 1.2345, :dec_lng => 9.8765

    repeated_dec_lat_lng = UniqueDecimal.new :dec_lat => 1.2345, :dec_lng => 9.8765

    assert !repeated_dec_lat_lng.valid?
  end

  def test_validates_uniqueness_of_defining_model_deltha
    DefineDelthaUniqueFloat.create! :lat => 1.23

    repeated_lat = DefineDelthaUniqueFloat.new :lat => 1.23

    assert !repeated_lat.valid?
  end


  private
    def invalid!(values, error=nil)
      with_each_topic_approved_value(values) do |topic, value|
        assert !topic.valid?, "#{value.inspect} not rejected as a number"
        assert topic.errors.on(:approved)
        assert_equal error, topic.errors.on(:approved) if error
      end
    end

    def valid!(values)
      with_each_topic_approved_value(values) do |topic, value|
        assert topic.valid?, "#{value.inspect} not accepted as a number"
      end
    end

    def with_each_topic_approved_value(values)
      topic = Topic.new("title" => "numeric test", "content" => "whatever")
      values.each do |value|
        topic.approved = value
        yield topic, value
      end
    end
end
