
module ActiveRecord
  module AttributeAssignment
    extend ActiveSupport::Concern
    include ActiveModel::AttributeAssignment

    class MultiparameterAttribute < ActiveModel::AttributeAssignment::MultiparameterAttribute #:nodoc:
      attr_reader :column

      private

      def class_for_attribute
        @column = object.class.reflect_on_aggregation(name.to_sym) ||
                  object.column_for_attribute(name)

        column.klass
      end

      def instantiate_time_object(set_values)
        if object.class.send(:create_time_zone_conversion_attribute?, name, column)
          super
        else
          Time.time_with_datetime_fallback(object.class.default_timezone, *set_values)
        end
      end

      def read_time
        # If column is a :time (and not :date or :timestamp) there is no need to validate if
        # there are year/month/day fields
        if column.type == :time
          # if the column is a time set the values to their defaults as January 1, 1970, but only if they're nil
          { 1 => 1970, 2 => 1, 3 => 1 }.each do |key,value|
            values[key] ||= value
          end
        else
          # else column is a timestamp, so if Date bits were not provided, error
          validate_missing_parameters!([1,2,3])

          # If Date bits were provided but blank, then return nil
          return if blank_date_parameter?
        end

        super
      end
    end
  end
end
