require "cases/helper"
require 'models/post'
require 'models/comment'

module ActiveRecord
  class RelationTest < ActiveRecord::TestCase
    fixtures :posts, :comments

    class FakeKlass < Struct.new(:table_name)
    end

    def test_construction
      relation = nil
      assert_nothing_raised do
        relation = Relation.new :a, :b
      end
      assert_equal :a, relation.klass
      assert_equal :b, relation.table
      assert !relation.loaded, 'relation is not loaded'
    end

    def test_single_values
      assert_equal [:limit, :offset, :lock, :readonly, :create_with, :from, :reorder].map(&:to_s).sort,
        Relation::SINGLE_VALUE_ATTRIBUTES.map(&:to_s).sort
    end

    def test_initialize_single_values
      relation = Relation.new :a, :b
      Relation::SINGLE_VALUE_ATTRIBUTES.each do |attribute|
        assert_nil relation.attributes[attribute], attribute.to_s
      end
    end

    def test_multi_value_methods
      assert_equal [:includes, :eager_load, :preload, :select, :group, :order, :joins, :where, :having, :bind].map(&:to_s).sort,
        Relation::MULTI_VALUE_ATTRIBUTES.map(&:to_s).sort
    end

    def test_multi_value_initialize
      relation = Relation.new :a, :b
      Relation::MULTI_VALUE_ATTRIBUTES.each do |attribute|
        assert_equal [], relation.attributes[attribute], attribute.to_s
      end
    end

    def test_extensions
      relation = Relation.new :a, :b
      assert_equal [], relation.extensions
    end

    def test_empty_where_values_hash
      relation = Relation.new :a, :b
      assert_equal({}, relation.where_values_hash)

      relation.attributes[:where] << :hello
      assert_equal({}, relation.where_values_hash)
    end

    def test_has_values
      relation = Relation.new Post, Post.arel_table
      relation.attributes[:where] << relation.table[:id].eq(10)
      assert_equal({:id => 10}, relation.where_values_hash)
    end

    def test_values_wrong_table
      relation = Relation.new Post, Post.arel_table
      relation.attributes[:where] << Comment.arel_table[:id].eq(10)
      assert_equal({}, relation.where_values_hash)
    end

    def test_tree_is_not_traversed
      relation = Relation.new Post, Post.arel_table
      left     = relation.table[:id].eq(10)
      right    = relation.table[:id].eq(10)
      combine  = left.and right
      relation.attributes[:where] << combine
      assert_equal({}, relation.where_values_hash)
    end

    def test_table_name_delegates_to_klass
      relation = Relation.new FakeKlass.new('foo'), :b
      assert_equal 'foo', relation.table_name
    end

    def test_scope_for_create
      relation = Relation.new :a, :b
      assert_equal({}, relation.scope_for_create)
    end

    def test_create_with_value
      relation = Relation.new Post, Post.arel_table
      hash = { :hello => 'world' }
      relation.attributes[:create_with] = hash
      assert_equal hash, relation.scope_for_create
    end

    def test_create_with_value_with_wheres
      relation = Relation.new Post, Post.arel_table
      relation.attributes[:where] << relation.table[:id].eq(10)
      relation.attributes[:create_with] = {:hello => 'world'}
      assert_equal({:hello => 'world', :id => 10}, relation.scope_for_create)
    end

    # FIXME: is this really wanted or expected behavior?
    def test_scope_for_create_is_cached
      relation = Relation.new Post, Post.arel_table
      assert_equal({}, relation.scope_for_create)

      relation.attributes[:where] << relation.table[:id].eq(10)
      assert_equal({}, relation.scope_for_create)

      relation.attributes[:create_with] = {:hello => 'world'}
      assert_equal({}, relation.scope_for_create)
    end

    def test_empty_eager_loading?
      relation = Relation.new :a, :b
      assert !relation.eager_loading?
    end

    def test_eager_load_values
      relation = Relation.new :a, :b
      relation.attributes[:eager_load] << :b
      assert relation.eager_loading?
    end

    def test_includes!
      r1 = Relation.new :a, :b
      r2 = r1.includes!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:includes]
    end

    def test_eager_load!
      r1 = Relation.new :a, :b
      r2 = r1.eager_load!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:eager_load]
    end

    def test_preload!
      r1 = Relation.new :a, :b
      r2 = r1.preload!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:preload]
    end

    def test_select!
      r1 = Relation.new :a, :b
      r2 = r1.select!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:select]
    end

    def test_group!
      r1 = Relation.new :a, :b
      r2 = r1.group!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:group]
    end

    def test_order!
      r1 = Relation.new :a, :b
      r2 = r1.order!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:order]
    end

    def test_reorder!
      r1 = Relation.new :a, :b
      r2 = r1.reorder!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:reorder]
    end

    def test_joins!
      r1 = Relation.new :a, :b
      r2 = r1.joins!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:joins]
    end

    def test_bind!
      r1 = Relation.new :a, :b
      r2 = r1.bind!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:bind]
    end

    def test_where!
      r1 = Relation.new :a, :b
      r2 = r1.where!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:where]
    end

    def test_having!
      r1 = Relation.new :a, :b
      r2 = r1.having!(:foo)

      assert r1.equal?(r2)
      assert_equal [:foo], r2.attributes[:having]
    end

    def test_limit!
      r1 = Relation.new :a, :b
      r2 = r1.limit!(5)

      assert r1.equal?(r2)
      assert_equal 5, r2.attributes[:limit]
    end

    def test_offset!
      r1 = Relation.new :a, :b
      r2 = r1.offset!(5)

      assert r1.equal?(r2)
      assert_equal 5, r2.attributes[:offset]
    end

    def test_lock!
      r1 = Relation.new :a, :b
      r2 = r1.lock!

      assert r1.equal?(r2)
      assert_equal true, r2.attributes[:lock]

      r2.lock!(false)
      assert_equal false, r2.attributes[:lock]
    end

    def test_readonly!
      r1 = Relation.new :a, :b
      r2 = r1.readonly!

      assert r1.equal?(r2)
      assert_equal true, r2.attributes[:readonly]

      r2.readonly!(false)
      assert_equal false, r2.attributes[:readonly]
    end

    def test_create_with!
      r1 = Relation.new :a, :b
      r2 = r1.create_with!(:foo => :bar)

      assert r1.equal?(r2)
      assert_equal({ :foo => :bar }, r2.attributes[:create_with])
    end

    def test_from!
      r1 = Relation.new :a, :b
      r2 = r1.from!(:foo)

      assert r1.equal?(r2)
      assert_equal :foo, r2.attributes[:from]
    end

    def test_extending!
      mod = Module.new

      r1 = Relation.new :a, :b
      r2 = r1.extending!(mod)

      assert r1.equal?(r2)
      assert_equal [mod], r2.extensions
    end
  end
end
