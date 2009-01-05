require 'helper'
require 'active_orm/core'


module OrmModule
end

class OrmModuleModel
  include OrmModule
  
  def initialize
    @new = true
    @valid = true
  end
  def save
    @new = false
  end
  def new_record?
    @new
  end
  def invalidate
    @valid = false
  end
  def valid?
    @valid
  end
end

class FailingModel
end

class SubclassModel < ActiveOrm::TestOrmModel
end

class CoreTest < Test::Unit::TestCase
  def setup
    @model = ActiveOrm::TestOrmModel.new
    @modulemodel = OrmModuleModel.new
  end

  def teardown
  end

  def test_supports?
    assert ActiveOrm.supports? @model
  end
  
  def test_supports_for_module
    ActiveOrm.use :klass => OrmModule, :proxy => ActiveOrm::Proxies::TestOrmProxy
    assert ActiveOrm.supports? @modulemodel
  end
  
  def test_supports_failing?
    assert !ActiveOrm.supports?(FailingModel.new)
  end
  
  def test_proxy
    assert_equal @model, (ActiveOrm.for @model).model
  end
  
  def test_subclass_proxy
    assert ActiveOrm.supports?(SubclassModel.new)
  end
end