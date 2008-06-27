module ActiveModel
  module Validatable
    module Validations
      # Unlike validates_condition, this doesn't have a message option and you're expected
      # to call +errors.add(message)+ on your own and the return value of the block is not
      # important.
      class ValidatesEach < Base
        options :block
        required :block => "#{validation_macro_name} requires a block."
        def valid?(value, instance)
          instance.instance_exec(*[value, @attribute][0...block_arity], &options[:block])
          true
        end
      end
    end
  end
end