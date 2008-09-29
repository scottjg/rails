require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))
class AssociationsTest < ActiveModel::TestCase

  class Something < ActiveModel::Base
    def self.tada
      "TADA!"
    end
  end
      
  class Example < ActiveModel::Base
    has_many :somethings
  end
  
  # test "Model supports has_many class-level call" do
  #     assert_nothing_raised do
  #       Class.new(ActiveModel::Base) do
  #         has_many :somethings
  #       end
  #     end
  #   end
  #   
  #   test "has_many creates a reflection which can be inspected" do
  #     assert_not_nil Example.reflect_on_association(:somethings)
  #   end
  #   
  #   test "has_many generates accessor methods based on reflection name" do
  #     assert_respond_to Example.new, :somethings
  #     assert_respond_to Example.new, :somethings=
  #     assert_respond_to stubbed_example_model.somethings, :each
  #   end
  # test "can do .class" do
  #   stubbed_example_model.somethings.class
  # end
  
  test "proxies missing methods through to the model which the association is configured for" do
    # method_missing should be invoked on somethings, which is a HasManyAssociation instance (see collection_reader_method in assocations.rb)    
    # We expect HasManyAssociation's superclass (AssociationCollection) to handle this method_missing invokation.
    # Instead, when we call #tada, it's invoking method_missing on AssociationCollection's superclass despite there being a method_missing on AssociationCollection
    # I've seen problems with errors seeming to be swallowed inside method_missing, so maybe the issue is that AssociationCollection's method_missing is in fact being called
    # but I'm somehow not able to see that.
#    require 'ruby-debug'; debugger
    the_proxy = stubbed_example_model.somethings
    assert_equal "TADA!", the_proxy.tada
  end
  
  private
    def stubbed_example_model
      returning example = Example.new do
        example.stubs(:persistence_driver).returns(stub('persistence driver', :new_record? => false, :find => []))
      end
    end
end