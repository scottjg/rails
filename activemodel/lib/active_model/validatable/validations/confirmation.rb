module ActiveModel
  module Validatable
    module Validations
      class ValidatesConfirmationOf < Base
        options :message => "{attribute_name} must be confirmed.", :case_sensitive => true
        
        def valid?(value, object)
          if case_sensitive
            value == confirmation_value(object)
          else
            value.casecmp(confirmation_value(object)) == 0
          end
        end
        def confirmation_attribute
          "#{attribute}_confirmation"
        end
        def confirmation_value(object)
          object.send(confirmation_attribute)
        end
      end
    end
  end
end
