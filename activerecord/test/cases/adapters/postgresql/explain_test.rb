require "cases/helper"
require 'models/developer'

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      class ExplainTest < ActiveRecord::TestCase
        fixtures :developers

        def test_explain_for_one_query
          explain = Developer.where(:id => 1).explain
          assert_match %(EXPLAIN for: SELECT "developers".* FROM "developers"  WHERE "developers"."id" = 1), explain
          assert_match %(QUERY PLAN), explain
          assert_match %(Index Scan using developers_pkey on developers), explain
        end

=begin
"tbd"
+EXPLAIN for: SELECT "developers".* FROM "developers"  WHERE "developers"."id" = 1
+                                     QUERY PLAN
+------------------------------------------------------------------------------------
+ Index Scan using developers_pkey on developers  (cost=0.00..8.27 rows=1 width=556)
+   Index Cond: (id = 1)
+(2 rows)

11) Failure:
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::ExplainTest#test_explain_for_one_query [/Users/nsingh/dev/rails_edge/rails/activerecord/test/cases/adapters/postgresql/explain_test.rb:14]:
Expected /Index\ Scan\ using\ developers_pkey\ on\ developers/ to match EXPLAIN for: SELECT "developers".* FROM "developers"  WHERE "developers"."id" = 1
                        QUERY PLAN
-----------------------------------------------------------
 Seq Scan on developers  (cost=0.00..3.41 rows=1 width=49)
   Filter: (id = 1)
(2 rows)

=end
        def test_explain_with_eager_loading
          explain = Developer.where(:id => 1).includes(:audit_logs).explain
          assert_match %(QUERY PLAN), explain
          assert_match %(EXPLAIN for: SELECT "developers".* FROM "developers"  WHERE "developers"."id" = 1), explain
          assert_match %(Index Scan using developers_pkey on developers), explain
          assert_match %(EXPLAIN for: SELECT "audit_logs".* FROM "audit_logs"  WHERE "audit_logs"."developer_id" IN (1)), explain
          assert_match %(Seq Scan on audit_logs), explain
        end
      end
    end
  end
end
