require 'active_support/core_ext/object/instance_yield'

class InstanceYieldTest < Test::Unit::TestCase
  def test_instance_eval
    assert_equal "foo", "foo".instance_yield { self }
  end

  def test_yield
    assert_equal self, "foo".instance_yield { |s| self }
  end
end
