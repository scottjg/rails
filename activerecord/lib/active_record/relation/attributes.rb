module ActiveRecord
  class Relation
    module Attributes #:nodoc:
      extend ActiveSupport::Concern

      autoload :Attribute,          'active_record/relation/attributes/attribute'
      autoload :SingleAttribute,    'active_record/relation/attributes/single_attribute'
      autoload :MultiAttribute,     'active_record/relation/attributes/multi_attribute'
      autoload :ConditionAttribute, 'active_record/relation/attributes/condition_attribute'

      # SQL attributes
      autoload :Select,  'active_record/relation/attributes/select'
      autoload :Lock,    'active_record/relation/attributes/lock'
      autoload :From,    'active_record/relation/attributes/from'
      autoload :Joins,   'active_record/relation/attributes/joins'
      autoload :Where,   'active_record/relation/attributes/where'
      autoload :Group,   'active_record/relation/attributes/group'
      autoload :Having,  'active_record/relation/attributes/having'
      autoload :Order,   'active_record/relation/attributes/order'
      autoload :Reorder, 'active_record/relation/attributes/reorder'
      autoload :Limit,   'active_record/relation/attributes/limit'
      autoload :Offset,  'active_record/relation/attributes/offset'

      # Non-SQL attributes
      autoload :Readonly,  'active_record/relation/attributes/readonly'
      autoload :Bind,      'active_record/relation/attributes/bind'
      autoload :Preload,   'active_record/relation/attributes/preload'
      autoload :Includes,  'active_record/relation/attributes/includes'
      autoload :Extending, 'active_record/relation/attributes/extending'

      class Single
        def initial
          nil
        end
      end

      class Multiple
        def initial
          []
        end
      end

      module ClassMethods
        cattr_accessor :attributes
        self.attributes = {}

        def attribute(name, klass)
          attributes[name] = klass.new(name)

          class_eval <<-CODE, __FILE__, __LINE__
            def #{name}(*args, &block)       # def where(*args, &block)
              clone.#{name}!(*args, &block)  #   clone.where!(*args, &block)
            end                              # end

            def #{name}!(*args, &block)                      # def where!(*args, &block)
              attribute = self.class.attributes[:#{name}]    #   attribute = self.class.attributes[:where]
              value     = attribute.add(self, *args, &block) #   value     = attribute.add(self, *args, &block)
              self.attributes[:#{name}] = value              #   self.attributes[:where] = value
              self                                           #   self
            end                                              # end
          CODE
        end
      end

      def initial_attributes
        Hash[self.class.attributes.map { |name, attribute| [name, attribute.initial]]
      end
    end
  end
end
