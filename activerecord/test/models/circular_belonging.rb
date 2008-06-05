class Romeo < ActiveRecord::Base
  attr_accessor :montague
  validates_presence_of :montague
  has_many :juliets, :dependent=>:destroy
  belongs_to :juliet
end

class Juliet < ActiveRecord::Base
  attr_accessor :capulet
  validates_presence_of :capulet
  belongs_to :romeo
end