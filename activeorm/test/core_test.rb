require 'helper'
require 'active_orm/core'


module TestModule
end

class TestModuleModel
  include TestModule
  
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

class TestFailingModel
end

class TestSubclassModel < ActiveORM::TestORMModel
end

class CoreTest < Test::Unit::TestCase
  def setup
    @model = ActiveORM::TestORMModel.new
    @modulemodel = TestModuleModel.new
  end

  def teardown
  end

  def test_supports?
    assert ActiveORM.supports? @model
  end
  
  def test_supports_for_module
    ActiveORM.use :klass => TestModuleModel, :proxy => ActiveORM::Proxies::TestORMProxy
    assert ActiveORM.supports? @modulemodel
  end
  
  def test_supports_failing?
    assert !ActiveORM.supports?(TestFailingModel.new)
  end
  
  def test_proxy
    assert_equal @model, (ActiveORM.for @model).model
  end
  
  def test_subclass_proxy
    assert ActiveORM.supports?(TestSubclassModel.new)
  end
end