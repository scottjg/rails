require 'abstract_unit'

class RoutingConcernsTest < ActionDispatch::IntegrationTest
  Routes = ActionDispatch::Routing::RouteSet.new.tap do |app|
    app.draw do
      concern :commentable do
        resources :comments
      end

      concern :image_attachable do
        resources :images, only: :index
      end

      resources :posts, concerns: [:commentable, :image_attachable] do
        resource :video, concerns: :commentable
      end

      resource :picture, concerns: :commentable do
        resources :posts, concerns: :commentable
      end

      scope "/videos" do
        concerns :commentable
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

  test "accessing concern from resources with more than one concern" do
    get "/posts/1/images"
    assert_equal "200", @response.code
    assert_equal "/posts/1/images", post_images_path(post_id: 1)
  end

  test "accessing concern from resources using only option" do
    get "/posts/1/image/1"
    assert_equal "404", @response.code
  end

  test "accessing concern from a scope" do
    get "/videos/comments"
    assert_equal "200", @response.code
  end

  test "with an invalid concern name" do
    e = assert_raise ArgumentError do
      ActionDispatch::Routing::RouteSet.new.tap do |app|
        app.draw do
          resources :posts, concerns: :foo
        end
      end
    end

    assert_equal "No concern named foo was found!", e.message
  end
end
