module ActiveModel
  module Validatable
    module Validations
      class ValidatesCondition < Base
        options :block
        required :block => "#{validation_macro_name} requires a block."
        def valid?(value, instance)
          instance.instance_exec(*[value, @attribute][0...block_arity], &options[:block])
        end
      end
    end
  end
end