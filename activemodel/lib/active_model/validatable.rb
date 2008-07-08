validatable = File.dirname(__FILE__) + "/validatable"
require "#{validatable}/class_methods"
require "#{validatable}/errors"
require "#{validatable}/validations"

=begin
RUY-NOTE: Welcome to my public Work-In-Progress on AcitveModel::Validatable, which will hopefully repalce
ActiveRecord::Validations one day soon.

The most obvious changes it the rename to Validatable (mostly because i wanted to save Validations for the modules containing
the validation clases itself)

Major changes:
  - Errors 
    - fairly different .errors API - see errors.rb
    - error messages themselves encapsulated in ErrorMessage class - see error_message.rb
  - Validations are now classes - see validations/base.rb
  
Also note that this module does not COMPLETELY supplant ActiveRecord::Validations - AR-specific stuff like the :on=>:save|:update|:create
option, as well as validates_uniqueness_of are taken care of by AR:V, albeit by extending AM:V
    
  
=end
module ActiveModel
  module Validatable
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send!(:include, ActiveSupport::Callbacks)
      base.define_callbacks :validate
      Validations.define_macros(base)
    end
    
    

    # Returns the Errors object that holds all information about attribute error messages.
    def errors
      @errors ||= Errors.new(self)
    end

    # Runs all the specified validations and returns true if no errors were added otherwise false.
    def valid?
      errors.clear

      run_callbacks(:validate)
      
      self.class.validations.values.flatten.each do |validation|
        validation.validate(self)
      end
      
      if respond_to?(:validate)
        ActiveSupport::Deprecation.warn "Base#validate has been deprecated, please use Base.validate :method instead"
        validate
      end

      errors.empty?
    end
  end
end