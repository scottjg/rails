module ActiveRecord
  # Raised by save! and create! when the record is invalid.  Use the
  # +record+ method to retrieve the record which did not validate.
  #   begin
  #     complex_operation_that_calls_save!_internally
  #   rescue ActiveRecord::RecordInvalid => invalid
  #     puts invalid.record.errors
  #   end
  class RecordInvalid < ActiveRecordError
    attr_reader :record
    def initialize(record)
      @record = record
      super("Validation failed: #{@record.errors.full_messages.join(", ")}")
    end
  end
  
  module Errors
    def self.default_error_messages
      ActiveSupport::Deprecation.warn "ActiveRecord::Errors has been deprecated, use ActiveModel::Errors instead"
      ActiveModel::Errors.default_error_messages
    end
  end


  module Validations
    def self.included(base) # :nodoc:
      base.class_eval do
        alias_method_chain :save, :validation
        alias_method_chain :save!, :validation
      end
    end

    # The validation process on save can be skipped by passing false. The regular Base#save method is
    # replaced with this when the validations module is mixed in, which it is by default.
    def save_with_validation(perform_validation = true)
      if perform_validation && valid? || !perform_validation
        save_without_validation
      else
        false
      end
    end

    # Attempts to save the record just like Base#save but will raise a RecordInvalid exception instead of returning false
    # if the record is not valid.
    def save_with_validation!
      if valid?
        save_without_validation!
      else
        raise RecordInvalid.new(self)
      end
    end
  end
end
