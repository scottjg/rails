require 'helper'

class AbstractProxyTest < Test::Unit::TestCase
  def setup
    @model = OrmModel.new
    @proxy = ActiveOrm.new @model
  end

  def teardown
  end

  def test_new_record?
    assert @proxy.new_record?
    @model.save
    assert !@proxy.new_record?
  end
  
  def test_valid?
    assert @proxy.valid?
    @model.invalidate
    assert !@proxy.valid?
  end
end