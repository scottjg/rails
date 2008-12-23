class Man < ActiveRecord::Base
  has_one :face, :inverse => :man
  has_many :interests, :inverse => :man
end
