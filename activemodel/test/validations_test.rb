require File.join(File.dirname(__FILE__), "helper")
require 'active_model/validatable'

class Post < TestClassBase
  attr_accessor :tags, :title
  validate :no_title_tag, :title_cant_be_angry
  def no_title_tag
    errors.add "Title can't also be a tag" if tags.include?(title)
  end
  def title_cant_be_angry
    # errors.on(:title).add "Title is too angry!" if title =~ /\!$/
  end
end
class Tag < TestClassBase

  attr_accessor :post
end



class TestValidations < ActiveSupport::TestCase

  test "validation passing" do
    assert Post.new(:title=>"New validations rock!", :tags=>%w(announcement important)).valid?
  end
  
  test "callback validation failing for errors on base" do
    assert !Post.new(:title=>"junk",:tags=>["junk", "other"]).valid?
  end
  
  test "callback validation failing for errors on an attribute" do
    # assert !Post.new(:title=>"junk",:tags=>["junk", "other"]).valid?
  end
end
