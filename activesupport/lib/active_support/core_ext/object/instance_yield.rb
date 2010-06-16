class Object
  # Leaves the decission to use instance_exec for internal DSLs up the end user
  # by using instance_exec if the given block takes more arguments than passed to
  # instance_yield, yield(self, *args) otherwise.
  #
  #   def my_dsl(&block)
  #     dsl_object.instance_yield(42, &block)
  #   end
  #   
  #   my_dsl do |number|
  #     do_something :with => "a string"
  #     self    # => dsl_object
  #     number  # => 42
  #   end
  #   
  #   my_dsl do |object, number|
  #     object.do_something :with => "a string"
  #     self    # => main
  #     number  # => 42
  #   end
  def instance_yield(*args, &block)
    if block.arity > args.size or (-1 - block.arity) > args.size
      yield(self, *args)
    else
      instance_exec(*args, &block)
    end
  end
end