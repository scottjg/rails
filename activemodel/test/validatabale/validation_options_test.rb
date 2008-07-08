require File.expand_path(File.join(File.dirname(__FILE__), 'validation_test_helper'))

# RUY-NOTE: OBSOLETE - Slowly being replaced with the much smaller tests in validations/*_test.rb

class Car < TestClassBase
  attr_accessor :engine, :year, :make
end




class TestValidationMacroOptions < ActiveModel::TestCase

  


  
  test "allowing validation with required options set" do
    assert_nothing_raised(ActiveModel::Validatable::MissingRequiredOption) do
      Car.validates_inclusion_of :year, :in=>1940..2008
    end
  end
  
  test "options for validates_length_of" do
    assert_nothing_raised(ActiveModel::Validatable::MissingRequiredOption) do
      Car.validates_length_of :make, :in=>2..40
      Car.validates_length_of :make, :within=>2..40
      Car.validates_length_of :make, :is=>12
      Car.validates_length_of :make, :min=>2
      Car.validates_length_of :make, :max=>40
      Car.validates_length_of :make, :min=>2, :max=>40
    end
    assert_raise(ActiveModel::Validatable::MissingRequiredOption) do
      Car.validates_length_of :make
    end
    assert_raise(ActiveModel::Validatable::MissingRequiredOption) do
      Car.validates_length_of :make, :min=>2, :in=>2..40
    end
    assert_raise(ActiveModel::Validatable::MissingRequiredOption) do
      Car.validates_length_of :make, :within=>10..20, :in=>2..40
    end
  end
  
  
end
