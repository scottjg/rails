require 'helper'

class AbstractProxyTest < Test::Unit::TestCase
  def setup
    @model = OrmModel.new
    @proxy = ActiveOrm::Core.proxy @model
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
  
  def test_proxy_uses_cache
    class << @proxy
      def am_using_cache; end
    end
    cached = ActiveOrm::Core.proxy @model
    assert cached.respond_to? :am_using_cache
  end
end