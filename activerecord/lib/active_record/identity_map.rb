module ActiveRecord
  module IdentityMap
    extend ActiveSupport::Concern

    class << self
      attr_accessor :repositories
      attr_accessor :current_repository_name
      attr_accessor :enabled
      
      def current
        repositories[current_repository_name] ||= Weakling::WeakHash.new
      end

      def with_repository(name = :default, &block)
        old_repository = self.current_repository_name
        self.current_repository_name = name

        block.call(current)
      ensure
        self.current_repository_name = old_repository
      end

      def without(&block)
        old, self.enabled = self.enabled, false

        block.call
      ensure
        self.enabled = old
      end

      def get(class_name, primary_key)
        current[[class_name, primary_key]]
      end

      def add(record)
        current[[record.class.name, record.id]] = record
      end

      def remove(record)
        current[[record.class.name, record.id]] = nil
      end

      def clear
        current.clear
      end

      alias enabled? enabled
    end

    self.repositories ||= Hash.new
    self.current_repository_name ||= :default
    self.enabled = true

    module InstanceMethods

    end
    
    module ClassMethods
      def identity_map
        ActiveRecord::IdentityMap
      end
    end
  end
end
