module ActiveModel
  class Errors < Hash
    include DeprecatedErrorMethods
    
    # note by geekQ: not really needed, you can put the message near the code,
    # which produces them, just prefix with underscore like _("%{attr} is invalid")
    # Makes coding easier, there is no need to stop every time and spread messages  
    # and code to different files.
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
  
    ##
    # :singleton-method:
    # Holds a hash with all the default error messages that can be replaced by your own copy or localizations.
    cattr_accessor :default_error_messages

    alias_method :get, :[]
    alias_method :set, :[]=

    # * <tt>attribute</tt> - symbol or string representing the name of the attribute
    # * <tt>message</tt> - can be 
    #          * string
    #          * symbol 
    #          * proc
    # * <tt>params</tt> - data, that will be interpolated into the message; 
    #          attribute name will be automatically reverse merged into the params hash
    # 
    # example errors.add(:name, _("%{attribute} is too long (maximum is %{maximum} characters)"), :maximum => 30)
    # 
    # Note: parameter interpolation logic placed here to avoid the repetion 
    # of the attribute name in particular validators (validates_length_of etc.). Compare to
    # errors[:name] = _("%{attribute} is too long (maximum is %{maximum} characters)") % 
    #   {:attribute => :name, :maximum => 30}
    def add(attribute, message, params={})
      params2 = {:attribute => _(attribute.to_s.humanize)}.merge(params)
      if message.is_a?(Proc)
        s = message.call(params2)
      else
        # TODO: decide what to do (differently?) to symbols and strings
        # TODO: needs the improved percent method (e.g. as implemented by Masao)
        s = message % params2
      end
      self[attribute] = s
    end

    def [](attribute)
      if errors = get(attribute.to_sym)
        errors.size == 1 ? errors.first : errors
      else
        set(attribute.to_sym, [])
      end
    end

    # IMHO the name is pretty unfortunate.
    # '[]=' suggests overwriting while in this case it is appending a message to the list.
    # String interpolation needs more than two parameters anyway.
    def []=(attribute, error)
      self[attribute.to_sym] << error
    end

    def each
      each_key do |attribute| 
        self[attribute].each { |error| yield attribute, error }
      end
    end

    def size
      values.flatten.size
    end

    def to_a
      # some sort of flattening for the hash of arrays
      inject([]) do |errors_with_attributes, (attribute, errors)|
        errors_with_attributes + error
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
  end
end
