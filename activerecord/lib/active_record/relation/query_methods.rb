require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/blank'

module ActiveRecord
  module QueryMethods
    extend ActiveSupport::Concern

    def includes(*args)
      args.reject! {|a| a.blank? }
      return self if args.empty?
      clone.includes!(*args)
    end

    def includes!(*args)
      args.reject! {|a| a.blank? }
      self.attributes[:includes] = (attributes[:includes] + args).flatten.uniq
      self
    end

    def eager_load(*args)
      return self if args.blank?
      clone.eager_load!(*args)
    end

    def eager_load!(*args)
      self.attributes[:eager_load] += args
      self
    end

    def preload(*args)
      return self if args.blank?
      clone.preload!(*args)
    end

    def preload!(*args)
      self.attributes[:preload] += args
      self
    end

    def select(value = Proc.new)
      if block_given?
        to_a.select {|*block_args| value.call(*block_args) }
      else
        clone.select!(value)
      end
    end

    def select!(value)
      self.attributes[:select] += Array.wrap(value)
      self
    end

    def group(*args)
      return self if args.blank?
      clone.group!(*args)
    end

    def group!(*args)
      self.attributes[:group] += args.flatten
      self
    end

    def order(*args)
      return self if args.blank?
      clone.order!(*args)
    end

    def order!(*args)
      self.attributes[:order] += args.flatten
      self
    end

    def reorder(*args)
      return self if args.blank?
      clone.reorder!(*args)
    end

    def reorder!(*args)
      self.attributes[:reorder] = args.flatten
      self
    end

    def joins(*args)
      return self if args.compact.blank?
      clone.joins!(*args)
    end

    def joins!(*args)
      self.attributes[:joins] += args.flatten
      self
    end

    def bind(value)
      clone.bind!(value)
    end

    def bind!(value)
      self.attributes[:bind] += [value]
      self
    end

    def where(opts, *rest)
      return self if opts.blank?
      clone.where!(opts, *rest)
    end

    def where!(opts, *rest)
      self.attributes[:where] += build_where(opts, rest)
      self
    end

    def having(*args)
      return self if args.blank?
      clone.having!(*args)
    end

    def having!(*args)
      self.attributes[:having] += build_where(*args)
      self
    end

    def limit(value)
      clone.limit!(value)
    end

    def limit!(value)
      self.attributes[:limit] = value
      self
    end

    def offset(value)
      clone.offset!(value)
    end

    def offset!(value)
      self.attributes[:offset] = value
      self
    end

    def lock(locks = true)
      clone.lock!(locks)
    end

    def lock!(locks = true)
      case locks
      when String, TrueClass, NilClass
        self.attributes[:lock] = locks || true
      else
        self.attributes[:lock] = false
      end

      self
    end

    def readonly(value = true)
      clone.readonly!(value)
    end

    def readonly!(value = true)
      self.attributes[:readonly] = value
      self
    end

    def create_with(value)
      clone.create_with!(value)
    end

    def create_with!(value)
      self.attributes[:create_with] = value && (attributes[:create_with] || {}).merge(value)
      self
    end

    def from(value)
      clone.from!(value)
    end

    def from!(value)
      self.attributes[:from] = value
      self
    end

    def extending(*modules)
      modules << Module.new(&Proc.new) if block_given?
      return self if modules.empty?
      clone.extending!(*modules)
    end

    def extending!(*modules)
      modules << Module.new(&Proc.new) if block_given?

      apply_modules(modules.flatten)
      self
    end

    def reverse_order
      clone.reverse_order!
    end

    def reverse_order!
      order_clause = arel.order_clauses

      order = order_clause.empty? ?
        "#{table_name}.#{primary_key} DESC" :
        reverse_sql_order(order_clause).join(', ')

      self.attributes[:order] = [Arel.sql(order)]
      self
    end

    def arel
      @arel ||= with_default_scope.build_arel
    end

    def build_arel
      arel = table.from table

      build_joins(arel, attributes[:joins]) unless attributes[:joins].empty?

      collapse_wheres(arel, (attributes[:where] - ['']).uniq)

      arel.having(*attributes[:having].uniq.reject{|h| h.blank?}) unless attributes[:having].empty?

      arel.take(connection.sanitize_limit(attributes[:limit])) if attributes[:limit]
      arel.skip(attributes[:offset]) if attributes[:offset]

      arel.group(*attributes[:group].uniq.reject{|g| g.blank?}) unless attributes[:group].empty?

      order = attributes[:reorder] || attributes[:order]
      arel.order(*order.uniq.reject{|o| o.blank?}) unless order.empty?

      build_select(arel, attributes[:select].uniq)

      arel.from(attributes[:from]) if attributes[:from]
      arel.lock(attributes[:lock]) if attributes[:lock]

      arel
    end

    private

    def custom_join_ast(table, joins)
      joins = joins.reject { |join| join.blank? }

      return [] if joins.empty?

      @implicit_readonly = true

      joins.map do |join|
        case join
        when Array
          join = Arel.sql(join.join(' ')) if array_of_strings?(join)
        when String
          join = Arel.sql(join)
        end
        table.create_string_join(join)
      end
    end

    def collapse_wheres(arel, wheres)
      equalities = wheres.grep(Arel::Nodes::Equality)

      arel.where(Arel::Nodes::And.new(equalities)) unless equalities.empty?

      (wheres - equalities).each do |where|
        where = Arel.sql(where) if String === where
        arel.where(Arel::Nodes::Grouping.new(where))
      end
    end

    def build_where(opts, other = [])
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

    def build_joins(manager, joins)
      buckets = joins.group_by do |join|
        case join
        when String
          'string_join'
        when Hash, Symbol, Array
          'association_join'
        when ActiveRecord::Associations::JoinDependency::JoinAssociation
          'stashed_join'
        when Arel::Nodes::Join
          'join_node'
        else
          raise 'unknown class: %s' % join.class.name
        end
      end

      association_joins         = buckets['association_join'] || []
      stashed_association_joins = buckets['stashed_join'] || []
      join_nodes                = buckets['join_node'] || []
      string_joins              = (buckets['string_join'] || []).map { |x|
        x.strip
      }.uniq

      join_list = custom_join_ast(manager, string_joins)

      join_dependency = ActiveRecord::Associations::JoinDependency.new(
        @klass,
        association_joins,
        join_list
      )

      join_nodes.each do |join|
        join_dependency.alias_tracker.aliased_name_for(join.left.name.downcase)
      end

      join_dependency.graft(*stashed_association_joins)

      @implicit_readonly = true unless association_joins.empty? && stashed_association_joins.empty?

      # FIXME: refactor this to build an AST
      join_dependency.join_associations.each do |association|
        association.join_to(manager)
      end

      manager.join_sources.concat join_nodes.uniq
      manager.join_sources.concat join_list

      manager
    end

    def build_select(arel, selects)
      unless selects.empty?
        @implicit_readonly = false
        arel.project(*selects)
      else
        arel.project(@klass.arel_table[Arel.star])
      end
    end

    def apply_modules(modules)
      unless modules.empty?
        @extensions += modules
        modules.each {|extension| extend(extension) }
      end
    end

    def reverse_sql_order(order_query)
      order_query.join(', ').split(',').collect do |s|
        s.gsub!(/\sasc\Z/i, ' DESC') || s.gsub!(/\sdesc\Z/i, ' ASC') || s.concat(' DESC')
      end
    end

    def array_of_strings?(o)
      o.is_a?(Array) && o.all?{|obj| obj.is_a?(String)}
    end

  end
end
