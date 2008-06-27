module ActiveModel
  module Validatable
    module Validations
      class ValidatesAcceptanceOf < Base
        options :message => "{attribute_name} must be accepted.", :accept=>"1"
        
        def valid?(value)
          value == options[:accept]
        end
      end
    end
  end
end