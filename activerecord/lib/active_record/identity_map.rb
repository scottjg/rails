module ActiveRecord
  module IdentityMap
    extend ActiveSupport::Concern

    module InstanceMethods
      
    end
    
    module ClassMethods
      attr_accessor :repositories
      attr_accessor :current_repository

      def identity_map
        self.repositories ||= Hash.new
        self.current_repository ||= :default
        self.repositories[current_repository] ||= Weakling::WeakHash.new
      end

      # Finder methods must instantiate through this method to work with the
      # single-table inheritance model that makes it possible to create
      # objects of different types from the same table.
      def instantiate(record)
        p(record)
        klass = find_sti_class(record[inheritance_column])
        pk_value = record[klass.primary_key]

        object = identity_map[[klass.name, pk_value]] ||= super

        object
      end
    end
  end
end
