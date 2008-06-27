module ActiveModel
  module Validatable
    module Validations
      class ValidatesConfirmationOf < Base
        options :message => "{attribute_name} must be confirmed."
        
        def valid?(value, object)
          value == confirmation_value(object)
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
