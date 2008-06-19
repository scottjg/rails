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

  # This class builds on ActiveModel::Validations to add ActiveRecord
  # -specific functionality, namely:
  #
  #   * adding validate_on_create and validate_on_update callbacks to support 
  #     the :on=>(:save|:create) option
  #   * defining the 'bang' methods (save! and create!)
  #
  module Validations
    def self.included(base) # :nodoc:
      base.extend ClassMethods
      base.class_eval do
        alias_method_chain :save, :validation
        alias_method_chain :save!, :validation
        alias_method_chain :valid?, :create_or_update_callbacks
      end
      base.define_callbacks :validate_on_create, :validate_on_update
      base.default_validation_options[:on] = :save
    end
    
    module ClassMethods
      # Creates an object just like Base.create but calls save! instead of save
      # so an exception is raised if the record is invalid.
      def create!(attributes = nil, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| create!(attr, &block) }
        else
          object = new(attributes)
          yield(object) if block_given?
          object.save!
          object
        end
      end
      def validation_method(on)
        case on
          when :save   then :validate
          when :create then :validate_on_create
          when :update then :validate_on_update
          else super(on)
        end
      end
      
    end
    
    def valid_with_create_or_update_callbacks?
      valid_without_create_or_update_callbacks?
      if new_record?
        run_callbacks(:validate_on_create)

        if respond_to?(:validate_on_create)
          ActiveSupport::Deprecation.warn(
            "Base#validate_on_create has been deprecated, please use Base.validate_on_create :method instead")
          validate_on_create
        end
      else
        run_callbacks(:validate_on_update)

        if respond_to?(:validate_on_update)
          ActiveSupport::Deprecation.warn(
            "Base#validate_on_update has been deprecated, please use Base.validate_on_update :method instead")
          validate_on_update
        end
      end
      errors.empty?
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
