class Reader < ActiveRecord::Base
  belongs_to :post
  belongs_to :person, :inverse_of => :readers
  belongs_to :single_person, :class_name => 'Person', :foreign_key => :person_id, :inverse_of => :reader
end

class ProtectedReader < ActiveRecord::Base
  self.table_name = 'readers'

  belongs_to :loose_person, :foreign_key => :person_id
  attr_accessible
end
