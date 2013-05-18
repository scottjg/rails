module Enumerable
  # Coerces the enumerable to an array for JSON encoding.
  def as_json(options = nil) #:nodoc:
    to_a
  end
end

class Array
  def as_json(options = nil) #:nodoc:
    self
  end
end
