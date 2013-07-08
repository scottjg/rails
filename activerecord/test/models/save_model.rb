class SaveModel < ActiveRecord::Base
  after_create do
    raise ActiveRecord::StatementInvalid.new('Deadlock')
  end
end