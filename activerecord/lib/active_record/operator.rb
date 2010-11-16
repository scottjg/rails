module ActiveRecord
  class Operator
     attr_reader :operator, :values

     def initialize(operator, values)
       @operator = operator
       @values = values
     end
   end
end
