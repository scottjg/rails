require "multi_xml"

module ActiveSupport
  module Xml
    DEFAULT_ENCODINGS = {
      "binary" => "base64"
    } unless defined?(DEFAULT_ENCODINGS)

    FORMATTING = {
      "symbol"   => Proc.new { |symbol| symbol.to_s },
      "date"     => Proc.new { |date| date.to_s(:db) },
      "datetime" => Proc.new { |time| time.xmlschema },
      "binary"   => Proc.new { |binary| ActiveSupport::Base64.encode64(binary) },
      "yaml"     => Proc.new { |yaml| yaml.to_yaml }
    } unless defined?(FORMATTING)

    class << self
      def to_tag(key, value, options)
        type_name = options.delete(:type)
        merged_options = options.merge(:root => key, :skip_instruct => true)

        if value.is_a?(::Method) || value.is_a?(::Proc)
          if value.arity == 1
            value.call(merged_options)
          else
            value.call(merged_options, key.to_s.singularize)
          end
        elsif value.respond_to?(:to_xml)
          value.to_xml(merged_options)
        else
          type_name ||= MultiXml::TYPE_NAMES[value.class.name]
          type_name ||= value.class.name if value && !value.respond_to?(:to_str)
          type_name   = type_name.to_s   if type_name

          key = rename_key(key.to_s, options)

          attributes = options[:skip_types] || type_name.nil? ? { } : { :type => type_name }
          attributes[:nil] = true if value.nil?

          encoding = options[:encoding] || DEFAULT_ENCODINGS[type_name]
          attributes[:encoding] = encoding if encoding

          formatted_value = FORMATTING[type_name] && !value.nil? ?
            FORMATTING[type_name].call(value) : value

          options[:builder].tag!(key, formatted_value, attributes)
        end
      end

      def rename_key(key, options = {})
        camelize  = options[:camelize]
        dasherize = !options.has_key?(:dasherize) || options[:dasherize]
        if camelize
          key = true == camelize ? key.camelize : key.camelize(camelize)
        end
        key = _dasherize(key) if dasherize
        key
      end

      protected

      def _dasherize(key)
        # $2 must be a non-greedy regex for this to work
        left, middle, right = /\A(_*)(.*?)(_*)\Z/.match(key.strip)[1,3]
        "#{left}#{middle.tr('_ ', '--')}#{right}"
      end
    end
  end
end
