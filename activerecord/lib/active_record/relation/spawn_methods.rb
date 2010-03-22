module ActiveRecord
  module SpawnMethods
    def merge(r)
      merged_relation = clone
      return merged_relation unless r

      merging_values = r.options_values.clone
      merging_values.delete(:lock) if merged_relation.options_values[:lock]
      wheres = merging_values.delete(:where)

      merging_values.keys.each do |option|
        if Relation::SINGLE_VALUE_METHODS.include?(option)
          merged_relation.options_values[option] = merging_values[option].nil? ? merged_relation.options_values[option] : merging_values[option]
        else
          merged_relation.options_values[option] = Array.wrap(merged_relation.options_values[option]) + Array.wrap(merging_values[option])
        end
      end

      merged_wheres = []
      merged_wheres += options_values[:where] if options_values[:where]

      wheres.each do |w|
        if w.is_a?(Arel::Predicates::Equality)
          merged_wheres = merged_wheres.reject {|p| p.is_a?(Arel::Predicates::Equality) && p.operand1.name == w.operand1.name }
        end

        merged_wheres += [w]
      end if wheres

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
