class ActiveRecord
  class Relation
    module Attributes
      class Select < MultiAttribute #:nodoc:
        def add(relation, select)
          relation.attributes[:select] + Array.wrap(select)
        end
      end
    end
  end
end
