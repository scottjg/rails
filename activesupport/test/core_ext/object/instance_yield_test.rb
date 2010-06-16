require 'active_support/core_ext/object/instance_yield'

class InstanceYieldTest < Test::Unit::TestCase
  def test_instance_exec
    assert_equal "foo", "foo".instance_yield { self }
  end

  def test_yield
    assert_equal self, "foo".instance_yield { |s| self }
  end

  def test_intance_exec_with_argument
    assert_equal 42, instance_yield(42) { |a| 42 }
    assert_equal "foo", "foo".instance_yield(10) { |a| self }
    assert_equal "foo", "foo".instance_yield(10, 20) { |a, b| self }
  end

  def test_yield_with_argument
    assert_equal 42, instance_yield(42) { |s, a| 42 }
    assert_equal self, "foo".instance_yield(10) { |s, a| self }
    assert_equal self, "foo".instance_yield(10, 20) { |s, a, b| self }
  end
end
