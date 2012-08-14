require 'active_support/concern'
require 'active_support/core_ext/object/acts_like'

module InfiniteComparable
  extend ActiveSupport::Concern

  included do
    class_exec do
      origin_compare = instance_method(:<=>)

      define_method(:<=>) do |other|
        conversion = :"to_#{self.class.name.downcase}"
        if other.respond_to?(:infinite?) && other.infinite?
          -other.infinite?
        elsif other.respond_to?(conversion) && (other.acts_like?(:date) || other.acts_like?(:time))
          origin_compare.bind(self).call(other.send(conversion))
        else
          origin_compare.bind(self).call(other)
        end
      end
    end
  end
end
