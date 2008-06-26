require File.dirname(__FILE__)+"/validations/base.rb"
Dir[File.dirname(__FILE__)+"/validations/*.rb"].each do |file|
  require file
end
module ActiveModel
  module Validatable
    module Validations
      def self.define_macros(base)
        self.constants.each do |const|
          klass = self.const_get(const)
          if klass.respond_to?(:validation_macro_name) && klass.validation_macro_name
            base.instance_eval <<-end_eval, __FILE__, __LINE__+1
              def #{klass.validation_macro_name}(*attribute_names, &block)
                options = attribute_names.extract_options!
                options[:block] = block if block
                attribute_names.each do |attribute_name|
                  self.validations[attribute_name] << #{klass.name}.new(self, attribute_name, options)
                end
              end
            end_eval
          end
        end
      end
    end
  end
end