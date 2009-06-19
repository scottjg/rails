module ActiveModel
  module Validations
    module ClassMethods

      ALL_ORDER_CHECKS = {
        :greater_than => '>',
        :greater_than_or_equal_to => '>=',
        :equal_to => '==',
        :less_than => '<',
        :less_than_or_equal_to => '<='}.freeze

      # Validates whether attribute values are in a specified order
      #
      #   class Person < ActiveRecord::Base
      #     validates_order_of :date_of_birth, :less_than_or_equal_to => :date_of_death
      #     validates_order_of :date_of_first_words, :greater_than => :date_of_birth, :less_than => :date_of_death
      #   end
      #
      # Configuration options:
      # * <tt>:message</tt> - A custom error message (default is: "is not a number").
      # * <tt>:on</tt> - Specifies when this validation is active (default is <tt>:save</tt>, other options <tt>:create</tt>, <tt>:update</tt>).
      # * <tt>:allow_nil</tt> - Skip validation if attribute is +nil+ (default is +false+). Notice that for fixnum and float columns empty strings are converted to +nil+.
      # * <tt>:allow_blank</tt> - Skip validation if attribute is blank.
      # * <tt>:greater_than</tt> - Specifies the value must be greater than the supplied attribute value.
      # * <tt>:greater_than_or_equal_to</tt> - Specifies the value must be greater than or equal the supplied attribute value.
      # * <tt>:equal_to</tt> - Specifies the value must be equal to the supplied attribute value.
      # * <tt>:less_than</tt> - Specifies the value must be less than the supplied attribute value.
      # * <tt>:less_than_or_equal_to</tt> - Specifies the value must be less than or equal the supplied attribute value.
      # * <tt>:if</tt> - Specifies a method, proc or string to call to determine if the validation should
      #   occur (e.g. <tt>:if => :allow_validation</tt>, or <tt>:if => Proc.new { |user| user.signup_step > 2 }</tt>).  The
      #   method, proc or string should return or evaluate to a true or false value.
      # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine if the validation should
      #   not occur (e.g. <tt>:unless => :skip_validation</tt>, or <tt>:unless => Proc.new { |user| user.signup_step <= 2 }</tt>).  The
      #   method, proc or string should return or evaluate to a true or false value.
      def validates_order_of(*attr_names)
        configuration = { :on => :save, :allow_nil => false }
        configuration.update(attr_names.extract_options!)

        order_options = ALL_ORDER_CHECKS.keys & configuration.keys

        order_options.each do |option|
          raise ArgumentError, ":#{option} must be a string" unless configuration[option].respond_to?(:to_s)
        end

        validates_each(attr_names, configuration) do |record, attr_name, lvalue|
          next if configuration[:allow_nil]   and lvalue.nil?
          next if configuration[:allow_blank] and lvalue.blank?

          order_options.each do |option|
            comparator  = ALL_ORDER_CHECKS[option]
            next unless lvalue.respond_to?(comparator)

            rattr   = configuration[option]
            rvalue  = record[rattr]
            next unless rvalue.respond_to?(comparator)

            unless lvalue.send(comparator, rvalue)
              record.errors.add attr_name,
                                option,
                                :default => configuration[:message],
                                :value => lvalue,
                                :count => record.class.human_attribute_name(rattr.to_s).downcase
            end
          end
        end
      end
    end
  end
end
