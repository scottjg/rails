require File.join(File.dirname(__FILE__), "errors")
module ActiveModel
  module Validations
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send!(:include, ActiveSupport::Callbacks)
      base.class_eval do
        alias_method_chain :save, :validation
        alias_method_chain :save!, :validation
      end
      base.define_callbacks :validate, :validate_on_create, :validate_on_update
    end

    module ClassMethods
      DEFAULT_VALIDATION_OPTIONS = { :on => :save, :allow_nil => false, :allow_blank => false, :message => nil }.freeze

      # Adds a validation method or block to the class. This is useful when
      # overriding the +validate+ instance method becomes too unwieldly and
      # you're looking for more descriptive declaration of your validations.
      #
      # This can be done with a symbol pointing to a method:
      #
      #   class Comment < ActiveRecord::Base
      #     validate :must_be_friends
      #
      #     def must_be_friends
      #       errors.add_to_base("Must be friends to leave a comment") unless commenter.friend_of?(commentee)
      #     end
      #   end
      #
      # Or with a block which is passed the current record to be validated:
      #
      #   class Comment < ActiveRecord::Base
      #     validate do |comment|
      #       comment.must_be_friends
      #     end
      #
      #     def must_be_friends
      #       errors.add_to_base("Must be friends to leave a comment") unless commenter.friend_of?(commentee)
      #     end
      #   end
      #
      # This usage applies to +validate_on_create+ and +validate_on_update as well+.
      #
      # Validates each attribute against a block.
      #
      #   class Person < ActiveRecord::Base
      #     validates_each :first_name, :last_name do |record, attr, value|
      #       record.errors.add attr, 'starts with z.' if value[0] == ?z
      #     end
      #   end
      #
      # Options:
      # * <tt>:on</tt> - Specifies when this validation is active (default is <tt>:save</tt>, other options <tt>:create</tt>, <tt>:update</tt>)
      # * <tt>:allow_nil</tt> - Skip validation if attribute is +nil+.
      # * <tt>:allow_blank</tt> - Skip validation if attribute is blank.
      # * <tt>:if</tt> - Specifies a method, proc or string to call to determine if the validation should
      #   occur (e.g. <tt>:if => :allow_validation</tt>, or <tt>:if => Proc.new { |user| user.signup_step > 2 }</tt>).  The
      #   method, proc or string should return or evaluate to a true or false value.
      # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine if the validation should
      #   not occur (e.g. <tt>:unless => :skip_validation</tt>, or <tt>:unless => Proc.new { |user| user.signup_step <= 2 }</tt>).  The
      #   method, proc or string should return or evaluate to a true or false value.
      def validates_each(*attrs)
        options = attrs.extract_options!.symbolize_keys
        attrs   = attrs.flatten

        # Declare the validation.
        send(validation_method(options[:on] || :save), options) do |record|
          attrs.each do |attr|
            value = record.send(attr)
            next if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank])
            yield record, attr, value
          end
        end
      end

      private
        def validation_method(on)
          case on
            when :save   then :validate
            when :create then :validate_on_create
            when :update then :validate_on_update
          end
        end
    end

    # Returns the Errors object that holds all information about attribute error messages.
    def errors
      @errors ||= Errors.new
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

    # Runs all the specified validations and returns true if no errors were added otherwise false.
    def valid?
      errors.clear

      run_callbacks(:validate)
      
      if respond_to?(:validate)
        ActiveSupport::Deprecation.warn "Base#validate has been deprecated, please use Base.validate :method instead"
        validate
      end

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
  end
end

Dir[File.dirname(__FILE__) + "/validations/*.rb"].sort.each do |path|
  filename = File.basename(path)
  require "active_model/validations/#{filename}"
end