module ActiveModel
  module Validatable
    module Validations
      class ValidatesPresenceOf < Base
        options :message => "{attribute_name} can't be empty."
        
        def valid?(value)
          !value.blank?
        end
      end
    end
  end
end
