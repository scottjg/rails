class Object
  # Leaves the decission to use instance_eval for internal DSLs up the end user
  # by using instance_eval if the given block takes an argument, yield(self)
  # otherwise.
  #
  #   def my_dsl(&block)
  #     dsl_object.instance_yield(&block)
  #   end
  #   
  #   my_dsl do
  #     do_something :with => "a string"
  #     self # => dsl_object
  #   end
  #   
  #   my_dsl do |c|
  #     c.do_something :with => "a string"
  #     self # => main
  #   end
  def instance_yield(&block)
    block.arity > 0 ? yield(self) : instance_eval(&block)
  end
end