require 'helper'
require 'active_orm/core'

class CoreTest < Test::Unit::TestCase
  def setup
    @model = OrmModel.new
  end

  def teardown
  end

  def test_proxyable?
    assert ActiveOrm::Core.proxyable? @model
  end
  
  def test_proxy
    assert_equal @model, (ActiveOrm::Core.proxy @model).model
  end
end