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
            raise InvalidOptionValue, "'#{self.class.validation_macro_name} :#{key} => <#{value.class}>' <#{value.class}>.#{validation} does not respond" unless value.respond_to?(validation)
          end
        end
        
      end
    end
  end
end