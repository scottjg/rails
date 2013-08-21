
module ActiveRecord
  module AttributeAssignment
    extend ActiveSupport::Concern
    include ActiveModel::AttributeAssignment

    private

    def attribute_assignment_error_class
      ActiveRecord::AttributeAssignmentError
    end

    def multiparameter_assignment_errors_class
      ActiveRecord::MultiparameterAssignmentErrors
    end

    def unknown_attribute_error_class
      ActiveRecord::UnknownAttributeError
    end

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
          Time.send(object.class.default_timezone, *set_values)
        end
        { 1 => 1970, 2 => 1, 3 => 1 }.each do |key,value|
          values[key] ||= value
        end
        super
      end

    end
  end
end
