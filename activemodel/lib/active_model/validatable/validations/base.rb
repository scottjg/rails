module ActiveModel
  module Validatable
    module Validations
      class Base
        def initialize(base, attribute,options={})
          @base = base
          @attribute = attribute
          @options = options
        end
        class << self
          def validation_macro_name
            return if self == Base
            name.demodulize.underscore
          end
        end
      end
    end
  end
end