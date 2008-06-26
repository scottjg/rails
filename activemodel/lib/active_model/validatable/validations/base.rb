module ActiveModel
  module Validatable
    module Validations
      class Base
        attr_reader :attribute, :klass, :options
        def initialize(klass, attribute,options={})
          @klass = klass
          @attribute = attribute
          @options = options
        end
        
        def validate(instance)
          instance.errors.on(attribute).add(message) if valid?(instance)
        end
        
        def get_value(instance)
          instance.send(self.attribute)
        end
        
        def message
          options[:message]
        end
          
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
        end
      end
    end
  end
end