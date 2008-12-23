class Interest < ActiveRecord::Base
  belongs_to :man, :inverse => :interests
  belongs_to :zine, :inverse => :interests
end
