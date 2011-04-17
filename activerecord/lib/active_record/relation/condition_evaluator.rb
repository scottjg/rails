module ActiveRecord
  class Relation
    class ConditionEvaluator
      class Condition
        attr_reader :arel

        def initialize(arel)
          @arel = arel
        end

        def &(other)
          # This bit just ensures we don't spam the SQL with loads of unnecessary parentheses
          if and_node?(arel)
            ands = arel.expr.children + [other.arel]
          elsif and_node?(other.arel)
            ands = [arel] + other.arel.expr.children
          else
            ands = [arel, other.arel]
          end

          Condition.new(Arel::Nodes::Grouping.new(Arel::Nodes::And.new(ands)))
        end

        def |(other)
          Condition.new(Arel::Nodes::Grouping.new(Arel::Nodes::Or.new(arel, other.arel)))
        end

        private

        def and_node?(node)
          node.is_a?(Arel::Nodes::Grouping) && node.expr.is_a?(Arel::Nodes::And)
        end
      end

      class Name
        def initialize(symbol, table)
          @symbol, @table = symbol, table
        end

        def ==(other)
          predicate :eq, other
        end

        def !=(other)
          predicate :not_eq, other
        end

        def <(other)
          predicate :lt, other
        end

        def >(other)
          predicate :gt, other
        end

        def <=(other)
          predicate :lteq, other
        end

        def >=(other)
          predicate :gteq, other
        end

        def =~(other)
          if other.is_a?(Array)
            predicate :in, other
          else
            predicate :matches, other
          end
        end

        def !~(other)
          if other.is_a?(Array)
            predicate :not_in, other
          else
            predicate :does_not_match, other
          end
        end

        def method_missing(method_name, *args)
          if args.empty?
            Name.new(method_name, Arel::Table.new(@symbol))
          else
            super
          end
        end

        private

        def predicate(name, other)
          Condition.new(@table[@symbol].send(name, other))
        end
      end

      class Context
        def initialize(table)
          @table = table
        end

        def method_missing(method_name, *args)
          if args.empty?
            Name.new(method_name, @table)
          else
            super
          end
        end
      end

      attr_reader :table, :condition

      def initialize(table, condition)
        @table, @condition = table, condition
      end

      def eval
        node = Context.new(table).instance_eval(&condition).arel
        node.is_a?(Arel::Nodes::Grouping) ? node.expr : node
      end
    end
  end
end
