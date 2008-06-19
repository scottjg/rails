require File.join(File.dirname(__FILE__), "helper")
require 'active_model/validations'

class TestCoreValidation < ActiveSupport::TestCase
  test "inclusion to a basic class and default state" do
    class BasicThing
      include ActiveModel::Validations
    end
    thing = BasicThing.new
    assert thing.valid?
    assert thing.errors.empty?
    
  end
  
  test "basic validation with errors" do
    class Person
      include ActiveModel::Validations

      attr_accessor :name, :dob

      validate :check_name
      def check_name
        errors[:name] << "You gotta have a name!" unless @name
      end
      
      validate do |my|
        my.errors[:dob] << "Were you never born??" unless @dob
      end
      
    end
    person = Person.new
    assert !person.valid?
    assert !person.errors.empty?
    assert !person.errors[:name].empty?
    assert !person.errors[:dob].empty?
    assert_equal 2, person.errors.size
    assert_equal 1, person.errors[:name].size
    assert_equal 1, person.errors[:dob].size
  end
end