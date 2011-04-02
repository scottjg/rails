require 'cases/helper'

class ObservedModel
  include ActiveModel::Observing

  class Observer
  end
end

class FooObserver < ActiveModel::Observer
  class << self
    public :new
  end

  attr_accessor :stub

  def on_spec(record)
    stub.event_with(record) if stub
  end
end

class Foo
  include ActiveModel::Observing
end

class BarObserver < ActiveModel::Observer
  observe :foo
  attr_accessor :stub

  def on_spec(record)
    stub.event_with(record) if stub
  end
end

class ObservingTest < ActiveModel::TestCase
  def setup
    ObservedModel.observers.clear
  end

  test "initializes model with no cached observers" do
    assert ObservedModel.observers.empty?, "Not empty: #{ObservedModel.observers.inspect}"
  end

  test "stores cached observers in an array" do
    ObservedModel.observers << :foo
    assert ObservedModel.observers.include?(:foo), ":foo not in #{ObservedModel.observers.inspect}"
  end

  test "flattens array of assigned cached observers" do
    ObservedModel.observers = [[:foo], :bar]
    assert ObservedModel.observers.include?(:foo), ":foo not in #{ObservedModel.observers.inspect}"
    assert ObservedModel.observers.include?(:bar), ":bar not in #{ObservedModel.observers.inspect}"
  end

  test "instantiates observer names passed as strings" do
    ObservedModel.observers << 'foo_observer'
    FooObserver.expects(:instance)
    ObservedModel.instantiate_observers
  end

  test "instantiates observer names passed as symbols" do
    ObservedModel.observers << :foo_observer
    FooObserver.expects(:instance)
    ObservedModel.instantiate_observers
  end

  test "instantiates observer classes" do
    ObservedModel.observers << ObservedModel::Observer
    ObservedModel::Observer.expects(:instance)
    ObservedModel.instantiate_observers
  end

  test "passes observers to subclasses" do
    FooObserver.instance
    bar = Class.new(Foo)
    assert_equal Foo.count_observers, bar.count_observers
  end
end

class ObserverTest < ActiveModel::TestCase
  def setup
    ObservedModel.observers = :foo_observer, :bar_observer
    FooObserver.instance_eval do
      alias_method :original_observed_classes, :observed_classes
    end
  end

  def teardown
    FooObserver.instance_eval do
      undef_method :observed_classes
      alias_method :observed_classes, :original_observed_classes
    end
    FooObserver.instance.stub = nil
    BarObserver.instance.stub = nil

    Foo.enable_observers :all
  end

  test "guesses implicit observable model name" do
    assert_equal Foo, FooObserver.observed_class
  end

  test "tracks implicit observable models" do
    instance = FooObserver.new
    assert  instance.send(:observed_classes).include?(Foo), "Foo not in #{instance.send(:observed_classes).inspect}"
    assert !instance.send(:observed_classes).include?(ObservedModel), "ObservedModel in #{instance.send(:observed_classes).inspect}"
  end

  test "tracks explicit observed model class" do
    old_instance = FooObserver.new
    assert !old_instance.send(:observed_classes).include?(ObservedModel), "ObservedModel in #{old_instance.send(:observed_classes).inspect}"
    FooObserver.observe ObservedModel
    instance = FooObserver.new
    assert instance.send(:observed_classes).include?(ObservedModel), "ObservedModel not in #{instance.send(:observed_classes).inspect}"
  end

  test "tracks explicit observed model as string" do
    old_instance = FooObserver.new
    assert !old_instance.send(:observed_classes).include?(ObservedModel), "ObservedModel in #{old_instance.send(:observed_classes).inspect}"
    FooObserver.observe 'observed_model'
    instance = FooObserver.new
    assert instance.send(:observed_classes).include?(ObservedModel), "ObservedModel not in #{instance.send(:observed_classes).inspect}"
  end

  test "tracks explicit observed model as symbol" do
    old_instance = FooObserver.new
    assert !old_instance.send(:observed_classes).include?(ObservedModel), "ObservedModel in #{old_instance.send(:observed_classes).inspect}"
    FooObserver.observe :observed_model
    instance = FooObserver.new
    assert instance.send(:observed_classes).include?(ObservedModel), "ObservedModel not in #{instance.send(:observed_classes).inspect}"
  end

  def setup_observer_mock(observer_class, should_be_notified, arg = nil)
    observer_class.instance.stub = stub("#{observer_class} notification stub")

    if should_be_notified
      observer_class.instance.stub.expects(:event_with).with(arg)
    else
      observer_class.instance.stub.expects(:event_with).never
    end
  end

  test "calls existing observer event" do
    foo = Foo.new
    setup_observer_mock(FooObserver, true, foo)
    Foo.send(:notify_observers, :on_spec, foo)
  end

  test "can disable invidual observers by calling `disable_observers :symbol` on the class that includes Observing" do
    foo = Foo.new
    Foo.disable_observers :foo_observer
    setup_observer_mock(BarObserver, true, foo)
    setup_observer_mock(FooObserver, false, foo)
    Foo.send(:notify_observers, :on_spec, foo)
  end

  test "can disable invidual observers by calling `disable_observers ObserverClass` on the class that includes Observing" do
    foo = Foo.new
    Foo.disable_observers FooObserver
    setup_observer_mock(BarObserver, true, foo)
    setup_observer_mock(FooObserver, false, foo)
    Foo.send(:notify_observers, :on_spec, foo)
  end

  test "can disable invidual observers by setting enabled = false on the observer class" do
    foo = Foo.new
    BarObserver.enabled = false
    setup_observer_mock(BarObserver, false, foo)
    setup_observer_mock(FooObserver, true, foo)
    Foo.send(:notify_observers, :on_spec, foo)
  end

  test "can re-enable invidual observers by calling `enable_observers :symbol` on the class that includes Observing" do
    foo = Foo.new
    Foo.disable_observers :foo_observer
    Foo.enable_observers :foo_observer
    setup_observer_mock(BarObserver, true, foo)
    setup_observer_mock(FooObserver, true, foo)
    Foo.send(:notify_observers, :on_spec, foo)
  end

  test "can re-enable invidual observers by calling `enable_observers ObserverClass` on the class that includes Observing" do
    foo = Foo.new
    Foo.disable_observers FooObserver
    Foo.enable_observers FooObserver
    setup_observer_mock(BarObserver, true, foo)
    setup_observer_mock(FooObserver, true, foo)
    Foo.send(:notify_observers, :on_spec, foo)
  end

  test "can re-enable invidual observers by setting enabled = true on the observer class" do
    foo = Foo.new
    BarObserver.enabled = false
    BarObserver.enabled = true
    setup_observer_mock(BarObserver, true, foo)
    setup_observer_mock(FooObserver, true, foo)
    Foo.send(:notify_observers, :on_spec, foo)
  end

  test "can disable all observers by calling `disable_observers :all` on the class that includes Observing" do
    foo = Foo.new
    Foo.disable_observers :all
    setup_observer_mock(BarObserver, false, foo)
    setup_observer_mock(FooObserver, false, foo)
    Foo.send(:notify_observers, :on_spec, foo)
  end

  test "can re-enable all observers by calling `enable_observers :all` on the class that includes Observing" do
    foo = Foo.new
    Foo.disable_observers :all
    Foo.enable_observers :all
    setup_observer_mock(BarObserver, true, foo)
    setup_observer_mock(FooObserver, true, foo)
    Foo.send(:notify_observers, :on_spec, foo)
  end

  test "skips nonexistent observer event" do
    foo = Foo.new
    Foo.send(:notify_observers, :whatever, foo)
  end
end
