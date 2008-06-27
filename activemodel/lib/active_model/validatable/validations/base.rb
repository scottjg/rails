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
          
          def options(*options)
            defaults = options.extract_options!
            self.valid_options += options + defaults.keys
            defaults.each do |option, default_value|
              self.default_options[option] = default_value
            end
          end
          
          def required(*options)
            options_with_messages = options.extract_options!
            options.each do |option|
              self.required_options[option] = "#{validation_macro_name} requires the :#{option} option to be set"
            end
            self.required_options.merge!(options_with_messages)
          end
          
          def validate(validations={})
            self.option_validations = validations
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
        
        options :message=>"{attribute_name} is invalid."
        
        def initialize(klass, attribute,options={})
          @klass = klass
          @attribute = attribute
          @options = self.class.default_options.merge(options)
          validate_options
        end
        
        def validate(instance)
          value = get_value(instance)
          arity = method(:valid?).arity
          instance.errors.on(attribute).add(message) unless valid?(*[value,instance][0...arity])
        end
        
        def get_value(instance)
          instance.send(self.attribute)
        end
        
        def message
          options[:message]
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