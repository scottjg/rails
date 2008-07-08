=begin
RUY-NOTE: There are two reasons for making this a class:

  1.  Generating well worded error messages which include data only known at validation time, such as
      the name of the field we're validating, the validated value, and validation config options (like max-length.)
      - e.g. "{attribute_name} must be between {min} and {max} long."
      - e.g. "{attribute_name} '{value}' is already taken by {other_user}"
      - a MUST for internationalizable default messages (think word order problems)
      Having this behavior be isolated in a class gives us a lot more power and control over the error message template.
      
   2. Allow the errors messages to be more self contained, which also makes them more 'portable'.
      This means we don't need to have an error's +Errors+ object to know what attribute it applies to.
      We can also do neat tricks ilke send back the error template as JSON with {attribute_name} left unrepalced
      so that it can be populated from the *actual* HTML LABEL element via JS (and it ALSO gives us a clue as to where
      to which INPUT the error belongs to). We are already doing this in our production app and it's VERY handy!

The actual implementation below could do with some improving however.

=end
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
        "{#{key_name}}"
      end
    end
  end
end