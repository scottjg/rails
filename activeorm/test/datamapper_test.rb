require 'helper'

uses_datamapper('DatamapperTest') do
  DataMapper.setup(:default, 'sqlite3::memory:')

  class Page
    include DataMapper::Resource
  
    property :id,   Serial
    property :name, String
    property :body, String
  
    validates_present :name
  end

  Page.auto_migrate!

  ActiveOrm.register "DataMapper::Resource", ActiveOrm::Proxies::DataMapperProxy
  
  class DatamapperTest < Test::Unit::TestCase
    def setup
      @page = Page.new :name => "test"
      @invalid_page = Page.new
      @proxy_page = ActiveOrm.new @page    
      @proxy_invalid_page = ActiveOrm.new @invalid_page
    end
  
    def test_proxyable?
      assert ActiveOrm.proxyable? @page
    end
  
    def test_new_record?
      assert @proxy_page.new_record?
      @page.save
      assert !@proxy_page.new_record?
    end
  
    def test_valid?
      assert @proxy_page.valid?
      assert !@proxy_invalid_page.valid?
    end

  end
end