validatable = File.dirname(__FILE__)
require "#{validatable}/error_message"
=begin
RUY-NOTES: My changes to errors are the most drastic departure from the existing ActiveRecord code.

The first 'design goal' is to make Errors more 'familiar' with ruby data types.

One thing that (IMO) causes a lot of confusion is how .errors[:whatever] can sometimes return an
array of strings, and sometimes just the string. NOTHING ELSE EVER DOES THIS IN RUBY. EVER.

It also makes it a PITA to work with errors since you need to check the return type and UGH - it's just so NOT GOOD.

So basically, I'm putting my foot down and saying: Erors is basically an Array. I would have it inherit from Array,
but I'm not smart enough to do that in a good way (there are some special considerations, described below). No doubt,
somebody else will be.

So, for example:
  
  @person.errors[0] # => "Name can't be blank."
  @person.errors.first #=> "Name can't be blank."
  @person.errors.each # .. etc, it all works as expected

For all you care, it's an Array! Ok? Ok!

The second 'design goal' is to encapsulate error messages in a class of their own - see error_message.rb
  
  # You shouldn't do this:
  @person.errors << "Failure!"
  # You could do this instead:
  @person.errors << ErrorMessage.new(...)
  # But really, you should just do this:
  @person.errors.add "Failure"
  
We'll look more in depth at adding errors later.

So how is it not like an Array? Well you'll want to be able to filter errors by attribute. The Array-ness of Errors
is more important to me then it's Error-ness, so @person.errors[:name] is no longer supported. Instead we just 
have the old @person.errors.on(:name).

And what does that return? Why another Errors (Array) of course! 

  @person.errors[0] # => "Person is too ugly."
  @person.errors[1] # => "Name can't be blank."
  @person.errors[2] # => "Address can't be blank."
  
  @person.errors.on(:name)[0] # => "Name can't be blank"
  @person.errors.on(:address)[0] # => "Address can't be blank"

  # What about the first one though?
  @person.errors.on(:base)[0] # => "Person is too ugly"
  @person.errors.on(:base).size # => 1
  # Yay awsome!


One neat thing about this is that if the attribute whose errors you want has a .errors of it's own, they are included
recursively:

  @person.errors[0] # => "Name can't be blank."
  @person.errors[1] # => "Company name is taken."
  
  @person.on(:name)[0] # => "Name can't be blank."
  @person.errors.on(:company)[0] # => "Company name is taken."
  @person.errors.on(:company).on(:name)[0] # => "Company name is taken."

  @person.errors.on(:company) == @person.company.errors # Not exactly true, but that's the idea.

Now one potential problem you might realize is that when you ADD an error to an Errors array, some confusion arises as to where
to actually store the error. I hope the behavior is *mostly* intuitive, but there are definately a few confusing edge cases. 

LEAKY ABSTRACTION WARNING: One key thought to hang on to is that READING from an Errors object works on a
different underlying array then WRITING to the same Errors object. 

Examples:

  @person.errors.on(:name).add "Name is stupid!"
  @person.errors.on(:title).add "REALLY now? A title?"
  
  @person.errors == ["Name is stupid!","REALLY now? A title?"]
  @person.errors.on(:name) == ["Name is stupid!"]
  @person.errors.on(:title) == ["REALLY now? A title?"]
  
  # So far so good yes?
  
  @person.errors.add "I hate this person."
  # ... is actually the same as ...
  @person.errors.on(:base).add "I hate this person."
  
  @person.errors == ["I hate this person.", "Name is stupid!","REALLY now? A title?"]
  # (note that :base errors always show up first)
  
  # Now for something REALLY confusing!
  @person.errors.on(:company).add "This person can't work at this company."
  
  @person.errors == ["I hate this person.", "Name is stupid!","REALLY now? A title?", "This person can't work at this company."]
  @person.errors.on(:company) == ["This person can't work at this company."]
  # HOWEVER!
  @person.company.errors == []
  # ZUH?
  
Rationale:
When you go @errors.on(:company) we assume you mean there is a problem with this particular association, NOT the company as a whole. 
The comapny is 'valid', it's just that this person working there is not a valid situation. 

  # To add an error to the company itself, you can (predictably I hope) do this:
  @person.company.errors.add "Company is not a legal employer."
  
  @person.errors.on(:company) == ["This person can't work at this company.","Company is not a legal employer."]
  @person.company.errors == ["Company is not a legal employer."]

That's not so bad now is it? It also deals with adding errors to an aggregate association (@person.errors.on(:friends).add) quite elegantly...

Do note however, that if you were to dig deeper, you DO end up modifying the associate object's errors:

  @person.errors.on(:company).on(:name).add "Company name sounds silly."
  
  @person.errors.on(:company) == ["This person can't work at this company.","Company is not a legal employer.","Company name sounds silly."]
  @person.company.errors == ["Company is not a legal employer.","Company name sounds silly."]
  @person.company.errors.on(:name) == ["Company name sounds silly."]
  @person.errors.on(:company).on(:name) == ["Company name sounds silly."]

Seems reasonable that if the error is specific to an attribute of the assocatation it's not particular to just this association.
Also, the alternative would be pain to implement.


So yes, there are some complications here, but I think they are mostly isolated to pretty useless / ridiculous edge cases.

Overall, Errors should be much easier to work with (due to their array-likeness) and we can think of .on() as a simple filter. You
should also keep in mind that manually adding errors is a MUCH less common case then reading from them, and most of the confusing bits
from this API only apply to adding errors.


=end
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