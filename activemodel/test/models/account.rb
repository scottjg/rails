class Account
  include ActiveModel::ForbiddenAttributesProtection

  def self.attributes_forbidden_by_default
    ['id']
  end

  public :sanitize_for_mass_assignment
end
