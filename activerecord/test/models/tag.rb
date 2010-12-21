class Tag < ActiveRecord::Base
  has_many :taggings
  has_many :taggables, :through => :taggings
  has_one  :tagging

  has_many :tagged_posts, :through => :taggings, :source => :taggable, :source_type => 'Post'

  has_many :polytaggings, :as => :polytag, :class_name => 'Tagging'
  has_many :polytagged_posts, :through => :polytaggings, :source => :taggable, :source_type => 'Post'
end

class SpecialTag < Tag; end
