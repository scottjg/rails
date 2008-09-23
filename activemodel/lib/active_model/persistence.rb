module ActiveModel
  ##
  # This module implements no-op versions of the methods an extending framework
  # needs in order to implement persistence.
  # 
  # ActiveModel::Persistence is here to provide blank implementations of these methods
  # for the benefit of other modules which depend on them (e.g. ActiveModel::Callbacks).
  #
  module Persistence
    def save(*args, &block)
      create_or_update
    end
    
    def create(*args, &block)
      persistence_driver.create(*args, &block)
    end
    
    def update(*args, &block)
      persistence_driver.update(*args, &block)
    end
    
    def destroy(*args, &block)
      persistence_driver.update(*args, &block)      
    end
    
    def create_or_update(*args, &block)
      persistence_driver.update(*args, &block)      
    end
  end
end