module ActiveModel
  class Base
    include Observing
    include Persistence
    include Validations
    include Callbacks
  end
end