class UserTeam
  extend ActiveModel::Naming
  set_route_key :team
end

class UserTeam::Developers
  extend ActiveModel::Naming

  set_route_key :team
end

class Developers < UserTeam
  set_route_key :team
end
