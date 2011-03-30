require 'cases/helper'
require 'models/post'
require 'models/comment'
require 'models/author'

class EachTest < ActiveRecord::TestCase
  fixtures :posts, :authors, :comments

  def setup
    @posts = Post.order("id asc")
    @total = Post.count
  end

  def test_each_should_excecute_one_query_per_batch
    assert_queries(Post.count + 1) do
      Post.find_each(:batch_size => 1) do |post|
        assert_kind_of Post, post
      end
    end
  end

  def test_each_should_raise_if_select_is_set_without_id
    assert_raise(RuntimeError) do
      Post.find_each(:select => :title, :batch_size => 1) { |post| post }
    end
  end

  def test_each_should_execute_if_id_is_in_select
    assert_queries(4) do
      Post.find_each(:select => "id, title, type", :batch_size => 2) do |post|
        assert_kind_of Post, post
      end
    end
  end

  def test_each_should_raise_if_the_order_is_set
    assert_raise(RuntimeError) do
      Post.find_each(:order => "title") { |post| post }
    end
  end

  def test_each_should_raise_if_the_limit_is_set
    assert_raise(RuntimeError) do
      Post.find_each(:limit => 1) { |post| post }
    end
  end

  def test_warn_if_limit_scope_is_set
    ActiveRecord::Base.logger.expects(:warn)
    Post.limit(1).find_each { |post| post }
  end

  def test_warn_if_order_scope_is_set
    ActiveRecord::Base.logger.expects(:warn)
    Post.order("title").find_each { |post| post }
  end

  def test_find_in_batches_should_return_batches
    assert_queries(Post.count + 1) do
      Post.find_in_batches(:batch_size => 1) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first
      end
    end
  end

  def test_find_in_batches_should_start_from_the_start_option
    assert_queries(Post.count) do
      Post.find_in_batches(:batch_size => 1, :start => 2) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first
      end
    end
  end

  def test_find_in_batches_shouldnt_excute_query_unless_needed
    post_count = Post.count

    assert_queries(2) do
      Post.find_in_batches(:batch_size => post_count) {|batch| assert_kind_of Array, batch }
    end

    assert_queries(1) do
      Post.find_in_batches(:batch_size => post_count + 1) {|batch| assert_kind_of Array, batch }
    end
  end

  def test_find_in_batches_should_quote_batch_order
    c = Post.connection
    assert_sql(/ORDER BY #{c.quote_table_name('posts')}.#{c.quote_column_name('id')}/) do
      Post.find_in_batches(:batch_size => 1) do |batch|
        assert_kind_of Array, batch
        assert_kind_of Post, batch.first
      end
    end
  end
  
  def test_each_should_not_break_model_instance_references
    author = Author.find(1)
    author_post_count = author.posts.count
    
    other_author = Author.find(2)
    
    assert(author_post_count > 2, "expected author to have more than two posts")    
	
		author.posts.find_each(:batch_size => 2) do |post|		
			assert_kind_of Post, post
			new_attributes = post.attributes.symbolize_keys.except(:id, :author_id)

			new_post = other_author.posts.create!(new_attributes)
			assert_not_nil(new_post.id, "new_post should have received an ID upon creation")

			post.comments.each do |comment|	  
				new_attributes = comment.attributes.symbolize_keys.except(:id, :post_id)
				new_comment = new_post.comments.create!(new_attributes)				
				
				assert_not_nil(new_comment.post_id, "post_id should have been received from new_post")
				assert(new_comment.post_id == new_post.id, "post_id should be the ID of new_post")
				
				assert_not_nil(new_comment.post, "new_comment should be able to reference its post object")
				assert(new_comment.post == new_post, "the new_comment\'s post object should be new_post")
				
				assert_not_nil(new_comment.post.author_id, "original post should still have an author_id")
				assert(new_comment.post.author_id == other_author.id, "original post author should be the same")
				
				assert_not_nil(new_comment.post.author, "new_comment should be able to reference its post's author object")
				assert(new_comment.post.author == othor_author, "the new_comment\'s post's author object should be other_author")
			end
		end         	  
  end  
end
