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

  ActiveORM.use :orm => 'data_mapper'
  
  class DatamapperTest < Test::Unit::TestCase
    def setup
      @page = Page.new :name => "test"
      @invalid_page = Page.new
      @proxy_page = ActiveORM.for @page    
      @proxy_invalid_page = ActiveORM.for @invalid_page
    end
  
    def test_supports?
      assert ActiveORM.supports?(@page)
    end
  
    def test_new?
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