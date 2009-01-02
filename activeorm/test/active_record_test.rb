require 'helper'

uses_active_record('ActiveRecordTest') do

  class Page < ActiveRecord::Base
    validate_presence_of :name
  end

  ActiveOrm.register ActiveRecord::Base, ActiveOrm::Proxies::DataMapperProxy

  class ActiveRecordTest < Test::Unit::TestCase
    def setup
      @page = Page.new :name => "test"
      @invalid_page = Page.new
      @proxy_page = ActiveOrm.proxy @page    
      @proxy_invalid_page = ActiveOrm.proxy @invalid_page
    end
  
    def test_proxyable?
      assert ActiveOrm.proxyable? @page
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
end