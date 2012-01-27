require "cases/migration/helper"

module ActiveRecord
  class Migration
    class CreateJoinTableTest < ActiveRecord::TestCase
      include ActiveRecord::Migration::TestHelper

      self.use_transactional_fixtures = false

      def setup
        super
      end

      def test_create_join_table
        con = connection

        create_join_table :tie => :person, :to => :group

        table_name = "groups_people"
        assert con.table_exists?(table_name)

        columns = con.columns(table_name)
        assert !columns.find { |c| c.name == "group_id" }.null
        assert !columns.find { |c| c.name == "person_id" }.null

        assert !con.index_name_exists?(table_name, "index_groups_people_on_group_id", false)
        assert !con.index_name_exists?(table_name, "index_groups_people_on_person_id", false)
      ensure
        drop_join_table :tie => :person, :to => :group
      end

      def test_create_join_table_with_index
        con = connection

        create_join_table :tie => :person, :to => :group, :index => true

        table_name = "groups_people"
        assert con.index_name_exists?(table_name, "index_groups_people_on_group_id",  false)
        assert con.index_name_exists?(table_name, "index_groups_people_on_person_id", false)
      ensure
        drop_join_table :tie => :person, :to => :group
      end

      def test_create_join_table_with_table_name_and_options
        table_name = "habtm"
        create_join_table table_name, :tie => :person, :to => :group
        assert connection.table_exists?(table_name)
      ensure
        drop_join_table table_name
      end

      private

      def create_join_table(*args)
        connection.create_join_table(*args)
      end

      def drop_join_table(*args)
        connection.drop_join_table(*args)
      end

    end
  end
end
