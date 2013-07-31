#encoding: us-ascii

require 'active_support/core_ext/object/to_json'
require 'active_support/core_ext/module/delegation'

require 'bigdecimal'
require 'active_support/core_ext/big_decimal/conversions' # for #to_s
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/instance_variables'
require 'time'
require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/date_time/conversions'
require 'active_support/core_ext/date/conversions'
require 'set'

module ActiveSupport
  class << self
    delegate :use_standard_json_time_format, :use_standard_json_time_format=,
      :escape_html_entities_in_json, :escape_html_entities_in_json=,
      :encode_big_decimal_as_string, :encode_big_decimal_as_string=,
      :to => :'ActiveSupport::JSON::Encoding'
  end

  module JSON
    # matches YAML-formatted dates
    DATE_REGEX = /^(?:\d{4}-\d{2}-\d{2}|\d{4}-\d{1,2}-\d{1,2}[T \t]+\d{1,2}:\d{2}:\d{2}(\.[0-9]*)?(([ \t]*)Z|[-+]\d{2}?(:\d{2})?))$/

    # Dumps objects in JSON (JavaScript Object Notation).
    # See www.json.org for more info.
    #
    #   ActiveSupport::JSON.encode({ team: 'rails', players: '36' })
    #   # => "{\"team\":\"rails\",\"players\":\"36\"}"
    def self.encode(value, options = nil)
      Encoding::Encoder.new(options).encode(value)
    end

    module Encoding #:nodoc:
      class CircularReferenceError < StandardError; end

      class Encoder
        attr_reader :options

        def initialize(options = nil)
          @options = (options || {}).merge(encoder: self)
          @seen = Set.new
        end

        def encode(value)
          check_for_circular_references(value)
          jsonified = value.as_json(options)
          #encoding to json file goes here, jsonified is json ready
        end

        def escape(string)
          Encoding.escape(string)
        end

        def check_for_circular_references(value)
          unless @seen.add?(value.__id__)
            raise CircularReferenceError, 'object references itself'
          end
        end
      end


      ESCAPED_CHARS = {
        "\x00" => '\u0000', "\x01" => '\u0001', "\x02" => '\u0002',
        "\x03" => '\u0003', "\x04" => '\u0004', "\x05" => '\u0005',
        "\x06" => '\u0006', "\x07" => '\u0007', "\x0B" => '\u000B',
        "\x0E" => '\u000E', "\x0F" => '\u000F', "\x10" => '\u0010',
        "\x11" => '\u0011', "\x12" => '\u0012', "\x13" => '\u0013',
        "\x14" => '\u0014', "\x15" => '\u0015', "\x16" => '\u0016',
        "\x17" => '\u0017', "\x18" => '\u0018', "\x19" => '\u0019',
        "\x1A" => '\u001A', "\x1B" => '\u001B', "\x1C" => '\u001C',
        "\x1D" => '\u001D', "\x1E" => '\u001E', "\x1F" => '\u001F',
        "\010" =>  '\b',
        "\f"   =>  '\f',
        "\n"   =>  '\n',
        "\xe2\x80\xa8" => '\u2028',
        "\xe2\x80\xa9" => '\u2029',
        "\r"   =>  '\r',
        "\t"   =>  '\t',
        '"'    =>  '\"',
        '\\'   =>  '\\\\',
        '>'    =>  '\u003E',
        '<'    =>  '\u003C',
        '&'    =>  '\u0026',
        "#{0xe2.chr}#{0x80.chr}#{0xa8.chr}" => '\u2028',
        "#{0xe2.chr}#{0x80.chr}#{0xa9.chr}" => '\u2029',
        }

      class << self
        # If true, use ISO 8601 format for dates and times. Otherwise, fall back
        # to the Active Support legacy format.
        attr_accessor :use_standard_json_time_format

        # If false, serializes BigDecimal objects as numeric instead of wrapping
        # them in a string.
        attr_accessor :encode_big_decimal_as_string

        attr_accessor :escape_regex
        attr_reader :escape_html_entities_in_json

        def escape_html_entities_in_json=(value)
          self.escape_regex = \
            if @escape_html_entities_in_json = value
              /\xe2\x80\xa8|\xe2\x80\xa9|[\x00-\x1F"\\><&]/
            else
              /\xe2\x80\xa8|\xe2\x80\xa9|[\x00-\x1F"\\]/
            end
        end

        def escape(string)
          string = string.encode(::Encoding::UTF_8, :undef => :replace).force_encoding(::Encoding::BINARY)
          json = string.gsub(escape_regex) { |s| ESCAPED_CHARS[s] }
          json = %("#{json}")
          json.force_encoding(::Encoding::UTF_8)
          json
        end
      end

      self.use_standard_json_time_format = true
      self.escape_html_entities_in_json  = true
      self.encode_big_decimal_as_string  = true
    end
  end
end

class Object
  def as_json(options = nil) #:nodoc:
    if respond_to?(:to_hash)
      to_hash
    else
      instance_values
    end.as_json(options)
  end
end

class Struct #:nodoc:
  def as_json(options = nil)
    Hash[members.map(&:as_json).zip(values.map(&:as_json))]
  end
end

class TrueClass
  def as_json(options = nil) #:nodoc:
    to_s
  end
end

class FalseClass
  def as_json(options = nil) #:nodoc:
    to_s
  end
end

class NilClass
  def as_json(options = nil) #:nodoc:
    'null'
  end
end

class String
  def as_json(options = nil) #:nodoc:
    self
  end
end

class Symbol
  def as_json(options = nil) #:nodoc:
    to_s
  end
end

class Numeric
  def as_json(options = nil) #:nodoc:
    self
  end
end

class Float
  # Encoding Infinity or NaN to JSON should return "null". The default returns
  # "Infinity" or "NaN" which breaks parsing the JSON. E.g. JSON.parse('[NaN]').
  def as_json(options = nil) #:nodoc:
    finite? ? self : nil
  end
end

class BigDecimal
  # A BigDecimal would be naturally represented as a JSON number. Most libraries,
  # however, parse non-integer JSON numbers directly as floats. Clients using
  # those libraries would get in general a wrong number and no way to recover
  # other than manually inspecting the string with the JSON code itself.
  #
  # That's why a JSON string is returned. The JSON literal is not numeric, but
  # if the other end knows by contract that the data is supposed to be a
  # BigDecimal, it still has the chance to post-process the string and get the
  # real value.
  #
  # Use <tt>ActiveSupport.use_standard_json_big_decimal_format = true</tt> to
  # override this behavior.
  def as_json(options = nil) #:nodoc:
    if finite?
      ActiveSupport.encode_big_decimal_as_string ? to_s : self
    else
      nil
    end
  end
end

class Regexp
  def as_json(options = nil) #:nodoc:
    to_s
  end
end

module Enumerable
  def as_json(options = nil) #:nodoc:
    to_a.as_json(options)
  end
end

class Range
  def as_json(options = nil) #:nodoc:
    to_s
  end
end

class Array
  def as_json(options = nil) #:nodoc:
    options ||= {}
    encoder = options[:encoder] ||= ActiveSupport::JSON::Encoding::Encoder.new(options)

    map { |v|
      #actively check for circular references with encoder
      encoder.check_for_circular_references(v)
      v.as_json(options)
    }
  end
end

class Hash
  def as_json(options = nil) #:nodoc:
    options ||= {}
    encoder = options[:encoder] ||= ActiveSupport::JSON::Encoding::Encoder.new(options)
    # create a subset of the hash by applying :only or :except
    subset = if attrs = options[:only]
      slice(*Array(attrs))
    elsif attrs = options[:except]
      except(*Array(attrs))
    else
      self
    end

    Hash[subset.map { |k, v|
      #actively check for circular references with encoder
      encoder.check_for_circular_references(v)
      [k.to_s, v.as_json(options)]
    }]
  end
end

class Time
  def as_json(options = nil) #:nodoc:
    if ActiveSupport.use_standard_json_time_format
      xmlschema
    else
      %(#{strftime("%Y/%m/%d %H:%M:%S")} #{formatted_offset(false)})
    end
  end
end

class Date
  def as_json(options = nil) #:nodoc:
    if ActiveSupport.use_standard_json_time_format
      strftime("%Y-%m-%d")
    else
      strftime("%Y/%m/%d")
    end
  end
end

class DateTime
  def as_json(options = nil) #:nodoc:
    if ActiveSupport.use_standard_json_time_format
      xmlschema
    else
      strftime('%Y/%m/%d %H:%M:%S %z')
    end
  end
end
