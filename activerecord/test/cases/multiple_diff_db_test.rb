
require "cases/helper"

# first define the legacy...

ActiveRecord::Base.establish_connection(
  :adapter  => 'mysql2',
  :database => 'activerecord_unittest',
  :username => 'rails'
 # :password => 'rails'
)
ActiveRecord::Schema.define do
  #create_database 'activerecord_unittest.legacy'
  create_table :foo, :force => true do |t|
    t.string :name
    t.integer :legacy_id
  end
end
ActiveRecord::Base.remove_connection


# now the main...
ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:'
)
ActiveRecord::Schema.define do
  create_table :horses, :force => true do |t|
    t.string :name 
    t.integer :horse_id
  end  
end

# now the AR classes...
class Horse < ActiveRecord::Base
end

# now a legacy table on a different connection
class Legacy < ActiveRecord::Base
  establish_connection(adapter: 'mysql2', database: 'activerecord_unittest', username: 'rails')
  self.table_name = "foo"
end

# add some records...
m = Legacy.new(name: "john", legacy_id: 5)
m.save
m = Horse.new(name: "fireball", horse_id: 3)
m.save


class MultipleDiffDbTest < ActiveRecord::TestCase
  self.use_transactional_fixtures = false

  def test_proper_connection
    assert_not_equal(Horse.connection, Legacy.connection)
    assert_equal(Horse.connection, Horse.retrieve_connection)
    assert_equal(Legacy.connection, Legacy.retrieve_connection)
    assert_equal(ActiveRecord::Base.connection, Horse.connection)
  end

  def test_where_first_style
    leg = Legacy.where(:legacy_id => 5)
    assert_equal 1, leg.count
    hrse = Horse.where(:horse_id => 3)
    assert_equal 1, hrse.count
  end

  def test_where_second_style
    leg = Legacy.where("legacy_id = ?",5)
    assert_equal 1, leg.count
    hrse = Horse.where("horse_id = ?",3)
    assert_equal 1, hrse.count
  end

end