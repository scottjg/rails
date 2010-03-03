require "cases/helper"

class Foo < ActiveRecord::Base
  has_many :bars
end
class Bar < ActiveRecord::Base
  set_table_name 'some_bars'
end

class IncludeWithSetTableNameTest < ActiveRecord::TestCase

  def setup
    if ActiveRecord::Base.connection.supports_migrations?
      ActiveRecord::Base.connection.create_table :foos do |t|
        # Typically we'd have more fields like "username", but they're not
        # needed for the test.
      end
      ActiveRecord::Base.connection.create_table :some_bars do |t|
        t.column :foo_id, :integer
        t.column :name, :string
      end
      @have_tables = true
    else
      @have_tables = false
    end
  end

  def teardown
    return unless @have_tables
    ActiveRecord::Base.connection.drop_table :foos
    ActiveRecord::Base.connection.drop_table :some_bars
  end

  def test_include_with_set_table_name_uses_table_not_class_name
    return unless @have_tables
    f = Foo.create
    b = f.bars.create :name => "baz"
    assert_nothing_raised do
      res = Foo.find :all, :conditions => { :bars => { :name => "baz" } },
        :joins => :bars
      assert_equal c.id, res.first.id
    end
  end

end
