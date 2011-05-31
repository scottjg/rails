class ActiveRecord
  class Relation
    module Attributes
      class Where < ConditionAttribute #:nodoc:
        def set(relation, opts, *rest)
          if opts.blank?
            relation.attributes[:where]
          else
            relation.attributes[:where] + build(opts, *rest)
          end
        end
      end
    end
  end
end
