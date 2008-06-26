validatable = File.dirname(__FILE__) + "/validatable"
require "#{validatable}/class_methods"
require "#{validatable}/errors"
require "#{validatable}/validations"

=begin
  Design notes (not for public consumption):
  
  What we currently can't do with validations:
    - Come up with well worded error messages which include data only known at validation time, such as
      the name of the field we're validating, the validated value, and validation config options (like max-length.)
      - e.g. "{attribute_name} must be between {min_length} and {max_length} long."
      - e.g. "{attribute_name} '{value}' is already taken by {other_user}"
      - a MUST for internationalizable but generic error messages!
    - Serialize error messages in such a way that they can be applied to an existing form using AJAX.
      - This would allow, among other things, generic validation-error handling
        - e.g. use angry save (save!) and then have an app wide filter to trap and render errors for ajax
      - This would also make more interesting AJAX validations (like continuous validations) much more feasible
    - Serialize validations themselves so we can, for instance, auto-generate client-side validation in certain cases.
    - Deal with errors for child classes
      - In form_for
      - Elsewhere
  
  Validation
    @base
    @attribute
    - message
    (?) name 
  
  ErrorMessage
    - template
    - message (value, maybe others?)
    - base
    - attribute
  
  ErrorMessageTemplate
    @template_string
    - evaluate(*data_sources)
    - variables
  
  Errors
    - NO DAMN IT Array like!
    - Use [] like normal people, for indexing
      - It's not a hash!
    - errors.on(:foo) - it's a filter!
      - limit to all ErrorMessages for which @attribute==:foo
      - also include @base.foo.errors if it exists
    - errors[:foo] << Error
      - only adds it to self
    
  @post.errors.on(:title)
    .each
    [i]
    .to_a / .to_json etc
  
  @post.errors.on(:title).add("Your mother")
  @post.errors.on(:author) # => 
  @post.errors #=> @attribute == :base, but also has some special meaning for enumeration
  
  
    
  
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
      
      if respond_to?(:validate)
        ActiveSupport::Deprecation.warn "Base#validate has been deprecated, please use Base.validate :method instead"
        validate
      end

      errors.empty?
    end
  end
end