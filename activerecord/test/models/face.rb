class Face < ActiveRecord::Base
  belongs_to :man, :inverse => :face
end
