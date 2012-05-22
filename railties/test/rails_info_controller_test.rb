require 'abstract_unit'

module ActionController
  class Base
    include ActionController::Testing
  end
end

class InfoControllerTest < ActionController::TestCase
  tests Rails::InfoController

  def setup
    Rails.application.routes.draw do
      get '/rails/info/:id' => "rails/info#show"
    end
    @request.stubs(:local? => true)
    Rails.application.config.stubs(:consider_all_requests_local => false)
    @routes = Rails.application.routes

    Rails::InfoController.send(:include, @routes.url_helpers)
  end

  test "info controller does not allow remote requests" do
    @request.stubs(:local? => false)
    get :show, :id => :properties
    assert_response :forbidden
  end

  test "info controller renders an error message when request was forbidden" do
    @request.stubs(:local? => false)
    get :show, :id => :properties
    assert_select 'p'
  end

  test "info controller allows requests when all requests are considered local" do
    @request.stubs(:local? => false)
    Rails.application.config.stubs(:consider_all_requests_local => true)
    get :show, :id => :properties
    assert_response :success
  end

  test "info controller allows local requests" do
    get :show, :id => :properties
    assert_response :success
  end

  test "info controller renders a table with properties" do
    get :show, :id => :properties
    assert_select 'table'
  end

  test "info controller renders with routes" do
    get :show, :id => :routes
    assert_select 'pre'
  end

end
