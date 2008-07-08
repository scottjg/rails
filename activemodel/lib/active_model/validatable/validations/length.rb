module ActiveModel
  module Validatable
    module Validations
      class ValidatesLengthOf < Base
        options :min, :max, :in, :within, :is, :message => "{attribute_name} '{value}' must be one of {in}."
        validate_option :in=>:include?
        
        def range
          if options[:min] && options[:max]
            (options[:min]..options[:max])
          else
            options[:in] || options[:within]
          end
        end
        
        def validate_options
          alternatives = [:min, :max, :in, :within, :is]
          hits = (options.keys & alternatives).size
          unless  hits == 1 or (hits == 2 && options.keys.include?(:min) && options.keys.include?(:max) )
            alts = alternatives.collect(&:inspect).to_sentence(:connector=>"or")
            raise MissingRequiredOption, "#{self.class.validation_macro_name} requires either :in, :within, :is, or :min and/or :max as options."
          end
          super
        end
        
        def valid?(value)
          if range
            range.include?(value.length)
          elsif options[:max]
            value.length <= options[:max]
          elsif options[:min]
            value.length >= options[:min]
          elsif options[:is]
            value.length == options[:is]
          end
        end
        def message
          super
        end
      end
    end
  end
end
