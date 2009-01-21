class Ship < ActiveRecord::Base
  self.record_timestamps = false

  belongs_to :pirate, :autosave => true
  has_many :parts, :class_name => 'ShipPart', :autosave => true

  validates_presence_of :name
end