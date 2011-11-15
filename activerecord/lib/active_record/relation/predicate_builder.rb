module ActiveRecord
  class PredicateBuilder # :nodoc:
    def self.build_from_hash(engine, attributes, default_table)
      predicates = attributes.map do |column, value|
        table = default_table

        if value.is_a?(Hash)
          table = Arel::Table.new(column, engine)
          build_from_hash(engine, value, table)
        else
          column = column.to_s

          if column.include?('.')
            table_name, column = column.split('.', 2)
            table = Arel::Table.new(table_name, engine)
          end

          attribute = table[column.to_sym]

          case value
          when ActiveRecord::Relation
            value = value.select(value.klass.arel_table[value.klass.primary_key]) if value.select_values.empty?
            attribute.in(value.arel.ast)
          when Array, ActiveRecord::Associations::CollectionProxy
            values = value.to_a.map { |x|
              x.is_a?(ActiveRecord::Base) ? x.id : x
            }

            if values.include?(nil)
              values = values.compact
              if values.empty?
                attribute.eq nil
              else
                from_array_with_ranges(attribute, values).or attribute.eq(nil)
              end
            else
              from_array_with_ranges(attribute, values)
            end

          when Range, Arel::Relation
            attribute.in(value)
          when ActiveRecord::Base
            attribute.eq(value.id)
          when Class
            # FIXME: I think we need to deprecate this behavior
            attribute.eq(value.name)
          else
            attribute.eq(value)
          end
        end
      end

      predicates.flatten
    end

    def self.from_array_with_ranges(attribute, values)
      ranges, other = values.partition { |v|
        v.is_a?(Range) || v.is_a?(Arel::Relation)
      }

      if ranges.empty?
        attribute.in(values)
      else
        attribute.in_any(ranges + [other])
      end
    end
  end
end
