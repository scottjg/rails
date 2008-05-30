class ApprovedTopic < ActiveRecord::Base
  set_table_name :topics
  default_scope :conditions => { :approved => true }
end
