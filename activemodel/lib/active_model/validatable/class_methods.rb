module ActiveModel
  module Validatable
    module ClassMethods
      def validations
        @validations ||= Hash.new{|h,k|h[k] = []}
      end
    end
  end
end