require 'debugger'

module ActiveRecord
  # = Active Record Has And Belongs To Many Association
  module Associations
    class HasAndBelongsToManyAssociation < CollectionAssociation #:nodoc:
      attr_reader :join_table

      def initialize(owner, reflection)
        @join_table = Arel::Table.new(reflection.join_table)
        super
      end

      def insert_record(record, validate = true, raise = false)
        if record.new_record?
          if raise
            record.save!(:validate => validate)
          else
            return unless record.save(:validate => validate)
          end
        end

        if options[:insert_sql]
          owner.connection.insert(interpolate(options[:insert_sql], record))
        else
          stmt = join_table.compile_insert(
            join_table[reflection.foreign_key]             => owner.id,
            join_table[reflection.association_foreign_key] => record.id
          )

          owner.connection.insert stmt
        end
        update_counter(1)
        record
      end

      private

        def cached_counter_attribute_name
          source_reflection.counter_cache_column
        end

        def count_records
          if has_cached_counter?
            cached_count = owner.send(:read_attribute, cached_counter_attribute_name)
          end
          cached_count || load_target.size
        end

        def delete_records(records, method)
          count = if sql = options[:delete_sql]
            records = load_target if records == :all
            records.each { |record| owner.connection.delete(interpolate(sql, record)) }
            records.length
          else
            relation  = join_table
            condition = relation[reflection.foreign_key].eq(owner.id)

            unless records == :all
              condition = condition.and(
                relation[reflection.association_foreign_key]
                  .in(records.map { |x| x.id }.compact)
              )
            end

            count = owner.connection.delete(relation.where(condition).compile_delete)
          end
          update_counter(-count)
          count
        end

        def has_cached_counter?
          unless source_reflection
            debugger
          end
          source_reflection.options[:counter_cache]
        end

        def invertible_for?(record)
          false
        end

        def source_reflection(reflection = reflection)
          habtm_refs = reflection.klass.reflect_on_all_associations(:has_and_belongs_to_many)
          habtm_refs.select do |source_reflection|
            reflection.join_table == source_reflection.join_table
          end.first
        end

        def update_counter(difference, reflection = reflection)
          if has_cached_counter?
            counter = cached_counter_attribute_name
            owner.class.update_counters(owner.id, counter => difference)
            owner[counter] += difference
            owner.changed_attributes.delete(counter) # eww
          end
        end
    end
  end
end
