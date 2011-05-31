class ActiveRecord
  class Relation
    module Attributes
      class MultiAttribute < Attribute #:nodoc:
        def initial
          []
        end

        def add(relation, *args)
          relation.attributes[name] + args.compact.flatten
        end
      end
    end
  end
end
