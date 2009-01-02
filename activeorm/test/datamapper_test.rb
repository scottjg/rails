require 'helper'

require 'dm-core'
require 'dm-validations'
DataMapper.setup(:default, 'sqlite3::memory:')

class Page
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String
  property :body, String
  
  validates_present :name
end

Page.auto_migrate!

ActiveOrm::Core.register Page, ActiveOrm::Proxies::DataMapperProxy

class DatamapperTest < Test::Unit::TestCase
  def setup
    @page = Page.new :name => "test"
    @invalid_page = Page.new
    @proxy_page = ActiveOrm::Core.proxy @page    
    @proxy_invalid_page = ActiveOrm::Core.proxy @invalid_page
  end
  
  def test_proxyable?
    assert ActiveOrm::Core.proxyable? @page
  end
  
  def test_new?
    assert @proxy_page.new?
    @page.save
    assert !@proxy_page.new?
  end
  
  def test_valid?
    assert @proxy_page.valid?
    assert !@proxy_invalid_page.valid?
  end

end