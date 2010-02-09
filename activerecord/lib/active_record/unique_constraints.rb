module ActiveRecord
  module UniqueConstraints
    extend ActiveSupport::Concern

    # work around postgres not allowing us to query indexes in the middle of an aborted transaction
    def cache_indexes #:nodoc:
      connection.cached_indexes(self.class.table_name) if connection.respond_to?(:cached_indexes)
    end

    def save(*) #:nodoc:
      cache_indexes
      super
    rescue ActiveRecord::RecordNotUnique => e
      parse_unique_exception(e)
      false
    end

    def save!(*) #:nodoc:
      cache_indexes
      super
    rescue ActiveRecord::RecordNotUnique => e
      parse_unique_exception(e)
      raise RecordInvalid.new(self)
    end

    protected

    def parse_unique_exception(e)
      index = connection.index_for_record_not_unique(e, self.class.table_name)
      if !index
        errors[:base] << I18n.translate(:'activerecord.errors.messages.taken_generic')
      elsif index.columns.size == 1
        errors.add(index.columns.first, :taken, :value => attributes[index.columns.first])
      else
        errors.add(index.columns.first, :taken_multiple, :context => index.columns.slice(1..-1).join('/'), :value => attributes[index.columns.first])
      end
    end
  end
end
