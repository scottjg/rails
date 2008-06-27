require File.join(File.dirname(__FILE__), "helper")

class User < TestClassBase
  attr_accessor :name, :zip, :age
  validates_presence_of :name
  validates_presence_of :zip, :message => "You must enter your Zip Code."
end

class TestErrorMessages < ActiveSupport::TestCase
  def setup
    @user = User.new
    @user.valid?
    @errors = @user.errors
  end
  
  test "default and specific messages" do
    assert_equal "Name can't be empty.", @errors.on(:name).first.to_s
    assert_equal "You must enter your Zip Code.", @errors.on(:zip).first.to_s
  end
  
  
  
end