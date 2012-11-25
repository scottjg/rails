require 'active_record/scoping/default'
require 'active_record/scoping/named'
require 'active_record/base'

module ActiveRecord
  class SchemaMigration < ActiveRecord::Base

    def self.table_name
      "#{Base.table_name_prefix}schema_migrations#{Base.table_name_suffix}"
    end

    def self.index_name
      "#{Base.table_name_prefix}unique_schema_migrations#{Base.table_name_suffix}"
    end

    def self.create_table
      if connection.table_exists?(table_name)
        cols = connection.columns(table_name).collect { |col| col.name }
        unless cols.include?("name")
          connection.add_column table_name, :name, :string, :null => false, :default => ""
        end
        unless cols.include?("migrated_at")
          connection.add_column table_name, :migrated_at, :datetime
          q_table_name = connection.quote_table_name(table_name)
          q_timestamp = connection.quoted_date(Time.now)
          connection.update "UPDATE #{q_table_name} SET migrated_at = '#{q_timestamp}' WHERE migrated_at IS NULL"
          connection.change_column table_name, :migrated_at, :datetime, :null => false
        end
      else
        connection.create_table(table_name, :id => false) do |t|
          t.column :version, :string, :null => false
          t.column :name, :string, :null => false, :default => ""
          t.column :migrated_at, :datetime, :null => false
        end
        connection.add_index table_name, :version, :unique => true, :name => index_name
      end
    end

    def self.drop_table
      if connection.table_exists?(table_name)
        connection.remove_index table_name, :name => index_name
        connection.drop_table(table_name)
      end
    end

    def version
      super.to_i
    end
  end
end
