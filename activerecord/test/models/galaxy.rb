class Galaxy < ActiveRecord::Base
  self.primary_key = 'id'
  has_many :stars
end
