require "cases/helper"
require 'models/company'


class OperatorTest < ActiveRecord::TestCase
  def test_not_eq
    Company.class_eval do
      scope :name_not_nil, where(:name => not_eq(nil))
    end
    
    assert_equal "SELECT `companies`.* FROM `companies` WHERE (`companies`.`name` IS NOT NULL)", Company.name_not_nil.to_sql
    
    assert_equal "SELECT `companies`.* FROM `companies` WHERE (`companies`.`name` != 'bob')", Company.where(:name => Company.not_eq('bob')).to_sql
  end
end
