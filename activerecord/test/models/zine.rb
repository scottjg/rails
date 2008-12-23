class Zine < ActiveRecord::Base
  has_many :interests, :inverse => :zine
end
