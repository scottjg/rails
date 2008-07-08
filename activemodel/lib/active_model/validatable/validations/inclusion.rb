module ActiveModel
  module Validatable
    module Validations
      class ValidatesInclusionOf < Base
        options :in, :message => "{attribute_name} '{value}' must be one of {in}."
        required :in
        validate_option :in=>:include?
        
        def valid?(value)
          self.in.include?(value)
        end
      end
    end
  end
end
