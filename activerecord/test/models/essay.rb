# encoding: utf-8
class Essay < ActiveRecord::Base
  belongs_to :writer, :primary_key => :name, :polymorphic => true
end
