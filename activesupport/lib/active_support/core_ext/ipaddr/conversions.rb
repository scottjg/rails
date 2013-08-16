class IPAddr
  # In order to do not raise exception on comparing `IPAddr` with `String` with invalid addr.
  def ==(other)
    super
  rescue AttributeError
    false
  end
end
