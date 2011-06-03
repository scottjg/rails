class Business < ActiveRecord::Base
  has_many :business_managements, :foreign_key => :business_id
  has_many :business_managers,                  :through => :business_managements,          :source => :business_position
  has_many :business_managers_contracts,        :through => :business_managers,             :source => :business_contracts
  has_many :business_managers_consultants,      :through => :business_managers_contracts,   :source => :business_consultants
  has_many :business_managers_properties,       :through => :business_managers_consultants, :source => :business_properties
end

class BusinessPosition < Business
  has_many :business_managements
  has_many :business_managed_units, :through => :business_managements

  has_many :business_contract_to_position
  has_many :business_contracts, :through => :business_contract_to_position, :source => :business_contract
end


class BusinessContract < Business
  has_many :business_contractings
  has_many :business_consultants, :through => :business_contractings

  has_many :business_contract_to_position
  has_many :business_positions, :through => :business_contract_to_position
end

class BusinessConsultant < Business
  has_many :business_contractings
  has_many :business_contracts, :through => :business_contractings

  has_many :business_properties, :class_name => "BusinessConsultantAttribute"
end

class BusinessConsultantAttribute < ActiveRecord::Base
  belongs_to :business_consultant, :inverse_of => :business_properties
end

class BusinessContractToPosition < ActiveRecord::Base
  belongs_to :business_position
  belongs_to :business_contract
end

class BusinessManagement < ActiveRecord::Base
  belongs_to :business
  belongs_to :business_position
end

class BusinessContracting < ActiveRecord::Base
  belongs_to :business_contract
  belongs_to :business_consultant
end
