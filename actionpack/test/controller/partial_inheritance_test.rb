require File.dirname(__FILE__) + '/../abstract_unit'

class ParentTestController < ActionController::Base
  def self.controller_name; "test"; end
  def self.controller_path; "test"; end
  
  def do_partial
    render :partial => params[:partialname]
  end
  
end

class InheritedTestController < ParentTestController
  def self.controller_name; "test_inherited"; end
  def self.controller_path; "test/inheritance"; end
  
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
  
  def test_inherited
    get :do_partial, :partialname => 'partial_parent'
    assert_equal "_partial parent", @response.body
  end
  
  def test_inherited_thru_template
    get :template_to_partial, :partialname => 'partial_parent'
    assert_equal "_partial parent", @response.body
  end

  def test_overridden
    get :do_partial, :partialname => 'partial_overridden'
    assert_equal "_partial_overridden inherited", @response.body
  end
  
  def test_overridden_thru_template
    get :template_to_partial, :partialname => 'partial_overridden'
    assert_equal "_partial_overridden inherited", @response.body
  end

end
