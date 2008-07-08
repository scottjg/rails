require File.expand_path(File.join(File.dirname(__FILE__), '..', 'validation_test_helper'))

# RUY-NOTE TODO: check valid macro options

class TestValidatesCondition < ActiveModel::ValidationTestCase
  validation_test_class :Person, :first_name, :last_name
  
  test "with default options" do
    Person.validates_condition :first_name do |name|
      name == "Ruy"
    end

    person.first_name = "Joe"
    assert_errors ["First name is invalid."], person

    person.first_name = "Ruy"
    assert_valid person
  end
  
  test "for multiple attributes" do
    Person.validates_condition :first_name, :last_name do |name, attr|
      # This is a pretty contrived test...
      case attr
      when :first_name
        name == 'Ruy'
      when :last_name
        name == 'Asan'
      end
    end
    
    person.first_name = "Joe"
    person.last_name = "Bob"
    assert_errors ["First name is invalid.", "Last name is invalid."], person
    
    person.first_name = "Ruy"
    assert_errors ["Last name is invalid."], person
    
    person.last_name = "Asan"
    assert_valid person
    
    person.first_name = "Joe"
    assert_errors ["First name is invalid."], person
  end
end