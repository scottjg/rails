module ActiveModel
  module Validatable
    # This is the simplest possible validation... give it a block which returns true or false (pass or fail).
    # You will usually want to provide the :message option
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