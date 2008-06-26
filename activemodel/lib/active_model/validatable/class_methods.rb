module ActiveModel
  module Validatable
    module ClassMethods
      def validations
        @validations ||= Hash.new{|h,k|h[k] = []}
      end
      def attributes_with_validations
        @validations.keys
      end
    end
  end
end