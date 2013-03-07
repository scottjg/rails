module ActiveRecord
  module ArelBuilder # :nodoc:

    # Like #arel, but ignores the default scope of the model.
    def build_arel
      arel = Arel::SelectManager.new(table.engine, table)

      build_joins(arel, joins_values) unless joins_values.empty?

      collapse_wheres(arel, (where_values - ['']).uniq)

      arel.having(*having_values.uniq.reject{|h| h.blank?}) unless having_values.empty?

      arel.take(connection.sanitize_limit(limit_value)) if limit_value
      arel.skip(offset_value.to_i) if offset_value

      arel.group(*group_values.uniq.reject{|g| g.blank?}) unless group_values.empty?

      build_order(arel)

      build_select(arel, select_values.uniq)

      arel.distinct(uniq_value)
      arel.from(build_from) if from_value
      arel.lock(lock_value) if lock_value

      arel
    end

    private

      def build_joins(manager, joins)
        buckets = joins.group_by do |join|
          case join
          when String
            :string_join
          when Hash, Symbol, Array
            :association_join
          when ActiveRecord::Associations::JoinDependency::JoinAssociation
            :stashed_join
          when Arel::Nodes::Join
            :join_node
          else
            raise 'unknown class: %s' % join.class.name
          end
        end

        association_joins         = buckets[:association_join] || []
        stashed_association_joins = buckets[:stashed_join] || []
        join_nodes                = (buckets[:join_node] || []).uniq
        string_joins              = (buckets[:string_join] || []).map { |x|
          x.strip
        }.uniq

        join_list = join_nodes + custom_join_ast(manager, string_joins)

        join_dependency = ActiveRecord::Associations::JoinDependency.new(
                                                                         @klass,
                                                                         association_joins,
                                                                         join_list
                                                                         )

        join_dependency.graft(*stashed_association_joins)

        @implicit_readonly = true unless association_joins.empty? && stashed_association_joins.empty?

        # FIXME: refactor this to build an AST
        join_dependency.join_associations.each do |association|
          association.join_to(manager)
        end

        manager.join_sources.concat join_list

        manager
      end

      def build_from
        opts, name = from_value
        case opts
        when Relation
          name ||= 'subquery'
          opts.arel.as(name.to_s)
        else
          opts
        end
      end

      def build_order(arel)
        orders = order_values
        orders = reverse_sql_order(orders) if reverse_order_value

        orders = orders.uniq.reject(&:blank?).flat_map do |order|
          case order
          when Symbol
            table[order].asc
          when Hash
            order.map { |field, dir| table[field].send(dir) }
          else
            order
          end
        end

        arel.order(*orders) unless orders.empty?
      end

      def collapse_wheres(arel, wheres)
        equalities = wheres.grep(Arel::Nodes::Equality)

        arel.where(Arel::Nodes::And.new(equalities)) unless equalities.empty?

        (wheres - equalities).each do |where|
          where = Arel.sql(where) if String === where
          arel.where(Arel::Nodes::Grouping.new(where))
        end
      end

      def reverse_sql_order(order_query)
        order_query = ["#{quoted_table_name}.#{quoted_primary_key} ASC"] if order_query.empty?

        order_query.flat_map do |o|
          case o
          when Arel::Nodes::Ordering
            o.reverse
          when String
            o.to_s.split(',').collect do |s|
              s.strip!
              s.gsub!(/\sasc\Z/i, ' DESC') || s.gsub!(/\sdesc\Z/i, ' ASC') || s.concat(' DESC')
            end
          when Symbol
            { o => :desc }
          when Hash
            o.each_with_object({}) do |(field, dir), memo|
              memo[field] = (dir == :asc ? :desc : :asc )
            end
          else
            o
          end
        end
      end
  end
end
