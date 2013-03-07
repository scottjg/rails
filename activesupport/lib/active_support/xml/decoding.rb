require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/delegation'
require 'multi_xml'

module ActiveSupport
  # Look for and parse xml strings that look like ISO 8601 times.
  mattr_accessor :parse_xml_times

  module Xml
    class << self
      def decode(xml, options ={})
        data = MultiXml.parse(xml, options)
        if ActiveSupport.parse_xml_times
          convert_dates_from(data)
        else
          data
        end
      end

      def engine
        MultiXml.parser
      end
      alias :backend :engine

      def engine=(name)
        MultiXml.parser = name
      end
      alias :backend= :engine=

      def with_backend(name)
        old_backend, self.backend = backend, name
        yield
      ensure
        self.backend = old_backend
      end

      def parse_error
        MultiXml::ParseError
      end

      private

      def convert_dates_from(data)
        case data
        when nil
          nil
        when DATE_REGEX
          begin
            DateTime.parse(data)
          rescue ArgumentError
            data
          end
        when Array
          data.map! { |d| convert_dates_from(d) }
        when Hash
          data.each do |key, value|
            data[key] = convert_dates_from(value)
          end
        else
          data
        end
      end
    end
  end
end
