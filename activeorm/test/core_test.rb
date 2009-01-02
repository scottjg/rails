require 'helper'
require 'active_orm/core'

class FailingModel
end

class CoreTest < Test::Unit::TestCase
  def setup
    @model = OrmModel.new
    @modulemodel = OrmModuleModel.new
  end

  def teardown
  end

  def test_proxyable?
    assert ActiveOrm::Core.proxyable? @model
  end
  
  def test_proxyable_for_module
    assert ActiveOrm::Core.proxyable? @modulemodel
  end
  
  def test_failing_proxyable?
    assert !ActiveOrm::Core.proxyable?(FailingModel.new)
  end
  
  def test_proxy
    assert_equal @model, (ActiveOrm::Core.proxy @model).model
  end
  
  def test_proxy_uses_cache
    proxy = ActiveOrm::Core.proxy @model
    class << proxy
      def am_using_cache; end
    end
    cached = ActiveOrm::Core.proxy @model
    assert cached.respond_to? :am_using_cache
  end

end