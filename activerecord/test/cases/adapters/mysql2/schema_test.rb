require "cases/helper"
require 'models/post'
require 'models/comment'

module ActiveRecord
  module ConnectionAdapters
    class Mysql2SchemaTest < ActiveRecord::TestCase
      fixtures :posts

      def setup
        @connection = ActiveRecord::Base.connection
        db          = Post.connection_pool.spec.config[:database]
        table       = Post.table_name
        @db_name    = db

        @omgpost = Class.new(ActiveRecord::Base) do
          self.table_name = "#{db}.#{table}"
          def self.name; 'Post'; end
        end
      end

      def test_schema
        assert @omgpost.first
      end

      def test_primary_key
        assert_equal 'id', @omgpost.primary_key
      end

      def test_table_exists?
        name = @omgpost.table_name
        assert @connection.table_exists?(name), "#{name} table should exist"
      end

      def test_table_exists_wrong_schema
        assert(!@connection.table_exists?("#{@db_name}.zomg"), "table should not exist")
      end

      def test_tables_quoting
        begin
          @connection.tables(nil, "foo-bar", nil)
          flunk
        rescue => e
          # assertion for *quoted* database properly
          assert_match(/database 'foo-bar'/, e.inspect)
        end
      end

      def test_dump_indexes
        index_a_name = 'index_post_title'
        index_b_name = 'index_post_body'
        index_c_name = 'index_post_title_fulltext'

        table = Post.table_name

        @connection.execute "ALTER TABLE `#{table}` ENGINE=MyISAM"

        @connection.execute "CREATE INDEX `#{index_a_name}` ON `#{table}` (`title`);"
        @connection.execute "CREATE INDEX `#{index_b_name}` USING btree ON `#{table}` (`body`(10));"
        @connection.execute "CREATE FULLTEXT INDEX `#{index_c_name}` ON `#{table}` (`title`);"

        indexes = @connection.indexes(table).sort_by {|i| i.name}
        assert_equal 3,indexes.size

        index_a = indexes.select{|i| i.name == index_a_name}[0]
        index_b = indexes.select{|i| i.name == index_b_name}[0]
        index_c = indexes.select{|i| i.name == index_c_name}[0]
        assert_equal({:using => :btree }, index_a.options)
        assert_nil index_a.type
        assert_equal({:using => :btree }, index_b.options)
        assert_nil index_b.type

        assert_nil index_c.options
        assert_equal(:fulltext, index_c.type)

        @connection.execute "DROP INDEX `#{index_a_name}` ON `#{table}`;"
        @connection.execute "DROP INDEX `#{index_b_name}` ON `#{table}`;"
        @connection.execute "DROP INDEX `#{index_c_name}` ON `#{table}`;"


        @connection.execute "ALTER TABLE `#{table}` ENGINE=InnoDB"
      end
    end
  end
end
