class Alias < ActiveRecord::Base
  set_table_name 'postgresql_Aliases'
  set_primary_key 'postgresql_Aliases_id'

  belongs_to :mixed_case, :foreign_key => 'postgresql_MixedCase_id'
end
