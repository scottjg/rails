module ActiveModel
  module Validatable
    class ErrorMessage < String
      attr_reader :object, :validation, :value, :attribute_name, :message_template
      def initialize(object, attribute_name, message_template, validation=nil)
        @object = object
        @attribute_name = attribute_name
        @message_template = message_template
        @validation = validation
        super(compile)
      end
      def compile
        @message_template.gsub(/\{[_a-z0-9]+[?!]?\}/i) do |key|
          substitute_key(key[1...-1])
        end
      end
      
      def attribute_name
        @attribute_name.to_s.humanize
      end
      
      def value
        @object.send(@attribute_name)
      end
      
      def substitute_key(key_name)
        [validation,self, value, object].each do |delegator|
          return delegator.send(key_name) if delegator.respond_to?(key_name)
        end
        raise "Could not find susbtitution value for {#{key_name}} in #{message_template.inspect}"
      end
    end
  end
end