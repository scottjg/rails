module ActiveModel
  module Validatable
    module Validations
      class ValidatesLengthOf < Base
        options :min, :max, :in, :within, :is, :unit=>"character",
                :message => "{attribute_name} '{value}' must be between {min} and {max} {units} long.",
                :too_long => "{attribute_name} '{value}' must be shorter then {max} {units}.",
                :too_short => "{attribute_name} '{value}' must be longer then {min} {units}.",
                :wrong_length => "{attribute_name} '{value}' must be exactly {is} {units} long."
                
        validate_option :in=>:include?
        
        def units
          if (max && max > 1) || (min && min > 1) || (is > 1)
            unit.pluralize
          else
            unit
          end
        end
        
        def range
          if options[:min] && options[:max]
            (options[:min]..options[:max])
          else
            options[:in] || options[:within]
          end
        end
        
        def min
          options[:min] || (range && range.first)
        end
        def max
          options[:max] || (range && range.last)
        end
        
        def validate_options
          case (options.keys & [:min, :max, :in, :within, :is]).collect(&:to_s).sort
          when %w(max min),%w(min), %w(max),%w(in),%w(within),%w(is)
            super
          else
           raise MissingRequiredOption, "#{self.class.validation_macro_name} requires either :in, :within, :is, or :min and/or :max as options."
          end
        end
        
        def valid?(value)
          if range
            range.include?(value.length)
          elsif max
            value.length <= max
          elsif min
            value.length >= min
          elsif is
            value.length == is
          end
        end
        def message
          if range
            super
          elsif max
            too_long
          elsif min
            too_short
          elsif is
            wrong_length
          end
        end
      end
    end
  end
end
