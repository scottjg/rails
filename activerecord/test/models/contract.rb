# encoding: utf-8
class Contract < ActiveRecord::Base
  belongs_to :company
  belongs_to :developer
end

