require 'abstract_unit'

class Record
  include ActiveSupport::Callbacks

  define_callbacks :before_save, :after_save

  class << self
    def callback_symbol(callback_method)
      returning("#{callback_method}_method") do |method_name|
        define_method(method_name) do
          history << [callback_method, :symbol]
        end
      end
    end

    def callback_string(callback_method)
      "history << [#{callback_method.to_sym.inspect}, :string]"
    end

    def callback_proc(callback_method)
      Proc.new { |model| model.history << [callback_method, :proc] }
    end

    def callback_object(callback_method)
      klass = Class.new
      klass.send(:define_method, callback_method) do |model|
        model.history << [callback_method, :object]
      end
      klass.new
    end
  end

  def history
    @history ||= []
  end
end

class Person < Record
  [:before_save, :after_save].each do |callback_method|
    callback_method_sym = callback_method.to_sym
    send(callback_method, callback_symbol(callback_method_sym))
    send(callback_method, callback_string(callback_method_sym))
    send(callback_method, callback_proc(callback_method_sym))
    send(callback_method, callback_object(callback_method_sym))
    send(callback_method) { |model| model.history << [callback_method_sym, :block] }
  end

  def save
    run_callbacks(:before_save)
    run_callbacks(:after_save)
  end
end

class ConditionalPerson < Record
  before_save Proc.new { |r| r.history << [:before_save, :proc] }, :if => Proc.new { |r| true }
  before_save Proc.new { |r| r.history << "b00m" }, :if => Proc.new { |r| false }
  before_save Proc.new { |r| r.history << [:before_save, :proc] }, :unless => Proc.new { |r| false }
  before_save Proc.new { |r| r.history << "b00m" }, :unless => Proc.new { |r| true }

  def save
    run_callbacks(:before_save)
    run_callbacks(:after_save)
  end
end

class ArgumentativePerson < Record
  before_save :check_no_args, :check_first_arg, :check_first_two_args, :check_all_args, :check_first_and_any_args, :check_any_args
  
  def check_no_args
    history << [:no]
  end

  def check_first_arg(a)
    history << [:first, a]
  end
  
  def check_first_two_args(a,b)
    history << [:first_two, a, b]
  end
  
  def check_all_args(a,b,c,d)
    history << [:all, a, b, c, d]
  end

  def check_first_and_any_args(a, *args)
    history << [:first_and_any, a, *args]
  end
  
  def check_any_args(*args)
    history << [:any, *args]
  end
  
  before_save "history << [:string_callback]"
  
  before_save { |record|          record.history << [:no] }
  before_save { |record, a|       record.history << [:first, a] }
  before_save { |record, a,b|     record.history << [:first_two, a, b] }
  before_save { |record, a,b,c,d| record.history << [:all, a, b, c, d] }
  before_save { |record, a,*args| record.history << [:first_and_any, a, *args] }
  before_save { |record, *args|   record.history << [:any, *args] }
  
  class NoArgObserver
    def before_save(record)
      record.history << [:no]
    end
  end
  
  class TwoArgObserver
    def before_save(record, a,b)
      record.history << [:two, a,b]
    end
  end
  
  class FirstAndAnyObserver
    def before_save(record, a, *args)
      record.history << [:first_and_any, a,*args]
    end
  end
  
  before_save NoArgObserver.new
  before_save TwoArgObserver.new
  before_save FirstAndAnyObserver.new
    

  def save
    run_callbacks(:before_save, :args=>[1,2,3,4])
    run_callbacks(:after_save)
  end
end

class CallbacksTest < Test::Unit::TestCase
  def test_save_person
    person = Person.new
    assert_equal [], person.history
    person.save
    assert_equal [
      [:before_save, :symbol],
      [:before_save, :string],
      [:before_save, :proc],
      [:before_save, :object],
      [:before_save, :block],
      [:after_save, :symbol],
      [:after_save, :string],
      [:after_save, :proc],
      [:after_save, :object],
      [:after_save, :block]
    ], person.history
  end
end

class ConditionalCallbackTest < Test::Unit::TestCase
  def test_save_conditional_person
    person = ConditionalPerson.new
    person.save
    assert_equal [
      [:before_save, :proc],
      [:before_save, :proc]
    ], person.history
  end
end

class CallbackTest < Test::Unit::TestCase
  include ActiveSupport::Callbacks

  def test_eql
    callback = Callback.new(:before, :save, :identifier => :lifesaver)
    assert callback.eql?(Callback.new(:before, :save, :identifier => :lifesaver))
    assert callback.eql?(Callback.new(:before, :save))
    assert callback.eql?(:lifesaver)
    assert callback.eql?(:save)
    assert !callback.eql?(Callback.new(:before, :destroy))
    assert !callback.eql?(:destroy)
  end

  def test_dup
    a = Callback.new(:before, :save)
    assert_equal({}, a.options)
    b = a.dup
    b.options[:unless] = :pigs_fly
    assert_equal({:unless => :pigs_fly}, b.options)
    assert_equal({}, a.options)
  end
end

class CallbackChainTest < Test::Unit::TestCase
  include ActiveSupport::Callbacks

  def setup
    @chain = CallbackChain.build(:make, :bacon, :lettuce, :tomato)
  end

  def test_build
    assert_equal 3, @chain.size
    assert_equal [:bacon, :lettuce, :tomato], @chain.map(&:method)
  end

  def test_find
    assert_equal :bacon, @chain.find(:bacon).method
  end

  def test_union
    assert_equal [:bacon, :lettuce, :tomato], (@chain | Callback.new(:make, :bacon)).map(&:method)
    assert_equal [:bacon, :lettuce, :tomato, :turkey], (@chain | CallbackChain.build(:make, :bacon, :lettuce, :tomato, :turkey)).map(&:method)
    assert_equal [:bacon, :lettuce, :tomato, :turkey, :mayo], (@chain | Callback.new(:make, :mayo)).map(&:method)
  end

  def test_delete
    assert_equal [:bacon, :lettuce, :tomato], @chain.map(&:method)
    @chain.delete(:bacon)
    assert_equal [:lettuce, :tomato], @chain.map(&:method)
  end
end

class CallbackWithArgumentsTest < Test::Unit::TestCase
  def test_callbaks_with_arguments
    person = ArgumentativePerson.new
    assert_equal [], person.history
    person.save
    assert_equal [
      [:no              ],
      [:first,          1],
      [:first_two,      1,2],
      [:all,            1,2,3,4],
      [:first_and_any,  1,2,3,4],
      [:any,            1,2,3,4],
      [:string_callback ],
      [:no              ],
      [:first,          1],
      [:first_two,      1,2],
      [:all,            1,2,3,4],
      [:first_and_any,  1,2,3,4],
      [:any,            1,2,3,4],
      [:no              ],
      [:two,            1,2],
      [:first_and_any,  1,2,3,4],
    ], person.history    
  end
end
