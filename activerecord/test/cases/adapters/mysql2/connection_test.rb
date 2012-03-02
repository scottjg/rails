require "cases/helper"

class MysqlConnectionTest < ActiveRecord::TestCase
  def setup
    super
    @connection = ActiveRecord::Model.connection
  end

  def test_no_automatic_reconnection_after_timeout
    assert @connection.active?
    @connection.update('set @@wait_timeout=1')
    sleep 2
    assert !@connection.active?
  end

  def test_successful_reconnection_after_timeout_with_manual_reconnect
    assert @connection.active?
    @connection.update('set @@wait_timeout=1')
    sleep 2
    @connection.reconnect!
    assert @connection.active?
  end

  def test_successful_reconnection_after_timeout_with_verify
    assert @connection.active?
    @connection.update('set @@wait_timeout=1')
    sleep 2
    @connection.verify!
    assert @connection.active?
  end

  def test_charset_after_timeout_with_manual_reconnect
    assert @connection.active?
    assert_equal 'utf8', @connection.show_variable('character_set_client')
    assert_equal 'utf8', @connection.show_variable('character_set_connection')
    assert_equal 'utf8', @connection.show_variable('character_set_results')
    @connection.update('set @@wait_timeout=1')
    sleep 2
    @connection.reconnect!
    assert @connection.active?
    assert_equal 'utf8', @connection.show_variable('character_set_client')
    assert_equal 'utf8', @connection.show_variable('character_set_connection')
    assert_equal 'utf8', @connection.show_variable('character_set_results')
  end

  def test_charset_after_timeout_with_automatic_reconnect
    run_without_connection do |orig_connection|
      ActiveRecord::Model.establish_connection(orig_connection.merge({:reconnect => true}))
      @connection = ActiveRecord::Model.connection
      @connection.reconnect!
      assert @connection.active?
      assert_equal 'utf8', @connection.show_variable('character_set_client')
      assert_equal 'utf8', @connection.show_variable('character_set_connection')
      assert_equal 'utf8', @connection.show_variable('character_set_results')
      @connection.update('set @@wait_timeout=1')
      sleep 2
      assert @connection.active?
      assert_equal 'utf8', @connection.show_variable('character_set_client')
      assert_equal 'utf8', @connection.show_variable('character_set_connection')
      assert_equal 'utf8', @connection.show_variable('character_set_results')
    end
  end

  private

  def run_without_connection
    original_connection = ActiveRecord::Model.remove_connection
    begin
      yield original_connection
    ensure
      ActiveRecord::Model.establish_connection(original_connection)
    end
  end
end
