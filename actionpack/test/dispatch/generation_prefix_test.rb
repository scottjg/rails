require 'abstract_unit'

module TestGenerationPrefix
  class WithMountPoint < ActionDispatch::IntegrationTest
    Router = ActionDispatch::Routing::RouteSet.new
    Router.generation_scope = ["/:omg/blog", {:omg => "awesome"}]

    Router.draw do
      match "/posts/:id", :to => "my_route_generating#index", :as => :post
    end

    class ::MyRouteGeneratingController < ActionController::Base
      include Router.url_helpers
      def index
        render :text => post_path(:id => params[:id])
      end
    end

    include Router.url_helpers

    def _router
      Router
    end

    def app
      Router
    end

    test "generating URLS with given prefix" do
      assert_equal "/awesome/blog/posts/1", post_path(:id => 1)
    end

    test "generating URLS with SCRIPT_NAME" do
      get "/posts/1", {}, 'SCRIPT_NAME' => '/pure-awesomness/blog'
      assert_equal "/pure-awesomness/blog/posts/1", response.body
    end

    test "generating urls with options for both prefix and named_route" do
      assert_equal "/pure-awesomness/blog/posts/3", post_path(:id => 3, :omg => "pure-awesomness")
    end
  end
end
