require 'active_support/core_ext/object/blank'

module ActiveRecord
  module SpawnMethods
    def merge(r)
      return self unless r
      return to_a & r if r.is_a?(Array)

      merged_relation = clone

      r = r.with_default_scope if r.default_scoped? && r.klass != klass

      (Relation::MULTI_VALUE_ATTRIBUTES - [:where]).each do |attribute|
        value = r.attributes[attribute]
        merged_relation.send("#{attribute}!", *value) if value.present?
      end

      merged_wheres = attributes[:where] + r.attributes[:where]

      unless attributes[:where].empty?
        # Remove duplicates, last one wins.
        seen = Hash.new { |h,table| h[table] = {} }
        merged_wheres = merged_wheres.reverse.reject { |w|
          nuke = false
          if w.respond_to?(:operator) && w.operator == :==
            name              = w.left.name
            table             = w.left.relation.name
            nuke              = seen[table][name]
            seen[table][name] = true
          end
          nuke
        }.reverse
      end

      merged_relation.attributes[:where] = merged_wheres

      Relation::SINGLE_VALUE_ATTRIBUTES.each do |attribute|
        value = r.attributes[attribute]
        merged_relation.send("#{attribute}!", value) unless value.nil?
      end

      # Apply scope extension modules
      merged_relation.send :apply_modules, r.extensions

      merged_relation
    end

    # Removes from the query the condition(s) specified in +skips+.
    #
    # Example:
    #
    #   Post.order('id asc').except(:order)                  # discards the order condition
    #   Post.where('id > 10').order('id asc').except(:where) # discards the where condition but keeps the order
    #
    def except(*skips)
      result = self.class.new(klass, table)
      result.default_scoped = default_scoped
      result.attributes.merge!(attributes.except(*skips))

      # Apply scope extension modules
      result.send(:apply_modules, extensions)

      result
    end

    # Removes any condition from the query other than the one(s) specified in +onlies+.
    #
    # Example:
    #
    #   Post.order('id asc').only(:where)         # discards the order condition
    #   Post.order('id asc').only(:where, :order) # uses the specified order
    #
    def only(*onlies)
      result = self.class.new(@klass, table)
      result.default_scoped = default_scoped
      result.attributes.merge!(attributes.slice(*onlies))

      # Apply scope extension modules
      result.send(:apply_modules, extensions)

      result
    end

    VALID_FIND_OPTIONS = [ :conditions, :include, :joins, :limit, :offset, :extend,
                           :order, :select, :readonly, :group, :having, :from, :lock ]

    def apply_finder_options(options)
      relation = clone
      return relation unless options

      options.assert_valid_keys(VALID_FIND_OPTIONS)
      finders = options.dup
      finders.delete_if { |key, value| value.nil? && key != :limit }

      ([:joins, :select, :group, :order, :having, :limit, :offset, :from, :lock, :readonly] & finders.keys).each do |finder|
        relation = relation.send(finder, finders[finder])
      end

      relation = relation.where(finders[:conditions]) if options.has_key?(:conditions)
      relation = relation.includes(finders[:include]) if options.has_key?(:include)
      relation = relation.extending(finders[:extend]) if options.has_key?(:extend)

      relation
    end

  end
end
