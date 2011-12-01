require "cases/helper"
require 'models/reply'

class ConnectionPostgresqlTest < ActiveRecord::TestCase

  self.use_transactional_fixtures = false

  fixtures :topics

  def setup
    @connection = ActiveRecord::Base.connection
    assert @connection.active?
  end

  def test_database_version_returns_a_version_string
    assert_match /PostgreSQL\s+\d/i, @connection.database_version
  end

  def test_set_spid_on_connect
    assert_instance_of Fixnum, @connection.spid
  end

  def test_reset_spid_on_disconnect!
    @connection.disconnect!
    assert @connection.spid.nil?
  end

  def test_be_able_to_disconnect_and_reconnect_at_will
    @connection.disconnect!
    assert !@connection.active?
    @connection.reconnect!
    assert @connection.active?
  end

  def test_auto_reconnect_when_setting_is_on
    with_auto_connect(true) do
      @connection.disconnect!
      assert_nothing_raised() { Topic.count }
      assert @connection.active?
    end
  end

  def test_not_auto_reconnect_when_setting_is_off
    with_auto_connect(false) do
      @connection.disconnect!
      assert_raise(ActiveRecord::LostConnection) { Topic.count }
    end
  end

  def test_disable_auto_reconnect_when_auto_reconnect_setting_is_on
    with_auto_connect(true) do
      @connection.send(:disable_auto_reconnect) do
        assert !@connection.class.auto_connect
      end
      assert @connection.class.auto_connect
    end
  end

  def test_disable_auto_reconnect_when_auto_reconnect_setting_is_off
    with_auto_connect(false) do
      @connection.send(:disable_auto_reconnect) do
        assert !@connection.class.auto_connect
      end
      assert !@connection.class.auto_connect
    end
  end

  def test_not_auto_reconnect_on_commit_transaction
    @connection.disconnect!
    assert_raise(ActiveRecord::LostConnection) { @connection.commit_db_transaction }
  end

  def test_not_auto_reconnect_on_rollback_transaction
    @connection.disconnect!
    assert_raise(ActiveRecord::LostConnection) { @connection.rollback_db_transaction }
  end

  def test_not_auto_reconnect_on_create_savepoint
    @connection.disconnect!
    assert_raise(ActiveRecord::LostConnection) { @connection.create_savepoint }
  end

  def test_not_auto_reconnect_on_rollback_to_savepoint
    @connection.disconnect!
    assert_raise(ActiveRecord::LostConnection) { @connection.rollback_to_savepoint }
  end

  def with_auto_connect(boolean)
    existing = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.auto_connect
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.auto_connect = boolean
    yield
  ensure
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.auto_connect = existing
  end

end if current_adapter?(:PostgreSQLAdapter) 
