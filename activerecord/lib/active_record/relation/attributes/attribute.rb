class ActiveRecord
  class Relation
    module Attributes
      # Abstract class which defines the interface for attributes
      class Attribute #:nodoc:
        attr_reader :name

        def initialize(name)
          @name = name
        end

        # The initial value of the attribute
        def initial
          raise NotImplementedError
        end

        # Return the value of the attribute added on to the relation according to the args and block
        def add(relation, *args, &block)
          raise NotImplementedError
        end
      end
    end
  end
end
