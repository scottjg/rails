module ActiveRecord
  module OperatorMethods
    def self.included(base)
      base.extend Methods
      base.class_eval do
        include Methods
      end
      
    end
    module Methods
      [:not_eq].each do |operator|
         define_method operator do |*values|
           Operator.new(operator, values)
         end
       end
    end
    
  end
end