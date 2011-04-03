class Car < ActiveRecord::Base

  has_many :bulbs
  has_many :foo_bulbs, :class_name => "Bulb", :conditions => { :name => 'foo' }
  has_many :tyres
  has_many :engines
  has_many :wheels, :as => :wheelable

  def self.incl_tyres
    includes(:tyres)
  end

  def self.incl_engines
    includes(:engines)
  end

  def self.order_using_new_style
    order('name asc')
  end

  ActiveSupport::Deprecation.silence do
    scope :order_using_old_style, :order => 'name asc'
  end

end

class CoolCar < Car
  def self.default_scope
    order 'name desc'
  end
end

class FastCar < Car
  def self.default_scope
    order 'name desc'
  end
end
