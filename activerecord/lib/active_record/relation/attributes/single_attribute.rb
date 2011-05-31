class ActiveRecord
  class Relation
    module Attributes
      class SingleAttribute < Attribute #:nodoc:
        def initial
          nil
        end

        def add(relation, value)
          value
        end
      end
    end
  end
end
