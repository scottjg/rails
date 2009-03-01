require "cases/helper"
require 'models/mixed_case'
require 'models/alias'

MixedCase.connection.execute <<-_SQL
 DROP TABLE IF EXISTS "postgresql_MixedCases";
 CREATE TABLE "postgresql_MixedCases" (
 "postgresql_MixedCase_id" SERIAL PRIMARY KEY,
 "firstName" character varying(50)
 );

 DROP TABLE IF EXISTS "postgresql_Aliases";
 CREATE TABLE "postgresql_Aliases" (
   "postgresql_Aliases_id" SERIAL PRIMARY KEY,
   "postgresql_MixedCase_id" integer,
   "aliasName" character varying(50)
 );
_SQL

class PostgreqlMixedCaseTest< ActiveRecord::TestCase
  def test_creation
    mc = MixedCase.create!(:firstName => 'bob')
    assert_equal 'bob', mc.reload.firstName
  end

  def test_has_many_and_has_one
    mc = MixedCase.create!
    mc.aliases.create!(:aliasName => 'abraham')
    assert_equal 'abraham', mc.reload.aliases.first.aliasName
    assert_equal 'abraham', mc.reload.alias.aliasName
    mc.aliases.clear
    assert_equal 0, mc.reload.aliases.count
    assert_equal nil, mc.alias
  end

  def test_belongs_to
    mc = MixedCase.create!
    a = Alias.new(:aliasName => 'ham')
    a.mixed_case = mc
    a.save!
  end

  def FAILS_test_validation_of_primary_key
    MixedCase.class_eval do
      alias orig_validate validate
      alias orig_validate_on_create validate_on_create
      alias orig_validate_on_update validate_on_update

      validates_numericality_of :postgresql_MixedCase_id
    end

    MixedCase.create!
  ensure
    MixedCase.class_eval do
      alias validate orig_validate
      alias validate_on_create orig_validate_on_create
      alias validate_on_update orig_validate_on_update
    end
  end
end
