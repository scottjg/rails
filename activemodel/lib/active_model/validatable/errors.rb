validatable = File.dirname(__FILE__)
require "#{validatable}/error_message"
module ActiveModel
  module Validatable
    # Errors is an Array-like structure of sorts which includes all "child" error arrays within it.
    #
    # <example>
    # 
    # At least this is the case for reading methods. Mutation methods however, are dispatched to just 
    # one place, hopefully in an intuitive manner...
    class Errors
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
    
      def clear
        if attribute_proxy?
          @errors_for_attribute.values.each(&:clear)
        else
          @errors_array.clear
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
      
      # Adds the +message+ string as an ErrorMessage for the current object/attribute. 
      # Optionally accepts a validation object for substitutions.
      def add(message, validation=nil)
        self << ErrorMessage.new(@base, @attribute, message, validation)
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
    
      def to_a
        errors_array_for_reading
      end
      
      def to_s
        "#<#{self.class.name} on #{@base.class.name}##{@attribute}: #{to_a.inspect} >"
      end
    
      private
    
      # This is the array we pretend to be when being read from
      def errors_array_for_reading
        errors_array = []
        errors_array += @errors_array if @errors_array
        if attribute_proxy?
          errs = @errors_for_attribute.dup
          # :base goes first
          errors_array += errs.delete(:base).send(:errors_array_for_reading) if errs[:base]
          errors_array += errs.values.collect{|e|e.send :errors_array_for_reading}.flatten
        end
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
end