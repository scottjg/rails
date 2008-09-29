module ActiveModel
  # Generic Active Model exception class.
  class ActiveModelError < StandardError
  end
  
  class RecordNotFound < ActiveModelError
  end

  class Base
    include Observing
    include Associations
    include Reflection    
    include Persistence
    include Validations
    include Callbacks
  end
end