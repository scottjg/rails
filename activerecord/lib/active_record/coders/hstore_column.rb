require 'yaml'

module ActiveRecord
  module Coders # :nodoc:
    class HstoreColumn # :nodoc:

      attr_accessor :object_class

      def initialize(object_class = Object)
        @object_class = object_class
      end

      def dump(obj)
        return if obj.nil?

        unless obj.is_a?(object_class)
          raise SerializationTypeMismatch,
            "Attribute was supposed to be a #{object_class}, but was a #{obj.class}. -- #{obj.inspect}"
        end
        ConnectionAdapters::PostgreSQLColumn.string_to_hstore obj
      end

      def load(data)
        ConnectionAdapters::PostgreSQLColumn.hstore_to_string data
      end
    end
  end
end
