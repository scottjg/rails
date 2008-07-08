require File.expand_path(File.join(File.dirname(__FILE__), '..', 'validation_test_helper'))

class TestValidatesAcceptanceOf < ActiveModel::ValidationTestCase
  validation_test_class :Person, :terms_of_service, :eula
  
  test "with default options" do
    Person.validates_acceptance_of :terms_of_service
    assert_errors ["Terms of service must be accepted."], person

    person.terms_of_service = true
    assert_errors ["Terms of service must be accepted."], person

    person.terms_of_service = "1"
    assert_valid person
  end
  
  test "with custom accept" do
    Person.validates_acceptance_of :eula, :accept => true
    person.eula = "1"
    assert_errors ["Eula must be accepted."], person
    
    person.eula = true
    assert_valid person
  end
end