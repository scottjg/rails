require "cases/helper"

module ActiveRecord
  module ConnectionAdapters
    class Mysql2AuthenticationTest < ActiveRecord::TestCase
      def setup
        @ar_config = ARTest.connection_config['arunit']

        @db = @ar_config['database']

        @unpriv_user = "m2_uc_test"
        @unpriv_pass = "m2_uc_pass"

        @unpriv_config = @ar_config.merge('username' => @unpriv_user, 'password' => @unpriv_pass)

        # create an unprivileged user
        # using GRANT then immediately
        # REVOKING the permissions
        # CREATE fails if the user already exists
        ActiveRecord::Base.connection.execute(<<-_SQL_
          GRANT SELECT ON #{@db}.*
          TO '#{@unpriv_user}'@'localhost'
          IDENTIFIED BY '#{@unpriv_pass}';
        _SQL_
        )
        ActiveRecord::Base.connection.execute(<<-_SQL_
          REVOKE ALL ON #{@db}.* FROM '#{@unpriv_user}'@'localhost'
        _SQL_
        )
      end

      def teardown
        # re-establish the default connection
        ActiveRecord::Base.establish_connection 'arunit'
        ActiveRecord::Base.connection.execute(<<-_SQL_
          DROP USER '#{@unpriv_user}'@'localhost';
        _SQL_
        )
      end

      def test_privileged_user_can_connect_to_database_directly
        assert_nothing_raised do
          ActiveRecord::Base.establish_connection(@ar_config).connection
        end
      end

      def test_unprivileged_user_cant_connect_to_database_directly
        assert_raises(Mysql2::Error) do
          ActiveRecord::Base.establish_connection(@unpriv_config).connection
        end
      end

      def test_unprivileged_user_can_connect_without_database
        assert_nothing_raised do
          ActiveRecord::Base.establish_connection(@unpriv_config.except('database')).connection
        end
      end

      def test_privileged_user_can_connect_then_specify_database
        assert_nothing_raised do
          ActiveRecord::Base.establish_connection(@ar_config.except('database'))
          ActiveRecord::Base.connection.execute("USE #{@db}")
        end
      end
    end
  end
end
