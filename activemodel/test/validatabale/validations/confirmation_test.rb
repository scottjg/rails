require File.expand_path(File.join(File.dirname(__FILE__), '..', 'validation_test_helper'))

# RUY-NOTE TODO: check valid macro options

class TestValidatesConfirmationOf < ActiveModel::ValidationTestCase
  validation_test_class :Person, :password, :password_confirmation
  
  test "with default options" do
    Person.validates_confirmation_of :password
    
    person.password = "foo"
    assert_errors ["Password must be confirmed."], person

    person.password_confirmation = "FOO"
    assert_errors ["Password must be confirmed."], person

    person.password_confirmation = "foo"
    assert_valid person
  end
  
  test "with case insensitive confirmation " do
    Person.validates_confirmation_of :password, :case_sensitive => false
    
    person.password = "foo"
    person.password_confirmation = "blop"
    assert_errors ["Password must be confirmed."], person

    person.password_confirmation = "FOO"
    assert_valid person
  end
end