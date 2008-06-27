require File.join(File.dirname(__FILE__), "helper")

class Car < TestClassBase
  attr_accessor :engine, :year, :make
end




class TestValidationMacroOptions < ActiveSupport::TestCase
  test "checking for invalid options" do
    assert_raise(ActiveModel::Validatable::InvalidOption) do
      Car.validates_presence_of :engine, :santa_claus=>"very yes"
    end
  end
  
  test "allowing valid options" do
    assert_nothing_raised(ActiveModel::Validatable::InvalidOption) do
      Car.validates_presence_of :engine, :message=>"It really helps to have one of these."
    end
  end
  
  test "checking for required options" do
    assert_raise(ActiveModel::Validatable::MissingRequiredOption) do
      Car.validates_inclusion_of :year
    end
  end
  
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
