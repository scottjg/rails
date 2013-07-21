class Star < ActiveRecord::Base
  self.primary_key = 'id'
  belongs_to :galaxy
end
