require File.join(File.dirname(__FILE__), "helper")

class Company < TestClassBase
  attr_accessor :name, :business_number, :features, :industry
  validates_presence_of :name, :business_number
  validates_condition :features, :message => "{oppressive_features} don't work well for software companies." do |value, record|
    industry == :software && record.oppressive_features.size > 0
  end
  
  
  def oppressive_features
    features && %w(no_lunch_breaks drug_tests high_supervision)
  end
end




class TestValidationMacros < ActiveSupport::TestCase
  def setup
    @company = Company.new(:name=>"American Robots", :business_number=>"2982982723772", :industry=>:software)
  end

  test "validation passing" do
    assert @company.valid?
  end
  
  
  test "validates_presence_of" do
    @company.name = nil
    @company.business_number = nil
    assert !@company.valid?
    assert_equal 1, @company.errors.on(:name).size
    assert_equal 1, @company.errors.on(:business_number).size
    @company.name = "Mom's Friendly Robot Company"
    assert !@company.valid?
    assert_equal 0, @company.errors.on(:name).size
    assert_equal 1, @company.errors.on(:business_number).size
    @company.business_number = "2528592892892822"
    assert @company.valid?
  end
  
end
