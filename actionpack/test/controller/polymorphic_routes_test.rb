require 'abstract_unit'

class Article
  attr_reader :id
  def save; @id = 1 end
  def new_record?; @id.nil? end
  def name
    model = self.class.name.downcase
    @id.nil? ? "new #{model}" : "#{model} ##{@id}"
  end
end

class Response < Article
  def post_id; 1 end
end

class Editorial < Article
end

class Tag < Article
  def response_id; 1 end
end

# TODO: test nested models
class Response::Nested < Response; end

uses_mocha 'polymorphic URL helpers' do
  class PolymorphicRoutesTest < Test::Unit::TestCase

    include ActionController::PolymorphicRoutes

    def setup
      @article = Article.new
      @response = Response.new
      @editorial = Editorial.new
    end
  
    def test_with_record
      @article.save
      expects(:article_url).with(@article)
      polymorphic_url(@article)
    end

    def test_with_fallthrough_to_route_for_base_class
      @editorial.save
      stubs(:respond_to?).with('editorial_url').returns(false)
      stubs(:respond_to?).with('article_url').returns(true)
      expects(:article_url).with(@editorial)
      polymorphic_url(@editorial)
    end
    
    def test_with_no_matching_routes
      @editorial.save
      stubs(:respond_to?).with('article_url').returns(false)
      stubs(:respond_to?).with('editorial_url').returns(false)
      expects(:editorial_url).with(@editorial)
      polymorphic_url(@editorial)
    end
    
    def test_with_new_record
      expects(:articles_url).with()
      @article.expects(:new_record?).returns(true)
      polymorphic_url(@article)
    end
    
    def test_fallthrough_with_new_record
      @editorial.stubs(:new_record?).returns(true)
      stubs(:respond_to?).with('editorials_url').returns(false)
      stubs(:respond_to?).with('articles_url').returns(true)
      expects(:articles_url).with()
      polymorphic_url(@editorial)
    end

    def test_with_record_and_action
      expects(:new_article_url).with()
      @article.expects(:new_record?).never
      polymorphic_url(@article, :action => 'new')
    end

    def test_fallthrough_with_record_and_action
      stubs(:respond_to?).with('new_editorial_url').returns(false)
      stubs(:respond_to?).with('new_article_url').returns(true)
      expects(:new_article_url).with()
      @editorial.expects(:new_record?).never
      polymorphic_url(@editorial, :action => 'new')
    end

    def test_url_helper_prefixed_with_new
      expects(:new_article_url).with()
      new_polymorphic_url(@article)
    end

    def test_fallthrough_with_url_helper_prefixed_with_new
      stubs(:respond_to?).with('new_editorial_url').returns(false)
      stubs(:respond_to?).with('new_article_url').returns(true)
      expects(:new_article_url).with()
      new_polymorphic_url(@editorial)
    end

    def test_url_helper_prefixed_with_edit
      @article.save
      expects(:edit_article_url).with(@article)
      edit_polymorphic_url(@article)
    end

    def test_fallthrough_with_url_helper_prefixed_with_edit
      @editorial.save
      stubs(:respond_to?).with('edit_editorial_url').returns(false)
      stubs(:respond_to?).with('edit_article_url').returns(true)
      expects(:edit_article_url).with(@editorial)
      edit_polymorphic_url(@editorial)
    end

    def test_formatted_url_helper
      expects(:formatted_article_url).with(@article, :pdf)
      formatted_polymorphic_url([@article, :pdf])
    end

    def test_fallthrough_with_formatted_url_helper
      stubs(:respond_to?).with('formatted_editorial_url').returns(false)
      stubs(:respond_to?).with('formatted_article_url').returns(true)
      expects(:formatted_article_url).with(@editorial, :pdf)
      formatted_polymorphic_url([@editorial, :pdf])
    end

    def test_format_option
      @article.save
      expects(:article_url).with(@article, :pdf)
      polymorphic_url(@article, :format => :pdf)
    end

    def test_fallthrough_with_format_option
      @editorial.save
      stubs(:respond_to?).with('editorial_url').returns(false)
      stubs(:respond_to?).with('article_url').returns(true)
      expects(:article_url).with(@editorial, :pdf)
      polymorphic_url(@editorial, :format => :pdf)
    end

    def test_id_and_format_option
      @article.save
      expects(:article_url).with(:id => @article, :format => :pdf)
      polymorphic_url(:id => @article, :format => :pdf)
    end

    def test_fallthrough_with_id_and_format_option
      @editorial.save
      stubs(:respond_to?).with('editorial_url').returns(false)
      stubs(:respond_to?).with('article_url').returns(true)
      expects(:article_url).with(:id => @editorial, :format => :pdf)
      polymorphic_url(:id => @editorial, :format => :pdf)
    end

    def test_with_nested
      @response.save
      expects(:article_response_url).with(@article, @response)
      polymorphic_url([@article, @response])
    end
    
    def test_fallthrough_for_child_with_nested
      @editorial.save
      stubs(:respond_to?).with('response_editorial_url').returns(false)
      stubs(:respond_to?).with('response_article_url').returns(true)
      expects(:response_article_url).with(@response, @editorial)
      polymorphic_url([@response, @editorial])
    end

    def test_fallthrough_for_parent_with_nested #fallthrough only currently works for the targeted resource, not for parents it is nested inside
      @response.save
      stubs(:respond_to?).with('editorial_article_url').returns(false)
      stubs(:respond_to?).with('editorial_response_url').returns(false)
      expects(:editorial_response_url).with(@editorial, @response) #TODO: this should be expects(:article_response_url).with(@editorial, @response)
      polymorphic_url([@editorial, @response])
    end

    def test_with_nested_unsaved
      expects(:article_responses_url).with(@article)
      polymorphic_url([@article, @response])
    end
    
    def test_fallthrough_for_child_with_nested_unsaved
      stubs(:respond_to?).with('response_editorials_url').returns(false)
      stubs(:respond_to?).with('response_articles_url').returns(true)
      expects(:response_articles_url).with(@response)
      polymorphic_url([@response, @editorial])
    end

    def test_new_with_array_and_namespace
      expects(:new_admin_article_url).with()
      polymorphic_url([:admin, @article], :action => 'new')
    end

    def test_fallthrough_for_new_with_array_and_namespace
      stubs(:respond_to?).with('new_admin_editorial_url').returns(false)
      stubs(:respond_to?).with('new_admin_article_url').returns(true)
      expects(:new_admin_article_url).with()
      polymorphic_url([:admin, @editorial], :action => 'new')
    end

    def test_unsaved_with_array_and_namespace
      expects(:admin_articles_url).with()
      polymorphic_url([:admin, @article])
    end
    
    def test_fallthrough_for_unsaved_with_array_and_namespace
      stubs(:respond_to?).with('admin_editorials_url').returns(false)
      stubs(:respond_to?).with('admin_articles_url').returns(true)
      expects(:admin_articles_url).with()
      polymorphic_url([:admin, @editorial])
    end

    def test_nested_unsaved_with_array_and_namespace
      @article.save
      expects(:admin_article_url).with(@article)
      polymorphic_url([:admin, @article])
      expects(:admin_article_responses_url).with(@article)
      polymorphic_url([:admin, @article, @response])
    end

    def test_fallthrough_for_nested_unsaved_with_array_and_namespace
      @editorial.save
      stubs(:respond_to?).with('admin_editorial_url').returns(false)
      stubs(:respond_to?).with('admin_article_url').returns(true)
      expects(:admin_article_url).with(@editorial)
      polymorphic_url([:admin, @editorial])
      
      #fallthrough only currently works for the targeted resource, not for parents it is nested inside
      stubs(:respond_to?).with('admin_editorial_responses_url').returns(false)
      stubs(:respond_to?).with('admin_editorial_articles_url').returns(false)
      stubs(:respond_to?).with('admin_article_responses_url').returns(true)
      expects(:admin_editorial_responses_url).with(@editorial) #TODO: this should be expects(:admin_article_responses_url).with(@editorial)
      polymorphic_url([:admin, @editorial, @response])
    end

    def test_nested_with_array_and_namespace
      @response.save
      expects(:admin_article_response_url).with(@article, @response)
      polymorphic_url([:admin, @article, @response])

      # a ridiculously long named route tests correct ordering of namespaces and nesting:
      @tag = Tag.new
      @tag.save
      expects(:site_admin_article_response_tag_url).with(@article, @response, @tag)
      polymorphic_url([:site, :admin, @article, @response, @tag])
    end
    
    def test_fallthrough_for_nested_with_array_and_namespace
      @response.save
      stubs(:respond_to?).with('admin_editorial_response_url').returns(false)
      stubs(:respond_to?).with('admin_editorial_article_url').returns(false)
      stubs(:respond_to?).with('admin_article_response_url').returns(true)
      expects(:admin_editorial_response_url).with(@editorial, @response) #TODO: this should be expects(:admin_article_response_url).with(@editorial, @response)
      polymorphic_url([:admin, @editorial, @response])

      # a ridiculously long named route tests correct ordering of namespaces and nesting:
      @tag = Tag.new
      @tag.save
      stubs(:respond_to?).with('site_admin_editorial_response_tag_url').returns(false)
      stubs(:respond_to?).with('site_admin_editorial_response_article_url').returns(false)
      stubs(:respond_to?).with('site_admin_article_response_tag_url').returns(true)
      expects(:site_admin_editorial_response_tag_url).with(@editorial, @response, @tag) #TODO: this should be expects(:site_admin_article_response_tag_url).with(@editorial, @response, @tag)
      polymorphic_url([:site, :admin, @editorial, @response, @tag])
    end

    # TODO: Needs to be updated to correctly know about whether the object is in a hash or not
    def xtest_with_hash
      expects(:article_url).with(@article)
      @article.save
      polymorphic_url(:id => @article)
    end

    def test_polymorphic_path_accepts_options
      expects(:new_article_path).with()
      polymorphic_path(@article, :action => :new)
    end
    
    def test_fallthrough_with_polymorphic_path_accepts_options
      stubs(:respond_to?).with('new_editorial_path').returns(false)
      stubs(:respond_to?).with('new_article_path').returns(true)
      expects(:new_article_path).with()
      polymorphic_path(@editorial, :action => :new)
    end

    def test_polymorphic_path_does_not_modify_arguments
      expects(:admin_article_responses_url).with(@article)
      path = [:admin, @article, @response]
      assert_no_difference 'path.size' do
        polymorphic_url(path)
      end
    end
  end
end
