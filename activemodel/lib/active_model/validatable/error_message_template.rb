module ActiveModel
  module Validatable
    class ErrorMessageTemplate
      attr_reader :object
      def initialize(object, attribute_name, message_template)
        @object = object
        @attribute_name = attribute_name
        @message_template = message_template
      end
      def call(*args)
        @message_template.gsub(/\{[_a-zA_Z?!]+\}/) do |key|
          substitute_key(key[1...-1])
        end
      end
      alias_method :to_s, :call
      
      def attribute_name
        @attribute_name.to_s.humanize
      end
      
      def substitute_key(key_name)
        if %w(attribute_name).include?(key_name)
          delegator = self 
        else
          delegator = @object
        end
        delegator.send(key_name)
      end
    end
  end
end