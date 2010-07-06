require 'abstract_unit'

module TestUrlGeneration
  class MultipleRouters < ActionDispatch::IntegrationTest
    Router = ActionDispatch::Routing::RouteSet.new
    Router.draw do
      resources :articles do
        resources :comments
      end
    end

    include Router.url_helpers

    Router2 = ActionDispatch::Routing::RouteSet.new
    Router2.draw {
      resources :users
    }

    include Router2.url_helpers

    test "allow using named routes from both routers" do
      assert_equal "/articles/1/comments", article_comments_path(1)
      assert_equal "/users", users_path
    end
  end
end

