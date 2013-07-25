require "cases/helper"
require 'debugger'

class TestAdapterWithInvalidConnection < ActiveRecord::TestCase
  self.use_transactional_fixtures = false

  class Bird < ActiveRecord::Base
  end

  def setup
    # Can't just use current adapter; sqlite3 will create a database
    # file on the fly.
    adapter = ActiveRecord::Base.connection_config[:adapter]
    Bird.establish_connection adapter: adapter, database: 'i_do_not_exist'
  end

  def teardown
    return if in_memory_db?
    Bird.remove_connection
  end

  test "inspect on Model class does not raise" do
    assert_equal "#{Bird.name}(no database connection)", Bird.inspect
  end
end
