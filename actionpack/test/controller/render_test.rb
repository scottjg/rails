require 'abstract_unit'
require 'controller/fake_models'
require 'pathname'

module Fun
  class GamesController < ActionController::Base
    # :ported:
    def hello_world
    end

    def nested_partial_with_form_builder
      render :partial => ActionView::Helpers::FormBuilder.new(:post, nil, view_context, {})
    end
  end
end

module Quiz
  class QuestionsController < ActionController::Base
    def new
      render :partial => Quiz::Question.new("Namespaced Partial")
    end
  end
end

class TestControllerWithExtraEtags < ActionController::Base
  etag { nil  }
  etag { 'ab' }
  etag { :cde }
  etag { [:f] }
  etag { nil  }

  def fresh
    render text: "stale" if stale?(etag: '123')
  end

  def array
    render text: "stale" if stale?(etag: %w(1 2 3))
  end
end

class TestController < ActionController::Base
  protect_from_forgery

  before_action :set_variable_for_layout

  class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  end

  layout :determine_layout

  def name
    nil
  end

  private :name
  helper_method :name

  def hello_world
  end

  def hello_world_file
    render :file => File.expand_path("../../fixtures/hello", __FILE__), :formats => [:html]
  end

  def conditional_hello
    if stale?(:last_modified => Time.now.utc.beginning_of_day, :etag => [:foo, 123])
      render :action => 'hello_world'
    end
  end

  def conditional_hello_with_record
    record = Struct.new(:updated_at, :cache_key).new(Time.now.utc.beginning_of_day, "foo/123")

    if stale?(record)
      render :action => 'hello_world'
    end
  end

  def conditional_hello_with_public_header
    if stale?(:last_modified => Time.now.utc.beginning_of_day, :etag => [:foo, 123], :public => true)
      render :action => 'hello_world'
    end
  end

  def conditional_hello_with_public_header_with_record
    record = Struct.new(:updated_at, :cache_key).new(Time.now.utc.beginning_of_day, "foo/123")

    if stale?(record, :public => true)
      render :action => 'hello_world'
    end
  end

  def conditional_hello_with_public_header_and_expires_at
    expires_in 1.minute
    if stale?(:last_modified => Time.now.utc.beginning_of_day, :etag => [:foo, 123], :public => true)
      render :action => 'hello_world'
    end
  end

  def conditional_hello_with_expires_in
    expires_in 60.1.seconds
    render :action => 'hello_world'
  end

  def conditional_hello_with_expires_in_with_public
    expires_in 1.minute, :public => true
    render :action => 'hello_world'
  end

  def conditional_hello_with_expires_in_with_must_revalidate
    expires_in 1.minute, :must_revalidate => true
    render :action => 'hello_world'
  end

  def conditional_hello_with_expires_in_with_public_and_must_revalidate
    expires_in 1.minute, :public => true, :must_revalidate => true
    render :action => 'hello_world'
  end

  def conditional_hello_with_expires_in_with_public_with_more_keys
    expires_in 1.minute, :public => true, 's-maxage' => 5.hours
    render :action => 'hello_world'
  end

  def conditional_hello_with_expires_in_with_public_with_more_keys_old_syntax
    expires_in 1.minute, :public => true, :private => nil, 's-maxage' => 5.hours
    render :action => 'hello_world'
  end

  def conditional_hello_with_expires_now
    expires_now
    render :action => 'hello_world'
  end

  def conditional_hello_with_cache_control_headers
    response.headers['Cache-Control'] = 'no-transform'
    expires_now
    render :action => 'hello_world'
  end

  def conditional_hello_with_bangs
    render :action => 'hello_world'
  end
  before_action :handle_last_modified_and_etags, :only=>:conditional_hello_with_bangs

  def handle_last_modified_and_etags
    fresh_when(:last_modified => Time.now.utc.beginning_of_day, :etag => [ :foo, 123 ])
  end

  # :ported:
  def render_hello_world
    render :template => "test/hello_world"
  end

  def render_hello_world_with_last_modified_set
    response.last_modified = Date.new(2008, 10, 10).to_time
    render :template => "test/hello_world"
  end

  # :ported: compatibility
  def render_hello_world_with_forward_slash
    render :template => "/test/hello_world"
  end

  # :ported:
  def render_template_in_top_directory
    render :template => 'shared'
  end

  # :deprecated:
  def render_template_in_top_directory_with_slash
    render :template => '/shared'
  end

  # :ported:
  def render_hello_world_from_variable
    @person = "david"
    render :text => "hello #{@person}"
  end

  # :ported:
  def render_action_hello_world
    render :action => "hello_world"
  end

  def render_action_upcased_hello_world
    render :action => "Hello_world"
  end

  def render_action_hello_world_as_string
    render "hello_world"
  end

  def render_action_hello_world_with_symbol
    render :action => :hello_world
  end

  # :ported:
  def render_text_hello_world
    render :text => "hello world"
  end

  # :ported:
  def render_text_hello_world_with_layout
    @variable_for_layout = ", I am here!"
    render :text => "hello world", :layout => true
  end

  def hello_world_with_layout_false
    render :layout => false
  end

  # :ported:
  def render_file_with_instance_variables
    @secret = 'in the sauce'
    path = File.join(File.dirname(__FILE__), '../fixtures/test/render_file_with_ivar')
    render :file => path
  end

  # :ported:
  def render_file_as_string_with_instance_variables
    @secret = 'in the sauce'
    path = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/test/render_file_with_ivar'))
    render path
  end

  # :ported:
  def render_file_not_using_full_path
    @secret = 'in the sauce'
    render :file => 'test/render_file_with_ivar'
  end

  def render_file_not_using_full_path_with_dot_in_path
    @secret = 'in the sauce'
    render :file => 'test/dot.directory/render_file_with_ivar'
  end

  def render_file_using_pathname
    @secret = 'in the sauce'
    render :file => Pathname.new(File.dirname(__FILE__)).join('..', 'fixtures', 'test', 'dot.directory', 'render_file_with_ivar')
  end

  def render_file_from_template
    @secret = 'in the sauce'
    @path = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/test/render_file_with_ivar'))
  end

  def render_file_with_locals
    path = File.join(File.dirname(__FILE__), '../fixtures/test/render_file_with_locals')
    render :file => path, :locals => {:secret => 'in the sauce'}
  end

  def render_file_as_string_with_locals
    path = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/test/render_file_with_locals'))
    render path, :locals => {:secret => 'in the sauce'}
  end

  def accessing_request_in_template
    render :inline =>  "Hello: <%= request.host %>"
  end

  def accessing_logger_in_template
    render :inline =>  "<%= logger.class %>"
  end

  def accessing_action_name_in_template
    render :inline =>  "<%= action_name %>"
  end

  def accessing_controller_name_in_template
    render :inline =>  "<%= controller_name %>"
  end

  # :ported:
  def render_custom_code
    render :text => "hello world", :status => 404
  end

  # :ported:
  def render_text_with_nil
    render :text => nil
  end

  # :ported:
  def render_text_with_false
    render :text => false
  end

  def render_text_with_resource
    render :text => Customer.new("David")
  end

  # :ported:
  def render_nothing_with_appendix
    render :text => "appended"
  end

  # This test is testing 3 things:
  #   render :file in AV      :ported:
  #   render :template in AC  :ported:
  #   setting content type
  def render_xml_hello
    @name = "David"
    render :template => "test/hello"
  end

  def render_xml_hello_as_string_template
    @name = "David"
    render "test/hello"
  end

  def render_line_offset
    render :inline => '<% raise %>', :locals => {:foo => 'bar'}
  end

  def heading
    head :ok
  end

  def greeting
    # let's just rely on the template
  end

  # :ported:
  def blank_response
    render :text => ' '
  end

  # :ported:
  def layout_test
    render :action => "hello_world"
  end

  # :ported:
  def builder_layout_test
    @name = nil
    render :action => "hello", :layout => "layouts/builder"
  end

  # :move: test this in Action View
  def builder_partial_test
    render :action => "hello_world_container"
  end

  # :ported:
  def partials_list
    @test_unchanged = 'hello'
    @customers = [ Customer.new("david"), Customer.new("mary") ]
    render :action => "list"
  end

  def partial_only
    render :partial => true
  end

  def hello_in_a_string
    @customers = [ Customer.new("david"), Customer.new("mary") ]
    render :text => "How's there? " + render_to_string(:template => "test/list")
  end

  def accessing_params_in_template
    render :inline => "Hello: <%= params[:name] %>"
  end

  def accessing_local_assigns_in_inline_template
    name = params[:local_name]
    render :inline => "<%= 'Goodbye, ' + local_name %>",
           :locals => { :local_name => name }
  end

  def render_implicit_html_template_from_xhr_request
  end

  def render_implicit_js_template_without_layout
  end

  def formatted_html_erb
  end

  def formatted_xml_erb
  end

  def render_to_string_test
    @foo = render_to_string :inline => "this is a test"
  end

  def default_render
    @alternate_default_render ||= nil
    if @alternate_default_render
      @alternate_default_render.call
    else
      super
    end
  end

  def render_action_hello_world_as_symbol
    render :action => :hello_world
  end

  def layout_test_with_different_layout
    render :action => "hello_world", :layout => "standard"
  end

  def layout_test_with_different_layout_and_string_action
    render "hello_world", :layout => "standard"
  end

  def layout_test_with_different_layout_and_symbol_action
    render :hello_world, :layout => "standard"
  end

  def rendering_without_layout
    render :action => "hello_world", :layout => false
  end

  def layout_overriding_layout
    render :action => "hello_world", :layout => "standard"
  end

  def rendering_nothing_on_layout
    render :nothing => true
  end

  def render_to_string_with_assigns
    @before = "i'm before the render"
    render_to_string :text => "foo"
    @after = "i'm after the render"
    render :template => "test/hello_world"
  end

  def render_to_string_with_exception
    render_to_string :file => "exception that will not be caught - this will certainly not work"
  end

  def render_to_string_with_caught_exception
    @before = "i'm before the render"
    begin
      render_to_string :file => "exception that will be caught- hope my future instance vars still work!"
    rescue
    end
    @after = "i'm after the render"
    render :template => "test/hello_world"
  end

  def accessing_params_in_template_with_layout
    render :layout => true, :inline =>  "Hello: <%= params[:name] %>"
  end

  # :ported:
  def render_with_explicit_template
    render :template => "test/hello_world"
  end

  def render_with_explicit_unescaped_template
    render :template => "test/h*llo_world"
  end

  def render_with_explicit_escaped_template
    render :template => "test/hello,world"
  end

  def render_with_explicit_string_template
    render "test/hello_world"
  end

  # :ported:
  def render_with_explicit_template_with_locals
    render :template => "test/render_file_with_locals", :locals => { :secret => 'area51' }
  end

  # :ported:
  def double_render
    render :text => "hello"
    render :text => "world"
  end

  def double_redirect
    redirect_to :action => "double_render"
    redirect_to :action => "double_render"
  end

  def render_and_redirect
    render :text => "hello"
    redirect_to :action => "double_render"
  end

  def render_to_string_and_render
    @stuff = render_to_string :text => "here is some cached stuff"
    render :text => "Hi web users! #{@stuff}"
  end

  def render_to_string_with_inline_and_render
    render_to_string :inline => "<%= 'dlrow olleh'.reverse %>"
    render :template => "test/hello_world"
  end

  def rendering_with_conflicting_local_vars
    @name = "David"
    render :action => "potential_conflicts"
  end

  def hello_world_from_rxml_using_action
    render :action => "hello_world_from_rxml", :handlers => [:builder]
  end

  # :deprecated:
  def hello_world_from_rxml_using_template
    render :template => "test/hello_world_from_rxml", :handlers => [:builder]
  end

  def action_talk_to_layout
    # Action template sets variable that's picked up by layout
  end

  # :addressed:
  def render_text_with_assigns
    @hello = "world"
    render :text => "foo"
  end

  def yield_content_for
    render :action => "content_for", :layout => "yield"
  end

  def render_content_type_from_body
    response.content_type = Mime::RSS
    render :text => "hello world!"
  end

  def head_created
    head :created
  end

  def head_created_with_application_json_content_type
    head :created, :content_type => "application/json"
  end

  def head_ok_with_image_png_content_type
    head :ok, :content_type => "image/png"
  end

  def head_with_location_header
    head :location => "/foo"
  end

  def head_with_location_object
    head :location => Customer.new("david", 1)
  end

  def head_with_symbolic_status
    head :status => params[:status].intern
  end

  def head_with_integer_status
    head :status => params[:status].to_i
  end

  def head_with_string_status
    head :status => params[:status]
  end

  def head_with_custom_header
    head :x_custom_header => "something"
  end

  def head_with_www_authenticate_header
    head 'WWW-Authenticate' => 'something'
  end

  def head_with_status_code_first
    head :forbidden, :x_custom_header => "something"
  end

  def render_using_layout_around_block
    render :action => "using_layout_around_block"
  end

  def render_using_layout_around_block_in_main_layout_and_within_content_for_layout
    render :action => "using_layout_around_block", :layout => "layouts/block_with_layout"
  end

  def partial_formats_html
    render :partial => 'partial', :formats => [:html]
  end

  def partial
    render :partial => 'partial'
  end

  def partial_html_erb
    render :partial => 'partial_html_erb'
  end

  def render_to_string_with_partial
    @partial_only = render_to_string :partial => "partial_only"
    @partial_with_locals = render_to_string :partial => "customer", :locals => { :customer => Customer.new("david") }
    render :template => "test/hello_world"
  end

  def render_to_string_with_template_and_html_partial
    @text = render_to_string :template => "test/with_partial", :formats => [:text]
    @html = render_to_string :template => "test/with_partial", :formats => [:html]
    render :template => "test/with_html_partial"
  end

  def render_to_string_and_render_with_different_formats
    @html = render_to_string :template => "test/with_partial", :formats => [:html]
    render :template => "test/with_partial", :formats => [:text]
  end

  def render_template_within_a_template_with_other_format
    render  :template => "test/with_xml_template",
            :formats  => [:html],
            :layout   => "with_html_partial"
  end

  def partial_with_counter
    render :partial => "counter", :locals => { :counter_counter => 5 }
  end

  def partial_with_locals
    render :partial => "customer", :locals => { :customer => Customer.new("david") }
  end

  def partial_with_form_builder
    render :partial => ActionView::Helpers::FormBuilder.new(:post, nil, view_context, {})
  end

  def partial_with_form_builder_subclass
    render :partial => LabellingFormBuilder.new(:post, nil, view_context, {})
  end

  def partial_collection
    render :partial => "customer", :collection => [ Customer.new("david"), Customer.new("mary") ]
  end

  def partial_collection_with_as
    render :partial => "customer_with_var", :collection => [ Customer.new("david"), Customer.new("mary") ], :as => :customer
  end

  def partial_collection_with_counter
    render :partial => "customer_counter", :collection => [ Customer.new("david"), Customer.new("mary") ]
  end

  def partial_collection_with_as_and_counter
    render :partial => "customer_counter_with_as", :collection => [ Customer.new("david"), Customer.new("mary") ], :as => :client
  end

  def partial_collection_with_locals
    render :partial => "customer_greeting", :collection => [ Customer.new("david"), Customer.new("mary") ], :locals => { :greeting => "Bonjour" }
  end

  def partial_collection_with_spacer
    render :partial => "customer", :spacer_template => "partial_only", :collection => [ Customer.new("david"), Customer.new("mary") ]
  end

  def partial_collection_with_spacer_which_uses_render
    render :partial => "customer", :spacer_template => "partial_with_partial", :collection => [ Customer.new("david"), Customer.new("mary") ]
  end

  def partial_collection_shorthand_with_locals
    render :partial => [ Customer.new("david"), Customer.new("mary") ], :locals => { :greeting => "Bonjour" }
  end

  def partial_collection_shorthand_with_different_types_of_records
    render :partial => [
        BadCustomer.new("mark"),
        GoodCustomer.new("craig"),
        BadCustomer.new("john"),
        GoodCustomer.new("zach"),
        GoodCustomer.new("brandon"),
        BadCustomer.new("dan") ],
      :locals => { :greeting => "Bonjour" }
  end

  def empty_partial_collection
    render :partial => "customer", :collection => []
  end

  def partial_collection_shorthand_with_different_types_of_records_with_counter
    partial_collection_shorthand_with_different_types_of_records
  end

  def missing_partial
    render :partial => 'thisFileIsntHere'
  end

  def partial_with_hash_object
    render :partial => "hash_object", :object => {:first_name => "Sam"}
  end

  def partial_with_nested_object
    render :partial => "quiz/questions/question", :object => Quiz::Question.new("first")
  end

  def partial_with_nested_object_shorthand
    render Quiz::Question.new("first")
  end

  def partial_hash_collection
    render :partial => "hash_object", :collection => [ {:first_name => "Pratik"}, {:first_name => "Amy"} ]
  end

  def partial_hash_collection_with_locals
    render :partial => "hash_greeting", :collection => [ {:first_name => "Pratik"}, {:first_name => "Amy"} ], :locals => { :greeting => "Hola" }
  end

  def partial_with_implicit_local_assignment
    @customer = Customer.new("Marcel")
    render :partial => "customer"
  end

  def render_call_to_partial_with_layout
    render :action => "calling_partial_with_layout"
  end

  def render_call_to_partial_with_layout_in_main_layout_and_within_content_for_layout
    render :action => "calling_partial_with_layout", :layout => "layouts/partial_with_layout"
  end

  before_action only: :render_with_filters do
    request.format = :xml
  end

  # Ensure that the before filter is executed *before* self.formats is set.
  def render_with_filters
    render :action => :formatted_xml_erb
  end

  private

    def set_variable_for_layout
      @variable_for_layout = nil
    end

    def determine_layout
      case action_name
        when "hello_world", "layout_test", "rendering_without_layout",
             "rendering_nothing_on_layout", "render_text_hello_world",
             "render_text_hello_world_with_layout",
             "hello_world_with_layout_false",
             "partial_only", "accessing_params_in_template",
             "accessing_params_in_template_with_layout",
             "render_with_explicit_template",
             "render_with_explicit_string_template",
             "update_page", "update_page_with_instance_variables"

          "layouts/standard"
        when "action_talk_to_layout", "layout_overriding_layout"
          "layouts/talk_from_action"
        when "render_implicit_html_template_from_xhr_request"
          (request.xhr? ? 'layouts/xhr' : 'layouts/standard')
      end
    end
end

class MetalTestController < ActionController::Metal
  include AbstractController::Rendering
  include ActionView::Rendering
  include ActionController::Rendering

  def accessing_logger_in_template
    render :inline =>  "<%= logger.class %>"
  end
end

class ExpiresInRenderTest < ActionController::TestCase
  tests TestController

  def setup
    @request.host = "www.nextangle.com"
  end

  def test_expires_in_header
    get :conditional_hello_with_expires_in
    assert_equal "max-age=60, private", @response.headers["Cache-Control"]
  end

  def test_expires_in_header_with_public
    get :conditional_hello_with_expires_in_with_public
    assert_equal "max-age=60, public", @response.headers["Cache-Control"]
  end

  def test_expires_in_header_with_must_revalidate
    get :conditional_hello_with_expires_in_with_must_revalidate
    assert_equal "max-age=60, private, must-revalidate", @response.headers["Cache-Control"]
  end

  def test_expires_in_header_with_public_and_must_revalidate
    get :conditional_hello_with_expires_in_with_public_and_must_revalidate
    assert_equal "max-age=60, public, must-revalidate", @response.headers["Cache-Control"]
  end

  def test_expires_in_header_with_additional_headers
    get :conditional_hello_with_expires_in_with_public_with_more_keys
    assert_equal "max-age=60, public, s-maxage=18000", @response.headers["Cache-Control"]
  end

  def test_expires_in_old_syntax
    get :conditional_hello_with_expires_in_with_public_with_more_keys_old_syntax
    assert_equal "max-age=60, public, s-maxage=18000", @response.headers["Cache-Control"]
  end

  def test_expires_now
    get :conditional_hello_with_expires_now
    assert_equal "no-cache", @response.headers["Cache-Control"]
  end

  def test_expires_now_with_cache_control_headers
    get :conditional_hello_with_cache_control_headers
    assert_match(/no-cache/, @response.headers["Cache-Control"])
    assert_match(/no-transform/, @response.headers["Cache-Control"])
  end

  def test_date_header_when_expires_in
    time = Time.mktime(2011,10,30)
    Time.stubs(:now).returns(time)
    get :conditional_hello_with_expires_in
    assert_equal Time.now.httpdate, @response.headers["Date"]
  end
end

class LastModifiedRenderTest < ActionController::TestCase
  tests TestController

  def setup
    super
    @request.host = "www.nextangle.com"
    @last_modified = Time.now.utc.beginning_of_day.httpdate
  end

  def test_responds_with_last_modified
    get :conditional_hello
    assert_equal @last_modified, @response.headers['Last-Modified']
  end

  def test_request_not_modified
    @request.if_modified_since = @last_modified
    get :conditional_hello
    assert_equal 304, @response.status.to_i
    assert @response.body.blank?
    assert_equal @last_modified, @response.headers['Last-Modified']
  end

  def test_request_not_modified_but_etag_differs
    @request.if_modified_since = @last_modified
    @request.if_none_match = "234"
    get :conditional_hello
    assert_response :success
  end

  def test_request_modified
    @request.if_modified_since = 'Thu, 16 Jul 2008 00:00:00 GMT'
    get :conditional_hello
    assert_equal 200, @response.status.to_i
    assert @response.body.present?
    assert_equal @last_modified, @response.headers['Last-Modified']
  end


  def test_responds_with_last_modified_with_record
    get :conditional_hello_with_record
    assert_equal @last_modified, @response.headers['Last-Modified']
  end

  def test_request_not_modified_with_record
    @request.if_modified_since = @last_modified
    get :conditional_hello_with_record
    assert_equal 304, @response.status.to_i
    assert @response.body.blank?
    assert_equal @last_modified, @response.headers['Last-Modified']
  end

  def test_request_not_modified_but_etag_differs_with_record
    @request.if_modified_since = @last_modified
    @request.if_none_match = "234"
    get :conditional_hello_with_record
    assert_response :success
  end

  def test_request_modified_with_record
    @request.if_modified_since = 'Thu, 16 Jul 2008 00:00:00 GMT'
    get :conditional_hello_with_record
    assert_equal 200, @response.status.to_i
    assert @response.body.present?
    assert_equal @last_modified, @response.headers['Last-Modified']
  end

  def test_request_with_bang_gets_last_modified
    get :conditional_hello_with_bangs
    assert_equal @last_modified, @response.headers['Last-Modified']
    assert_response :success
  end

  def test_request_with_bang_obeys_last_modified
    @request.if_modified_since = @last_modified
    get :conditional_hello_with_bangs
    assert_response :not_modified
  end

  def test_last_modified_works_with_less_than_too
    @request.if_modified_since = 5.years.ago.httpdate
    get :conditional_hello_with_bangs
    assert_response :success
  end
end

class EtagRenderTest < ActionController::TestCase
  tests TestControllerWithExtraEtags

  def setup
    super
    @request.host = "www.nextangle.com"
  end

  def test_multiple_etags
    @request.if_none_match = etag(["123", 'ab', :cde, [:f]])
    get :fresh
    assert_response :not_modified

    @request.if_none_match = %("nomatch")
    get :fresh
    assert_response :success
  end

  def test_array
    @request.if_none_match = etag([%w(1 2 3), 'ab', :cde, [:f]])
    get :array
    assert_response :not_modified

    @request.if_none_match = %("nomatch")
    get :array
    assert_response :success
  end

  def etag(record)
    Digest::MD5.hexdigest(ActiveSupport::Cache.expand_cache_key(record)).inspect
  end
end


class MetalRenderTest < ActionController::TestCase
  tests MetalTestController

  def test_access_to_logger_in_view
    get :accessing_logger_in_template
    assert_equal "NilClass", @response.body
  end
end
