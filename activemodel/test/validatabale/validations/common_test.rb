require File.expand_path(File.join(File.dirname(__FILE__), '..', 'validation_test_helper'))

class CommonValidation < ActiveModel::Validatable::Validations::Base
  options :with, :foo=>"foo"
  required :with
  validate_option :foo=>String, :with=>:[]
  
  def froob
    "avast!"
  end
  
  def valid?
    false
  end
end

CommonValidation.define_validation_macro(TestClassBase)

class TestCommonValidationBehavior < ActiveModel::ValidationTestCase
  validation_test_class :Thing, :name, :bar
  
  test "allowing default option values" do
    Thing.common_validation :name, :with=>[]
    assert_equal "foo", Thing.validations[:name].first.foo
  end
  
  test "allow over-riding default option values" do
    Thing.common_validation :name, :with=>[], :foo=>"bar"
    assert_equal "bar", Thing.validations[:name].first.foo
  end
  
  test "checking for invalid options" do
    assert_raise(ActiveModel::Validatable::InvalidOption) do
      Thing.common_validation :name, :with=>[], :santa_claus=>"very yes"
    end
  end
  
  test "checking for required options" do
    assert_raise(ActiveModel::Validatable::MissingRequiredOption) do
      Thing.common_validation :name
    end
  end
  
  test "checking for valid option value using respond_to?" do
    assert_raise(ActiveModel::Validatable::InvalidOptionValue) do
      Thing.common_validation :name, :with=>true
    end
  end
  
  test "checking for valid option value using kind_of?" do
    assert_raise(ActiveModel::Validatable::InvalidOptionValue) do
      Thing.common_validation :name, :with=>[], :foo=>232
    end
  end
  
  test "allow nil" do
    Thing.common_validation :name, :with=>[], :allow_nil => true
    thing.name = nil
    assert_valid thing
  end
  
  test "check nil by default" do
    Thing.common_validation :name, :with=>[]
    thing.name = nil
    assert_errors ["Name is invalid."], thing
  end
  
  test "allow blank" do
    Thing.common_validation :name, :with=>[], :allow_blank => true
    thing.name = ""
    assert_valid thing
  end
  
  test "check blank by default" do
    Thing.common_validation :name, :with=>[]
    thing.name = ""
    assert_errors ["Name is invalid."], thing
  end
  
  test "default failure message" do
    Thing.common_validation :name, :with=>[]
    assert_errors ["Name is invalid."], thing
  end
  
  test "changing the default failure message" do
    old_msg = CommonValidation.default_options[:message]

    CommonValidation.options :message=>"{attribute_name} is not valid!"
    Thing.common_validation :name, :with=>[]
    assert_errors ["Name is not valid!"], thing
    
    CommonValidation.default_options[:message] = old_msg
  end
  
  test "with custom message" do
    Thing.common_validation :name, :with=>[], :message=>"{attribute_name} smells like ham."
    assert_errors ["Name smells like ham."], thing
  end
  
  test "with message referencing validation options" do
    Thing.common_validation :name, :with=>%w(a b c), :message=>"{attribute_name} doesn't jive with {with}."
    assert_errors ["Name doesn't jive with abc."], thing
  end
  
  test "with message referencing validation method" do
    Thing.common_validation :name, :with=>[], :message=>"{attribute_name} froobs with '{froob}'"
    assert_errors ["Name froobs with 'avast!'"], thing
  end
  
  test "with message referencing the validated value" do
    Thing.common_validation :name, :with=>[], :message=>"{attribute_name} '{value}' just won't do."
    thing.name = "Alfonzo"
    assert_errors ["Name 'Alfonzo' just won't do."], thing
  end
  
  test "with message referencing a property of the validated value" do
    Thing.common_validation :name, :with=>[], :message=>"{now} is not the time."
    thing.name = Time
    assert_errors ["#{thing.name.now} is not the time."], thing
  end
  
  test "with message referencing a property on the object" do
    Thing.common_validation :name, :with=>[], :message=>"Too much {bar}!"
    thing.bar = "WHAM"
    assert_errors ["Too much WHAM!"], thing
  end
end