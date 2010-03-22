module ActiveRecord
  module QueryMethods
    extend ActiveSupport::Concern

    included do
      (ActiveRecord::Relation::ASSOCIATION_METHODS + ActiveRecord::Relation::MULTI_VALUE_METHODS).each do |query_method|

        next if [:where, :having].include?(query_method)
        class_eval <<-CEVAL
          def #{query_method}(*args)
            return self if args.empty?
            new_relation = clone
            value = Array.wrap(args.flatten).reject {|x| x.blank? }
            if value.present?
              new_relation.options_values[:#{query_method}] ||= []
              new_relation.options_values[:#{query_method}] += value
            end
            new_relation
          end
        CEVAL
      end

      [:where, :having].each do |query_method|
        class_eval <<-CEVAL
          def #{query_method}(*args)
            return self if args.empty?
            new_relation = clone
            value = build_where(*args)
            if value.present?
              new_relation.options_values[:#{query_method}] ||= []
              new_relation.options_values[:#{query_method}] += [*value]
            end
            new_relation
          end
        CEVAL
      end

      ActiveRecord::Relation::SINGLE_VALUE_METHODS.each do |query_method|

        class_eval <<-CEVAL
          def #{query_method}(value = true)
            return self if value.nil?
            new_relation = clone
            new_relation.options_values[:#{query_method}] = value
            new_relation
          end
        CEVAL
      end
    end

    def lock(locks = true)
      relation = clone
      case locks
      when String, TrueClass, NilClass
        clone.tap {|new_relation| new_relation.options_values[:lock] = locks || true }
      else
        clone.tap {|new_relation| new_relation.options_values[:lock] = false }
      end
    end

    def reverse_order
      order_clause = arel.send(:order_clauses).join(', ')
      relation = except(:order)

      if order_clause.present?
        relation.order(reverse_sql_order(order_clause))
      else
        relation.order("#{@klass.table_name}.#{@klass.primary_key} DESC")
      end
    end

    def arel
      @arel ||= build_arel
    end

    def build_arel
      arel = table

      if options_values[:joins]
        joined_associations = []
        association_joins = []

        joins = options_values[:joins].map {|j| j.respond_to?(:strip) ? j.strip : j}.uniq

        # Build association joins first
        joins.each do |join|
          association_joins << join if [Hash, Array, Symbol].include?(join.class) && !array_of_strings?(join)
        end

        if association_joins.any?
          join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(@klass, association_joins.uniq, nil)
          to_join = []

          join_dependency.join_associations.each do |association|
            if (association_relation = association.relation).is_a?(Array)
              to_join << [association_relation.first, association.association_join.first]
              to_join << [association_relation.last, association.association_join.last]
            else
              to_join << [association_relation, association.association_join]
            end
          end

          to_join.each do |tj|
            unless joined_associations.detect {|ja| ja[0] == tj[0] && ja[1] == tj[1] }
              joined_associations << tj
              arel = arel.join(tj[0]).on(*tj[1])
            end
          end
        end

        joins.each do |join|
          next if join.blank?

          @implicit_readonly = true

          case join
          when Relation::JoinOperation
            arel = arel.join(join.relation, join.join_class).on(*join.on)
          when Hash, Array, Symbol
            if array_of_strings?(join)
              join_string = join.join(' ')
              arel = arel.join(join_string)
            end
          else
            arel = arel.join(join)
          end
        end
      end

      options_values[:where].uniq.each do |where|
        next if where.blank?

        case where
        when Arel::SqlLiteral
          arel = arel.where(where)
        else
          sql = where.is_a?(String) ? where : where.to_sql
          arel = arel.where(Arel::SqlLiteral.new("(#{sql})"))
        end
      end if options_values[:where]

      options_values[:having].uniq.each do |h|
        arel = h.is_a?(String) ? arel.having(h) : arel.having(*h)
      end if options_values[:having]

      arel = arel.take(options_values[:limit]) if options_values[:limit]
      arel = arel.skip(options_values[:offset]) if options_values[:offset]

      options_values[:group].uniq.each do |g|
        arel = arel.group(g) if g.present?
      end if options_values[:group]

      options_values[:order].uniq.each do |o|
        arel = arel.order(Arel::SqlLiteral.new(o.to_s)) if o.present?
      end if options_values[:order]

      selects = options_values[:select]

      quoted_table_name = @klass.quoted_table_name

      if selects
        selects.uniq.each do |s|
          @implicit_readonly = false
          arel = arel.project(s) if s.present?
        end
      else
        arel = arel.project(quoted_table_name + '.*')
      end

      arel =
        if options_values[:from]
          arel.from(options_values[:from])
        else
          arel.from(quoted_table_name)
        end

      case options_values[:lock]
      when TrueClass
        arel = arel.lock
      when String
        arel = arel.lock(options_values[:lock])
      end

      arel
    end

    def build_where(*args)
      return if args.blank?

      builder = PredicateBuilder.new(table.engine)

      opts = args.first
      case opts
      when String, Array
        @klass.send(:sanitize_sql, args.size > 1 ? args : opts)
      when Hash
        attributes = @klass.send(:expand_hash_conditions_for_aggregates, opts)
        builder.build_from_hash(attributes, table)
      else
        opts
      end
    end

    private

    def reverse_sql_order(order_query)
      order_query.to_s.split(/,/).each { |s|
        if s.match(/\s(asc|ASC)$/)
          s.gsub!(/\s(asc|ASC)$/, ' DESC')
        elsif s.match(/\s(desc|DESC)$/)
          s.gsub!(/\s(desc|DESC)$/, ' ASC')
        else
          s.concat(' DESC')
        end
      }.join(',')
    end

    def array_of_strings?(o)
      o.is_a?(Array) && o.all?{|obj| obj.is_a?(String)}
    end

  end
end
