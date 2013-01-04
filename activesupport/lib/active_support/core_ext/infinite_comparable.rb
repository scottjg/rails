require 'active_support/concern'
<<<<<<< HEAD
require 'active_support/core_ext/object/acts_like'
=======
require 'active_support/core_ext/object/try'
>>>>>>> upstream/master

module InfiniteComparable
  extend ActiveSupport::Concern

  included do
<<<<<<< HEAD
    class_exec do
      origin_compare = instance_method(:<=>)

      define_method(:<=>) do |other|
        return origin_compare.bind(self).call(other) if other.class == self.class

        conversion = :"to_#{self.class.name.downcase}"
        if other.respond_to?(:infinite?) && other.infinite?
          -other.infinite?
        elsif other.respond_to?(conversion)
          origin_compare.bind(self).call(other.send(conversion))
        else
          origin_compare.bind(self).call(other)
        end
=======
    alias_method_chain :<=>, :infinity
  end

  define_method :'<=>_with_infinity' do |other|
    if other.class == self.class
      public_send :'<=>_without_infinity', other
    else
      infinite = try(:infinite?)
      other_infinite = other.try(:infinite?)

      # inf <=> inf
      if infinite && other_infinite
        infinite <=> other_infinite
      # not_inf <=> inf
      elsif other_infinite
        -other_infinite
      # inf <=> not_inf
      elsif infinite
        infinite
      else
        conversion = "to_#{self.class.name.downcase}"
        other = other.public_send(conversion) if other.respond_to?(conversion)
        public_send :'<=>_without_infinity', other
>>>>>>> upstream/master
      end
    end
  end
end
