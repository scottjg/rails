require 'cases/helper'

module ActiveRecord
  class Migration
    class CreateJoinTableTest < ActiveRecord::TestCase
      attr_reader :connection

      def setup
        super
        @connection = ActiveRecord::Base.connection
      end

      def teardown
        super
        %w(artists_musics musics_videos catalog).each do |table_name|
          connection.drop_table table_name if connection.tables.include?(table_name)
        end
      end

      def test_create_join_table
        connection.create_join_table :artists, :musics

        assert_equal %w(artist_id music_id), connection.columns(:artists_musics).map(&:name).sort
      end

      def test_create_join_table_set_not_null_by_default
        connection.create_join_table :artists, :musics

        assert_equal [false, false], connection.columns(:artists_musics).map(&:null)
      end

      def test_create_join_table_with_strings
        connection.create_join_table 'artists', 'musics'

        assert_equal %w(artist_id music_id), connection.columns(:artists_musics).map(&:name).sort
      end

      def test_create_join_table_with_the_proper_order
        connection.create_join_table :videos, :musics

        assert_equal %w(music_id video_id), connection.columns(:musics_videos).map(&:name).sort
      end

      def test_create_join_table_with_the_table_name
        connection.create_join_table :artists, :musics, :table_name => :catalog

        assert_equal %w(artist_id music_id), connection.columns(:catalog).map(&:name).sort
      end

      def test_create_join_table_with_the_table_name_as_string
        connection.create_join_table :artists, :musics, :table_name => 'catalog'

        assert_equal %w(artist_id music_id), connection.columns(:catalog).map(&:name).sort
      end

      def test_create_join_table_with_column_options
        connection.create_join_table :artists, :musics, :column_options => {:null => true}

        assert_equal [true, true], connection.columns(:artists_musics).map(&:null)
      end

      def test_create_join_table_adds_indexes_by_default
        connection.create_join_table :artists, :musics

        if connection.one_index_per_table_query?
          assert_equal 1, connection.indexes(:artists_musics).count
          assert_equal ['artist_id', 'music_id'],
            connection.indexes(:artists_musics)[0].columns.sort
        else
          assert_equal [['artist_id'], ['music_id']],
            connection.indexes(:artists_musics).map(&:columns).sort
        end
      end

      def test_create_join_table_without_indexes
        connection.create_join_table :artists, :musics, :indexes => false

        assert_equal 0, connection.indexes(:artists_musics).count
      end

      def test_create_join_table_adds_indexes_with_options
        connection.create_join_table :artists, :musics, :index_options => :unique

        if connection.one_index_per_table_query?
          assert_equal true, connection.indexes(:artists_musics)[0].unique
        else
          assert_equal [true, true], connection.indexes(:artists_musics).map(&:unique).sort
        end
      end
    end
  end
end
