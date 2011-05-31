class ActiveRecord
  class Relation
    module Attributes
      class ConditionAttribute < MultiAttribute #:nodoc:
        def set(relation, opts, *other)


          case opts
          when String, Array
            [@klass.send(:sanitize_sql, other.empty? ? opts : ([opts] + other))]
          when Hash
            attributes = @klass.send(:expand_hash_conditions_for_aggregates, opts)
            PredicateBuilder.build_from_hash(table.engine, attributes, table)
          else
            [opts]
          end
        end
      end
    end
  end
end
