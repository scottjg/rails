require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
class TestClassBase
  include ActiveModel::Validatable
  def initialize(attribs={})
    attribs.each do |attr, value|
      self.send("#{attr}=",value)
    end
  end
end

module ActiveModel
  class ValidationTestCase < TestCase
    class << self
      @@test_classes = {}
      # Define +klass+ every time a test runs.
      # Defines +attributes+ as accessors if given.
      # Creates a convenience method to instantiate +klass+.
      def validation_test_class(klass, *attributes)
        @@test_classes[klass] = attributes
        define_method klass.to_s.underscore do 
          @instances[klass] ||= self.class.const_get(klass).new
        end
      end
    end
    def setup
      @instances = {}
      @@test_classes.each do |klass_name, attributes|
        silence_warnings do
          new_klass = self.class.const_set klass_name, Class.new(TestClassBase)
          new_klass.send :attr_accessor, *attributes
        end
      end
    end
    def assert_errors(expected, object)
      assert !object.valid?
      assert_equal expected.sort, object.errors.to_a.sort
    end
    
    def assert_valid(object)
      assert object.valid?, "Validation failures:\n#{object.errors.collect{|e|"  - #{e}"}}"
    end
  end
end