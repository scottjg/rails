require 'cases/helper'

class Item < ActiveRecord::Base
  self.table_name = 'postgresql_null_constraint'
end

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      class NotNullTest < ActiveRecord::TestCase
        def test_not_null_constraint
          assert_raises(ActiveRecord::InvalidValue) do 
            Item.new.save
          end
        end
      end
    end
  end
end