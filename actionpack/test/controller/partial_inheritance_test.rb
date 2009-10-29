require 'abstract_unit'

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


class ViewInheritanceTest < ActionController::TestCase
  tests InheritedTestController

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
