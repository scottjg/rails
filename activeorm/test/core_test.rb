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

  def test_proxyable?
    assert ActiveOrm.proxyable? @model
  end
  
  def test_proxyable_for_module
    ActiveOrm.use :klass => OrmModule, :proxy => ActiveOrm::Proxies::TestOrmProxy
    assert ActiveOrm.proxyable? @modulemodel
  end
  
  def test_failing_proxyable?
    assert !ActiveOrm.proxyable?(FailingModel.new)
  end
  
  def test_proxy
    assert_equal @model, (ActiveOrm.proxy @model).model
  end
  
  def test_subclass_proxy
    assert ActiveOrm.proxyable?(SubclassModel.new)
  end
    
  # Cache was a source of a memory leak, good idea though...
  #def test_proxy_uses_cache
  #  proxy = ActiveOrm.proxy @model
  #  class << proxy
  #    def am_using_cache; end
  #  end
  #  cached = ActiveOrm.proxy @model
  #  assert cached.respond_to? :am_using_cache
  #end

end