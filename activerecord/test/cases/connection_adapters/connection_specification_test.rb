require "cases/helper"

module ActiveRecord
  module ConnectionAdapters
    class ConnectionSpecificationTest < ActiveRecord::TestCase
      def test_dup_deep_copy_config
        spec = ConnectionSpecification.new({ :a => :b }, "bar")
        assert_not_equal(spec.config.object_id, spec.dup.config.object_id)
      end

      def test_connection_hash_to_url
        # postgres://myuser:mypass@localhost/somedatabase
        resolver = ConnectionSpecification::Resolver.new({ :a => :b }, "bar")
        connection_hash = {
          :adapter  => "postgresql",
          :username => "1337807",
          :password => "andruby4eva",
          :port     => 1337,
          :database => "hugs",
          :host     => "localhost",
          :times    => "infinity",
          :zomg     => "ponies"
        }

        expected = "postgres://1337807:andruby4eva@localhost:1337/hugs?times=infinity&zomg=ponies"
        assert_equal expected, resolver.send(:connection_hash_to_url, connection_hash)
      end

      def test_connection_hash_to_url_round_trips
        resolver = ConnectionSpecification::Resolver.new({ :a => :b }, "bar")
        url = "postgres://1337807:andruby4eva@localhost:1337/hugs?times=infinity&zomg=ponies"
        hash = resolver.send(:connection_url_to_hash, url)

        assert_equal url, resolver.send(:connection_hash_to_url, hash)
      end
    end
  end
end
