=begin
RUY-NOTE:
Validations-as-classes was inspired (loosley) by the Validatable gem. 

A validation class can turn itself into a macro (using Base.define_validation_macro(other_class)) based on it's name.

The macro will instantiate the class and add it to other_class.validations hash, which stores validations by attribute name.
(So yes, validates_presence_of :name, :password will generate TWO ValidatesPresenceOf instances, one in base.validations[:name] 
and one in base.validations[:password])

This alone has advantages: we can finally attempt to serialize validations for public consumption elsewhere. Auto-generated
JavaScript validation is one obvious possibility, converting some validations to RDBMS constraints is a more exotic one.

The Validations::Base contains several facilities for declaring valid options, making some required, validating their type etc.

For the most part, sublasses need only declare their options using the above helpers, and implement a valid? instance method. 
acceptance.rb contains a nice illustration of this. lentgh.rb contains something more complicated.

The Base class also takes care of common options, such as :allow_nil, :allow_blank, :if and so forth (and also provides a convenient
'hook' point for adding new 'global' options, such as :on for ActiveRecord).

TODO:
:if/:unless are not actually supported yet - I would like to implement them using a callback (:should_run) - which could be used
to implement not only :if/:unless but also :allow_nil/:allow_blank and Validatable's (the gem) :group option.

Unforunately there is no way to pass additional arguments to callbacks (like the object instance... kinda important) using AciveSupport::Callbacks, 
so I will probably have to either add that to AS:C or start hammering out ActiveModel::Callbacks. 

=end
module ActiveModel
  module Validatable
    class InvalidOption < Exception; end
    class InvalidOptionValue < Exception; end
    
    class MissingRequiredOption < Exception; end
      
    module Validations
      class Base
        class << self
          def validation_macro_name
            name.demodulize.underscore
          end
          def define_validation_macro(base)
            return if self == Base
            base.instance_eval <<-end_eval, __FILE__, __LINE__+1
              def #{validation_macro_name}(*attribute_names, &block)
                options = attribute_names.extract_options!
                options[:block] = block if block
                attribute_names.each do |attribute_name|
                  self.validations[attribute_name] << #{self.name}.new(self, attribute_name, options)
                end
              end
            end_eval
          end
          
          # Define valid options for the validation, optionally specifying default values. 
          # Options will be exposed as instance methods to the validation.
          # 
          # Example:
          #
          #   class ValidatesInclusionOf < Base
          #     options :in, :message => "{attribute_name} '{value}' must be one of {in}."
          #   end
          #   v = ValidatesInclusionOf.new
          #   v.message # => "{attribute_name} '{value}' must be one of {in}."
          #   v.in      # => nil
          def options(*options)
            defaults = options.extract_options!
            (options + defaults.keys).each do |option|
              register_option(option)
            end
            defaults.each do |option, default_value|
              self.default_options[option] = default_value
            end
          end
          
          # Define which options are required, optionally specifying a cusotm error message.
          #
          # Example:
          #
          #   class ValidatesEach < Base
          #     options :block
          #     required :block => "#{validation_macro_name} requires a block."
          #   end
          def required(*options)
            options_with_messages = options.extract_options!
            options.each do |option|
              self.required_options[option] = "#{validation_macro_name} requires the :#{option} option to be set"
            end
            self.required_options.merge!(options_with_messages)
          end
          
          # Define a 'validation on the validation' which checks each validation option against if 
          # it is a subclass of a given class, or if it responds to the given symbol.
          # 
          # Example:
          # 
          #   class ValidatesInclusionOf < Base
          #     options :in, :message
          #     validate_option :in=>:include?, :message=>String 
          #   end
          def validate_option(validations={})
            self.option_validations = validations
          end
          
          private
          
          def register_option(option)
            self.valid_options << option
            self.send :define_method, option do 
              options[option]
            end
          end
        end
        
        attr_reader :attribute, :klass, :options
        class_inheritable_hash :default_options
        self.default_options = {}
        class_inheritable_array :valid_options
        self.valid_options = []
        
        class_inheritable_hash :required_options
        self.required_options = {}
        
        class_inheritable_hash :option_validations
        self.option_validations = {}
        
        options :message=>"{attribute_name} is invalid.", :allow_nil => false, :allow_blank=>false
        
        def initialize(klass, attribute,options={})
          @klass = klass
          @attribute = attribute
          @options = self.class.default_options.merge(options)
          validate_options
        end
        
        def validate(instance)
          value = get_value(instance)
          return if allow_nil && value.nil?
          return if allow_blank && value.blank?
          arity = method(:valid?).arity
          instance.errors.on(attribute).add(message,self) unless valid?(*[value,instance][0...arity])
        end
        
        def get_value(instance)
          instance.send(self.attribute)
        end
        
        def block_arity
          options[:block].arity
        end
        
        private
        
        # Verifies the options passed to the validation macro
        def validate_options
          options.keys.each do |option|
            raise InvalidOption, "#{option.inspect} is not a valid option for #{self.class.validation_macro_name}" unless self.class.valid_options.include?(option)
          end
          
          self.class.required_options.each do |option, error_message|
            raise MissingRequiredOption, error_message unless options.has_key?(option)
          end
          
          self.class.option_validations.each do |key, validation|
            next unless options.has_key?(key)
            value = options[key]
            case validation
            when Symbol
              raise InvalidOptionValue, "'#{self.class.validation_macro_name} :#{key} => <#{value.class}>' requires <#{value.class}> to respond to #{validation}" unless value.respond_to?(validation)
            when Class
              raise InvalidOptionValue, "'#{self.class.validation_macro_name} :#{key} => <#{value.class}>' expects <#{value.class}> to be a kind of #{validation}" unless value.kind_of?(validation)
            end
          end
        end
        
      end
    end
  end
end