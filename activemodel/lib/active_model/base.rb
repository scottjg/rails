module ActiveModel
  class Base
    include Observing
    include Validatable
    # disabled, until they're tested
    # include Callbacks
  end
end