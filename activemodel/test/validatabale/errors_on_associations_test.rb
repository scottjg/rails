require File.expand_path(File.join(File.dirname(__FILE__), 'validation_test_helper'))

class Post < TestClassBase
  attr_accessor :tags, :title, :author
end
class Tag < TestClassBase
  attr_accessor :post, :name
end
class Author < TestClassBase
  attr_accessor :posts, :name
end



class TestErrorsOnAssociations < ActiveModel::TestCase
  def setup
    @author = Author.new(:name=>"Joe")
    @post = Post.new(:title=>"New validations rock!", :author=>@author)
    @tags = [ Tag.new(:name=>"cool",:post=>@post),
              Tag.new(:name=>"awsome", :post=>@post),
              Tag.new(:name=>"tubular", :post=>@post)
            ]
    @post.tags = @tags
    @author.posts = [@post]
  end
  test "error counts with validatable singular association" do
    @post.errors.add "Your post sucks."
    @post.errors.on(:base).add "Your post is stupid."
    @post.errors.on(:title).add "The title is too short."
    
    @post.errors.on(:author).add "Author isn't cool enough to write about this subject."
    @author.errors.add "Author is too young."
    @author.errors.on(:name).add "Name is too short."
    @post.errors.on(:author).on(:name).add "Name is already taken."
    @post.author.errors.add "I just plain don't like you"
    
    assert_equal 8, @post.errors.size
    assert_equal 2, @post.errors.on(:base).size
    assert_equal 1, @post.errors.on(:title).size

    assert_equal 5, @post.errors.on(:author).size
    assert_equal 4, @author.errors.size
    assert_equal 4, @post.author.errors.size
    assert_equal 2, @author.errors.on(:base).size
    assert_equal 2, @post.errors.on(:author).on(:base).size
    assert_equal 2, @post.errors.on(:author).on(:name).size
    assert_equal 2, @post.author.errors.on(:name).size
    assert_equal 2, @post.author.errors.on(:base).size
    
  end
end
