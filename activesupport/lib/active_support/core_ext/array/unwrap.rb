class Array
  # Unwraps the first object from the argument.
  #
  # This is basically the opposite of +Array.wrap+ and can be useful in cases
  # where a single element array is expected or when you might have an array.
  #
  # Specifically:
  #
  # * If the argument is an array (or array-like), the first element is returned.
  # * If the array is empty, +nil+ is returned.
  # * Otherwise, if the argument is any other object, the object is returned.
  #
  #     Array.unwrap([1]) # => 1
  #     Array.unwrap([])  # => nil
  #     Array.unwrap(1)   # => 1
  #
  # Array.unwrap is roughly equivalent to:
  #
  #     Array.wrap(object).first
  def self.unwrap(array)
    object, _ = array

    object
  end
end
