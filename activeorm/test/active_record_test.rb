require 'helper'

uses_active_record('ActiveRecordTest') do

  class Page < ActiveRecord::Base
    validate_presence_of :name
  end

  ActiveOrm.register "ActiveRecord::Base", ActiveOrm::Proxies::ActiveRecordProxy

  class ActiveRecordTest < Test::Unit::TestCase
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