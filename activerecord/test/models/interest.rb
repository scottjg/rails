class Interest < ActiveRecord::Base
  belongs_to :man, :inverse_of => :interests, :validate => true
  belongs_to :polymorphic_man, :polymorphic => true, :inverse_of => :polymorphic_interests
  belongs_to :zine, :inverse_of => :interests
  
  validates_presence_of :topic
end
