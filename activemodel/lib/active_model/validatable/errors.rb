require File.join(File.dirname(__FILE__), "deprecated_error_methods")
=begin

post.errors
  base = post
  attribute = nil
  errs = :sux, :short, :stupid
  errs >> errors.on(:base).errs
post.errors.on(:title)
  base = post
  attribute = :title
  errs = :short
  errs >> errs
post.errors.on(:base)
  base = post
  attribute = :base
  errs = :short, :stupid
  errs >> errs

post.errors.on(:author)
  base = post
  attribute = :author
  errs = :postcount_max, :noname, :tooyoung
  errs >> errs
post.author.errors
  base = author
  attribute = nil
  errs = :noname, :tooyoung
  errs >> errors.on(:base).errs
post.author.errors.on(:name)
  base = author
  attribute = :name
  errs = :noname
  errs >> errs
post.errors.on(:author).on(:name)
  base = author
  attribute = :name
  erros = :noname
  errs >> errs
  
post.errors.on(:tags)
  base = post
  attribute = :tags
  errs = :toomany, :invalid, :invalid
post.tags[0].errors
  base = tag
  attribute = nil
  errs = :invalid
post.errors.on(:tags).on(:name)
  base = [tags]
  attribute = :name
  errs = :invalid, :invalid
  errs >> add to all?

=end
module ActiveModel
  class Errors
    
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
    
    
    def initialize(base, attribute = nil)
      @base = base
      @attribute = attribute
      if attribute_proxy?
        # Only store references to Errors for each attribute (including :base)
        @errors_for_attribute = {}
      else
        # Store the actual error messages
        @errors_array = []
      end

    end
    
    def attribute_proxy? #:nodoc:
      @attribute.nil?
    end
    
    def association_proxy? #:nodoc:
      return false if attribute_proxy? or !@base.respond_to?(@attribute)
      @base.send(@attribute).respond_to?(:errors)
    end
    
    def associate_errors #:nodoc:
      @base.send(@attribute).errors
    end
    
    def add(message)
      self << message
    end
    
    # Think of this is a filter
    def on(attribute)
      if association_proxy?
        associate_errors.on(attribute) 
      else
        @errors_for_attribute[attribute] ||= Errors.new(@base, attribute)
      end
    end
    
    def on_base
      on(:base)
    end
    
    def method_missing(method_name, *args, &block)
      array_we_pretend_to_be = errors_array_for_reading.freeze
      retried = false
      begin
        array_we_pretend_to_be.send(method_name, *args, &block)
      rescue TypeError => e
        raise e if retried
        array_we_pretend_to_be = errors_array_for_modifying
        retried = true
        retry
      end
      
    end
    
    private
    
    # This is the array we pretend to be when being read from
    def errors_array_for_reading
      errors_array = []
      errors_array += @errors_for_attribute.values.collect{|e|e.send :errors_array_for_reading}.flatten if attribute_proxy?
      errors_array += @errors_array if @errors_array
      errors_array += associate_errors.send(:errors_array_for_reading) if association_proxy?
      errors_array
    end
    
    # This is the array we pretend to be when being modified
    def errors_array_for_modifying
      if attribute_proxy?
        on(:base).send(:errors_array_for_modifying)
      else
        @errors_array 
      end
    end
    
  end
end