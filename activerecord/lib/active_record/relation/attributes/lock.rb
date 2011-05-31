class ActiveRecord
  class Relation
    module Attributes
      class Lock < SingleAttribute #:nodoc:
        def add(relation, lock = true)
          case lock
          when String, TrueClass, NilClass
            lock || true
          else
            false
          end
        end
      end
    end
  end
end
