require File.join(File.dirname(__FILE__), "..", "test_helper")

class User < TestClassBase
  attr_accessor :name, :zip, :age, :title
  validates_presence_of :name
  validates_presence_of :zip, :message => "You must enter your Zip Code."
  validates_inclusion_of :age, :in=>20..30, :message=>"{attribute_name} {age} is not within {in}"
  validates_length_of :title, :min=>10, :too_short=>"{attribute_name} is too short! Make it longer then {min} {units}!"
end

class TestErrorMessages < ActiveModel::TestCase
  def setup
    @user = User.new(:age=>40, :title=>"bah")
    @user.valid?
    @errors = @user.errors
  end
  
  test "default and specific messages" do
    assert_equal "Name can't be empty.", @errors.on(:name).first
    assert_equal "You must enter your Zip Code.", @errors.on(:zip).first
  end
  
  test "substitutions in the message" do
    assert_equal "Age 40 is not within 20..30", @errors.on(:age).first
  end
  
  test "alternative error messages" do
    assert_equal "Title is too short! Make it longer then 10 characters!", @errors.on(:title).first
  end
  
  
  
end