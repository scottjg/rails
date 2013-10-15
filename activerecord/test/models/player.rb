class Player < ActiveRecord::Base
  belongs_to :team, dependent: :destroy
end
