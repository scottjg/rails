module ActiveRecord
  module IdentityMap
    extend ActiveSupport::Concern

    class << self
      attr_accessor :repositories
      attr_accessor :current_repository_name
      
      def current
        repositories[current_repository_name] ||= Weakling::WeakHash.new
      end

      def with_repository(name = :default, &block)
        old_repository = self.current_repository_name
        self.current_repository_name = name

        block.call(current)
      ensure
        self.current_repository_name = old_repository

        current
      end

      def with_temporary_repository(&block)
        repositories[:temporary] && repositories[:temporary].clear
        with_repository(:temporary, &block)
      ensure
        repositories[:temporary] && repositories[:temporary].clear
      end
    end

    self.repositories ||= Hash.new
    self.current_repository_name ||= :default

    module InstanceMethods

    end
    
    module ClassMethods
      def identity_map
        ActiveRecord::IdentityMap.current
      end
    end
  end
end
