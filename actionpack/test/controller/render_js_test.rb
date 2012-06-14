require 'abstract_unit'
require 'controller/fake_models'
require 'pathname'

class RenderJSTest < ActionController::TestCase
  class TestController < ActionController::Base
    protect_from_forgery

    def self.controller_path
      'test'
    end

    def render_vanilla_js_hello
      render :js => "alert('hello')"
    end

    def show_partial
      render :partial => 'partial'
    end

    def only_html
      render
    end

    def partial_only_html
      render :partial => 'partial_only_html'
    end
  end

  tests TestController

  def test_render_vanilla_js
    get :render_vanilla_js_hello
    assert_equal "alert('hello')", @response.body
    assert_equal "text/javascript", @response.content_type
  end

  def test_should_render_js_partial
    xhr :get, :show_partial, :format => 'js'
    assert_equal 'partial js', @response.body
  end

  def test_adding_html_as_fallback_to_js_is_deprecated
    assert_deprecated(/The only format passed to controller was :js/) do
      get :only_html, :format => 'js'
    end

    assert_deprecated(/The only format passed to controller was :js/) do
      get :partial_only_html, :format => 'js'
    end
  end
end
