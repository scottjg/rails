require 'abstract_unit'

module TestGenerationPrefix
  class WithMountedEngine < ActionDispatch::IntegrationTest
    require 'rack/test'
    include Rack::Test::Methods

    class BlogEngine
      def self.routes
        @routes ||= begin
          routes = ActionDispatch::Routing::RouteSet.new
          routes.draw do
            match "/posts/:id", :to => "inside_engine_generating#index", :as => :post
            match "/bare_url_for", :to => "inside_engine_generating#bare_url_for", :as => :bare_url_for
          end

          routes
        end
      end

      def self.call(env)
        env['action_dispatch.routes'] = routes
        routes.call(env)
      end
    end

    class RailsApplication
      def self.routes
        @routes ||= begin
          routes = ActionDispatch::Routing::RouteSet.new
          routes.draw do
            scope "/:omg", :omg => "awesome" do
              mount BlogEngine => "/blog"
            end
            match "/generate", :to => "outside_engine_generating#index"
            root :to => "outside_engine_generating#index"
          end

          routes
        end
      end

      def self.call(env)
        env['action_dispatch.routes'] = routes

        # the next to values should be set only in application
        env['ORIGINAL_SCRIPT_NAME'] = env['SCRIPT_NAME']
        env['action_dispatch.parent_routes'] = routes
        routes.call(env)
      end
    end

    class ::InsideEngineGeneratingController < ActionController::Base
      include BlogEngine.routes.url_helpers
      def index
        render :text => post_path(:id => params[:id])
      end

      def bare_url_for
        path = url_for( :routes => RailsApplication.routes,
                        :controller => "outside_engine_generating", 
                        :action => "index",
                        :only_path => true)
        render :text => path
      end
    end

    class ::OutsideEngineGeneratingController < ActionController::Base
      include BlogEngine.routes.url_helpers
      def index
        render :text => post_path(:id => 1)
      end
    end

    class Foo
      include ActionDispatch::Routing::UrlFor
      include BlogEngine.routes.url_helpers

      def foo
        post_path(42)
      end
    end

    class Bar
      include ActionDispatch::Routing::UrlFor
      include RailsApplication.routes.url_helpers

      def bar
        root_path
      end
    end

    RailsApplication.routes # force draw
    include BlogEngine.routes.url_helpers

    def app
      RailsApplication
    end

    def setup
      RailsApplication.routes.default_url_options = {}
    end

    test "generating URL with prefix" do
      assert_equal "/awesome/blog/posts/1", post_path(:id => 1)
    end

    test "use SCRIPT_NAME inside the engine" do
      get "/pure-awesomness/blog/posts/1"
      assert_equal "/pure-awesomness/blog/posts/1", last_response.body
    end

    test "prepend prefix outside the engine" do
      RailsApplication.routes.default_url_options = {:script_name => "/something"}
      get "/generate", {}, 'SCRIPT_NAME' => "/something"
      assert_equal "/something/awesome/blog/posts/1", last_response.body
    end

    test "generating urls with options for both prefix and named_route" do
      assert_equal "/pure-awesomness/blog/posts/3", post_path(:id => 3, :omg => "pure-awesomness")
    end

    test "generating urls with url_for should prepend the prefix" do
      path = BlogEngine.routes.url_for(:omg => 'omg', :controller => "inside_engine_generating", :action => "index", :id => 1, :only_path => true)
      assert_equal "/omg/blog/posts/1", path
    end

    test "generating urls from a regular class" do
      assert_equal "/awesome/blog/posts/42", Foo.new.foo
    end

    test "passing :routes to url_for to change current routes" do
      RailsApplication.routes.default_url_options = {:script_name => "/something"}
      get "/pure-awesomness/blog/bare_url_for", {}, 'SCRIPT_NAME' => "/something"
      assert_equal "/something/generate", last_response.body
    end

    test "using default_url_options[:script_name] in regular classes" do
      RailsApplication.routes.default_url_options = {:script_name => "/something"}
      assert_equal "/something/", Bar.new.bar
    end
  end
end
