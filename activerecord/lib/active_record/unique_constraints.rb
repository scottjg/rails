module ActiveRecord
  # See ActiveRecord::Transactions::ClassMethods for documentation.
  module UniqueConstraints
    def self.included(base)
      base.class_eval do
        alias_method_chain :save, :unique_constraints
        alias_method_chain :save!, :unique_constraints
      end
    end

    # work around postgres not allowing us to query indexes in the middle of an aborted transaction
    def cache_indexes
      connection.cached_indexes(self.class.table_name) if connection.respond_to?(:cached_indexes)
    end

    def save_with_unique_constraints(perform_validation = true) #:nodoc:
      cache_indexes
      save_without_unique_constraints(perform_validation)
    rescue ActiveRecord::RecordNotUnique => e
      parse_unique_exception(e)
      false
    end

    def save_with_unique_constraints! #:nodoc:
      cache_indexes
      save_without_unique_constraints!
    rescue ActiveRecord::RecordNotUnique => e
      parse_unique_exception(e)
      raise RecordInvalid.new(self)
    end

    protected
      def parse_unique_exception(e)
        index = connection.index_for_record_not_unique(e.original_exception, self.class.table_name)
        if !index
          errors.add_to_base(I18n.translate(:'activerecord.errors.messages.taken_generic'))
        elsif index.columns.size == 1
          errors.add(index.columns.first, :taken, :value => attributes[index.columns.first])
        else
          errors.add(index.columns.first, :taken_multiple, :context => index.columns.slice(1..-1).join('/'), :value => attributes[index.columns.first])
        end
      end
  end
end