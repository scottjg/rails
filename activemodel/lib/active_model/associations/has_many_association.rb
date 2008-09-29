module ActiveModel
  module Associations
    # This is the proxy that handles a has many association.
    #
    # If the association has a <tt>:through</tt> option further specialization
    # is provided by its child HasManyThroughAssociation.
    class HasManyAssociation < AssociationCollection #:nodoc:
    end
  end
end