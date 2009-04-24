# encoding: utf-8
require 'rubygems'
require "cases/helper"
require 'models/ship'
require 'models/ship_part'
require 'fast_gettext'

FastGettext.add_text_domain 'MyApp', 
  :path => File.join(File.dirname(__FILE__)),
  :type => :po
FastGettext.text_domain = 'MyApp'

class RealShip < Ship
  include FastGettext::Translation
  validates_length_of :parts, :minimum => 1, :message => proc {_("Ship needs an least one part.")}
end

class ValidationMessageTest < ActiveSupport::TestCase
  include FastGettext::Translation
  def test_nice_message
    FastGettext.locale = :ru 
    ship = RealShip.new
    assert !ship.valid?
    assert_equal "У корабля должна быть хотя бы одна часть!", ship.errors[:parts]
  end 
end
