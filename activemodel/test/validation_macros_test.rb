require File.join(File.dirname(__FILE__), "helper")

class Company < TestClassBase
  attr_accessor :name, :business_number, :features, :industry, :terms, :password, :password_confirmation, :agreement, :founding_year
  validates_presence_of :name, :business_number
  validates_condition :features, :message => "{oppressive_features} don't work well for {attribute_name} companies." do |value|
    !(industry == :software && oppressive_features.any? )
  end
  
  validates_each :features do |value,attr|
    errors.on(attr).add "Colors are not features...." unless (features & %w(red green blue)).empty?
  end
  
  def oppressive_features
    features & %w(no_lunch_breaks drug_tests high_supervision)
  end
  
  validates_acceptance_of :terms
  validates_acceptance_of :agreement, :accept=>"yes"
  
  validates_confirmation_of :password
  
  validates_exclusion_of :name, :in=>%w(microsoft apple google)
  
  validates_inclusion_of :founding_year, :in=>(1950..2008)
  
  validates_length_of :name, :min=>3, :allow_nil => true
  validates_length_of :name, :max=>40, :allow_nil => true
  validates_length_of :name, :in=>3..40, :allow_nil => true
  validates_length_of :name, :within=>3..40, :allow_nil => true
  validates_length_of :name, :min=>3, :max=>40, :allow_nil => true
  validates_length_of :business_number, :is=>10, :allow_nil => true
  
end




class TestValidationMacros < ActiveSupport::TestCase
  def setup
    @company = Company.new( 
      :name=>"American Robots",
      :business_number=>"1234567890",
      :industry=>:software,
      :features=>%w(medical dental),
      :terms=>"1",
      :agreement => "yes",
      :password => "foo",
      :password_confirmation => "foo",
      :founding_year => 2001
    )
  end

  test "validation passing" do
    @company.valid?
    puts @company.errors.to_a
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
    @company.business_number = "0987654321"
    assert @company.valid?
  end
  
  test "validates_condition" do
    @company.features += %w(drug_tests high_supervision)
    assert !@company.valid?
    assert_equal 1, @company.errors.on(:features).size
    @company.industry = :banking
    assert @company.valid?
  end
  
  test "validates_each" do
    @company.features << "red"
    assert !@company.valid?
    assert_equal 1, @company.errors.on(:features).size
    @company.features.delete("red")
    assert @company.valid?
  end
  
  
  test "validates_acceptance_of" do
    @company.terms = "no"
    assert !@company.valid?
    assert_equal 1, @company.errors.on(:terms).size
    @company.terms = "1"
    assert @company.valid?
  end
  
  test "validates_acceptance_of with custom :accept" do
    @company.agreement = "1"
    assert !@company.valid?
    assert_equal 1, @company.errors.on(:agreement).size
    @company.agreement = "yes"
    assert @company.valid?
  end
  
  test "validates_confirmation_of" do
    @company.password_confirmation = "bar"
    assert !@company.valid?
    assert_equal 1, @company.errors.on(:password).size
    @company.password_confirmation = "foo"
    assert @company.valid?
  end
  
  test "validate_exclusion_of" do
    @company.name = "google"
    assert !@company.valid?
    assert_equal 1, @company.errors.on(:name).size
    @company.name = "podunk & co"
    assert @company.valid?
  end
  
  test "validates_inclusion_of" do
    @company.founding_year = 1464
    assert !@company.valid?
    assert_equal 1, @company.errors.on(:founding_year).size
    @company.founding_year = 1982
    assert @company.valid?
  end
  
  test "validates_length_of" do
    @company.name = "a"
    assert !@company.valid?
    assert_equal 4, @company.errors.on(:name).size
    @company.name = "woooooo"
    assert @company.valid?
    @company.name = "z"*42
    assert !@company.valid?
    assert_equal 4, @company.errors.on(:name).size
  end
  
end
