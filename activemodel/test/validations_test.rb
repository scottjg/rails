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
    class Guy
      include ActiveModel::Validations

      attr_accessor :name, :dob

      validate :check_name
      def check_name
        errors[:name] << "You gotta have a name!" unless self.name
      end
      
      validate do |my|
        my.errors[:dob] << "Were you never born??" unless my.dob
      end
      
    end
    
    guy = Guy.new
    assert !guy.valid?
    assert !guy.errors.empty?
    assert !guy.errors[:name].empty?
    assert !guy.errors[:dob].empty?
    assert_equal 2, guy.errors.size
    assert_equal 1, guy.errors[:name].size
    assert_equal 1, guy.errors[:dob].size
    
    guy.name = "Guy"
    guy.dob = Date.new
    assert guy.valid?
    assert guy.errors.empty?
    assert guy.errors[:name].empty?
    assert guy.errors[:dob].empty?
  end
  
  test "validates_each with multiple failures" do
    class Person
      include ActiveModel::Validations
      attr_accessor :first_name, :last_name
      
      validates_each :first_name, :last_name do |record, attr, value|
        record.errors[attr] << "#{attr} of #{value} is too short!" if value.size < 3
        record.errors[attr] << "#{attr} of #{value} can't contain digits!" if value =~ /\d/
        record.errors[attr] << "#{attr} of #{value} can't start with G!" if value =~ /^g/i
      end
    end
    
    person = Person.new

    person.first_name =  "Murd0ch"
    person.last_name = "G2"    
    assert !person.valid?
    errors = []
    person.errors.each { |attr, value|errors << value }    
    assert_equal "first_name of Murd0ch can't contain digits!", errors[0]
    assert_equal "last_name of G2 is too short!",               errors[1]
    assert_equal "last_name of G2 can't contain digits!",       errors[2]
    assert_equal "last_name of G2 can't start with G!",         errors[3]
    
    person.last_name = "W1nchester"
    assert !person.valid?
    errors = []
    person.errors.each { |attr, value|errors << value }    
    assert_equal "first_name of Murd0ch can't contain digits!",  errors[0]
    assert_equal "last_name of W1nchester can't contain digits!",errors[1]
    
    person.first_name = "Murdoch"
    assert !person.valid?
    errors = []
    person.errors.each { |attr, value|errors << value }    
    assert_equal "last_name of W1nchester can't contain digits!",errors[0]
    assert person.errors[:first_name].empty?
    
    person.last_name = "Winchester"
    assert person.valid?
    assert person.errors.empty?
    assert person.errors[:first_name].empty?
    assert person.errors[:last_name].empty?
  end
end