require 'abstract_unit'

class CommentsController < ActionController::Base
  def index
    head :ok
  end
end

class RoutingConcernsTest < ActionDispatch::IntegrationTest
  Routes = ActionDispatch::Routing::RouteSet.new.tap do |app|
    app.draw do
      concern :commentable do
        resources :comments
      end

      resources :posts, concerns: :commentable
      resource  :picture,  concerns: :commentable
    end
  end

  include Routes.url_helpers
  def app; Routes end

  test "accessing concern from resources" do
    get "/posts/1/comments"
    assert_equal "200", @response.code
    assert_equal "/posts/1/comments", post_comments_path(post_id: 1)
  end

  test "accessing concern from resource" do
    get "/picture/comments"
    assert_equal "200", @response.code
    assert_equal "/picture/comments", picture_comments_path
  end
end
