module ActiveModel
  class Errors
    include DeprecatedErrorMethods
    include Enumerable
    
    @@default_error_messages = {
      :inclusion                => "is not included in the list",
      :exclusion                => "is reserved",
      :invalid                  => "is invalid",
      :confirmation             => "doesn't match confirmation",
      :accepted                 => "must be accepted",
      :empty                    => "can't be empty",
      :blank                    => "can't be blank",
      :too_long                 => "is too long (maximum is %d characters)",
      :too_short                => "is too short (minimum is %d characters)",
      :wrong_length             => "is the wrong length (should be %d characters)",
      :taken                    => "has already been taken",
      :not_a_number             => "is not a number",
      :greater_than             => "must be greater than %d",
      :greater_than_or_equal_to => "must be greater than or equal to %d",
      :equal_to                 => "must be equal to %d",
      :less_than                => "must be less than %d",
      :less_than_or_equal_to    => "must be less than or equal to %d",
      :odd                      => "must be odd",
      :even                     => "must be even"
    }
  
    # Holds a hash with all the default error messages that can be replaced by your own copy or localizations.
    cattr_accessor :default_error_messages
    
    # Delegate Hash methods that actually make sense for Errors
    delegate :[]=, :clear, :delete, :delete_if, :empty?, :include?, :length, :size, 
             :merge, :merge!, :reject, :reject!, :replace,  :select, :shift, :update,
             :to=>:errors_hash
    
    def initialize(base)
      @base = base
      @on = {}
    end

    def [](attribute)
      # Note: Can't use Hash#default_proc for this because it would make AR:B unserializable.
      @on[attribute] ||= []
    end
    
    alias_method :count, :size

    def each
      @on.each_key do |attribute| 
        self[attribute].each { |error| yield attribute, error }
      end
    end

    def size
      values.flatten.size
    end

    def to_a
      inject([]) do |errors_with_attributes, (attribute, errors)|
        if error.blank?
          errors_with_attributes
        else
          if attr == :base
            errors_with_attributes << error
          else
            errors_with_attributes << (attribute.to_s.humanize + " " + error)
          end
        end
      end
    end

    def to_xml(options={})
      options[:root]    ||= "errors"
      options[:indent]  ||= 2
      options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

      options[:builder].instruct! unless options.delete(:skip_instruct)
      options[:builder].errors do |e|
        to_a.each { |error| e.error(error) }
      end
    end
    
    private
    
    def errors_hash
      @on
    end
    
  end
end