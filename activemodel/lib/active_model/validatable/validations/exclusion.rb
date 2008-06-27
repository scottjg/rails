module ActiveModel
  module Validatable
    module Validations
      class ValidatesExclusionOf < Base
        options :in, :message => "{attribute_name} '{value}' is reserved."
        required :in
        validate :in=>:include?
        
        def valid?(value)
          !options[:in].include?(value)
        end
      end
    end
  end
end
