require "cases/helper"
require "models/parrot"

class PostgresqlOrderByClauseParsingTest < ActiveRecord::TestCase
  def setup
    @connection = ActiveRecord::Base.connection
  end

  def test_escaping_with_backslashes
    columns = @connection.send(:parse_columns, "E'Doe\\',John', 'Voltaire'")
    assert_equal ["E'Doe\\',John'", "'Voltaire'"], columns

    if @connection.supports_standard_conforming_strings?
      columns = @connection.send(:parse_columns, "'Doe\\',John', 'Voltaire'")
      assert_equal ["'Doe\\'", "John', 'Voltaire'"], columns
    else
      columns = @connection.send(:parse_columns, "'Doe\\',John', 'Voltaire'")
      assert_equal ["'Doe\\',John'", "'Voltaire'"], columns
    end
  end

  def test_escaping_with_repeated_single_quotes
    columns = @connection.send(:parse_columns, "'Doe''','John', 'Voltaire'")
    assert_equal ["'Doe'''","'John'", "'Voltaire'"], columns
  end

  def test_parsing_with_identifiers
    columns = @connection.send(:parse_columns, '"Last Name" DESC, "First Name" ASC')
    assert_equal ['"Last Name" DESC', '"First Name" ASC'], columns

    columns = @connection.send(:parse_columns, '"\'Special\' Name" DESC, "First Name" ASC')
    assert_equal ['"\'Special\' Name" DESC', '"First Name" ASC'], columns
  end

  def test_parsing_with_multi_argument_functions
    columns = @connection.send(:parse_columns, "COALESCE(name, 'Unknown') DESC, age")
    assert_equal ["COALESCE(name, 'Unknown') DESC", "age"], columns

    columns = @connection.send(:parse_columns, "GREATEST(created_at, updated_at, completed_at) DESC, last_name, first_name")
    assert_equal ["GREATEST(created_at, updated_at, completed_at) DESC", "last_name", "first_name"], columns
  end

  def test_parsing_with_nested_functions
    columns = @connection.send(:parse_columns, "GREATEST(COALESCE(voting_age, 18), COALESCE(driving_age, 15), COALESCE(military_age, 18)), full_name")
    assert_equal ["GREATEST(COALESCE(voting_age, 18), COALESCE(driving_age, 15), COALESCE(military_age, 18))", "full_name"], columns
  end

  def test_parsing_with_arrays
    columns = @connection.send(:parse_columns, "ARRAY[1,2,3+4], created_at")
    assert_equal ["ARRAY[1,2,3+4]", "created_at"], columns
  end
end
