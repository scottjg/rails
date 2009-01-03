require 'helper'

class AbstractProxyTest < Test::Unit::TestCase
  def setup
    @model = ActiveOrm::TestOrmModel.new
    @proxy = ActiveOrm.proxy @model
  end

  def teardown
  end

  def test_new?
    assert @proxy.new?
    @model.save
    assert !@proxy.new?
  end
  
  def test_valid?
    assert @proxy.valid?
    @model.invalidate
    assert !@proxy.valid?
  end
end