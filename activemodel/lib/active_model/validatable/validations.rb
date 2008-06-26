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
          klass.define_validation_macro(base) if klass.respond_to?(:define_validation_macro)
        end
      end
    end
  end
end