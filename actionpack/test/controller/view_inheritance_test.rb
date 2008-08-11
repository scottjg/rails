require File.dirname(__FILE__) + '/../abstract_unit'

class ParentTestController < ActionController::Base
  def self.controller_name; "test"; end
  def self.controller_path; "test"; end
  
  layout "layouts/standard"
  
  def hello_world
  end
  
  def overridden
  end
end

class InheritedTestController < ParentTestController
  def self.controller_name; "test_inherited"; end
  def self.controller_path; "test/inheritance"; end
  
  def another_hello_world
    render :action => :hello_world
  end
end

ParentTestController.view_paths = File.dirname(__FILE__) + "/../fixtures/"
InheritedTestController.view_paths = File.dirname(__FILE__) + "/../fixtures/"


class ViewInheritanceTest < Test::Unit::TestCase
  def setup
    @controller = InheritedTestController.new
    
    # enable a logger so that (e.g.) the benchmarking stuff runs, so we can get
    # a more accurate simulation of what happens in "real life".
    @controller.logger = Logger.new(nil)
    
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @request.host = "www.nextangle.com"
  end
  
  def test_view_inheritance
    get :hello_world
    assert_template "test/hello_world"
  end
  
  def test_view_inheritance_with_explicit_render
    get :another_hello_world
    assert_template "test/hello_world"
  end
  
  def test_view_overriding
    get :overridden
    assert_template "test/inheritance/overridden"
  end
end
