require File.expand_path(File.join(File.dirname(__FILE__), 'validation_test_helper'))

class Article < TestClassBase
  attr_accessor :tags, :title
  validate :no_title_tag, :title_cant_be_angry
  def no_title_tag
    errors.add "Title can't also be a tag" if tags.include?(title)
  end
  def title_cant_be_angry
    errors.on(:title).add "Title is too angry!" if title =~ /\!\!+$/
  end
end




class TestValidations < ActiveModel::TestCase
  def setup
    @article = Article.new(:title=>"New validations rock!", :tags=>%w(announcement important))
  end

  test "validation passing" do
    assert @article.valid?
  end
  
  test "callback validation failing for errors on base" do
    @article.tags << "junk"
    @article.title = "junk"
    assert !@article.valid?
  end
  
  test "callback validation failing for errors on an attribute" do
    @article.title = "Grahhh!!!!"
    assert !@article.valid?
  end
  
end
