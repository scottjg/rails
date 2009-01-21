module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      alias :execute_without_graceful_reconnect :execute
      def execute(sql, name = nil)
        gracefully_reconnect do
          execute_without_graceful_reconnect(sql, name)
        end
      end

      alias :query_without_graceful_reconnect :query
      def query(sql, name = nil)
        gracefully_reconnect do
          query_without_graceful_reconnect(sql, name)
        end
      end

      def gracefully_reconnect
        retries = 0
        begin
          yield
        rescue ActiveRecord::StatementInvalid => e
          retries += 1
          raise e if connection_alive? || retries > 10
			 sleep 1
			 @logger.info("Disconnected from database, trying to reconnect.")
          reconnect!
          retry
        end
      end

      # when the connection is killed, "active?" raises an exception.
      # let's wrap it so we can easily know if the connection died
      def connection_alive?
        active? rescue false
      end
    end
  end
end
