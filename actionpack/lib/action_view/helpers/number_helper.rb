require 'active_support/core_ext/big_decimal/conversions'
require 'active_support/core_ext/float/rounding'
require 'active_support/core_ext/object/blank'

module ActionView
  module Helpers #:nodoc:

    # Provides methods for converting numbers into formatted strings.
    # Methods are provided for phone numbers, currency, percentage,
    # precision, positional notation, file size and pretty printing.
    #
    # Most methods expect a +number+ argument, and will return it
    # unchanged if can't be converted into a valid number.
    module NumberHelper

      # Raised when argument +number+ param given to the helpers is invalid and
      # the option :raise is set to  +true+.
      class InvalidNumberError < StandardError
        attr_accessor :number
        def initialize(number)
          @number = number
        end
      end

      # Formats a +number+ into a US phone number (e.g., (555) 123-9876). You can customize the format
      # in the +options+ hash.
      #
      # ==== Options
      # * <tt>:area_code</tt>  - Adds parentheses around the area code.
      # * <tt>:delimiter</tt>  - Specifies the delimiter to use (defaults to "-").
      # * <tt>:extension</tt>  - Specifies an extension to add to the end of the
      #   generated number.
      # * <tt>:country_code</tt>  - Sets the country code for the phone number.
      #
      # ==== Examples
      #  number_to_phone(5551234)                                           # => 555-1234
      #  number_to_phone(1235551234)                                        # => 123-555-1234
      #  number_to_phone(1235551234, :area_code => true)                    # => (123) 555-1234
      #  number_to_phone(1235551234, :delimiter => " ")                     # => 123 555 1234
      #  number_to_phone(1235551234, :area_code => true, :extension => 555) # => (123) 555-1234 x 555
      #  number_to_phone(1235551234, :country_code => 1)                    # => +1-123-555-1234
      #
      #  number_to_phone(1235551234, :country_code => 1, :extension => 1343, :delimiter => ".")
      #  => +1.123.555.1234 x 1343
      def number_to_phone(number, options = {})
        return nil if number.nil?

        begin
          Float(number)
          is_number_html_safe = true
        rescue ArgumentError, TypeError
          if options[:raise]
            raise InvalidNumberError, number
          else
            is_number_html_safe = number.to_s.html_safe?
          end
        end

        number       = number.to_s.strip
        options      = options.symbolize_keys
        area_code    = options[:area_code] || nil
        delimiter    = options[:delimiter] || "-"
        extension    = options[:extension].to_s.strip || nil
        country_code = options[:country_code] || nil

        str = ""
        str << "+#{country_code}#{delimiter}" unless country_code.blank?
        str << if area_code
          number.gsub!(/([0-9]{1,3})([0-9]{3})([0-9]{4}$)/,"(\\1) \\2#{delimiter}\\3")
        else
          number.gsub!(/([0-9]{0,3})([0-9]{3})([0-9]{4})$/,"\\1#{delimiter}\\2#{delimiter}\\3")
          number.starts_with?('-') ? number.slice!(1..-1) : number
        end
        str << " x #{extension}" unless extension.blank?
        is_number_html_safe ? str.html_safe : str
      end

      # Formats a +number+ into a currency string (e.g., $13.65). You can customize the format
      # in the +options+ hash.
      #
      # ==== Options
      # * <tt>:precision</tt>  -  Sets the level of precision (defaults to 2).
      # * <tt>:unit</tt>       - Sets the denomination of the currency (defaults to "$").
      # * <tt>:separator</tt>  - Sets the separator between the units (defaults to ".").
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to ",").
      # * <tt>:format</tt>     - Sets the format of the output string (defaults to "%u%n"). The field types are:
      #
      #     %u  The currency unit
      #     %n  The number
      #
      # ==== Examples
      #  number_to_currency(1234567890.50)                    # => $1,234,567,890.50
      #  number_to_currency(1234567890.506)                   # => $1,234,567,890.51
      #  number_to_currency(1234567890.506, :precision => 3)  # => $1,234,567,890.506
      #
      #  number_to_currency(1234567890.50, :unit => "&pound;", :separator => ",", :delimiter => "")
      #  # => &pound;1234567890,50
      #  number_to_currency(1234567890.50, :unit => "&pound;", :separator => ",", :delimiter => "", :format => "%n %u")
      #  # => 1234567890,50 &pound;
      def number_to_currency(number, options = {})
        return nil if number.nil?

        options.symbolize_keys!

        defaults  = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
        currency  = I18n.translate(:'number.currency.format', :locale => options[:locale], :default => {})
        defaults  = defaults.merge(currency)

        options = options.reverse_merge(defaults)

        unit      = options.delete(:unit)
        format    = options.delete(:format)

        begin
          value = number_with_precision(number, options.merge(:raise => true))
          format.gsub(/%n/, value).gsub(/%u/, unit).html_safe
        rescue InvalidNumberError => e
          if options[:raise]
            raise
          else
            formatted_number = format.gsub(/%n/, e.number).gsub(/%u/, unit)
            e.number.to_s.html_safe? ? formatted_number.html_safe : formatted_number
          end
        end

      end

      # Formats a +number+ as a percentage string (e.g., 65%). You can customize the
      # format in the +options+ hash.
      #
      # ==== Options
      # * <tt>:precision</tt>  - Sets the precision of the number (defaults to 3).
      # * <tt>:significant</tt>  - If +true+, precision will be the # of significant_digits. If +false+, the # of fractional digits (defaults to +false+)
      # * <tt>:separator</tt>  - Sets the separator between the fractional and integer digits (defaults to ".").
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to "").
      # * <tt>:strip_insignificant_zeros</tt>  - If +true+ removes insignificant zeros after the decimal separator (defaults to +false+)
      #
      # ==== Examples
      #  number_to_percentage(100)                                        # => 100.000%
      #  number_to_percentage(100, :precision => 0)                       # => 100%
      #  number_to_percentage(1000, :delimiter => '.', :separator => ',') # => 1.000,000%
      #  number_to_percentage(302.24398923423, :precision => 5)           # => 302.24399%
      def number_to_percentage(number, options = {})
        return nil if number.nil?

        options.symbolize_keys!

        defaults   = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
        percentage = I18n.translate(:'number.percentage.format', :locale => options[:locale], :default => {})
        defaults  = defaults.merge(percentage)

        options = options.reverse_merge(defaults)

        begin
          "#{number_with_precision(number, options.merge(:raise => true))}%".html_safe
        rescue InvalidNumberError => e
          if options[:raise]
            raise
          else
            e.number.to_s.html_safe? ? "#{e.number}%".html_safe : "#{e.number}%"
          end
        end
      end

      # Formats a +number+ with grouped thousands using +delimiter+ (e.g., 12,324). You can
      # customize the format in the +options+ hash.
      #
      # ==== Options
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to ",").
      # * <tt>:separator</tt>  - Sets the separator between the fractional and integer digits (defaults to ".").
      #
      # ==== Examples
      #  number_with_delimiter(12345678)                        # => 12,345,678
      #  number_with_delimiter(12345678.05)                     # => 12,345,678.05
      #  number_with_delimiter(12345678, :delimiter => ".")     # => 12.345.678
      #  number_with_delimiter(12345678, :separator => ",")     # => 12,345,678
      #  number_with_delimiter(98765432.98, :delimiter => " ", :separator => ",")
      #  # => 98 765 432,98
      #
      # You can still use <tt>number_with_delimiter</tt> with the old API that accepts the
      # +delimiter+ as its optional second and the +separator+ as its
      # optional third parameter:
      #  number_with_delimiter(12345678, " ")                     # => 12 345 678
      #  number_with_delimiter(12345678.05, ".", ",")             # => 12.345.678,05
      def number_with_delimiter(number, *args)
        options = args.extract_options!
        options.symbolize_keys!

        begin
          Float(number)
        rescue ArgumentError, TypeError
          if options[:raise]
            raise InvalidNumberError, number
          else
            return number
          end
        end

        defaults = I18n.translate(:'number.format', :locale => options[:locale], :default => {})

        unless args.empty?
          ActiveSupport::Deprecation.warn('number_with_delimiter takes an option hash ' +
            'instead of separate delimiter and precision arguments.', caller)
          options[:delimiter] ||= args[0] if args[0]
          options[:separator] ||= args[1] if args[1]
        end

        options = options.reverse_merge(defaults)

        parts = number.to_s.split('.')
        parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
        parts.join(options[:separator]).html_safe

      end

      # Formats a +number+ with the specified level of <tt>:precision</tt> (e.g., 112.32 has a precision
      # of 2 if +:significant+ is +false+, and 5 if +:significant+ is +true+).
      # You can customize the format in the +options+ hash.
      #
      # ==== Options
      # * <tt>:precision</tt>  - Sets the precision of the number (defaults to 3).
      # * <tt>:significant</tt>  - If +true+, precision will be the # of significant_digits. If +false+, the # of fractional digits (defaults to +false+)
      # * <tt>:separator</tt>  - Sets the separator between the fractional and integer digits (defaults to ".").
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to "").
      # * <tt>:strip_insignificant_zeros</tt>  - If +true+ removes insignificant zeros after the decimal separator (defaults to +false+)
      #
      # ==== Examples
      #  number_with_precision(111.2345)                                            # => 111.235
      #  number_with_precision(111.2345, :precision => 2)                           # => 111.23
      #  number_with_precision(13, :precision => 5)                                 # => 13.00000
      #  number_with_precision(389.32314, :precision => 0)                          # => 389
      #  number_with_precision(111.2345, :significant => true)                      # => 111
      #  number_with_precision(111.2345, :precision => 1, :significant => true)     # => 100
      #  number_with_precision(13, :precision => 5, :significant => true)           # => 13.000
      #  number_with_precision(13, :precision => 5, :significant => true, strip_insignificant_zeros => true)
      #  # => 13
      #  number_with_precision(389.32314, :precision => 4, :significant => true)    # => 389.3
      #  number_with_precision(1111.2345, :precision => 2, :separator => ',', :delimiter => '.')
      #  # => 1.111,23
      #
      # You can still use <tt>number_with_precision</tt> with the old API that accepts the
      # +precision+ as its optional second parameter:
      #   number_with_precision(111.2345, 2)   # => 111.23
      def number_with_precision(number, *args)

        options = args.extract_options!
        options.symbolize_keys!

        number = begin
          Float(number)
        rescue ArgumentError, TypeError
          if options[:raise]
            raise InvalidNumberError, number
          else
            return number
          end
        end

        defaults           = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
        precision_defaults = I18n.translate(:'number.precision.format', :locale => options[:locale], :default => {})
        defaults           = defaults.merge(precision_defaults)

        #Backwards compatibility
        unless args.empty?
          ActiveSupport::Deprecation.warn('number_with_precision takes an option hash ' +
            'instead of a separate precision argument.', caller)
          options[:precision] ||= args[0] if args[0]
        end

        options = options.reverse_merge(defaults)  # Allow the user to unset default values: Eg.: :significant => false
        precision = options.delete :precision
        significant = options.delete :significant
        strip_insignificant_zeros = options.delete :strip_insignificant_zeros

        if significant and precision > 0
          if number == 0
            digits, rounded_number = 1, 0
          else
            digits = (Math.log10(number) + 1).floor
            rounded_number = BigDecimal.new((number / 10 ** (digits - precision)).to_s).round.to_f * 10 ** (digits - precision)
          end
          precision = precision - digits
          precision = precision > 0 ? precision : 0  #don't let it be negative
        else
          rounded_number = BigDecimal.new((number * (10 ** precision)).to_s).round.to_f / 10 ** precision
        end
        formatted_number = number_with_delimiter("%01.#{precision}f" % rounded_number, options)
        if strip_insignificant_zeros
          escaped_separator = Regexp.escape(options[:separator])
          formatted_number.sub(/(#{escaped_separator})(\d*[1-9])?0+\z/, '\1\2').sub(/#{escaped_separator}\z/, '').html_safe
        else
          formatted_number
        end

      end

      STORAGE_UNITS = [:byte, :kb, :mb, :gb, :tb].freeze

      # Formats the bytes in +number+ into a more understandable representation
      # (e.g., giving it 1500 yields 1.5 KB). This method is useful for
      # reporting file sizes to users. You can customize the
      # format in the +options+ hash.
      #
      # See <tt>number_to_human</tt> if you want to pretty-print a generic number.
      #
      # ==== Options
      # * <tt>:precision</tt>  - Sets the precision of the number (defaults to 3).
      # * <tt>:significant</tt>  - If +true+, precision will be the # of significant_digits. If +false+, the # of fractional digits (defaults to +true+)
      # * <tt>:separator</tt>  - Sets the separator between the fractional and integer digits (defaults to ".").
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to "").
      # * <tt>:strip_insignificant_zeros</tt>  - If +true+ removes insignificant zeros after the decimal separator (defaults to +true+)
      # ==== Examples
      #  number_to_human_size(123)                                          # => 123 Bytes
      #  number_to_human_size(1234)                                         # => 1.21 KB
      #  number_to_human_size(12345)                                        # => 12.1 KB
      #  number_to_human_size(1234567)                                      # => 1.18 MB
      #  number_to_human_size(1234567890)                                   # => 1.15 GB
      #  number_to_human_size(1234567890123)                                # => 1.12 TB
      #  number_to_human_size(1234567, :precision => 2)                     # => 1.2 MB
      #  number_to_human_size(483989, :precision => 2)                      # => 470 KB
      #  number_to_human_size(1234567, :precision => 2, :separator => ',')  # => 1,2 MB
      #
      # Unsignificant zeros after the fractional separator are stripped out by default (set
      # <tt>:strip_insignificant_zeros</tt> to +false+ to change that):
      #  number_to_human_size(1234567890123, :precision => 5)        # => "1.1229 TB"
      #  number_to_human_size(524288000, :precision=>5)              # => "500 MB"
      #
      # You can still use <tt>number_to_human_size</tt> with the old API that accepts the
      # +precision+ as its optional second parameter:
      #  number_to_human_size(1234567, 1)    # => 1 MB
      #  number_to_human_size(483989, 2)     # => 470 KB
      def number_to_human_size(number, *args)
        options = args.extract_options!
        options.symbolize_keys!

        number = begin
          Float(number)
        rescue ArgumentError, TypeError
          if options[:raise]
            raise InvalidNumberError, number
          else
            return number
          end
        end

        defaults = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
        human    = I18n.translate(:'number.human.format', :locale => options[:locale], :default => {})
        defaults = defaults.merge(human)

        unless args.empty?
          ActiveSupport::Deprecation.warn('number_to_human_size takes an option hash ' +
            'instead of a separate precision argument.', caller)
          options[:precision] ||= args[0] if args[0]
        end

        options = options.reverse_merge(defaults)
        #for backwards compatibility with those that didn't add strip_insignificant_zeros to their locale files
        options[:strip_insignificant_zeros] = true if not options.key?(:strip_insignificant_zeros)

        storage_units_format = I18n.translate(:'number.human.storage_units.format', :locale => options[:locale], :raise => true)

        if number.to_i < 1024
          unit = I18n.translate(:'number.human.storage_units.units.byte', :locale => options[:locale], :count => number.to_i, :raise => true)
          storage_units_format.gsub(/%n/, number.to_i.to_s).gsub(/%u/, unit).html_safe
        else
          max_exp  = STORAGE_UNITS.size - 1
          exponent = (Math.log(number) / Math.log(1024)).to_i # Convert to base 1024
          exponent = max_exp if exponent > max_exp # we need this to avoid overflow for the highest unit
          number  /= 1024 ** exponent

          unit_key = STORAGE_UNITS[exponent]
          unit = I18n.translate(:"number.human.storage_units.units.#{unit_key}", :locale => options[:locale], :count => number, :raise => true)

          formatted_number = number_with_precision(number, options)
          storage_units_format.gsub(/%n/, formatted_number).gsub(/%u/, unit).html_safe
        end
      end

      DECIMAL_UNITS = {0 => :unit, 1 => :ten, 2 => :hundred, 3 => :thousand, 6 => :million, 9 => :billion, 12 => :trillion, 15 => :quadrillion,
        -1 => :deci, -2 => :centi, -3 => :mili, -6 => :micro, -9 => :nano, -12 => :pico, -15 => :femto}.freeze

      # Pretty prints (formats and approximates) a number in a way it is more readable by humans
      # (eg.: 1200000000 becomes "1.2 Billion"). This is useful for numbers that
      # can get very large (and too hard to read).
      #
      # See <tt>number_to_human_size</tt> if you want to print a file size.
      #
      # You can also define you own unit-quantifier names if you want to use other decimal units
      # (eg.: 1500 becomes "1.5 kilometers", 0.150 becomes "150 mililiters", etc). You may define
      # a wide range of unit quantifiers, even fractional ones (centi, deci, mili, etc).
      #
      # ==== Options
      # * <tt>:precision</tt>  - Sets the precision of the number (defaults to 3).
      # * <tt>:significant</tt>  - If +true+, precision will be the # of significant_digits. If +false+, the # of fractional digits (defaults to +true+)
      # * <tt>:separator</tt>  - Sets the separator between the fractional and integer digits (defaults to ".").
      # * <tt>:delimiter</tt>  - Sets the thousands delimiter (defaults to "").
      # * <tt>:strip_insignificant_zeros</tt>  - If +true+ removes insignificant zeros after the decimal separator (defaults to +true+)
      # * <tt>:units</tt> - A Hash of unit quantifier names. Or a string containing an i18n scope where to find this hash. It might have the following keys:
      #   * *integers*: <tt>:unit</tt>, <tt>:ten</tt>, <tt>:hundred</tt>, <tt>:thousand</tt>,  <tt>:million</tt>,  <tt>:billion</tt>, <tt>:trillion</tt>, <tt>:quadrillion</tt>
      #   * *fractionals*: <tt>:deci</tt>, <tt>:centi</tt>, <tt>:mili</tt>, <tt>:micro</tt>, <tt>:nano</tt>, <tt>:pico</tt>, <tt>:femto</tt>
      # * <tt>:format</tt> - Sets the format of the output string (defaults to "%n %u"). The field types are:
      #
      #     %u  The quantifier (ex.: 'thousand')
      #     %n  The number
      #
      # ==== Examples
      #  number_to_human(123)                                          # => "123"
      #  number_to_human(1234)                                         # => "1.23 Thousand"
      #  number_to_human(12345)                                        # => "12.3 Thousand"
      #  number_to_human(1234567)                                      # => "1.23 Million"
      #  number_to_human(1234567890)                                   # => "1.23 Billion"
      #  number_to_human(1234567890123)                                # => "1.23 Trillion"
      #  number_to_human(1234567890123456)                             # => "1.23 Quadrillion"
      #  number_to_human(1234567890123456789)                          # => "1230 Quadrillion"
      #  number_to_human(489939, :precision => 2)                      # => "490 Thousand"
      #  number_to_human(489939, :precision => 4)                      # => "489.9 Thousand"
      #  number_to_human(1234567, :precision => 4,
      #                           :significant => false)               # => "1.2346 Million"
      #  number_to_human(1234567, :precision => 1,
      #                           :separator => ',',
      #                           :significant => false)               # => "1,2 Million"
      #
      # Unsignificant zeros after the decimal separator are stripped out by default (set
      # <tt>:strip_insignificant_zeros</tt> to +false+ to change that):
      #  number_to_human(12345012345, :significant_digits => 6)       # => "12.345 Billion"
      #  number_to_human(500000000, :precision=>5)                    # => "500 Million"
      #
      # ==== Custom Unit Quantifiers
      #
      # You can also use your own custom unit quantifiers:
      #  number_to_human(500000, :units => {:unit => "ml", :thousand => "lt"})  # => "500 lt"
      #
      # If in your I18n locale you have:
      #   distance:
      #     centi:
      #       one: "centimeter"
      #       other: "centimeters"
      #     unit:
      #       one: "meter"
      #       other: "meters"
      #     thousand:
      #       one: "kilometer"
      #       other: "kilometers"
      #     billion: "gazilion-distance"
      #
      # Then you could do:
      #
      #  number_to_human(543934, :units => :distance)                              # => "544 kilometers"
      #  number_to_human(54393498, :units => :distance)                            # => "54400 kilometers"
      #  number_to_human(54393498000, :units => :distance)                         # => "54.4 gazilion-distance"
      #  number_to_human(343, :units => :distance, :precision => 1)                # => "300 meters"
      #  number_to_human(1, :units => :distance)                                   # => "1 meter"
      #  number_to_human(0.34, :units => :distance)                                # => "34 centimeters"
      #
      def number_to_human(number, options = {})
        options.symbolize_keys!

        number = begin
          Float(number)
        rescue ArgumentError, TypeError
          if options[:raise]
            raise InvalidNumberError, number
          else
            return number
          end
        end

        defaults = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
        human    = I18n.translate(:'number.human.format', :locale => options[:locale], :default => {})
        defaults = defaults.merge(human)

        options = options.reverse_merge(defaults)
        #for backwards compatibility with those that didn't add strip_insignificant_zeros to their locale files
        options[:strip_insignificant_zeros] = true if not options.key?(:strip_insignificant_zeros)

        units = options.delete :units
        unit_exponents = case units
        when Hash
          units
        when String, Symbol
          I18n.translate(:"#{units}", :locale => options[:locale], :raise => true)
        when nil
          I18n.translate(:"number.human.decimal_units.units", :locale => options[:locale], :raise => true)
        else
          raise ArgumentError, ":units must be a Hash or String translation scope."
        end.keys.map{|e_name| DECIMAL_UNITS.invert[e_name] }.sort_by{|e| -e}

        number_exponent = Math.log10(number).floor
        display_exponent = unit_exponents.find{|e| number_exponent >= e }
        number  /= 10 ** display_exponent

        unit = case units
        when Hash
          units[DECIMAL_UNITS[display_exponent]]
        when String, Symbol
          I18n.translate(:"#{units}.#{DECIMAL_UNITS[display_exponent]}", :locale => options[:locale], :count => number.to_i)
        else
          I18n.translate(:"number.human.decimal_units.units.#{DECIMAL_UNITS[display_exponent]}", :locale => options[:locale], :count => number.to_i)
        end

        decimal_format = options[:format] || I18n.translate(:'number.human.decimal_units.format', :locale => options[:locale], :default => "%n %u")
        formatted_number = number_with_precision(number, options)
        decimal_format.gsub(/%n/, formatted_number).gsub(/%u/, unit).strip.html_safe
      end

    end
  end
end
