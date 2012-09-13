
module ActiveRecord
  ActiveSupport.on_load(:active_record_config) do
    mattr_accessor :whitelist_attributes,      instance_accessor: false
    mattr_accessor :mass_assignment_sanitizer, instance_accessor: false
  end

  module AttributeAssignment
    extend ActiveSupport::Concern
    include ActiveModel::MassAssignmentSecurity

    included do
      initialize_mass_assignment_sanitizer
    end

    module ClassMethods
      def inherited(child) # :nodoc:
        child.send :initialize_mass_assignment_sanitizer if self == Base
        super
      end

      private

      # The primary key and inheritance column can never be set by mass-assignment for security reasons.
      def attributes_protected_by_default
        default = [ primary_key, inheritance_column ]
        default << 'id' unless primary_key.eql? 'id'
        default
      end

      def initialize_mass_assignment_sanitizer
        attr_accessible(nil) if Model.whitelist_attributes
        self.mass_assignment_sanitizer = Model.mass_assignment_sanitizer if Model.mass_assignment_sanitizer
      end
    end

    # Allows you to set all the attributes at once by passing in a hash with keys
    # matching the attribute names (which again matches the column names).
    #
    # If any attributes are protected by either +attr_protected+ or
    # +attr_accessible+ then only settable attributes will be assigned.
    #
    #   class User < ActiveRecord::Base
    #     attr_protected :is_admin
    #   end
    #
    #   user = User.new
    #   user.attributes = { :username => 'Phusion', :is_admin => true }
    #   user.username   # => "Phusion"
    #   user.is_admin?  # => false
    def attributes=(new_attributes)
      return unless new_attributes.is_a?(Hash)

      assign_attributes(new_attributes)
    end

    # Allows you to set all the attributes for a particular mass-assignment
    # security role by passing in a hash of attributes with keys matching
    # the attribute names (which again matches the column names) and the role
    # name using the :as option.
    #
    # To bypass mass-assignment security you can use the :without_protection => true
    # option.
    #
    #   class User < ActiveRecord::Base
    #     attr_accessible :name
    #     attr_accessible :name, :is_admin, :as => :admin
    #   end
    #
    #   user = User.new
    #   user.assign_attributes({ :name => 'Josh', :is_admin => true })
    #   user.name       # => "Josh"
    #   user.is_admin?  # => false
    #
    #   user = User.new
    #   user.assign_attributes({ :name => 'Josh', :is_admin => true }, :as => :admin)
    #   user.name       # => "Josh"
    #   user.is_admin?  # => true
    #
    #   user = User.new
    #   user.assign_attributes({ :name => 'Josh', :is_admin => true }, :without_protection => true)
    #   user.name       # => "Josh"
    #   user.is_admin?  # => true
    def assign_attributes(new_attributes, options = {})
      return if new_attributes.blank?

      attributes                  = MultiparameterAttributeParser.process_params(new_attributes.stringify_keys)
      multi_parameter_attributes  = []
      nested_parameter_attributes = []
      previous_options            = @mass_assignment_options
      @mass_assignment_options    = options

      unless options[:without_protection]
        attributes = sanitize_for_mass_assignment(attributes, mass_assignment_role)
      end

      errors = []
      attributes.each do |k, v|
        begin
          if v.is_a?(Array)
            _assign_multi_parameter_attribute(k, v)
          elsif v.is_a?(Hash)
            nested_parameter_attributes << [ k, v ]
          else
            _assign_attribute(k, v)
          end
        rescue AttributeAssignmentError => ex
          errors << ex
        end
      end
      unless errors.empty?
        error_descriptions = errors.map { |ex| ex.message }.join(",")
        raise MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes [#{error_descriptions}]"
      end

      assign_nested_parameter_attributes(nested_parameter_attributes) unless nested_parameter_attributes.empty?
    ensure
      @mass_assignment_options = previous_options
    end

    protected

    def mass_assignment_options
      @mass_assignment_options ||= {}
    end

    def mass_assignment_role
      mass_assignment_options[:as] || :default
    end

    private

    def _assign_attribute(k, v)
      public_send("#{k}=", v)
    rescue NoMethodError
      if respond_to?("#{k}=")
        raise
      else
        raise UnknownAttributeError, "unknown attribute: #{k}"
      end
    end

    def _assign_multi_parameter_attribute(k, v)
      begin
        send("#{k}=", MultiparameterAttribute.new(self, k, v).read_value)
      rescue => ex
        raise AttributeAssignmentError.new("error on assignment #{v.inspect} to #{k} (#{ex.message})", ex, k)
      end
    end

    # Assign any deferred nested attributes after the base attributes have been set.
    def assign_nested_parameter_attributes(pairs)
      pairs.each { |k, v| _assign_attribute(k, v) }
    end

    def execute_callstack_for_multiparameter_attributes(callstack)
      errors = []
      callstack.each do |name, values_with_empty_parameters|
        begin
          send("#{name}=", MultiparameterAttribute.new(self, name, values_with_empty_parameters).read_value)
        rescue => ex
          errors << AttributeAssignmentError.new("error on assignment #{values_with_empty_parameters.values.inspect} to #{name} (#{ex.message})", ex, name)
        end
      end
      unless errors.empty?
        error_descriptions = errors.map { |ex| ex.message }.join(",")
        raise MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes [#{error_descriptions}]"
      end
    end

    class MultiparameterAttributeParser
      class << self
        def process_params(attributes_standing_in_for_params)
          processed_params = {}
          multi_parameter_params = []
          attributes_standing_in_for_params.each do |k, v|
            if k.include?("(")
              multi_parameter_params << [ k, v ]
            else
              processed_params[k] = v
            end
          end
          processed_params.merge(extract_callstack_for_multiparameter_attributes(multi_parameter_params))
        end

        def extract_callstack_for_multiparameter_attributes(pairs)
          attributes = { }

          pairs.each do |(multiparameter_name, value)|
            attribute_name = multiparameter_name.split("(").first
            attributes[attribute_name] ||= {}

            parameter_value = value.empty? ? nil : type_cast_attribute_value(multiparameter_name, value)
            attributes[attribute_name][find_parameter_position(multiparameter_name)] ||= parameter_value
          end
          puts "MultiparameterAttributeParser! #{attributes.inspect}"
          puts "YO: #{attributes.collect { |k, values_hash| [k, values_hash_to_array(values_hash)] }.inspect}"
          puts "HO: #{Hash[attributes.collect { |k, values_hash| [k, values_hash_to_array(values_hash)] }].inspect}"

          Hash[attributes.collect { |k, values_hash| [k, values_hash_to_array(values_hash)] }]
        end

        def type_cast_attribute_value(multiparameter_name, value)
          multiparameter_name =~ /\([0-9]*([if])\)/ ? value.send("to_" + $1) : value
        end

        def find_parameter_position(multiparameter_name)
          multiparameter_name.scan(/\(([0-9]*).*\)/).first.first.to_i
        end

        def values_hash_to_array(values_hash)
          values_array = []
          max_key = extract_max_param(values_hash)
          (1..max_key).each { |k| values_array << (values_hash[k] || nil) }
          values_array
        end

        def extract_max_param(values, upper_cap = 100)
          [values.keys.max, upper_cap].min
        end
      end
    end

    class MultiparameterAttribute #:nodoc:
      attr_reader :object, :name, :values, :column

      def initialize(object, name, values)
        @object = object
        @name   = name
        @values = values
      end

      def read_value
        return if values.compact.empty?

        @column = object.class.reflect_on_aggregation(name.to_sym) || object.column_for_attribute(name)
        klass   = column.klass

        if klass == Time
          read_time
        elsif klass == Date
          read_date
        else
          read_other(klass)
        end
      end

      private

      def instantiate_time_object(values)
        if object.class.send(:create_time_zone_conversion_attribute?, name, column)
          Time.zone.local(*values)
        else
          Time.time_with_datetime_fallback(object.class.default_timezone, *values)
        end
      end

      def read_time
        # If column is a :time (and not :date or :timestamp) there is no need to validate if
        # there are year/month/day fields
        if column.type == :time
          # if the column is a time set the values to their defaults as January 1, 1970, but only if they're nil
          [1970, 1, 1].each_with_index do |value, i|
            values[i] ||= value
          end
        else
          # else column is a timestamp, so if Date bits were not provided, error
          validate_missing_parameters!([0,1,2])

          # If Date bits were provided but blank, then return nil
          return if blank_date_parameter?
        end

        max_position = extract_max_param(6)
        set_values   = values.values_at(*(1..max_position))
        # If Time bits are not there, then default to 0
        (3..5).each { |i| set_values[i] = set_values[i].presence || 0 }
        instantiate_time_object(set_values)
      end

      def read_date
        return if blank_date_parameter?
        begin
          Date.new(*values)
        rescue ArgumentError # if Date.new raises an exception on an invalid date
          instantiate_time_object(values).to_date # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
        end
      end

      def read_other(klass)
        validate_missing_parameters!(all_indexes(values))
        klass.new(*values)
      end

      def all_indexes(values)
        (0..(values.length - 1)).to_a
      end

      # Checks whether some blank date parameter exists. Note that this is different
      # than the validate_missing_parameters! method, since it just checks for blank
      # positions instead of missing ones, and does not raise in case one blank position
      # exists. The caller is responsible to handle the case of this returning true.
      def blank_date_parameter?
        (0..2).any? { |index| values[index].blank? }
      end

      # If some position is not provided, it errors out a missing parameter exception.
      def validate_missing_parameters!(indexes)
        if missing_parameter = indexes.detect { |position| !values.fetch(position, false) }
          raise ArgumentError.new("Missing Parameter - #{name}(#{missing_parameter})")
        end
      end

      def extract_max_param(upper_cap = 100)
        [values.keys.max, upper_cap].min
      end
    end
  end
end
