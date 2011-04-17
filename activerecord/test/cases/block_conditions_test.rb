require 'cases/helper'
require 'ostruct'
require 'models/post'
require 'models/comment'

class BlockConditionsTest < ActiveRecord::TestCase
  fixtures :posts, :comments

  test "equality" do
    expected = [posts(:welcome)]

    assert_equal expected, Post.where { id == 1 }
    assert_equal expected, Post.where { posts.id == 1 }
  end

  test "inequality" do
    expected = Post.order(:id).where('id != 1').to_a

    assert_equal expected, Post.order(:id).where { id != 1 }
    assert_equal expected, Post.order(:id).where { posts.id != 1 }
  end

  test "anding predicates" do
    assert_equal [], Post.where { (id == 1)       & (id == 2)       }
    assert_equal [], Post.where { (posts.id == 1) & (posts.id == 2) }
    assert_equal [], Post.where { (posts.id == 1) & (id == 2)       }

    expected = [posts(:thinking)]
    assert_equal expected, Post.where { (tags_count == 1) & (title =~ '%thinking%') }
    assert_equal expected, Post.where { (posts.tags_count == 1) & (posts.title =~ '%thinking%') }
  end

  test "collapsing subsequent ands" do
    arel = Post.where { ((a == 1) & (b == 1)) & (c == 3) }.arel
    node = arel.ast.cores.first.wheres.first.expr
    assert node.is_a?(Arel::Nodes::And)
    assert_equal 3, node.children.count

    arel = Post.where { (a == 1) & ((b == 1) & (c == 3)) }.arel
    node = arel.ast.cores.first.wheres.first.expr
    assert node.is_a?(Arel::Nodes::And)
    assert_equal 3, node.children.count
  end

  test "oring predicates" do
    expected = [posts(:welcome), posts(:thinking)]

    assert_equal expected, Post.order(:id).where { (id == 1)       | (id == 2)       }
    assert_equal expected, Post.order(:id).where { (posts.id == 1) | (posts.id == 2) }
    assert_equal expected, Post.order(:id).where { (posts.id == 1) | (id == 2)       }
  end

  test "more complex ands and ors" do
    assert_equal(
      [posts(:thinking)],
      Post.where { (id =~ [1, 2, 3]) & (id =~ [2, 3, 4]) & (id =~ [5, 2, 8]) }
    )

    assert_equal(
      [posts(:welcome), posts(:thinking)],
      Post.where { ((id =~ [1, 6]) & (id =~ [1, 3])) | ((id =~ [1, 2]) & (id =~ [1, 2, 6])) }
    )

    assert_equal(
      [Post.find(7)],
      Post.where { ((id == 3) | (id == 7)) & ((id == 7) | (id == 5)) }
    )
  end

  test "less than" do
    expected = [posts(:welcome), posts(:thinking)]

    assert_equal expected, Post.order(:id).where { id < 3 }
    assert_equal expected, Post.order(:id).where { posts.id < 3 }
  end

  test "greater than" do
    expected = Post.order(:id).where('id > 9').to_a

    assert_equal expected, Post.order(:id).where { id > 9 }
    assert_equal expected, Post.order(:id).where { posts.id > 9 }
  end

  test "less than or equal" do
    expected = [posts(:welcome), posts(:thinking)]

    assert_equal expected, Post.order(:id).where { id <= 2 }
    assert_equal expected, Post.order(:id).where { posts.id <= 2 }
  end

  test "greater than or equal" do
    expected = Post.order(:id).where('id >= 9').to_a

    assert_equal expected, Post.order(:id).where { id >= 9 }
    assert_equal expected, Post.order(:id).where { posts.id >= 9 }
  end

  test "matches" do
    expected = [posts(:misc_by_bob), posts(:misc_by_mary)]

    assert_equal expected, Post.order(:id).where { title =~ 'misc%' }
    assert_equal expected, Post.order(:id).where { posts.title =~ 'misc%' }
  end

  test "doesn't match" do
    expected = Post.order(:id).where("title NOT LIKE 'misc%'").to_a

    assert_equal expected, Post.order(:id).where { title !~ 'misc%' }
    assert_equal expected, Post.order(:id).where { posts.title !~ 'misc%' }
  end

  test "in" do
    expected = [posts(:welcome), posts(:thinking)]

    assert_equal expected, Post.order(:id).where { id =~ [1, 2] }
    assert_equal expected, Post.order(:id).where { posts.id =~ [1, 2] }
  end

  test "not in" do
    expected = Post.order(:id).where('id NOT IN (1, 2)').to_a

    assert_equal expected, Post.order(:id).where { id !~ [1, 2] }
    assert_equal expected, Post.order(:id).where { posts.id !~ [1, 2] }
  end

  test "referencing a join table" do
    expected = [posts(:welcome), posts(:thinking)]
    assert_equal expected, Post.joins(:comments).order(:id).where { comments.id =~ [2, 3] }
  end

  test "referencing an association" do
    expected = [posts(:welcome), posts(:thinking)]
    assert_equal expected, Post.joins(:other_comments).order(:id).where { other_comments.id =~ [2, 3] }
  end

  def foo
    3
  end

  def bar(num)
    num
  end

  test "referencing a method from inside the conditions" do
    assert_equal [Post.find(3)], Post.where { id == foo }
    assert_equal [Post.find(3)], Post.where { id == bar(3) }
  end
end
