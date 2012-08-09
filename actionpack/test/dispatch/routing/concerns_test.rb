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

      resources :posts, concerns: :commentable do
        resource :video, concerns: :commentable
      end

      resource :picture, concerns: :commentable do
        resources :posts, concerns: :commentable
      end
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

  test "accessing concern from nested resource" do
    get "/posts/1/video/comments"
    assert_equal "200", @response.code
    assert_equal "/posts/1/video/comments", post_video_comments_path(post_id: 1)
  end

  test "accessing concern from nested resources" do
    get "/picture/posts/1/comments"
    assert_equal "200", @response.code
    assert_equal "/picture/posts/1/comments", picture_post_comments_path(post_id: 1)
  end
end
