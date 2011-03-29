class Comment < ActiveRecord::Base
  def self.limit_by(l)
    limit(l)
  end

  def self.containing_the_letter_e
    where "comments.body LIKE '%e%'"
  end

  def self.not_again
    where("comments.body NOT LIKE '%again%'")
  end

  def self.for_first_post
    where :post_id => 1
  end

  def self.for_first_author
    joins(:post).where("posts.author_id" => 1)
  end

  belongs_to :post, :counter_cache => true
  has_many :ratings

  def self.what_are_you
    'a comment...'
  end

  def self.search_by_type(q)
    self.find(:all, :conditions => ["#{QUOTED_TYPE} = ?", q])
  end

  def self.all_as_method
    all
  end

  ActiveSupport::Deprecation.silence do
    scope :all_as_scope, {}
  end
end

class SpecialComment < Comment
  def self.what_are_you
    'a special comment...'
  end
end

class SubSpecialComment < SpecialComment
end

class VerySpecialComment < Comment
  def self.what_are_you
    'a very special comment...'
  end
end
