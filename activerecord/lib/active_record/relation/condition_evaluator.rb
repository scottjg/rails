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
        def initialize(symbol)
          @symbol = symbol
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

        private

        def arel_table
          raise NotImplementedError
        end

        def predicate(name, other)
          Condition.new(arel_table[@symbol].send(name, other))
        end
      end

      class ColumnName < Name
        def initialize(symbol, table)
          super(symbol)
          @arel_table = table
        end

        private

        attr_reader :arel_table
      end

      class TableOrColumnName < Name
        def initialize(symbol, klass)
          super(symbol)
          @klass = klass
        end

        def method_missing(method_name, *args)
          if args.empty?
            reflection = @klass.reflect_on_association(@symbol)
            table      = Arel::Table.new(reflection ? reflection.table_name : @symbol)

            ColumnName.new(method_name, table)
          else
            super
          end
        end

        private

        def arel_table
          @klass.arel_table
        end
      end

      class Context
        def initialize(klass)
          @klass = klass
        end

        def method_missing(method_name, *args)
          if args.empty?
            TableOrColumnName.new(method_name, @klass)
          else
            super
          end
        end
      end

      attr_reader :klass, :condition

      def initialize(klass, condition)
        @klass, @condition = klass, condition
      end

      def eval
        node = Context.new(klass).instance_eval(&condition).arel
        node.is_a?(Arel::Nodes::Grouping) ? node.expr : node
      end
    end
  end
end
