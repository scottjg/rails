module ActiveRecord
  module SpawnMethods
    def merge(r)
      merged_relation = clone
      return merged_relation unless r

      merged_relation = merged_relation.eager_load(r.options_values[:eager_load]).preload(r.options_values[:preload]).includes(r.options_values[:includes])

      merged_relation.options_values[:readonly] = r.options_values[:readonly] unless r.options_values[:readonly].nil?
      merged_relation.options_values[:limit] = r.options_values[:limit] if r.options_values[:limit].present?
      merged_relation.options_values[:lock] = r.options_values[:lock] unless merged_relation.options_values[:lock]
      merged_relation.options_values[:offset] = r.options_values[:offset] if r.options_values[:offset].present?

      merged_relation = merged_relation.
        joins(r.options_values[:joins]).
        group(r.options_values[:group]).
        select(r.options_values[:select]).
        from(r.options_values[:from]).
        having(r.options_values[:having])

      merged_relation.options_values[:order] = r.options_values[:order] if r.options_values[:order].present?

      merged_relation.options_values[:create_with] = options_values[:create_with]

      if options_values[:create_with] && r.options_values[:create_with]
        merged_relation.options_values[:create_with] = options_values[:create_with].merge(r.options_values[:create_with])
      else
        merged_relation.options_values[:create_with] = r.options_values[:create_with] || options_values[:create_with]
      end

      merged_wheres = [*options_values[:where]]

      r.options_values[:where].each do |w|
        if w.is_a?(Arel::Predicates::Equality)
          merged_wheres = merged_wheres.reject {|p| p.is_a?(Arel::Predicates::Equality) && p.operand1.name == w.operand1.name }
        end

        merged_wheres += [w]
      end if r.options_values[:where]

      merged_relation.options_values[:where] = merged_wheres

      merged_relation
    end

    alias :& :merge

    def except(*skips)
      result = self.class.new(@klass, table)

      options_values.each do |method, value|
        result.options_values[method] = value unless skips.include?(method)
      end

      result
    end

    VALID_FIND_OPTIONS = [ :conditions, :include, :joins, :limit, :offset,
                           :order, :select, :readonly, :group, :having, :from, :lock ]

    def apply_finder_options(options)
      relation = clone
      return relation unless options

      options.assert_valid_keys(VALID_FIND_OPTIONS)

      [:joins, :select, :group, :having, :order, :limit, :offset, :from, :lock, :readonly].each do |finder|
        relation = relation.send(finder, options[finder]) if options.has_key?(finder)
      end

      relation = relation.where(options[:conditions]) if options.has_key?(:conditions)
      relation = relation.includes(options[:include]) if options.has_key?(:include)

      relation
    end

  end
end
