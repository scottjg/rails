class MixedCase < ActiveRecord::Base
  set_table_name 'postgresql_MixedCases'
  set_primary_key 'postgresql_MixedCase_id'

  has_many :aliases, :foreign_key => 'postgresql_MixedCase_id'
  has_one :alias, :foreign_key => 'postgresql_MixedCase_id'
end
