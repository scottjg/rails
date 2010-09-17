require 'abstract_unit'

module RenderPartial

  class BasicController < ActionController::Base

    self.view_paths = [ActionView::FixtureResolver.new(
      "render_partial/basic/_basic.html.erb"    => "BasicPartial!",
      "render_partial/basic/basic.html.erb"      => "<%= @test_unchanged = 'goodbye' %><%= render :partial => 'basic' %><%= @test_unchanged %>",
      "render_partial/basic/overriden.html.erb"    => "<%= @test_unchanged = 'goodbye' %><%= render :partial => 'overriden' %><%= @test_unchanged %>",
      "render_partial/basic/_overriden.html.erb"    => "ParentPartial!",
      "render_partial/child/_overriden.html.erb"    => "OverridenPartial!"
    )]

    def changing
      @test_unchanged = 'hello'
      render :action => "basic"
    end

    def overriden
      @test_unchanged = 'hello'
    end
  end
  
  class ChildController < BasicController; end

  class TestPartial < Rack::TestCase
    testing BasicController

    test "rendering a partial in ActionView doesn't pull the ivars again from the controller" do
      get :changing
      assert_response("goodbyeBasicPartial!goodbye")
    end
  end

  class TestInheritedPartial < Rack::TestCase
    testing ChildController

    test "partial from parent controller gets picked if missing in child one" do
      get :changing
      assert_response("goodbyeBasicPartial!goodbye")
    end

    test "partial from child controller gets picked" do
      get :overriden
      assert_response("goodbyeOverridenPartial!goodbye")
    end
  end

end
