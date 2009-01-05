class Comment < ActiveRecord::Base
  belongs_to :post
  has_many :readers, :through => :post
  
  def self.what_are_you
    'a comment...'
  end
  
  def self.search_by_type(q)
    self.find(:all, :conditions => ["#{QUOTED_TYPE} = ?", q])
  end
end

class SpecialComment < Comment
  def self.what_are_you
    'a special comment...'
  end
end

class VerySpecialComment < Comment
  def self.what_are_you
    'a very special comment...'
  end
end
